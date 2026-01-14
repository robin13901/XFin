import 'dart:collection';

import 'package:drift/drift.dart';
import 'package:xfin/l10n/app_localizations.dart';
import 'package:xfin/utils/global_constants.dart';
import '../app_database.dart';
import '../tables.dart';

part 'trades_dao.g.dart';

class TradeWithAsset {
  final Trade trade;
  final Asset asset;

  TradeWithAsset({required this.trade, required this.asset});
}

@DriftAccessor(
    tables: [Trades, Assets, Accounts, AssetsOnAccounts, Bookings, Transfers])
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

  Stream<List<TradeWithAsset>> watchAllTrades() {
    return (select(trades)
          ..orderBy([
            (t) => OrderingTerm.desc(t.datetime),
            (t) => OrderingTerm.desc(t.id)
          ]))
        .join([innerJoin(assets, assets.id.equalsExp(trades.assetId))])
        .watch()
        .map((rows) {
          return rows
              .map((r) => TradeWithAsset(
                  trade: r.readTable(trades), asset: r.readTable(assets)))
              .toList();
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
      TradesCompanion t, ListQueue<Map<String, double>> fifo) async {
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
        throw Exception('Not enough shares to process this sell.');
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
      final fifo = await db.assetsOnAccountsDao.buildFiFoQueue(
        t.assetId.value,
        t.targetAccountId.value,
        upToDatetime: t.datetime.value,
        upToType: t.type.value.name,
        upToId: 0,
      );

      await applyTradeToDb(t, fifo);

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

      await applyTradeToDb(updatedTrade, fifo);

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

// Future<void> insertFromCsv() async {
//   int count = 1;
//   List<String> rows = csv.split('\n');
//   for (final row in rows) {
//     final fields = row.split(';');
//
//     int datetime = int.parse(fields[0]);
//     TradeTypes type = const TradeTypesConverter().fromSql(fields[1]);
//     int sourceAccountId = int.parse(fields[2]);
//     int targetAccountId = int.parse(fields[3]);
//     int assetId = int.parse(fields[4]);
//     double shares = double.parse(fields[5]);
//     double costBasis = double.parse(fields[6]);
//     double fee = double.parse(fields[7]);
//
//     TradesCompanion t = TradesCompanion(
//         datetime: Value(datetime),
//         type: Value(type),
//         sourceAccountId: Value(sourceAccountId),
//         targetAccountId: Value(targetAccountId),
//         assetId: Value(assetId),
//         shares: Value(shares),
//         costBasis: Value(costBasis),
//         fee: Value(fee),
//         tax: const Value(0));
//
//     try {
//       insertTrade(t);
//       print('Trade ${count}/${rows.length} inserted successfully');
//       count++;
//     } catch (e) {
//       print('Error at row ' + row.toString());
//       print(e);
//       break;
//     }
//   }
// }
//
//   final String csv = """
// 20250119150344;sell;11;11;58;1799999.999900000000;0.000020797660;0.000000000000
// 20250119150344;buy;11;11;48;38.338564209870;0.975500000000;0.037435787998
// 20250119150357;sell;11;11;48;51.953370000000;0.975500000000;0.000000000000
// 20250119150357;buy;11;11;60;0.679319487565;69.425359500000;0.050680512435
// 20250321181012;sell;11;11;48;118.430507660000;0.925200000000;0.000000000000
// 20250321181012;buy;11;11;25;49.314728094313;2.216964240000;0.109571905687
// 20250503075433;sell;11;11;60;0.729270000000;11.491355400000;0.000000000000
// 20250503075433;sell;11;11;49;0.005440000000;0.008210327206;0.000000000000
// 20250503075433;sell;11;11;56;80.789130000000;0.063671562078;0.000000000000
// 20250503075433;sell;11;11;22;0.000000857500;85483.747062000000;0.000000000000
// 20250503075433;sell;11;11;53;0.001000000000;0.152488434000;0.000000000000
// 20250503075433;sell;11;11;50;9.680200000000;0.902417460000;0.000000000000
// 20250503075433;sell;11;11;48;0.000136430670;0.886200000000;0.000000000000
// 20250503075434;buy;11;11;61;5.594670230000;3.883328400000;0.443386709060
// 20250503075728;sell;11;11;61;5.594600000000;3.885100800000;0.000000000000
// 20250503075728;buy;11;11;48;24.504990815064;0.886200000000;0.021735584936
// 20250503075748;sell;11;11;48;24.500592000000;0.886200000000;0.000000000000
// 20250503075748;buy;11;11;62;41.738287575370;0.519933540000;0.021712424630
// 20250503173825;buy;11;11;48;111.900745600000;0.886200000000;0.099254400000
// 20250503173850;sell;11;11;48;9.998816000000;0.886200000000;0.000000000000
// 20250503173850;buy;11;11;63;43.351139049261;0.204357720000;0.008860950739
// 20250503173905;sell;11;11;48;9.999990000000;0.886100000000;0.000000000000
// 20250503173905;buy;11;11;64;0.690439008861;12.671230000000;0.008860991139
// 20250503174100;sell;11;11;48;9.999477000000;0.886100000000;0.000000000000
// 20250503174100;buy;11;11;65;0.474439463430;18.333409000000;0.008860536570
// 20250503174125;sell;11;11;48;19.999980000000;0.886100000000;0.000000000000
// 20250503174125;buy;11;11;66;27.954278017722;0.633561500000;0.017721982278
// 20250503174151;sell;11;11;48;61.861950000000;0.886100000000;0.000000000000
// 20250503174151;buy;11;11;67;0.048684126105;529.621970000000;0.054815873895
// 20251111155746;sell;11;11;67;0.103300000000;846.742600000000;0.000000000000
// 20251111155746;buy;11;11;48;101.384121489420;0.862000000000;0.087468510580
// """;
}
