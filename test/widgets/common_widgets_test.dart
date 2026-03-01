import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xfin/widgets/common_widgets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SectionTitle', () {
    testWidgets('renders title with default style', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            textTheme: const TextTheme(
              headlineSmall: TextStyle(fontSize: 18),
            ),
          ),
          home: const Scaffold(
            body: SectionTitle(title: 'Test Section'),
          ),
        ),
      );

      expect(find.text('Test Section'), findsOneWidget);

      final text = tester.widget<Text>(find.text('Test Section'));
      expect(text.style?.fontWeight, FontWeight.w700);
    });

    testWidgets('renders title with custom style', (tester) async {
      const customStyle = TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w500,
        color: Colors.purple,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SectionTitle(
              title: 'Custom Section',
              style: customStyle,
            ),
          ),
        ),
      );

      final text = tester.widget<Text>(find.text('Custom Section'));
      expect(text.style?.fontSize, 24);
      expect(text.style?.fontWeight, FontWeight.w500);
      expect(text.style?.color, Colors.purple);
    });

    testWidgets('renders with empty title', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SectionTitle(title: ''),
          ),
        ),
      );

      expect(find.text(''), findsWidgets);
    });

    testWidgets('renders with very long title', (tester) async {
      const longTitle = 'This is a very long section title that should render correctly';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SectionTitle(title: longTitle),
          ),
        ),
      );

      expect(find.text(longTitle), findsOneWidget);
    });

    testWidgets('inherits theme when no custom style provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            textTheme: const TextTheme(
              headlineSmall: TextStyle(
                fontSize: 22,
                color: Colors.orange,
              ),
            ),
          ),
          home: const Scaffold(
            body: SectionTitle(title: 'Themed Section'),
          ),
        ),
      );

      expect(find.text('Themed Section'), findsOneWidget);
    });
  });

  group('StatTile', () {
    testWidgets('renders label and value with default styles', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatTile(
              label: 'Total Trades',
              value: '42',
            ),
          ),
        ),
      );

      expect(find.text('Total Trades'), findsOneWidget);
      expect(find.text('42'), findsOneWidget);

      final labelText = tester.widget<Text>(find.text('Total Trades'));
      expect(labelText.style?.fontSize, 16);

      final valueText = tester.widget<Text>(find.text('42'));
      expect(valueText.style?.fontSize, 16);
      expect(valueText.style?.fontWeight, FontWeight.w600);
    });

    testWidgets('uses ListTile with correct properties', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatTile(
              label: 'Test',
              value: 'Value',
            ),
          ),
        ),
      );

      final listTile = tester.widget<ListTile>(find.byType(ListTile));
      expect(listTile.visualDensity, const VisualDensity(vertical: -3));
      expect(listTile.contentPadding, EdgeInsets.zero);
    });

    testWidgets('renders with custom label style', (tester) async {
      const customLabelStyle = TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.blue,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatTile(
              label: 'Custom Label',
              value: '100',
              labelStyle: customLabelStyle,
            ),
          ),
        ),
      );

      final labelText = tester.widget<Text>(find.text('Custom Label'));
      expect(labelText.style?.fontSize, 20);
      expect(labelText.style?.fontWeight, FontWeight.bold);
      expect(labelText.style?.color, Colors.blue);
    });

    testWidgets('renders with custom value style', (tester) async {
      const customValueStyle = TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w900,
        color: Colors.red,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatTile(
              label: 'Label',
              value: '999',
              valueStyle: customValueStyle,
            ),
          ),
        ),
      );

      final valueText = tester.widget<Text>(find.text('999'));
      expect(valueText.style?.fontSize, 22);
      expect(valueText.style?.fontWeight, FontWeight.w900);
      expect(valueText.style?.color, Colors.red);
    });

    testWidgets('renders numeric value', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatTile(
              label: 'Count',
              value: '12345',
            ),
          ),
        ),
      );

      expect(find.text('Count'), findsOneWidget);
      expect(find.text('12345'), findsOneWidget);
    });

    testWidgets('renders currency value', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatTile(
              label: 'Revenue',
              value: '\$1,234,567.89',
            ),
          ),
        ),
      );

      expect(find.text('Revenue'), findsOneWidget);
      expect(find.text('\$1,234,567.89'), findsOneWidget);
    });

    testWidgets('renders negative value', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatTile(
              label: 'Loss',
              value: '-\$500',
            ),
          ),
        ),
      );

      expect(find.text('Loss'), findsOneWidget);
      expect(find.text('-\$500'), findsOneWidget);
    });

    testWidgets('renders decimal value', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatTile(
              label: 'Average',
              value: '42.5',
            ),
          ),
        ),
      );

      expect(find.text('Average'), findsOneWidget);
      expect(find.text('42.5'), findsOneWidget);
    });

    testWidgets('renders with empty label', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatTile(
              label: '',
              value: '100',
            ),
          ),
        ),
      );

      expect(find.text(''), findsWidgets);
      expect(find.text('100'), findsOneWidget);
    });

    testWidgets('renders with empty value', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatTile(
              label: 'Empty',
              value: '',
            ),
          ),
        ),
      );

      expect(find.text('Empty'), findsOneWidget);
      expect(find.text(''), findsWidgets);
    });

    testWidgets('renders multiple stat tiles in a column', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                StatTile(label: 'Buys', value: '10'),
                StatTile(label: 'Sells', value: '5'),
                StatTile(label: 'Total', value: '15'),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(StatTile), findsNWidgets(3));
      expect(find.text('Buys'), findsOneWidget);
      expect(find.text('Sells'), findsOneWidget);
      expect(find.text('Total'), findsOneWidget);
    });

    testWidgets('renders with very long label text', (tester) async {
      const longLabel = 'This is a very long label that should still render properly in the tile';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatTile(
              label: longLabel,
              value: '123',
            ),
          ),
        ),
      );

      expect(find.text(longLabel), findsOneWidget);
      expect(find.text('123'), findsOneWidget);
    });

    testWidgets('renders with very long value text', (tester) async {
      const longValue = '1,234,567,890,123,456.78';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatTile(
              label: 'Big Number',
              value: longValue,
            ),
          ),
        ),
      );

      expect(find.text('Big Number'), findsOneWidget);
      expect(find.text(longValue), findsOneWidget);
    });
  });
}
