import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables.dart';

part 'periodic_bookings_dao.g.dart';

@DriftAccessor(tables: [PeriodicBookings, Accounts])
class PeriodicBookingsDao extends DatabaseAccessor<AppDatabase> with _$PeriodicBookingsDaoMixin {
  PeriodicBookingsDao(super.db);

  // double _getCycleFactor(Cycles cycle) {
  //   switch (cycle) {
  //     case Cycles.daily:
  //       return 30.436875;
  //     case Cycles.weekly:
  //       return 30.436875 / 7;
  //     case Cycles.monthly:
  //       return 1.0;
  //     case Cycles.quarterly:
  //       return 1.0 / 3.0;
  //     case Cycles.yearly:
  //       return 1.0 / 12.0;
  //   }
  // }

}
