import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xfin/database/app_database.dart';
import 'package:xfin/database/tables.dart';
import 'package:xfin/providers/base_currency_provider.dart';
import 'package:xfin/utils/format.dart';
import 'package:xfin/utils/global_constants.dart';
import 'package:xfin/widgets/charts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // formatCurrency reads BaseCurrencyProvider.symbol statically
    BaseCurrencyProvider.symbol = '\u20AC'; // Euro sign
  });

  // ============================================================
  // AllocationItem unit tests
  // ============================================================

  group('AllocationItem', () {
    test('creates with required fields only', () {
      const item = AllocationItem(label: 'Stocks', value: 1000.0);

      expect(item.label, 'Stocks');
      expect(item.value, 1000.0);
      expect(item.type, isNull);
      expect(item.asset, isNull);
    });

    test('creates with all optional fields', () {
      const asset = Asset(
        id: 1,
        name: 'EUR',
        type: AssetTypes.fiat,
        tickerSymbol: 'EUR',
        currencySymbol: '\u20AC',
        value: 0,
        shares: 0,
        brokerCostBasis: 1,
        netCostBasis: 1,
        buyFeeTotal: 0,
        isArchived: false,
      );

      const item = AllocationItem(
        label: 'Fiat',
        value: 500.0,
        type: AssetTypes.fiat,
        asset: asset,
      );

      expect(item.label, 'Fiat');
      expect(item.value, 500.0);
      expect(item.type, AssetTypes.fiat);
      expect(item.asset, isNotNull);
      expect(item.asset!.name, 'EUR');
    });

    test('supports zero value', () {
      const item = AllocationItem(label: 'Empty', value: 0.0);
      expect(item.value, 0.0);
    });

    test('supports negative value', () {
      const item = AllocationItem(label: 'Loss', value: -100.0);
      expect(item.value, -100.0);
    });
  });

  // ============================================================
  // AllocationPieChart widget tests
  // ============================================================

  group('AllocationPieChart', () {
    testWidgets('renders a PieChart inside a SizedBox', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AllocationPieChart(
              items: [
                AllocationItem(label: 'A', value: 100),
                AllocationItem(label: 'B', value: 200),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(PieChart), findsOneWidget);
      expect(find.byType(SizedBox), findsWidgets);

      // Verify the SizedBox height
      final sizedBox = tester.widget<SizedBox>(
        find.ancestor(
          of: find.byType(PieChart),
          matching: find.byType(SizedBox),
        ),
      );
      expect(sizedBox.height, 240);
    });

    testWidgets('renders with empty items list', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AllocationPieChart(items: []),
          ),
        ),
      );

      expect(find.byType(PieChart), findsOneWidget);
    });

    testWidgets('shows percentage title for items >= 8% of total',
        (tester) async {
      // Item A is 90% (>= 8%), Item B is 10% (>= 8%)
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AllocationPieChart(
              items: [
                AllocationItem(label: 'Large', value: 900),
                AllocationItem(label: 'Medium', value: 100),
              ],
            ),
          ),
        ),
      );

      final pieChart = tester.widget<PieChart>(find.byType(PieChart));
      final sections = pieChart.data.sections;

      expect(sections.length, 2);
      // 900/1000 = 90% -> title should be '90%'
      expect(sections[0].title, '90%');
      // 100/1000 = 10% -> title should be '10%'
      expect(sections[1].title, '10%');
    });

    testWidgets('hides title for items < 8% of total', (tester) async {
      // Item A is 95%, Item B is 5% (< 8%)
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AllocationPieChart(
              items: [
                AllocationItem(label: 'Large', value: 950),
                AllocationItem(label: 'Tiny', value: 50),
              ],
            ),
          ),
        ),
      );

      final pieChart = tester.widget<PieChart>(find.byType(PieChart));
      final sections = pieChart.data.sections;

      // 50/1000 = 5% -> title should be empty
      expect(sections[1].title, '');
    });

    testWidgets('handles zero total gracefully', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AllocationPieChart(
              items: [
                AllocationItem(label: 'Zero', value: 0),
              ],
            ),
          ),
        ),
      );

      // PieChart renders without errors even when total is 0
      expect(find.byType(PieChart), findsOneWidget);
    });

    testWidgets('assigns correct chartColors to sections', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AllocationPieChart(
              items: [
                AllocationItem(label: 'A', value: 100),
                AllocationItem(label: 'B', value: 200),
                AllocationItem(label: 'C', value: 300),
              ],
            ),
          ),
        ),
      );

      final pieChart = tester.widget<PieChart>(find.byType(PieChart));
      final sections = pieChart.data.sections;

      expect(sections[0].color, chartColors[0]);
      expect(sections[1].color, chartColors[1]);
      expect(sections[2].color, chartColors[2]);
    });

    testWidgets('uses PieChartData with correct configuration',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AllocationPieChart(
              items: [AllocationItem(label: 'A', value: 100)],
            ),
          ),
        ),
      );

      final pieChart = tester.widget<PieChart>(find.byType(PieChart));
      expect(pieChart.data.sectionsSpace, 3);
      expect(pieChart.data.centerSpaceRadius, 46);
      expect(pieChart.data.startDegreeOffset, -90);
    });
  });

  // ============================================================
  // AllocationBreakdownSection widget tests
  // ============================================================

  group('AllocationBreakdownSection', () {
    testWidgets('renders title text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AllocationBreakdownSection(
                items: [AllocationItem(label: 'Stocks', value: 1000)],
                title: 'Portfolio Breakdown',
              ),
            ),
          ),
        ),
      );

      expect(find.text('Portfolio Breakdown'), findsOneWidget);
    });

    testWidgets('renders a ListTile for each item', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AllocationBreakdownSection(
                items: [
                  AllocationItem(label: 'Stocks', value: 600),
                  AllocationItem(label: 'Bonds', value: 400),
                ],
                title: 'Allocation',
              ),
            ),
          ),
        ),
      );

      expect(find.byType(ListTile), findsNWidgets(2));
      expect(find.text('Stocks'), findsOneWidget);
      expect(find.text('Bonds'), findsOneWidget);
    });

    testWidgets('displays formatted currency values', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AllocationBreakdownSection(
                items: [
                  AllocationItem(label: 'Item', value: 1234.56),
                ],
                title: 'Test',
              ),
            ),
          ),
        ),
      );

      // formatCurrency uses de_DE locale with Euro symbol
      final expectedCurrency = formatCurrency(1234.56);
      expect(find.text(expectedCurrency), findsOneWidget);
    });

    testWidgets('displays formatted percentages', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AllocationBreakdownSection(
                items: [
                  AllocationItem(label: 'A', value: 750),
                  AllocationItem(label: 'B', value: 250),
                ],
                title: 'Test',
              ),
            ),
          ),
        ),
      );

      // A = 750/1000 = 75%
      final expectedPercentA = formatPercent(0.75);
      // B = 250/1000 = 25%
      final expectedPercentB = formatPercent(0.25);
      expect(find.text(expectedPercentA), findsOneWidget);
      expect(find.text(expectedPercentB), findsOneWidget);
    });

    testWidgets('includes AllocationPieChart', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AllocationBreakdownSection(
                items: [AllocationItem(label: 'X', value: 100)],
                title: 'Test',
              ),
            ),
          ),
        ),
      );

      expect(find.byType(AllocationPieChart), findsOneWidget);
    });

    testWidgets('calls onItemTap when item is tapped', (tester) async {
      AllocationItem? tappedItem;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AllocationBreakdownSection(
                items: const [
                  AllocationItem(label: 'Tappable', value: 500),
                ],
                title: 'Test',
                onItemTap: (item) => tappedItem = item,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Tappable'));
      await tester.pumpAndSettle();

      expect(tappedItem, isNotNull);
      expect(tappedItem!.label, 'Tappable');
      expect(tappedItem!.value, 500);
    });

    testWidgets('ListTile is not tappable when onItemTap is null',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AllocationBreakdownSection(
                items: [
                  AllocationItem(label: 'Non-Tappable', value: 100),
                ],
                title: 'Test',
                onItemTap: null,
              ),
            ),
          ),
        ),
      );

      final listTile = tester.widget<ListTile>(find.byType(ListTile));
      expect(listTile.onTap, isNull);
    });

    testWidgets('shows 0% for all items when total is zero', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AllocationBreakdownSection(
                items: [
                  AllocationItem(label: 'Zero', value: 0),
                ],
                title: 'Test',
              ),
            ),
          ),
        ),
      );

      final expectedPercent = formatPercent(0.0);
      expect(find.text(expectedPercent), findsOneWidget);
    });

    testWidgets('assigns correct colors from chartColors', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AllocationBreakdownSection(
                items: [
                  AllocationItem(label: 'A', value: 100),
                  AllocationItem(label: 'B', value: 200),
                  AllocationItem(label: 'C', value: 300),
                ],
                title: 'Test',
              ),
            ),
          ),
        ),
      );

      final avatars =
          tester.widgetList<CircleAvatar>(find.byType(CircleAvatar)).toList();

      expect(avatars.length, 3);
      expect(avatars[0].backgroundColor, chartColors[0]);
      expect(avatars[1].backgroundColor, chartColors[1]);
      expect(avatars[2].backgroundColor, chartColors[2]);
    });

    testWidgets('color cycling wraps around chartColors length',
        (tester) async {
      // Create more items than chartColors has entries (10 colors)
      final items = List.generate(
        12,
        (i) => AllocationItem(label: 'Item $i', value: 100),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AllocationBreakdownSection(
                items: items,
                title: 'Test',
              ),
            ),
          ),
        ),
      );

      final avatars =
          tester.widgetList<CircleAvatar>(find.byType(CircleAvatar)).toList();

      expect(avatars.length, 12);
      // Item 10 should wrap to chartColors[0]
      expect(avatars[10].backgroundColor, chartColors[0]);
      // Item 11 should wrap to chartColors[1]
      expect(avatars[11].backgroundColor, chartColors[1]);
    });

    testWidgets('renders with empty items list', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AllocationBreakdownSection(
                items: [],
                title: 'Empty',
              ),
            ),
          ),
        ),
      );

      expect(find.text('Empty'), findsOneWidget);
      expect(find.byType(ListTile), findsNothing);
      expect(find.byType(AllocationPieChart), findsOneWidget);
    });

    testWidgets('CircleAvatar has radius 8', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AllocationBreakdownSection(
                items: [AllocationItem(label: 'A', value: 100)],
                title: 'Test',
              ),
            ),
          ),
        ),
      );

      final avatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar));
      expect(avatar.radius, 8);
    });

    testWidgets('label text has bold font weight', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AllocationBreakdownSection(
                items: [AllocationItem(label: 'Bold Label', value: 100)],
                title: 'Test',
              ),
            ),
          ),
        ),
      );

      final labelText = tester.widget<Text>(find.text('Bold Label'));
      expect(labelText.style?.fontWeight, FontWeight.w600);
    });
  });
}
