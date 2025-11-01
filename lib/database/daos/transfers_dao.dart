import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables.dart';

part 'transfers_dao.g.dart';

@DriftAccessor(tables: [Transfers, Accounts])
class TransfersDao extends DatabaseAccessor<AppDatabase> with _$TransfersDaoMixin {
  TransfersDao(super.db);

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

  Future<void> validate(Transfer transfer) async {
    _validateDate(transfer.date);
    if (transfer.amount <= 0) {
      throw Exception('Amount must be greater than 0.');
    }

    if (transfer.sendingAccountId == transfer.receivingAccountId) {
      throw Exception('Sending and receiving account cannot be the same.');
    }

    final sendingAccount = await (select(accounts)..where((a) => a.id.equals(transfer.sendingAccountId))).getSingle();
    if (sendingAccount.type != AccountTypes.cash) {
      throw Exception('Sending account must be of type cash.');
    }

    final receivingAccount = await (select(accounts)..where((a) => a.id.equals(transfer.receivingAccountId))).getSingle();
    if (receivingAccount.type != AccountTypes.cash) {
      throw Exception('Receiving account must be of type cash.');
    }
  }

  Future<int> _addTransfer(TransfersCompanion entry) => into(transfers).insert(entry);

  Future<int> _deleteTransfer(int id) => (delete(transfers)..where((tbl) => tbl.id.equals(id))).go();

  Future<Transfer> getTransfer(int id) => (select(transfers)..where((tbl) => tbl.id.equals(id))).getSingle();

  Future<int> createTransferAndUpdateAccounts(TransfersCompanion entry) {
    return transaction(() async {
      final transferId = await _addTransfer(entry);
      final amount = entry.amount.value;
      await db.accountsDao.updateBalance(entry.sendingAccountId.value, -amount);
      await db.accountsDao.updateBalance(entry.receivingAccountId.value, amount);
      return transferId;
    });
  }

  Future<void> deleteTransferAndUpdateAccounts(int id) {
    return transaction(() async {
      final transfer = await getTransfer(id);
      await _deleteTransfer(id);
      await db.accountsDao.updateBalance(transfer.sendingAccountId, transfer.amount);
      await db.accountsDao.updateBalance(transfer.receivingAccountId, -transfer.amount);
    });
  }
}
