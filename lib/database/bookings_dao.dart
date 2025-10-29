import 'package:drift/drift.dart';
import 'package:xfin/database/app_database.dart';
import 'package:xfin/database/tables.dart';

part 'bookings_dao.g.dart';

// Data class to hold a booking with its associated account objects.
class BookingWithAccounts {
  final Booking booking;
  final Account? sendingAccount;
  final Account? receivingAccount;

  BookingWithAccounts({
    required this.booking,
    this.sendingAccount,
    this.receivingAccount,
  });
}

@DriftAccessor(tables: [Bookings, Accounts])
class BookingsDao extends DatabaseAccessor<AppDatabase> with _$BookingsDaoMixin {
  BookingsDao(super.db);

  Stream<List<BookingWithAccounts>> watchBookingsWithAccounts() {
    final sendingAccounts = alias(accounts, 's');
    final receivingAccounts = alias(accounts, 'r');

    final query = select(bookings).join([
      leftOuterJoin(sendingAccounts, sendingAccounts.id.equalsExp(bookings.sendingAccountId)),
      leftOuterJoin(receivingAccounts, receivingAccounts.id.equalsExp(bookings.receivingAccountId)),
    ]);

    query.orderBy([
      OrderingTerm.desc(bookings.date),
      OrderingTerm.desc(bookings.amount),
    ]);

    return query.watch().map((rows) {
      return rows.map((row) {
        return BookingWithAccounts(
          booking: row.readTable(bookings),
          sendingAccount: row.readTableOrNull(sendingAccounts),
          receivingAccount: row.readTableOrNull(receivingAccounts),
        );
      }).toList();
    });
  }

  Future<Booking?> findMergeableBooking(BookingsCompanion newBooking) async {
    final isTransfer = newBooking.sendingAccountId.present &&
        newBooking.sendingAccountId.value != null &&
        newBooking.receivingAccountId.present &&
        newBooking.receivingAccountId.value != null;

    if (isTransfer) {
      final query = select(bookings)
        ..where((tbl) =>
            tbl.date.equals(newBooking.date.value) &
            tbl.excludeFromAverage.equals(newBooking.excludeFromAverage.value) &
            tbl.notes.isNull() &
            tbl.sendingAccountId.isNotNull() &
            tbl.receivingAccountId.isNotNull());

      final potentialMatches = await query.get();

      for (final match in potentialMatches) {
        final sameAccounts = match.sendingAccountId == newBooking.sendingAccountId.value &&
            match.receivingAccountId == newBooking.receivingAccountId.value;
        final swappedAccounts = match.sendingAccountId == newBooking.receivingAccountId.value &&
            match.receivingAccountId == newBooking.sendingAccountId.value;

        if (sameAccounts || swappedAccounts) {
          return match;
        }
      }
    } else {
      final newAmount = newBooking.amount.value;
      final query = select(bookings)
        ..where((tbl) =>
            tbl.sendingAccountId.isNull() &
            tbl.date.equals(newBooking.date.value) &
            tbl.reason.equals(newBooking.reason.value!) &
            tbl.receivingAccountId.equals(newBooking.receivingAccountId.value!) &
            tbl.excludeFromAverage.equals(newBooking.excludeFromAverage.value) &
            tbl.notes.isNull() &
            ((tbl.amount.isBiggerThanValue(0) & Constant(newAmount > 0)) |
                (tbl.amount.isSmallerThanValue(0) & Constant(newAmount < 0))));

      try {
        return await query.getSingle();
      } catch (e) {
        return null;
      }
    }

    return null;
  }

  // Methods that are not transactional
  Future<int> _addBooking(BookingsCompanion entry) => into(bookings).insert(entry);
  Future<bool> _updateBooking(BookingsCompanion entry) => update(bookings).replace(entry);
  Future<int> _deleteBooking(int id) => (delete(bookings)..where((tbl) => tbl.id.equals(id))).go();
  Future<Booking> getBooking(int id) => (select(bookings)..where((tbl) => tbl.id.equals(id))).getSingle();


  // Transactional methods for booking manipulation
  Future<void> createBooking(BookingsCompanion entry) {
    return transaction(() async {
      await _addBooking(entry);
      final amount = entry.amount.value;
      if (entry.receivingAccountId.value != null) {
        await db.accountsDao.updateBalance(entry.receivingAccountId.value!, amount);
      }
      if (entry.sendingAccountId.value != null) {
        await db.accountsDao.updateBalance(entry.sendingAccountId.value!, -amount);
      }
    });
  }

  Future<void> updateBookingWithBalance(Booking oldBooking, BookingsCompanion newBooking) {
    return transaction(() async {
      await _updateBooking(newBooking);

      final oldAmount = oldBooking.amount;
      final newAmount = newBooking.amount.value;
      final oldReceiving = oldBooking.receivingAccountId;
      final newReceiving = newBooking.receivingAccountId.value;
      final oldSending = oldBooking.sendingAccountId;
      final newSending = newBooking.sendingAccountId.value;

      // Revert old booking
      if (oldReceiving != null) await db.accountsDao.updateBalance(oldReceiving, -oldAmount);
      if (oldSending != null) await db.accountsDao.updateBalance(oldSending, oldAmount);

      // Apply new booking
      if (newReceiving != null) await db.accountsDao.updateBalance(newReceiving, newAmount);
      if (newSending != null) await db.accountsDao.updateBalance(newSending, -newAmount);
    });
  }

  Future<void> deleteBookingWithBalance(int id) {
    return transaction(() async {
      final booking = await getBooking(id);
      await _deleteBooking(id);

      // Revert the booking's amount on the affected accounts
      if (booking.receivingAccountId != null) {
        await db.accountsDao.updateBalance(booking.receivingAccountId!, -booking.amount);
      }
      if (booking.sendingAccountId != null) {
        await db.accountsDao.updateBalance(booking.sendingAccountId!, booking.amount);
      }
    });
  }
}
