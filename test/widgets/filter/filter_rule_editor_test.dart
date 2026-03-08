import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xfin/l10n/app_localizations.dart';
import 'package:xfin/models/filter/filter_config.dart';
import 'package:xfin/models/filter/filter_rule.dart';
import 'package:xfin/widgets/filter/filter_rule_editor.dart';
import 'package:xfin/widgets/filter/filter_value_inputs.dart';

void main() {
  final l10n = lookupAppLocalizations(const Locale('en'));

  FilterConfig buildTestConfig() {
    return FilterConfig(
      title: 'Test Filters',
      fields: [
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
      ],
      loadDropdownOptions: (fieldId) async {
        if (fieldId == 'accountId') {
          return [
            const DropdownOption(id: 1, displayName: 'Account A'),
            const DropdownOption(id: 2, displayName: 'Account B'),
          ];
        }
        return [];
      },
    );
  }

  Widget buildTestWidget({
    FilterConfig? config,
    FilterRule? existingRule,
    ValueChanged<FilterRule>? onSave,
    VoidCallback? onCancel,
  }) {
    return MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SingleChildScrollView(
          child: FilterRuleEditor(
            config: config ?? buildTestConfig(),
            existingRule: existingRule,
            onSave: onSave ?? (_) {},
            onCancel: onCancel ?? () {},
          ),
        ),
      ),
    );
  }

  group('FilterRuleEditor', () {
    testWidgets('shows field selection chips', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text(l10n.selectField), findsOneWidget);
      expect(find.text('Value'), findsOneWidget);
      expect(find.text('Name'), findsOneWidget);
      expect(find.text('Account'), findsOneWidget);
      expect(find.text('Date'), findsOneWidget);
    });

    testWidgets('selecting field shows operator selection', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Select numeric field "Value"
      await tester.tap(find.text('Value'));
      await tester.pumpAndSettle();

      // Should show operator selection
      expect(find.text(l10n.selectOperator), findsOneWidget);
      expect(find.text(l10n.greaterThan), findsOneWidget);
      expect(find.text(l10n.lessThan), findsOneWidget);
    });

    testWidgets('auto-selects operator when field has only one',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Select dropdown field "Account" (has only 'inList' operator)
      await tester.tap(find.text('Account'));
      await tester.pumpAndSettle();

      // Should NOT show operator selection since only one operator
      expect(find.text(l10n.selectOperator), findsNothing);
      // Should directly show value input
      expect(find.text(l10n.enterValue), findsOneWidget);
    });

    testWidgets('selecting operator shows value input', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Select "Value" field
      await tester.tap(find.text('Value'));
      await tester.pumpAndSettle();

      // Select "greater than" operator
      await tester.tap(find.text(l10n.greaterThan));
      await tester.pumpAndSettle();

      // Should show value entry
      expect(find.text(l10n.enterValue), findsOneWidget);
    });

    testWidgets('save button disabled until all selections made',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Save button should be disabled (no selections)
      final saveButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, l10n.save),
      );
      expect(saveButton.onPressed, isNull);
    });

    testWidgets('save button calls onSave with correct FilterRule',
        (tester) async {
      FilterRule? savedRule;

      await tester.pumpWidget(buildTestWidget(
        onSave: (rule) => savedRule = rule,
      ));
      await tester.pumpAndSettle();

      // Select "Name" field (text type)
      await tester.tap(find.text('Name'));
      await tester.pumpAndSettle();

      // Select "contains" operator
      await tester.tap(find.text(l10n.contains));
      await tester.pumpAndSettle();

      // Enter value
      await tester.enterText(find.byType(TextField), 'test');
      await tester.pumpAndSettle();

      // Tap save
      await tester.tap(find.widgetWithText(FilledButton, l10n.save));
      await tester.pumpAndSettle();

      expect(savedRule, isNotNull);
      expect(savedRule!.fieldId, 'name');
      expect(savedRule!.operator, FilterOperator.contains);
      expect(savedRule!.value, 'test');
    });

    testWidgets('cancel button calls onCancel', (tester) async {
      bool cancelled = false;

      await tester.pumpWidget(buildTestWidget(
        onCancel: () => cancelled = true,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text(l10n.cancel));
      await tester.pumpAndSettle();

      expect(cancelled, isTrue);
    });

    testWidgets('pre-fills from existingRule', (tester) async {
      const existingRule = FilterRule(
        fieldId: 'name',
        operator: FilterOperator.contains,
        value: 'hello',
      );

      await tester.pumpWidget(buildTestWidget(existingRule: existingRule));
      await tester.pumpAndSettle();

      // Field should be pre-selected
      final nameChip = tester.widget<ChoiceChip>(
        find.ancestor(
          of: find.text('Name'),
          matching: find.byType(ChoiceChip),
        ),
      );
      expect(nameChip.selected, isTrue);

      // Should show value input (operator was auto-set or pre-filled)
      expect(find.text(l10n.enterValue), findsOneWidget);
    });

    testWidgets('changing field resets operator and value', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Select "Value" field and operator
      await tester.tap(find.text('Value'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.greaterThan));
      await tester.pumpAndSettle();

      // Value input should be visible
      expect(find.text(l10n.enterValue), findsOneWidget);

      // Now change to "Name" field
      await tester.tap(find.text('Name'));
      await tester.pumpAndSettle();

      // Operator should be reset — show operator selection for text field
      expect(find.text(l10n.selectOperator), findsOneWidget);
      // Value input should be hidden (no operator selected)
      expect(find.text(l10n.enterValue), findsNothing);
    });

    testWidgets('numeric field shows NumericFilterInput', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Value'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.greaterThan));
      await tester.pumpAndSettle();

      expect(find.byType(NumericFilterInput), findsOneWidget);
    });

    testWidgets('text field shows TextFilterInput', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Name'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.contains));
      await tester.pumpAndSettle();

      expect(find.byType(TextFilterInput), findsOneWidget);
    });

    testWidgets('dropdown field shows DropdownFilterInput', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Account'));
      await tester.pumpAndSettle();

      // Account has only one operator (inList), auto-selected
      expect(find.byType(DropdownFilterInput), findsOneWidget);
    });

    testWidgets('between operator shows NumericRangeInput', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Value'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.between));
      await tester.pumpAndSettle();

      expect(find.byType(NumericRangeInput), findsOneWidget);
    });

    testWidgets('date field shows DateFilterInput', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Date'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.after));
      await tester.pumpAndSettle();

      expect(find.byType(DateFilterInput), findsOneWidget);
    });

    testWidgets('dateBetween operator shows DateRangeInput', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Date'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.between));
      await tester.pumpAndSettle();

      expect(find.byType(DateRangeInput), findsOneWidget);
    });
  });
}
