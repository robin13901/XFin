import 'dart:collection';

import 'package:drift/drift.dart';
import 'package:xfin/l10n/app_localizations.dart';
import 'package:xfin/models/filter/filter_rule.dart';
import 'package:xfin/utils/global_constants.dart';
import '../app_database.dart';
import '../dao_exception.dart';
import '../filter_builder.dart';
import '../tables.dart';

part 'trades_dao.g.dart';

class TradeWithAsset {
  final Trade trade;
  final Asset asset;

  TradeWithAsset({required this.trade, required this.asset});
}

@DriftAccessor(tables: [Trades, Assets])
class TradesDao extends DatabaseAccessor<AppDatabase> with _$TradesDaoMixin {
  TradesDao(super.db);

  Future<int> _insert(TradesCompanion t) => into(trades).insert(t);

  Future<bool> _update(TradesCompanion t) => update(trades).replace(t);

  Future<int> _delete(TradesCompanion t) => delete(trades).delete(t);

  Future<Trade> getTrade(int id) =>
      (select(trades)..where((a) => a.id.equals(id))).getSingle();

  Future<List<Trade>> getAllTrades() => select(trades).get();

  Future<List<Trade>> getTradesForAccount(int accountId) => (select(trades)
        ..where((t) =>
            t.sourceAccountId.equals(accountId) |
            t.targetAccountId.equals(accountId)))
      .get();

  Future<List<Trade>> getTradesForAOA(
          int assetId, int accountId) =>
      (select(trades)
            ..where((t) =>
                t.assetId.equals(assetId) &
                ((t.targetAccountId.equals(accountId)) |
                    (t.sourceAccountId.equals(accountId)))))
          .get();

  Future<List<Trade>> getTradesAfter(
          int assetId, int accountId, int datetime) =>
      (select(trades)
            ..where((t) =>
                t.assetId.equals(assetId) &
                t.targetAccountId.equals(accountId) &
                t.datetime.isBiggerOrEqualValue(datetime))
            ..orderBy([
              (t) => OrderingTerm(expression: t.datetime),
            ]))
          .get();

