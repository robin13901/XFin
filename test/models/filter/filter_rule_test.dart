import 'package:flutter_test/flutter_test.dart';
import 'package:xfin/models/filter/filter_rule.dart';

void main() {
  group('FilterOperator', () {
    test('has correct number of operators', () {
      expect(FilterOperator.values.length, 13);
    });
  });

  group('FilterFieldType', () {
    test('has correct number of types', () {
      expect(FilterFieldType.values.length, 4);
    });
  });

  group('FilterField', () {
    test('creates field correctly', () {
      const field = FilterField(
        id: 'value',
        displayName: 'Value',
        type: FilterFieldType.numeric,
      );

      expect(field.id, 'value');
      expect(field.displayName, 'Value');
      expect(field.type, FilterFieldType.numeric);
    });

    test('numeric field has correct operators', () {
      const field = FilterField(
        id: 'value',
        displayName: 'Value',
        type: FilterFieldType.numeric,
      );

      final operators = field.availableOperators;
      expect(operators, contains(FilterOperator.greaterThan));
      expect(operators, contains(FilterOperator.lessThan));
      expect(operators, contains(FilterOperator.greaterOrEqual));
      expect(operators, contains(FilterOperator.lessOrEqual));
      expect(operators, contains(FilterOperator.equals));
      expect(operators, contains(FilterOperator.between));
      expect(operators.length, 6);
    });

    test('text field has correct operators', () {
      const field = FilterField(
        id: 'category',
        displayName: 'Category',
        type: FilterFieldType.text,
      );

      final operators = field.availableOperators;
      expect(operators, contains(FilterOperator.contains));
      expect(operators, contains(FilterOperator.startsWith));
      expect(operators, contains(FilterOperator.textEquals));
      expect(operators.length, 3);
    });

    test('dropdown field has correct operators', () {
      const field = FilterField(
        id: 'accountId',
        displayName: 'Account',
        type: FilterFieldType.dropdown,
      );

      final operators = field.availableOperators;
      expect(operators, contains(FilterOperator.inList));
      expect(operators.length, 1);
    });

    test('date field has correct operators', () {
      const field = FilterField(
        id: 'date',
        displayName: 'Date',
        type: FilterFieldType.date,
      );

      final operators = field.availableOperators;
      expect(operators, contains(FilterOperator.before));
      expect(operators, contains(FilterOperator.after));
      expect(operators, contains(FilterOperator.dateBetween));
      expect(operators.length, 3);
    });
  });

  group('FilterRule', () {
    test('creates rule correctly', () {
      const rule = FilterRule(
        fieldId: 'value',
        operator: FilterOperator.greaterThan,
        value: 100.0,
      );

      expect(rule.fieldId, 'value');
      expect(rule.operator, FilterOperator.greaterThan);
      expect(rule.value, 100.0);
    });

    test('isRangeOperator returns true for between', () {
      const rule = FilterRule(
        fieldId: 'value',
        operator: FilterOperator.between,
        value: [0.0, 100.0],
      );

      expect(rule.isRangeOperator, isTrue);
    });

    test('isRangeOperator returns true for dateBetween', () {
      const rule = FilterRule(
        fieldId: 'date',
        operator: FilterOperator.dateBetween,
        value: [20240101, 20241231],
      );

      expect(rule.isRangeOperator, isTrue);
    });

    test('isRangeOperator returns false for non-range operators', () {
      const rule = FilterRule(
        fieldId: 'value',
        operator: FilterOperator.greaterThan,
        value: 100.0,
      );

      expect(rule.isRangeOperator, isFalse);
    });

    test('copyWith creates new rule with changed values', () {
      const original = FilterRule(
        fieldId: 'value',
        operator: FilterOperator.greaterThan,
        value: 100.0,
      );

      final copied = original.copyWith(value: 200.0);

      expect(copied.fieldId, 'value');
      expect(copied.operator, FilterOperator.greaterThan);
      expect(copied.value, 200.0);
      expect(original.value, 100.0); // Original unchanged
    });

    test('equality works for simple values', () {
      const rule1 = FilterRule(
        fieldId: 'value',
        operator: FilterOperator.greaterThan,
        value: 100.0,
      );
      const rule2 = FilterRule(
        fieldId: 'value',
        operator: FilterOperator.greaterThan,
        value: 100.0,
      );

      expect(rule1, equals(rule2));
    });

    test('equality works for list values', () {
      const rule1 = FilterRule(
        fieldId: 'value',
        operator: FilterOperator.between,
        value: [0.0, 100.0],
      );
      const rule2 = FilterRule(
        fieldId: 'value',
        operator: FilterOperator.between,
        value: [0.0, 100.0],
      );

      expect(rule1, equals(rule2));
    });

    test('inequality for different values', () {
      const rule1 = FilterRule(
        fieldId: 'value',
        operator: FilterOperator.greaterThan,
        value: 100.0,
      );
      const rule2 = FilterRule(
        fieldId: 'value',
        operator: FilterOperator.greaterThan,
        value: 200.0,
      );

      expect(rule1, isNot(equals(rule2)));
    });

    test('copyWith preserves unchanged fields', () {
      const original = FilterRule(
        fieldId: 'v',
        operator: FilterOperator.greaterThan,
        value: 100.0,
      );
      final copied = original.copyWith(fieldId: 'x');
      expect(copied.fieldId, 'x');
      expect(copied.operator, FilterOperator.greaterThan);
      expect(copied.value, 100.0);
    });

    test('copyWith changes operator only', () {
      const original = FilterRule(
        fieldId: 'value',
        operator: FilterOperator.greaterThan,
        value: 50.0,
      );
      final copied = original.copyWith(operator: FilterOperator.lessThan);
      expect(copied.fieldId, 'value');
      expect(copied.operator, FilterOperator.lessThan);
      expect(copied.value, 50.0);
    });

    test('inequality for different fieldId', () {
      const rule1 = FilterRule(
        fieldId: 'value',
        operator: FilterOperator.greaterThan,
        value: 100.0,
      );
      const rule2 = FilterRule(
        fieldId: 'shares',
        operator: FilterOperator.greaterThan,
        value: 100.0,
      );
      expect(rule1, isNot(equals(rule2)));
    });

    test('inequality for different operator', () {
      const rule1 = FilterRule(
        fieldId: 'value',
        operator: FilterOperator.greaterThan,
        value: 100.0,
      );
      const rule2 = FilterRule(
        fieldId: 'value',
        operator: FilterOperator.lessThan,
        value: 100.0,
      );
      expect(rule1, isNot(equals(rule2)));
    });

    test('equality for empty list values', () {
      const rule1 = FilterRule(
        fieldId: 'ids',
        operator: FilterOperator.inList,
        value: <int>[],
      );
      const rule2 = FilterRule(
        fieldId: 'ids',
        operator: FilterOperator.inList,
        value: <int>[],
      );
      expect(rule1, equals(rule2));
    });

    test('inequality for lists of different length', () {
      const rule1 = FilterRule(
        fieldId: 'ids',
        operator: FilterOperator.inList,
        value: [1, 2],
      );
      const rule2 = FilterRule(
        fieldId: 'ids',
        operator: FilterOperator.inList,
        value: [1, 2, 3],
      );
      expect(rule1, isNot(equals(rule2)));
    });

    test('inequality when one value is List and other is scalar', () {
      const rule1 = FilterRule(
        fieldId: 'value',
        operator: FilterOperator.greaterThan,
        value: [100.0],
      );
      const rule2 = FilterRule(
        fieldId: 'value',
        operator: FilterOperator.greaterThan,
        value: 100.0,
      );
      expect(rule1, isNot(equals(rule2)));
    });

    test('inequality when values are Lists with different elements', () {
      const rule1 = FilterRule(
        fieldId: 'ids',
        operator: FilterOperator.inList,
        value: [1, 2],
      );
      const rule2 = FilterRule(
        fieldId: 'ids',
        operator: FilterOperator.inList,
        value: [1, 3],
      );
      expect(rule1, isNot(equals(rule2)));
    });

    test('hashCode is consistent for equal rules', () {
      const rule1 = FilterRule(
        fieldId: 'value',
        operator: FilterOperator.greaterThan,
        value: 100.0,
      );
      const rule2 = FilterRule(
        fieldId: 'value',
        operator: FilterOperator.greaterThan,
        value: 100.0,
      );
      expect(rule1.hashCode, equals(rule2.hashCode));
    });

    test('hashCode differs for unequal rules', () {
      const rule1 = FilterRule(
        fieldId: 'value',
        operator: FilterOperator.greaterThan,
        value: 100.0,
      );
      const rule2 = FilterRule(
        fieldId: 'shares',
        operator: FilterOperator.lessThan,
        value: 200.0,
      );
      // hashCodes *may* collide, but for these distinct inputs they should not
      expect(rule1.hashCode, isNot(equals(rule2.hashCode)));
    });

    test('is not equal to non-FilterRule object', () {
      const rule = FilterRule(
        fieldId: 'value',
        operator: FilterOperator.greaterThan,
        value: 100.0,
      );
      // ignore: unrelated_type_equality_checks
      expect(rule == 'not a rule', isFalse);
    });

    test('identical rules are equal', () {
      const rule = FilterRule(
        fieldId: 'value',
        operator: FilterOperator.greaterThan,
        value: 100.0,
      );
      expect(rule == rule, isTrue);
    });
  });
}
