import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:xfin/database/app_database.dart';
import 'package:xfin/database/bookings_dao.dart';

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
      final accountId = await database.accountsDao.addAccount(AccountsCompanion(
        name: const Value('Test Account'),
        balance: const Value(100.0),
        initialBalance: const Value(100.0),
        type: const Value('Cash'),
        creationDate: Value(getTodayAsInt()),
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
      final accountId = await database.accountsDao.addAccount(AccountsCompanion(
        name: const Value('Test Account'),
        balance: const Value(100.0),
        initialBalance: const Value(100.0),
        type: const Value('Cash'),
        creationDate: Value(getTodayAsInt()),
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
      final sendingId = await database.accountsDao.addAccount(AccountsCompanion(
        name: const Value('Sending'),
        balance: const Value(100.0),
        initialBalance: const Value(100.0),
        type: const Value('Cash'),
        creationDate: Value(getTodayAsInt()),
      ));
      final receivingId = await database.accountsDao.addAccount(AccountsCompanion(
        name: const Value('Receiving'),
        balance: const Value(50.0),
        initialBalance: const Value(50.0),
        type: const Value('Cash'),
        creationDate: Value(getTodayAsInt()),
      ));

      // ACT
      final booking = BookingsCompanion(
        reason: const Value.absent(), // Transfers have null reason
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
      final accountId = await database.accountsDao.addAccount(AccountsCompanion(
        name: const Value('Test Account'),
        balance: const Value(150.0), // Balance after income
        initialBalance: const Value(100.0),
        type: const Value('Cash'),
        creationDate: Value(getTodayAsInt()),
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
      final sendingId = await database.accountsDao.addAccount(AccountsCompanion(
        name: const Value('Sending'),
        balance: const Value(75.0), // State after transfer
        initialBalance: const Value(100.0),
        type: const Value('Cash'),
        creationDate: Value(getTodayAsInt()),
      ));
      final receivingId = await database.accountsDao.addAccount(AccountsCompanion(
        name: const Value('Receiving'),
        balance: const Value(75.0), // State after transfer
        initialBalance: const Value(50.0),
        type: const Value('Cash'),
        creationDate: Value(getTodayAsInt()),
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
      final accountId = await database.accountsDao.addAccount(AccountsCompanion(
        name: const Value('Test Account'),
        balance: const Value(150.0), // Balance after initial booking
        initialBalance: const Value(100.0),
        type: const Value('Cash'),
        creationDate: Value(getTodayAsInt()),
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
      final sendingId = await database.accountsDao.addAccount(AccountsCompanion(
        name: const Value('Sending'),
        balance: const Value(100.0),
        initialBalance: const Value(100.0),
        type: const Value('Cash'),
        creationDate: Value(getTodayAsInt()),
      ));
      final receivingId = await database.accountsDao.addAccount(AccountsCompanion(
        name: const Value('Receiving'),
        balance: const Value(50.0),
        initialBalance: const Value(50.0),
        type: const Value('Cash'),
        creationDate: Value(getTodayAsInt()),
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
        sendingAccountId: const Value.absent(), // It's no longer a transfer.
      );

      await database.bookingsDao.updateBookingWithBalance(bookingToUpdate, updatedCompanion);

      // ASSERT
      final sendingAccount = await getAccount(sendingId);
      final receivingAccount = await getAccount(receivingId);

      // The sending account started at 100, went to 75 after the transfer, then a revert and an update are applied.
      // Revert: 75 + 25 = 100. Apply: 100 - 30 = 70.
      expect(sendingAccount.balance, 70.0);

      // The receiving account started at 50, went to 75 after the transfer, and should be back to 50 after the revert.
      expect(receivingAccount.balance, 50.0);
    });
  });

  group('findMergeableBooking', () {
    test('should find a mergeable booking for a non-transfer', () async {
      // ARRANGE
      final accountId = await database.accountsDao.addAccount(AccountsCompanion(
        name: const Value('Test Account'),
        balance: const Value(100.0),
        initialBalance: const Value(100.0),
        type: const Value('Cash'),
        creationDate: Value(getTodayAsInt()),
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
      final accountId = await database.accountsDao.addAccount(AccountsCompanion(
        name: const Value('Test Account'),
        balance: const Value(100.0),
        initialBalance: const Value(100.0),
        type: const Value('Cash'),
        creationDate: Value(getTodayAsInt()),
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
      final sendingId = await database.accountsDao.addAccount(AccountsCompanion(name: const Value('A'), balance: const Value(100), initialBalance: const Value(100), type: const Value('Cash'), creationDate: Value(getTodayAsInt())));
      final receivingId = await database.accountsDao.addAccount(AccountsCompanion(name: const Value('B'), balance: const Value(100), initialBalance: const Value(100), type: const Value('Cash'), creationDate: Value(getTodayAsInt())));
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
      final sendingId = await database.accountsDao.addAccount(AccountsCompanion(name: const Value('A'), balance: const Value(100), initialBalance: const Value(100), type: const Value('Cash'), creationDate: Value(getTodayAsInt())));
      final receivingId = await database.accountsDao.addAccount(AccountsCompanion(name: const Value('B'), balance: const Value(100), initialBalance: const Value(100), type: const Value('Cash'), creationDate: Value(getTodayAsInt())));
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
      final accountId = await database.accountsDao.addAccount(AccountsCompanion(
        name: const Value('Test Account'),
        balance: const Value(100.0),
        initialBalance: const Value(100.0),
        type: const Value('Cash'),
        creationDate: Value(getTodayAsInt()),
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
      final accountId = await database.accountsDao.addAccount(AccountsCompanion(
        name: const Value('Test Account'),
        balance: const Value(100.0),
        initialBalance: const Value(100.0),
        type: const Value('Cash'),
        creationDate: Value(getTodayAsInt()),
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

  group('watchBookingsWithAccounts', () {
    test('should return a stream of bookings with their accounts', () async {
      // ARRANGE
      final sendingId = await database.accountsDao.addAccount(AccountsCompanion(
        name: const Value('Sending Account'),
        balance: const Value(100.0),
        initialBalance: const Value(100.0),
        type: const Value('Cash'),
        creationDate: Value(getTodayAsInt()),
      ));
      final receivingId = await database.accountsDao.addAccount(AccountsCompanion(
        name: const Value('Receiving Account'),
        balance: const Value(0.0),
        initialBalance: const Value(0.0),
        type: const Value('Cash'),
        creationDate: Value(getTodayAsInt()),
      ));
      final bookingId = await database.into(database.bookings).insert(BookingsCompanion(
        amount: const Value(50.0),
        date: Value(getTodayAsInt()),
        sendingAccountId: Value(sendingId),
        receivingAccountId: Value(receivingId),
      ));

      // ACT
      final stream = database.bookingsDao.watchBookingsWithAccounts();

      // ASSERT
      expect(stream, emits(
        isA<List<BookingWithAccounts>>()
            .having((list) => list.length, 'length', 1)
            .having((list) => list.first.booking.id, 'booking id', bookingId)
            .having((list) => list.first.sendingAccount!.id, 'sending account id', sendingId)
            .having((list) => list.first.receivingAccount!.id, 'receiving account id', receivingId),
      ));
    });
  });
}
