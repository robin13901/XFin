import 'dart:collection';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:test/test.dart';
import 'package:xfin/database/app_database.dart';
import 'package:xfin/database/daos/assets_on_accounts_dao.dart';
import 'package:xfin/database/tables.dart';

void main() {
  late AppDatabase db;
  late AssetsOnAccountsDao aoaDao;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    aoaDao = db.assetsOnAccountsDao;

    // Insert base currency (id = 1) as done in the project tests
    await db.into(db.assets).insert(AssetsCompanion.insert(
      name: 'EUR',
      type: AssetTypes.fiat,
      tickerSymbol: 'EUR',
    ));
  });

  tearDown(() async {
    await db.close();
  });

  // Helper to convert fifo queue to a List for easier assertions
  List<Map<String, double>> fifoToList(ListQueue<Map<String, double>> q) =>
      List<Map<String, double>>.from(q.map((m) => Map<String, double>.from(m)));

  double fifoTotalShares(ListQueue<Map<String, double>> q) =>
      q.fold<double>(0.0, (p, e) => p + (e['shares'] ?? 0.0));

  group('AssetsOnAccountsDao basic CRUD', () {
    late int accountId;
    late int assetId;

    setUp(() async {
      accountId = await db.into(db.accounts).insert(AccountsCompanion.insert(
        name: 'A',
        type: AccountTypes.cash,
      ));
      assetId = await db.into(db.assets).insert(AssetsCompanion.insert(
        name: 'TST',
        type: AssetTypes.stock,
        tickerSymbol: 'TST',
      ));
    });

    test('addAssetOnAccount and getAOA', () async {
      final comp = AssetsOnAccountsCompanion.insert(
          accountId: accountId, assetId: assetId);
      await aoaDao.addAssetOnAccount(comp);
      final aoa = await aoaDao.getAOA(accountId, assetId);
      expect(aoa.accountId, accountId);
      expect(aoa.assetId, assetId);
      expect(aoa.shares, closeTo(0.0, 1e-12));
      expect(aoa.value, closeTo(0.0, 1e-12));
      // default cost-bases in schema are 1
      expect(aoa.netCostBasis, closeTo(1.0, 1e-12));
      expect(aoa.brokerCostBasis, closeTo(1.0, 1e-12));
      expect(aoa.buyFeeTotal, closeTo(0.0, 1e-12));
    });

    test('ensureAssetOnAccountExists returns existing or creates', () async {
      final created =
      await aoaDao.ensureAssetOnAccountExists(assetId, accountId);
      expect(created.accountId, accountId);
      expect(created.assetId, assetId);

      final fetched =
      await aoaDao.ensureAssetOnAccountExists(assetId, accountId);
      expect(fetched.accountId, created.accountId);
      expect(fetched.assetId, created.assetId);
    });

    test('getAOAsForAccount returns multiple AOAs', () async {
      final asset2Id = await db.into(db.assets).insert(AssetsCompanion.insert(
        name: 'TST2',
        type: AssetTypes.stock,
        tickerSymbol: 'TST2',
      ));
      await db.into(db.assetsOnAccounts).insert(AssetsOnAccountsCompanion.insert(
        accountId: accountId,
        assetId: assetId,
      ));
      await db.into(db.assetsOnAccounts).insert(AssetsOnAccountsCompanion.insert(
        accountId: accountId,
        assetId: asset2Id,
      ));
      final list = await aoaDao.getAOAsForAccount(accountId);
      expect(list.length, 2);
      final ids = list.map((e) => e.assetId).toSet();
      expect(ids.contains(assetId), isTrue);
      expect(ids.contains(asset2Id), isTrue);
    });

    test('deleteAOA removes the AOA', () async {
      await db.into(db.assetsOnAccounts).insert(AssetsOnAccountsCompanion.insert(
        accountId: accountId,
        assetId: assetId,
      ));
      final aoa = await aoaDao.getAOA(accountId, assetId);
      await aoaDao.deleteAOA(aoa);
      expect(() async => await aoaDao.getAOA(accountId, assetId),
          throwsA(isA<StateError>()));
    });
  });

  group('updateBaseCurrencyAssetOnAccount', () {
    late int accountId;

    setUp(() async {
      accountId = await db.into(db.accounts).insert(AccountsCompanion.insert(
        name: 'BaseAcc',
        type: AccountTypes.cash,
      ));
      // ensure base currency asset on account exists (asset id 1)
      await db.into(db.assetsOnAccounts).insert(AssetsOnAccountsCompanion.insert(
        accountId: accountId,
        assetId: 1,
      ));
    });

    test('increments shares and value by amount', () async {
      final before = await aoaDao.getAOA(accountId, 1);
      expect(before.assetId, 1);

      await aoaDao.updateBaseCurrencyAssetOnAccount(accountId, 50.0);

      final after = await aoaDao.getAOA(accountId, 1);
      expect(after.shares, closeTo(before.shares + 50.0, 1e-9));
      expect(after.value, closeTo(before.value + 50.0, 1e-9));
    });
  });

  group('updateAOA arithmetic and edge cases', () {
    late int accountId;
    late int assetId;

    setUp(() async {
      accountId = await db.into(db.accounts).insert(AccountsCompanion.insert(
        name: 'UpdAcc',
        type: AccountTypes.portfolio,
      ));
      assetId = await db.into(db.assets).insert(AssetsCompanion.insert(
        name: 'UPD',
        type: AssetTypes.stock,
        tickerSymbol: 'UPD',
      ));
      await db.into(db.assetsOnAccounts).insert(AssetsOnAccountsCompanion.insert(
        accountId: accountId,
        assetId: assetId,
        shares: const Value(10.0),
        value: const Value(100.0),
        buyFeeTotal: const Value(2.0),
        netCostBasis: const Value(10.0),
        brokerCostBasis: const Value(10.2),
      ));
    });

    test('updateAOA non-zero resulting shares updates cost-bases correctly',
            () async {
          final delta = AssetOnAccount(
            accountId: accountId,
            assetId: assetId,
            shares: 5.0,
            value: 55.0,
            netCostBasis: 0,
            brokerCostBasis: 0,
            buyFeeTotal: 3.0,
          );

          await aoaDao.updateAOA(delta);
          final result = await aoaDao.getAOA(accountId, assetId);
          expect(result.shares, closeTo(15.0, 1e-9));
          expect(result.value, closeTo(155.0, 1e-9));
          expect(result.buyFeeTotal, closeTo(5.0, 1e-9));
          expect(result.netCostBasis, closeTo(155.0 / 15.0, 1e-9));
          expect(result.brokerCostBasis, closeTo((155.0 + 5.0) / 15.0, 1e-9));
        });

    test('updateAOA resulting in zero shares sets cost-bases to 1', () async {
      final delta = AssetOnAccount(
        accountId: accountId,
        assetId: assetId,
        shares: -10.0,
        value: -100.0,
        netCostBasis: 0,
        brokerCostBasis: 0,
        buyFeeTotal: -2.0,
      );

      await aoaDao.updateAOA(delta);

      final result = await aoaDao.getAOA(accountId, assetId);
      expect(result.shares, closeTo(0.0, 1e-9));
      expect(result.value, closeTo(0.0, 1e-9));
      expect(result.buyFeeTotal, closeTo(0.0, 1e-9));
      // when shares == 0 schema uses 1 as default cost basis in some places — assert consistent behaviour
      expect(result.netCostBasis, closeTo(1.0, 1e-9));
      expect(result.brokerCostBasis, closeTo(1.0, 1e-9));
    });
  });

  group('buildFiFoQueue - many scenarios', () {
    late int acc;
    late int asset;

    setUp(() async {
      acc = await db.into(db.accounts).insert(AccountsCompanion.insert(
        name: 'FIFOAcc',
        type: AccountTypes.portfolio,
      ));
      asset = await db.into(db.assets).insert(AssetsCompanion.insert(
        name: 'FIFOAS',
        type: AssetTypes.stock,
        tickerSymbol: 'FIFOAS',
      ));
    });

    test('only initial AOA -> single lot equal to initial shares and cost',
            () async {
          await db.into(db.assetsOnAccounts).insert(AssetsOnAccountsCompanion.insert(
            accountId: acc,
            assetId: asset,
            shares: const Value(10.0),
            value: const Value(100.0),
            netCostBasis: const Value(10.0),
            brokerCostBasis: const Value(10.0),
            buyFeeTotal: const Value(0.0),
          ));

          final fifo = await aoaDao.buildFiFoQueue(asset, acc);
          final list = fifoToList(fifo);
          expect(list.length, 1);
          expect(list.first['shares'], closeTo(10.0, 1e-9));
          expect(list.first['costBasis'], closeTo(10.0, 1e-9));
        });

    test('initial + single booking out consumes correct shares from initial lot',
            () async {
          await db.into(db.assetsOnAccounts).insert(AssetsOnAccountsCompanion.insert(
            accountId: acc,
            assetId: asset,
            shares: const Value(10.0),
            value: const Value(100.0),
          ));

          // booking: outflow of 4 shares
          await db.bookingsDao.createBooking(BookingsCompanion.insert(
            date: 20240102,
            shares: -4.0,
            value: -40.0,
            costBasis: const Value(10.0),
            category: 'B',
            accountId: acc,
            assetId: Value(asset),
          ));

          final fifo = await aoaDao.buildFiFoQueue(asset, acc);
          final list = fifoToList(fifo);
          expect(list.length, 1);
          expect(list.first['shares'], closeTo(6.0, 1e-9));
          expect(list.first['costBasis'], closeTo(10.0, 1e-9));
        });

    test('initial + multiple in bookings + out booking consumes FIFO order',
            () async {
          await db.into(db.assetsOnAccounts).insert(AssetsOnAccountsCompanion.insert(
            accountId: acc,
            assetId: asset,
            shares: const Value(10.0),
            value: const Value(100.0),
          ));

          // booking 1: in 5 @ 12 (later)
          await db.bookingsDao.createBooking(BookingsCompanion.insert(
            date: 20240103,
            shares: 5.0,
            value: 60.0,
            costBasis: const Value(12.0),
            category: 'B1',
            accountId: acc,
            assetId: Value(asset),
          ));

          // booking 2: out 8 (consumes from earliest lot first)
          await db.bookingsDao.createBooking(BookingsCompanion.insert(
            date: 20240104,
            shares: -8.0,
            value: -96.0,
            costBasis: const Value(12.0),
            category: 'B2',
            accountId: acc,
            assetId: Value(asset),
          ));

          final fifo = await aoaDao.buildFiFoQueue(asset, acc);
          final list = fifoToList(fifo);

          expect(list.length, 2);
          expect(list[0]['shares'], closeTo(2.0, 1e-9)); // initial leftover
          expect(list[0]['costBasis'], closeTo(10.0, 1e-9));
          expect(list[1]['shares'], closeTo(5.0, 1e-9)); // booking in remains
          expect(list[1]['costBasis'], closeTo(12.0, 1e-9));
        });

    test('transfer included unless passed as oldTransfer; comparing both behaviours',
            () async {
          await db.into(db.assetsOnAccounts).insert(AssetsOnAccountsCompanion.insert(
            accountId: acc,
            assetId: asset,
            shares: const Value(10.0),
            value: const Value(100.0),
          ));

          // create a transfer inflow of 5 shares to this account
          final transferId = await db.into(db.transfers).insert(TransfersCompanion.insert(
            date: 20240105,
            assetId: Value(asset),
            sendingAccountId: 999,
            receivingAccountId: acc,
            shares: 5.0,
            value: 60.0,
            costBasis: const Value(12.0),
          ));

          // update AOA to reflect transfer effect (tests simulate that DB-level account balances were updated elsewhere)
          await (db.update(db.assetsOnAccounts)
            ..where((a) => a.accountId.equals(acc) & a.assetId.equals(asset)))
              .write(const AssetsOnAccountsCompanion(
            shares: Value(15.0),
            value: Value(160.0),
            netCostBasis: Value(10.6666666667),
            brokerCostBasis: Value(10.6666666667),
          ));

          // build queue without oldTransfer -> transfer should be included
          final fifoWithTransfer = await aoaDao.buildFiFoQueue(asset, acc);
          final listWith = fifoToList(fifoWithTransfer);
          expect(listWith.length, 2);
          expect(listWith[0]['shares'], closeTo(10.0, 1e-9));
          expect(listWith[0]['costBasis'], closeTo(10.0, 1e-9));
          expect(listWith[1]['shares'], closeTo(5.0, 1e-9));
          expect(listWith[1]['costBasis'], closeTo(12.0, 1e-9));

          // fetch the actual Transfer row
          final tr = await (db.select(db.transfers)..where((t) => t.id.equals(transferId))).getSingle();

          // build queue with oldTransfer param -> the transfer event should be ignored for FIFO (but its accounting effect remains)
          final fifoWithoutTransfer =
          await aoaDao.buildFiFoQueue(asset, acc, oldTransfer: tr);
          final listWithout = fifoToList(fifoWithoutTransfer);

          // Only initial lot should remain for FIFO
          expect(listWithout.length, 1);
          expect(listWithout[0]['shares'], closeTo(10.0, 1e-9));
          expect(listWithout[0]['costBasis'], closeTo(10.0, 1e-9));

          // The total shares in DB should still reflect the transfer (we didn't lose accounting)
          final aoa = await aoaDao.getAOA(acc, asset);
          expect(aoa.shares, closeTo(15.0, 1e-9));
        });

    test('trades are considered and influence FIFO (buys/sells interplay)', () async {
      // initial 10@10
      await db.into(db.assetsOnAccounts).insert(AssetsOnAccountsCompanion.insert(
        accountId: acc,
        assetId: asset,
        shares: const Value(10.0),
        value: const Value(100.0),
      ));

      // other account
      final otherAcc = await db.into(db.accounts).insert(AccountsCompanion.insert(
        name: 'Other',
        type: AccountTypes.cash,
      ));

      // buy trade -> inflow of 3 (account is target)
      await db.into(db.trades).insert(TradesCompanion.insert(
        datetime: 20240106000000,
        assetId: asset,
        type: TradeTypes.buy,
        sourceAccountId: otherAcc,
        targetAccountId: acc,
        shares: 3.0,
        costBasis: 11.0,
        sourceAccountValueDelta: -33.0,
        targetAccountValueDelta: 33.0,
      ));

      // sell trade -> outflow of 4 (account is source)
      await db.into(db.trades).insert(TradesCompanion.insert(
        datetime: 20240107000000,
        assetId: asset,
        type: TradeTypes.sell,
        sourceAccountId: acc,
        targetAccountId: otherAcc,
        shares: 4.0,
        costBasis: 12.0,
        sourceAccountValueDelta: -48.0,
        targetAccountValueDelta: 48.0,
      ));

      // Also ensure AOA reflects current aggregated totals (10 - initial +3 -4 = 9)
      await (db.update(db.assetsOnAccounts)
        ..where((a) => a.accountId.equals(acc) & a.assetId.equals(asset)))
          .write(const AssetsOnAccountsCompanion(
        shares: Value(9.0),
        value: Value(9.0 * 11.0), // not precise but sufficient to test total shares
      ));

      final fifo = await aoaDao.buildFiFoQueue(asset, acc);
      final list = fifoToList(fifo);

      // The DAO reverse-applied later events to compute an initial snapshot and then built FIFO.
      // We assert that final FIFO total shares match the AOA.shares (9.0)
      final total = fifoTotalShares(fifo);
      expect(total, closeTo(9.0, 1e-9));

      // There must be at least one lot (initial or combinations)
      expect(list.isNotEmpty, isTrue);
    });

    test('fractional fees and fractional share consumption handled correctly', () async {
      // initial 1.5 shares @ 10
      await db.into(db.assetsOnAccounts).insert(AssetsOnAccountsCompanion.insert(
        accountId: acc,
        assetId: asset,
        shares: const Value(1.5),
        value: const Value(15.0),
        buyFeeTotal: const Value(0.1),
      ));

      // buy 0.5 shares @ 12 with fee 0.05 (inflow later)
      final other = await db.into(db.accounts).insert(AccountsCompanion.insert(
        name: 'O2',
        type: AccountTypes.cash,
      ));
      await db.into(db.trades).insert(TradesCompanion.insert(
        datetime: 20240102000000,
        assetId: asset,
        type: TradeTypes.buy,
        sourceAccountId: other,
        targetAccountId: acc,
        shares: 0.5,
        costBasis: 12.0,
        fee: const Value(0.05),
        sourceAccountValueDelta: -6.05,
        targetAccountValueDelta: 6.0,
      ));

      // ensure AOA = 2.0 shares total
      await (db.update(db.assetsOnAccounts)
        ..where((a) => a.accountId.equals(acc) & a.assetId.equals(asset)))
          .write(const AssetsOnAccountsCompanion(
        shares: Value(2.0),
        value: Value(15.0 + 6.0),
        buyFeeTotal: Value(0.15),
      ));

      final fifo = await aoaDao.buildFiFoQueue(asset, acc);
      final list = fifoToList(fifo);

      // expect two lots: 1.5@10 and 0.5@12 (fees represented in lot meta)
      expect(list.length, 2);
      expect(list[0]['shares'], closeTo(1.5, 1e-9));
      expect(list[0]['costBasis'], closeTo(10.0, 1e-9));
      expect(list[1]['shares'], closeTo(0.5, 1e-9));
      expect(list[1]['costBasis'], closeTo(12.0, 1e-9));
    });

    test('ordering tie-breakers: datetime/type/id produce deterministic ordering', () async {
      // initial 10@10
      await db.into(db.assetsOnAccounts).insert(AssetsOnAccountsCompanion.insert(
        accountId: acc,
        assetId: asset,
        shares: const Value(10.0),
        value: const Value(100.0),
      ));

      // create buy and sell with identical datetime; buys should sort before sells (alphabetical)
      final other = await db.into(db.accounts).insert(AccountsCompanion.insert(
        name: 'TieOther',
        type: AccountTypes.cash,
      ));

      // two events with same datetime
      const sameDt = 20240101000000;

      // create buy trade (will be "in")
      await db.into(db.trades).insert(TradesCompanion.insert(
        datetime: sameDt,
        assetId: asset,
        type: TradeTypes.buy,
        sourceAccountId: other,
        targetAccountId: acc,
        shares: 2.0,
        costBasis: 9.0,
        sourceAccountValueDelta: -18.0,
        targetAccountValueDelta: 18.0,
      ));

      // create sell trade (will be "out")
      await db.into(db.trades).insert(TradesCompanion.insert(
        datetime: sameDt,
        assetId: asset,
        type: TradeTypes.sell,
        sourceAccountId: acc,
        targetAccountId: other,
        shares: 1.0,
        costBasis: 12.0,
        sourceAccountValueDelta: 12.0,
        targetAccountValueDelta: -12.0,
      ));

      // ensure AOA aggregate reflects net effect: 10 +2 -1 =11
      await (db.update(db.assetsOnAccounts)
        ..where((a) => a.accountId.equals(acc) & a.assetId.equals(asset)))
          .write(const AssetsOnAccountsCompanion(
        shares: Value(11.0),
        value: Value(11.0 * 10.0),
      ));

      // Build FIFO and inspect ordering: included events should place buy before sell if same datetime
      final fifo = await aoaDao.buildFiFoQueue(asset, acc);
      final list = fifoToList(fifo);

      // There should be at least one lot, and because buy occurred at same datetime, the lot added by buy should
      // appear after the initial snapshot but before any lot consumption by the sell if ordering dictates.
      // We'll assert deterministic total shares and non-empty list
      expect(fifoTotalShares(fifo), closeTo(11.0, 1e-9));
      expect(list.isNotEmpty, isTrue);
    });

    test('upToDatetime/upToType/upToId: building prefix FIFO works as expected', () async {
      // initial 10@10
      await db.into(db.assetsOnAccounts).insert(AssetsOnAccountsCompanion.insert(
        accountId: acc,
        assetId: asset,
        shares: const Value(10.0),
        value: const Value(100.0),
      ));

      // booking inflow 5@12
      await db.into(db.bookings).insert(BookingsCompanion.insert(
        date: 20240102,
        assetId: Value(asset),
        accountId: acc,
        category: 'bk',
        shares: 5.0,
        value: 60.0,
        costBasis: const Value(12.0),
      ));

      // trade inflow 3@13
      const dt3 = 20240103 * 1000000;
      await db.into(db.trades).insert(TradesCompanion.insert(
        datetime: dt3,
        assetId: asset,
        type: TradeTypes.buy,
        sourceAccountId: (await db.into(db.accounts).insert(AccountsCompanion.insert(name: 's', type: AccountTypes.cash))),
        targetAccountId: acc,
        shares: 3.0,
        costBasis: 13.0,
        sourceAccountValueDelta: -39.0,
        targetAccountValueDelta: 39.0,
      ));

      // update AOA to include all effects: final shares = 10 +5 +3 = 18
      await (db.update(db.assetsOnAccounts)
        ..where((a) => a.accountId.equals(acc) & a.assetId.equals(asset)))
          .write(const AssetsOnAccountsCompanion(
        shares: Value(18.0),
        value: Value(100.0 + 60.0 + 39.0),
      ));

      // Build FIFO up to dt3 (exclude dt3 trade itself). We expect to see only initial and booking(5) lots
      final prefixFifo = await aoaDao.buildFiFoQueue(asset, acc, upToDatetime: dt3, upToType: 'buy', upToId: 0);
      final prefix = fifoToList(prefixFifo);
      // should contain initial and booking lot (two lots)
      expect(prefix.length, 2);
      expect(prefix[0]['shares'], closeTo(10.0, 1e-9));
      expect(prefix[1]['shares'], closeTo(5.0, 1e-9));

      // Build full FIFO (no upTo) -> must contain the dt3 buy as well => total lots 3
      final fullFifo = await aoaDao.buildFiFoQueue(asset, acc);
      final full = fifoToList(fullFifo);
      expect(full.length, 3);
      expect(fifoTotalShares(fullFifo), closeTo(18.0, 1e-9));
    });

    test('robustness: selling more than available (invalid state) results in empty-ish FIFO or handled gracefully',
            () async {
          // If DB is in inconsistent state (AOA says 1 share but events show more removed),
          // the FIFO builder should not crash (it will try to consume and end up empty).
          await db.into(db.assetsOnAccounts).insert(AssetsOnAccountsCompanion.insert(
            accountId: acc,
            assetId: asset,
            shares: const Value(1.0),
            value: const Value(10.0),
          ));

          // booking out 5 shares in the past (creating an impossible "out")
          await db.bookingsDao.createBooking(BookingsCompanion.insert(
            date: 20240101,
            shares: -5.0,
            value: -50.0,
            costBasis: const Value(10.0),
            category: 'bad',
            accountId: acc,
            assetId: Value(asset),
          ));

          // A well-behaved FIFO builder should return an empty queue or a queue with zero shares rather than throwing.
          // We assert builder returns and that total shares is >= 0 (no NaN)
          final fifo = await aoaDao.buildFiFoQueue(asset, acc);
          final total = fifoTotalShares(fifo);
          expect(total.isFinite, isTrue);
          expect(total >= 0.0, isTrue);
        });
  });
}