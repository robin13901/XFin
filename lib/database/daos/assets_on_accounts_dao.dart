import 'dart:collection';

import 'package:drift/drift.dart';
import 'package:xfin/l10n/app_localizations.dart';
import '../../utils/global_constants.dart';
import '../app_database.dart';
import '../tables.dart';

part 'assets_on_accounts_dao.g.dart';

@DriftAccessor(
    tables: [AssetsOnAccounts, Accounts, Assets, Trades, Bookings, Transfers])
class AssetsOnAccountsDao extends DatabaseAccessor<AppDatabase>
    with _$AssetsOnAccountsDaoMixin {
  AssetsOnAccountsDao(super.db);

  Future<int> addAssetOnAccount(AssetsOnAccountsCompanion entry) =>
      into(assetsOnAccounts).insert(entry);

  Future<bool> _updateAssetOnAccount(AssetsOnAccountsCompanion entry) =>
      update(assetsOnAccounts).replace(entry);

  Future<AssetOnAccount> getAOA(int accountId, int assetId) {
    return (select(assetsOnAccounts)
          ..where(
              (a) => a.accountId.equals(accountId) & a.assetId.equals(assetId)))
        .getSingle();
  }

  Future<int> deleteAOA(AssetOnAccount aoa) =>
      db.delete(db.assetsOnAccounts).delete(aoa);

  Future<void> updateAOA(AssetOnAccount aoaWithDeltas) async {
    AssetOnAccount existingAOA = await ensureAssetOnAccountExists(
        aoaWithDeltas.assetId, aoaWithDeltas.accountId);

    double newShares = existingAOA.shares + aoaWithDeltas.shares;
    double newValue =
        existingAOA.value + aoaWithDeltas.value;
    double newBuyFeeTotal = existingAOA.buyFeeTotal + aoaWithDeltas.buyFeeTotal;
    double newNetCostBasis = newShares == 0 ? 1 : newValue / newShares;
    double newBrokerCostBasis =
        newShares == 0 ? 1 : (newValue + newBuyFeeTotal) / newShares;

    AssetOnAccount modifiedAOA = existingAOA.copyWith(
        shares: normalize(newShares),
        value: normalize(newValue),
        buyFeeTotal: normalize(newBuyFeeTotal),
        netCostBasis: normalize(newNetCostBasis),
        brokerCostBasis: normalize(newBrokerCostBasis));

    await _updateAssetOnAccount(modifiedAOA.toCompanion(false));
  }

  Future<AssetOnAccount> ensureAssetOnAccountExists(
      int assetId, int accountId) async {
    var assetOnAccount = await (select(assetsOnAccounts)
          ..where(
              (a) => a.assetId.equals(assetId) & a.accountId.equals(accountId)))
        .getSingleOrNull();

    if (assetOnAccount == null) {
      await into(assetsOnAccounts).insert(AssetsOnAccountsCompanion.insert(
          assetId: assetId, accountId: accountId));
      assetOnAccount = await (select(assetsOnAccounts)
            ..where((a) =>
                a.assetId.equals(assetId) & a.accountId.equals(accountId)))
          .getSingle();
    }

    return assetOnAccount;
  }

  Future<void> updateBaseCurrencyAOA(int accountId, double amountDelta) async {
    await updateAOA(AssetOnAccount(
      accountId: accountId,
      assetId: 1,
      value: amountDelta,
      shares: amountDelta,
      netCostBasis: 0,
      brokerCostBasis: 0,
      buyFeeTotal: 0,
    ));
  }

  Future<List<AssetOnAccount>> getAOAsForAccount(int accountId) async {
    return (select(assetsOnAccounts)
          ..where((a) => a.accountId.equals(accountId)))
        .get();
  }

  /// Build a FIFO queue for (assetId, accountId) that accounts for:
  /// - trades (buys/sells)
  /// - bookings
  /// - transfers
  /// - the initial AssetsOnAccounts row (reverse engineered from current snapshot)
  ///
  /// The returned queue represents the lot state *before* the ordering key:
  /// ordering key = (upToDatetime, upToType, upToId).
  /// Events with key < orderingKey are included, events with key >= orderingKey are considered "after".
  ///
  /// If upToDatetime/upToType/upToId are omitted, the queue for the full history is returned.
  Future<ListQueue<Map<String, double>>> buildFiFoQueue(
    int assetId,
    int accountId, {
    Booking? oldBooking,
    Transfer? oldTransfer,
    int? upToDatetime,
    String? upToType,
    int? upToId,
  }) async {
    int cmpKey(int dtA, String typeA, int idA, int dtB, String typeB, int idB) {
      if (dtA != dtB) return dtA < dtB ? -1 : 1;
      final tc = typeA.compareTo(typeB);
      if (tc != 0) return tc < 0 ? -1 : 1;
      if (idA != idB) return idA < idB ? -1 : 1;
      return 0;
    }

    // 0) Current aggregated AOA row
    final initialAOA = await ensureAssetOnAccountExists(
        assetId, accountId); //await getAOA(accountId, assetId);
    double initialShares = initialAOA.shares;
    double initialValue = initialAOA.value;
    double initialBuyFeeTotal = initialAOA.buyFeeTotal;

    // 1) Collect raw events
    final tradeRows = await (select(trades)
          ..where((t) =>
              t.assetId.equals(assetId) &
              ((t.targetAccountId.equals(accountId)) |
                  (t.sourceAccountId.equals(accountId)))))
        .get();

    final bookingRows = await (select(bookings)
          ..where(
              (b) => b.assetId.equals(assetId) & b.accountId.equals(accountId)))
        .get();

    final transferRows = await (select(transfers)
          ..where((tr) =>
              tr.assetId.equals(assetId) &
              ((tr.receivingAccountId.equals(accountId)) |
                  (tr.sendingAccountId.equals(accountId)))))
        .get();

    // 2) Build unified events list
    final events = <Map<String, dynamic>>[];

    for (final t in tradeRows) {
      final isInflow = t.type == TradeTypes.buy;
      var value = t.shares * t.costBasis;
      initialShares += isInflow ? -t.shares : t.shares;
      initialValue += isInflow ? -value : value;
      events.add({
        'datetime': t.datetime,
        'typeStr': t.type.name,
        'id': t.id,
        'in': isInflow,
        'shares': t.shares,
        'costBasis': t.costBasis,
        'fee': t.fee,
      });
    }

    for (final b in bookingRows) {
      initialShares -= b.shares;
      initialValue -= b.value;
      if (oldBooking != null && b.id == oldBooking.id) continue;
      final datetime = b.date * 1000000;
      events.add({
        'datetime': datetime,
        'typeStr': '_booking',
        'id': 0,
        'in': b.shares > 0,
        'shares': b.shares.abs(),
        'costBasis': b.costBasis,
        'fee': 0.0,
      });
    }

    for (var tr in transferRows) {
      final isInflow = tr.receivingAccountId == accountId;
      initialShares += isInflow ? -tr.shares : tr.shares;
      initialValue += isInflow ? -tr.value : tr.value;
      if (oldTransfer != null && tr.id == oldTransfer.id) continue;
      final datetime = tr.date * 1000000;
      events.add({
        'datetime': datetime,
        'typeStr': '_transfer',
        'id': tr.id,
        'in': isInflow,
        'shares': tr.shares,
        'costBasis': tr.costBasis,
        'fee': 0.0,
      });
    }

    // 3) Partition events
    final keyDt = upToDatetime ?? 99999999999999;
    final keyType = upToType ?? '\uFFFF';
    final keyId = upToId ?? 999999999;

    final eventsBefore = <Map<String, dynamic>>[];
    final eventsAfter = <Map<String, dynamic>>[];

    for (final e in events) {
      final cmp = cmpKey(
        e['datetime'] as int,
        e['typeStr'] as String,
        e['id'] as int,
        keyDt,
        keyType,
        keyId,
      );
      if (cmp < 0) {
        eventsBefore.add(e);
      } else {
        eventsAfter.add(e);
      }
    }

    if (initialShares.abs() > 1e-12) {
      eventsBefore.add({
        'datetime': 0,
        'typeStr': 'initial',
        'id': 0,
        'in': true,
        'shares': initialShares,
        'costBasis':
            initialShares.abs() > 1e-12 ? initialValue / initialShares : 0.0,
        'fee': initialBuyFeeTotal,
      });
    }

    // 4) Sort
    eventsBefore.sort((a, b) => cmpKey(
          a['datetime'] as int,
          a['typeStr'] as String,
          a['id'] as int,
          b['datetime'] as int,
          b['typeStr'] as String,
          b['id'] as int,
        ));

    // 5) Build FIFO queue
    final fifo = ListQueue<Map<String, double>>();

    for (final e in eventsBefore) {
      final inFlow = e['in'] as bool;
      final shares = (e['shares'] as num).toDouble();
      final costBasis = (e['costBasis'] as num).toDouble();
      final fee = (e['fee'] as num).toDouble();

      if (inFlow) {
        fifo.add({'shares': shares, 'costBasis': costBasis, 'fee': fee});
      } else {
        var remaining = shares;
        while (remaining > 0 && fifo.isNotEmpty) {
          final lot = fifo.first;
          if (lot['shares']! <= remaining + 1e-12) {
            remaining -= lot['shares']!;
            fifo.removeFirst();
          } else {
            var originalLotShares = lot['shares']!;
            lot['shares'] = lot['shares']! - remaining;
            lot['fee'] = lot['fee']! * (lot['shares']! / originalLotShares);
            remaining = 0;
          }
        }
      }
    }

    return fifo;
  }

  // --- NEW -------------------------------------------------------------------

  int cmpKey(int dtA, String typeA, int idA, int dtB, String typeB, int idB) {
    if (dtA != dtB) return dtA < dtB ? -1 : 1;
    final tc = typeA.compareTo(typeB);
    if (tc != 0) return tc < 0 ? -1 : 1;
    if (idA != idB) return idA < idB ? -1 : 1;
    return 0;
  }

  int _compareEvents(_RecalcEvent a, _RecalcEvent b) {
    return cmpKey(a.datetime, a.typeStr, a.id, b.datetime, b.typeStr, b.id);
  }

// ----------------------------
// Public entrypoint
// ----------------------------
// upToDatetime/upToType/upToId define the ordering key such that events with
// key < orderingKey are considered "before" and events with key >= orderingKey
// are "after" (and therefore should be recalculated).
  Future<void> recalculateSubsequentEvents({
    required AppLocalizations l10n,
    required int assetId,
    required int accountId,
    required int upToDatetime, // yyyyMMddhhmmss
    required String upToType, // '_booking' | '_transfer' | 'buy' | 'sell'
    required int upToId,
  }) {
    return transaction(() async {
      final visited = <String>{};
      final accounts = await _recalculateInternal(
        l10n: l10n,
        assetId: assetId,
        accountId: accountId,
        upToDatetime: upToDatetime,
        upToType: upToType,
        upToId: upToId,
        visited: visited,
        accounts: {},
        initialFifo: null,
      );

      for (final accountId in accounts) {
        final inconsistent = await db.accountsDao.isInconsistent(accountId);
        if (inconsistent) {
          throw Exception(l10n.actionCancelledDueToDataInconsistency);
        }
      }
    });
  }

// ----------------------------
// Core recursive worker
// ----------------------------
  Future<Set<int>> _recalculateInternal({
    required AppLocalizations l10n,
    required int assetId,
    required int accountId,
    required int upToDatetime, // ordering key
    required String upToType,
    required int upToId,
    required Set<String> visited,
    required Set<int> accounts,
    ListQueue<Map<String, double>>?
        initialFifo, // optional pre-built FIFO for receiver recursion
  }) async {
    // No need to recalculate base currency events
    if (assetId == 1) accounts;

    // visited key should include the ordering key to prevent reprocessing same startpoint
    final visitKey = '$assetId|$accountId|$upToDatetime|$upToType|$upToId';
    if (visited.contains(visitKey)) return accounts;
    visited.add(visitKey);
    accounts.add(accountId);

    // 1) Build or use provided FIFO prefix
    final fifo = initialFifo ??
        await buildFiFoQueue(
          assetId,
          accountId,
          upToDatetime: upToDatetime,
          upToType: upToType,
          upToId: upToId,
        );

    // 2) Collect candidate events (loose filter) and then tightly partition using cmpKey
    final events = <_RecalcEvent>[];

    // bookings candidate: date >= upToDate (coarse)
    final upToDate = upToDatetime ~/ 1000000;
    final bookingsCandidates = await (select(bookings)
          ..where((b) =>
              b.assetId.equals(assetId) &
              b.accountId.equals(accountId) &
              b.date.isBiggerOrEqualValue(upToDate)))
        .get();
    for (final b in bookingsCandidates) {
      final e = _RecalcEvent.booking(b);
      if (cmpKey(e.datetime, e.typeStr, e.id, upToDatetime, upToType, upToId) >
          0) {
        events.add(e);
      }
    }

    // transfers candidate: date >= upToDate (coarse)
    final transfersCandidates = await (select(transfers)
          ..where((t) =>
              t.assetId.equals(assetId) &
              (t.sendingAccountId.equals(accountId) |
                  t.receivingAccountId.equals(accountId)) &
              t.date.isBiggerOrEqualValue(upToDate)))
        .get();
    for (final t in transfersCandidates) {
      final e = _RecalcEvent.transfer(t);
      if (cmpKey(e.datetime, e.typeStr, e.id, upToDatetime, upToType, upToId) >
          0) {
        events.add(e);
      }
    }

    // trades candidate: load chronological full list for asset/account and filter
    final allTradesAsc =
        await db.tradesDao.loadTradesForAssetAndAccount(assetId, accountId);
    for (final t in allTradesAsc) {
      final e = _RecalcEvent.trade(t);
      if (cmpKey(e.datetime, e.typeStr, e.id, upToDatetime, upToType, upToId) >
          0) {
        events.add(e);
      }
    }

    // 3) Sort events in canonical chronological order
    events.sort(_compareEvents);

    // 4) Undo trades (reverse chronological)
    final tradesToUndo = events
        .where((e) => e.type == _RecalcEventType.trade)
        .map((e) => e.trade!)
        .toList();
    tradesToUndo.sort((a, b) => b.datetime.compareTo(a.datetime));

    if (tradesToUndo.isNotEmpty) {
      for (final t in tradesToUndo) {
        await db.tradesDao.undoTradeFromDb(t);
      }
    }

    // 5) Replay all events forward, mutating fifo and updating rows as needed
    for (final event in events) {
      if (event.type == _RecalcEventType.booking) {
        final b = event.booking!;
        // Check key again here, because we might have already recalculated this one in a previous recursion
        final visitKey =
            '$assetId|$accountId|${b.date * 1000000}|_booking|${b.id}';
        if (visited.contains(visitKey)) return accounts;
        visited.add(visitKey);
        accounts.add(accountId);
        final shares = b.shares;
        if (shares > 0) {
          fifo.add({
            'shares': shares,
            'costBasis': b.costBasis,
            'fee': 0.0
          }); // TODO: ich glaub hier muss noch updateAOA gecallt werden...
        } else if (shares < 0) {
          var remaining = -shares;
          double removedShares = 0.0;
          double removedCost = 0.0;
          while (remaining > 1e-12 && fifo.isNotEmpty) {
            final lot = fifo.first;
            final lotShares = lot['shares']!;
            final take = lotShares <= remaining + 1e-12 ? lotShares : remaining;
            removedShares += take;
            removedCost += take * lot['costBasis']!;
            if (lotShares <= remaining + 1e-12) {
              fifo.removeFirst();
            } else {
              lot['shares'] = lotShares - take;
            }
            remaining -= take;
          }

          final newCostBasis =
              removedShares > 1e-12 ? removedCost / removedShares : b.costBasis;

          if ((b.costBasis - newCostBasis).abs() > 1e-9) {
            final oldValue =
                (await db.bookingsDao.getBooking(b.id)).value; //b.value;
            final newValue = newCostBasis * b.shares;

            // Persist booking with new computed values
            await (update(bookings)..where((tbl) => tbl.id.equals(b.id))).write(
              BookingsCompanion(
                costBasis: Value(newCostBasis),
                value: Value(newValue),
              ),
            );

            // Apply deltas to snapshot rows: account balance, AOA, and global asset
            final valueDelta = newValue - oldValue;

            // 1) account balance: booking previously contributed oldValue, now must contribute newValue -> delta
            await db.accountsDao.updateBalance(b.accountId, valueDelta);

            // 2) assetsOnAccounts: adjust the value (shares are unchanged for a booking that only changed costBasis)
            await updateAOA(AssetOnAccount(
              accountId: b.accountId,
              assetId: assetId,
              value: valueDelta,
              shares: 0,
              netCostBasis: 0,
              brokerCostBasis: 0,
              buyFeeTotal: 0,
            ));

            // 3) global asset totals must also reflect booking value change
            await db.assetsDao.updateAsset(assetId, 0, valueDelta, 0);

            // Update the in-memory event object so later code in this loop sees updated values
            // b = b.copyWith(costBasis: newCostBasis, value: newValue);
          }
        } // else shares == 0 -> ignore
      } else if (event.type == _RecalcEventType.transfer) {
        final tr = event.transfer!;
        // Check key again here, because we might have already recalculated this one in a previous recursion
        final visitKey =
            '$assetId|$accountId|${tr.date * 1000000}|_transfer|${tr.id}';
        if (visited.contains(visitKey)) return accounts;
        visited.add(visitKey);
        accounts.add(accountId);
        final isInflow = tr.receivingAccountId == accountId;
        if (isInflow) {
          // incoming transfer: rely on transfer.costBasis (should have been set by sending-side),
          // but if zero/fallback, still add with stored costBasis.
          fifo.add(
              {'shares': tr.shares, 'costBasis': tr.costBasis, 'fee': 0.0});
        } else {
          // sending side: consume FIFO and write transfer.costBasis, then propagate to receiver
          var remaining = tr.shares;
          double removedShares = 0.0;
          double removedCost = 0.0;
          while (remaining > 1e-12 && fifo.isNotEmpty) {
            final lot = fifo.first;
            final lotShares = lot['shares']!;
            final take = lotShares <= remaining + 1e-12 ? lotShares : remaining;
            removedShares += take;
            removedCost += take * lot['costBasis']!;
            if (lotShares <= remaining + 1e-12) {
              fifo.removeFirst();
            } else {
              lot['shares'] = lotShares - take;
            }
            remaining -= take;
          }

          final newCostBasis = removedShares > 1e-12
              ? removedCost / removedShares
              : tr.costBasis;

          if ((tr.costBasis - newCostBasis).abs() > 1e-9) {
            final oldValue =
                (await db.transfersDao.getTransfer(tr.id)).value; //tr.value;
            final newValue = newCostBasis * tr.shares;

            await (update(transfers)..where((tbl) => tbl.id.equals(tr.id)))
                .write(
              TransfersCompanion(
                costBasis: Value(newCostBasis),
                value: Value(newValue),
              ),
            );

            // Apply deltas to snapshot rows:
            final valueDelta =
                newValue - oldValue; // positive if newValue > oldValue

            final sendingId = tr.sendingAccountId;
            final receivingId = tr.receivingAccountId;

            // 1) Account balances: sending had -oldValue, should have -newValue => adjust by -delta
            await db.accountsDao.updateBalance(sendingId, -valueDelta);
            // receiving had +oldValue, should have +newValue => adjust by +delta
            await db.accountsDao.updateBalance(receivingId, valueDelta);

            // 2) AssetsOnAccounts: subtract valueDelta from sender, add to receiver (shares unchanged)
            await db.assetsOnAccountsDao.updateAOA(AssetOnAccount(
              accountId: sendingId,
              assetId: assetId,
              value: -valueDelta,
              shares: 0,
              netCostBasis: 0,
              brokerCostBasis: 0,
              buyFeeTotal: 0,
            ));

            await db.assetsOnAccountsDao.updateAOA(AssetOnAccount(
              accountId: receivingId,
              assetId: assetId,
              value: valueDelta,
              shares: 0,
              netCostBasis: 0,
              brokerCostBasis: 0,
              buyFeeTotal: 0,
            ));

            // No change to global assets table for intra-account transfer values.

            // Update the in-memory event/tr so subsequent code sees new values
            // tr = tr.copyWith(costBasis: newCostBasis, value: newValue);
          }

          // Build receiver FIFO prefix up to *before* this transfer, then add incoming lot and recurse.
          final recvId = tr.receivingAccountId;
          final recvUpToDt = event.datetime - 1; // just before transfer
          final recvFifo = await buildFiFoQueue(
            assetId,
            recvId,
            upToDatetime: recvUpToDt,
            upToType: '_transfer',
            upToId: tr.id,
          );
          // add incoming lot
          recvFifo.add(
              {'shares': tr.shares, 'costBasis': newCostBasis, 'fee': 0.0});

          // recurse for receiver, starting at this transfer's key (so receiver will process events after transfer)
          await _recalculateInternal(
            l10n: l10n,
            assetId: assetId,
            accountId: recvId,
            upToDatetime: event.datetime,
            upToType: '_transfer',
            upToId: tr.id,
            visited: visited,
            accounts: accounts,
            initialFifo: recvFifo,
          );

          // break;
        }
      } else {
        // trade: reapply using your existing _applyTradeToDb helper.
        final t = event.trade!;

        // Check key again here, because we might have already recalculated this one in a previous recursion
        final visitKey = '$assetId|$accountId|${t.datetime}|_trade|${t.id}';
        if (visited.contains(visitKey)) return accounts;
        visited.add(visitKey);
        accounts.add(t.sourceAccountId);
        accounts.add(t.targetAccountId);

        final companion = t.toCompanion(false);

        // Re-apply trade (update existing row). This will mutate FIFO and update aggregates.
        await db.tradesDao.applyTradeToDb(companion, fifo,);
      }
      accounts.add(accountId);
    } // end for events
    return accounts;
  }
}

// --- small helper types for unified event handling ---
enum _RecalcEventType { booking, transfer, trade }

class _RecalcEvent {
  final _RecalcEventType type;
  final int datetime; // yyyyMMddHHmmss
  final String typeStr; // '_booking', '_transfer', 'buy'/'sell'
  final int id;

  final Booking? booking;
  final Transfer? transfer;
  final Trade? trade;

  _RecalcEvent.booking(this.booking)
      : type = _RecalcEventType.booking,
        datetime = booking!.date * 1000000,
        typeStr = '_booking',
        id = booking.id,
        transfer = null,
        trade = null;

  _RecalcEvent.transfer(this.transfer)
      : type = _RecalcEventType.transfer,
        datetime = transfer!.date * 1000000,
        typeStr = '_transfer',
        id = transfer.id,
        booking = null,
        trade = null;

  _RecalcEvent.trade(this.trade)
      : type = _RecalcEventType.trade,
        datetime = trade!.datetime,
        typeStr = trade.type.name,
        id = trade.id,
        booking = null,
        transfer = null;
}
