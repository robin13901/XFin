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

  Future<ListQueue<Map<String, double>>> buildFiFoQueue(
      int assetId, int accountId,
      {Transfer? oldTransfer}) async {
    // Collect initial assets
    final initialAOA = await getAOA(accountId, assetId);
    var initialShares = initialAOA.shares;
    var initialValue = initialAOA.value;

    //1) Collect trades
    final tRows = await (select(trades)
          ..where((t) =>
              t.assetId.equals(assetId) &
              ((t.targetAccountId.equals(accountId)) |
                  (t.sourceAccountId.equals(accountId)))))
        .get();

    // 2) Collect bookings
    final bRows = await (select(bookings)
          ..where(
              (b) => b.assetId.equals(assetId) & b.accountId.equals(accountId)))
        .get();

    // 3) Collect transfers
    final trRows = await (select(transfers)
          ..where((tr) =>
              tr.assetId.equals(assetId) &
              ((tr.sendingAccountId.equals(accountId)) |
                  (tr.receivingAccountId.equals(accountId)))))
        .get();

    // Build a lightweight list of maps (no extra classes) with common fields
    final events = <Map<String, dynamic>>[];

    for (final t in tRows) {
      final isInflow = t.type == TradeTypes.buy;
      var value = t.shares * t.costBasis;
      initialShares += isInflow ? -t.shares : t.shares;
      initialValue += isInflow ? -value : value;
      final datetime = t.datetime;
      events.add({
        'in': isInflow,
        'datetime': datetime,
        'shares': t.shares,
        'costBasis': t.costBasis
      });
    }

    for (final b in bRows) {
      final datetime = b.date * 1000000; // convert yyyyMMdd -> yyyyMMdd000000
      events.add({
        'in': b.shares > 0,
        'datetime': datetime,
        'shares': b.shares.abs(),
        'costBasis': b.costBasis
      });
      initialShares -= b.shares;
      initialValue -= b.value;
    }

    for (final tr in trRows) {
      final isInflow = tr.receivingAccountId == accountId;
      initialShares += isInflow ? -tr.shares : tr.shares;
      initialValue += isInflow ? -tr.value : tr.value;
      if (oldTransfer != null && tr.id == oldTransfer.id) continue;
      final datetime = tr.date * 1000000; // convert yyyyMMdd -> yyyyMMdd000000
      events.add({
        'in': isInflow,
        'datetime': datetime,
        'shares': tr.shares,
        'costBasis': tr.costBasis
      });
    }

    // Add initial AOA
    events.add({
      'in': true,
      'datetime': 00000000,
      'shares': initialShares,
      'costBasis': initialValue / initialShares
    });
    events
        .sort((a, b) => (a['datetime'] as int).compareTo(b['datetime'] as int));

    final fifo = ListQueue<Map<String, double>>();
    for (var e in events) {
      if (e['in']) {
        fifo.add({'shares': e['shares'], 'costBasis': e['costBasis']});
      } else {
        var sharesToConsume = e['shares'];
        while (sharesToConsume > 0 && fifo.isNotEmpty) {
          var currentLot = fifo.first;
          if (currentLot['shares']! <= sharesToConsume) {
            sharesToConsume -= currentLot['shares']!;
            fifo.removeFirst();
          } else {
            currentLot['shares'] = currentLot['shares']! - sharesToConsume;
            sharesToConsume = 0;
          }
        }
      }
    }

    return fifo;
  }
}
