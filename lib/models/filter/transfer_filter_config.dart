import '../../database/app_database.dart';
import '../../l10n/app_localizations.dart';
import 'filter_config.dart';
import 'filter_rule.dart';

/// Builds filter configuration for Transfers entity
FilterConfig buildTransferFilterConfig(AppLocalizations l10n, AppDatabase db) {
  return FilterConfig(
    title: l10n.filterTransfers,
    fields: [
      FilterField(
        id: 'value',
        displayName: l10n.value,
        type: FilterFieldType.numeric,
      ),
      FilterField(
        id: 'shares',
        displayName: l10n.shares,
        type: FilterFieldType.numeric,
      ),
      FilterField(
        id: 'notes',
        displayName: l10n.notes,
        type: FilterFieldType.text,
      ),
      FilterField(
        id: 'assetId',
        displayName: l10n.asset,
        type: FilterFieldType.dropdown,
      ),
      FilterField(
        id: 'sendingAccountId',
        displayName: l10n.sendingAccount,
        type: FilterFieldType.dropdown,
      ),
      FilterField(
        id: 'receivingAccountId',
        displayName: l10n.receivingAccount,
        type: FilterFieldType.dropdown,
      ),
      FilterField(
        id: 'date',
        displayName: l10n.date,
        type: FilterFieldType.date,
      ),
    ],
    loadDropdownOptions: (fieldId) async {
      if (fieldId == 'assetId') {
        // Get assets that are actually used in transfers
        final transfers = await db.transfersDao.getAllTransfers();
        final usedAssetIds = transfers.map((t) => t.assetId).toSet();
        final assets = await db.assetsDao.getAllAssets();
        return assets
            .where((a) => usedAssetIds.contains(a.id))
            .map((a) => DropdownOption(id: a.id, displayName: a.name))
            .toList();
      } else if (fieldId == 'sendingAccountId' ||
          fieldId == 'receivingAccountId') {
        final accounts = await db.accountsDao.getAllAccounts();
        return accounts
            .where((a) => !a.isArchived)
            .map((a) => DropdownOption(id: a.id, displayName: a.name))
            .toList();
      }
      return [];
    },
  );
}
