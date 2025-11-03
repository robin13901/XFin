import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xfin/database/app_database.dart';
import 'package:xfin/database/daos/accounts_dao.dart';
import 'package:xfin/database/daos/bookings_dao.dart';
import 'package:xfin/database/tables.dart';

void main() {
  late AppDatabase db;
  late BookingsDao bookingsDao;
  late AccountsDao accountsDao;

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
      accountId1 = await accountsDao.addAccount(const AccountsCompanion(
        name: Value('Account 1'),
        balance: Value(1000),
        initialBalance: Value(1000),
        type: Value(AccountTypes.cash),
      ));
      accountId2 = await accountsDao.addAccount(const AccountsCompanion(
        name: Value('Account 2'),
        balance: Value(500),
        initialBalance: Value(500),
        type: Value(AccountTypes.cash),
      ));
      archivedAccountId = await accountsDao.addAccount(const AccountsCompanion(
        name: Value('Archived Account'),
        balance: Value(0),
        initialBalance: Value(0),
        type: Value(AccountTypes.cash),
        isArchived: Value(true),
      ));
    });

    test('watchBookingsWithAccount filters archived and orders correctly', () async {
      // Arrange
      await bookingsDao.createBookingAndUpdateAccount(BookingsCompanion(
          date: const Value(20230101),
          reason: const Value('Booking 1'),
          amount: const Value(100),
          isGenerated: const Value(false),
          accountId: Value(accountId1)));
      await bookingsDao.createBookingAndUpdateAccount(BookingsCompanion(
          date: const Value(20230102),
          reason: const Value('Booking 2'),
          amount: const Value(200),
          isGenerated: const Value(false),
          accountId: Value(accountId1)));
      await bookingsDao.createBookingAndUpdateAccount(BookingsCompanion(
          date: const Value(20230102),
          reason: const Value('Booking 3'),
          amount: const Value(50),
          isGenerated: const Value(false),
          accountId: Value(accountId2)));
      await bookingsDao.createBookingAndUpdateAccount(BookingsCompanion(
          date: const Value(20230103),
          reason: const Value('Archived Booking'),
          amount: const Value(50),
          isGenerated: const Value(false),
          accountId: Value(archivedAccountId)));

      // Act
      final stream = bookingsDao.watchBookingsWithAccount();
      final result = await stream.first;

      // Assert
      expect(result.length, 3);
      expect(result.any((b) => b.booking.reason == 'Archived Booking'), isFalse);
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
          reason: const Value('Groceries'),
          amount: const Value(-50.0),
          accountId: Value(accountId1),
          excludeFromAverage: const Value(false),
          isGenerated: const Value(false));

      await bookingsDao.createBookingAndUpdateAccount(companion.copyWith(notes: const Value('some note'))); // Not mergeable
      await bookingsDao.createBookingAndUpdateAccount(companion.copyWith(amount: const Value(50.0))); // Not mergeable (different sign)
      await bookingsDao.createBookingAndUpdateAccount(companion); // This one is mergeable

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
          reason: const Value('Groceries'),
          amount: const Value(-50.0),
          accountId: Value(accountId1),
          excludeFromAverage: const Value(false),
          isGenerated: const Value(false));
          
       // Act
      final mergeable = await bookingsDao.findMergeableBooking(companion);

      // Assert
      expect(mergeable, isNull);
    });

    test('watchDistinctReasons returns unique, sorted reasons', () async {
      // Arrange
      await bookingsDao.createBookingAndUpdateAccount(BookingsCompanion(
          date: const Value(20230101),
          reason: const Value('Groceries'),
          amount: const Value(100),
          isGenerated: const Value(false),
          accountId: Value(accountId1)));
      await bookingsDao.createBookingAndUpdateAccount(BookingsCompanion(
          date: const Value(20230102),
          reason: const Value('Salary'),
          amount: const Value(200),
          isGenerated: const Value(false),
          accountId: Value(accountId1)));
      await bookingsDao.createBookingAndUpdateAccount(BookingsCompanion(
          date: const Value(20230103),
          reason: const Value('Groceries'),
          amount: const Value(50),
          isGenerated: const Value(false),
          accountId: Value(accountId2)));

      // Act
      final stream = bookingsDao.watchDistinctReasons();
      final result = await stream.first;

      // Assert
      expect(result, hasLength(2));
      expect(result, containsAllInOrder(['Groceries', 'Salary']));
    });

    test('createBookingAndUpdateAccount works correctly', () async {
      // Arrange
      final companion = BookingsCompanion(
          date: const Value(20230101),
          reason: const Value('Salary'),
          amount: const Value(500),
          isGenerated: const Value(false),
          accountId: Value(accountId1));

      // Act
      await bookingsDao.createBookingAndUpdateAccount(companion);

      // Assert
      final booking = await bookingsDao.getBooking(1);
      final account = await accountsDao.getAccount(accountId1);
      expect(booking.reason, 'Salary');
      expect(account.balance, 1500); // 1000 + 500
    });

    test('updateBookingAndUpdateAccount handles same account', () async {
      // Arrange
      await bookingsDao.createBookingAndUpdateAccount(BookingsCompanion(
          date: const Value(20230101),
          reason: const Value('Initial'),
          amount: const Value(100),
          isGenerated: const Value(false),
          accountId: Value(accountId1)));
      final oldBooking = await bookingsDao.getBooking(1);
      final newCompanion = oldBooking.toCompanion(true).copyWith(amount: const Value(-50));
      
      // Act
      await bookingsDao.updateBookingAndUpdateAccount(oldBooking, newCompanion);

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
       await bookingsDao.createBookingAndUpdateAccount(BookingsCompanion(
          date: const Value(20230101),
          reason: const Value('Initial'),
          amount: const Value(100),
          isGenerated: const Value(false),
          accountId: Value(accountId1)));
      final oldBooking = await bookingsDao.getBooking(1);
      final newCompanion = oldBooking.toCompanion(true).copyWith(accountId: Value(accountId2));

      // Act
      await bookingsDao.updateBookingAndUpdateAccount(oldBooking, newCompanion);

      // Assert
      final account1 = await accountsDao.getAccount(accountId1);
      final account2 = await accountsDao.getAccount(accountId2);
      expect(account1.balance, 1000); // 1100 - 100
      expect(account2.balance, 600); // 500 + 100
    });

    test('deleteBookingAndUpdateAccount works correctly', () async {
      // Arrange
      await bookingsDao.createBookingAndUpdateAccount(BookingsCompanion(
          date: const Value(20230101),
          reason: const Value('Expense'),
          amount: const Value(-200),
          isGenerated: const Value(false),
          accountId: Value(accountId1)));
          
      expect((await accountsDao.getAccount(accountId1)).balance, 800);

      // Act
      await bookingsDao.deleteBookingAndUpdateAccount(1);

      // Assert
      final account = await accountsDao.getAccount(accountId1);
      expect(account.balance, 1000); // 800 - (-200)
      
      final bookings = await (db.select(db.bookings)..where((b) => b.id.equals(1))).get();
      expect(bookings, isEmpty);
    });
  });
}
