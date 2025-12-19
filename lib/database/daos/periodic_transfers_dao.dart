import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables.dart';

part 'periodic_transfers_dao.g.dart';

@DriftAccessor(tables: [PeriodicTransfers, Accounts])
class PeriodicTransfersDao extends DatabaseAccessor<AppDatabase> with _$PeriodicTransfersDaoMixin {
  PeriodicTransfersDao(super.db);

}
