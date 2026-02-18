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

  Future<int> _insert(AssetsOnAccountsCompanion entry) =>
      into(assetsOnAccounts).insert(entry);

  Future<bool> _update(AssetsOnAccountsCompanion entry) =>
      update(assetsOnAccounts).replace(entry);

  Future<int> deleteAOA(AssetOnAccount aoa) =>
      db.delete(db.assetsOnAccounts).delete(aoa);

  Future<AssetOnAccount> getAOA(int accountId, int assetId) {
    return (select(assetsOnAccounts)
          ..where(
              (a) => a.accountId.equals(accountId) & a.assetId.equals(assetId)))
        .getSingle();
  }

  Future<void> updateAOA(AssetOnAccount aoaWithDeltas) async {
    AssetOnAccount existingAOA = await ensureAssetOnAccountExists(
        aoaWithDeltas.assetId, aoaWithDeltas.accountId);

    double newShares = existingAOA.shares + aoaWithDeltas.shares;
    double newValue = existingAOA.value + aoaWithDeltas.value;
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

    await _update(modifiedAOA.toCompanion(false));
  }

  Future<AssetOnAccount> ensureAssetOnAccountExists(
      int assetId, int accountId) async {
    var assetOnAccount = await (select(assetsOnAccounts)
          ..where(
              (a) => a.assetId.equals(assetId) & a.accountId.equals(accountId)))
        .getSingleOrNull();

    if (assetOnAccount == null) {
      await _insert(AssetsOnAccountsCompanion.insert(assetId: assetId, accountId: accountId));
      assetOnAccount = await getAOA(accountId, assetId);
    }

    return assetOnAccount;
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
    final initialAOA = await ensureAssetOnAccountExists(assetId, accountId);
    double initialShares = initialAOA.shares;
    double initialValue = initialAOA.value;
    double initialBuyFeeTotal = initialAOA.buyFeeTotal;

    final bookingsFuture = db.bookingsDao.getBookingsForAOA(assetId, accountId);
    final tradesFuture = db.tradesDao.getTradesForAOA(assetId, accountId);
    final transfersFuture =
    db.transfersDao.getTransfersForAOA(assetId, accountId);

    final bookings = await bookingsFuture;
    final trades = await tradesFuture;
    final transfers = await transfersFuture;

    final events = <Map<String, dynamic>>[];

    for (final b in bookings) {
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

    for (var tr in transfers) {
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

    for (final t in trades) {
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
      (cmp < 0 ? eventsBefore : eventsAfter).add(e);
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

    eventsBefore.sort((a, b) => cmpKey(
          a['datetime'] as int,
          a['typeStr'] as String,
          a['id'] as int,
          b['datetime'] as int,
          b['typeStr'] as String,
          b['id'] as int,
        ));

    final fifo = ListQueue<Map<String, double>>();

    for (final e in eventsBefore) {
      final shares = (e['shares'] as num).toDouble();
      final costBasis = (e['costBasis'] as num).toDouble();
      final fee = (e['fee'] as num).toDouble();

      if (e['in'] as bool) {
        fifo.add({'shares': shares, 'costBasis': costBasis, 'fee': fee});
      } else {
        consumeFiFo(fifo, shares);
      }
    }

    return fifo;
  }

  int _compareEvents(_RecalcEvent a, _RecalcEvent b) {
    return cmpKey(a.datetime, a.typeStr, a.id, b.datetime, b.typeStr, b.id);
  }

  Future<void> recalculateSubsequentEvents({
    required AppLocalizations l10n,
    required int assetId,
    required int accountId,
    required int upToDatetime,
    required String upToType, // '_booking' | '_transfer' | 'buy' | 'sell'
    required int upToId,
  }) {
    return transaction(() async {
      final visited = <String>{};
      final accounts = await _recalculateInternal(
        l10n: l10n,
        assetId: assetId,
        accountId: accountId,
        cmpDt: upToDatetime,
        cmpType: upToType,
        cmpId: upToId,
        visited: visited,
        accounts: {},
        initialFifo: null,
      );

      for (final accountId in accounts) {
        final inconsistent = await db.accountsDao.leadsToInconsistentBalanceHistory(accountId: accountId);
        if (inconsistent) {
          throw Exception(l10n.actionCancelledDueToDataInconsistency);
        }
      }
    });
  }

  Future<Set<int>> _recalculateInternal({
    required AppLocalizations l10n,
    required int assetId,
    required int accountId,
    required int cmpDt,
    required String cmpType,
    required int cmpId,
    required Set<String> visited,
    required Set<int> accounts,
    ListQueue<Map<String, double>>?
        initialFifo, // optional pre-built FIFO for receiver recursion
  }) async {
    if (assetId == 1) return accounts;

    final visitKey = '$assetId|$accountId|$cmpDt|$cmpType|$cmpId';
    if (visited.contains(visitKey)) return accounts;
    visited.add(visitKey);
    accounts.add(accountId);



    final events = <_RecalcEvent>[];
    final tradesToUndo = <Trade>[];

    final bookingsFuture =
        db.bookingsDao.getBookingsAfter(assetId, accountId, cmpDt);
    final transfersFuture =
        db.transfersDao.getTransfersAfter(assetId, accountId, cmpDt);
    final tradesFuture = db.tradesDao.getTradesAfter(assetId, accountId, cmpDt);

    final bookingsCandidates = await bookingsFuture;
    final transfersCandidates = await transfersFuture;
    final tradesCandidates = await tradesFuture;

    for (final b in bookingsCandidates) {
      final dt = b.date * 1000000;
      if (cmpKey(dt, '_booking', b.id, cmpDt, cmpType, cmpId) <= 0) continue;
      events.add(_RecalcEvent.booking(b));
    }

    for (final t in transfersCandidates) {
      final dt = t.date * 1000000;
      if (cmpKey(dt, '_transfer', t.id, cmpDt, cmpType, cmpId) <= 0) continue;
      events.add(_RecalcEvent.transfer(t));
    }

    for (final t in tradesCandidates) {
      if (cmpKey(t.datetime, t.type.name, t.id, cmpDt, cmpType, cmpId) <= 0) {
        continue;
      }
      events.add(_RecalcEvent.trade(t));
      tradesToUndo.add(t);
    }

    final fifo = initialFifo ??
        await buildFiFoQueue(
          assetId,
          accountId,
          upToDatetime: cmpDt,
          upToType: cmpType,
          upToId: cmpId,
        );

    for (final t in tradesToUndo.reversed) {
      await db.tradesDao.undoTradeFromDb(t);
    }

    events.sort(_compareEvents);
    for (final e in events) {
      final visitKey = '$assetId|$accountId|${e.datetime}|${e.typeStr}|${e.id}';
      if (visited.contains(visitKey)) return accounts;
      visited.add(visitKey);
      if (e.type == _RecalcEventType.booking) {
        final b = e.booking!;
        if (b.shares > 0) {
          fifo.add({'shares': b.shares, 'costBasis': b.costBasis, 'fee': 0.0});
        } else if (b.shares < 0) {
          double consumedValue = 0;
          (consumedValue, _) = consumeFiFo(fifo, -b.shares);
          final newCostBasis = consumedValue / b.shares;

          if (b.costBasis != newCostBasis) {
            await (update(bookings)..where((tbl) => tbl.id.equals(b.id))).write(
              BookingsCompanion(
                costBasis: Value(newCostBasis),
                value: Value(consumedValue),
              ),
            );
            final valueDelta = consumedValue - b.value;
            await db.tradesDao
                .applyDbEffects(assetId, b.accountId, 0, valueDelta, 0);
          }
        }
      } else if (e.type == _RecalcEventType.transfer) {
        final t = e.transfer!;
        if (t.receivingAccountId == accountId) {
          fifo.add({'shares': t.shares, 'costBasis': t.costBasis, 'fee': 0.0});
        } else {
          double consumedValue = 0;
          (consumedValue, _) = consumeFiFo(fifo, t.shares);
          final newCostBasis = -consumedValue / t.shares;

          if (t.costBasis != newCostBasis) {
            await (update(transfers)..where((tbl) => tbl.id.equals(t.id)))
                .write(
              TransfersCompanion(
                costBasis: Value(newCostBasis),
                value: Value(-consumedValue),
              ),
            );

            final valueDelta = -consumedValue - t.value;
            await db.tradesDao.applyDbEffects(
                assetId, t.sendingAccountId, 0, -valueDelta, 0,
                updateAsset: false);
            await db.tradesDao.applyDbEffects(
                assetId, t.receivingAccountId, 0, valueDelta, 0,
                updateAsset: false);
          }

          final receiverFifo = await buildFiFoQueue(
            assetId,
            t.receivingAccountId,
            upToDatetime: e.datetime - 1,
            upToType: '_transfer',
            upToId: t.id,
          );
          receiverFifo
              .add({'shares': t.shares, 'costBasis': newCostBasis, 'fee': 0.0});

          await _recalculateInternal(
            l10n: l10n,
            assetId: assetId,
            accountId: t.receivingAccountId,
            cmpDt: e.datetime,
            cmpType: '_transfer',
            cmpId: t.id,
            visited: visited,
            accounts: accounts,
            initialFifo: receiverFifo,
          );
        }
      } else {
        final t = e.trade!;
        accounts.add(t.sourceAccountId);
        accounts.add(t.targetAccountId);
        await db.tradesDao.applyTradeToDb(t.toCompanion(false), fifo);
      }
      accounts.add(accountId);
    }
    return accounts;
  }
}

enum _RecalcEventType { booking, transfer, trade }

class _RecalcEvent {
  final _RecalcEventType type;
  final int datetime;
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
