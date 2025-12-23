import 'dart:collection';

import 'package:drift/drift.dart';
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

  Future<void> updateBaseCurrencyAssetOnAccount(
      int accountId, double amount) async {
    AssetOnAccount baseCurrencyAssetOnAccount = await getAOA(accountId, 1);
    await (update(assetsOnAccounts)
          ..where((a) => a.assetId.equals(1) & a.accountId.equals(accountId)))
        .write(
      AssetsOnAccountsCompanion(
          shares: Value(baseCurrencyAssetOnAccount.shares + amount),
          value: Value(baseCurrencyAssetOnAccount.value + amount)),
    );
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
    final initialAOA = await getAOA(accountId, assetId);
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

    for (final tr in transferRows) {
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
            lot['shares'] = lot['shares']! - remaining;
            remaining = 0;
          }
        }
      }
    }

    return fifo;
  }
}
