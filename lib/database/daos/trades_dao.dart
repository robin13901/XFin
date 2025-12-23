import 'dart:collection';

import 'package:drift/drift.dart';
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
      shares: Value(newAoaShares),
      value: Value(newAoaValue),
      buyFeeTotal: Value(newAoaBuyFee),
      netCostBasis: Value(newAoaShares > 0 ? newAoaValue / newAoaShares : 0),
      brokerCostBasis: Value(
          newAoaShares > 0 ? (newAoaValue + newAoaBuyFee) / newAoaShares : 0),
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
      shares: Value(newAssetShares),
      value: Value(newAssetValue),
      buyFeeTotal: Value(newAssetBuyFee),
      netCostBasis:
          Value(newAssetShares > 0 ? newAssetValue / newAssetShares : 0),
      brokerCostBasis: Value(newAssetShares > 0
          ? (newAssetValue + newAssetBuyFee) / newAssetShares
          : 0),
    ));

    // Undo account balances
    final sourceAcc = await (select(accounts)
          ..where((a) => a.id.equals(t.sourceAccountId)))
        .getSingle();
    await (update(accounts)..where((a) => a.id.equals(t.sourceAccountId)))
        .write(
      AccountsCompanion(
          balance: Value(sourceAcc.balance - t.sourceAccountValueDelta)),
    );

    final targetAcc = await (select(accounts)
          ..where((a) => a.id.equals(t.targetAccountId)))
        .getSingle();
    await (update(accounts)..where((a) => a.id.equals(t.targetAccountId)))
        .write(
      AccountsCompanion(
          balance: Value(targetAcc.balance - t.targetAccountValueDelta)),
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
      ListQueue<Map<String, double>>? fifoParam}) async {
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

      if (fifoParam != null) {
        fifoParam.add({'shares': shares, 'costBasis': costBasis, 'fee': fee});
      }

      updatedAOAShares = assetOnAccount.shares + shares;
      updatedAOABuyFeeTotal = assetOnAccount.buyFeeTotal + fee;

      updatedAssetShares = asset.shares + shares;
      updatedAssetBuyFeeTotal = asset.buyFeeTotal + fee;
    } else {
      // SELL
      final fifo = fifoParam ??
          await db.assetsOnAccountsDao.buildFiFoQueue(assetId, targetAccountId);

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
      var newTrade = insertNew ? entry.copyWith(
          sourceAccountValueDelta: Value(sourceAccountValueDelta),
          targetAccountValueDelta: Value(targetAccountValueDelta)) : null;
      if (await db.accountsDao
          .leadsToInconsistentBalanceHistory(
          newTrade: newTrade)) {
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
      shares: Value(updatedAOAShares),
      value: Value(updatedAOAValue),
      buyFeeTotal: Value(updatedAOABuyFeeTotal),
      netCostBasis:
          Value(updatedAOAShares > 0 ? updatedAOAValue / updatedAOAShares : 0),
      brokerCostBasis: Value(updatedAOAShares > 0
          ? (updatedAOAValue + updatedAOABuyFeeTotal) / updatedAOAShares
          : 0),
    ));

    // Update Asset totals
    updatedAssetValue = asset.value + targetAccountValueDelta;
    await (update(assets)..where((a) => a.id.equals(assetId)))
        .write(AssetsCompanion(
      shares: Value(updatedAssetShares),
      value: Value(updatedAssetValue),
      buyFeeTotal: Value(updatedAssetBuyFeeTotal),
      netCostBasis: Value(
          updatedAssetShares > 0 ? updatedAssetValue / updatedAssetShares : 0),
      brokerCostBasis: Value(updatedAssetShares > 0
          ? (updatedAssetValue + updatedAssetBuyFeeTotal) / updatedAssetShares
          : 0),
    ));

    // Base currency adjustments
    await db.assetsOnAccountsDao.updateBaseCurrencyAssetOnAccount(
        sourceAccountId, sourceAccountValueDelta);
    await db.assetsDao
        .updateAsset(1, sourceAccountValueDelta, sourceAccountValueDelta);

    // Insert or update trade row
    if (insertNew) {
      final tradeWithCalculatedValues = entry.copyWith(
        sourceAccountValueDelta: Value(sourceAccountValueDelta),
        targetAccountValueDelta: Value(targetAccountValueDelta),
        profitAndLoss: Value(profitAndLoss),
        returnOnInvest: Value(returnOnInvest),
      );
      await into(trades).insert(tradeWithCalculatedValues);
    } else {
      if (updateTradeId == null) {
        throw Exception('updateTradeId required when insertNew is false');
      }
      await (update(trades)..where((t) => t.id.equals(updateTradeId)))
          .write(TradesCompanion(
        sourceAccountValueDelta: Value(sourceAccountValueDelta),
        targetAccountValueDelta: Value(targetAccountValueDelta),
        profitAndLoss: Value(profitAndLoss),
        returnOnInvest: Value(returnOnInvest),
      ));
    }

    // Update account balances
    final clearingAccount = await (select(accounts)
          ..where((a) => a.id.equals(sourceAccountId)))
        .getSingle();
    await (update(accounts)..where((a) => a.id.equals(sourceAccountId))).write(
      AccountsCompanion(
          balance: Value(clearingAccount.balance + sourceAccountValueDelta)),
    );

    final portfolioAccount = await (select(accounts)
          ..where((a) => a.id.equals(targetAccountId)))
        .getSingle();
    await (update(accounts)..where((a) => a.id.equals(targetAccountId))).write(
      AccountsCompanion(
          balance: Value(portfolioAccount.balance + targetAccountValueDelta)),
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
      await _applyTradeToDb(newEntry, insertNew: true, fifoParam: fifo);

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
            insertNew: false, updateTradeId: t.id, fifoParam: fifo);
      }
    });
  }

  // ----------------------------
  // PUBLIC API: updateTrade (replaces processBackdatedUpdate)
  // ----------------------------
  Future<void> updateTrade(int tradeId, TradesCompanion updatedFields) {
    return db.transaction(() async {
      final original = await (select(trades)
            ..where((t) => t.id.equals(tradeId)))
          .getSingle();

      // Merge helper
      Value<T> merge<T>(Value<T>? v, T orig) =>
          (v != null && v.present) ? v : Value(orig);

      final merged = TradesCompanion(
        datetime: merge<int>(updatedFields.datetime, original.datetime),
        assetId: Value(original.assetId),
        sourceAccountId: Value(original.sourceAccountId),
        targetAccountId: Value(original.targetAccountId),
        type: Value(original.type),
        shares: merge<double>(updatedFields.shares, original.shares),
        costBasis: merge<double>(updatedFields.costBasis, original.costBasis),
        fee: merge<double>(updatedFields.fee, original.fee),
        tax: merge<double>(updatedFields.tax, original.tax),
      );

      final assetId = original.assetId;
      final accountId = original.targetAccountId;

      // compute earliestKey
      final oldDt = original.datetime;
      final oldTypeStr = _typeString(original.type);
      final oldId = original.id;

      final newDt = merged.datetime.value;
      final newTypeStr = _typeString(merged.type.value);
      final newId = oldId; // keep same id for ordering comparisons

      final earliestIsNew =
          cmpKey(newDt, newTypeStr, newId, oldDt, oldTypeStr, oldId) < 0;
      final earliestDt = earliestIsNew ? newDt : oldDt;
      final earliestType = earliestIsNew ? newTypeStr : oldTypeStr;
      final earliestId = earliestIsNew ? newId : oldId;

      // // 1) Balance timeline check
      // final inconsistent = await db.accountsDao
      //     .leadsToInconsistentBalanceHistory(
      //         originalBooking: null, newTrade: merged);
      // if (inconsistent)
      //   throw Exception('Edit would break account balance history.');

      // 2) Build FIFO prefix using AOA builder up to earliestKey (includes bookings/transfers)
      final fifo = await db.assetsOnAccountsDao.buildFiFoQueue(
        assetId,
        accountId,
        upToDatetime: earliestDt,
        upToType: earliestType,
        upToId: earliestId,
      );

      // 3) Fetch candidate trades with datetime >= earliestDt (only these can be undone)
      final candidateTrades = await (select(trades)
            ..where((t) =>
                t.assetId.equals(assetId) &
                t.datetime.isBiggerOrEqualValue(earliestDt))
            ..orderBy([
              (t) => OrderingTerm(expression: t.datetime),
              (t) => OrderingTerm(expression: t.type),
              (t) => OrderingTerm(expression: t.id),
            ]))
          .get();

      // 4) Partition into tradesBefore (in the candidate set that are actually before earliestKey) and tradesToUndo (>= earliestKey)
      final tradesBefore = <Trade>[];
      final tradesToUndo = <Trade>[];

      for (final t in candidateTrades) {
        final tTypeStr = _typeString(t.type);
        final cmp = cmpKey(
            t.datetime, tTypeStr, t.id, earliestDt, earliestType, earliestId);
        if (cmp < 0) {
          tradesBefore.add(t);
        } else {
          tradesToUndo.add(t);
        }
      }

      // Ensure original is in tradesToUndo
      if (!tradesToUndo.any((t) => t.id == tradeId)) {
        tradesToUndo.add(original);
        tradesToUndo.sort((a, b) {
          final ta = _typeString(a.type);
          final tb = _typeString(b.type);
          return cmpKey(a.datetime, ta, a.id, b.datetime, tb, b.id);
        });
      }

      // 5) Undo tradesToUndo in reverse chronological order (we need the full chronological context for fee undo)
      final allTradesAsc =
          await _loadTradesForAssetAndAccount(assetId, accountId);
      for (final t in tradesToUndo.reversed) {
        await _undoTradeFromDb(t, allTradesAsc);
      }

      // 6) Rebuild the FIFO from tradesBefore using the AOA builder (this is effectively identical to 'fifo' above,
      // but if tradesBefore contains some trades that are not represented in the AOA builder prefix we rely on the builder anyway)
      // (we already built fifo up to earliestKey; we will use it as the prefix to reapply)
      // 7) Build the reapply list: tradesToUndo without original + merged inserted in correct spot
      final toReapplyBase = tradesToUndo.where((t) => t.id != tradeId).toList();

      int insertIndex = toReapplyBase.indexWhere((existing) {
        final existingTypeStr = _typeString(existing.type);
        final cmpExistingVsMerged = cmpKey(existing.datetime, existingTypeStr,
            existing.id, newDt, newTypeStr, newId);
        return cmpExistingVsMerged > 0;
      });
      if (insertIndex < 0) insertIndex = toReapplyBase.length;

      final reapplyEntries = <_ReapplyEntry>[];
      for (int i = 0; i < toReapplyBase.length + 1; i++) {
        if (i == insertIndex) {
          reapplyEntries.add(
              _ReapplyEntry(companion: merged, isMerged: true, id: tradeId));
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

      // 8) Validate merged if it is a sell (simulate on a copy)
      if (merged.type.value == TradeTypes.sell) {
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
              throw Exception(
                  'Not enough shares to process this edited sell at its new position.');
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
                throw Exception(
                    'Existing trade sequence invalid during validation.');
              }
            }
          }
        }
      }

      // 9) Reapply all entries in order using the same fifo instance.
      for (final entry in reapplyEntries) {
        if (entry.isMerged) {
          await _applyTradeToDb(entry.companion,
              insertNew: false, updateTradeId: entry.id, fifoParam: fifo);
        } else {
          await _applyTradeToDb(entry.companion,
              insertNew: false, updateTradeId: entry.id, fifoParam: fifo);
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
            insertNew: false, updateTradeId: t.id, fifoParam: fifo);
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
}

/// small container used in reapply stage
class _ReapplyEntry {
  final TradesCompanion companion;
  final bool isMerged;
  final int id;

  _ReapplyEntry(
      {required this.companion, required this.isMerged, required this.id});
}
