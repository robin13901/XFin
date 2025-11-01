import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables.dart';

part 'periodic_bookings_dao.g.dart';

@DriftAccessor(tables: [PeriodicBookings, Accounts])
class PeriodicBookingsDao extends DatabaseAccessor<AppDatabase> with _$PeriodicBookingsDaoMixin {
  PeriodicBookingsDao(super.db);

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

  Future<void> validate(PeriodicBooking periodicBooking) async {
    _validateDate(periodicBooking.nextExecutionDate);
    if (periodicBooking.amount == 0) {
      throw Exception('Amount must not be 0.');
    }
    if (periodicBooking.reason.isEmpty) {
      throw Exception('Reason must not be empty.');
    }

    final account = await (select(accounts)..where((a) => a.id.equals(periodicBooking.accountId))).getSingle();
    if (account.type != AccountTypes.cash) {
      throw Exception('Account must be of type cash.');
    }
  }
}
