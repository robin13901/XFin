import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
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
        date: Value(DateTime.now().millisecondsSinceEpoch),
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
        date: Value(DateTime.now().millisecondsSinceEpoch),
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
        date: Value(DateTime.now().millisecondsSinceEpoch),
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
          date: const Value(0),
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
          date: const Value(0),
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
              date: const Value(0),
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
  });
}
