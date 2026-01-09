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

  int cmpKey(int dtA, String typeA, int idA, int dtB, String typeB, int idB) {
    if (dtA != dtB) return dtA < dtB ? -1 : 1;
    final tc = typeA.compareTo(typeB);
    if (tc != 0) return tc < 0 ? -1 : 1;
    if (idA != idB) return idA < idB ? -1 : 1;
    return 0;
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
  Future<void> undoTradeFromDb(Trade t, List<Trade> allTradesAsc) async {
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
  Future<void> applyTradeToDb(TradesCompanion entry,
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

  Future<void> insertTrade(TradesCompanion newEntry, AppLocalizations l10n) {
    return db.transaction(() async {
      final assetId = newEntry.assetId.value;
      final targetAccountId = newEntry.targetAccountId.value;
      final newDt = newEntry.datetime.value;
      final newTypeStr = newEntry.type.value.name;

      // Ensure AOA exists
      await db.assetsOnAccountsDao.ensureAssetOnAccountExists(assetId, targetAccountId);

      // 1) Build FIFO prefix up to the new trade key (new trade NOT yet in DB)
      final fifo = await db.assetsOnAccountsDao.buildFiFoQueue(
        assetId,
        targetAccountId,
        upToDatetime: newDt,
        upToType: newTypeStr,
        upToId: 0, // existing trades with same (dt,type) are considered AFTER the new trade
      );

      // 2) Validate new trade if it's a sell (simulate on fifo copy)
      if (newEntry.type.value == TradeTypes.sell) {
        var sharesToSell = newEntry.shares.value;
        final fifoCopy = ListQueue<Map<String, double>>.from(
          fifo.map((e) => Map<String, double>.from(e)),
        );
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

      // 3) Apply new trade (this inserts/updates AOAs/assets/accounts).
      // applyTradeToDb now returns the inserted id when insertNew == true (see small change below).
      await applyTradeToDb(newEntry, insertNew: true, fifo: fifo);

      // 4) Recalculate *subsequent* events (trades, transfers, bookings) that come AFTER the new trade.
      // We want the recalculation prefix to *include* the newly inserted trade (because we've already applied it),
      // but exclude events that are strictly after it. To accomplish this we set the ordering key to
      // (newDt, newTypeStr, insertedId + 1) so that events with (dt,type,id) < that key (i.e. the new trade)
      // are included in the prefix.
      await db.assetsOnAccountsDao.recalculateSubsequentEvents(
        l10n: l10n,
        assetId: assetId,
        accountId: targetAccountId,
        upToDatetime: newDt,
        upToType: newTypeStr,
        upToId: 999999999,
      );

      // done (transaction ensures atomicity)
    });
  }

  Future<void> updateTrade(
      int tradeId, TradesCompanion updatedFields, AppLocalizations l10n) {
    return db.transaction(() async {
      // 1) Load original trade
      final originalTrade = await (select(trades)..where((t) => t.id.equals(tradeId)))
          .getSingle();

      // Merge helper (unchanged)
      Value<T> merge<T>(Value<T>? v, T orig) => (v != null && v.present) ? v : Value(orig);

      // 2) Build updated trade companion (merged values)
      var updatedTrade = TradesCompanion(
        datetime: merge<int>(updatedFields.datetime, originalTrade.datetime),
        assetId: Value(originalTrade.assetId),
        sourceAccountId: Value(originalTrade.sourceAccountId),
        targetAccountId: Value(originalTrade.targetAccountId),
        type: Value(originalTrade.type),
        shares: merge<double>(updatedFields.shares, originalTrade.shares),
        costBasis: merge<double>(updatedFields.costBasis, originalTrade.costBasis),
        fee: merge<double>(updatedFields.fee, originalTrade.fee),
        tax: merge<double>(updatedFields.tax, originalTrade.tax),
      );

      // 3) Compute earliestKey (min of original vs updated)
      final dt1 = originalTrade.datetime;
      final t1 = originalTrade.type.name;
      final id1 = originalTrade.id;
      final dt2 = updatedTrade.datetime.value;
      final t2 = updatedTrade.type.value.name;
      final id2 = id1; // keep same id for ordering comparisons
      final earliestIsNew = cmpKey(dt2, t2, id2, dt1, t1, id1) < 0;
      final earliestDt = earliestIsNew ? dt2 : dt1;
      final earliestType = earliestIsNew ? t2 : t1;
      final earliestId = earliestIsNew ? id2 : id1;

      // 4) Build FIFO up to earliestKey (used to compute account deltas for validation)
      final fifoForValidation = await db.assetsOnAccountsDao.buildFiFoQueue(
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

      final fifoCopyForCalc = ListQueue<Map<String, double>>.from(
          fifoForValidation.map((e) => Map<String, double>.from(e)));

      if (updatedTrade.type.value == TradeTypes.buy) {
        clearingAccountValueDelta = -movedValue - fee - tax;
        portfolioAccountValueDelta = movedValue;
      } else {
        var sharesToSell = shares;
        clearingAccountValueDelta = movedValue - fee - tax;

        while (sharesToSell > 0 && fifoCopyForCalc.isNotEmpty) {
          final currentLot = fifoCopyForCalc.first;
          final lotShares = currentLot['shares']!;
          final lotCostBasis = currentLot['costBasis']!;

          if (lotShares <= sharesToSell + 1e-12) {
            portfolioAccountValueDelta -= lotShares * lotCostBasis;
            sharesToSell -= lotShares;
            fifoCopyForCalc.removeFirst();
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

      // 6) Ensure update does not lead to inconsistent balance history (same as before)
      if (await db.accountsDao.leadsToInconsistentBalanceHistory(
          originalTrade: originalTrade, newTrade: updatedTrade)) {
        throw Exception(l10n.updateWouldBreakAccountBalanceHistory);
      }

      // 7) Undo ONLY the original trade's numeric effects (we will reapply updated trade and let
      //    the global recalculation handle subsequent trades/transfers/bookings).
      final allTradesAsc = await loadTradesForAssetAndAccount(
          originalTrade.assetId, originalTrade.targetAccountId);
      await undoTradeFromDb(originalTrade, allTradesAsc);

      // 8) Build FIFO prefix **up to the updated trade key** (this is the correct prefix for applying the updated trade)
      final fifoForApply = await db.assetsOnAccountsDao.buildFiFoQueue(
        originalTrade.assetId,
        originalTrade.targetAccountId,
        upToDatetime: dt2,
        upToType: t2,
        upToId: id2,
      );

      // 9) Validate updatedTrade if it is a sell (simulate on fifo copy built for apply)
      if (updatedTrade.type.value == TradeTypes.sell) {
        var sharesToSell = updatedTrade.shares.value;
        final fifoCopy = ListQueue<Map<String, double>>.from(
            fifoForValidation.map((e) => Map<String, double>.from(e)));
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
          throw Exception(l10n.updateWouldBreakAccountBalanceHistory);
        }
      }

      // 10) Apply updated trade (update existing row) using fifoForApply so all numeric deltas are computed & written
      await applyTradeToDb(updatedTrade,
          insertNew: false, updateTradeId: tradeId, fifo: fifoForApply);

      // 11) Recalculate subsequent events (bookings/transfers/trades) that come AFTER the updated trade
      // Use ordering key just after updated trade so that the updated trade is considered part of
      // the prefix in the recalc and subsequent events are processed.
      final recalcUpToId = tradeId + 1;
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

  Future<void> deleteTrade(int tradeId, AppLocalizations l10n) {
    return db.transaction(() async {
      // 1) Load original trade
      final original = await (select(trades)..where((t) => t.id.equals(tradeId)))
          .getSingle();

      final assetId = original.assetId;
      final accountId = original.targetAccountId;

      // earliestKey = original's key
      final oldDt = original.datetime;
      final oldTypeStr = original.type.name;
      final oldId = original.id;

      // 2) Undo only the original trade's numeric effects (use full chronological context)
      final allTradesAsc = await loadTradesForAssetAndAccount(assetId, accountId);
      await undoTradeFromDb(original, allTradesAsc);

      // 3) Delete the original trade row
      await (delete(trades)..where((t) => t.id.equals(tradeId))).go();

      // 4) Recalculate everything that comes AFTER the original trade key.
      // Use the original trade key as the ordering cutoff so events with key < originalKey are part of the prefix.
      await db.assetsOnAccountsDao.recalculateSubsequentEvents(
        l10n: l10n,
        assetId: assetId,
        accountId: accountId,
        upToDatetime: oldDt,
        upToType: oldTypeStr,
        upToId: oldId,
      );
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
  Future<List<Trade>> loadTradesForAssetAndAccount(
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
