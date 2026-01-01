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

  Future<List<Trade>> getAllTrades() => select(trades).get();

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

  // ----------------------------
  // Small helpers (ordering / type string)
  // ----------------------------
  String _typeString(dynamic type) {
    if (type == null) return '';
    if (type is String) return type;
    final s = type.toString();
    if (s.contains('.')) return s.split('.').last;
    return s;
  }

  int cmpKey(int dtA, String typeA, int idA, int dtB, String typeB, int idB) {
    if (dtA != dtB) return dtA < dtB ? -1 : 1;
    final tc = typeA.compareTo(typeB);
    if (tc != 0) return tc < 0 ? -1 : 1;
    if (idA != idB) return idA < idB ? -1 : 1;
    return 0;
  }

  /// Returns true if existing should be considered AFTER a hypothetical new trade (newDt,newTypeStr)
  bool _isExistingTradeAfter(Trade existing, int newDt, String newTypeStr) {
    final existingDt = existing.datetime;
    if (existingDt > newDt) return true;
    if (existingDt < newDt) return false;
    final existingTypeStr = _typeString(existing.type);
    final cmp = existingTypeStr.compareTo(newTypeStr);
    if (cmp > 0) return true;
    if (cmp < 0) return false;
    // equal datetime & type -> consider existing as after (so new trade goes before existing)
    return true;
  }

  // ----------------------------
  // Buy-fee delta computation (same semantics)
  // ----------------------------
  double _computeBuyFeeDeltaForTrade(Trade trade, List<Trade> allTradesAsc) {
    if (trade.type == TradeTypes.buy) return trade.fee;
    final fifo = ListQueue<Map<String, double>>();
    for (final t in allTradesAsc) {
      if (t.id == trade.id) break;
      if (t.type == TradeTypes.buy) {
        fifo.add({'shares': t.shares, 'fee': t.fee, 'costBasis': t.costBasis});
      } else {
        var sharesToConsume = t.shares;
        while (sharesToConsume > 0 && fifo.isNotEmpty) {
          final lot = fifo.first;
          if (lot['shares']! <= sharesToConsume + 1e-12) {
            sharesToConsume -= lot['shares']!;
            fifo.removeFirst();
          } else {
            lot['shares'] = lot['shares']! - sharesToConsume;
            sharesToConsume = 0;
          }
        }
      }
    }

    var sharesToSell = trade.shares;
    double feeConsumed = 0.0;
    while (sharesToSell > 0 && fifo.isNotEmpty) {
      final lot = fifo.first;
      if (lot['shares']! <= sharesToSell + 1e-12) {
        feeConsumed += lot['fee']!;
        sharesToSell -= lot['shares']!;
        fifo.removeFirst();
      } else {
        feeConsumed += (sharesToSell / lot['shares']!) * lot['fee']!;
        lot['shares'] = lot['shares']! - sharesToSell;
        sharesToSell = 0;
      }
    }

    return -feeConsumed;
  }

  // ----------------------------
  // Undo a single trade's numeric effects (does NOT delete the row)
  // ----------------------------
  Future<void> _undoTradeFromDb(Trade t, List<Trade> allTradesAsc) async {
    final double buyFeeDelta = _computeBuyFeeDeltaForTrade(t, allTradesAsc);
    final double targetValueDelta = t.targetAccountValueDelta;
    final double sharesDelta =
        (t.type == TradeTypes.buy) ? t.shares : -t.shares;

    // Update assetsOnAccounts
    final aoaRow = await (select(assetsOnAccounts)
          ..where((a) =>
              a.assetId.equals(t.assetId) &
              a.accountId.equals(t.targetAccountId)))
        .getSingle();

    final newAoaShares = aoaRow.shares - sharesDelta;
    final newAoaValue = aoaRow.value - targetValueDelta;
    final newAoaBuyFee = aoaRow.buyFeeTotal - buyFeeDelta;

    await (update(assetsOnAccounts)
          ..where((a) =>
              a.assetId.equals(t.assetId) &
              a.accountId.equals(t.targetAccountId)))
        .write(AssetsOnAccountsCompanion(
      shares: Value(normalize(newAoaShares)),
      value: Value(normalize(newAoaValue)),
      buyFeeTotal: Value(normalize(newAoaBuyFee)),
      netCostBasis:
          Value(normalize(newAoaShares > 0 ? newAoaValue / newAoaShares : 0)),
      brokerCostBasis: Value(normalize(
          newAoaShares > 0 ? (newAoaValue + newAoaBuyFee) / newAoaShares : 0)),
    ));

    // Update global asset
    final assetRow = await (select(assets)
          ..where((a) => a.id.equals(t.assetId)))
        .getSingle();
    final newAssetShares = assetRow.shares - sharesDelta;
    final newAssetValue = assetRow.value - targetValueDelta;
    final newAssetBuyFee = assetRow.buyFeeTotal - buyFeeDelta;

    await (update(assets)..where((a) => a.id.equals(t.assetId)))
        .write(AssetsCompanion(
      shares: Value(normalize(newAssetShares)),
      value: Value(normalize(newAssetValue)),
      buyFeeTotal: Value(normalize(newAssetBuyFee)),
      netCostBasis: Value(
          normalize(newAssetShares > 0 ? newAssetValue / newAssetShares : 0)),
      brokerCostBasis: Value(normalize(newAssetShares > 0
          ? (newAssetValue + newAssetBuyFee) / newAssetShares
          : 0)),
    ));

    // Undo account balances
    final sourceAcc = await (select(accounts)
          ..where((a) => a.id.equals(t.sourceAccountId)))
        .getSingle();
    await (update(accounts)..where((a) => a.id.equals(t.sourceAccountId)))
        .write(
      AccountsCompanion(
          balance:
              Value(normalize(sourceAcc.balance - t.sourceAccountValueDelta))),
    );

    final targetAcc = await (select(accounts)
          ..where((a) => a.id.equals(t.targetAccountId)))
        .getSingle();
    await (update(accounts)..where((a) => a.id.equals(t.targetAccountId)))
        .write(
      AccountsCompanion(
          balance:
              Value(normalize(targetAcc.balance - t.targetAccountValueDelta))),
    );

    // Undo base-currency adjustments
    await db.assetsOnAccountsDao.updateBaseCurrencyAssetOnAccount(
        t.sourceAccountId, -t.sourceAccountValueDelta);
    await db.assetsDao
        .updateAsset(1, -t.sourceAccountValueDelta, -t.sourceAccountValueDelta);
  }

  // ----------------------------
  // Core apply method (insert/update)
  // ----------------------------
  Future<void> _applyTradeToDb(TradesCompanion entry,
      {required bool insertNew,
      int? updateTradeId,
      required ListQueue<Map<String, double>> fifo}) async {
    final assetId = entry.assetId.value;
    final targetAccountId = entry.targetAccountId.value;
    final sourceAccountId = entry.sourceAccountId.value;
    final shares = entry.shares.value;
    final costBasis = entry.costBasis.value;
    final fee = entry.fee.value;
    final tradeType = entry.type.value;
    final tax = tradeType == TradeTypes.sell ? entry.tax.value : 0.0;

    // Ensure AOA exists & load global asset
    var assetOnAccount = await db.assetsOnAccountsDao
        .ensureAssetOnAccountExists(assetId, targetAccountId);
    final asset = await db.assetsDao.getAsset(assetId);

    final movedValue = shares * costBasis;
    double sourceAccountValueDelta = 0;
    double targetAccountValueDelta = 0;
    double profitAndLoss = 0;
    double returnOnInvest = 0;

    double updatedAOAShares = assetOnAccount.shares;
    double updatedAOAValue = assetOnAccount.value;
    double updatedAOABuyFeeTotal = assetOnAccount.buyFeeTotal;

    double updatedAssetShares = asset.shares;
    double updatedAssetValue = asset.value;
    double updatedAssetBuyFeeTotal = asset.buyFeeTotal;

    if (tradeType == TradeTypes.buy) {
      sourceAccountValueDelta = -movedValue - fee - tax;
      targetAccountValueDelta = movedValue;

      fifo.add({'shares': shares, 'costBasis': costBasis, 'fee': fee});

      updatedAOAShares = assetOnAccount.shares + shares;
      updatedAOABuyFeeTotal = assetOnAccount.buyFeeTotal + fee;

      updatedAssetShares = asset.shares + shares;
      updatedAssetBuyFeeTotal = asset.buyFeeTotal + fee;
    } else {
      // SELL
      var sharesToSell = shares;
      sourceAccountValueDelta = movedValue - fee - tax;
      double buyFeeTotalDelta = 0.0;

      while (sharesToSell > 0 && fifo.isNotEmpty) {
        final currentLot = fifo.first;
        final lotShares = currentLot['shares']!;
        final lotCostBasis = currentLot['costBasis']!;
        final lotFee = currentLot['fee'] ?? 0.0;

        if (lotShares <= sharesToSell + 1e-12) {
          targetAccountValueDelta -= lotShares * lotCostBasis;
          sharesToSell -= lotShares;
          buyFeeTotalDelta -= lotFee;
          fifo.removeFirst();
        } else {
          targetAccountValueDelta -= sharesToSell * lotCostBasis;
          buyFeeTotalDelta -= (sharesToSell / lotShares) * lotFee;
          currentLot['shares'] = lotShares - sharesToSell;
          sharesToSell = 0;
        }
      }

      // Balance history check
      var newTrade = insertNew
          ? entry.copyWith(
              sourceAccountValueDelta: Value(sourceAccountValueDelta),
              targetAccountValueDelta: Value(targetAccountValueDelta))
          : null;
      if (await db.accountsDao
          .leadsToInconsistentBalanceHistory(newTrade: newTrade)) {
        throw Exception(
            'Applying this trade would break account balance history.');
      }

      if (sharesToSell > 1e-12) {
        throw Exception(
            'Not enough shares to sell in AOA for account $targetAccountId');
      }

      profitAndLoss =
          sourceAccountValueDelta + targetAccountValueDelta - fee + tax;
      final denom = (targetAccountValueDelta + buyFeeTotalDelta).abs();
      returnOnInvest = denom < 1e-12
          ? 0.0
          : -profitAndLoss / (targetAccountValueDelta + buyFeeTotalDelta);

      updatedAOAShares = assetOnAccount.shares - shares;
      updatedAOABuyFeeTotal = assetOnAccount.buyFeeTotal + buyFeeTotalDelta;
      if (updatedAOAShares.abs() < 1e-9) {
        updatedAOAShares = 0;
        updatedAOAValue = 0;
        updatedAOABuyFeeTotal = 0;
      }

      updatedAssetShares = asset.shares - shares;
      updatedAssetBuyFeeTotal = asset.buyFeeTotal + buyFeeTotalDelta;
    }

    // Update AssetOnAccount
    updatedAOAValue = assetOnAccount.value + targetAccountValueDelta;
    await (update(assetsOnAccounts)
          ..where((a) =>
              a.assetId.equals(assetId) & a.accountId.equals(targetAccountId)))
        .write(AssetsOnAccountsCompanion(
      shares: Value(normalize(updatedAOAShares)),
      value: Value(normalize(updatedAOAValue)),
      buyFeeTotal: Value(normalize(updatedAOABuyFeeTotal)),
      netCostBasis: Value(normalize(
          updatedAOAShares > 0 ? updatedAOAValue / updatedAOAShares : 0)),
      brokerCostBasis: Value(normalize(updatedAOAShares > 0
          ? (updatedAOAValue + updatedAOABuyFeeTotal) / updatedAOAShares
          : 0)),
    ));

    // Update Asset totals
    updatedAssetValue = asset.value + targetAccountValueDelta;
    await (update(assets)..where((a) => a.id.equals(assetId)))
        .write(AssetsCompanion(
      shares: Value(normalize(updatedAssetShares)),
      value: Value(normalize(updatedAssetValue)),
      buyFeeTotal: Value(normalize(updatedAssetBuyFeeTotal)),
      netCostBasis: Value(normalize(
          updatedAssetShares > 0 ? updatedAssetValue / updatedAssetShares : 0)),
      brokerCostBasis: Value(normalize(updatedAssetShares > 0
          ? (updatedAssetValue + updatedAssetBuyFeeTotal) / updatedAssetShares
          : 0)),
    ));

    // Base currency adjustments
    await db.assetsOnAccountsDao.updateBaseCurrencyAssetOnAccount(
        sourceAccountId, sourceAccountValueDelta);
    await db.assetsDao
        .updateAsset(1, sourceAccountValueDelta, sourceAccountValueDelta);

    // Insert or update trade row
    if (insertNew) {
      final tradeWithCalculatedValues = entry.copyWith(
        sourceAccountValueDelta: Value(normalize(sourceAccountValueDelta)),
        targetAccountValueDelta: Value(normalize(targetAccountValueDelta)),
        profitAndLoss: Value(normalize(profitAndLoss)),
        returnOnInvest: Value(normalize(returnOnInvest)),
      );
      await into(trades).insert(tradeWithCalculatedValues);
    } else {
      if (updateTradeId == null) {
        throw Exception('updateTradeId required when insertNew is false');
      }
      await (update(trades)..where((t) => t.id.equals(updateTradeId)))
          .write(TradesCompanion(
        datetime: Value(entry.datetime.value),
        shares: Value(entry.shares.value),
        costBasis: Value(entry.costBasis.value),
        fee: Value(entry.fee.value),
        tax: Value(entry.tax.value),
        sourceAccountValueDelta: Value(normalize(sourceAccountValueDelta)),
        targetAccountValueDelta: Value(normalize(targetAccountValueDelta)),
        profitAndLoss: Value(normalize(profitAndLoss)),
        returnOnInvest: Value(normalize(returnOnInvest)),
      ));
    }

    // Update account balances
    final clearingAccount = await (select(accounts)
          ..where((a) => a.id.equals(sourceAccountId)))
        .getSingle();
    await (update(accounts)..where((a) => a.id.equals(sourceAccountId))).write(
      AccountsCompanion(
          balance: Value(
              normalize(clearingAccount.balance + sourceAccountValueDelta))),
    );

    final portfolioAccount = await (select(accounts)
          ..where((a) => a.id.equals(targetAccountId)))
        .getSingle();
    await (update(accounts)..where((a) => a.id.equals(targetAccountId))).write(
      AccountsCompanion(
          balance: Value(
              normalize(portfolioAccount.balance + targetAccountValueDelta))),
    );
  }

  // ----------------------------
  // PUBLIC API: insertTrade (replaces processBackdatedInsert/processTrade)
  // ----------------------------
  Future<void> insertTrade(TradesCompanion newEntry) {
    return db.transaction(() async {
      final assetId = newEntry.assetId.value;
      final targetAccountId = newEntry.targetAccountId.value;
      final newDt = newEntry.datetime.value;
      final newTypeStr = _typeString(newEntry.type.value);

      await db.assetsOnAccountsDao
          .ensureAssetOnAccountExists(assetId, targetAccountId);

      // 1) Build FIFO prefix up to the new trade key.
      // Use upToId = 0 so existing trades with same (dt,type) are considered AFTER the new trade (as per original rule).
      final fifo = await db.assetsOnAccountsDao.buildFiFoQueue(
        assetId,
        targetAccountId,
        upToDatetime: newDt,
        upToType: newTypeStr,
        upToId: 0,
      );

      // 2) Fetch only candidate trades that could be after the new trade
      final candidateAfter = await (select(trades)
            ..where((t) =>
                t.assetId.equals(assetId) &
                t.datetime.isBiggerOrEqualValue(newDt))
            ..orderBy([
              (t) => OrderingTerm(expression: t.datetime),
              (t) => OrderingTerm(expression: t.type),
              (t) => OrderingTerm(expression: t.id),
            ]))
          .get();

      // 3) Partition into tradesAfter
      final tradesAfter = <Trade>[];
      for (final t in candidateAfter) {
        if (_isExistingTradeAfter(t, newDt, newTypeStr)) {
          tradesAfter.add(t);
        }
      }

      // 4) Undo tradesAfter (reverse order)
      for (final t in tradesAfter.reversed) {
        // For buy-fee computations we need the chronological all-trades context for that asset/account.
        // We can pass `candidateAfter` + prefix trades if callers need full context; keep original approach: fetch chronological slice including all trades before and after
        // But to compute fee deltas we need an "allTradesAsc" that represents the chronological order of trades in DB.
        // For correctness of undo fee calculation we build allTradesAsc by fetching all trades for that asset+account.
        final allTradesAsc =
            await _loadTradesForAssetAndAccount(assetId, targetAccountId);
        await _undoTradeFromDb(t, allTradesAsc);
      }

      // 5) Validate new trade if it's a sell (using fifo we built earlier)
      if (newEntry.type.value == TradeTypes.sell) {
        var sharesToSell = newEntry.shares.value;
        final fifoCopy = ListQueue<Map<String, double>>.from(
            fifo.map((e) => Map<String, double>.from(e)));
        while (sharesToSell > 0 && fifoCopy.isNotEmpty) {
          final lot = fifoCopy.first;
          if (lot['shares']! <= sharesToSell + 1e-12) {
            sharesToSell -= lot['shares']!;
            fifoCopy.removeFirst();
          } else {
            lot['shares'] = lot['shares']! - sharesToSell;
            sharesToSell = 0;
          }
        }
        if (sharesToSell > 1e-12) {
          throw Exception('Not enough shares to process this sell.');
        }
      }

      // 6) Apply new trade (insert) passing fifo so it is mutated and used by re-applies
      await _applyTradeToDb(newEntry, insertNew: true, fifo: fifo);

      // 7) Reapply tradesAfter in chronological order with same FIFO instance
      for (final t in tradesAfter) {
        final comp = TradesCompanion(
          datetime: Value(t.datetime),
          assetId: Value(t.assetId),
          type: Value(t.type),
          shares: Value(t.shares),
          costBasis: Value(t.costBasis),
          fee: Value(t.fee),
          tax: Value(t.tax),
          sourceAccountId: Value(t.sourceAccountId),
          targetAccountId: Value(t.targetAccountId),
        );
        await _applyTradeToDb(comp,
            insertNew: false, updateTradeId: t.id, fifo: fifo);
      }
    });
  }

  Future<void> updateTrade(
      int tradeId, TradesCompanion updatedFields, AppLocalizations l10n) {
    return db.transaction(() async {
      // 1) Load original trade
      final originalTrade = await (select(trades)
            ..where((t) => t.id.equals(tradeId)))
          .getSingle();

      // Merge helper
      Value<T> merge<T>(Value<T>? v, T orig) =>
          (v != null && v.present) ? v : Value(orig);

      // 2) Build updated trade
      var updatedTrade = TradesCompanion(
        datetime: merge<int>(updatedFields.datetime, originalTrade.datetime),
        assetId: Value(originalTrade.assetId),
        sourceAccountId: Value(originalTrade.sourceAccountId),
        targetAccountId: Value(originalTrade.targetAccountId),
        type: Value(originalTrade.type),
        shares: merge<double>(updatedFields.shares, originalTrade.shares),
        costBasis:
            merge<double>(updatedFields.costBasis, originalTrade.costBasis),
        fee: merge<double>(updatedFields.fee, originalTrade.fee),
        tax: merge<double>(updatedFields.tax, originalTrade.tax),
      );

      // 3) Compute earliestKey
      final dt1 = originalTrade.datetime;
      final t1 = originalTrade.type.name;
      final id1 = originalTrade.id;
      final dt2 = updatedTrade.datetime.value;
      final t2 = _typeString(updatedTrade.type.value);
      final id2 = id1; // keep same id for ordering comparisons
      final earliestIsNew = cmpKey(dt2, t2, id2, dt1, t1, id1) < 0;
      final earliestDt = earliestIsNew ? dt2 : dt1;
      final earliestType = earliestIsNew ? t2 : t1;
      final earliestId = earliestIsNew ? id2 : id1;

      // 4) Build FIFO queue up to earliestKey
      final fifo = await db.assetsOnAccountsDao.buildFiFoQueue(
        originalTrade.assetId,
        originalTrade.targetAccountId,
        upToDatetime: earliestDt,
        upToType: earliestType,
        upToId: earliestId,
      );

      // 5) Compute clearingAccountValueDelta and portfolioAccountValueDelta for updated trade
      double clearingAccountValueDelta = 0;
      double portfolioAccountValueDelta = 0;
      final shares = updatedTrade.shares.value;
      final costBasis = updatedTrade.costBasis.value;
      final fee = updatedTrade.fee.value;
      final tax = updatedTrade.tax.value;
      final movedValue = shares * costBasis;

      final fifoCopy = ListQueue<Map<String, double>>.from(
          fifo.map((e) => Map<String, double>.from(e)));

      if (updatedTrade.type.value == TradeTypes.buy) {
        clearingAccountValueDelta = -movedValue - fee - tax;
        portfolioAccountValueDelta = movedValue;
      } else {
        var sharesToSell = shares;
        clearingAccountValueDelta = movedValue - fee - tax;

        while (sharesToSell > 0 && fifoCopy.isNotEmpty) {
          final currentLot = fifoCopy.first;
          final lotShares = currentLot['shares']!;
          final lotCostBasis = currentLot['costBasis']!;

          if (lotShares <= sharesToSell + 1e-12) {
            portfolioAccountValueDelta -= lotShares * lotCostBasis;
            sharesToSell -= lotShares;
            fifo.removeFirst();
          } else {
            portfolioAccountValueDelta -= sharesToSell * lotCostBasis;
            currentLot['shares'] = lotShares - sharesToSell;
            sharesToSell = 0;
          }
        }
      }

      updatedTrade = updatedTrade.copyWith(
          sourceAccountValueDelta: Value(clearingAccountValueDelta),
          targetAccountValueDelta: Value(portfolioAccountValueDelta));

      // 6) Ensure update does not lead to inconsistent balance history on clearing and portfolio accounts
      if (await db.accountsDao.leadsToInconsistentBalanceHistory(
          originalTrade: originalTrade, newTrade: updatedTrade)) {
        throw Exception(l10n.updateWouldBreakAccountBalanceHistory);
      }

      // 7) Fetch candidate trades that might have to be undone
      final candidateTrades = await (select(trades)
            ..where((t) =>
                t.assetId.equals(originalTrade.assetId) &
                t.sourceAccountId.equals(originalTrade.sourceAccountId) &
                t.targetAccountId.equals(originalTrade.targetAccountId) &
                t.datetime.isBiggerOrEqualValue(earliestDt))
            ..orderBy([
              (t) => OrderingTerm(expression: t.datetime),
              (t) => OrderingTerm(expression: t.type),
              (t) => OrderingTerm(expression: t.id),
            ]))
          .get();

      // 8) Partition into trades before and after earliestKey
      final tradesBefore = <Trade>[];
      final tradesToUndo = <Trade>[];
      for (final t in candidateTrades) {
        final cmp = cmpKey(t.datetime, t.type.name, t.id, earliestDt,
            earliestType, earliestId);
        if (cmp < 0) {
          tradesBefore.add(t);
        } else {
          tradesToUndo.add(t);
        }
      }

      // 9) Ensure originalTrade is in tradesToUndo
      if (!tradesToUndo.any((t) => t.id == tradeId)) {
        tradesToUndo.add(originalTrade);
        tradesToUndo.sort((a, b) {
          final ta = a.type.name;
          final tb = b.type.name;
          return cmpKey(a.datetime, ta, a.id, b.datetime, tb, b.id);
        });
      }

      // 10) Undo trades in reverse chronological order
      final allTradesAsc = await _loadTradesForAssetAndAccount(
          originalTrade.assetId, originalTrade.targetAccountId);
      for (final t in tradesToUndo.reversed) {
        await _undoTradeFromDb(t, allTradesAsc);
      }

      // 11) Build the reapply list: tradesToUndo - originalTrade + updatedTrade inserted in correct spot
      final toReapplyBase = tradesToUndo.where((t) => t.id != tradeId).toList();

      int insertIndex = toReapplyBase.indexWhere((existing) {
        final cmpExistingVsMerged = cmpKey(
            existing.datetime, existing.type.name, existing.id, dt2, t2, id2);
        return cmpExistingVsMerged > 0;
      });
      if (insertIndex < 0) insertIndex = toReapplyBase.length;

      final reapplyEntries = <_ReapplyEntry>[];
      for (int i = 0; i < toReapplyBase.length + 1; i++) {
        if (i == insertIndex) {
          reapplyEntries.add(_ReapplyEntry(
              companion: updatedTrade, isMerged: true, id: tradeId));
        }
        if (i < toReapplyBase.length) {
          final t = toReapplyBase[i];
          reapplyEntries.add(_ReapplyEntry(
            companion: TradesCompanion(
              datetime: Value(t.datetime),
              assetId: Value(t.assetId),
              type: Value(t.type),
              shares: Value(t.shares),
              costBasis: Value(t.costBasis),
              fee: Value(t.fee),
              tax: Value(t.tax),
              sourceAccountId: Value(t.sourceAccountId),
              targetAccountId: Value(t.targetAccountId),
            ),
            isMerged: false,
            id: t.id,
          ));
        }
      }

      // 12) Validate updatedTrade if it is a sell (simulate on a fifo copy)
      if (updatedTrade.type.value == TradeTypes.sell) {
        final fifoCopyForValidation = ListQueue<Map<String, double>>.from(
            fifo.map((e) => Map<String, double>.from(e)));
        for (final entry in reapplyEntries) {
          if (entry.isMerged) {
            var sharesToSell = entry.companion.shares.value;
            while (sharesToSell > 0 && fifoCopyForValidation.isNotEmpty) {
              final lot = fifoCopyForValidation.first;
              if (lot['shares']! <= sharesToSell + 1e-12) {
                sharesToSell -= lot['shares']!;
                fifoCopyForValidation.removeFirst();
              } else {
                lot['shares'] = lot['shares']! - sharesToSell;
                sharesToSell = 0;
              }
            }
            if (sharesToSell > 1e-12) {
              throw Exception(l10n.updateWouldBreakAccountBalanceHistory);
            }
          } else {
            if (entry.companion.type.value == TradeTypes.buy) {
              fifoCopyForValidation.add({
                'shares': entry.companion.shares.value,
                'costBasis': entry.companion.costBasis.value,
                'fee': entry.companion.fee.value,
              });
            } else {
              var s = entry.companion.shares.value;
              while (s > 0 && fifoCopyForValidation.isNotEmpty) {
                final lot = fifoCopyForValidation.first;
                if (lot['shares']! <= s + 1e-12) {
                  s -= lot['shares']!;
                  fifoCopyForValidation.removeFirst();
                } else {
                  lot['shares'] = lot['shares']! - s;
                  s = 0;
                }
              }
              if (s > 1e-12) {
                throw Exception(l10n.updateWouldBreakAccountBalanceHistory);
              }
            }
          }
        }
      }

      // 13) Reapply all entries in order using the same fifo instance
      for (final entry in reapplyEntries) {
        // await _applyTradeToDb(entry.companion,
        //     insertNew: false, updateTradeId: entry.id, fifo: fifo);
        if (entry.isMerged) {
          await _applyTradeToDb(entry.companion,
              insertNew: false, updateTradeId: entry.id, fifo: fifo);
        } else {
          await _applyTradeToDb(entry.companion,
              insertNew: false, updateTradeId: entry.id, fifo: fifo);
        }
      }
    });
  }

  // ----------------------------
  // PUBLIC API: deleteTrade (replaces processBackdatedDelete)
  // ----------------------------
  Future<void> deleteTrade(int tradeId) {
    return db.transaction(() async {
      final original = await (select(trades)
            ..where((t) => t.id.equals(tradeId)))
          .getSingle();

      final assetId = original.assetId;
      final accountId = original.targetAccountId;

      // earliestKey = original's key
      final oldDt = original.datetime;
      final oldTypeStr = _typeString(original.type);
      final oldId = original.id;

      // 1) Build FIFO prefix up to original key
      final fifo = await db.assetsOnAccountsDao.buildFiFoQueue(
        assetId,
        accountId,
        upToDatetime: oldDt,
        upToType: oldTypeStr,
        upToId: oldId,
      );

      // 2) Fetch candidate trades with datetime >= earliestDt
      final candidateTrades = await (select(trades)
            ..where((t) =>
                t.assetId.equals(assetId) &
                t.datetime.isBiggerOrEqualValue(oldDt))
            ..orderBy([
              (t) => OrderingTerm(expression: t.datetime),
              (t) => OrderingTerm(expression: t.type),
              (t) => OrderingTerm(expression: t.id),
            ]))
          .get();

      // Partition into tradesBefore and tradesToUndo
      final tradesBefore = <Trade>[];
      final tradesToUndo = <Trade>[];

      for (final t in candidateTrades) {
        final tTypeStr = _typeString(t.type);
        final cmp =
            cmpKey(t.datetime, tTypeStr, t.id, oldDt, oldTypeStr, oldId);
        if (cmp < 0) {
          tradesBefore.add(t);
        } else {
          tradesToUndo.add(t);
        }
      }

      // Ensure original is included
      if (!tradesToUndo.any((t) => t.id == tradeId)) {
        tradesToUndo.add(original);
        tradesToUndo.sort((a, b) {
          final ta = _typeString(a.type);
          final tb = _typeString(b.type);
          return cmpKey(a.datetime, ta, a.id, b.datetime, tb, b.id);
        });
      }

      // // Balance timeline check
      // final inconsistent =
      //     await db.accountsDao.leadsToInconsistentBalanceHistory();
      // if (inconsistent)
      //   throw Exception(
      //       'Deleting this trade would break account balance history.');

      // Undo tradesToUndo in reverse (need full chronological context)
      final allTradesAsc =
          await _loadTradesForAssetAndAccount(assetId, accountId);
      for (final t in tradesToUndo.reversed) {
        await _undoTradeFromDb(t, allTradesAsc);
      }

      // Delete original trade row
      await (delete(trades)..where((t) => t.id.equals(tradeId))).go();

      // Validate reapplying remaining trades will succeed (simulate with a copy)
      final toReapplyBase = tradesToUndo.where((t) => t.id != tradeId).toList()
        ..sort((a, b) {
          final ta = _typeString(a.type);
          final tb = _typeString(b.type);
          return cmpKey(a.datetime, ta, a.id, b.datetime, tb, b.id);
        });

      final fifoCopy = ListQueue<Map<String, double>>.from(
          fifo.map((e) => Map<String, double>.from(e)));
      for (final t in toReapplyBase) {
        if (t.type == TradeTypes.buy) {
          fifoCopy.add(
              {'shares': t.shares, 'costBasis': t.costBasis, 'fee': t.fee});
        } else {
          var s = t.shares;
          while (s > 0 && fifoCopy.isNotEmpty) {
            final lot = fifoCopy.first;
            if (lot['shares']! <= s + 1e-12) {
              s -= lot['shares']!;
              fifoCopy.removeFirst();
            } else {
              lot['shares'] = lot['shares']! - s;
              s = 0;
            }
          }
          if (s > 1e-12) {
            throw Exception(
                'Reapplying trades after delete would result in an invalid sell (insufficient shares).');
          }
        }
      }

      // Reapply using the SAME FIFO instance (mutated)
      for (final t in toReapplyBase) {
        final comp = TradesCompanion(
          datetime: Value(t.datetime),
          assetId: Value(t.assetId),
          type: Value(t.type),
          shares: Value(t.shares),
          costBasis: Value(t.costBasis),
          fee: Value(t.fee),
          tax: Value(t.tax),
          sourceAccountId: Value(t.sourceAccountId),
          targetAccountId: Value(t.targetAccountId),
        );
        await _applyTradeToDb(comp,
            insertNew: false, updateTradeId: t.id, fifo: fifo);
      }
    });
  }

  // ----------------------------
  // Helper: getTrade
  // ----------------------------
  Future<Trade> getTrade(int id) {
    return (select(trades)..where((a) => a.id.equals(id))).getSingle();
  }

  // ----------------------------
  // Internal helper kept for some undo logic that expects all chronological trades.
  // You can still keep this if other parts rely on full list; otherwise you can remove.
  // ----------------------------
  Future<List<Trade>> _loadTradesForAssetAndAccount(
      int assetId, int accountId) {
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

//   Future<void> insertFromCsv() async {
//     int count = 1;
//     List<String> rows = csv.split('\n');
//     for (final row in rows) {
//       final fields = row.split(';');
//
//       int datetime = int.parse(fields[0]);
//       TradeTypes type = const TradeTypesConverter().fromSql(fields[1]);
//       int sourceAccountId = int.parse(fields[2]);
//       int targetAccountId = int.parse(fields[3]);
//       int assetId = int.parse(fields[4]);
//       double shares = double.parse(fields[5]);
//       double costBasis = double.parse(fields[6]);
//       double fee = double.parse(fields[7]);
//
//       TradesCompanion t = TradesCompanion(
//           datetime: Value(datetime),
//           type: Value(type),
//           sourceAccountId: Value(sourceAccountId),
//           targetAccountId: Value(targetAccountId),
//           assetId: Value(assetId),
//           shares: Value(shares),
//           costBasis: Value(costBasis),
//           fee: Value(fee),
//           tax: const Value(0));
//
//       try {
//         insertTrade(t);
//         print('Trade ${count}/${rows.length} inserted successfully');
//         count++;
//       } catch (e) {
//         print('Error at row ' + row.toString());
//         print(e);
//         break;
//       }
//     }
//   }
//
//   final String csv = """
// 20241210105136;buy;11;11;48;51.948000000000;0.950900000000;0.049446800000
// 20241210111438;buy;11;11;48;210.789000000000;0.949800000000;0.200407800000
// 20241210111501;sell;11;11;48;49.999680000000;0.950000000000;0.000000000000
// 20241210111501;buy;11;11;49;1233.325440000000;0.038475000000;0.047499696000
// 20241210143623;sell;11;11;49;233.320000000000;0.042433032000;0.000000000000
// 20241210143623;buy;11;11;48;10.397996794800;0.951200000000;0.009900475026
// 20241210143623;sell;11;11;49;1000.000000000000;0.042433032000;0.000000000000
// 20241210143623;buy;11;11;48;44.565390000000;0.951200000000;0.042433032000
// 20241210150046;sell;11;11;48;149.967268000000;0.951700000000;0.000000000000
// 20241210150046;buy;11;11;50;10.109880000000;14.103147130000;0.142723848956
// 20241210151932;sell;11;11;50;10.100000000000;6.221620650000;0.000000000000
// 20241210151932;buy;11;11;48;66.003080850000;0.951100000000;0.062838368565
// 20241211075317;sell;11;11;48;39.729300000000;0.951200000000;0.000000000000
// 20241211075317;buy;11;11;51;39.610350000000;0.953102400000;0.037790510160
// 20241211080510;buy;11;11;48;261.738000000000;0.951300000000;0.249240600000
// 20241211132927;sell;11;11;48;20.000000000000;0.952400000000;0.000000000000
// 20241211132927;buy;11;11;52;3121.875000000000;0.006095360000;0.019048000000
// 20241211133227;sell;11;11;48;19.999072000000;0.952800000000;0.000000000000
// 20241211133227;buy;11;11;53;128.731140000000;0.147874560000;0.019055115802
// 20241211134005;sell;11;11;53;128.730000000000;0.153560520000;0.000000000000
// 20241211134005;buy;11;11;48;20.717664597000;0.953200000000;0.019767845740
// 20241211134343;sell;11;11;52;3121.870000000000;0.006909975000;0.000000000000
// 20241211134343;buy;11;11;48;22.610923942500;0.953100000000;0.021572043653
// 20241211135920;sell;11;11;48;24.981946000000;0.953300000000;0.000000000000
// 20241211135920;buy;11;11;24;0.110988900000;214.359038000000;0.023815289122
// 20241211140301;sell;11;11;24;0.109900000000;214.444060000000;0.000000000000
// 20241211140301;buy;11;11;48;24.704968302000;0.953000000000;0.023567402194
// 20241211171157;sell;11;11;48;35.465808000000;0.952200000000;0.000000000000
// 20241211171157;buy;11;11;53;248.111640000000;0.135974160000;0.033770542378
// 20241211171157;sell;11;11;48;14.534184000000;0.952200000000;0.000000000000
// 20241211171157;buy;11;11;53;101.678220000000;0.135974160000;0.013839450005
// 20241211172640;sell;11;11;53;349.790000000000;0.136264700000;0.000000000000
// 20241211172640;buy;11;11;48;49.969950030000;0.952900000000;0.047664029413
// 20241211201450;sell;11;11;48;49.955576000000;0.951600000000;0.000000000000
// 20241211201450;buy;11;11;50;9.670320000000;4.910922120000;0.047537726122
// 20241211201728;sell;11;11;48;49.858263000000;0.951600000000;0.000000000000
// 20241211201728;buy;11;11;54;3577.419000000000;0.013249126800;0.047445123071
// 20241211201929;sell;11;11;48;31.999972489000;0.951600000000;0.000000000000
// 20241211201929;buy;11;11;55;77.688333900000;0.391573884000;0.030451173821
// 20241211201936;sell;11;11;48;2.602710900000;0.951600000000;0.000000000000
// 20241211201936;buy;11;11;56;6.383610000000;0.387596196000;0.002476739692
// 20241211202023;sell;11;11;48;16.820413900000;0.951500000000;0.000000000000
// 20241211202023;buy;11;11;56;41.228730000000;0.387802855000;0.016004623826
// 20241211202023;sell;11;11;48;1.821167400000;0.951500000000;0.000000000000
// 20241211202023;buy;11;11;56;4.465530000000;0.387660130000;0.001732840781
// 20241211202023;sell;11;11;48;1.735524000000;0.951500000000;0.000000000000
// 20241211202023;buy;11;11;56;4.255740000000;0.387641100000;0.001651351086
// 20241211202023;sell;11;11;48;7.719661500000;0.951500000000;0.000000000000
// 20241211202023;buy;11;11;56;18.931050000000;0.387612555000;0.007345257917
// 20241211202023;sell;11;11;48;2.252590200000;0.951500000000;0.000000000000
// 20241211202023;buy;11;11;56;5.524470000000;0.387584010000;0.002143339575
// 20241213083429;buy;11;11;48;103.896000000000;0.955900000000;0.099413600000
// 20241213083448;sell;11;11;48;49.999990990000;0.955800000000;0.000000000000
// 20241213083448;buy;11;11;57;2133703.161000000000;0.000022375278;0.047789991388
// 20241213083501;sell;11;11;48;49.999999999950;0.955800000000;0.000000000000
// 20241213083501;buy;11;11;58;1799999.999998200000;0.000026523450;0.047790000000
// 20241216195237;buy;11;11;24;0.238261500000;209.500000000000;0.049965750000
// 20241216200448;buy;11;11;48;159.840000000000;0.946800000000;0.151488000000
// """;
}

/// small container used in reapply stage
class _ReapplyEntry {
  final TradesCompanion companion;
  final bool isMerged;
  final int id;

  _ReapplyEntry(
      {required this.companion, required this.isMerged, required this.id});
}
