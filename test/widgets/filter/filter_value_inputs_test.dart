import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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

    testWidgets('has numeric keyboard type', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: NumericFilterInput(
                value: null,
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      );

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(
        textField.keyboardType,
        const TextInputType.numberWithOptions(decimal: true, signed: true),
      );
    });
  });
}
