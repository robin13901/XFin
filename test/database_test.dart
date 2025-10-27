import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:xfin/database/app_database.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  Future<Account> getAccount(int id) {
    return (database.select(database.accounts)..where((a) => a.id.equals(id))).getSingle();
  }

  int getTodayAsInt() {
    return int.parse(DateFormat('yyyyMMdd').format(DateTime.now()));
  }

  group('Booking transactions', () {
    test('creating an income booking updates account balance', () async {
      // ARRANGE
      final accountId = await database.accountsDao.addAccount(const AccountsCompanion(
        name: Value('Test Account'),
        balance: Value(100.0),
      ));

      // ACT
      final booking = BookingsCompanion(
        reason: const Value('Paycheck'),
        amount: const Value(50.0),
        date: Value(getTodayAsInt()),
        receivingAccountId: Value(accountId),
      );
      await database.bookingsDao.createBooking(booking);

      // ASSERT
      final account = await getAccount(accountId);
      expect(account.balance, 150.0);
    });

    test('creating an expense booking updates account balance', () async {
      // ARRANGE
      final accountId = await database.accountsDao.addAccount(const AccountsCompanion(
        name: Value('Test Account'),
        balance: Value(100.0),
      ));

      // ACT
      final booking = BookingsCompanion(
        reason: const Value('Groceries'),
        amount: const Value(-50.0),
        date: Value(getTodayAsInt()),
        receivingAccountId: Value(accountId),
      );
      await database.bookingsDao.createBooking(booking);

      // ASSERT
      final account = await getAccount(accountId);
      expect(account.balance, 50.0);
    });

    test('creating a transfer updates both account balances', () async {
      // ARRANGE
      final sendingId = await database.accountsDao.addAccount(const AccountsCompanion(
        name: Value('Sending'),
        balance: Value(100.0),
      ));
      final receivingId = await database.accountsDao.addAccount(const AccountsCompanion(
        name: Value('Receiving'),
        balance: Value(50.0),
      ));

      // ACT
      final booking = BookingsCompanion(
        reason: const Value(null), // Transfers have null reason
        amount: const Value(25.0),
        date: Value(getTodayAsInt()),
        sendingAccountId: Value(sendingId),
        receivingAccountId: Value(receivingId),
      );
      await database.bookingsDao.createBooking(booking);

      // ASSERT
      final sendingAccount = await getAccount(sendingId);
      final receivingAccount = await getAccount(receivingId);
      expect(sendingAccount.balance, 75.0);
      expect(receivingAccount.balance, 75.0);
    });

    test('deleting an income booking reverts account balance', () async {
      // ARRANGE
      final accountId = await database.accountsDao.addAccount(const AccountsCompanion(
        name: Value('Test Account'),
        balance: Value(150.0), // Balance after income
      ));
      final bookingId = await database.into(database.bookings).insert(BookingsCompanion(
          reason: const Value('Initial'),
          amount: const Value(50.0),
          date: Value(getTodayAsInt()),
          receivingAccountId: Value(accountId)));

      // ACT
      await database.bookingsDao.deleteBookingWithBalance(bookingId);

      // ASSERT
      final account = await getAccount(accountId);
      expect(account.balance, 100.0);
    });

    test('deleting a transfer reverts both account balances', () async {
      // ARRANGE
      final sendingId = await database.accountsDao.addAccount(const AccountsCompanion(
        name: Value('Sending'),
        balance: Value(75.0), // State after transfer
      ));
      final receivingId = await database.accountsDao.addAccount(const AccountsCompanion(
        name: Value('Receiving'),
        balance: Value(75.0), // State after transfer
      ));
      final bookingId = await database.into(database.bookings).insert(BookingsCompanion(
          amount: const Value(25.0),
          date: Value(getTodayAsInt()),
          sendingAccountId: Value(sendingId),
          receivingAccountId: Value(receivingId)));

      // ACT
      await database.bookingsDao.deleteBookingWithBalance(bookingId);

      // ASSERT
      final sendingAccount = await getAccount(sendingId);
      final receivingAccount = await getAccount(receivingId);
      expect(sendingAccount.balance, 100.0);
      expect(receivingAccount.balance, 50.0);
    });

    test('updating a booking correctly adjusts balances', () async {
      // ARRANGE
      final accountId = await database.accountsDao.addAccount(const AccountsCompanion(
        name: Value('Test Account'),
        balance: Value(150.0), // Balance after initial booking
      ));
      final bookingToUpdate = await database.bookingsDao.getBooking(
          await database.into(database.bookings).insert(BookingsCompanion(
              reason: const Value('Old'),
              amount: const Value(50.0),
              date: Value(getTodayAsInt()),
              receivingAccountId: Value(accountId))));

      // ACT
      final updatedCompanion = BookingsCompanion(
          id: Value(bookingToUpdate.id),
          amount: const Value(-20.0), // Change from +50 to -20
          date: Value(bookingToUpdate.date),
          reason: Value(bookingToUpdate.reason),
          receivingAccountId: Value(bookingToUpdate.receivingAccountId));
      await database.bookingsDao.updateBookingWithBalance(bookingToUpdate, updatedCompanion);

      // ASSERT
      final account = await getAccount(accountId);
      expect(account.balance, 80.0); // 150 - 50 (revert) + (-20) (apply) = 80
    });

    test('updating a transfer to an expense correctly adjusts balances', () async {
      // ARRANGE
      final sendingId = await database.accountsDao.addAccount(const AccountsCompanion(
        name: Value('Sending'),
        balance: Value(100.0),
      ));
      final receivingId = await database.accountsDao.addAccount(const AccountsCompanion(
        name: Value('Receiving'),
        balance: Value(50.0),
      ));

      // Create the initial transfer booking, which also updates balances.
      await database.bookingsDao.createBooking(BookingsCompanion(
        amount: const Value(25.0),
        date: Value(getTodayAsInt()),
        sendingAccountId: Value(sendingId),
        receivingAccountId: Value(receivingId),
      ));

      // Fetch the created booking to update it.
      final bookingToUpdate = (await database.select(database.bookings).get()).single;

      // ACT: Update the transfer to be an expense from the sending account.
      final updatedCompanion = BookingsCompanion(
        id: Value(bookingToUpdate.id),
        amount: const Value(-30.0), // New expense amount
        date: Value(bookingToUpdate.date),
        reason: const Value('New Expense'),
        receivingAccountId: Value(sendingId), // The expense is on the 'sending' account.
        sendingAccountId: const Value(null), // It's no longer a transfer.
      );

      await database.bookingsDao.updateBookingWithBalance(bookingToUpdate, updatedCompanion);

      // ASSERT
      final sendingAccount = await getAccount(sendingId);
      final receivingAccount = await getAccount(receivingId);

      // The sending account started at 100, went to 75 after the transfer,
      // and should now be 70 after the update (reverting +25, applying -30).
      expect(sendingAccount.balance, 70.0);

      // The receiving account started at 50, went to 75 after the transfer,
      // and should be back to 50 after the update (reverting -25).
      expect(receivingAccount.balance, 50.0);
    });
  });

  group('findMergeableBooking', () {
    test('should find a mergeable booking for a non-transfer', () async {
      // ARRANGE
      final accountId = await database.accountsDao.addAccount(const AccountsCompanion(
        name: Value('Test Account'),
        balance: Value(100.0),
      ));
      final existingBooking = BookingsCompanion(
        date: Value(getTodayAsInt()),
        reason: const Value('Drinks'),
        amount: const Value(-8.0),
        receivingAccountId: Value(accountId),
        excludeFromAverage: const Value(false),
      );
      await database.bookingsDao.createBooking(existingBooking);

      // ACT
      final newBooking = BookingsCompanion(
        date: Value(getTodayAsInt()),
        reason: const Value('Drinks'),
        amount: const Value(-7.0),
        receivingAccountId: Value(accountId),
        excludeFromAverage: const Value(false),
      );
      final mergeable = await database.bookingsDao.findMergeableBooking(newBooking);

      // ASSERT
      expect(mergeable, isNotNull);
      expect(mergeable!.amount, -8.0);
    });

    test('should not find a mergeable booking if notes are not empty', () async {
      // ARRANGE
      final accountId = await database.accountsDao.addAccount(const AccountsCompanion(
        name: Value('Test Account'),
        balance: Value(100.0),
      ));
      final existingBooking = BookingsCompanion(
        date: Value(getTodayAsInt()),
        reason: const Value('Drinks'),
        amount: const Value(-8.0),
        receivingAccountId: Value(accountId),
        notes: const Value('some notes'),
        excludeFromAverage: const Value(false),
      );
      await database.bookingsDao.createBooking(existingBooking);

      // ACT
      final newBooking = BookingsCompanion(
        date: Value(getTodayAsInt()),
        reason: const Value('Drinks'),
        amount: const Value(-7.0),
        receivingAccountId: Value(accountId),
        excludeFromAverage: const Value(false),
      );
      final mergeable = await database.bookingsDao.findMergeableBooking(newBooking);

      // ASSERT
      expect(mergeable, isNull);
    });

    test('should find a mergeable booking for a transfer with same accounts', () async {
      // ARRANGE
      final sendingId = await database.accountsDao.addAccount(const AccountsCompanion(name: Value('A'), balance: Value(100)));
      final receivingId = await database.accountsDao.addAccount(const AccountsCompanion(name: Value('B'), balance: Value(100)));
      await database.bookingsDao.createBooking(BookingsCompanion(
        date: Value(getTodayAsInt()),
        amount: const Value(10.0),
        sendingAccountId: Value(sendingId),
        receivingAccountId: Value(receivingId),
        excludeFromAverage: const Value(false),
      ));

      // ACT
      final newBooking = BookingsCompanion(
        date: Value(getTodayAsInt()),
        amount: const Value(5.0),
        sendingAccountId: Value(sendingId),
        receivingAccountId: Value(receivingId),
        excludeFromAverage: const Value(false),
      );
      final mergeable = await database.bookingsDao.findMergeableBooking(newBooking);

      // ASSERT
      expect(mergeable, isNotNull);
    });

    test('should find a mergeable booking for a transfer with swapped accounts', () async {
      // ARRANGE
      final sendingId = await database.accountsDao.addAccount(const AccountsCompanion(name: Value('A'), balance: Value(100)));
      final receivingId = await database.accountsDao.addAccount(const AccountsCompanion(name: Value('B'), balance: Value(100)));
      await database.bookingsDao.createBooking(BookingsCompanion(
        date: Value(getTodayAsInt()),
        amount: const Value(10.0),
        sendingAccountId: Value(sendingId),
        receivingAccountId: Value(receivingId),
        excludeFromAverage: const Value(false),
      ));

      // ACT
      final newBooking = BookingsCompanion(
        date: Value(getTodayAsInt()),
        amount: const Value(5.0),
        sendingAccountId: Value(receivingId), // Swapped
        receivingAccountId: Value(sendingId), // Swapped
        excludeFromAverage: const Value(false),
      );
      final mergeable = await database.bookingsDao.findMergeableBooking(newBooking);

      // ASSERT
      expect(mergeable, isNotNull);
    });

    test('should not find a mergeable booking if excludeFromAverage is different', () async {
      // ARRANGE
      final accountId = await database.accountsDao.addAccount(const AccountsCompanion(
        name: Value('Test Account'),
        balance: Value(100.0),
      ));
      await database.bookingsDao.createBooking(BookingsCompanion(
        date: Value(getTodayAsInt()),
        reason: const Value('Drinks'),
        amount: const Value(-8.0),
        receivingAccountId: Value(accountId),
        excludeFromAverage: const Value(false),
      ));

      // ACT
      final newBooking = BookingsCompanion(
        date: Value(getTodayAsInt()),
        reason: const Value('Drinks'),
        amount: const Value(-7.0),
        receivingAccountId: Value(accountId),
        excludeFromAverage: const Value(true), // Different flag
      );
      final mergeable = await database.bookingsDao.findMergeableBooking(newBooking);

      // ASSERT
      expect(mergeable, isNull);
    });

    test('should not find a mergeable booking if amount signs are different', () async {
      // ARRANGE
      final accountId = await database.accountsDao.addAccount(const AccountsCompanion(
        name: Value('Test Account'),
        balance: Value(100.0),
      ));
      await database.bookingsDao.createBooking(BookingsCompanion(
        date: Value(getTodayAsInt()),
        reason: const Value('Drinks'),
        amount: const Value(-8.0), // Expense
        receivingAccountId: Value(accountId),
        excludeFromAverage: const Value(false),
      ));

      // ACT
      final newBooking = BookingsCompanion(
        date: Value(getTodayAsInt()),
        reason: const Value('Drinks'),
        amount: const Value(7.0), // Income
        receivingAccountId: Value(accountId),
        excludeFromAverage: const Value(false),
      );
      final mergeable = await database.bookingsDao.findMergeableBooking(newBooking);

      // ASSERT
      expect(mergeable, isNull);
    });
  });
}
