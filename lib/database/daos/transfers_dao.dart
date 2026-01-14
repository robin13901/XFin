import 'package:drift/drift.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/global_constants.dart';
import '../app_database.dart';
import '../tables.dart';

part 'transfers_dao.g.dart';

@DriftAccessor(tables: [Transfers, Accounts, Assets, AssetsOnAccounts])
class TransfersDao extends DatabaseAccessor<AppDatabase>
    with _$TransfersDaoMixin {
  TransfersDao(super.db);

  /// Watch transfers together with sending + receiving accounts and the asset.
  Stream<List<TransferWithAccountsAndAsset>>
      watchTransfersWithAccountsAndAsset() {
    final sending = alias(accounts, 'sending');
    final receiving = alias(accounts, 'receiving');

    final query = select(transfers).join([
      leftOuterJoin(sending, sending.id.equalsExp(transfers.sendingAccountId)),
      leftOuterJoin(
          receiving, receiving.id.equalsExp(transfers.receivingAccountId)),
      leftOuterJoin(assets, assets.id.equalsExp(transfers.assetId)),
    ]);

    // Only show transfers where both accounts are not archived
    query.where(
        sending.isArchived.equals(false) & receiving.isArchived.equals(false));

    query.orderBy([
      OrderingTerm.desc(transfers.date),
      OrderingTerm.desc(transfers.shares),
    ]);

    return query.watch().map((rows) {
      return rows.map((row) {
        return TransferWithAccountsAndAsset(
          transfer: row.readTable(transfers),
          sendingAccount: row.readTable(sending),
          receivingAccount: row.readTable(receiving),
          asset: row.readTable(assets),
        );
      }).toList();
    });
  }

  Future<int> _insert(TransfersCompanion entry) =>
      into(transfers).insert(entry);

  Future<bool> _update(TransfersCompanion entry) =>
      update(transfers).replace(entry);

  Future<int> _delete(int id) =>
      (delete(transfers)..where((t) => t.id.equals(id))).go();

  Future<Transfer> getTransfer(int id) =>
      (select(transfers)..where((t) => t.id.equals(id))).getSingle();

  Future<List<Transfer>> getAllTransfers() => select(transfers).get();

  Future<List<Transfer>> getTransfersAfter(
          int assetId, int accountId, int datetime) =>
      (select(transfers)
            ..where((t) =>
                t.assetId.equals(assetId) &
                (t.sendingAccountId.equals(accountId) |
                    t.receivingAccountId.equals(accountId)) &
                t.date.isBiggerOrEqualValue(datetime ~/ 1000000))
            ..orderBy([
              (t) => OrderingTerm(expression: t.date),
            ]))
          .get();

  Future<List<Transfer>> getTransfersForAccount(
          int accountId) =>
      (select(transfers)
            ..where((t) =>
                t.sendingAccountId.equals(accountId) |
                t.receivingAccountId.equals(accountId)))
          .get();

  Future<List<Transfer>> getTransfersForAOA(int assetId, int accountId) =>
      (select(transfers)
            ..where((tr) =>
                tr.assetId.equals(assetId) &
                ((tr.receivingAccountId.equals(accountId)) |
                    (tr.sendingAccountId.equals(accountId)))))
          .get();

  Future<TransfersCompanion> _calculateCostBasisAndValue(TransfersCompanion t,
      {Transfer? tOld}) async {
    final shares = t.shares.value;
    double costBasis = 1, value = shares * costBasis;

    if (t.assetId.value != 1) {
      final fifo = await db.assetsOnAccountsDao.buildFiFoQueue(
          t.assetId.value, t.sendingAccountId.value,
          upToDatetime: t.date.value * 1000000, oldTransfer: tOld);

      (value, _) = consumeFiFo(fifo, shares);
      value = value.abs();
      costBasis = value / shares.abs();
    }
    return t.copyWith(
        costBasis: Value(normalize(costBasis)), value: Value(normalize(value)));
  }

  Future<void> createTransfer(TransfersCompanion t, AppLocalizations l10n) {
    return transaction(() async {
      if (!t.costBasis.present) t = await _calculateCostBasisAndValue(t);

      final transferId = await _insert(t);

      await db.tradesDao.applyDbEffects(t.assetId.value,
          t.sendingAccountId.value, -t.shares.value, -t.value.value, 0,
          updateAsset: false);
      await db.tradesDao.applyDbEffects(t.assetId.value,
          t.receivingAccountId.value, t.shares.value, t.value.value, 0,
          updateAsset: false);

      await db.assetsOnAccountsDao.recalculateSubsequentEvents(
        l10n: l10n,
        assetId: t.assetId.value,
        accountId: t.receivingAccountId.value,
        upToDatetime: t.date.value * 1000000 + 1,
        upToType: '_transfer',
        upToId: transferId,
      );
    });
  }

  Future<void> updateTransfer(
      Transfer tOld, TransfersCompanion tNew, AppLocalizations l10n) {
    return transaction(() async {
      tNew = await _calculateCostBasisAndValue(tNew, tOld: tOld);
      tNew = tNew.copyWith(id: Value(tOld.id));

      await _update(tNew);

      await db.tradesDao.applyDbEffects(
          tOld.assetId, tOld.sendingAccountId, tOld.shares, tOld.value, 0,
          updateAsset: false);
      await db.tradesDao.applyDbEffects(
          tOld.assetId, tOld.receivingAccountId, -tOld.shares, -tOld.value, 0,
          updateAsset: false);

      await db.tradesDao.applyDbEffects(tNew.assetId.value,
          tNew.sendingAccountId.value, -tNew.shares.value, -tNew.value.value, 0,
          updateAsset: false);
      await db.tradesDao.applyDbEffects(tNew.assetId.value,
          tNew.receivingAccountId.value, tNew.shares.value, tNew.value.value, 0,
          updateAsset: false);

      await db.assetsOnAccountsDao.recalculateSubsequentEvents(
        l10n: l10n,
        assetId: tOld.assetId,
        accountId: tOld.receivingAccountId,
        upToDatetime: tOld.date * 1000000 + 1,
        upToType: '_transfer',
        upToId: tOld.id,
      );

      if (tOld.receivingAccountId != tNew.receivingAccountId.value ||
          tOld.assetId != tNew.assetId.value) {
        await db.assetsOnAccountsDao.recalculateSubsequentEvents(
          l10n: l10n,
          assetId: tNew.assetId.value,
          accountId: tNew.receivingAccountId.value,
          upToDatetime: tNew.date.value * 1000000 + 1,
          upToType: '_transfer',
          upToId: tOld.id,
        );
      }
    });
  }

  Future<void> deleteTransfer(int id, AppLocalizations l10n) {
    return transaction(() async {
      final t = await getTransfer(id);

      await db.tradesDao.applyDbEffects(
          t.assetId, t.sendingAccountId, t.shares, t.value, 0,
          updateAsset: false);
      await db.tradesDao.applyDbEffects(
          t.assetId, t.receivingAccountId, -t.shares, -t.value, 0,
          updateAsset: false);

      await _delete(id);

      await db.assetsOnAccountsDao.recalculateSubsequentEvents(
        l10n: l10n,
        assetId: t.assetId,
        accountId: t.receivingAccountId,
        upToDatetime: t.date * 1000000 + 1,
        upToType: '_transfer',
        upToId: id,
      );
    });
  }
}

class TransferWithAccountsAndAsset {
  final Transfer transfer;
  final Account sendingAccount;
  final Account receivingAccount;
  final Asset asset;

  TransferWithAccountsAndAsset({
    required this.transfer,
    required this.sendingAccount,
    required this.receivingAccount,
    required this.asset,
  });
}
