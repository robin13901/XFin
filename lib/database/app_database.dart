import 'package:drift/drift.dart';
import 'package:xfin/database/accounts_dao.dart';
import 'package:xfin/database/bookings_dao.dart';
import 'package:xfin/database/tables.dart';

part 'app_database.g.dart';

// This file is now platform-agnostic.
// We'll use a separate file for the platform-specific implementation.

@DriftDatabase(tables: [Accounts, Bookings, StandingOrders, Goals], daos: [BookingsDao, AccountsDao])
class AppDatabase extends _$AppDatabase {
  AppDatabase(QueryExecutor e) : super(e);

  @override
  int get schemaVersion => 2;

  @override
  late final BookingsDao bookingsDao = BookingsDao(this);

  @override
  late final AccountsDao accountsDao = AccountsDao(this);
}
