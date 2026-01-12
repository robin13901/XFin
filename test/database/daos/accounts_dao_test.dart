import 'package:drift/drift.dart';
import 'package:test/test.dart';
import 'package:xfin/database/app_database.dart';
import 'package:xfin/database/daos/accounts_dao.dart';
import 'package:drift/native.dart';
import 'package:xfin/database/tables.dart';

void main() {
  late AppDatabase db;
  late AccountsDao accountsDao;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    accountsDao = db.accountsDao;

    await db.into(db.assets).insert(AssetsCompanion.insert(
        name: 'EUR', type: AssetTypes.fiat, tickerSymbol: 'EUR'));
  });

  tearDown(() async {
    await db.close();
  });

  group('AccountsDao Tests', () {
    late int accountId;

    setUp(() async {
      accountId = await db
          .into(db.accounts)
          .insert(AccountsCompanion.insert(name: 'A', type: AccountTypes.cash));
    });

    test('insert', () async {
      final id = await accountsDao.insert(
          AccountsCompanion.insert(name: 'B', type: AccountTypes.cash));

      final act = await accountsDao.getAccount(id);
      expect(act.id, id);
      expect(act.name, 'B');
      expect(act.balance, 0);
      expect(act.initialBalance, 0);
      expect(act.isArchived, false);
    });

    test('getAccount', () async {
      final act = await accountsDao.getAccount(accountId);
      expect(act.id, accountId);
    });

    test('deleteAccount', () async {
      await accountsDao.deleteAccount(accountId);
      expect(() async => await accountsDao.getAccount(accountId),
          throwsA(isA<StateError>()));
    });

    test('setArchived', () async {
      final id = await db.into(db.accounts).insert(AccountsCompanion.insert(
          name: 'Test Account',
          balance: const Value(1000.0),
          initialBalance: const Value(1000.0),
          type: AccountTypes.cash));

      await accountsDao.setArchived(id, true);
      var result = await accountsDao.getAccount(id);
      expect(result.isArchived, true);

      await accountsDao.setArchived(id, false);
      result = await accountsDao.getAccount(id);
      expect(result.isArchived, false);
    });

    test('updateBalance', () async {
      final id = await db.into(db.accounts).insert(AccountsCompanion.insert(
          name: 'Test Account',
          balance: const Value(1000.0),
          initialBalance: const Value(1000.0),
          type: AccountTypes.cash));

      await accountsDao.updateBalance(id, 500.0);
      var result = await accountsDao.getAccount(id);
      expect(result.balance, 1500.0);

      await accountsDao.updateBalance(id, -250.0);
      result = await accountsDao.getAccount(id);
      expect(result.balance, 1250.0);
    });

    test('watchAllAccounts and watchArchivedAccounts', () async {
      await db.into(db.accounts).insert(AccountsCompanion.insert(
          name: 'Archived Account',
          balance: const Value(1000.0),
          initialBalance: const Value(1000.0),
          type: AccountTypes.cash,
          isArchived: const Value(true)));

      final activeAccountsStream = accountsDao.watchAllAccounts();
      final archivedAccountsStream = accountsDao.watchArchivedAccounts();

      expect(
          activeAccountsStream,
          emits(isA<List<Account>>()
              .having((list) => list.length, 'length', 1)
              .having((list) => list.first.name, 'name', 'A')));
      expect(
          archivedAccountsStream,
          emits(isA<List<Account>>()
              .having((list) => list.length, 'length', 1)
              .having((list) => list.first.name, 'name', 'Archived Account')));
    });

    // group('test leadsToInconsistentBalanceHistory', () {
    //   late Booking booking1, booking2;
    //   late int accountId2;
    //
    //   setUp(() async {
    //     accountId2 = await db.into(db.accounts).insert(
    //         AccountsCompanion.insert(name: 'B', type: AccountTypes.cash));
    //
    //     booking1 = Booking(
    //         id: 1,
    //         date: 20250105,
    //         shares: 5,
    //         costBasis: 1,
    //         value: 5,
    //         assetId: 1,
    //         category: 'T',
    //         accountId: accountId,
    //         excludeFromAverage: false,
    //         isGenerated: false);
    //     booking2 = Booking(
    //         id: 2,
    //         date: 20250109,
    //         shares: -1,
    //         costBasis: 1,
    //         assetId: 1,
    //         value: -1,
    //         category: 'T',
    //         accountId: accountId,
    //         excludeFromAverage: false,
    //         isGenerated: false);
    //     await db.into(db.bookings).insert(booking1.toCompanion(false));
    //     await db.into(db.bookings).insert(booking2.toCompanion(false));
    //   });
    //
    //   test('create booking', () async {
    //     expect(
    //         await accountsDao.leadsToInconsistentBalanceHistory(
    //           newBooking: BookingsCompanion.insert(
    //               date: 20250104,
    //               shares: -1,
    //               value: -1,
    //               category: 'Test',
    //               accountId: accountId),
    //         ),
    //         isTrue);
    //     expect(
    //         await accountsDao.leadsToInconsistentBalanceHistory(
    //           newBooking: BookingsCompanion.insert(
    //               date: 20250105,
    //               shares: -1,
    //               value: -1,
    //               category: 'Test',
    //               accountId: accountId),
    //         ),
    //         isFalse);
    //     expect(
    //         await accountsDao.leadsToInconsistentBalanceHistory(
    //           newBooking: BookingsCompanion.insert(
    //               date: 20250106,
    //               shares: -1,
    //               value: -1,
    //               category: 'Test',
    //               accountId: accountId),
    //         ),
    //         isFalse);
    //   });
    //
    //   test('delete booking', () async {
    //     expect(
    //         await accountsDao.leadsToInconsistentBalanceHistory(
    //             originalBooking: booking1),
    //         isTrue);
    //     expect(
    //         await accountsDao.leadsToInconsistentBalanceHistory(
    //             originalBooking: booking2),
    //         isFalse);
    //   });
    //
    //   test('update booking', () async {
    //     expect(
    //         await accountsDao.leadsToInconsistentBalanceHistory(
    //             originalBooking: booking1,
    //             newBooking: booking1
    //                 .toCompanion(false)
    //                 .copyWith(accountId: Value(accountId2))),
    //         isTrue);
    //     expect(
    //         await accountsDao.leadsToInconsistentBalanceHistory(
    //             originalBooking: booking2,
    //             newBooking: booking2
    //                 .toCompanion(false)
    //                 .copyWith(accountId: Value(accountId2))),
    //         isTrue);
    //     expect(
    //         await accountsDao.leadsToInconsistentBalanceHistory(
    //             originalBooking: booking1,
    //             newBooking: booking1
    //                 .toCompanion(false)
    //                 .copyWith(date: const Value(20250110))),
    //         isTrue);
    //     expect(
    //         await accountsDao.leadsToInconsistentBalanceHistory(
    //             originalBooking: booking2,
    //             newBooking: booking2.toCompanion(false).copyWith(
    //                 accountId: Value(accountId2), shares: const Value(1), value: const Value(1))),
    //         isFalse);
    //   });
    // });
  });

  group('Has references tests', () {
    late Account cashAccount1, cashAccount2, investmentAccount;
    late Asset asset;

    setUp(() async {
      cashAccount1 = const Account(
          id: 1,
          name: 'Cash Account 1',
          balance: 5000,
          initialBalance: 5000,
          type: AccountTypes.cash,
          isArchived: false);

      cashAccount2 = const Account(
          id: 2,
          name: 'Cash Account 2',
          balance: 2000,
          initialBalance: 2000,
          type: AccountTypes.cash,
          isArchived: false);

      investmentAccount = const Account(
          id: 3,
          name: 'Investment Account',
          balance: 10,
          initialBalance: 0,
          type: AccountTypes.portfolio,
          isArchived: false);

      asset = const Asset(
          id: 2,
          name: 'Test Asset',
          type: AssetTypes.stock,
          tickerSymbol: 'TEST',
          currencySymbol: '',
          value: 0,
          shares: 0,
          netCostBasis: 0,
          brokerCostBasis: 0,
          buyFeeTotal: 0, 
          isArchived: false);

      await db.into(db.accounts).insert(cashAccount1.toCompanion(false));
      await db.into(db.accounts).insert(cashAccount2.toCompanion(false));
      await db.into(db.accounts).insert(investmentAccount.toCompanion(false));
      await db.into(db.assets).insert(asset.toCompanion(false));
    });

    test('hasBookings', () async {
      expect(await accountsDao.hasBookings(cashAccount1.id), isFalse);

      await db.into(db.bookings).insert(BookingsCompanion.insert(
          date: 20240101,
          shares: 100.0,
          value: 100.0,
          category: 'Test',
          accountId: cashAccount1.id));

      expect(await accountsDao.hasBookings(cashAccount1.id), isTrue);
    });

    test('hasPeriodicBookings', () async {
      expect(await accountsDao.hasPeriodicBookings(cashAccount1.id), isFalse);

      await db.into(db.periodicBookings).insert(
          PeriodicBookingsCompanion.insert(
              nextExecutionDate: 20251010,
              shares: 5, 
              value: 5,
              accountId: 1,
              category: 'Test',));

      expect(await accountsDao.hasPeriodicBookings(cashAccount1.id), isTrue);
    });

    test('hasTransfers', () async {
      expect(await accountsDao.hasTransfers(cashAccount1.id), isFalse);
      expect(await accountsDao.hasTransfers(cashAccount2.id), isFalse);

      await db.into(db.transfers).insert(TransfersCompanion.insert(
          date: 20240101,
          shares: 100.0,
          sendingAccountId: cashAccount1.id,
          receivingAccountId: cashAccount2.id,
          value: 100.0));

      expect(await accountsDao.hasTransfers(cashAccount1.id), isTrue);
      expect(await accountsDao.hasTransfers(cashAccount2.id), isTrue);
    });

    test('hasPeriodicTransfers', () async {
      expect(await accountsDao.hasPeriodicTransfers(cashAccount1.id), isFalse);
      expect(await accountsDao.hasPeriodicTransfers(cashAccount2.id), isFalse);

      await db.into(db.periodicTransfers).insert(
          PeriodicTransfersCompanion.insert(
              nextExecutionDate: 20251010,
              shares: 5,
              value: 5,
              sendingAccountId: 1,
              receivingAccountId: 2));

      expect(await accountsDao.hasPeriodicTransfers(cashAccount1.id), isTrue);
      expect(await accountsDao.hasPeriodicTransfers(cashAccount2.id), isTrue);
    });

    test('hasTrades', () async {
      expect(await accountsDao.hasTrades(cashAccount1.id), isFalse);
      expect(await accountsDao.hasTrades(investmentAccount.id), isFalse);

      await db.into(db.assetsOnAccounts).insert(
          AssetsOnAccountsCompanion.insert(
              accountId: investmentAccount.id, assetId: asset.id));

      await db.into(db.trades).insert(TradesCompanion.insert(
          datetime: 20240101,
          assetId: asset.id,
          type: TradeTypes.buy,
          sourceAccountValueDelta: -1,
          targetAccountValueDelta: 1,
          shares: 1,
          costBasis: 1,
          sourceAccountId: cashAccount1.id,
          targetAccountId: investmentAccount.id));

      expect(await accountsDao.hasTrades(cashAccount1.id), isTrue);
      expect(await accountsDao.hasTrades(investmentAccount.id), isTrue);
    });

    test('hasAssets', () async {
      expect(await accountsDao.hasAssets(investmentAccount.id), isFalse);

      await db
          .into(db.assetsOnAccounts)
          .insert(AssetsOnAccountsCompanion.insert(accountId: 3, assetId: 2));

      expect(await accountsDao.hasAssets(investmentAccount.id), isTrue);
    });

    test('hasGoals', () async {
      expect(await accountsDao.hasGoals(cashAccount1.id), isFalse);

      await db.into(db.goals).insert(GoalsCompanion.insert(
          accountId: Value(cashAccount1.id),
          createdOn: 20251010,
          targetDate: 20261010,
          targetShares: 15000,
          targetValue: 15000));

      expect(await accountsDao.hasGoals(cashAccount1.id), isTrue);
    });
  });
}
