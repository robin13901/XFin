import 'dart:ui';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xfin/database/app_database.dart';
import 'package:xfin/database/daos/accounts_dao.dart';
import 'package:xfin/database/daos/bookings_dao.dart';
import 'package:xfin/database/tables.dart';
import 'package:xfin/providers/base_currency_provider.dart';

void main() {
  late AppDatabase db;
  late BookingsDao bookingsDao;
  late AccountsDao accountsDao;
  late BaseCurrencyProvider currencyProvider;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    bookingsDao = db.bookingsDao;
    accountsDao = db.accountsDao;
  });

  tearDown(() async {
    await db.close();
  });

  group('BookingsDao Tests', () {
    late int accountId1;
    late int accountId2;
    late int archivedAccountId;

    setUp(() async {
      const locale = Locale('en');
      currencyProvider = BaseCurrencyProvider();
      await currencyProvider.initialize(locale);

      // Create base currency asset
      await db.into(db.assets).insert(
          const AssetsCompanion(
              name: Value('EUR'),
              type: Value(AssetTypes.currency),
              tickerSymbol: Value('EUR'),
              value: Value(0),
              sharesOwned: Value(0),
              brokerCostBasis: Value(1),
              netCostBasis: Value(1),
              buyFeeTotal: Value(0)));

      accountId1 = await accountsDao.createAccount(const AccountsCompanion(
        name: Value('Account 1'),
        balance: Value(1000),
        initialBalance: Value(1000),
        type: Value(AccountTypes.cash),
      ));
      accountId2 = await accountsDao.createAccount(const AccountsCompanion(
        name: Value('Account 2'),
        balance: Value(500),
        initialBalance: Value(500),
        type: Value(AccountTypes.cash),
      ));
      archivedAccountId = await accountsDao.createAccount(const AccountsCompanion(
        name: Value('Archived Account'),
        balance: Value(0),
        initialBalance: Value(0),
        type: Value(AccountTypes.cash),
        isArchived: Value(true),
      ));
    });

    test('watchBookingsWithAccount filters archived and orders correctly', () async {
      // Arrange
      await bookingsDao.createBooking(BookingsCompanion(
          date: const Value(20230101),
          category: const Value('Booking 1'),
          amount: const Value(100),
          isGenerated: const Value(false),
          accountId: Value(accountId1)));
      await bookingsDao.createBooking(BookingsCompanion(
          date: const Value(20230102),
          category: const Value('Booking 2'),
          amount: const Value(200),
          isGenerated: const Value(false),
          accountId: Value(accountId1)));
      await bookingsDao.createBooking(BookingsCompanion(
          date: const Value(20230102),
          category: const Value('Booking 3'),
          amount: const Value(50),
          isGenerated: const Value(false),
          accountId: Value(accountId2)));
      await bookingsDao.createBooking(BookingsCompanion(
          date: const Value(20230103),
          category: const Value('Archived Booking'),
          amount: const Value(50),
          isGenerated: const Value(false),
          accountId: Value(archivedAccountId)));

      // Act
      final stream = bookingsDao.watchBookingsWithAccount();
      final result = await stream.first;

      // Assert
      expect(result.length, 3);
      expect(result.any((b) => b.booking.category == 'Archived Booking'), isFalse);
      expect(result[0].booking.date, 20230102);
      expect(result[0].booking.amount, 200); // Higher amount first for same date
      expect(result[1].booking.date, 20230102);
      expect(result[1].booking.amount, 50);
      expect(result[2].booking.date, 20230101);
    });

    test('findMergeableBooking finds a suitable booking', () async {
      // Arrange
      final companion = BookingsCompanion(
          date: const Value(20230501),
          category: const Value('Groceries'),
          amount: const Value(-50.0),
          accountId: Value(accountId1),
          excludeFromAverage: const Value(false),
          isGenerated: const Value(false));

      await bookingsDao.createBooking(companion.copyWith(notes: const Value('some note'))); // Not mergeable
      await bookingsDao.createBooking(companion.copyWith(amount: const Value(50.0))); // Not mergeable (different sign)
      await bookingsDao.createBooking(companion); // This one is mergeable

      // Act
      final mergeable = await bookingsDao.findMergeableBooking(companion.copyWith(amount: const Value(-25.0)));

      // Assert
      expect(mergeable, isNotNull);
      expect(mergeable!.amount, -50.0);
    });
    
    test('findMergeableBooking returns null when no suitable booking is found', () async {
       // Arrange
      final companion = BookingsCompanion(
          date: const Value(20230501),
          category: const Value('Groceries'),
          amount: const Value(-50.0),
          accountId: Value(accountId1),
          excludeFromAverage: const Value(false),
          isGenerated: const Value(false));
          
       // Act
      final mergeable = await bookingsDao.findMergeableBooking(companion);

      // Assert
      expect(mergeable, isNull);
    });

    test('watchDistinctCategorys returns unique, sorted categorys', () async {
      // Arrange
      await bookingsDao.createBooking(BookingsCompanion(
          date: const Value(20230101),
          category: const Value('Groceries'),
          amount: const Value(100),
          isGenerated: const Value(false),
          accountId: Value(accountId1)));
      await bookingsDao.createBooking(BookingsCompanion(
          date: const Value(20230102),
          category: const Value('Salary'),
          amount: const Value(200),
          isGenerated: const Value(false),
          accountId: Value(accountId1)));
      await bookingsDao.createBooking(BookingsCompanion(
          date: const Value(20230103),
          category: const Value('Groceries'),
          amount: const Value(50),
          isGenerated: const Value(false),
          accountId: Value(accountId2)));

      // Act
      final stream = bookingsDao.watchDistinctCategories();
      final result = await stream.first;

      // Assert
      expect(result, hasLength(2));
      expect(result, containsAllInOrder(['Groceries', 'Salary']));
    });

    test('createBookingAndUpdateAccount works correctly', () async {
      // Arrange
      final companion = BookingsCompanion(
          date: const Value(20230101),
          category: const Value('Salary'),
          amount: const Value(500),
          isGenerated: const Value(false),
          accountId: Value(accountId1));

      // Act
      await bookingsDao.createBooking(companion);

      // Assert
      final booking = await bookingsDao.getBooking(1);
      final account = await accountsDao.getAccount(accountId1);
      expect(booking.category, 'Salary');
      expect(account.balance, 1500); // 1000 + 500
    });

    test('updateBookingAndUpdateAccount handles same account', () async {
      // Arrange
      await bookingsDao.createBooking(BookingsCompanion(
          date: const Value(20230101),
          category: const Value('Initial'),
          amount: const Value(100),
          isGenerated: const Value(false),
          accountId: Value(accountId1)));
      final oldBooking = await bookingsDao.getBooking(1);
      final newCompanion = oldBooking.toCompanion(true).copyWith(amount: const Value(-50));
      
      // Act
      await bookingsDao.updateBooking(oldBooking, newCompanion);

      // Assert
      final updatedBooking = await bookingsDao.getBooking(1);
      final account = await accountsDao.getAccount(accountId1);
      expect(updatedBooking.amount, -50);
      // Initial: 1000 + 100 = 1100. Update: 1100 - 100 (old) + (-50) (new) = 950
      // Or delta: -50 - 100 = -150. Balance: 1100 - 150 = 950.
      expect(account.balance, 950);
    });
    
    test('updateBookingAndUpdateAccount handles different accounts', () async {
      // Arrange
       await bookingsDao.createBooking(BookingsCompanion(
          date: const Value(20230101),
          category: const Value('Initial'),
          amount: const Value(100),
          isGenerated: const Value(false),
          accountId: Value(accountId1)));
      final oldBooking = await bookingsDao.getBooking(1);
      final newCompanion = oldBooking.toCompanion(true).copyWith(accountId: Value(accountId2));

      // Act
      await bookingsDao.updateBooking(oldBooking, newCompanion);

      // Assert
      final account1 = await accountsDao.getAccount(accountId1);
      final account2 = await accountsDao.getAccount(accountId2);
      expect(account1.balance, 1000); // 1100 - 100
      expect(account2.balance, 600); // 500 + 100
    });

    test('deleteBookingAndUpdateAccount works correctly', () async {
      // Arrange
      await bookingsDao.createBooking(BookingsCompanion(
          date: const Value(20230101),
          category: const Value('Expense'),
          amount: const Value(-200),
          isGenerated: const Value(false),
          accountId: Value(accountId1)));
          
      expect((await accountsDao.getAccount(accountId1)).balance, 800);

      // Act
      await bookingsDao.deleteBooking(1);

      // Assert
      final account = await accountsDao.getAccount(accountId1);
      expect(account.balance, 1000); // 800 - (-200)
      
      final bookings = await (db.select(db.bookings)..where((b) => b.id.equals(1))).get();
      expect(bookings, isEmpty);
    });
  });
}
