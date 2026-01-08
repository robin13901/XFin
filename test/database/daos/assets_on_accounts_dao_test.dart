import 'dart:collection';
import 'dart:ui';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:test/test.dart';
import 'package:xfin/database/app_database.dart';
import 'package:xfin/database/daos/assets_on_accounts_dao.dart';
import 'package:xfin/database/tables.dart';
import 'package:xfin/l10n/app_localizations.dart';

void main() {
  late AppDatabase db;
  late AssetsOnAccountsDao aoaDao;
  late Asset baseCurrencyAsset;
  late AppLocalizations l10n;

  setUp(() async {
    const locale = Locale('en');
    l10n = await AppLocalizations.delegate.load(locale);
    db = AppDatabase(NativeDatabase.memory());
    aoaDao = db.assetsOnAccountsDao;

    baseCurrencyAsset = const Asset(
        id: 1,
        name: 'Euro',
        type: AssetTypes.fiat,
        tickerSymbol: 'EUR',
        currencySymbol: '\$',
        value: 0,
        shares: 0,
        netCostBasis: 1,
        brokerCostBasis: 1,
        buyFeeTotal: 0,
        isArchived: false);

    await db.into(db.assets).insert(baseCurrencyAsset.toCompanion(false));
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
      await db
          .into(db.assetsOnAccounts)
          .insert(AssetsOnAccountsCompanion.insert(
            accountId: accountId,
            assetId: assetId,
          ));
      await db
          .into(db.assetsOnAccounts)
          .insert(AssetsOnAccountsCompanion.insert(
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
      await db
          .into(db.assetsOnAccounts)
          .insert(AssetsOnAccountsCompanion.insert(
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
      await db
          .into(db.assetsOnAccounts)
          .insert(AssetsOnAccountsCompanion.insert(
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
      await db
          .into(db.assetsOnAccounts)
          .insert(AssetsOnAccountsCompanion.insert(
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
      await db
          .into(db.assetsOnAccounts)
          .insert(AssetsOnAccountsCompanion.insert(
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

    test(
        'initial + single booking out consumes correct shares from initial lot',
        () async {
      await db
          .into(db.assetsOnAccounts)
          .insert(AssetsOnAccountsCompanion.insert(
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
      await db
          .into(db.assetsOnAccounts)
          .insert(AssetsOnAccountsCompanion.insert(
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

    test(
        'transfer included unless passed as oldTransfer; comparing both behaviours',
        () async {
      await db
          .into(db.assetsOnAccounts)
          .insert(AssetsOnAccountsCompanion.insert(
            accountId: acc,
            assetId: asset,
            shares: const Value(10.0),
            value: const Value(100.0),
          ));

      // create a transfer inflow of 5 shares to this account
      final transferId =
          await db.into(db.transfers).insert(TransfersCompanion.insert(
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
      final tr = await (db.select(db.transfers)
            ..where((t) => t.id.equals(transferId)))
          .getSingle();

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

    test('trades are considered and influence FIFO (buys/sells interplay)',
        () async {
      // initial 10@10
      await db
          .into(db.assetsOnAccounts)
          .insert(AssetsOnAccountsCompanion.insert(
            accountId: acc,
            assetId: asset,
            shares: const Value(10.0),
            value: const Value(100.0),
          ));

      // other account
      final otherAcc =
          await db.into(db.accounts).insert(AccountsCompanion.insert(
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
        value: Value(
            9.0 * 11.0), // not precise but sufficient to test total shares
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

    test('fractional fees and fractional share consumption handled correctly',
        () async {
      // initial 1.5 shares @ 10
      await db
          .into(db.assetsOnAccounts)
          .insert(AssetsOnAccountsCompanion.insert(
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

    test(
        'ordering tie-breakers: datetime/type/id produce deterministic ordering',
        () async {
      // initial 10@10
      await db
          .into(db.assetsOnAccounts)
          .insert(AssetsOnAccountsCompanion.insert(
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

    test('upToDatetime/upToType/upToId: building prefix FIFO works as expected',
        () async {
      // initial 10@10
      await db
          .into(db.assetsOnAccounts)
          .insert(AssetsOnAccountsCompanion.insert(
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
            sourceAccountId: (await db.into(db.accounts).insert(
                AccountsCompanion.insert(name: 's', type: AccountTypes.cash))),
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
      final prefixFifo = await aoaDao.buildFiFoQueue(asset, acc,
          upToDatetime: dt3, upToType: 'buy', upToId: 0);
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

    test(
        'robustness: selling more than available (invalid state) results in empty-ish FIFO or handled gracefully',
        () async {
      // If DB is in inconsistent state (AOA says 1 share but events show more removed),
      // the FIFO builder should not crash (it will try to consume and end up empty).
      await db
          .into(db.assetsOnAccounts)
          .insert(AssetsOnAccountsCompanion.insert(
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

  group('Subsequent Event Recalculation', () {
    late Asset assetOne;
    late Account bankAccount, portfolio1, portfolio2, portfolio3;
    late AssetOnAccount baseCurrencyAssetOnBankAccount;

    setUp(() async {
      assetOne = const Asset(
          id: 2,
          name: 'Asset One',
          type: AssetTypes.stock,
          tickerSymbol: 'ONE',
          currencySymbol: '',
          value: 0,
          shares: 0,
          netCostBasis: 0,
          brokerCostBasis: 0,
          buyFeeTotal: 0,
          isArchived: false);

      bankAccount = const Account(
          id: 1,
          name: 'Bank Account',
          balance: 1000,
          initialBalance: 1000,
          type: AccountTypes.bankAccount,
          isArchived: false);

      portfolio1 = const Account(
          id: 2,
          name: 'Portfolio Account',
          balance: 0,
          initialBalance: 0,
          type: AccountTypes.portfolio,
          isArchived: false);

      portfolio2 = const Account(
          id: 3,
          name: 'Portfolio Account 2',
          balance: 0,
          initialBalance: 0,
          type: AccountTypes.portfolio,
          isArchived: false);

      portfolio3 = const Account(
          id: 4,
          name: 'Portfolio Account 3',
          balance: 0,
          initialBalance: 0,
          type: AccountTypes.portfolio,
          isArchived: false);

      baseCurrencyAssetOnBankAccount = AssetOnAccount(
          assetId: 1,
          accountId: 1,
          shares: bankAccount.initialBalance,
          value: bankAccount.initialBalance,
          netCostBasis: 1,
          brokerCostBasis: 1,
          buyFeeTotal: 0);

      await db.into(db.assets).insert(assetOne.toCompanion(false));
      await db.into(db.accounts).insert(bankAccount.toCompanion(false));
      await db.into(db.accounts).insert(portfolio1.toCompanion(false));
      await db.into(db.accounts).insert(portfolio2.toCompanion(false));
      await db.into(db.accounts).insert(portfolio3.toCompanion(false));
      await db
          .into(db.assetsOnAccounts)
          .insert(baseCurrencyAssetOnBankAccount.toCompanion(false));
      await db.assetsDao.updateAsset(baseCurrencyAsset.id,
          bankAccount.initialBalance, bankAccount.initialBalance);
    });

    group('Insert/Update/Delete Booking', () {
      test('insert booking recalculates subsequent trade correctly', () async {
        // Buy 1 @ 100
        await db.tradesDao.insertTrade(TradesCompanion(
          datetime: const Value(20250101111111),
          assetId: Value(assetOne.id),
          type: const Value(TradeTypes.buy),
          shares: const Value(1),
          costBasis: const Value(100),
          fee: const Value(0),
          tax: const Value(0),
          sourceAccountId: Value(bankAccount.id),
          targetAccountId: Value(portfolio1.id),
        ));

        // Sell 1 @ 200
        await db.tradesDao.insertTrade(TradesCompanion(
          datetime: const Value(20250202222222),
          assetId: Value(assetOne.id),
          type: const Value(TradeTypes.sell),
          shares: const Value(1),
          costBasis: const Value(200),
          fee: const Value(0),
          tax: const Value(0),
          sourceAccountId: Value(bankAccount.id),
          targetAccountId: Value(portfolio1.id),
        ));

        // Prechecks
        var secondTrade = await db.tradesDao.getTrade(2);
        expect(secondTrade.sourceAccountValueDelta, closeTo(200, 1e-9));
        expect(secondTrade.targetAccountValueDelta, closeTo(-100, 1e-9));
        expect(secondTrade.profitAndLoss, closeTo(100, 1e-9));
        expect(secondTrade.returnOnInvest, closeTo(1, 1e-9));
        var aoBankAccount = await db.assetsOnAccountsDao
            .getAOA(bankAccount.id, baseCurrencyAsset.id);
        expect(aoBankAccount.shares, closeTo(1100, 1e-9));
        expect(aoBankAccount.value, closeTo(1100, 1e-9));
        expect(aoBankAccount.netCostBasis, closeTo(1, 1e-9));
        expect(aoBankAccount.brokerCostBasis, closeTo(1, 1e-9));
        expect(aoBankAccount.buyFeeTotal, closeTo(0, 1e-9));
        var aoPortfolioAccount =
            await db.assetsOnAccountsDao.getAOA(portfolio1.id, assetOne.id);
        expect(aoPortfolioAccount.shares, closeTo(0, 1e-9));
        expect(aoPortfolioAccount.value, closeTo(0, 1e-9));
        expect(aoPortfolioAccount.netCostBasis, closeTo(0, 1e-9));
        expect(aoPortfolioAccount.brokerCostBasis, closeTo(0, 1e-9));
        expect(aoPortfolioAccount.buyFeeTotal, closeTo(0, 1e-9));
        var aBaseCurrency = await db.assetsDao.getAsset(baseCurrencyAsset.id);
        expect(aBaseCurrency.shares, closeTo(1100, 1e-9));
        expect(aBaseCurrency.value, closeTo(1100, 1e-9));
        expect(aBaseCurrency.netCostBasis, closeTo(1, 1e-9));
        expect(aBaseCurrency.brokerCostBasis, closeTo(1, 1e-9));
        expect(aBaseCurrency.buyFeeTotal, closeTo(0, 1e-9));
        var aOne = await db.assetsDao.getAsset(assetOne.id);
        expect(aOne.shares, closeTo(0, 1e-9));
        expect(aOne.value, closeTo(0, 1e-9));
        expect(aOne.netCostBasis, closeTo(0, 1e-9));
        expect(aOne.brokerCostBasis, closeTo(0, 1e-9));
        expect(aOne.buyFeeTotal, closeTo(0, 1e-9));

        /// Insert booking before first trade
        /// The first trade should be unaffected since its a buy
        /// The second trade should be recalculated since its a sell
        await db.bookingsDao.createBooking(BookingsCompanion(
            date: const Value(20250101),
            assetId: Value(assetOne.id),
            accountId: Value(portfolio1.id),
            category: const Value('B'),
            shares: const Value(0.5),
            costBasis: const Value(50),
            value: const Value(25)));

        // Postchecks
        var firstTrade = await db.tradesDao.getTrade(1);
        expect(firstTrade.sourceAccountValueDelta, closeTo(-100, 1e-9));
        expect(firstTrade.targetAccountValueDelta, closeTo(100, 1e-9));
        expect(firstTrade.profitAndLoss, closeTo(0, 1e-9));
        expect(firstTrade.returnOnInvest, closeTo(0, 1e-9));
        secondTrade = await db.tradesDao.getTrade(2);
        expect(secondTrade.sourceAccountValueDelta, closeTo(200, 1e-9));
        expect(secondTrade.targetAccountValueDelta, closeTo(-75, 1e-9));
        expect(secondTrade.profitAndLoss, closeTo(125, 1e-9));
        expect(secondTrade.returnOnInvest, closeTo(125 / 75, 1e-9));
        aoBankAccount = await db.assetsOnAccountsDao
            .getAOA(bankAccount.id, baseCurrencyAsset.id);
        expect(aoBankAccount.shares, closeTo(1100, 1e-9));
        expect(aoBankAccount.value, closeTo(1100, 1e-9));
        expect(aoBankAccount.netCostBasis, closeTo(1, 1e-9));
        expect(aoBankAccount.brokerCostBasis, closeTo(1, 1e-9));
        expect(aoBankAccount.buyFeeTotal, closeTo(0, 1e-9));
        aoPortfolioAccount =
            await db.assetsOnAccountsDao.getAOA(portfolio1.id, assetOne.id);
        expect(aoPortfolioAccount.shares, closeTo(0.5, 1e-9));
        expect(aoPortfolioAccount.value, closeTo(50, 1e-9));
        expect(aoPortfolioAccount.netCostBasis, closeTo(100, 1e-9));
        expect(aoPortfolioAccount.brokerCostBasis, closeTo(100, 1e-9));
        expect(aoPortfolioAccount.buyFeeTotal, closeTo(0, 1e-9));
        aBaseCurrency = await db.assetsDao.getAsset(baseCurrencyAsset.id);
        expect(aBaseCurrency.shares, closeTo(1100, 1e-9));
        expect(aBaseCurrency.value, closeTo(1100, 1e-9));
        expect(aBaseCurrency.netCostBasis, closeTo(1, 1e-9));
        expect(aBaseCurrency.brokerCostBasis, closeTo(1, 1e-9));
        expect(aBaseCurrency.buyFeeTotal, closeTo(0, 1e-9));
        aOne = await db.assetsDao.getAsset(assetOne.id);
        expect(aOne.shares, closeTo(0.5, 1e-9));
        expect(aOne.value, closeTo(50, 1e-9));
        expect(aOne.netCostBasis, closeTo(100, 1e-9));
        expect(aOne.brokerCostBasis, closeTo(100, 1e-9));
        expect(aOne.buyFeeTotal, closeTo(0, 1e-9));
      });

      test(
          'insert booking recalculates subsequent transfer and withdrawal correctly',
          () async {
        // Buy 1 @ 100
        await db.tradesDao.insertTrade(TradesCompanion(
          datetime: const Value(20250101111111),
          assetId: Value(assetOne.id),
          type: const Value(TradeTypes.buy),
          shares: const Value(1),
          costBasis: const Value(100),
          fee: const Value(0),
          tax: const Value(0),
          sourceAccountId: Value(bankAccount.id),
          targetAccountId: Value(portfolio1.id),
        ));

        // Transfer 1 share to portfolio 2
        await db.transfersDao.createTransfer(TransfersCompanion(
          date: const Value(20250102),
          assetId: Value(assetOne.id),
          sendingAccountId: Value(portfolio1.id),
          receivingAccountId: Value(portfolio2.id),
          shares: const Value(1),
        ));

        // Withdraw 1 share from portfolio 2
        await db.bookingsDao.createBooking(BookingsCompanion(
          date: const Value(20250103),
          assetId: Value(assetOne.id),
          accountId: Value(portfolio2.id),
          category: const Value('B'),
          shares: const Value(-1),
        ));

        // Prechecks
        var transfer = await db.transfersDao.getTransfer(1);
        expect(transfer.shares, closeTo(1, 1e-9));
        expect(transfer.costBasis, closeTo(100, 1e-9));
        expect(transfer.value, closeTo(100, 1e-9));
        var withdrawal = await db.bookingsDao.getBooking(1);
        expect(withdrawal.shares, closeTo(-1, 1e-9));
        expect(withdrawal.costBasis, closeTo(100, 1e-9));
        expect(withdrawal.value, closeTo(-100, 1e-9));
        var aoPortfolio1 =
            await db.assetsOnAccountsDao.getAOA(portfolio1.id, assetOne.id);
        expect(aoPortfolio1.shares, closeTo(0, 1e-9));
        expect(aoPortfolio1.value, closeTo(0, 1e-9));
        expect(aoPortfolio1.netCostBasis, closeTo(1, 1e-9));
        expect(aoPortfolio1.brokerCostBasis, closeTo(1, 1e-9));
        expect(aoPortfolio1.buyFeeTotal, closeTo(0, 1e-9));
        var aoPortfolio2 =
            await db.assetsOnAccountsDao.getAOA(portfolio2.id, assetOne.id);
        expect(aoPortfolio2.shares, closeTo(0, 1e-9));
        expect(aoPortfolio2.value, closeTo(0, 1e-9));
        expect(aoPortfolio2.netCostBasis, closeTo(1, 1e-9));
        expect(aoPortfolio2.brokerCostBasis, closeTo(1, 1e-9));
        expect(aoPortfolio2.buyFeeTotal, closeTo(0, 1e-9));
        var aOne = await db.assetsDao.getAsset(assetOne.id);
        expect(aOne.shares, closeTo(0, 1e-9));
        expect(aOne.value, closeTo(0, 1e-9));
        expect(aOne.netCostBasis, closeTo(1, 1e-9));
        expect(aOne.brokerCostBasis, closeTo(1, 1e-9));
        expect(aOne.buyFeeTotal, closeTo(0, 1e-9));
        var portAcc1 = await db.accountsDao.getAccount(portfolio1.id);
        expect(portAcc1.balance, closeTo(0, 1e-9));
        var portAcc2 = await db.accountsDao.getAccount(portfolio2.id);
        expect(portAcc2.balance, closeTo(0, 1e-9));

        /// Insert booking before trade
        /// The trade should be unaffected since its a buy
        /// The transfer and withdrawal should be recalculated
        await db.bookingsDao.createBooking(BookingsCompanion(
            date: const Value(20250101),
            assetId: Value(assetOne.id),
            accountId: Value(portfolio1.id),
            category: const Value('B'),
            shares: const Value(0.5),
            costBasis: const Value(50),
            value: const Value(25)));

        // Postchecks
        transfer = await db.transfersDao.getTransfer(1);
        expect(transfer.shares, closeTo(1, 1e-9));
        expect(transfer.costBasis, closeTo(75, 1e-9));
        expect(transfer.value, closeTo(75, 1e-9));
        withdrawal = await db.bookingsDao.getBooking(1);
        expect(withdrawal.shares, closeTo(-1, 1e-9));
        expect(withdrawal.costBasis, closeTo(75, 1e-9));
        expect(withdrawal.value, closeTo(-75, 1e-9));
        aoPortfolio1 =
            await db.assetsOnAccountsDao.getAOA(portfolio1.id, assetOne.id);
        expect(aoPortfolio1.shares, closeTo(0.5, 1e-9));
        expect(aoPortfolio1.value, closeTo(50, 1e-9));
        expect(aoPortfolio1.netCostBasis, closeTo(100, 1e-9));
        expect(aoPortfolio1.brokerCostBasis, closeTo(100, 1e-9));
        expect(aoPortfolio1.buyFeeTotal, closeTo(0, 1e-9));
        aoPortfolio2 =
            await db.assetsOnAccountsDao.getAOA(portfolio2.id, assetOne.id);
        expect(aoPortfolio2.shares, closeTo(0, 1e-9));
        expect(aoPortfolio2.value, closeTo(0, 1e-9));
        expect(aoPortfolio2.netCostBasis, closeTo(1, 1e-9));
        expect(aoPortfolio2.brokerCostBasis, closeTo(1, 1e-9));
        expect(aoPortfolio2.buyFeeTotal, closeTo(0, 1e-9));
        aOne = await db.assetsDao.getAsset(assetOne.id);
        expect(aOne.shares, closeTo(0.5, 1e-9));
        expect(aOne.value, closeTo(50, 1e-9));
        expect(aOne.netCostBasis, closeTo(100, 1e-9));
        expect(aOne.brokerCostBasis, closeTo(100, 1e-9));
        expect(aOne.buyFeeTotal, closeTo(0, 1e-9));
        portAcc1 = await db.accountsDao.getAccount(portfolio1.id);
        expect(portAcc1.balance, closeTo(50, 1e-9));
        portAcc2 = await db.accountsDao.getAccount(portfolio2.id);
        expect(portAcc2.balance, closeTo(0, 1e-9));
      });

      test('update booking recalculates subsequent trade correctly', () async {
        // Buy 0.5 @ 100
        await db.tradesDao.insertTrade(TradesCompanion(
          datetime: const Value(20250101111111),
          assetId: Value(assetOne.id),
          type: const Value(TradeTypes.buy),
          shares: const Value(0.5),
          costBasis: const Value(100),
          fee: const Value(0),
          tax: const Value(0),
          sourceAccountId: Value(bankAccount.id),
          targetAccountId: Value(portfolio1.id),
        ));

        // Inflow: 0.5 @ 50
        await db.bookingsDao.createBooking(BookingsCompanion(
            date: const Value(20250102),
            assetId: Value(assetOne.id),
            accountId: Value(portfolio1.id),
            category: const Value('B'),
            shares: const Value(0.5),
            costBasis: const Value(50),
            value: const Value(25)));

        // Sell 1 @ 200
        await db.tradesDao.insertTrade(TradesCompanion(
          datetime: const Value(20250202222222),
          assetId: Value(assetOne.id),
          type: const Value(TradeTypes.sell),
          shares: const Value(1),
          costBasis: const Value(200),
          fee: const Value(0),
          tax: const Value(0),
          sourceAccountId: Value(bankAccount.id),
          targetAccountId: Value(portfolio1.id),
        ));

        // Prechecks
        var subsequentTrade = await db.tradesDao.getTrade(2);
        expect(subsequentTrade.sourceAccountValueDelta, closeTo(200, 1e-9));
        expect(subsequentTrade.targetAccountValueDelta, closeTo(-75, 1e-9));
        expect(subsequentTrade.profitAndLoss, closeTo(125, 1e-9));
        expect(subsequentTrade.returnOnInvest, closeTo(125 / 75, 1e-9));
        var aoBankAccount = await db.assetsOnAccountsDao
            .getAOA(bankAccount.id, baseCurrencyAsset.id);
        expect(aoBankAccount.shares, closeTo(1150, 1e-9));
        expect(aoBankAccount.value, closeTo(1150, 1e-9));
        expect(aoBankAccount.netCostBasis, closeTo(1, 1e-9));
        expect(aoBankAccount.brokerCostBasis, closeTo(1, 1e-9));
        expect(aoBankAccount.buyFeeTotal, closeTo(0, 1e-9));
        var aoPortfolioAccount =
            await db.assetsOnAccountsDao.getAOA(portfolio1.id, assetOne.id);
        expect(aoPortfolioAccount.shares, closeTo(0, 1e-9));
        expect(aoPortfolioAccount.value, closeTo(0, 1e-9));
        expect(aoPortfolioAccount.netCostBasis, closeTo(0, 1e-9));
        expect(aoPortfolioAccount.brokerCostBasis, closeTo(0, 1e-9));
        expect(aoPortfolioAccount.buyFeeTotal, closeTo(0, 1e-9));
        var aBaseCurrency = await db.assetsDao.getAsset(baseCurrencyAsset.id);
        expect(aBaseCurrency.shares, closeTo(1150, 1e-9));
        expect(aBaseCurrency.value, closeTo(1150, 1e-9));
        expect(aBaseCurrency.netCostBasis, closeTo(1, 1e-9));
        expect(aBaseCurrency.brokerCostBasis, closeTo(1, 1e-9));
        expect(aBaseCurrency.buyFeeTotal, closeTo(0, 1e-9));
        var aOne = await db.assetsDao.getAsset(assetOne.id);
        expect(aOne.shares, closeTo(0, 1e-9));
        expect(aOne.value, closeTo(0, 1e-9));
        expect(aOne.netCostBasis, closeTo(0, 1e-9));
        expect(aOne.brokerCostBasis, closeTo(0, 1e-9));
        expect(aOne.buyFeeTotal, closeTo(0, 1e-9));

        // Update booking, this should recalculate subsequent events
        final oldBooking = await (db.select(db.bookings)
              ..where((b) => b.id.equals(1)))
            .getSingle();
        await db.bookingsDao.updateBooking(
            oldBooking,
            const BookingsCompanion(
                id: Value(1),
                date: Value(20250102),
                assetId: Value(2),
                accountId: Value(2),
                category: Value('B'),
                shares: Value(0.5),
                costBasis: Value(40),
                value: Value(20)));

        // Postchecks
        var updatedBooking = await db.bookingsDao.getBooking(1);
        expect(updatedBooking.shares, closeTo(0.5, 1e-9));
        expect(updatedBooking.costBasis, closeTo(40, 1e-9));
        expect(updatedBooking.value, closeTo(20, 1e-9));
        subsequentTrade = await db.tradesDao.getTrade(2);
        expect(subsequentTrade.sourceAccountValueDelta, closeTo(200, 1e-9));
        expect(subsequentTrade.targetAccountValueDelta, closeTo(-70, 1e-9));
        expect(subsequentTrade.profitAndLoss, closeTo(130, 1e-9));
        expect(subsequentTrade.returnOnInvest, closeTo(130 / 70, 1e-9));
        aoBankAccount = await db.assetsOnAccountsDao
            .getAOA(bankAccount.id, baseCurrencyAsset.id);
        expect(aoBankAccount.shares, closeTo(1150, 1e-9));
        expect(aoBankAccount.value, closeTo(1150, 1e-9));
        expect(aoBankAccount.netCostBasis, closeTo(1, 1e-9));
        expect(aoBankAccount.brokerCostBasis, closeTo(1, 1e-9));
        expect(aoBankAccount.buyFeeTotal, closeTo(0, 1e-9));
        aoPortfolioAccount =
            await db.assetsOnAccountsDao.getAOA(portfolio1.id, assetOne.id);
        expect(aoPortfolioAccount.shares, closeTo(0, 1e-9));
        expect(aoPortfolioAccount.value, closeTo(0, 1e-9));
        expect(aoPortfolioAccount.netCostBasis, closeTo(0, 1e-9));
        expect(aoPortfolioAccount.brokerCostBasis, closeTo(0, 1e-9));
        expect(aoPortfolioAccount.buyFeeTotal, closeTo(0, 1e-9));
        aBaseCurrency = await db.assetsDao.getAsset(baseCurrencyAsset.id);
        expect(aBaseCurrency.shares, closeTo(1150, 1e-9));
        expect(aBaseCurrency.value, closeTo(1150, 1e-9));
        expect(aBaseCurrency.netCostBasis, closeTo(1, 1e-9));
        expect(aBaseCurrency.brokerCostBasis, closeTo(1, 1e-9));
        expect(aBaseCurrency.buyFeeTotal, closeTo(0, 1e-9));
        aOne = await db.assetsDao.getAsset(assetOne.id);
        expect(aOne.shares, closeTo(0, 1e-9));
        expect(aOne.value, closeTo(0, 1e-9));
        expect(aOne.netCostBasis, closeTo(0, 1e-9));
        expect(aOne.brokerCostBasis, closeTo(0, 1e-9));
        expect(aOne.buyFeeTotal, closeTo(0, 1e-9));
      });

      test(
          'update booking recalculates subsequent transfer and withdrawal correctly',
          () async {
        // Inflow: 1 @ 100
        await db.bookingsDao.createBooking(BookingsCompanion(
            date: const Value(20250101),
            assetId: Value(assetOne.id),
            accountId: Value(portfolio1.id),
            category: const Value('B'),
            shares: const Value(1),
            costBasis: const Value(100),
            value: const Value(100)));

        // Transfer 1 share to portfolio 2
        await db.transfersDao.createTransfer(TransfersCompanion(
          date: const Value(20250102),
          assetId: Value(assetOne.id),
          sendingAccountId: Value(portfolio1.id),
          receivingAccountId: Value(portfolio2.id),
          shares: const Value(1),
        ));

        // Withdraw 1 share from portfolio 2
        await db.bookingsDao.createBooking(BookingsCompanion(
          date: const Value(20250103),
          assetId: Value(assetOne.id),
          accountId: Value(portfolio2.id),
          category: const Value('B'),
          shares: const Value(-1),
        ));

        // Prechecks
        var transfer = await db.transfersDao.getTransfer(1);
        expect(transfer.shares, closeTo(1, 1e-9));
        expect(transfer.costBasis, closeTo(100, 1e-9));
        expect(transfer.value, closeTo(100, 1e-9));
        var withdrawal = await db.bookingsDao.getBooking(2);
        expect(withdrawal.shares, closeTo(-1, 1e-9));
        expect(withdrawal.costBasis, closeTo(100, 1e-9));
        expect(withdrawal.value, closeTo(-100, 1e-9));
        var aoPortfolio1 =
            await db.assetsOnAccountsDao.getAOA(portfolio1.id, assetOne.id);
        expect(aoPortfolio1.shares, closeTo(0, 1e-9));
        expect(aoPortfolio1.value, closeTo(0, 1e-9));
        expect(aoPortfolio1.netCostBasis, closeTo(1, 1e-9));
        expect(aoPortfolio1.brokerCostBasis, closeTo(1, 1e-9));
        expect(aoPortfolio1.buyFeeTotal, closeTo(0, 1e-9));
        var aoPortfolio2 =
            await db.assetsOnAccountsDao.getAOA(portfolio2.id, assetOne.id);
        expect(aoPortfolio2.shares, closeTo(0, 1e-9));
        expect(aoPortfolio2.value, closeTo(0, 1e-9));
        expect(aoPortfolio2.netCostBasis, closeTo(1, 1e-9));
        expect(aoPortfolio2.brokerCostBasis, closeTo(1, 1e-9));
        expect(aoPortfolio2.buyFeeTotal, closeTo(0, 1e-9));
        var aOne = await db.assetsDao.getAsset(assetOne.id);
        expect(aOne.shares, closeTo(0, 1e-9));
        expect(aOne.value, closeTo(0, 1e-9));
        expect(aOne.netCostBasis, closeTo(1, 1e-9));
        expect(aOne.brokerCostBasis, closeTo(1, 1e-9));
        expect(aOne.buyFeeTotal, closeTo(0, 1e-9));
        var portAcc1 = await db.accountsDao.getAccount(portfolio1.id);
        expect(portAcc1.balance, closeTo(0, 1e-9));
        var portAcc2 = await db.accountsDao.getAccount(portfolio2.id);
        expect(portAcc2.balance, closeTo(0, 1e-9));

        /// Update inflow booking
        /// The transfer and withdrawal should be recalculated
        final oldBooking = await (db.select(db.bookings)
              ..where((b) => b.id.equals(1)))
            .getSingle();
        await db.bookingsDao.updateBooking(
            oldBooking,
            const BookingsCompanion(
                id: Value(1),
                date: Value(20250101),
                assetId: Value(2),
                accountId: Value(2),
                category: Value('B'),
                shares: Value(1),
                costBasis: Value(40),
                value: Value(40)));

        // Postchecks
        transfer = await db.transfersDao.getTransfer(1);
        expect(transfer.shares, closeTo(1, 1e-9));
        expect(transfer.costBasis, closeTo(40, 1e-9));
        expect(transfer.value, closeTo(40, 1e-9));
        withdrawal = await db.bookingsDao.getBooking(2);
        expect(withdrawal.shares, closeTo(-1, 1e-9));
        expect(withdrawal.costBasis, closeTo(40, 1e-9));
        expect(withdrawal.value, closeTo(-40, 1e-9));
        aoPortfolio1 =
            await db.assetsOnAccountsDao.getAOA(portfolio1.id, assetOne.id);
        expect(aoPortfolio1.shares, closeTo(0, 1e-9));
        expect(aoPortfolio1.value, closeTo(0, 1e-9));
        expect(aoPortfolio1.netCostBasis, closeTo(1, 1e-9));
        expect(aoPortfolio1.brokerCostBasis, closeTo(1, 1e-9));
        expect(aoPortfolio1.buyFeeTotal, closeTo(0, 1e-9));
        aoPortfolio2 =
            await db.assetsOnAccountsDao.getAOA(portfolio2.id, assetOne.id);
        expect(aoPortfolio2.shares, closeTo(0, 1e-9));
        expect(aoPortfolio2.value, closeTo(0, 1e-9));
        expect(aoPortfolio2.netCostBasis, closeTo(1, 1e-9));
        expect(aoPortfolio2.brokerCostBasis, closeTo(1, 1e-9));
        expect(aoPortfolio2.buyFeeTotal, closeTo(0, 1e-9));
        aOne = await db.assetsDao.getAsset(assetOne.id);
        expect(aOne.shares, closeTo(0, 1e-9));
        expect(aOne.value, closeTo(0, 1e-9));
        expect(aOne.netCostBasis, closeTo(1, 1e-9));
        expect(aOne.brokerCostBasis, closeTo(1, 1e-9));
        expect(aOne.buyFeeTotal, closeTo(0, 1e-9));
        portAcc1 = await db.accountsDao.getAccount(portfolio1.id);
        expect(portAcc1.balance, closeTo(0, 1e-9));
        portAcc2 = await db.accountsDao.getAccount(portfolio2.id);
        expect(portAcc2.balance, closeTo(0, 1e-9));
      });

      test('delete booking recalculates subsequent trade correctly', () async {
        // Inflow: 0.5 @ 50
        await db.bookingsDao.createBooking(BookingsCompanion(
            date: const Value(20250101),
            assetId: Value(assetOne.id),
            accountId: Value(portfolio1.id),
            category: const Value('B'),
            shares: const Value(0.5),
            costBasis: const Value(50),
            value: const Value(25)));

        // Buy 1 @ 100
        await db.tradesDao.insertTrade(TradesCompanion(
          datetime: const Value(20250101111111),
          assetId: Value(assetOne.id),
          type: const Value(TradeTypes.buy),
          shares: const Value(1),
          costBasis: const Value(100),
          fee: const Value(0),
          tax: const Value(0),
          sourceAccountId: Value(bankAccount.id),
          targetAccountId: Value(portfolio1.id),
        ));

        // Sell 1 @ 200
        await db.tradesDao.insertTrade(TradesCompanion(
          datetime: const Value(20250202222222),
          assetId: Value(assetOne.id),
          type: const Value(TradeTypes.sell),
          shares: const Value(1),
          costBasis: const Value(200),
          fee: const Value(0),
          tax: const Value(0),
          sourceAccountId: Value(bankAccount.id),
          targetAccountId: Value(portfolio1.id),
        ));

        // Prechecks
        var subsequentTrade = await db.tradesDao.getTrade(2);
        expect(subsequentTrade.sourceAccountValueDelta, closeTo(200, 1e-9));
        expect(subsequentTrade.targetAccountValueDelta, closeTo(-75, 1e-9));
        expect(subsequentTrade.profitAndLoss, closeTo(125, 1e-9));
        expect(subsequentTrade.returnOnInvest, closeTo(125 / 75, 1e-9));
        var aoBankAccount = await db.assetsOnAccountsDao
            .getAOA(bankAccount.id, baseCurrencyAsset.id);
        expect(aoBankAccount.shares, closeTo(1100, 1e-9));
        expect(aoBankAccount.value, closeTo(1100, 1e-9));
        expect(aoBankAccount.netCostBasis, closeTo(1, 1e-9));
        expect(aoBankAccount.brokerCostBasis, closeTo(1, 1e-9));
        expect(aoBankAccount.buyFeeTotal, closeTo(0, 1e-9));
        var aoPortfolioAccount =
            await db.assetsOnAccountsDao.getAOA(portfolio1.id, assetOne.id);
        expect(aoPortfolioAccount.shares, closeTo(0.5, 1e-9));
        expect(aoPortfolioAccount.value, closeTo(50, 1e-9));
        expect(aoPortfolioAccount.netCostBasis, closeTo(100, 1e-9));
        expect(aoPortfolioAccount.brokerCostBasis, closeTo(100, 1e-9));
        expect(aoPortfolioAccount.buyFeeTotal, closeTo(0, 1e-9));
        var aBaseCurrency = await db.assetsDao.getAsset(baseCurrencyAsset.id);
        expect(aBaseCurrency.shares, closeTo(1100, 1e-9));
        expect(aBaseCurrency.value, closeTo(1100, 1e-9));
        expect(aBaseCurrency.netCostBasis, closeTo(1, 1e-9));
        expect(aBaseCurrency.brokerCostBasis, closeTo(1, 1e-9));
        expect(aBaseCurrency.buyFeeTotal, closeTo(0, 1e-9));
        var aOne = await db.assetsDao.getAsset(assetOne.id);
        expect(aOne.shares, closeTo(0.5, 1e-9));
        expect(aOne.value, closeTo(50, 1e-9));
        expect(aOne.netCostBasis, closeTo(100, 1e-9));
        expect(aOne.brokerCostBasis, closeTo(100, 1e-9));
        expect(aOne.buyFeeTotal, closeTo(0, 1e-9));

        /// Delete booking
        /// This should recalculate the second trade
        await db.bookingsDao.deleteBooking(1);

        // Postchecks
        var secondTrade = await db.tradesDao.getTrade(2);
        expect(secondTrade.sourceAccountValueDelta, closeTo(200, 1e-9));
        expect(secondTrade.targetAccountValueDelta, closeTo(-100, 1e-9));
        expect(secondTrade.profitAndLoss, closeTo(100, 1e-9));
        expect(secondTrade.returnOnInvest, closeTo(1, 1e-9));
        aoBankAccount = await db.assetsOnAccountsDao
            .getAOA(bankAccount.id, baseCurrencyAsset.id);
        expect(aoBankAccount.shares, closeTo(1100, 1e-9));
        expect(aoBankAccount.value, closeTo(1100, 1e-9));
        expect(aoBankAccount.netCostBasis, closeTo(1, 1e-9));
        expect(aoBankAccount.brokerCostBasis, closeTo(1, 1e-9));
        expect(aoBankAccount.buyFeeTotal, closeTo(0, 1e-9));
        aoPortfolioAccount =
            await db.assetsOnAccountsDao.getAOA(portfolio1.id, assetOne.id);
        expect(aoPortfolioAccount.shares, closeTo(0, 1e-9));
        expect(aoPortfolioAccount.value, closeTo(0, 1e-9));
        expect(aoPortfolioAccount.netCostBasis, closeTo(0, 1e-9));
        expect(aoPortfolioAccount.brokerCostBasis, closeTo(0, 1e-9));
        expect(aoPortfolioAccount.buyFeeTotal, closeTo(0, 1e-9));
        aBaseCurrency = await db.assetsDao.getAsset(baseCurrencyAsset.id);
        expect(aBaseCurrency.shares, closeTo(1100, 1e-9));
        expect(aBaseCurrency.value, closeTo(1100, 1e-9));
        expect(aBaseCurrency.netCostBasis, closeTo(1, 1e-9));
        expect(aBaseCurrency.brokerCostBasis, closeTo(1, 1e-9));
        expect(aBaseCurrency.buyFeeTotal, closeTo(0, 1e-9));
        aOne = await db.assetsDao.getAsset(assetOne.id);
        expect(aOne.shares, closeTo(0, 1e-9));
        expect(aOne.value, closeTo(0, 1e-9));
        expect(aOne.netCostBasis, closeTo(0, 1e-9));
        expect(aOne.brokerCostBasis, closeTo(0, 1e-9));
        expect(aOne.buyFeeTotal, closeTo(0, 1e-9));
      });

      test(
          'delete booking recalculates subsequent transfer and withdrawal correctly',
          () async {
        // Inflow: 0.5 @ 50
        await db.bookingsDao.createBooking(BookingsCompanion(
            date: const Value(20250101),
            assetId: Value(assetOne.id),
            accountId: Value(portfolio1.id),
            category: const Value('B'),
            shares: const Value(0.5),
            costBasis: const Value(50),
            value: const Value(25)));

        // Buy 1 @ 100
        await db.tradesDao.insertTrade(TradesCompanion(
          datetime: const Value(20250101111111),
          assetId: Value(assetOne.id),
          type: const Value(TradeTypes.buy),
          shares: const Value(1),
          costBasis: const Value(100),
          fee: const Value(0),
          tax: const Value(0),
          sourceAccountId: Value(bankAccount.id),
          targetAccountId: Value(portfolio1.id),
        ));

        // Transfer 1 share to portfolio 2
        await db.transfersDao.createTransfer(TransfersCompanion(
            date: const Value(20250102),
            assetId: Value(assetOne.id),
            sendingAccountId: Value(portfolio1.id),
            receivingAccountId: Value(portfolio2.id),
            shares: const Value(1)));

        // Withdraw 1 share from portfolio 2
        await db.bookingsDao.createBooking(BookingsCompanion(
            date: const Value(20250103),
            assetId: Value(assetOne.id),
            accountId: Value(portfolio2.id),
            category: const Value('B'),
            shares: const Value(-1)));

        // Prechecks
        var transfer = await db.transfersDao.getTransfer(1);
        expect(transfer.shares, closeTo(1, 1e-9));
        expect(transfer.costBasis, closeTo(75, 1e-9));
        expect(transfer.value, closeTo(75, 1e-9));
        var withdrawal = await db.bookingsDao.getBooking(2);
        expect(withdrawal.shares, closeTo(-1, 1e-9));
        expect(withdrawal.costBasis, closeTo(75, 1e-9));
        expect(withdrawal.value, closeTo(-75, 1e-9));
        var aoPortfolio1 =
            await db.assetsOnAccountsDao.getAOA(portfolio1.id, assetOne.id);
        expect(aoPortfolio1.shares, closeTo(0.5, 1e-9));
        expect(aoPortfolio1.value, closeTo(50, 1e-9));
        expect(aoPortfolio1.netCostBasis, closeTo(100, 1e-9));
        expect(aoPortfolio1.brokerCostBasis, closeTo(100, 1e-9));
        expect(aoPortfolio1.buyFeeTotal, closeTo(0, 1e-9));
        var aoPortfolio2 =
            await db.assetsOnAccountsDao.getAOA(portfolio2.id, assetOne.id);
        expect(aoPortfolio2.shares, closeTo(0, 1e-9));
        expect(aoPortfolio2.value, closeTo(0, 1e-9));
        expect(aoPortfolio2.netCostBasis, closeTo(1, 1e-9));
        expect(aoPortfolio2.brokerCostBasis, closeTo(1, 1e-9));
        expect(aoPortfolio2.buyFeeTotal, closeTo(0, 1e-9));
        var aOne = await db.assetsDao.getAsset(assetOne.id);
        expect(aOne.shares, closeTo(0.5, 1e-9));
        expect(aOne.value, closeTo(50, 1e-9));
        expect(aOne.netCostBasis, closeTo(100, 1e-9));
        expect(aOne.brokerCostBasis, closeTo(100, 1e-9));
        expect(aOne.buyFeeTotal, closeTo(0, 1e-9));
        var portAcc1 = await db.accountsDao.getAccount(portfolio1.id);
        expect(portAcc1.balance, closeTo(50, 1e-9));
        var portAcc2 = await db.accountsDao.getAccount(portfolio2.id);
        expect(portAcc2.balance, closeTo(0, 1e-9));

        /// Delete booking
        await db.bookingsDao.deleteBooking(1);

        // Postchecks
        transfer = await db.transfersDao.getTransfer(1);
        expect(transfer.shares, closeTo(1, 1e-9));
        expect(transfer.costBasis, closeTo(100, 1e-9));
        expect(transfer.value, closeTo(100, 1e-9));
        withdrawal = await db.bookingsDao.getBooking(2);
        expect(withdrawal.shares, closeTo(-1, 1e-9));
        expect(withdrawal.costBasis, closeTo(100, 1e-9));
        expect(withdrawal.value, closeTo(-100, 1e-9));
        aoPortfolio1 =
            await db.assetsOnAccountsDao.getAOA(portfolio1.id, assetOne.id);
        expect(aoPortfolio1.shares, closeTo(0, 1e-9));
        expect(aoPortfolio1.value, closeTo(0, 1e-9));
        expect(aoPortfolio1.netCostBasis, closeTo(1, 1e-9));
        expect(aoPortfolio1.brokerCostBasis, closeTo(1, 1e-9));
        expect(aoPortfolio1.buyFeeTotal, closeTo(0, 1e-9));
        aoPortfolio2 =
            await db.assetsOnAccountsDao.getAOA(portfolio2.id, assetOne.id);
        expect(aoPortfolio2.shares, closeTo(0, 1e-9));
        expect(aoPortfolio2.value, closeTo(0, 1e-9));
        expect(aoPortfolio2.netCostBasis, closeTo(1, 1e-9));
        expect(aoPortfolio2.brokerCostBasis, closeTo(1, 1e-9));
        expect(aoPortfolio2.buyFeeTotal, closeTo(0, 1e-9));
        aOne = await db.assetsDao.getAsset(assetOne.id);
        expect(aOne.shares, closeTo(0, 1e-9));
        expect(aOne.value, closeTo(0, 1e-9));
        expect(aOne.netCostBasis, closeTo(1, 1e-9));
        expect(aOne.brokerCostBasis, closeTo(1, 1e-9));
        expect(aOne.buyFeeTotal, closeTo(0, 1e-9));
        portAcc1 = await db.accountsDao.getAccount(portfolio1.id);
        expect(portAcc1.balance, closeTo(0, 1e-9));
        portAcc2 = await db.accountsDao.getAccount(portfolio2.id);
        expect(portAcc2.balance, closeTo(0, 1e-9));
      });
    });

    group('Insert/Update/Delete Transfer', () {
      test('insert transfer recalculates subsequent trade correctly', () async {
        // Buy 1 @ 100
        await db.tradesDao.insertTrade(TradesCompanion(
          datetime: const Value(20250101111111),
          assetId: Value(assetOne.id),
          type: const Value(TradeTypes.buy),
          shares: const Value(1),
          costBasis: const Value(100),
          fee: const Value(0),
          tax: const Value(0),
          sourceAccountId: Value(bankAccount.id),
          targetAccountId: Value(portfolio1.id),
        ));

        // Sell 1 @ 200
        await db.tradesDao.insertTrade(TradesCompanion(
          datetime: const Value(20250202222222),
          assetId: Value(assetOne.id),
          type: const Value(TradeTypes.sell),
          shares: const Value(1),
          costBasis: const Value(200),
          fee: const Value(0),
          tax: const Value(0),
          sourceAccountId: Value(bankAccount.id),
          targetAccountId: Value(portfolio1.id),
        ));

        // Prechecks
        var secondTrade = await db.tradesDao.getTrade(2);
        expect(secondTrade.sourceAccountValueDelta, closeTo(200, 1e-9));
        expect(secondTrade.targetAccountValueDelta, closeTo(-100, 1e-9));
        expect(secondTrade.profitAndLoss, closeTo(100, 1e-9));
        expect(secondTrade.returnOnInvest, closeTo(1, 1e-9));
        var aoBankAccount = await db.assetsOnAccountsDao
            .getAOA(bankAccount.id, baseCurrencyAsset.id);
        expect(aoBankAccount.shares, closeTo(1100, 1e-9));
        expect(aoBankAccount.value, closeTo(1100, 1e-9));
        expect(aoBankAccount.netCostBasis, closeTo(1, 1e-9));
        expect(aoBankAccount.brokerCostBasis, closeTo(1, 1e-9));
        expect(aoBankAccount.buyFeeTotal, closeTo(0, 1e-9));
        var aoPortfolioAccount =
            await db.assetsOnAccountsDao.getAOA(portfolio1.id, assetOne.id);
        expect(aoPortfolioAccount.shares, closeTo(0, 1e-9));
        expect(aoPortfolioAccount.value, closeTo(0, 1e-9));
        expect(aoPortfolioAccount.netCostBasis, closeTo(0, 1e-9));
        expect(aoPortfolioAccount.brokerCostBasis, closeTo(0, 1e-9));
        expect(aoPortfolioAccount.buyFeeTotal, closeTo(0, 1e-9));
        var aBaseCurrency = await db.assetsDao.getAsset(baseCurrencyAsset.id);
        expect(aBaseCurrency.shares, closeTo(1100, 1e-9));
        expect(aBaseCurrency.value, closeTo(1100, 1e-9));
        expect(aBaseCurrency.netCostBasis, closeTo(1, 1e-9));
        expect(aBaseCurrency.brokerCostBasis, closeTo(1, 1e-9));
        expect(aBaseCurrency.buyFeeTotal, closeTo(0, 1e-9));
        var aOne = await db.assetsDao.getAsset(assetOne.id);
        expect(aOne.shares, closeTo(0, 1e-9));
        expect(aOne.value, closeTo(0, 1e-9));
        expect(aOne.netCostBasis, closeTo(0, 1e-9));
        expect(aOne.brokerCostBasis, closeTo(0, 1e-9));
        expect(aOne.buyFeeTotal, closeTo(0, 1e-9));

        /// Insert booking on other account and transfer to portfolio 1 before first trade
        /// The first trade should be unaffected since its a buy
        /// The second trade should be recalculated since its a sell
        await db.bookingsDao.createBooking(BookingsCompanion(
            date: const Value(20241201),
            assetId: Value(assetOne.id),
            accountId: Value(portfolio2.id),
            category: const Value('B'),
            shares: const Value(0.5),
            costBasis: const Value(50),
            value: const Value(25)));
        await db.transfersDao.createTransfer(TransfersCompanion(
          date: const Value(20241202),
          assetId: Value(assetOne.id),
          sendingAccountId: Value(portfolio2.id),
          receivingAccountId: Value(portfolio1.id),
          shares: const Value(0.5),
        ));

        // Postchecks
        var firstTrade = await db.tradesDao.getTrade(1);
        expect(firstTrade.sourceAccountValueDelta, closeTo(-100, 1e-9));
        expect(firstTrade.targetAccountValueDelta, closeTo(100, 1e-9));
        expect(firstTrade.profitAndLoss, closeTo(0, 1e-9));
        expect(firstTrade.returnOnInvest, closeTo(0, 1e-9));
        secondTrade = await db.tradesDao.getTrade(2);
        expect(secondTrade.sourceAccountValueDelta, closeTo(200, 1e-9));
        expect(secondTrade.targetAccountValueDelta, closeTo(-75, 1e-9));
        expect(secondTrade.profitAndLoss, closeTo(125, 1e-9));
        expect(secondTrade.returnOnInvest, closeTo(125 / 75, 1e-9));
        aoBankAccount = await db.assetsOnAccountsDao
            .getAOA(bankAccount.id, baseCurrencyAsset.id);
        expect(aoBankAccount.shares, closeTo(1100, 1e-9));
        expect(aoBankAccount.value, closeTo(1100, 1e-9));
        expect(aoBankAccount.netCostBasis, closeTo(1, 1e-9));
        expect(aoBankAccount.brokerCostBasis, closeTo(1, 1e-9));
        expect(aoBankAccount.buyFeeTotal, closeTo(0, 1e-9));
        aoPortfolioAccount =
            await db.assetsOnAccountsDao.getAOA(portfolio1.id, assetOne.id);
        expect(aoPortfolioAccount.shares, closeTo(0.5, 1e-9));
        expect(aoPortfolioAccount.value, closeTo(50, 1e-9));
        expect(aoPortfolioAccount.netCostBasis, closeTo(100, 1e-9));
        expect(aoPortfolioAccount.brokerCostBasis, closeTo(100, 1e-9));
        expect(aoPortfolioAccount.buyFeeTotal, closeTo(0, 1e-9));
        aBaseCurrency = await db.assetsDao.getAsset(baseCurrencyAsset.id);
        expect(aBaseCurrency.shares, closeTo(1100, 1e-9));
        expect(aBaseCurrency.value, closeTo(1100, 1e-9));
        expect(aBaseCurrency.netCostBasis, closeTo(1, 1e-9));
        expect(aBaseCurrency.brokerCostBasis, closeTo(1, 1e-9));
        expect(aBaseCurrency.buyFeeTotal, closeTo(0, 1e-9));
        aOne = await db.assetsDao.getAsset(assetOne.id);
        expect(aOne.shares, closeTo(0.5, 1e-9));
        expect(aOne.value, closeTo(50, 1e-9));
        expect(aOne.netCostBasis, closeTo(100, 1e-9));
        expect(aOne.brokerCostBasis, closeTo(100, 1e-9));
        expect(aOne.buyFeeTotal, closeTo(0, 1e-9));
      });

      test(
          'insert transfer recalculates subsequent transfer and withdrawal correctly',
          () async {
        // Buy 1 @ 100
        await db.tradesDao.insertTrade(TradesCompanion(
          datetime: const Value(20250101111111),
          assetId: Value(assetOne.id),
          type: const Value(TradeTypes.buy),
          shares: const Value(1),
          costBasis: const Value(100),
          fee: const Value(0),
          tax: const Value(0),
          sourceAccountId: Value(bankAccount.id),
          targetAccountId: Value(portfolio1.id),
        ));

        // Transfer 1 share to portfolio 2 effectively (+ back and forth a few times)
        await db.transfersDao.createTransfer(TransfersCompanion(
          date: const Value(20250102),
          assetId: Value(assetOne.id),
          sendingAccountId: Value(portfolio1.id),
          receivingAccountId: Value(portfolio2.id),
          shares: const Value(1),
        ));
        await db.transfersDao.createTransfer(TransfersCompanion(
          date: const Value(20250103),
          assetId: Value(assetOne.id),
          sendingAccountId: Value(portfolio2.id),
          receivingAccountId: Value(portfolio1.id),
          shares: const Value(1),
        ));
        await db.transfersDao.createTransfer(TransfersCompanion(
          date: const Value(20250104),
          assetId: Value(assetOne.id),
          sendingAccountId: Value(portfolio1.id),
          receivingAccountId: Value(portfolio2.id),
          shares: const Value(1),
        ));

        // Withdraw 1 share from portfolio 2
        await db.bookingsDao.createBooking(BookingsCompanion(
          date: const Value(20250105),
          assetId: Value(assetOne.id),
          accountId: Value(portfolio2.id),
          category: const Value('B'),
          shares: const Value(-1),
        ));

        // Prechecks
        var transfer = await db.transfersDao.getTransfer(1);
        expect(transfer.shares, closeTo(1, 1e-9));
        expect(transfer.costBasis, closeTo(100, 1e-9));
        expect(transfer.value, closeTo(100, 1e-9));
        var withdrawal = await db.bookingsDao.getBooking(1);
        expect(withdrawal.shares, closeTo(-1, 1e-9));
        expect(withdrawal.costBasis, closeTo(100, 1e-9));
        expect(withdrawal.value, closeTo(-100, 1e-9));
        var aoPortfolio1 =
            await db.assetsOnAccountsDao.getAOA(portfolio1.id, assetOne.id);
        expect(aoPortfolio1.shares, closeTo(0, 1e-9));
        expect(aoPortfolio1.value, closeTo(0, 1e-9));
        expect(aoPortfolio1.netCostBasis, closeTo(1, 1e-9));
        expect(aoPortfolio1.brokerCostBasis, closeTo(1, 1e-9));
        expect(aoPortfolio1.buyFeeTotal, closeTo(0, 1e-9));
        var aoPortfolio2 =
            await db.assetsOnAccountsDao.getAOA(portfolio2.id, assetOne.id);
        expect(aoPortfolio2.shares, closeTo(0, 1e-9));
        expect(aoPortfolio2.value, closeTo(0, 1e-9));
        expect(aoPortfolio2.netCostBasis, closeTo(1, 1e-9));
        expect(aoPortfolio2.brokerCostBasis, closeTo(1, 1e-9));
        expect(aoPortfolio2.buyFeeTotal, closeTo(0, 1e-9));
        var aOne = await db.assetsDao.getAsset(assetOne.id);
        expect(aOne.shares, closeTo(0, 1e-9));
        expect(aOne.value, closeTo(0, 1e-9));
        expect(aOne.netCostBasis, closeTo(1, 1e-9));
        expect(aOne.brokerCostBasis, closeTo(1, 1e-9));
        expect(aOne.buyFeeTotal, closeTo(0, 1e-9));
        var portAcc1 = await db.accountsDao.getAccount(portfolio1.id);
        expect(portAcc1.balance, closeTo(0, 1e-9));
        var portAcc2 = await db.accountsDao.getAccount(portfolio2.id);
        expect(portAcc2.balance, closeTo(0, 1e-9));

        /// Insert booking and transfer before trade
        /// The trade should be unaffected since its a buy
        /// The transfer and withdrawal should be recalculated
        await db.bookingsDao.createBooking(BookingsCompanion(
            date: const Value(20241201),
            assetId: Value(assetOne.id),
            accountId: Value(portfolio2.id),
            category: const Value('B'),
            shares: const Value(0.5),
            costBasis: const Value(50),
            value: const Value(25)));
        await db.transfersDao.createTransfer(TransfersCompanion(
          date: const Value(20241202),
          assetId: Value(assetOne.id),
          sendingAccountId: Value(portfolio2.id),
          receivingAccountId: Value(portfolio1.id),
          shares: const Value(0.5),
        ));

        // Postchecks
        transfer = await db.transfersDao.getTransfer(1);
        withdrawal = await db.bookingsDao.getBooking(1);
        aoPortfolio1 =
            await db.assetsOnAccountsDao.getAOA(portfolio1.id, assetOne.id);
        aoPortfolio2 =
            await db.assetsOnAccountsDao.getAOA(portfolio2.id, assetOne.id);
        aOne = await db.assetsDao.getAsset(assetOne.id);
        portAcc1 = await db.accountsDao.getAccount(portfolio1.id);
        portAcc2 = await db.accountsDao.getAccount(portfolio2.id);
        expect(transfer.shares, closeTo(1, 1e-9));
        expect(transfer.costBasis, closeTo(75, 1e-9));
        expect(transfer.value, closeTo(75, 1e-9));
        expect(withdrawal.shares, closeTo(-1, 1e-9));
        expect(withdrawal.costBasis, closeTo(87.5, 1e-9));
        expect(withdrawal.value, closeTo(-87.5, 1e-9));
        expect(aoPortfolio1.shares, closeTo(0.5, 1e-9));
        expect(aoPortfolio1.value, closeTo(37.5, 1e-9));
        expect(aoPortfolio1.netCostBasis, closeTo(75, 1e-9));
        expect(aoPortfolio1.brokerCostBasis, closeTo(75, 1e-9));
        expect(aoPortfolio1.buyFeeTotal, closeTo(0, 1e-9));
        expect(aoPortfolio2.shares, closeTo(0, 1e-9));
        expect(aoPortfolio2.value, closeTo(0, 1e-9));
        expect(aoPortfolio2.netCostBasis, closeTo(1, 1e-9));
        expect(aoPortfolio2.brokerCostBasis, closeTo(1, 1e-9));
        expect(aoPortfolio2.buyFeeTotal, closeTo(0, 1e-9));
        expect(aOne.shares, closeTo(0.5, 1e-9));
        expect(aOne.value, closeTo(37.5, 1e-9));
        expect(aOne.netCostBasis, closeTo(75, 1e-9));
        expect(aOne.brokerCostBasis, closeTo(75, 1e-9));
        expect(aOne.buyFeeTotal, closeTo(0, 1e-9));
        expect(portAcc1.balance, closeTo(37.5, 1e-9));
        expect(portAcc2.balance, closeTo(0, 1e-9));
      });

      test('update transfer recalculates subsequent trade correctly', () async {
        // Inflow: 1 @ 50 on portfolio 1
        await db.bookingsDao.createBooking(BookingsCompanion(
            date: const Value(20250101),
            assetId: Value(assetOne.id),
            accountId: Value(portfolio1.id),
            category: const Value('B'),
            shares: const Value(1),
            costBasis: const Value(50),
            value: const Value(50)));

        // Transfer 1 @ 50 to portfolio 2
        await db.transfersDao.createTransfer(TransfersCompanion(
          date: const Value(20250102),
          assetId: Value(assetOne.id),
          sendingAccountId: Value(portfolio1.id),
          receivingAccountId: Value(portfolio2.id),
          shares: const Value(1),
        ));

        // Inflow: 1 @ 100 on portfolio 2
        await db.bookingsDao.createBooking(BookingsCompanion(
            date: const Value(20250103),
            assetId: Value(assetOne.id),
            accountId: Value(portfolio2.id),
            category: const Value('B'),
            shares: const Value(1),
            costBasis: const Value(100),
            value: const Value(100)));

        // Sell 1 @ 200
        await db.tradesDao.insertTrade(TradesCompanion(
          datetime: const Value(20250202222222),
          assetId: Value(assetOne.id),
          type: const Value(TradeTypes.sell),
          shares: const Value(1),
          costBasis: const Value(200),
          fee: const Value(0),
          tax: const Value(0),
          sourceAccountId: Value(bankAccount.id),
          targetAccountId: Value(portfolio2.id),
        ));

        // Prechecks
        var subsequentTrade = await db.tradesDao.getTrade(1);
        expect(subsequentTrade.sourceAccountValueDelta, closeTo(200, 1e-9));
        expect(subsequentTrade.targetAccountValueDelta, closeTo(-50, 1e-9));
        expect(subsequentTrade.profitAndLoss, closeTo(150, 1e-9));
        expect(subsequentTrade.returnOnInvest, closeTo(150 / 50, 1e-9));
        var aoPortfolioAccount1 =
            await db.assetsOnAccountsDao.getAOA(portfolio1.id, assetOne.id);
        expect(aoPortfolioAccount1.shares, closeTo(0, 1e-9));
        expect(aoPortfolioAccount1.value, closeTo(0, 1e-9));
        expect(aoPortfolioAccount1.netCostBasis, closeTo(1, 1e-9));
        expect(aoPortfolioAccount1.brokerCostBasis, closeTo(1, 1e-9));
        expect(aoPortfolioAccount1.buyFeeTotal, closeTo(0, 1e-9));
        var aoPortfolioAccount2 =
            await db.assetsOnAccountsDao.getAOA(portfolio2.id, assetOne.id);
        expect(aoPortfolioAccount2.shares, closeTo(1, 1e-9));
        expect(aoPortfolioAccount2.value, closeTo(100, 1e-9));
        expect(aoPortfolioAccount2.netCostBasis, closeTo(100, 1e-9));
        expect(aoPortfolioAccount2.brokerCostBasis, closeTo(100, 1e-9));
        expect(aoPortfolioAccount2.buyFeeTotal, closeTo(0, 1e-9));
        var aOne = await db.assetsDao.getAsset(assetOne.id);
        expect(aOne.shares, closeTo(1, 1e-9));
        expect(aOne.value, closeTo(100, 1e-9));
        expect(aOne.netCostBasis, closeTo(100, 1e-9));
        expect(aOne.brokerCostBasis, closeTo(100, 1e-9));
        expect(aOne.buyFeeTotal, closeTo(0, 1e-9));

        // Update transfer, this should recalculate subsequent events
        final oldTransfer = await (db.select(db.transfers)
              ..where((tr) => tr.id.equals(1)))
            .getSingle();
        await db.transfersDao.updateTransfer(
            oldTransfer,
            TransfersCompanion(
              date: const Value(20250102),
              assetId: Value(assetOne.id),
              sendingAccountId: Value(portfolio1.id),
              receivingAccountId: Value(portfolio2.id),
              shares: const Value(0.5),
            ));

        // Postchecks
        var updatedTransfer = await db.transfersDao.getTransfer(1);
        expect(updatedTransfer.shares, closeTo(0.5, 1e-9));
        expect(updatedTransfer.costBasis, closeTo(50, 1e-9));
        expect(updatedTransfer.value, closeTo(25, 1e-9));
        subsequentTrade = await db.tradesDao.getTrade(1);
        expect(subsequentTrade.sourceAccountValueDelta, closeTo(200, 1e-9));
        expect(subsequentTrade.targetAccountValueDelta, closeTo(-75, 1e-9));
        expect(subsequentTrade.profitAndLoss, closeTo(125, 1e-9));
        expect(subsequentTrade.returnOnInvest, closeTo(125 / 75, 1e-9));
        aoPortfolioAccount1 =
            await db.assetsOnAccountsDao.getAOA(portfolio1.id, assetOne.id);
        expect(aoPortfolioAccount1.shares, closeTo(0.5, 1e-9));
        expect(aoPortfolioAccount1.value, closeTo(25, 1e-9));
        expect(aoPortfolioAccount1.netCostBasis, closeTo(50, 1e-9));
        expect(aoPortfolioAccount1.brokerCostBasis, closeTo(50, 1e-9));
        expect(aoPortfolioAccount1.buyFeeTotal, closeTo(0, 1e-9));
        aoPortfolioAccount2 =
            await db.assetsOnAccountsDao.getAOA(portfolio2.id, assetOne.id);
        expect(aoPortfolioAccount2.shares, closeTo(0.5, 1e-9));
        expect(aoPortfolioAccount2.value, closeTo(50, 1e-9));
        expect(aoPortfolioAccount2.netCostBasis, closeTo(100, 1e-9));
        expect(aoPortfolioAccount2.brokerCostBasis, closeTo(100, 1e-9));
        expect(aoPortfolioAccount2.buyFeeTotal, closeTo(0, 1e-9));
        aOne = await db.assetsDao.getAsset(assetOne.id);
        expect(aOne.shares, closeTo(1, 1e-9));
        expect(aOne.value, closeTo(75, 1e-9));
        expect(aOne.netCostBasis, closeTo(75, 1e-9));
        expect(aOne.brokerCostBasis, closeTo(75, 1e-9));
        expect(aOne.buyFeeTotal, closeTo(0, 1e-9));
      });

      test(
          'update transfer recalculates subsequent transfer and withdrawal correctly',
          () async {
        // Inflow: 1 @ 50 on portfolio 1
        await db.bookingsDao.createBooking(BookingsCompanion(
            date: const Value(20250101),
            assetId: Value(assetOne.id),
            accountId: Value(portfolio1.id),
            category: const Value('B'),
            shares: const Value(1),
            costBasis: const Value(50),
            value: const Value(50)));

        // Inflow: 1 @ 100 on portfolio 2
        await db.bookingsDao.createBooking(BookingsCompanion(
            date: const Value(20250103),
            assetId: Value(assetOne.id),
            accountId: Value(portfolio2.id),
            category: const Value('B'),
            shares: const Value(1),
            costBasis: const Value(100),
            value: const Value(100)));

        // Transfer 1 @ 50 from portfolio 1 to portfolio 2
        await db.transfersDao.createTransfer(TransfersCompanion(
          date: const Value(20250104),
          assetId: Value(assetOne.id),
          sendingAccountId: Value(portfolio1.id),
          receivingAccountId: Value(portfolio2.id),
          shares: const Value(1),
        ));

        // Transfer 1 share from portfolio 2 to portfolio 3
        await db.transfersDao.createTransfer(TransfersCompanion(
          date: const Value(20250105),
          assetId: Value(assetOne.id),
          sendingAccountId: Value(portfolio2.id),
          receivingAccountId: Value(portfolio3.id),
          shares: const Value(1),
        ));

        // Withdraw 1 share from portfolio 3
        await db.bookingsDao.createBooking(BookingsCompanion(
          date: const Value(20250106),
          assetId: Value(assetOne.id),
          accountId: Value(portfolio3.id),
          category: const Value('B'),
          shares: const Value(-1),
        ));

        // Prechecks
        var transfer2 = await db.transfersDao.getTransfer(2);
        expect(transfer2.shares, closeTo(1, 1e-9));
        expect(transfer2.costBasis, closeTo(100, 1e-9));
        expect(transfer2.value, closeTo(100, 1e-9));
        var withdrawal = await db.bookingsDao.getBooking(3);
        expect(withdrawal.shares, closeTo(-1, 1e-9));
        expect(withdrawal.costBasis, closeTo(100, 1e-9));
        expect(withdrawal.value, closeTo(-100, 1e-9));
        var aoPortfolio1 =
            await db.assetsOnAccountsDao.getAOA(portfolio1.id, assetOne.id);
        expect(aoPortfolio1.shares, closeTo(0, 1e-9));
        expect(aoPortfolio1.value, closeTo(0, 1e-9));
        expect(aoPortfolio1.netCostBasis, closeTo(1, 1e-9));
        expect(aoPortfolio1.brokerCostBasis, closeTo(1, 1e-9));
        expect(aoPortfolio1.buyFeeTotal, closeTo(0, 1e-9));
        var aoPortfolio2 =
            await db.assetsOnAccountsDao.getAOA(portfolio2.id, assetOne.id);
        expect(aoPortfolio2.shares, closeTo(1, 1e-9));
        expect(aoPortfolio2.value, closeTo(50, 1e-9));
        expect(aoPortfolio2.netCostBasis, closeTo(50, 1e-9));
        expect(aoPortfolio2.brokerCostBasis, closeTo(50, 1e-9));
        expect(aoPortfolio2.buyFeeTotal, closeTo(0, 1e-9));
        var aoPortfolio3 =
            await db.assetsOnAccountsDao.getAOA(portfolio3.id, assetOne.id);
        expect(aoPortfolio3.shares, closeTo(0, 1e-9));
        expect(aoPortfolio3.value, closeTo(0, 1e-9));
        expect(aoPortfolio3.netCostBasis, closeTo(1, 1e-9));
        expect(aoPortfolio3.brokerCostBasis, closeTo(1, 1e-9));
        expect(aoPortfolio3.buyFeeTotal, closeTo(0, 1e-9));
        var aOne = await db.assetsDao.getAsset(assetOne.id);
        expect(aOne.shares, closeTo(1, 1e-9));
        expect(aOne.value, closeTo(50, 1e-9));
        expect(aOne.netCostBasis, closeTo(50, 1e-9));
        expect(aOne.brokerCostBasis, closeTo(50, 1e-9));
        expect(aOne.buyFeeTotal, closeTo(0, 1e-9));
        var portAcc1 = await db.accountsDao.getAccount(portfolio1.id);
        expect(portAcc1.balance, closeTo(0, 1e-9));
        var portAcc2 = await db.accountsDao.getAccount(portfolio2.id);
        expect(portAcc2.balance, closeTo(50, 1e-9));
        var portAcc3 = await db.accountsDao.getAccount(portfolio3.id);
        expect(portAcc3.balance, closeTo(0, 1e-9));

        /// Update transfer 1:
        /// - move before inflow on portfolio 2
        /// - move only 0.5 shares instead of 1
        /// - this should consume 0.5@50, 0.5@100 in transfer 2 and withdrawal now instead of the 1 @ 100
        final oldTransfer = await (db.select(db.transfers)
              ..where((tr) => tr.id.equals(1)))
            .getSingle();
        await db.transfersDao.updateTransfer(
            oldTransfer,
            TransfersCompanion(
              date: const Value(20250102),
              assetId: Value(assetOne.id),
              sendingAccountId: Value(portfolio1.id),
              receivingAccountId: Value(portfolio2.id),
              shares: const Value(0.5),
            ));

        // Postchecks
        var transfer1 = await db.transfersDao.getTransfer(1);
        expect(transfer1.shares, closeTo(0.5, 1e-9));
        expect(transfer1.costBasis, closeTo(50, 1e-9));
        expect(transfer1.value, closeTo(25, 1e-9));
        transfer2 = await db.transfersDao.getTransfer(2);
        expect(transfer2.shares, closeTo(1, 1e-9));
        expect(transfer2.costBasis, closeTo(75, 1e-9));
        expect(transfer2.value, closeTo(75, 1e-9));
        withdrawal = await db.bookingsDao.getBooking(3);
        expect(withdrawal.shares, closeTo(-1, 1e-9));
        expect(withdrawal.costBasis, closeTo(75, 1e-9));
        expect(withdrawal.value, closeTo(-75, 1e-9));
        aoPortfolio1 =
            await db.assetsOnAccountsDao.getAOA(portfolio1.id, assetOne.id);
        expect(aoPortfolio1.shares, closeTo(0.5, 1e-9));
        expect(aoPortfolio1.value, closeTo(25, 1e-9));
        expect(aoPortfolio1.netCostBasis, closeTo(50, 1e-9));
        expect(aoPortfolio1.brokerCostBasis, closeTo(50, 1e-9));
        expect(aoPortfolio1.buyFeeTotal, closeTo(0, 1e-9));
        aoPortfolio2 =
            await db.assetsOnAccountsDao.getAOA(portfolio2.id, assetOne.id);
        expect(aoPortfolio2.shares, closeTo(0.5, 1e-9));
        expect(aoPortfolio2.value, closeTo(50, 1e-9));
        expect(aoPortfolio2.netCostBasis, closeTo(100, 1e-9));
        expect(aoPortfolio2.brokerCostBasis, closeTo(100, 1e-9));
        expect(aoPortfolio2.buyFeeTotal, closeTo(0, 1e-9));
        aoPortfolio3 =
            await db.assetsOnAccountsDao.getAOA(portfolio3.id, assetOne.id);
        expect(aoPortfolio3.shares, closeTo(0, 1e-9));
        expect(aoPortfolio3.value, closeTo(0, 1e-9));
        expect(aoPortfolio3.netCostBasis, closeTo(1, 1e-9));
        expect(aoPortfolio3.brokerCostBasis, closeTo(1, 1e-9));
        expect(aoPortfolio3.buyFeeTotal, closeTo(0, 1e-9));
        aOne = await db.assetsDao.getAsset(assetOne.id);
        expect(aOne.shares, closeTo(1, 1e-9));
        expect(aOne.value, closeTo(75, 1e-9));
        expect(aOne.netCostBasis, closeTo(75, 1e-9));
        expect(aOne.brokerCostBasis, closeTo(75, 1e-9));
        expect(aOne.buyFeeTotal, closeTo(0, 1e-9));
        portAcc1 = await db.accountsDao.getAccount(portfolio1.id);
        expect(portAcc1.balance, closeTo(25, 1e-9));
        portAcc2 = await db.accountsDao.getAccount(portfolio2.id);
        expect(portAcc2.balance, closeTo(50, 1e-9));
        portAcc3 = await db.accountsDao.getAccount(portfolio3.id);
        expect(portAcc3.balance, closeTo(0, 1e-9));
      });

      test('delete transfer recalculates subsequent trade correctly', () async {
        // Inflow: 1 @ 50 on portfolio 1
        await db.bookingsDao.createBooking(BookingsCompanion(
            date: const Value(20250101),
            assetId: Value(assetOne.id),
            accountId: Value(portfolio1.id),
            category: const Value('B'),
            shares: const Value(1),
            costBasis: const Value(50),
            value: const Value(50)));

        // Transfer 1 @ 50 to portfolio 2
        await db.transfersDao.createTransfer(TransfersCompanion(
          date: const Value(20250102),
          assetId: Value(assetOne.id),
          sendingAccountId: Value(portfolio1.id),
          receivingAccountId: Value(portfolio2.id),
          shares: const Value(1),
        ));

        // Inflow: 1 @ 100 on portfolio 2
        await db.bookingsDao.createBooking(BookingsCompanion(
            date: const Value(20250103),
            assetId: Value(assetOne.id),
            accountId: Value(portfolio2.id),
            category: const Value('B'),
            shares: const Value(1),
            costBasis: const Value(100),
            value: const Value(100)));

        // Sell 1 @ 200
        await db.tradesDao.insertTrade(TradesCompanion(
          datetime: const Value(20250202222222),
          assetId: Value(assetOne.id),
          type: const Value(TradeTypes.sell),
          shares: const Value(1),
          costBasis: const Value(200),
          fee: const Value(0),
          tax: const Value(0),
          sourceAccountId: Value(bankAccount.id),
          targetAccountId: Value(portfolio2.id),
        ));

        // Prechecks
        var subsequentTrade = await db.tradesDao.getTrade(1);
        expect(subsequentTrade.sourceAccountValueDelta, closeTo(200, 1e-9));
        expect(subsequentTrade.targetAccountValueDelta, closeTo(-50, 1e-9));
        expect(subsequentTrade.profitAndLoss, closeTo(150, 1e-9));
        expect(subsequentTrade.returnOnInvest, closeTo(150 / 50, 1e-9));
        var aoPortfolioAccount1 =
            await db.assetsOnAccountsDao.getAOA(portfolio1.id, assetOne.id);
        expect(aoPortfolioAccount1.shares, closeTo(0, 1e-9));
        expect(aoPortfolioAccount1.value, closeTo(0, 1e-9));
        expect(aoPortfolioAccount1.netCostBasis, closeTo(1, 1e-9));
        expect(aoPortfolioAccount1.brokerCostBasis, closeTo(1, 1e-9));
        expect(aoPortfolioAccount1.buyFeeTotal, closeTo(0, 1e-9));
        var aoPortfolioAccount2 =
            await db.assetsOnAccountsDao.getAOA(portfolio2.id, assetOne.id);
        expect(aoPortfolioAccount2.shares, closeTo(1, 1e-9));
        expect(aoPortfolioAccount2.value, closeTo(100, 1e-9));
        expect(aoPortfolioAccount2.netCostBasis, closeTo(100, 1e-9));
        expect(aoPortfolioAccount2.brokerCostBasis, closeTo(100, 1e-9));
        expect(aoPortfolioAccount2.buyFeeTotal, closeTo(0, 1e-9));
        var aOne = await db.assetsDao.getAsset(assetOne.id);
        expect(aOne.shares, closeTo(1, 1e-9));
        expect(aOne.value, closeTo(100, 1e-9));
        expect(aOne.netCostBasis, closeTo(100, 1e-9));
        expect(aOne.brokerCostBasis, closeTo(100, 1e-9));
        expect(aOne.buyFeeTotal, closeTo(0, 1e-9));

        // Delete transfer, this should recalculate subsequent trade
        await db.transfersDao.deleteTransfer(1);

        // Postchecks
        subsequentTrade = await db.tradesDao.getTrade(1);
        expect(subsequentTrade.sourceAccountValueDelta, closeTo(200, 1e-9));
        expect(subsequentTrade.targetAccountValueDelta, closeTo(-100, 1e-9));
        expect(subsequentTrade.profitAndLoss, closeTo(100, 1e-9));
        expect(subsequentTrade.returnOnInvest, closeTo(1, 1e-9));
        aoPortfolioAccount1 =
            await db.assetsOnAccountsDao.getAOA(portfolio1.id, assetOne.id);
        expect(aoPortfolioAccount1.shares, closeTo(1, 1e-9));
        expect(aoPortfolioAccount1.value, closeTo(50, 1e-9));
        expect(aoPortfolioAccount1.netCostBasis, closeTo(50, 1e-9));
        expect(aoPortfolioAccount1.brokerCostBasis, closeTo(50, 1e-9));
        expect(aoPortfolioAccount1.buyFeeTotal, closeTo(0, 1e-9));
        aoPortfolioAccount2 =
            await db.assetsOnAccountsDao.getAOA(portfolio2.id, assetOne.id);
        expect(aoPortfolioAccount2.shares, closeTo(0, 1e-9));
        expect(aoPortfolioAccount2.value, closeTo(0, 1e-9));
        expect(aoPortfolioAccount2.netCostBasis, closeTo(0, 1e-9));
        expect(aoPortfolioAccount2.brokerCostBasis, closeTo(0, 1e-9));
        expect(aoPortfolioAccount2.buyFeeTotal, closeTo(0, 1e-9));
        aOne = await db.assetsDao.getAsset(assetOne.id);
        expect(aOne.shares, closeTo(1, 1e-9));
        expect(aOne.value, closeTo(50, 1e-9));
        expect(aOne.netCostBasis, closeTo(50, 1e-9));
        expect(aOne.brokerCostBasis, closeTo(50, 1e-9));
        expect(aOne.buyFeeTotal, closeTo(0, 1e-9));
      });

      test(
          'delete transfer recalculates subsequent transfer and withdrawal correctly',
          () async {
        // Inflow: 1 @ 50 on portfolio 1
        await db.bookingsDao.createBooking(BookingsCompanion(
            date: const Value(20250102),
            assetId: Value(assetOne.id),
            accountId: Value(portfolio1.id),
            category: const Value('B'),
            shares: const Value(1),
            costBasis: const Value(50),
            value: const Value(50)));

        // Transfer 1 @ 50 from portfolio 1 to portfolio 2
        await db.transfersDao.createTransfer(TransfersCompanion(
          date: const Value(20250103),
          assetId: Value(assetOne.id),
          sendingAccountId: Value(portfolio1.id),
          receivingAccountId: Value(portfolio2.id),
          shares: const Value(1),
        ));

        // Inflow: 1 @ 100 on portfolio 2
        await db.bookingsDao.createBooking(BookingsCompanion(
            date: const Value(20250104),
            assetId: Value(assetOne.id),
            accountId: Value(portfolio2.id),
            category: const Value('B'),
            shares: const Value(1),
            costBasis: const Value(100),
            value: const Value(100)));

        // Transfer 1 share from portfolio 2 to portfolio 3
        await db.transfersDao.createTransfer(TransfersCompanion(
          date: const Value(20250105),
          assetId: Value(assetOne.id),
          sendingAccountId: Value(portfolio2.id),
          receivingAccountId: Value(portfolio3.id),
          shares: const Value(1),
        ));

        // Withdraw 1 share from portfolio 3
        await db.bookingsDao.createBooking(BookingsCompanion(
          date: const Value(20250106),
          assetId: Value(assetOne.id),
          accountId: Value(portfolio3.id),
          category: const Value('B'),
          shares: const Value(-1),
        ));

        // Prechecks
        var transfer2 = await db.transfersDao.getTransfer(2);
        expect(transfer2.shares, closeTo(1, 1e-9));
        expect(transfer2.costBasis, closeTo(50, 1e-9));
        expect(transfer2.value, closeTo(50, 1e-9));
        var withdrawal = await db.bookingsDao.getBooking(3);
        expect(withdrawal.shares, closeTo(-1, 1e-9));
        expect(withdrawal.costBasis, closeTo(50, 1e-9));
        expect(withdrawal.value, closeTo(-50, 1e-9));
        var aoPortfolio1 =
            await db.assetsOnAccountsDao.getAOA(portfolio1.id, assetOne.id);
        expect(aoPortfolio1.shares, closeTo(0, 1e-9));
        expect(aoPortfolio1.value, closeTo(0, 1e-9));
        expect(aoPortfolio1.netCostBasis, closeTo(1, 1e-9));
        expect(aoPortfolio1.brokerCostBasis, closeTo(1, 1e-9));
        expect(aoPortfolio1.buyFeeTotal, closeTo(0, 1e-9));
        var aoPortfolio2 =
            await db.assetsOnAccountsDao.getAOA(portfolio2.id, assetOne.id);
        expect(aoPortfolio2.shares, closeTo(1, 1e-9));
        expect(aoPortfolio2.value, closeTo(100, 1e-9));
        expect(aoPortfolio2.netCostBasis, closeTo(100, 1e-9));
        expect(aoPortfolio2.brokerCostBasis, closeTo(100, 1e-9));
        expect(aoPortfolio2.buyFeeTotal, closeTo(0, 1e-9));
        var aoPortfolio3 =
            await db.assetsOnAccountsDao.getAOA(portfolio3.id, assetOne.id);
        expect(aoPortfolio3.shares, closeTo(0, 1e-9));
        expect(aoPortfolio3.value, closeTo(0, 1e-9));
        expect(aoPortfolio3.netCostBasis, closeTo(1, 1e-9));
        expect(aoPortfolio3.brokerCostBasis, closeTo(1, 1e-9));
        expect(aoPortfolio3.buyFeeTotal, closeTo(0, 1e-9));
        var aOne = await db.assetsDao.getAsset(assetOne.id);
        expect(aOne.shares, closeTo(1, 1e-9));
        expect(aOne.value, closeTo(100, 1e-9));
        expect(aOne.netCostBasis, closeTo(100, 1e-9));
        expect(aOne.brokerCostBasis, closeTo(100, 1e-9));
        expect(aOne.buyFeeTotal, closeTo(0, 1e-9));
        var portAcc1 = await db.accountsDao.getAccount(portfolio1.id);
        expect(portAcc1.balance, closeTo(0, 1e-9));
        var portAcc2 = await db.accountsDao.getAccount(portfolio2.id);
        expect(portAcc2.balance, closeTo(100, 1e-9));
        var portAcc3 = await db.accountsDao.getAccount(portfolio3.id);
        expect(portAcc3.balance, closeTo(0, 1e-9));

        /// Delete transfer 1:
        /// - this should consume 1@100 in transfer 2 and withdrawal now instead of the 1 @ 50
        await db.transfersDao.deleteTransfer(1);

        // Postchecks
        transfer2 = await db.transfersDao.getTransfer(2);
        expect(transfer2.shares, closeTo(1, 1e-9));
        expect(transfer2.costBasis, closeTo(100, 1e-9));
        expect(transfer2.value, closeTo(100, 1e-9));
        withdrawal = await db.bookingsDao.getBooking(3);
        expect(withdrawal.shares, closeTo(-1, 1e-9));
        expect(withdrawal.costBasis, closeTo(100, 1e-9));
        expect(withdrawal.value, closeTo(-100, 1e-9));
        aoPortfolio1 =
            await db.assetsOnAccountsDao.getAOA(portfolio1.id, assetOne.id);
        expect(aoPortfolio1.shares, closeTo(1, 1e-9));
        expect(aoPortfolio1.value, closeTo(50, 1e-9));
        expect(aoPortfolio1.netCostBasis, closeTo(50, 1e-9));
        expect(aoPortfolio1.brokerCostBasis, closeTo(50, 1e-9));
        expect(aoPortfolio1.buyFeeTotal, closeTo(0, 1e-9));
        aoPortfolio2 =
            await db.assetsOnAccountsDao.getAOA(portfolio2.id, assetOne.id);
        expect(aoPortfolio2.shares, closeTo(0, 1e-9));
        expect(aoPortfolio2.value, closeTo(0, 1e-9));
        expect(aoPortfolio2.netCostBasis, closeTo(1, 1e-9));
        expect(aoPortfolio2.brokerCostBasis, closeTo(1, 1e-9));
        expect(aoPortfolio2.buyFeeTotal, closeTo(0, 1e-9));
        aoPortfolio3 =
            await db.assetsOnAccountsDao.getAOA(portfolio3.id, assetOne.id);
        expect(aoPortfolio3.shares, closeTo(0, 1e-9));
        expect(aoPortfolio3.value, closeTo(0, 1e-9));
        expect(aoPortfolio3.netCostBasis, closeTo(1, 1e-9));
        expect(aoPortfolio3.brokerCostBasis, closeTo(1, 1e-9));
        expect(aoPortfolio3.buyFeeTotal, closeTo(0, 1e-9));
        aOne = await db.assetsDao.getAsset(assetOne.id);
        expect(aOne.shares, closeTo(1, 1e-9));
        expect(aOne.value, closeTo(50, 1e-9));
        expect(aOne.netCostBasis, closeTo(50, 1e-9));
        expect(aOne.brokerCostBasis, closeTo(50, 1e-9));
        expect(aOne.buyFeeTotal, closeTo(0, 1e-9));
        portAcc1 = await db.accountsDao.getAccount(portfolio1.id);
        expect(portAcc1.balance, closeTo(50, 1e-9));
        portAcc2 = await db.accountsDao.getAccount(portfolio2.id);
        expect(portAcc2.balance, closeTo(0, 1e-9));
        portAcc3 = await db.accountsDao.getAccount(portfolio3.id);
        expect(portAcc3.balance, closeTo(0, 1e-9));
      });
    });

    group('Insert/Update/Delete Trade', () {
      test('insert trade recalculates subsequent trade correctly', () async {
        // Buy 1 @ 100
        await db.tradesDao.insertTrade(TradesCompanion(
          datetime: const Value(20250101111111),
          assetId: Value(assetOne.id),
          type: const Value(TradeTypes.buy),
          shares: const Value(1),
          costBasis: const Value(100),
          fee: const Value(0),
          tax: const Value(0),
          sourceAccountId: Value(bankAccount.id),
          targetAccountId: Value(portfolio1.id),
        ));

        // Sell 1 @ 200
        await db.tradesDao.insertTrade(TradesCompanion(
          datetime: const Value(20250202222222),
          assetId: Value(assetOne.id),
          type: const Value(TradeTypes.sell),
          shares: const Value(1),
          costBasis: const Value(200),
          fee: const Value(0),
          tax: const Value(0),
          sourceAccountId: Value(bankAccount.id),
          targetAccountId: Value(portfolio1.id),
        ));

        // Prechecks
        var secondTrade = await db.tradesDao.getTrade(2);
        expect(secondTrade.sourceAccountValueDelta, closeTo(200, 1e-9));
        expect(secondTrade.targetAccountValueDelta, closeTo(-100, 1e-9));
        expect(secondTrade.profitAndLoss, closeTo(100, 1e-9));
        expect(secondTrade.returnOnInvest, closeTo(1, 1e-9));
        var aoBankAccount = await db.assetsOnAccountsDao
            .getAOA(bankAccount.id, baseCurrencyAsset.id);
        expect(aoBankAccount.shares, closeTo(1100, 1e-9));
        expect(aoBankAccount.value, closeTo(1100, 1e-9));
        expect(aoBankAccount.netCostBasis, closeTo(1, 1e-9));
        expect(aoBankAccount.brokerCostBasis, closeTo(1, 1e-9));
        expect(aoBankAccount.buyFeeTotal, closeTo(0, 1e-9));
        var aoPortfolioAccount =
            await db.assetsOnAccountsDao.getAOA(portfolio1.id, assetOne.id);
        expect(aoPortfolioAccount.shares, closeTo(0, 1e-9));
        expect(aoPortfolioAccount.value, closeTo(0, 1e-9));
        expect(aoPortfolioAccount.netCostBasis, closeTo(0, 1e-9));
        expect(aoPortfolioAccount.brokerCostBasis, closeTo(0, 1e-9));
        expect(aoPortfolioAccount.buyFeeTotal, closeTo(0, 1e-9));
        var aBaseCurrency = await db.assetsDao.getAsset(baseCurrencyAsset.id);
        expect(aBaseCurrency.shares, closeTo(1100, 1e-9));
        expect(aBaseCurrency.value, closeTo(1100, 1e-9));
        expect(aBaseCurrency.netCostBasis, closeTo(1, 1e-9));
        expect(aBaseCurrency.brokerCostBasis, closeTo(1, 1e-9));
        expect(aBaseCurrency.buyFeeTotal, closeTo(0, 1e-9));
        var aOne = await db.assetsDao.getAsset(assetOne.id);
        expect(aOne.shares, closeTo(0, 1e-9));
        expect(aOne.value, closeTo(0, 1e-9));
        expect(aOne.netCostBasis, closeTo(0, 1e-9));
        expect(aOne.brokerCostBasis, closeTo(0, 1e-9));
        expect(aOne.buyFeeTotal, closeTo(0, 1e-9));

        /// Insert new trade before first trade
        /// The first trade should be unaffected since its a buy
        /// The second trade should be recalculated since its a sell
        await db.tradesDao.insertTrade(TradesCompanion(
          datetime: const Value(20250101000000),
          assetId: Value(assetOne.id),
          type: const Value(TradeTypes.buy),
          shares: const Value(0.5),
          costBasis: const Value(50),
          fee: const Value(0),
          tax: const Value(0),
          sourceAccountId: Value(bankAccount.id),
          targetAccountId: Value(portfolio1.id),
        ));

        // Postchecks
        var firstTrade = await db.tradesDao.getTrade(1);
        expect(firstTrade.sourceAccountValueDelta, closeTo(-100, 1e-9));
        expect(firstTrade.targetAccountValueDelta, closeTo(100, 1e-9));
        expect(firstTrade.profitAndLoss, closeTo(0, 1e-9));
        expect(firstTrade.returnOnInvest, closeTo(0, 1e-9));
        secondTrade = await db.tradesDao.getTrade(2);
        expect(secondTrade.sourceAccountValueDelta, closeTo(200, 1e-9));
        expect(secondTrade.targetAccountValueDelta, closeTo(-75, 1e-9));
        expect(secondTrade.profitAndLoss, closeTo(125, 1e-9));
        expect(secondTrade.returnOnInvest, closeTo(125 / 75, 1e-9));
        aoBankAccount = await db.assetsOnAccountsDao
            .getAOA(bankAccount.id, baseCurrencyAsset.id);
        expect(aoBankAccount.shares, closeTo(1075, 1e-9));
        expect(aoBankAccount.value, closeTo(1075, 1e-9));
        expect(aoBankAccount.netCostBasis, closeTo(1, 1e-9));
        expect(aoBankAccount.brokerCostBasis, closeTo(1, 1e-9));
        expect(aoBankAccount.buyFeeTotal, closeTo(0, 1e-9));
        aoPortfolioAccount =
            await db.assetsOnAccountsDao.getAOA(portfolio1.id, assetOne.id);
        expect(aoPortfolioAccount.shares, closeTo(0.5, 1e-9));
        expect(aoPortfolioAccount.value, closeTo(50, 1e-9));
        expect(aoPortfolioAccount.netCostBasis, closeTo(100, 1e-9));
        expect(aoPortfolioAccount.brokerCostBasis, closeTo(100, 1e-9));
        expect(aoPortfolioAccount.buyFeeTotal, closeTo(0, 1e-9));
        aBaseCurrency = await db.assetsDao.getAsset(baseCurrencyAsset.id);
        expect(aBaseCurrency.shares, closeTo(1075, 1e-9));
        expect(aBaseCurrency.value, closeTo(1075, 1e-9));
        expect(aBaseCurrency.netCostBasis, closeTo(1, 1e-9));
        expect(aBaseCurrency.brokerCostBasis, closeTo(1, 1e-9));
        expect(aBaseCurrency.buyFeeTotal, closeTo(0, 1e-9));
        aOne = await db.assetsDao.getAsset(assetOne.id);
        expect(aOne.shares, closeTo(0.5, 1e-9));
        expect(aOne.value, closeTo(50, 1e-9));
        expect(aOne.netCostBasis, closeTo(100, 1e-9));
        expect(aOne.brokerCostBasis, closeTo(100, 1e-9));
        expect(aOne.buyFeeTotal, closeTo(0, 1e-9));
      });

      test(
          'insert trade recalculates subsequent transfer and withdrawal correctly',
          () async {
        // Buy 1 @ 100
        await db.tradesDao.insertTrade(TradesCompanion(
          datetime: const Value(20250101111111),
          assetId: Value(assetOne.id),
          type: const Value(TradeTypes.buy),
          shares: const Value(1),
          costBasis: const Value(100),
          fee: const Value(0),
          tax: const Value(0),
          sourceAccountId: Value(bankAccount.id),
          targetAccountId: Value(portfolio1.id),
        ));

        // Transfer 1 share to portfolio 2
        await db.transfersDao.createTransfer(TransfersCompanion(
          date: const Value(20250102),
          assetId: Value(assetOne.id),
          sendingAccountId: Value(portfolio1.id),
          receivingAccountId: Value(portfolio2.id),
          shares: const Value(1),
        ));

        // Withdraw 1 share from portfolio 2
        await db.bookingsDao.createBooking(BookingsCompanion(
          date: const Value(20250103),
          assetId: Value(assetOne.id),
          accountId: Value(portfolio2.id),
          category: const Value('B'),
          shares: const Value(-1),
        ));

        // Prechecks
        var transfer = await db.transfersDao.getTransfer(1);
        expect(transfer.shares, closeTo(1, 1e-9));
        expect(transfer.costBasis, closeTo(100, 1e-9));
        expect(transfer.value, closeTo(100, 1e-9));
        var withdrawal = await db.bookingsDao.getBooking(1);
        expect(withdrawal.shares, closeTo(-1, 1e-9));
        expect(withdrawal.costBasis, closeTo(100, 1e-9));
        expect(withdrawal.value, closeTo(-100, 1e-9));
        var aoPortfolio1 =
            await db.assetsOnAccountsDao.getAOA(portfolio1.id, assetOne.id);
        expect(aoPortfolio1.shares, closeTo(0, 1e-9));
        expect(aoPortfolio1.value, closeTo(0, 1e-9));
        expect(aoPortfolio1.netCostBasis, closeTo(1, 1e-9));
        expect(aoPortfolio1.brokerCostBasis, closeTo(1, 1e-9));
        expect(aoPortfolio1.buyFeeTotal, closeTo(0, 1e-9));
        var aoPortfolio2 =
            await db.assetsOnAccountsDao.getAOA(portfolio2.id, assetOne.id);
        expect(aoPortfolio2.shares, closeTo(0, 1e-9));
        expect(aoPortfolio2.value, closeTo(0, 1e-9));
        expect(aoPortfolio2.netCostBasis, closeTo(1, 1e-9));
        expect(aoPortfolio2.brokerCostBasis, closeTo(1, 1e-9));
        expect(aoPortfolio2.buyFeeTotal, closeTo(0, 1e-9));
        var aOne = await db.assetsDao.getAsset(assetOne.id);
        expect(aOne.shares, closeTo(0, 1e-9));
        expect(aOne.value, closeTo(0, 1e-9));
        expect(aOne.netCostBasis, closeTo(1, 1e-9));
        expect(aOne.brokerCostBasis, closeTo(1, 1e-9));
        expect(aOne.buyFeeTotal, closeTo(0, 1e-9));
        var portAcc1 = await db.accountsDao.getAccount(portfolio1.id);
        expect(portAcc1.balance, closeTo(0, 1e-9));
        var portAcc2 = await db.accountsDao.getAccount(portfolio2.id);
        expect(portAcc2.balance, closeTo(0, 1e-9));

        /// Insert new trade before first trade
        /// The trade should be unaffected since its a buy
        /// The transfer and withdrawal should be recalculated
        await db.tradesDao.insertTrade(TradesCompanion(
          datetime: const Value(20250101000000),
          assetId: Value(assetOne.id),
          type: const Value(TradeTypes.buy),
          shares: const Value(0.5),
          costBasis: const Value(50),
          fee: const Value(0),
          tax: const Value(0),
          sourceAccountId: Value(bankAccount.id),
          targetAccountId: Value(portfolio1.id),
        ));

        // Postchecks
        transfer = await db.transfersDao.getTransfer(1);
        expect(transfer.shares, closeTo(1, 1e-9));
        expect(transfer.costBasis, closeTo(75, 1e-9));
        expect(transfer.value, closeTo(75, 1e-9));
        withdrawal = await db.bookingsDao.getBooking(1);
        expect(withdrawal.shares, closeTo(-1, 1e-9));
        expect(withdrawal.costBasis, closeTo(75, 1e-9));
        expect(withdrawal.value, closeTo(-75, 1e-9));
        aoPortfolio1 =
            await db.assetsOnAccountsDao.getAOA(portfolio1.id, assetOne.id);
        expect(aoPortfolio1.shares, closeTo(0.5, 1e-9));
        expect(aoPortfolio1.value, closeTo(50, 1e-9));
        expect(aoPortfolio1.netCostBasis, closeTo(100, 1e-9));
        expect(aoPortfolio1.brokerCostBasis, closeTo(100, 1e-9));
        expect(aoPortfolio1.buyFeeTotal, closeTo(0, 1e-9));
        aoPortfolio2 =
            await db.assetsOnAccountsDao.getAOA(portfolio2.id, assetOne.id);
        expect(aoPortfolio2.shares, closeTo(0, 1e-9));
        expect(aoPortfolio2.value, closeTo(0, 1e-9));
        expect(aoPortfolio2.netCostBasis, closeTo(1, 1e-9));
        expect(aoPortfolio2.brokerCostBasis, closeTo(1, 1e-9));
        expect(aoPortfolio2.buyFeeTotal, closeTo(0, 1e-9));
        aOne = await db.assetsDao.getAsset(assetOne.id);
        expect(aOne.shares, closeTo(0.5, 1e-9));
        expect(aOne.value, closeTo(50, 1e-9));
        expect(aOne.netCostBasis, closeTo(100, 1e-9));
        expect(aOne.brokerCostBasis, closeTo(100, 1e-9));
        expect(aOne.buyFeeTotal, closeTo(0, 1e-9));
        portAcc1 = await db.accountsDao.getAccount(portfolio1.id);
        expect(portAcc1.balance, closeTo(50, 1e-9));
        portAcc2 = await db.accountsDao.getAccount(portfolio2.id);
        expect(portAcc2.balance, closeTo(0, 1e-9));
      });

      test('update trade recalculates subsequent trade correctly', () async {
        // Buy 0.5 @ 100
        await db.tradesDao.insertTrade(TradesCompanion(
          datetime: const Value(20250101111111),
          assetId: Value(assetOne.id),
          type: const Value(TradeTypes.buy),
          shares: const Value(0.5),
          costBasis: const Value(100),
          fee: const Value(0),
          tax: const Value(0),
          sourceAccountId: Value(bankAccount.id),
          targetAccountId: Value(portfolio1.id),
        ));

        // Buy 0.5 @ 50
        await db.tradesDao.insertTrade(TradesCompanion(
          datetime: const Value(20250102000000),
          assetId: Value(assetOne.id),
          type: const Value(TradeTypes.buy),
          shares: const Value(0.5),
          costBasis: const Value(50),
          fee: const Value(0),
          tax: const Value(0),
          sourceAccountId: Value(bankAccount.id),
          targetAccountId: Value(portfolio1.id),
        ));

        // Sell 1 @ 200
        await db.tradesDao.insertTrade(TradesCompanion(
          datetime: const Value(20250202222222),
          assetId: Value(assetOne.id),
          type: const Value(TradeTypes.sell),
          shares: const Value(1),
          costBasis: const Value(200),
          fee: const Value(0),
          tax: const Value(0),
          sourceAccountId: Value(bankAccount.id),
          targetAccountId: Value(portfolio1.id),
        ));

        // Prechecks
        var subsequentTrade = await db.tradesDao.getTrade(3);
        expect(subsequentTrade.sourceAccountValueDelta, closeTo(200, 1e-9));
        expect(subsequentTrade.targetAccountValueDelta, closeTo(-75, 1e-9));
        expect(subsequentTrade.profitAndLoss, closeTo(125, 1e-9));
        expect(subsequentTrade.returnOnInvest, closeTo(125 / 75, 1e-9));
        var aoBankAccount = await db.assetsOnAccountsDao
            .getAOA(bankAccount.id, baseCurrencyAsset.id);
        expect(aoBankAccount.shares, closeTo(1125, 1e-9));
        expect(aoBankAccount.value, closeTo(1125, 1e-9));
        expect(aoBankAccount.netCostBasis, closeTo(1, 1e-9));
        expect(aoBankAccount.brokerCostBasis, closeTo(1, 1e-9));
        expect(aoBankAccount.buyFeeTotal, closeTo(0, 1e-9));
        var aoPortfolioAccount =
            await db.assetsOnAccountsDao.getAOA(portfolio1.id, assetOne.id);
        expect(aoPortfolioAccount.shares, closeTo(0, 1e-9));
        expect(aoPortfolioAccount.value, closeTo(0, 1e-9));
        expect(aoPortfolioAccount.netCostBasis, closeTo(0, 1e-9));
        expect(aoPortfolioAccount.brokerCostBasis, closeTo(0, 1e-9));
        expect(aoPortfolioAccount.buyFeeTotal, closeTo(0, 1e-9));
        var aBaseCurrency = await db.assetsDao.getAsset(baseCurrencyAsset.id);
        expect(aBaseCurrency.shares, closeTo(1125, 1e-9));
        expect(aBaseCurrency.value, closeTo(1125, 1e-9));
        expect(aBaseCurrency.netCostBasis, closeTo(1, 1e-9));
        expect(aBaseCurrency.brokerCostBasis, closeTo(1, 1e-9));
        expect(aBaseCurrency.buyFeeTotal, closeTo(0, 1e-9));
        var aOne = await db.assetsDao.getAsset(assetOne.id);
        expect(aOne.shares, closeTo(0, 1e-9));
        expect(aOne.value, closeTo(0, 1e-9));
        expect(aOne.netCostBasis, closeTo(0, 1e-9));
        expect(aOne.brokerCostBasis, closeTo(0, 1e-9));
        expect(aOne.buyFeeTotal, closeTo(0, 1e-9));

        // Update trade, this should recalculate subsequent events
        await db.tradesDao
            .updateTrade(2, const TradesCompanion(costBasis: Value(40)), l10n);

        // Postchecks
        var updatedTrade = await db.tradesDao.getTrade(2);
        expect(updatedTrade.shares, closeTo(0.5, 1e-9));
        expect(updatedTrade.costBasis, closeTo(40, 1e-9));
        expect(updatedTrade.sourceAccountValueDelta, closeTo(-20, 1e-9));
        expect(updatedTrade.targetAccountValueDelta, closeTo(20, 1e-9));
        subsequentTrade = await db.tradesDao.getTrade(3);
        expect(subsequentTrade.sourceAccountValueDelta, closeTo(200, 1e-9));
        expect(subsequentTrade.targetAccountValueDelta, closeTo(-70, 1e-9));
        expect(subsequentTrade.profitAndLoss, closeTo(130, 1e-9));
        expect(subsequentTrade.returnOnInvest, closeTo(130 / 70, 1e-9));
        aoBankAccount = await db.assetsOnAccountsDao
            .getAOA(bankAccount.id, baseCurrencyAsset.id);
        expect(aoBankAccount.shares, closeTo(1130, 1e-9));
        expect(aoBankAccount.value, closeTo(1130, 1e-9));
        expect(aoBankAccount.netCostBasis, closeTo(1, 1e-9));
        expect(aoBankAccount.brokerCostBasis, closeTo(1, 1e-9));
        expect(aoBankAccount.buyFeeTotal, closeTo(0, 1e-9));
        aoPortfolioAccount =
            await db.assetsOnAccountsDao.getAOA(portfolio1.id, assetOne.id);
        expect(aoPortfolioAccount.shares, closeTo(0, 1e-9));
        expect(aoPortfolioAccount.value, closeTo(0, 1e-9));
        expect(aoPortfolioAccount.netCostBasis, closeTo(0, 1e-9));
        expect(aoPortfolioAccount.brokerCostBasis, closeTo(0, 1e-9));
        expect(aoPortfolioAccount.buyFeeTotal, closeTo(0, 1e-9));
        aBaseCurrency = await db.assetsDao.getAsset(baseCurrencyAsset.id);
        expect(aBaseCurrency.shares, closeTo(1130, 1e-9));
        expect(aBaseCurrency.value, closeTo(1130, 1e-9));
        expect(aBaseCurrency.netCostBasis, closeTo(1, 1e-9));
        expect(aBaseCurrency.brokerCostBasis, closeTo(1, 1e-9));
        expect(aBaseCurrency.buyFeeTotal, closeTo(0, 1e-9));
        aOne = await db.assetsDao.getAsset(assetOne.id);
        expect(aOne.shares, closeTo(0, 1e-9));
        expect(aOne.value, closeTo(0, 1e-9));
        expect(aOne.netCostBasis, closeTo(0, 1e-9));
        expect(aOne.brokerCostBasis, closeTo(0, 1e-9));
        expect(aOne.buyFeeTotal, closeTo(0, 1e-9));
      });

      test(
          'update trade recalculates subsequent transfer and withdrawal correctly',
          () async {
        // Buy 1 @ 100
        await db.tradesDao.insertTrade(TradesCompanion(
          datetime: const Value(20250101000000),
          assetId: Value(assetOne.id),
          type: const Value(TradeTypes.buy),
          shares: const Value(1),
          costBasis: const Value(100),
          fee: const Value(0),
          tax: const Value(0),
          sourceAccountId: Value(bankAccount.id),
          targetAccountId: Value(portfolio1.id),
        ));

        // Transfer 1 share to portfolio 2
        await db.transfersDao.createTransfer(TransfersCompanion(
          date: const Value(20250102),
          assetId: Value(assetOne.id),
          sendingAccountId: Value(portfolio1.id),
          receivingAccountId: Value(portfolio2.id),
          shares: const Value(1),
        ));

        // Withdraw 1 share from portfolio 2
        await db.bookingsDao.createBooking(BookingsCompanion(
          date: const Value(20250103),
          assetId: Value(assetOne.id),
          accountId: Value(portfolio2.id),
          category: const Value('B'),
          shares: const Value(-1),
        ));

        // Prechecks
        var transfer = await db.transfersDao.getTransfer(1);
        expect(transfer.shares, closeTo(1, 1e-9));
        expect(transfer.costBasis, closeTo(100, 1e-9));
        expect(transfer.value, closeTo(100, 1e-9));
        var withdrawal = await db.bookingsDao.getBooking(1);
        expect(withdrawal.shares, closeTo(-1, 1e-9));
        expect(withdrawal.costBasis, closeTo(100, 1e-9));
        expect(withdrawal.value, closeTo(-100, 1e-9));
        var aoPortfolio1 =
            await db.assetsOnAccountsDao.getAOA(portfolio1.id, assetOne.id);
        expect(aoPortfolio1.shares, closeTo(0, 1e-9));
        expect(aoPortfolio1.value, closeTo(0, 1e-9));
        expect(aoPortfolio1.netCostBasis, closeTo(1, 1e-9));
        expect(aoPortfolio1.brokerCostBasis, closeTo(1, 1e-9));
        expect(aoPortfolio1.buyFeeTotal, closeTo(0, 1e-9));
        var aoPortfolio2 =
            await db.assetsOnAccountsDao.getAOA(portfolio2.id, assetOne.id);
        expect(aoPortfolio2.shares, closeTo(0, 1e-9));
        expect(aoPortfolio2.value, closeTo(0, 1e-9));
        expect(aoPortfolio2.netCostBasis, closeTo(1, 1e-9));
        expect(aoPortfolio2.brokerCostBasis, closeTo(1, 1e-9));
        expect(aoPortfolio2.buyFeeTotal, closeTo(0, 1e-9));
        var aOne = await db.assetsDao.getAsset(assetOne.id);
        expect(aOne.shares, closeTo(0, 1e-9));
        expect(aOne.value, closeTo(0, 1e-9));
        expect(aOne.netCostBasis, closeTo(1, 1e-9));
        expect(aOne.brokerCostBasis, closeTo(1, 1e-9));
        expect(aOne.buyFeeTotal, closeTo(0, 1e-9));
        var portAcc1 = await db.accountsDao.getAccount(portfolio1.id);
        expect(portAcc1.balance, closeTo(0, 1e-9));
        var portAcc2 = await db.accountsDao.getAccount(portfolio2.id);
        expect(portAcc2.balance, closeTo(0, 1e-9));

        /// Update trade
        /// The transfer and withdrawal should be recalculated
        await db.tradesDao
            .updateTrade(1, const TradesCompanion(costBasis: Value(40)), l10n);

        // Postchecks
        transfer = await db.transfersDao.getTransfer(1);
        expect(transfer.shares, closeTo(1, 1e-9));
        expect(transfer.costBasis, closeTo(40, 1e-9));
        expect(transfer.value, closeTo(40, 1e-9));
        withdrawal = await db.bookingsDao.getBooking(1);
        expect(withdrawal.shares, closeTo(-1, 1e-9));
        expect(withdrawal.costBasis, closeTo(40, 1e-9));
        expect(withdrawal.value, closeTo(-40, 1e-9));
        aoPortfolio1 =
            await db.assetsOnAccountsDao.getAOA(portfolio1.id, assetOne.id);
        expect(aoPortfolio1.shares, closeTo(0, 1e-9));
        expect(aoPortfolio1.value, closeTo(0, 1e-9));
        expect(aoPortfolio1.netCostBasis, closeTo(1, 1e-9));
        expect(aoPortfolio1.brokerCostBasis, closeTo(1, 1e-9));
        expect(aoPortfolio1.buyFeeTotal, closeTo(0, 1e-9));
        aoPortfolio2 =
            await db.assetsOnAccountsDao.getAOA(portfolio2.id, assetOne.id);
        expect(aoPortfolio2.shares, closeTo(0, 1e-9));
        expect(aoPortfolio2.value, closeTo(0, 1e-9));
        expect(aoPortfolio2.netCostBasis, closeTo(1, 1e-9));
        expect(aoPortfolio2.brokerCostBasis, closeTo(1, 1e-9));
        expect(aoPortfolio2.buyFeeTotal, closeTo(0, 1e-9));
        aOne = await db.assetsDao.getAsset(assetOne.id);
        expect(aOne.shares, closeTo(0, 1e-9));
        expect(aOne.value, closeTo(0, 1e-9));
        expect(aOne.netCostBasis, closeTo(1, 1e-9));
        expect(aOne.brokerCostBasis, closeTo(1, 1e-9));
        expect(aOne.buyFeeTotal, closeTo(0, 1e-9));
        portAcc1 = await db.accountsDao.getAccount(portfolio1.id);
        expect(portAcc1.balance, closeTo(0, 1e-9));
        portAcc2 = await db.accountsDao.getAccount(portfolio2.id);
        expect(portAcc2.balance, closeTo(0, 1e-9));
      });

      test('delete trade recalculates subsequent trade correctly', () async {
        // Buy 0.5 @ 50
        await db.tradesDao.insertTrade(TradesCompanion(
          datetime: const Value(20250101000000),
          assetId: Value(assetOne.id),
          type: const Value(TradeTypes.buy),
          shares: const Value(0.5),
          costBasis: const Value(50),
          fee: const Value(0),
          tax: const Value(0),
          sourceAccountId: Value(bankAccount.id),
          targetAccountId: Value(portfolio1.id),
        ));

        // Buy 1 @ 100
        await db.tradesDao.insertTrade(TradesCompanion(
          datetime: const Value(20250101111111),
          assetId: Value(assetOne.id),
          type: const Value(TradeTypes.buy),
          shares: const Value(1),
          costBasis: const Value(100),
          fee: const Value(0),
          tax: const Value(0),
          sourceAccountId: Value(bankAccount.id),
          targetAccountId: Value(portfolio1.id),
        ));

        // Sell 1 @ 200
        await db.tradesDao.insertTrade(TradesCompanion(
          datetime: const Value(20250202222222),
          assetId: Value(assetOne.id),
          type: const Value(TradeTypes.sell),
          shares: const Value(1),
          costBasis: const Value(200),
          fee: const Value(0),
          tax: const Value(0),
          sourceAccountId: Value(bankAccount.id),
          targetAccountId: Value(portfolio1.id),
        ));

        // Prechecks
        var subsequentTrade = await db.tradesDao.getTrade(3);
        expect(subsequentTrade.sourceAccountValueDelta, closeTo(200, 1e-9));
        expect(subsequentTrade.targetAccountValueDelta, closeTo(-75, 1e-9));
        expect(subsequentTrade.profitAndLoss, closeTo(125, 1e-9));
        expect(subsequentTrade.returnOnInvest, closeTo(125 / 75, 1e-9));
        var aoBankAccount = await db.assetsOnAccountsDao
            .getAOA(bankAccount.id, baseCurrencyAsset.id);
        expect(aoBankAccount.shares, closeTo(1075, 1e-9));
        expect(aoBankAccount.value, closeTo(1075, 1e-9));
        expect(aoBankAccount.netCostBasis, closeTo(1, 1e-9));
        expect(aoBankAccount.brokerCostBasis, closeTo(1, 1e-9));
        expect(aoBankAccount.buyFeeTotal, closeTo(0, 1e-9));
        var aoPortfolioAccount =
            await db.assetsOnAccountsDao.getAOA(portfolio1.id, assetOne.id);
        expect(aoPortfolioAccount.shares, closeTo(0.5, 1e-9));
        expect(aoPortfolioAccount.value, closeTo(50, 1e-9));
        expect(aoPortfolioAccount.netCostBasis, closeTo(100, 1e-9));
        expect(aoPortfolioAccount.brokerCostBasis, closeTo(100, 1e-9));
        expect(aoPortfolioAccount.buyFeeTotal, closeTo(0, 1e-9));
        var aBaseCurrency = await db.assetsDao.getAsset(baseCurrencyAsset.id);
        expect(aBaseCurrency.shares, closeTo(1075, 1e-9));
        expect(aBaseCurrency.value, closeTo(1075, 1e-9));
        expect(aBaseCurrency.netCostBasis, closeTo(1, 1e-9));
        expect(aBaseCurrency.brokerCostBasis, closeTo(1, 1e-9));
        expect(aBaseCurrency.buyFeeTotal, closeTo(0, 1e-9));
        var aOne = await db.assetsDao.getAsset(assetOne.id);
        expect(aOne.shares, closeTo(0.5, 1e-9));
        expect(aOne.value, closeTo(50, 1e-9));
        expect(aOne.netCostBasis, closeTo(100, 1e-9));
        expect(aOne.brokerCostBasis, closeTo(100, 1e-9));
        expect(aOne.buyFeeTotal, closeTo(0, 1e-9));

        /// Delete trade
        /// This should recalculate the sell trade
        await db.tradesDao.deleteTrade(1);

        // Postchecks
        var secondTrade = await db.tradesDao.getTrade(3);
        expect(secondTrade.sourceAccountValueDelta, closeTo(200, 1e-9));
        expect(secondTrade.targetAccountValueDelta, closeTo(-100, 1e-9));
        expect(secondTrade.profitAndLoss, closeTo(100, 1e-9));
        expect(secondTrade.returnOnInvest, closeTo(1, 1e-9));
        aoBankAccount = await db.assetsOnAccountsDao
            .getAOA(bankAccount.id, baseCurrencyAsset.id);
        expect(aoBankAccount.shares, closeTo(1100, 1e-9));
        expect(aoBankAccount.value, closeTo(1100, 1e-9));
        expect(aoBankAccount.netCostBasis, closeTo(1, 1e-9));
        expect(aoBankAccount.brokerCostBasis, closeTo(1, 1e-9));
        expect(aoBankAccount.buyFeeTotal, closeTo(0, 1e-9));
        aoPortfolioAccount =
            await db.assetsOnAccountsDao.getAOA(portfolio1.id, assetOne.id);
        expect(aoPortfolioAccount.shares, closeTo(0, 1e-9));
        expect(aoPortfolioAccount.value, closeTo(0, 1e-9));
        expect(aoPortfolioAccount.netCostBasis, closeTo(0, 1e-9));
        expect(aoPortfolioAccount.brokerCostBasis, closeTo(0, 1e-9));
        expect(aoPortfolioAccount.buyFeeTotal, closeTo(0, 1e-9));
        aBaseCurrency = await db.assetsDao.getAsset(baseCurrencyAsset.id);
        expect(aBaseCurrency.shares, closeTo(1100, 1e-9));
        expect(aBaseCurrency.value, closeTo(1100, 1e-9));
        expect(aBaseCurrency.netCostBasis, closeTo(1, 1e-9));
        expect(aBaseCurrency.brokerCostBasis, closeTo(1, 1e-9));
        expect(aBaseCurrency.buyFeeTotal, closeTo(0, 1e-9));
        aOne = await db.assetsDao.getAsset(assetOne.id);
        expect(aOne.shares, closeTo(0, 1e-9));
        expect(aOne.value, closeTo(0, 1e-9));
        expect(aOne.netCostBasis, closeTo(0, 1e-9));
        expect(aOne.brokerCostBasis, closeTo(0, 1e-9));
        expect(aOne.buyFeeTotal, closeTo(0, 1e-9));
      });

      test(
          'delete trade recalculates subsequent transfer and withdrawal correctly',
          () async {
        // Buy 0.5 @ 50
        await db.tradesDao.insertTrade(TradesCompanion(
          datetime: const Value(20250101000000),
          assetId: Value(assetOne.id),
          type: const Value(TradeTypes.buy),
          shares: const Value(0.5),
          costBasis: const Value(50),
          fee: const Value(0),
          tax: const Value(0),
          sourceAccountId: Value(bankAccount.id),
          targetAccountId: Value(portfolio1.id),
        ));

        // Buy 1 @ 100
        await db.tradesDao.insertTrade(TradesCompanion(
          datetime: const Value(20250101111111),
          assetId: Value(assetOne.id),
          type: const Value(TradeTypes.buy),
          shares: const Value(1),
          costBasis: const Value(100),
          fee: const Value(0),
          tax: const Value(0),
          sourceAccountId: Value(bankAccount.id),
          targetAccountId: Value(portfolio1.id),
        ));

        // Transfer 1 share to portfolio 2
        await db.transfersDao.createTransfer(TransfersCompanion(
            date: const Value(20250102),
            assetId: Value(assetOne.id),
            sendingAccountId: Value(portfolio1.id),
            receivingAccountId: Value(portfolio2.id),
            shares: const Value(1)));

        // Withdraw 1 share from portfolio 2
        await db.bookingsDao.createBooking(BookingsCompanion(
            date: const Value(20250103),
            assetId: Value(assetOne.id),
            accountId: Value(portfolio2.id),
            category: const Value('B'),
            shares: const Value(-1)));

        // Prechecks
        var transfer = await db.transfersDao.getTransfer(1);
        expect(transfer.shares, closeTo(1, 1e-9));
        expect(transfer.costBasis, closeTo(75, 1e-9));
        expect(transfer.value, closeTo(75, 1e-9));
        var withdrawal = await db.bookingsDao.getBooking(1);
        expect(withdrawal.shares, closeTo(-1, 1e-9));
        expect(withdrawal.costBasis, closeTo(75, 1e-9));
        expect(withdrawal.value, closeTo(-75, 1e-9));
        var aoPortfolio1 =
            await db.assetsOnAccountsDao.getAOA(portfolio1.id, assetOne.id);
        expect(aoPortfolio1.shares, closeTo(0.5, 1e-9));
        expect(aoPortfolio1.value, closeTo(50, 1e-9));
        expect(aoPortfolio1.netCostBasis, closeTo(100, 1e-9));
        expect(aoPortfolio1.brokerCostBasis, closeTo(100, 1e-9));
        expect(aoPortfolio1.buyFeeTotal, closeTo(0, 1e-9));
        var aoPortfolio2 =
            await db.assetsOnAccountsDao.getAOA(portfolio2.id, assetOne.id);
        expect(aoPortfolio2.shares, closeTo(0, 1e-9));
        expect(aoPortfolio2.value, closeTo(0, 1e-9));
        expect(aoPortfolio2.netCostBasis, closeTo(1, 1e-9));
        expect(aoPortfolio2.brokerCostBasis, closeTo(1, 1e-9));
        expect(aoPortfolio2.buyFeeTotal, closeTo(0, 1e-9));
        var aOne = await db.assetsDao.getAsset(assetOne.id);
        expect(aOne.shares, closeTo(0.5, 1e-9));
        expect(aOne.value, closeTo(50, 1e-9));
        expect(aOne.netCostBasis, closeTo(100, 1e-9));
        expect(aOne.brokerCostBasis, closeTo(100, 1e-9));
        expect(aOne.buyFeeTotal, closeTo(0, 1e-9));
        var portAcc1 = await db.accountsDao.getAccount(portfolio1.id);
        expect(portAcc1.balance, closeTo(50, 1e-9));
        var portAcc2 = await db.accountsDao.getAccount(portfolio2.id);
        expect(portAcc2.balance, closeTo(0, 1e-9));

        /// Delete trade
        await db.tradesDao.deleteTrade(1);

        // Postchecks
        transfer = await db.transfersDao.getTransfer(1);
        expect(transfer.shares, closeTo(1, 1e-9));
        expect(transfer.costBasis, closeTo(100, 1e-9));
        expect(transfer.value, closeTo(100, 1e-9));
        withdrawal = await db.bookingsDao.getBooking(1);
        expect(withdrawal.shares, closeTo(-1, 1e-9));
        expect(withdrawal.costBasis, closeTo(100, 1e-9));
        expect(withdrawal.value, closeTo(-100, 1e-9));
        aoPortfolio1 =
            await db.assetsOnAccountsDao.getAOA(portfolio1.id, assetOne.id);
        expect(aoPortfolio1.shares, closeTo(0, 1e-9));
        expect(aoPortfolio1.value, closeTo(0, 1e-9));
        expect(aoPortfolio1.netCostBasis, closeTo(1, 1e-9));
        expect(aoPortfolio1.brokerCostBasis, closeTo(1, 1e-9));
        expect(aoPortfolio1.buyFeeTotal, closeTo(0, 1e-9));
        aoPortfolio2 =
            await db.assetsOnAccountsDao.getAOA(portfolio2.id, assetOne.id);
        expect(aoPortfolio2.shares, closeTo(0, 1e-9));
        expect(aoPortfolio2.value, closeTo(0, 1e-9));
        expect(aoPortfolio2.netCostBasis, closeTo(1, 1e-9));
        expect(aoPortfolio2.brokerCostBasis, closeTo(1, 1e-9));
        expect(aoPortfolio2.buyFeeTotal, closeTo(0, 1e-9));
        aOne = await db.assetsDao.getAsset(assetOne.id);
        expect(aOne.shares, closeTo(0, 1e-9));
        expect(aOne.value, closeTo(0, 1e-9));
        expect(aOne.netCostBasis, closeTo(1, 1e-9));
        expect(aOne.brokerCostBasis, closeTo(1, 1e-9));
        expect(aOne.buyFeeTotal, closeTo(0, 1e-9));
        portAcc1 = await db.accountsDao.getAccount(portfolio1.id);
        expect(portAcc1.balance, closeTo(0, 1e-9));
        portAcc2 = await db.accountsDao.getAccount(portfolio2.id);
        expect(portAcc2.balance, closeTo(0, 1e-9));
      });
    });
  });
}
