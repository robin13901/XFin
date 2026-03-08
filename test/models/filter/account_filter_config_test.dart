import 'package:flutter_test/flutter_test.dart';
import 'package:xfin/database/tables.dart';
import 'package:xfin/models/filter/account_filter_config.dart';
import 'package:xfin/models/filter/filter_rule.dart';

import 'filter_config_test_helper.dart';

void main() {
  final l10n = getTestLocalizations();

  group('buildAccountFilterConfig', () {
    test('returns FilterConfig with correct title', () {
      final config = buildAccountFilterConfig(l10n);
      expect(config.title, l10n.filterAccounts);
    });

    test('has 3 fields', () {
      final config = buildAccountFilterConfig(l10n);
      expect(config.fields.length, 3);
    });

    test('fields have correct ids', () {
      final config = buildAccountFilterConfig(l10n);
      final ids = config.fields.map((f) => f.id).toList();
      expect(ids, ['name', 'balance', 'type']);
    });

    test('field types are correct (1 text, 1 numeric, 1 dropdown)', () {
      final config = buildAccountFilterConfig(l10n);
      final types = config.fields.map((f) => f.type).toList();
      expect(types, [
        FilterFieldType.text,
        FilterFieldType.numeric,
        FilterFieldType.dropdown,
      ]);
    });

    test('loadDropdownOptions for type returns all AccountTypes', () async {
      final config = buildAccountFilterConfig(l10n);
      final options = await config.loadDropdownOptions!('type');
      expect(options.length, AccountTypes.values.length);
      for (var i = 0; i < AccountTypes.values.length; i++) {
        expect(options[i].id, i);
      }
    });

    test('loadDropdownOptions for type returns localized names', () async {
      final config = buildAccountFilterConfig(l10n);
      final options = await config.loadDropdownOptions!('type');
      // Verify we get non-empty display names
      for (final option in options) {
        expect(option.displayName, isNotEmpty);
      }
    });

    test('loadDropdownOptions for unknown field returns empty list', () async {
      final config = buildAccountFilterConfig(l10n);
      final options = await config.loadDropdownOptions!('unknown');
      expect(options, isEmpty);
    });
  });
}
