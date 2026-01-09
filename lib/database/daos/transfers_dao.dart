import 'package:drift/drift.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/global_constants.dart';
import '../app_database.dart';
import '../tables.dart';

part 'transfers_dao.g.dart';

@DriftAccessor(tables: [Transfers, Accounts, Assets, AssetsOnAccounts])
class TransfersDao extends DatabaseAccessor<AppDatabase> with _$TransfersDaoMixin {
  TransfersDao(super.db);

  /// Watch transfers together with sending + receiving accounts and the asset.
  Stream<List<TransferWithAccountsAndAsset>> watchTransfersWithAccountsAndAsset() {
    final sending = alias(accounts, 'sending');
    final receiving = alias(accounts, 'receiving');

    final query = select(transfers).join([
      leftOuterJoin(sending, sending.id.equalsExp(transfers.sendingAccountId)),
      leftOuterJoin(receiving, receiving.id.equalsExp(transfers.receivingAccountId)),
      leftOuterJoin(assets, assets.id.equalsExp(transfers.assetId)),
    ]);

    // Only show transfers where both accounts are not archived
    query.where(sending.isArchived.equals(false) & receiving.isArchived.equals(false));

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

  // Simple helpers (non-transactional)
  Future<int> _addTransfer(TransfersCompanion entry) => into(transfers).insert(entry);

  Future<bool> _updateTransfer(TransfersCompanion entry) => update(transfers).replace(entry);

  Future<int> _deleteTransfer(int id) =>
      (delete(transfers)..where((t) => t.id.equals(id))).go();

  Future<Transfer> getTransfer(int id) =>
      (select(transfers)..where((t) => t.id.equals(id))).getSingle();

  Future<List<Transfer>> getAllTransfers() => select(transfers).get();


  Future<TransfersCompanion> calculateCostBasisAndValue(TransfersCompanion transfer,
      {Transfer? oldTransfer}) async {
    final assetId = transfer.assetId.value;
    final accountId = transfer.sendingAccountId.value;
    final shares = transfer.shares.value;
    final datetime = transfer.date.value * 1000000;
    double costBasis, value = 0.0;

    if (assetId == 1) {
      costBasis = 1;
      value = shares * costBasis;
    } else {
      final fifo = await db.assetsOnAccountsDao.buildFiFoQueue(
          assetId, accountId,
          upToDatetime: datetime, oldTransfer: oldTransfer);

      double sharesToConsume = shares.abs();
      while (sharesToConsume > 0 && fifo.isNotEmpty) {
        final currentLot = fifo.first;
        final lotShares = currentLot['shares']!;
        final lotCostBasis = currentLot['costBasis']!;

        if (lotShares <= sharesToConsume + 1e-12) {
          sharesToConsume -= lotShares;
          value += lotShares * lotCostBasis;
          fifo.removeFirst();
        } else {
          currentLot['shares'] = lotShares - sharesToConsume;
          value += sharesToConsume * lotCostBasis;
          sharesToConsume = 0;
        }
      }
      costBasis = value / shares.abs();
    }
    return transfer.copyWith(costBasis: Value(normalize(costBasis)), value: Value(normalize(value)));
  }

  /// Create a transfer and apply its effects:
  /// - subtract value from sending account balance
  /// - add value to receiving account balance
  /// - adjust AssetsOnAccounts: subtract shares/value from sending account, add shares/value to receiving account
  Future<void> createTransfer(TransfersCompanion transfer, AppLocalizations l10n) {
    return transaction(() async {
      if (!transfer.costBasis.present) {
        transfer = await calculateCostBasisAndValue(transfer);
      }

      final transferId = await _addTransfer(transfer);

      final sendingId = transfer.sendingAccountId.value;
      final receivingId = transfer.receivingAccountId.value;
      final assetId = transfer.assetId.value;
      final shares = transfer.shares.value;
      final value = transfer.value.value;

      // Update balances
      await db.accountsDao.updateBalance(sendingId, -value);
      await db.accountsDao.updateBalance(receivingId, value);

      // Update AssetsOnAccounts
      await db.assetsOnAccountsDao.updateAOA(AssetOnAccount(
        accountId: sendingId,
        assetId: assetId,
        value: -value,
        shares: -shares,
        netCostBasis: 0,
        brokerCostBasis: 0,
        buyFeeTotal: 0,
      ));

      await db.assetsOnAccountsDao.updateAOA(AssetOnAccount(
        accountId: receivingId,
        assetId: assetId,
        value: value,
        shares: shares,
        netCostBasis: 0,
        brokerCostBasis: 0,
        buyFeeTotal: 0,
      ));

      // await db.assetsOnAccountsDao.recalculateSubsequentEvents(
      //   assetId: transfer.assetId.value,
      //   accountId: transfer.sendingAccountId.value,
      //   upToDatetime: transfer.date.value * 1000000 + 1,
      //   upToType: '_transfer',
      //   upToId: transferId,
      // );

      await db.assetsOnAccountsDao.recalculateSubsequentEvents(
        l10n: l10n,
        assetId: transfer.assetId.value,
        accountId: transfer.receivingAccountId.value,
        upToDatetime: transfer.date.value * 1000000 + 1,
        upToType: '_transfer',
        upToId: transferId,
      );

      // Note: global Assets (assets table) represent totals across accounts.
      // A transfer between accounts does not change the global totals, so we do not update assets table here.
    });
  }

  /// Update a transfer. Implementation:
  /// - replace the transfer row
  /// - reverse the effects of the old transfer (restore sending account, remove from receiving)
  /// - apply the effects of the new transfer
  /// Doing it this way keeps logic simple and correct for all cases (changed accounts, changed asset, changed amount).
  Future<void> updateTransfer(Transfer oldTransfer, TransfersCompanion newTransfer, AppLocalizations l10n) {
    return transaction(() async {
      newTransfer = await calculateCostBasisAndValue(newTransfer, oldTransfer: oldTransfer);
      // if (!newTransfer.costBasis.present) {
      //   final costBasis = await _calculateCostBasis(newTransfer, oldTransfer: oldTransfer);
      //   final value = newTransfer.shares.value * costBasis;
      //   newTransfer = newTransfer.copyWith(costBasis: Value(costBasis), value: Value(value));
      // }
      newTransfer = newTransfer.copyWith(id: Value(oldTransfer.id));


      // We'll collect recalc tasks in this set (avoid duplicates).
      // Each entry is a tuple (assetId, accountId, datetime)
      final Set<String> recalcTasks = {};

      // Helper to add a task (string key to make set dedupe easy)
      void addRecalcTask(int assetId, int accountId, int dateUtc) {
        // dateUtc is yyyyMMddhhmmss (we'll store as int)
        final key = '$assetId|$accountId|$dateUtc';
        recalcTasks.add(key);
      }

      // Update the DB row first
      await _updateTransfer(newTransfer);

      // Reverse old effects
      final oldSending = oldTransfer.sendingAccountId;
      final oldReceiving = oldTransfer.receivingAccountId;
      final oldAssetId = oldTransfer.assetId;
      final oldShares = oldTransfer.shares;
      final oldValue = oldTransfer.value;

      // Restore balances: sending gets back its oldValue, receiving loses the oldValue
      await db.accountsDao.updateBalance(oldSending, oldValue);
      await db.accountsDao.updateBalance(oldReceiving, -oldValue);

      // Restore AOAs for old transfer
      await db.assetsOnAccountsDao.updateAOA(AssetOnAccount(
        accountId: oldSending,
        assetId: oldAssetId,
        value: oldValue,
        shares: oldShares,
        netCostBasis: 0,
        brokerCostBasis: 0,
        buyFeeTotal: 0,
      ));

      await db.assetsOnAccountsDao.updateAOA(AssetOnAccount(
        accountId: oldReceiving,
        assetId: oldAssetId,
        value: -oldValue,
        shares: -oldShares,
        netCostBasis: 0,
        brokerCostBasis: 0,
        buyFeeTotal: 0,
      ));

      // Apply new effects
      final newSending = newTransfer.sendingAccountId.value;
      final newReceiving = newTransfer.receivingAccountId.value;
      final newAssetId = newTransfer.assetId.value;
      final newShares = newTransfer.shares.value;
      final newValue = newTransfer.value.value;

      // For update we want to schedule recalculation for all affected (asset,account) pairs.
      final oldKeyDt = oldTransfer.date * 1000000;
      final newKeyDt = newTransfer.date.value * 1000000;
      addRecalcTask(oldAssetId, oldSending, oldKeyDt);
      addRecalcTask(oldAssetId, oldReceiving, newKeyDt);
      addRecalcTask(newAssetId, newSending, oldKeyDt);
      addRecalcTask(newAssetId, newReceiving, newKeyDt);

      await db.accountsDao.updateBalance(newSending, -newValue);
      await db.accountsDao.updateBalance(newReceiving, newValue);

      await db.assetsOnAccountsDao.updateAOA(AssetOnAccount(
        accountId: newSending,
        assetId: newAssetId,
        value: -newValue,
        shares: -newShares,
        netCostBasis: 0,
        brokerCostBasis: 0,
        buyFeeTotal: 0,
      ));

      await db.assetsOnAccountsDao.updateAOA(AssetOnAccount(
        accountId: newReceiving,
        assetId: newAssetId,
        value: newValue,
        shares: newShares,
        netCostBasis: 0,
        brokerCostBasis: 0,
        buyFeeTotal: 0,
      ));

      // --- AFTER all immediate numeric updates: run recalc for each affected pair ---
      // Convert the deduped string keys back to (assetId, accountId, datetime)
      for (final k in recalcTasks) {
        final parts = k.split('|');
        final assetIdToRecalc = int.parse(parts[0]);
        final accountIdToRecalc = int.parse(parts[1]);
        final dt = int.parse(parts[2]); // already yyyyMMddhhmmss

        await db.assetsOnAccountsDao.recalculateSubsequentEvents(
          l10n: l10n,
          assetId: assetIdToRecalc,
          accountId: accountIdToRecalc,
          upToDatetime: dt + 1,
          upToType: '_transfer',
          upToId: oldTransfer.id, // existing transfer id (same for update)
        );
      }

    });
  }

  /// Delete a transfer and reverse its effects.
  Future<void> deleteTransfer(int id, AppLocalizations l10n) {
    return transaction(() async {
      final transfer = await getTransfer(id);

      // Reverse effects
      await db.accountsDao.updateBalance(transfer.sendingAccountId, transfer.value);
      await db.accountsDao.updateBalance(transfer.receivingAccountId, -transfer.value);

      await db.assetsOnAccountsDao.updateAOA(AssetOnAccount(
        accountId: transfer.sendingAccountId,
        assetId: transfer.assetId,
        value: transfer.value,
        shares: transfer.shares,
        netCostBasis: 0,
        brokerCostBasis: 0,
        buyFeeTotal: 0,
      ));

      await db.assetsOnAccountsDao.updateAOA(AssetOnAccount(
        accountId: transfer.receivingAccountId,
        assetId: transfer.assetId,
        value: -transfer.value,
        shares: -transfer.shares,
        netCostBasis: 0,
        brokerCostBasis: 0,
        buyFeeTotal: 0,
      ));

      // Delete row
      await _deleteTransfer(id);

      await db.assetsOnAccountsDao.recalculateSubsequentEvents(
        l10n: l10n,
        assetId: transfer.assetId,
        accountId: transfer.receivingAccountId, // call on sending account; recursion handles receiver
        upToDatetime: transfer.date * 1000000 + 1,
        upToType: '_transfer',
        upToId: id,
      );

    });
  }
}

/// Convenience data holder for a transfer with both accounts and the asset.
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