  Stream<List<TradeWithAsset>> watchAllTrades({
    String? searchQuery,
    List<FilterRule>? filterRules,
  }) {
    final query = select(trades)
      ..orderBy([
        (t) => OrderingTerm.desc(t.datetime),
        (t) => OrderingTerm.desc(t.id)
      ]);

    // Apply filter rules
    if (filterRules != null && filterRules.isNotEmpty) {
      final builder = TradeFilterBuilder(trades);
      final filterExpr = builder.buildExpression(filterRules);
      if (filterExpr != null) {
        query.where((t) => filterExpr);
      }
    }

    return query
        .join([innerJoin(assets, assets.id.equalsExp(trades.assetId))])
        .watch()
        .map((rows) {
      var results = rows
          .map((r) => TradeWithAsset(
              trade: r.readTable(trades), asset: r.readTable(assets)))
          .toList();

      // Apply search query on asset name (post-filter since we need joined data)
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final searchLower = searchQuery.toLowerCase();
        results = results
            .where((r) => r.asset.name.toLowerCase().contains(searchLower) ||
                r.asset.tickerSymbol.toLowerCase().contains(searchLower))
            .toList();
      }

      return results;
    });
  }

  Future<double> _computeBuyFeeDeltaForTrade(Trade t) async {
    if (t.type == TradeTypes.buy) return t.fee;
    final fifo = await db.assetsOnAccountsDao.buildFiFoQueue(
        t.assetId, t.targetAccountId,
        upToDatetime: t.datetime, upToType: t.type.name, upToId: t.id);

    final (_, consumedFee) = consumeFiFo(fifo, t.shares);
    return consumedFee;
  }

  /// Updates Assets, Accounts and AssetsOnAccounts db tables based on deltas
  Future<void> applyDbEffects(int assetId, int accountId, double sharesDelta,
      double valueDelta, double buyFeeDelta,
      {bool updateAsset = true}) async {
    if (updateAsset) {
      await db.assetsDao
          .updateAsset(assetId, sharesDelta, valueDelta, buyFeeDelta);
    }
    await db.accountsDao.updateBalance(accountId, valueDelta);
    await db.assetsOnAccountsDao.updateAOA(AssetOnAccount(
      accountId: accountId,
      assetId: assetId,
      shares: sharesDelta,
      value: valueDelta,
      netCostBasis: 0,
      brokerCostBasis: 0,
      buyFeeTotal: buyFeeDelta,
    ));
  }

  /// Undo a single trade's numeric effects (does NOT delete the row)
  Future<void> undoTradeFromDb(Trade t) async {
    final sharesDelta = (t.type == TradeTypes.buy) ? t.shares : -t.shares;
    final buyFeeDelta = await _computeBuyFeeDeltaForTrade(t);

    await applyDbEffects(1, t.sourceAccountId, -t.sourceAccountValueDelta,
        -t.sourceAccountValueDelta, 0);
    await applyDbEffects(t.assetId, t.targetAccountId, -sharesDelta,
        -t.targetAccountValueDelta, -buyFeeDelta);
  }

  /// Computes trade values and inserts/updates it
  Future<void> applyTradeToDb(
      TradesCompanion t, ListQueue<Map<String, double>> fifo,
      AppLocalizations l10n) async {
    final shares = t.shares.value;
    final costBasis = t.costBasis.value;
    final fee = t.fee.value;
    final tradeType = t.type.value;
    final tax = tradeType == TradeTypes.sell ? t.tax.value : 0.0;

    final movedValue = shares * costBasis;
    final sharesDelta = tradeType == TradeTypes.buy ? shares : -shares;
    double clearingValueDelta = 0, portfolioValueDelta = 0;
    double pnl = 0, roi = 0;
    double buyFeeTotalDelta = 0.0;

    if (tradeType == TradeTypes.buy) {
      clearingValueDelta = -movedValue - fee - tax;
      portfolioValueDelta = movedValue;
      fifo.add({'shares': shares, 'costBasis': costBasis, 'fee': fee});
      buyFeeTotalDelta = fee;
    } else {
      clearingValueDelta = movedValue - fee - tax;
      if (fifo.fold(0.0, (sum, lot) => sum + lot['shares']!) < shares) {
        throw DaoValidationException(l10n.insufficientShares);
      }
      (portfolioValueDelta, buyFeeTotalDelta) = consumeFiFo(fifo, shares);
      pnl = clearingValueDelta + portfolioValueDelta - fee + tax;
      roi = (portfolioValueDelta + buyFeeTotalDelta).abs() < 1e-12
          ? 0.0
          : -pnl / (portfolioValueDelta + buyFeeTotalDelta);
    }

    await applyDbEffects(
        1, t.sourceAccountId.value, clearingValueDelta, clearingValueDelta, 0);
    await applyDbEffects(t.assetId.value, t.targetAccountId.value, sharesDelta,
        portfolioValueDelta, buyFeeTotalDelta);

    t = t.copyWith(
      sourceAccountValueDelta: Value(normalize(clearingValueDelta)),
      targetAccountValueDelta: Value(normalize(portfolioValueDelta)),
      profitAndLoss: Value(normalize(pnl)),
      returnOnInvest: Value(normalize(roi)),
    );
    await (t.id.present ? _update(t) : _insert(t));
  }

  Future<void> insertTrade(TradesCompanion t, AppLocalizations l10n) {
    return db.transaction(() async {
      if (t.shares.value <= 0) {
        throw DaoValidationException(l10n.sharesRequired);
      }

      final fifo = await db.assetsOnAccountsDao.buildFiFoQueue(
        t.assetId.value,
        t.targetAccountId.value,
        upToDatetime: t.datetime.value,
        upToType: t.type.value.name,
        upToId: 0,
      );

      await applyTradeToDb(t, fifo, l10n);

      await db.assetsOnAccountsDao.recalculateSubsequentEvents(
        l10n: l10n,
        assetId: t.assetId.value,
        accountId: t.targetAccountId.value,
        upToDatetime: t.datetime.value,
        upToType: t.type.value.name,
        upToId: 999999999,
      );
    });
  }

  Future<void> updateTrade(TradesCompanion t, AppLocalizations l10n) {
    return db.transaction(() async {
      final originalTrade = await getTrade(t.id.value);

      Value<T> merge<T>(Value<T>? v, T orig) =>
          (v != null && v.present) ? v : Value(orig);

      var updatedTrade = TradesCompanion(
        id: t.id,
        datetime: merge<int>(t.datetime, originalTrade.datetime),
        assetId: Value(originalTrade.assetId),
        sourceAccountId: Value(originalTrade.sourceAccountId),
        targetAccountId: Value(originalTrade.targetAccountId),
        type: Value(originalTrade.type),
        shares: merge<double>(t.shares, originalTrade.shares),
        costBasis: merge<double>(t.costBasis, originalTrade.costBasis),
        fee: merge<double>(t.fee, originalTrade.fee),
        tax: merge<double>(t.tax, originalTrade.tax),
      );

      // 3) Compute earliestKey (min of original vs updated)
      final dt1 = originalTrade.datetime;
      final dt2 = updatedTrade.datetime.value;
      final t2 = updatedTrade.type.value.name;

      await undoTradeFromDb(originalTrade);

      final fifo = await db.assetsOnAccountsDao.buildFiFoQueue(
        originalTrade.assetId,
        originalTrade.targetAccountId,
        upToDatetime: dt2,
        upToType: t2,
        upToId: originalTrade.id,
      );

      await applyTradeToDb(updatedTrade, fifo, l10n);

      final recalcUpToId = t.id.value + 1;
      await db.assetsOnAccountsDao.recalculateSubsequentEvents(
        l10n: l10n,
        assetId: originalTrade.assetId,
        accountId: originalTrade.targetAccountId,
        upToDatetime: dt2 < dt1 ? dt2 : dt1,
        upToType: t2,
        upToId: recalcUpToId,
      );
    });
  }

  Future<void> deleteTrade(int id, AppLocalizations l10n) {
    return db.transaction(() async {
      Trade t = await getTrade(id);
      await undoTradeFromDb(t);

      await _delete(t.toCompanion(false));

      await db.assetsOnAccountsDao.recalculateSubsequentEvents(
        l10n: l10n,
        assetId: t.assetId,
        accountId: t.targetAccountId,
        upToDatetime: t.datetime,
        upToType: t.type.name,
        upToId: t.id,
      );
    });
  }

  Future<List<Trade>> loadTradesForAssetAndAccount(int assetId, int accountId) {
    return (select(trades)
          ..where((t) =>
              t.assetId.equals(assetId) & t.targetAccountId.equals(accountId))
          ..orderBy([
            (t) => OrderingTerm(expression: t.datetime),
            (t) => OrderingTerm(expression: t.type),
            (t) => OrderingTerm(expression: t.id),
          ]))
        .get();
  }
}
