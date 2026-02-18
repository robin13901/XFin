import 'package:drift/drift.dart';
import 'package:xfin/utils/format.dart';
import 'package:xfin/utils/global_constants.dart';
import '../../l10n/app_localizations.dart';
import '../app_database.dart';
import '../tables.dart';

part 'periodic_bookings_dao.g.dart';

@DriftAccessor(tables: [PeriodicBookings, Accounts])
class PeriodicBookingsDao extends DatabaseAccessor<AppDatabase>
    with _$PeriodicBookingsDaoMixin {
  PeriodicBookingsDao(super.db);

  List<PeriodicBookingWithAccountAndAsset> _mapRows(List<TypedResult> rows) {
    return rows.map((row) {
      return PeriodicBookingWithAccountAndAsset(
        periodicBooking: row.readTable(periodicBookings),
        account: row.readTable(accounts),
        asset: row.readTable(assets),
      );
    }).toList();
  }

  Future<int> insertPeriodicBooking(PeriodicBookingsCompanion companion) {
    return into(periodicBookings).insert(companion);
  }

  Future<void> updatePeriodicBooking(PeriodicBookingsCompanion companion) {
    return update(periodicBookings).replace(companion);
  }

  Future<void> deletePeriodicBooking(int id) async {
    await (delete(periodicBookings)..where((t) => t.id.equals(id))).go();
  }

  Future<List<PeriodicBooking>> getAll() => select(periodicBookings).get();

  Stream<List<PeriodicBookingWithAccountAndAsset>>? watchAll() {
    final query = select(periodicBookings).join([
      leftOuterJoin(
          accounts, accounts.id.equalsExp(periodicBookings.accountId)),
      leftOuterJoin(assets, assets.id.equalsExp(periodicBookings.assetId)),
    ]);

    query.where(accounts.isArchived.equals(false));
    query.where(assets.isArchived.equals(false));

    query.orderBy([
      OrderingTerm.desc(periodicBookings.nextExecutionDate),
      OrderingTerm.desc(periodicBookings.value),
    ]);

    return query.watch().map(_mapRows);
  }

  Future<int> executePending(AppLocalizations l10n) async {
    int now = dateTimeToInt(DateTime.now());
    int executedCount = 0;
    return transaction(() async {
      final all = await getAll();
      for (PeriodicBooking pb in all) {
        while (pb.nextExecutionDate <= now) {
          await db.bookingsDao.createFromPeriodicBooking(pb, l10n);
          executedCount++;
          pb = pb.copyWith(nextExecutionDate: _calculateNextExecutionDate(pb));
          await updatePeriodicBooking(pb.toCompanion(false));
        }
      }
      return executedCount;
    });
  }

  int _calculateNextExecutionDate(PeriodicBooking pb) {
    DateTime current = intToDateTime(pb.nextExecutionDate)!;
    switch (pb.cycle) {
      case Cycles.daily:
        return dateTimeToInt(current.add(const Duration(days: 1)));
      case Cycles.weekly:
        return dateTimeToInt(current.add(const Duration(days: 7)));
      case Cycles.monthly:
        return dateTimeToInt(addMonths(current, 1));
      case Cycles.quarterly:
        return dateTimeToInt(addMonths(current, 3));
      case Cycles.yearly:
        return dateTimeToInt(addMonths(current, 12));
    }
  }
}

class PeriodicBookingWithAccountAndAsset {
  final PeriodicBooking periodicBooking;
  final Account account;
  final Asset asset;

  PeriodicBookingWithAccountAndAsset(
      {required this.periodicBooking,
      required this.account,
      required this.asset});
}
