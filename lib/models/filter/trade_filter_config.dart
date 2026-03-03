import '../../database/app_database.dart';
import '../../database/tables.dart';
import '../../l10n/app_localizations.dart';
import 'filter_config.dart';
import 'filter_rule.dart';

String _getTradeTypeName(AppLocalizations l10n, TradeTypes type) {
  return switch (type) {
    TradeTypes.buy => l10n.calendarTradeBuy,
    TradeTypes.sell => l10n.calendarTradeSell,
  };
}

/// Builds filter configuration for Trades entity
FilterConfig buildTradeFilterConfig(AppLocalizations l10n, AppDatabase db) {
  return FilterConfig(
    title: l10n.filterTrades,
    fields: [
      FilterField(
        id: 'type',
        displayName: l10n.type,
        type: FilterFieldType.dropdown,
      ),
      FilterField(
        id: 'shares',
        displayName: l10n.shares,
        type: FilterFieldType.numeric,
      ),
      FilterField(
        id: 'costBasis',
        displayName: l10n.pricePerShare,
        type: FilterFieldType.numeric,
      ),
      FilterField(
        id: 'fee',
        displayName: l10n.fee,
        type: FilterFieldType.numeric,
      ),
      FilterField(
        id: 'tax',
        displayName: l10n.tax,
        type: FilterFieldType.numeric,
      ),
      FilterField(
        id: 'profitAndLoss',
        displayName: l10n.profitAndLoss,
        type: FilterFieldType.numeric,
      ),
      FilterField(
        id: 'assetId',
        displayName: l10n.asset,
        type: FilterFieldType.dropdown,
      ),
      FilterField(
        id: 'sourceAccountId',
        displayName: l10n.clearingAccount,
        type: FilterFieldType.dropdown,
      ),
      FilterField(
        id: 'targetAccountId',
        displayName: l10n.investmentAccount,
        type: FilterFieldType.dropdown,
      ),
      FilterField(
        id: 'datetime',
        displayName: l10n.date,
        type: FilterFieldType.date,
      ),
    ],
    loadDropdownOptions: (fieldId) async {
      if (fieldId == 'type') {
        return TradeTypes.values
            .map((t) => DropdownOption(
                  id: t.index,
                  displayName: _getTradeTypeName(l10n, t),
                ))
            .toList();
      } else if (fieldId == 'assetId') {
        // Get assets that are actually used in trades
        final trades = await db.tradesDao.getAllTrades();
        final usedAssetIds = trades.map((t) => t.assetId).toSet();
        final assets = await db.assetsDao.getAllAssets();
        return assets
            .where((a) => usedAssetIds.contains(a.id))
            .map((a) => DropdownOption(id: a.id, displayName: a.name))
            .toList();
      } else if (fieldId == 'sourceAccountId' || fieldId == 'targetAccountId') {
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
