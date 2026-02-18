import 'package:drift/drift.dart';
import 'package:xfin/utils/format.dart';
import 'package:xfin/utils/global_constants.dart';
import '../../l10n/app_localizations.dart';
import '../app_database.dart';
import '../tables.dart';

part 'periodic_transfers_dao.g.dart';

@DriftAccessor(tables: [PeriodicTransfers, Accounts, Assets])
class PeriodicTransfersDao extends DatabaseAccessor<AppDatabase>
    with _$PeriodicTransfersDaoMixin {
  PeriodicTransfersDao(super.db);

  Future<int> insertPeriodicTransfer(PeriodicTransfersCompanion companion) {
    return into(periodicTransfers).insert(companion);
  }

  Future<void> updatePeriodicTransfer(PeriodicTransfersCompanion companion) {
    return update(periodicTransfers).replace(companion);
  }

  Future<void> deletePeriodicTransfer(int id) async {
    await (delete(periodicTransfers)..where((t) => t.id.equals(id))).go();
  }

  Future<List<PeriodicTransfer>> getAll() => select(periodicTransfers).get();

  Stream<List<PeriodicTransferWithAccountAndAsset>> watchAll() {
    final fromAccounts = alias(accounts, 'from_accounts');
    final toAccounts = alias(accounts, 'to_accounts');

    final query = select(periodicTransfers).join([
      leftOuterJoin(fromAccounts, fromAccounts.id.equalsExp(periodicTransfers.sendingAccountId)),
      leftOuterJoin(toAccounts, toAccounts.id.equalsExp(periodicTransfers.receivingAccountId)),
      leftOuterJoin(assets, assets.id.equalsExp(periodicTransfers.assetId)),
    ]);

    query.where(fromAccounts.isArchived.equals(false));
    query.where(toAccounts.isArchived.equals(false));
    query.where(assets.isArchived.equals(false));

    query.orderBy([
      OrderingTerm.desc(periodicTransfers.nextExecutionDate),
      OrderingTerm.desc(periodicTransfers.value),
    ]);

    return query.watch().map((rows) {
      return rows.map((row) {
        return PeriodicTransferWithAccountAndAsset(
          periodicTransfer: row.readTable(periodicTransfers),
          fromAccount: row.readTable(fromAccounts),
          toAccount: row.readTable(toAccounts),
          asset: row.readTable(assets),
        );
      }).toList();
    });
  }

  Future<int> executePending(AppLocalizations l10n) async {
    int now = dateTimeToInt(DateTime.now());
    int executedCount = 0;
    return transaction(() async {
      final all = await getAll();
      for (PeriodicTransfer pt in all) {
        while (pt.nextExecutionDate <= now) {
          await db.transfersDao.createFromPeriodicTransfer(pt, l10n);
          executedCount++;
          pt = pt.copyWith(nextExecutionDate: _calculateNextExecutionDate(pt));
          await updatePeriodicTransfer(pt.toCompanion(false));
        }
      }
      return executedCount;
    });
  }

  int _calculateNextExecutionDate(PeriodicTransfer pt) {
    DateTime current = intToDateTime(pt.nextExecutionDate)!;
    switch (pt.cycle) {
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

class PeriodicTransferWithAccountAndAsset {
  final PeriodicTransfer periodicTransfer;
  final Account fromAccount;
  final Account toAccount;
  final Asset asset;

  PeriodicTransferWithAccountAndAsset({
    required this.periodicTransfer,
    required this.fromAccount,
    required this.toAccount,
    required this.asset,
  });
}
