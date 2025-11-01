import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables.dart';

part 'bookings_dao.g.dart';

@DriftAccessor(tables: [Bookings, Accounts])
class BookingsDao extends DatabaseAccessor<AppDatabase> with _$BookingsDaoMixin {
  BookingsDao(super.db);

  void _validateDate(int dateInt) {
    final dateString = dateInt.toString();
    if (dateString.length != 8) {
      throw Exception('Date must be in yyyyMMdd format and a valid date.');
    }

    final year = int.tryParse(dateString.substring(0, 4)) ?? 0;
    final month = int.tryParse(dateString.substring(4, 6)) ?? 0;
    final day = int.tryParse(dateString.substring(6, 8)) ?? 0;

    try {
      final date = DateTime(year, month, day);
      if (date.year != year || date.month != month || date.day != day) {
        throw Exception('Date must be a valid date.');
      }
    } catch (e) {
      throw Exception('Date must be a valid date.');
    }
  }

  Future<void> validate(Booking booking) async {
    _validateDate(booking.date);
    if (booking.amount == 0) {
      throw Exception('Amount must not be 0.');
    }
    if (booking.reason.isEmpty) {
      throw Exception('Reason must not be empty.');
    }

    final account = await (select(accounts)..where((a) => a.id.equals(booking.accountId))).getSingle();
    if (account.type != AccountTypes.cash) {
      throw Exception('Account must be of type cash.');
    }
  }

  Stream<List<BookingWithAccount>> watchBookingsWithAccount() {
    final query = select(bookings).join([
      leftOuterJoin(accounts, accounts.id.equalsExp(bookings.accountId))
    ]);

    // Only show bookings from non-archived accounts, or where the account has been deleted.
    query.where(accounts.isArchived.equals(false) | accounts.id.isNull());

    query.orderBy([
      OrderingTerm.desc(bookings.date),
      OrderingTerm.desc(bookings.amount),
    ]);

    return query.watch().map((rows) {
      return rows.map((row) {
        return BookingWithAccount(
          booking: row.readTable(bookings),
          account: row.readTableOrNull(accounts),
        );
      }).toList();
    });
  }

  Future<Booking?> findMergeableBooking(BookingsCompanion newBooking) async {
    final newAmount = newBooking.amount.value;
    final query = select(bookings)
      ..where((tbl) =>
          tbl.date.equals(newBooking.date.value) &
          tbl.reason.equals(newBooking.reason.value) &
          tbl.accountId.equals(newBooking.accountId.value) &
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

  // Methods that are not transactional
  Future<int> _addBooking(BookingsCompanion entry) => into(bookings).insert(entry);
  Future<bool> _updateBooking(BookingsCompanion entry) => update(bookings).replace(entry);
  Future<int> _deleteBooking(int id) => (delete(bookings)..where((tbl) => tbl.id.equals(id))).go();
  Future<Booking> getBooking(int id) => (select(bookings)..where((tbl) => tbl.id.equals(id))).getSingle();

  // Transactional methods for booking manipulation
  Future<void> createBookingAndUpdateAccount(BookingsCompanion entry) {
    return transaction(() async {
      await _addBooking(entry);
      final amount = entry.amount.value;
      await db.accountsDao.updateBalance(entry.accountId.value, amount);
    });
  }

  Future<void> updateBookingAndUpdateAccount(Booking oldBooking, BookingsCompanion newBooking) {
    return transaction(() async {
      await _updateBooking(newBooking);

      final oldAmount = oldBooking.amount;
      final newAmount = newBooking.amount.value;
      final oldAccountId = oldBooking.accountId;
      final newAccountId = newBooking.accountId.value;

      if (oldAccountId == newAccountId) {
        final amountDelta = newAmount - oldAmount;
        await db.accountsDao.updateBalance(oldAccountId, amountDelta);
      } else {
        await db.accountsDao.updateBalance(oldAccountId, -oldAmount);
        await db.accountsDao.updateBalance(newAccountId, newAmount);
      }
    });
  }

  Future<void> deleteBookingAndUpdateAccount(int id) {
    return transaction(() async {
      final booking = await getBooking(id);
      await _deleteBooking(id);
      await db.accountsDao.updateBalance(booking.accountId, -booking.amount);
    });
  }
}

// Data class to hold a booking with its associated account object.
class BookingWithAccount {
  final Booking booking;
  final Account? account;

  BookingWithAccount({
    required this.booking,
    this.account,
  });
}
