import 'package:flutter_test/flutter_test.dart';
import 'package:xfin/database/tables.dart';
import 'package:xfin/models/filter/asset_filter_config.dart';
import 'package:xfin/models/filter/filter_rule.dart';

import 'filter_config_test_helper.dart';

void main() {
  final l10n = getTestLocalizations();

  group('buildAssetFilterConfig', () {
    test('returns FilterConfig with correct title', () {
      final config = buildAssetFilterConfig(l10n);
      expect(config.title, l10n.filterAssets);
    });

    test('has 5 fields', () {
      final config = buildAssetFilterConfig(l10n);
      expect(config.fields.length, 5);
    });

    test('fields have correct ids', () {
      final config = buildAssetFilterConfig(l10n);
      final ids = config.fields.map((f) => f.id).toList();
      expect(ids, ['name', 'tickerSymbol', 'value', 'shares', 'type']);
    });

    test('field types are correct (2 text, 2 numeric, 1 dropdown)', () {
      final config = buildAssetFilterConfig(l10n);
      final types = config.fields.map((f) => f.type).toList();
      expect(types, [
        FilterFieldType.text,
        FilterFieldType.text,
        FilterFieldType.numeric,
        FilterFieldType.numeric,
        FilterFieldType.dropdown,
      ]);
    });

    test('loadDropdownOptions for type returns all AssetTypes', () async {
      final config = buildAssetFilterConfig(l10n);
      final options = await config.loadDropdownOptions!('type');
      expect(options.length, AssetTypes.values.length);
      for (var i = 0; i < AssetTypes.values.length; i++) {
        expect(options[i].id, i);
      }
    });

    test('loadDropdownOptions for type returns localized names', () async {
      final config = buildAssetFilterConfig(l10n);
      final options = await config.loadDropdownOptions!('type');
      for (final option in options) {
        expect(option.displayName, isNotEmpty);
      }
    });

    test('loadDropdownOptions for unknown field returns empty list', () async {
      final config = buildAssetFilterConfig(l10n);
      final options = await config.loadDropdownOptions!('unknown');
      expect(options, isEmpty);
    });
  });
}
