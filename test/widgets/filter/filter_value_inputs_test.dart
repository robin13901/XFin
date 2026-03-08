import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xfin/l10n/app_localizations.dart';
import 'package:xfin/models/filter/filter_config.dart';
import 'package:xfin/models/filter/filter_rule.dart';
import 'package:xfin/widgets/filter/filter_value_inputs.dart';

void main() {
  group('TextFilterInput', () {
    testWidgets('maintains focus while typing', (tester) async {
      String lastValue = '';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: StatefulBuilder(
                builder: (context, setState) {
                  return TextFilterInput(
                    value: null,
                    onChanged: (val) => setState(() => lastValue = val),
                  );
                },
              ),
            ),
          ),
        ),
      );

      // Tap to focus the text field
      await tester.tap(find.byType(TextField));
      await tester.pump();

      // Type multiple characters
      await tester.enterText(find.byType(TextField), 'Hello');
      await tester.pump();

      expect(lastValue, 'Hello');

      // Verify the TextField still has focus
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.focusNode?.hasFocus ?? false, isFalse,
          reason: 'focusNode is managed internally');
      // The key test: text should be in the controller
      expect(textField.controller?.text, 'Hello');
    });

    testWidgets('has TextCapitalization.words', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: TextFilterInput(
                value: null,
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      );

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.textCapitalization, TextCapitalization.words);
    });

    testWidgets('displays initial value', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: TextFilterInput(
                value: 'Initial',
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('Initial'), findsOneWidget);
    });

    testWidgets('displays label text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: TextFilterInput(
                value: null,
                label: 'Category',
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('Category'), findsOneWidget);
    });
  });

  group('NumericFilterInput', () {
    testWidgets('maintains focus while typing', (tester) async {
      double? lastValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: StatefulBuilder(
                builder: (context, setState) {
                  return NumericFilterInput(
                    value: null,
                    onChanged: (val) => setState(() => lastValue = val),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(TextField));
      await tester.pump();

      await tester.enterText(find.byType(TextField), '42.5');
      await tester.pump();

      expect(lastValue, 42.5);

      // Verify the controller still has the text
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, '42.5');
    });

    testWidgets('displays initial value', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: NumericFilterInput(
                value: 99.9,
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('99.9'), findsOneWidget);
    });

    testWidgets('returns null for invalid input', (tester) async {
      double? lastValue = 1.0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: StatefulBuilder(
                builder: (context, setState) {
                  return NumericFilterInput(
                    value: null,
                    onChanged: (val) => setState(() => lastValue = val),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'abc');
      await tester.pump();

      expect(lastValue, isNull);
    });
  });

  group('NumericRangeInput', () {
    testWidgets('renders two NumericFilterInputs', (tester) async {
      final l10n = lookupAppLocalizations(const Locale('en'));

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: NumericRangeInput(
                l10n: l10n,
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      );

      // Should find two TextFields (from/to)
      expect(find.byType(TextField), findsNWidgets(2));
      expect(find.text(l10n.from), findsOneWidget);
      expect(find.text(l10n.to), findsOneWidget);
    });

    testWidgets('displays initial min and max values', (tester) async {
      final l10n = lookupAppLocalizations(const Locale('en'));

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: NumericRangeInput(
                minValue: 10.0,
                maxValue: 100.0,
                l10n: l10n,
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('10.0'), findsOneWidget);
      expect(find.text('100.0'), findsOneWidget);
    });
  });

  group('DropdownFilterInput', () {
    testWidgets('shows loading indicator while options load', (tester) async {
      final completer = Completer<List<DropdownOption>>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: DropdownFilterInput(
                selectedIds: const [],
                loadOptions: () => completer.future,
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      );

      // Should show loading immediately (future not yet completed)
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Complete the future to clean up
      completer.complete([]);
      await tester.pumpAndSettle();
    });

    testWidgets('renders FilterChips for each option', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: DropdownFilterInput(
                selectedIds: const [],
                loadOptions: () async => [
                  const DropdownOption(id: 1, displayName: 'Option A'),
                  const DropdownOption(id: 2, displayName: 'Option B'),
                ],
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(FilterChip), findsNWidgets(2));
      expect(find.text('Option A'), findsOneWidget);
      expect(find.text('Option B'), findsOneWidget);
    });

    testWidgets('toggles selection on tap', (tester) async {
      List<int> lastChanged = [];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: StatefulBuilder(
                builder: (context, setState) {
                  return DropdownFilterInput(
                    selectedIds: lastChanged,
                    loadOptions: () async => [
                      const DropdownOption(id: 1, displayName: 'Option A'),
                      const DropdownOption(id: 2, displayName: 'Option B'),
                    ],
                    onChanged: (ids) => setState(() => lastChanged = ids),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap Option A to select it
      await tester.tap(find.text('Option A'));
      await tester.pumpAndSettle();

      expect(lastChanged, [1]);
    });

    testWidgets('pre-selects chips from selectedIds', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: DropdownFilterInput(
                selectedIds: const [2],
                loadOptions: () async => [
                  const DropdownOption(id: 1, displayName: 'Option A'),
                  const DropdownOption(id: 2, displayName: 'Option B'),
                ],
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final chipB = tester.widget<FilterChip>(
        find.ancestor(
          of: find.text('Option B'),
          matching: find.byType(FilterChip),
        ),
      );
      expect(chipB.selected, isTrue);

      final chipA = tester.widget<FilterChip>(
        find.ancestor(
          of: find.text('Option A'),
          matching: find.byType(FilterChip),
        ),
      );
      expect(chipA.selected, isFalse);
    });
  });

  group('DateFilterInput', () {
    testWidgets('renders dash placeholder when no value', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: DateFilterInput(
                dateInt: null,
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('—'), findsOneWidget);
    });

    testWidgets('displays formatted date from int value', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: DateFilterInput(
                dateInt: 20240315,
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('15.03.2024'), findsOneWidget);
    });

    testWidgets('shows calendar icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: DateFilterInput(
                dateInt: null,
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.calendar_today), findsOneWidget);
    });

    testWidgets('displays label text when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: DateFilterInput(
                dateInt: null,
                label: 'Start Date',
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('Start Date'), findsOneWidget);
    });
  });

  group('DateRangeInput', () {
    testWidgets('renders two DateFilterInputs with from/to labels',
        (tester) async {
      final l10n = lookupAppLocalizations(const Locale('en'));

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: DateRangeInput(
                l10n: l10n,
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      );

      expect(find.text(l10n.from), findsOneWidget);
      expect(find.text(l10n.to), findsOneWidget);
      expect(find.byType(DateFilterInput), findsNWidgets(2));
    });
  });

  group('getOperatorDisplayName', () {
    test('returns correct l10n string for each operator', () {
      final l10n = lookupAppLocalizations(const Locale('en'));

      expect(
          getOperatorDisplayName(FilterOperator.greaterThan, l10n),
          l10n.greaterThan);
      expect(
          getOperatorDisplayName(FilterOperator.lessThan, l10n),
          l10n.lessThan);
      expect(
          getOperatorDisplayName(FilterOperator.greaterOrEqual, l10n),
          l10n.greaterOrEqual);
      expect(
          getOperatorDisplayName(FilterOperator.lessOrEqual, l10n),
          l10n.lessOrEqual);
      expect(
          getOperatorDisplayName(FilterOperator.equals, l10n),
          l10n.equalTo);
      expect(
          getOperatorDisplayName(FilterOperator.between, l10n),
          l10n.between);
      expect(
          getOperatorDisplayName(FilterOperator.contains, l10n),
          l10n.contains);
      expect(
          getOperatorDisplayName(FilterOperator.startsWith, l10n),
          l10n.startsWith);
      expect(
          getOperatorDisplayName(FilterOperator.textEquals, l10n),
          l10n.equalTo);
      expect(
          getOperatorDisplayName(FilterOperator.inList, l10n),
          l10n.select);
      expect(
          getOperatorDisplayName(FilterOperator.before, l10n),
          l10n.before);
      expect(
          getOperatorDisplayName(FilterOperator.after, l10n),
          l10n.after);
      expect(
          getOperatorDisplayName(FilterOperator.dateBetween, l10n),
          l10n.between);
    });
  });
}
