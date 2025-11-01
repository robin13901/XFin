import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables.dart';

part 'periodic_transfers_dao.g.dart';

@DriftAccessor(tables: [PeriodicTransfers, Accounts])
class PeriodicTransfersDao extends DatabaseAccessor<AppDatabase> with _$PeriodicTransfersDaoMixin {
  PeriodicTransfersDao(super.db);

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

  Future<void> validate(PeriodicTransfer periodicTransfer) async {
    _validateDate(periodicTransfer.nextExecutionDate);
    if (periodicTransfer.amount <= 0) {
      throw Exception('Amount must be greater than 0.');
    }

    if (periodicTransfer.sendingAccountId == periodicTransfer.receivingAccountId) {
      throw Exception('Sending and receiving account cannot be the same.');
    }

    final sendingAccount = await (select(accounts)..where((a) => a.id.equals(periodicTransfer.sendingAccountId))).getSingle();
    if (sendingAccount.type != AccountTypes.cash) {
      throw Exception('Sending account must be of type cash.');
    }

    final receivingAccount = await (select(accounts)..where((a) => a.id.equals(periodicTransfer.receivingAccountId))).getSingle();
    if (receivingAccount.type != AccountTypes.cash) {
      throw Exception('Receiving account must be of type cash.');
    }
  }
}
