import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xfin/widgets/summary_row.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SummaryRow', () {
    testWidgets('renders label and value with correct styling', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SummaryRow(
              label: 'Test Label',
              value: '\$1,234.56',
              valueColor: Colors.green,
            ),
          ),
        ),
      );

      expect(find.text('Test Label'), findsOneWidget);
      expect(find.text('\$1,234.56'), findsOneWidget);

      final labelText = tester.widget<Text>(find.text('Test Label'));
      expect(labelText.style?.fontSize, 15);
      expect(labelText.style?.fontWeight, FontWeight.w600);

      final valueText = tester.widget<Text>(find.text('\$1,234.56'));
      expect(valueText.style?.color, Colors.green);
      expect(valueText.style?.fontWeight, FontWeight.bold);
    });

    testWidgets('renders with custom label style', (tester) async {
      const customLabelStyle = TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w300,
        color: Colors.blue,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SummaryRow(
              label: 'Custom Label',
              value: '\$100',
              valueColor: Colors.red,
              labelStyle: customLabelStyle,
            ),
          ),
        ),
      );

      final labelText = tester.widget<Text>(find.text('Custom Label'));
      expect(labelText.style?.fontSize, 20);
      expect(labelText.style?.fontWeight, FontWeight.w300);
      expect(labelText.style?.color, Colors.blue);
    });

    testWidgets('renders with custom value style', (tester) async {
      const customValueStyle = TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w900,
        color: Colors.purple,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SummaryRow(
              label: 'Label',
              value: '\$500',
              valueColor: Colors.green,
              valueStyle: customValueStyle,
            ),
          ),
        ),
      );

      final valueText = tester.widget<Text>(find.text('\$500'));
      expect(valueText.style?.fontSize, 24);
      expect(valueText.style?.fontWeight, FontWeight.w900);
      expect(valueText.style?.color, Colors.purple);
    });

    testWidgets('uses spaceBetween layout for label and value', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SummaryRow(
              label: 'Label',
              value: 'Value',
              valueColor: Colors.black,
            ),
          ),
        ),
      );

      final row = tester.widget<Row>(find.byType(Row));
      expect(row.mainAxisAlignment, MainAxisAlignment.spaceBetween);
    });

    testWidgets('has correct vertical padding', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SummaryRow(
              label: 'Test',
              value: 'Test',
              valueColor: Colors.black,
            ),
          ),
        ),
      );

      final padding = tester.widget<Padding>(find.byType(Padding));
      expect(
        padding.padding,
        const EdgeInsets.symmetric(vertical: 4),
      );
    });

    testWidgets('renders with negative value color', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SummaryRow(
              label: 'Loss',
              value: '-\$50.00',
              valueColor: Colors.red,
            ),
          ),
        ),
      );

      expect(find.text('Loss'), findsOneWidget);
      expect(find.text('-\$50.00'), findsOneWidget);

      final valueText = tester.widget<Text>(find.text('-\$50.00'));
      expect(valueText.style?.color, Colors.red);
    });

    testWidgets('renders with empty label', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SummaryRow(
              label: '',
              value: '\$100',
              valueColor: Colors.green,
            ),
          ),
        ),
      );

      expect(find.text(''), findsWidgets);
      expect(find.text('\$100'), findsOneWidget);
    });

    testWidgets('renders with empty value', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SummaryRow(
              label: 'Label',
              value: '',
              valueColor: Colors.green,
            ),
          ),
        ),
      );

      expect(find.text('Label'), findsOneWidget);
      expect(find.text(''), findsWidgets);
    });

    testWidgets('renders with very long label text', (tester) async {
      const longLabel = 'This is a very long label that should still render correctly';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SummaryRow(
              label: longLabel,
              value: '\$1,000',
              valueColor: Colors.green,
            ),
          ),
        ),
      );

      expect(find.text(longLabel), findsOneWidget);
      expect(find.text('\$1,000'), findsOneWidget);
    });

    testWidgets('renders multiple instances in a column', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                SummaryRow(
                  label: 'Income',
                  value: '\$5,000',
                  valueColor: Colors.green,
                ),
                SummaryRow(
                  label: 'Expenses',
                  value: '\$3,000',
                  valueColor: Colors.red,
                ),
                SummaryRow(
                  label: 'Profit',
                  value: '\$2,000',
                  valueColor: Colors.blue,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(SummaryRow), findsNWidgets(3));
      expect(find.text('Income'), findsOneWidget);
      expect(find.text('Expenses'), findsOneWidget);
      expect(find.text('Profit'), findsOneWidget);
    });
  });
}
