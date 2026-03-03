import '../../database/tables.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/format.dart';
import 'filter_config.dart';
import 'filter_rule.dart';

/// Builds filter configuration for Assets entity
FilterConfig buildAssetFilterConfig(AppLocalizations l10n) {
  return FilterConfig(
    title: l10n.filterAssets,
    fields: [
      FilterField(
        id: 'name',
        displayName: l10n.assetName,
        type: FilterFieldType.text,
      ),
      FilterField(
        id: 'tickerSymbol',
        displayName: l10n.tickerSymbol,
        type: FilterFieldType.text,
      ),
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
        id: 'type',
        displayName: l10n.type,
        type: FilterFieldType.dropdown,
      ),
    ],
    loadDropdownOptions: (fieldId) async {
      if (fieldId == 'type') {
        return AssetTypes.values
            .map((t) => DropdownOption(
                  id: t.index,
                  displayName: getAssetTypeName(l10n, t),
                ))
            .toList();
      }
      return [];
    },
  );
}
