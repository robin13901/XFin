import 'package:flutter_test/flutter_test.dart';
import 'package:xfin/models/filter/filter_config.dart';
import 'package:xfin/models/filter/filter_rule.dart';

void main() {
  group('DropdownOption', () {
    test('creates correctly', () {
      const option = DropdownOption(id: 1, displayName: 'Test');
      expect(option.id, 1);
      expect(option.displayName, 'Test');
    });
  });

  group('FilterConfig', () {
    final fields = [
      const FilterField(
        id: 'value',
        displayName: 'Value',
        type: FilterFieldType.numeric,
      ),
      const FilterField(
        id: 'name',
        displayName: 'Name',
        type: FilterFieldType.text,
      ),
      const FilterField(
        id: 'accountId',
        displayName: 'Account',
        type: FilterFieldType.dropdown,
      ),
      const FilterField(
        id: 'date',
        displayName: 'Date',
        type: FilterFieldType.date,
      ),
    ];

    test('creates with title, fields, and optional loadDropdownOptions', () {
      final config = FilterConfig(
        title: 'Test Filters',
        fields: fields,
      );
      expect(config.title, 'Test Filters');
      expect(config.fields.length, 4);
      expect(config.loadDropdownOptions, isNull);
    });

    test('creates with loadDropdownOptions callback', () {
      final config = FilterConfig(
        title: 'Test',
        fields: fields,
        loadDropdownOptions: (fieldId) async => [],
      );
      expect(config.loadDropdownOptions, isNotNull);
    });

    test('getField returns matching field by id', () {
      final config = FilterConfig(title: 'Test', fields: fields);
      final field = config.getField('name');
      expect(field, isNotNull);
      expect(field!.id, 'name');
      expect(field.displayName, 'Name');
      expect(field.type, FilterFieldType.text);
    });

    test('getField returns null for unknown id', () {
      final config = FilterConfig(title: 'Test', fields: fields);
      expect(config.getField('unknown'), isNull);
    });

    test('getFieldsByType returns only matching fields', () {
      final config = FilterConfig(title: 'Test', fields: fields);
      final numericFields = config.getFieldsByType(FilterFieldType.numeric);
      expect(numericFields.length, 1);
      expect(numericFields.first.id, 'value');
    });

    test('getFieldsByType returns empty for no matches', () {
      const config = FilterConfig(
        title: 'Test',
        fields: [
          FilterField(
            id: 'name',
            displayName: 'Name',
            type: FilterFieldType.text,
          ),
        ],
      );
      final numericFields = config.getFieldsByType(FilterFieldType.numeric);
      expect(numericFields, isEmpty);
    });
  });
}
