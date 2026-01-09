import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:xfin/database/app_database.dart';
import 'package:xfin/database/daos/transfers_dao.dart';
import 'package:xfin/database/tables.dart';

void main() {
  late AppDatabase db;
  late TransfersDao transfersDao;
  late int assetId;
  late int accA;
  late int accB;
  late Asset assetOne;
  late Account portfolio1, portfolio2;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});

    db = AppDatabase(NativeDatabase.memory());
    transfersDao = db.transfersDao;

    // create one asset (base currency) and two accounts
    assetId = await db.into(db.assets).insert(AssetsCompanion.insert(
          name: 'EUR',
          type: AssetTypes.fiat,
          tickerSymbol: 'EUR',
        ));

    accA = await db.into(db.accounts).insert(AccountsCompanion.insert(
          name: 'AccountA',
          type: AccountTypes.cash,
          balance: const Value(100.0),
        ));

    accB = await db.into(db.accounts).insert(AccountsCompanion.insert(
          name: 'AccountB',
          type: AccountTypes.cash,
          balance: const Value(200.0),
        ));

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

    portfolio1 = const Account(
        id: 3,
        name: 'Portfolio 1',
        balance: 0,
        initialBalance: 0,
        type: AccountTypes.portfolio,
        isArchived: false);

    portfolio2 = const Account(
        id: 4,
        name: 'Portfolio 2',
        balance: 0,
        initialBalance: 0,
        type: AccountTypes.portfolio,
        isArchived: false);

    // Ensure both accounts have an AssetsOnAccounts row for the asset
    await db.into(db.assetsOnAccounts).insert(AssetsOnAccountsCompanion.insert(
          accountId: accA,
          assetId: assetId,
          value: const Value(100.0),
          shares: const Value(100.0),
        ));

    await db.into(db.assetsOnAccounts).insert(AssetsOnAccountsCompanion.insert(
          accountId: accB,
          assetId: assetId,
          value: const Value(200.0),
          shares: const Value(200.0),
        ));

    await db.into(db.assets).insert(assetOne.toCompanion(false));
    await db.into(db.accounts).insert(portfolio1.toCompanion(false));
    await db.into(db.accounts).insert(portfolio2.toCompanion(false));
  });

  tearDown(() async {
    await db.close();
  });

  group('TransfersDao basic behavior', () {
    test(
        'watchTransfersWithAccountsAndAsset emits only transfers where both accounts not archived',
        () async {
      // Create a transfer between accA -> accB
      await transfersDao.createTransfer(TransfersCompanion.insert(
        date: 20250101,
        sendingAccountId: accA,
        receivingAccountId: accB,
        assetId: Value(assetId),
        shares: 10.0,
        value: 10.0,
      ));

      // Create transfer where receiving account is archived (should be excluded)
      final accArchived =
          await db.into(db.accounts).insert(AccountsCompanion.insert(
                name: 'Archived',
                type: AccountTypes.cash,
                isArchived: const Value(true),
              ));

      await db
          .into(db.assetsOnAccounts)
          .insert(AssetsOnAccountsCompanion.insert(
            accountId: accArchived,
            assetId: assetId,
            value: const Value(0.0),
            shares: const Value(0.0),
          ));

      await transfersDao.createTransfer(TransfersCompanion.insert(
        date: 20250102,
        sendingAccountId: accA,
        receivingAccountId: accArchived,
        assetId: Value(assetId),
        shares: 5.0,
        value: 5.0,
      ));

      final rows =
          await transfersDao.watchTransfersWithAccountsAndAsset().first;

      // Only the first transfer (accA -> accB) should be present
      expect(rows.length, 1);
      final t = rows.first;
      expect(t.transfer.sendingAccountId, accA);
      expect(t.transfer.receivingAccountId, accB);
      expect(t.sendingAccount.id, accA);
      expect(t.receivingAccount.id, accB);
      expect(t.asset.id, assetId);
    });

    test('createTransfer updates balances and assetsOnAccounts correctly',
        () async {
      // balances before
      final aBefore = await (db.select(db.accounts)
            ..where((t) => t.id.equals(accA)))
          .getSingle();
      final bBefore = await (db.select(db.accounts)
            ..where((t) => t.id.equals(accB)))
          .getSingle();
      expect(aBefore.balance, closeTo(100.0, 1e-9));
      expect(bBefore.balance, closeTo(200.0, 1e-9));

      // create transfer: A -> B, value 30
      await transfersDao.createTransfer(TransfersCompanion.insert(
        date: 20250201,
        sendingAccountId: accA,
        receivingAccountId: accB,
        assetId: Value(assetId),
        shares: 30.0,
        value: 30.0,
      ));

      // balances after
      final aAfter = await (db.select(db.accounts)
            ..where((t) => t.id.equals(accA)))
          .getSingle();
      final bAfter = await (db.select(db.accounts)
            ..where((t) => t.id.equals(accB)))
          .getSingle();
      expect(aAfter.balance, closeTo(70.0, 1e-9)); // 100 - 30
      expect(bAfter.balance, closeTo(230.0, 1e-9)); // 200 + 30

      // assetsOnAccounts updated: A decreased by 30, B increased by 30
      final aoaA = await (db.select(db.assetsOnAccounts)
            ..where(
                (t) => t.accountId.equals(accA) & t.assetId.equals(assetId)))
          .getSingle();
      final aoaB = await (db.select(db.assetsOnAccounts)
            ..where(
                (t) => t.accountId.equals(accB) & t.assetId.equals(assetId)))
          .getSingle();

      expect(aoaA.value, closeTo(70.0, 1e-9)); // 100 - 30
      expect(aoaA.shares, closeTo(70.0, 1e-9));

      expect(aoaB.value, closeTo(230.0, 1e-9)); // 200 + 30
      expect(aoaB.shares, closeTo(230.0, 1e-9));
    });

    test(
        'updateTransfer reverses old transfer and applies new transfer correctly',
        () async {
      // create an initial transfer A -> B, value 20
      await transfersDao.createTransfer(TransfersCompanion.insert(
        date: 20250301,
        sendingAccountId: accA,
        receivingAccountId: accB,
        assetId: Value(assetId),
        shares: 20.0,
        value: 20.0,
      ));

      // fetch the stored transfer (there should be one)
      final transfers = await transfersDao.getAllTransfers();
      expect(transfers.length, greaterThanOrEqualTo(1));
      final old = transfers.last; // the one we inserted

      // Now prepare a new transfer that moves money from B -> A with value 50 and different shares
      final updatedCompanion = TransfersCompanion(
        id: Value(old.id),
        date: const Value(20250302),
        sendingAccountId: Value(accB),
        receivingAccountId: Value(accA),
        assetId: Value(assetId),
        shares: const Value(50.0),
        value: const Value(50.0),
      );

      // balances before the update
      await (db.select(db.accounts)..where((t) => t.id.equals(accA)))
          .getSingle();
      await (db.select(db.accounts)..where((t) => t.id.equals(accB)))
          .getSingle();

      // perform the update
      await transfersDao.updateTransfer(old, updatedCompanion);

      // balances after:
      final aAfter = await (db.select(db.accounts)
            ..where((t) => t.id.equals(accA)))
          .getSingle();
      final bAfter = await (db.select(db.accounts)
            ..where((t) => t.id.equals(accB)))
          .getSingle();

      // Explanation:
      // Initially we had A:100, B:200.
      // After createTransfer(old: 20): A=80, B=220.
      // updateTransfer reverses old: A += 20 => 100, B -= 20 => 200.
      // then applies new (B->A value 50): B -= 50 => 150, A += 50 => 150.
      expect(aAfter.balance, closeTo(150.0, 1e-9));
      expect(bAfter.balance, closeTo(150.0, 1e-9));

      // assetsOnAccounts should reflect same net changes
      final aoaA = await (db.select(db.assetsOnAccounts)
            ..where(
                (t) => t.accountId.equals(accA) & t.assetId.equals(assetId)))
          .getSingle();
      final aoaB = await (db.select(db.assetsOnAccounts)
            ..where(
                (t) => t.accountId.equals(accB) & t.assetId.equals(assetId)))
          .getSingle();

      // After the sequence above the expected AoA values:
      // Start: A=100, B=200
      // After initial transfer (A->B 20): A=80, B=220
      // After update reverse old: A=100, B=200
      // After new transfer (B->A 50): A=150, B=150
      expect(aoaA.value, closeTo(150.0, 1e-9));
      expect(aoaA.shares, closeTo(150.0, 1e-9));
      expect(aoaB.value, closeTo(150.0, 1e-9));
      expect(aoaB.shares, closeTo(150.0, 1e-9));

      // And transfer row should reflect the new values
      final changed = await transfersDao.getTransfer(old.id);
      expect(changed.sendingAccountId, accB);
      expect(changed.receivingAccountId, accA);
      expect(changed.value, 50.0);
      expect(changed.shares, 50.0);
    });

    test('deleteTransfer reverses effects and removes the row', () async {
      // create a transfer A -> B value 25
      await transfersDao.createTransfer(TransfersCompanion.insert(
        date: 20250401,
        sendingAccountId: accA,
        receivingAccountId: accB,
        assetId: Value(assetId),
        shares: 25.0,
        value: 25.0,
      ));

      final all = await transfersDao.getAllTransfers();
      final t = all.last;

      // balances after creation: A=75, B=225
      var aNow = await (db.select(db.accounts)..where((q) => q.id.equals(accA)))
          .getSingle();
      var bNow = await (db.select(db.accounts)..where((q) => q.id.equals(accB)))
          .getSingle();
      expect(aNow.balance, closeTo(75.0, 1e-9));
      expect(bNow.balance, closeTo(225.0, 1e-9));

      // delete
      await transfersDao.deleteTransfer(t.id);

      // transfer row should be gone
      final remaining = await transfersDao.getAllTransfers();
      expect(remaining.where((r) => r.id == t.id), isEmpty);

      // balances reversed: A back to 100, B back to 200
      aNow = await (db.select(db.accounts)..where((q) => q.id.equals(accA)))
          .getSingle();
      bNow = await (db.select(db.accounts)..where((q) => q.id.equals(accB)))
          .getSingle();
      expect(aNow.balance, closeTo(100.0, 1e-9));
      expect(bNow.balance, closeTo(200.0, 1e-9));

      // assetsOnAccounts reversed as well
      final aoaA = await (db.select(db.assetsOnAccounts)
            ..where(
                (q) => q.accountId.equals(accA) & q.assetId.equals(assetId)))
          .getSingle();
      final aoaB = await (db.select(db.assetsOnAccounts)
            ..where(
                (q) => q.accountId.equals(accB) & q.assetId.equals(assetId)))
          .getSingle();

      expect(aoaA.value, closeTo(100.0, 1e-9));
      expect(aoaA.shares, closeTo(100.0, 1e-9));
      expect(aoaB.value, closeTo(200.0, 1e-9));
      expect(aoaB.shares, closeTo(200.0, 1e-9));
    });

    test('costBasis correctly calculated in createTransfer and updateTransfer',
        () async {
      await db.bookingsDao.createBooking(BookingsCompanion(
          date: const Value(20250101),
          assetId: Value(assetOne.id),
          accountId: Value(portfolio1.id),
          category: const Value('Test'),
          shares: const Value(0.5),
          costBasis: const Value(100),
          value: const Value(50)));

      await db.bookingsDao.createBooking(BookingsCompanion(
          date: const Value(20250102),
          assetId: Value(assetOne.id),
          accountId: Value(portfolio1.id),
          category: const Value('Test'),
          shares: const Value(0.5),
          costBasis: const Value(200),
          value: const Value(100)));

      // Create SUT
      await db.transfersDao.createTransfer(TransfersCompanion(
          date: const Value(20250103),
          assetId: Value(assetOne.id),
          sendingAccountId: Value(portfolio1.id),
          receivingAccountId: Value(portfolio2.id),
          shares: const Value(1)));

      // Post-create-checks
      var sut = await db.transfersDao.getTransfer(1);
      expect(sut.shares, closeTo(1, 1e-9));
      expect(sut.costBasis, closeTo(150, 1e-9));
      expect(sut.value, closeTo(150, 1e-9));

      // Update SUT
      var updatedTransfer = TransfersCompanion(
          date: const Value(20250103),
          assetId: Value(assetOne.id),
          sendingAccountId: Value(portfolio1.id),
          receivingAccountId: Value(portfolio2.id),
          shares: const Value(0.5));
      db.transfersDao.updateTransfer(sut, updatedTransfer);

      // Post-update-checks
      sut = await db.transfersDao.getTransfer(1);
      expect(sut.shares, closeTo(0.5, 1e-9));
      expect(sut.costBasis, closeTo(100, 1e-9));
      expect(sut.value, closeTo(50, 1e-9));
    });
  });
}
