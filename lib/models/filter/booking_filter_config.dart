import '../../database/app_database.dart';
import '../../l10n/app_localizations.dart';
import 'filter_config.dart';
import 'filter_rule.dart';

/// Builds filter configuration for Bookings entity
FilterConfig buildBookingFilterConfig(AppLocalizations l10n, AppDatabase db) {
  return FilterConfig(
    title: l10n.filterBookings,
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
        id: 'category',
        displayName: l10n.category,
        type: FilterFieldType.text,
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
        id: 'accountId',
        displayName: l10n.account,
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
        // Get assets that are actually used in bookings
        final bookings = await db.bookingsDao.getAllBookings();
        final usedAssetIds = bookings.map((b) => b.assetId).toSet();
        final assets = await db.assetsDao.getAllAssets();
        return assets
            .where((a) => usedAssetIds.contains(a.id))
            .map((a) => DropdownOption(id: a.id, displayName: a.name))
            .toList();
      } else if (fieldId == 'accountId') {
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
