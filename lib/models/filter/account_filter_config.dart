import '../../database/tables.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/format.dart';
import 'filter_config.dart';
import 'filter_rule.dart';

/// Builds filter configuration for Accounts entity
FilterConfig buildAccountFilterConfig(AppLocalizations l10n) {
  return FilterConfig(
    title: l10n.filterAccounts,
    fields: [
      FilterField(
        id: 'name',
        displayName: l10n.accountName,
        type: FilterFieldType.text,
      ),
      FilterField(
        id: 'balance',
        displayName: l10n.amount,
        type: FilterFieldType.numeric,
      ),
      FilterField(
        id: 'type',
        displayName: l10n.accountType,
        type: FilterFieldType.dropdown,
      ),
    ],
    loadDropdownOptions: (fieldId) async {
      if (fieldId == 'type') {
        return AccountTypes.values
            .map((t) => DropdownOption(
                  id: t.index,
                  displayName: getAccountTypeName(l10n, t),
                ))
            .toList();
      }
      return [];
    },
  );
}
