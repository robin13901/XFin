import 'package:drift/drift.dart';
import 'daos/accounts_dao.dart';
import 'daos/analysis_dao.dart';
import 'daos/assets_dao.dart';
import 'daos/assets_on_accounts_dao.dart';
import 'daos/bookings_dao.dart';
import 'daos/goals_dao.dart';
import 'daos/periodic_bookings_dao.dart';
import 'daos/periodic_transfers_dao.dart';
import 'daos/trades_dao.dart';
import 'daos/transfers_dao.dart';
import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [
  Accounts,
  Assets,
  Bookings,
  Transfers,
  Trades,
  PeriodicBookings,
  PeriodicTransfers,
  AssetsOnAccounts,
  Goals
], daos: [
  AccountsDao,
  AnalysisDao,
  AssetsDao,
  AssetsOnAccountsDao,
  BookingsDao,
  GoalsDao,
  PeriodicBookingsDao,
  PeriodicTransfersDao,
  TradesDao,
  TransfersDao
])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
  );

}
