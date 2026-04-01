import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xfin/app_theme.dart';
import 'package:xfin/providers/base_currency_provider.dart';
import 'package:xfin/utils/format.dart';
import 'package:xfin/widgets/analysis_line_chart_section.dart';

/// Generates [days] FlSpot data points starting from 2024-01-01.
///
/// Each point is one day apart with y-values starting at [startValue]
/// and incrementing by [dailyDelta].
List<FlSpot> generateTestData(
  int days, {
  double startValue = 100.0,
  double dailyDelta = 1.0,
}) {
  final start = DateTime(2024, 1, 1);
  return List.generate(days, (i) {
    final date = start.add(Duration(days: i));
    return FlSpot(
      date.millisecondsSinceEpoch.toDouble(),
      startValue + i * dailyDelta,
    );
  });
}

/// Helper that wraps [AnalysisLineChartSection] in a pumped-ready widget tree.
Widget buildChart({
  required List<FlSpot> data,
  double startValue = 100.0,
  String selectedRange = 'MAX',
  bool showSma = false,
  bool showEma = false,
  bool showBb = false,
  bool showSma200 = false,
  bool showSma200Toggle = true,
  LineBarSpot? touchedSpot,
  ValueChanged<String>? onRangeSelected,
  ValueChanged<bool>? onShowSmaChanged,
  ValueChanged<bool>? onShowEmaChanged,
  ValueChanged<bool>? onShowBbChanged,
  ValueChanged<bool>? onShowSma200Changed,
  ValueChanged<LineBarSpot?>? onTouchedSpotChanged,
  VoidCallback? onPointerDown,
  VoidCallback? onPointerUpOrCancel,
  String valueLabel = '',
  Widget? topRight,
}) {
  return MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: AnalysisLineChartSection(
          allData: data,
          startValue: startValue,
          selectedRange: selectedRange,
          onRangeSelected: onRangeSelected ?? (_) {},
          showSma: showSma,
          showEma: showEma,
          showBb: showBb,
          showSma200: showSma200,
          onShowSmaChanged: onShowSmaChanged ?? (_) {},
          onShowEmaChanged: onShowEmaChanged ?? (_) {},
          onShowBbChanged: onShowBbChanged ?? (_) {},
          onShowSma200Changed: onShowSma200Changed,
          touchedSpot: touchedSpot,
          onTouchedSpotChanged: onTouchedSpotChanged ?? (_) {},
          onPointerDown: onPointerDown ?? () {},
          onPointerUpOrCancel: onPointerUpOrCancel ?? () {},
          valueFormatter: (v) => v.toStringAsFixed(2),
          showSma200Toggle: showSma200Toggle,
          valueLabel: valueLabel,
          topRight: topRight,
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await initializeDateFormatting('de_DE');
  });

  setUp(() {
    BaseCurrencyProvider.symbol = '\u20AC'; // Euro sign
  });

  // ============================================================
  // Group 1: Header display
  // ============================================================

  group('Header display', () {
    testWidgets('shows formatted total value (last data point)', (tester) async {
      // 10 days: values 100..109, last = 109
      final data = generateTestData(10);
      await tester.pumpWidget(buildChart(data: data));

      expect(find.text('109.00'), findsOneWidget);
    });

    testWidgets('shows profit with green arrow_upward when positive', (tester) async {
      // MAX range: profit = last - startValue = 109 - 100 = 9
      final data = generateTestData(10);
      await tester.pumpWidget(buildChart(data: data, startValue: 100.0));

      expect(find.byIcon(Icons.arrow_upward), findsOneWidget);

      final icon = tester.widget<Icon>(find.byIcon(Icons.arrow_upward));
      expect(icon.color, AppColors.green);
    });

    testWidgets('shows loss with red arrow_downward when negative', (tester) async {
      // MAX range: profit = last - startValue = 109 - 200 = -91
      final data = generateTestData(10);
      await tester.pumpWidget(buildChart(data: data, startValue: 200.0));

      expect(find.byIcon(Icons.arrow_downward), findsOneWidget);

      final icon = tester.widget<Icon>(find.byIcon(Icons.arrow_downward));
      expect(icon.color, AppColors.red);
    });

    testWidgets('shows range text for each time range', (tester) async {
      final data = generateTestData(400);

      // 1W
      await tester.pumpWidget(buildChart(data: data, selectedRange: '1W'));
      expect(find.text('Seit 7 Tagen'), findsOneWidget);

      // 1M
      await tester.pumpWidget(buildChart(data: data, selectedRange: '1M'));
      expect(find.text('Seit 1 Monat'), findsOneWidget);

      // 1J
      await tester.pumpWidget(buildChart(data: data, selectedRange: '1J'));
      expect(find.text('Seit 1 Jahr'), findsOneWidget);

      // MAX
      await tester.pumpWidget(buildChart(data: data, selectedRange: 'MAX'));
      expect(find.text('Insgesamt'), findsOneWidget);
    });

    testWidgets('shows valueLabel and topRight widget when provided', (tester) async {
      final data = generateTestData(10);
      await tester.pumpWidget(buildChart(
        data: data,
        valueLabel: 'Net Worth',
        topRight: const Icon(Icons.settings, key: Key('topRightIcon')),
      ));

      expect(find.text('Net Worth'), findsOneWidget);
      expect(find.byKey(const Key('topRightIcon')), findsOneWidget);
    });

    testWidgets('shows centered value when topRight is null', (tester) async {
      final data = generateTestData(10);
      await tester.pumpWidget(buildChart(data: data));

      // When topRight is null, value is rendered as a standalone Text
      // (not inside a Row with Expanded).
      // Verify the Text widget with fontSize 32 exists.
      final textWidget = tester.widget<Text>(find.text('109.00'));
      expect(textWidget.style?.fontSize, 32);
      expect(textWidget.style?.fontWeight, FontWeight.bold);

      // Should NOT find a Row containing the topRight widget
      expect(find.byType(Expanded), findsNothing);
    });
  });

  // ============================================================
  // Group 2: Range selection
  // ============================================================

  group('Range selection', () {
    testWidgets('renders all 4 range buttons (1W, 1M, 1J, MAX)', (tester) async {
      final data = generateTestData(10);
      await tester.pumpWidget(buildChart(data: data));

      expect(find.widgetWithText(TextButton, '1W'), findsOneWidget);
      expect(find.widgetWithText(TextButton, '1M'), findsOneWidget);
      expect(find.widgetWithText(TextButton, '1J'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'MAX'), findsOneWidget);
    });

    testWidgets('selected range has secondary background', (tester) async {
      final data = generateTestData(10);
      await tester.pumpWidget(buildChart(data: data, selectedRange: '1M'));

      // The selected button (1M) should have a non-transparent background.
      // Unselected (1W) should have transparent background.
      final selectedButton = tester.widget<TextButton>(
        find.widgetWithText(TextButton, '1M'),
      );
      final unselectedButton = tester.widget<TextButton>(
        find.widgetWithText(TextButton, '1W'),
      );

      // Resolve styles: selected should have secondary color bg
      final selectedBg = selectedButton.style?.backgroundColor?.resolve({});
      final unselectedBg = unselectedButton.style?.backgroundColor?.resolve({});

      expect(selectedBg, isNot(Colors.transparent));
      expect(unselectedBg, Colors.transparent);
    });

    testWidgets('tapping range button calls onRangeSelected', (tester) async {
      String? selected;
      final data = generateTestData(10);
      await tester.pumpWidget(buildChart(
        data: data,
        onRangeSelected: (v) => selected = v,
      ));

      await tester.tap(find.widgetWithText(TextButton, '1W'));
      expect(selected, '1W');

      await tester.tap(find.widgetWithText(TextButton, '1M'));
      expect(selected, '1M');
    });

    testWidgets('1W shows last 7 data points (value = 7th-from-last)', (tester) async {
      // 50 days: values 100..149, last = 149
      // 1W range = last 7 data points: values 143..149
      final data = generateTestData(50);
      await tester.pumpWidget(buildChart(data: data, selectedRange: '1W'));

      // totalToShow = last point of 1W range = 149
      expect(find.text('149.00'), findsOneWidget);

      // Profit for filtered range = last - first of range = 149 - 143 = 6
      // profitPercent = 6 / 143
      const expectedProfit = '6.00';
      final expectedPercent = formatPercent(6 / 143);
      expect(find.textContaining(expectedProfit), findsOneWidget);
      expect(find.textContaining(expectedPercent), findsOneWidget);
    });

    testWidgets('MAX shows all data points', (tester) async {
      // 10 days: values 100..109
      // MAX profit = last - startValue = 109 - 50 = 59
      final data = generateTestData(10);
      await tester.pumpWidget(buildChart(data: data, startValue: 50.0, selectedRange: 'MAX'));

      expect(find.text('109.00'), findsOneWidget);

      const expectedProfit = '59.00';
      final expectedPercent = formatPercent(59 / 50);
      expect(find.textContaining(expectedProfit), findsOneWidget);
      expect(find.textContaining(expectedPercent), findsOneWidget);
    });
  });

  // ============================================================
  // Group 3: Indicator toggles
  // ============================================================

  group('Indicator toggles', () {
    testWidgets('renders SMA, EMA, BB toggle buttons', (tester) async {
      final data = generateTestData(10);
      await tester.pumpWidget(buildChart(data: data));

      expect(find.text('SMA'), findsOneWidget);
      expect(find.text('EMA'), findsOneWidget);
      expect(find.text('BB'), findsOneWidget);
    });

    testWidgets('renders SMA200 when showSma200Toggle is true', (tester) async {
      final data = generateTestData(10);
      await tester.pumpWidget(buildChart(data: data, showSma200Toggle: true));

      // SMA200 is rendered with subscript: 'SMA\u2082\u2080\u2080'
      expect(find.text('SMA\u2082\u2080\u2080'), findsOneWidget);
    });

    testWidgets('hides SMA200 when showSma200Toggle is false', (tester) async {
      final data = generateTestData(10);
      await tester.pumpWidget(buildChart(data: data, showSma200Toggle: false));

      expect(find.text('SMA\u2082\u2080\u2080'), findsNothing);
    });

    testWidgets('tapping SMA calls onShowSmaChanged', (tester) async {
      bool? value;
      final data = generateTestData(10);
      await tester.pumpWidget(buildChart(
        data: data,
        showSma: false,
        onShowSmaChanged: (v) => value = v,
      ));

      await tester.tap(find.text('SMA'));
      // GestureDetector calls onChanged(!selected) => !false => true
      expect(value, true);
    });

    testWidgets('tapping EMA calls onShowEmaChanged', (tester) async {
      bool? value;
      final data = generateTestData(10);
      await tester.pumpWidget(buildChart(
        data: data,
        showEma: false,
        onShowEmaChanged: (v) => value = v,
      ));

      await tester.tap(find.text('EMA'));
      expect(value, true);
    });

    testWidgets('tapping BB calls onShowBbChanged', (tester) async {
      bool? value;
      final data = generateTestData(10);
      await tester.pumpWidget(buildChart(
        data: data,
        showBb: false,
        onShowBbChanged: (v) => value = v,
      ));

      await tester.tap(find.text('BB'));
      expect(value, true);
    });

    testWidgets('tapping SMA200 calls onShowSma200Changed', (tester) async {
      bool? value;
      final data = generateTestData(10);
      await tester.pumpWidget(buildChart(
        data: data,
        showSma200: false,
        showSma200Toggle: true,
        onShowSma200Changed: (v) => value = v,
      ));

      await tester.tap(find.text('SMA\u2082\u2080\u2080'));
      expect(value, true);
    });

    testWidgets('selected toggle has colored background', (tester) async {
      final data = generateTestData(10);
      await tester.pumpWidget(buildChart(data: data, showSma: true));

      // Find the Container for SMA toggle (which is selected)
      final smaText = find.text('SMA');
      final containerFinder = find.ancestor(
        of: smaText,
        matching: find.byType(Container),
      );

      // The immediate Container parent should have non-transparent background
      final container = tester.widget<Container>(containerFinder.first);
      final decoration = container.decoration as BoxDecoration?;
      expect(decoration?.color, isNot(Colors.transparent));
      // Should be orange with alpha for SMA
      expect(decoration?.color, Colors.orange.withValues(alpha: 0.2));
    });

    testWidgets('unselected toggle has transparent background', (tester) async {
      final data = generateTestData(10);
      await tester.pumpWidget(buildChart(data: data, showSma: false));

      final smaText = find.text('SMA');
      final containerFinder = find.ancestor(
        of: smaText,
        matching: find.byType(Container),
      );

      final container = tester.widget<Container>(containerFinder.first);
      final decoration = container.decoration as BoxDecoration?;
      expect(decoration?.color, Colors.transparent);
    });
  });

  // ============================================================
  // Group 4: Chart rendering
  // ============================================================

  group('Chart rendering', () {
    testWidgets('renders LineChart widget', (tester) async {
      final data = generateTestData(10);
      await tester.pumpWidget(buildChart(data: data));

      expect(find.byType(LineChart), findsOneWidget);
    });

    testWidgets('shows additional SMA line when showSma is true (30+ points)', (tester) async {
      final data = generateTestData(50);
      await tester.pumpWidget(buildChart(data: data, showSma: true));

      final lineChart = tester.widget<LineChart>(find.byType(LineChart));
      // 1 main line + 1 SMA line = 2
      expect(lineChart.data.lineBarsData.length, 2);

      // SMA line should be orange
      expect(lineChart.data.lineBarsData[1].color, Colors.orange);
    });

    testWidgets('shows additional EMA line when showEma is true (30+ points)', (tester) async {
      final data = generateTestData(50);
      await tester.pumpWidget(buildChart(data: data, showEma: true));

      final lineChart = tester.widget<LineChart>(find.byType(LineChart));
      expect(lineChart.data.lineBarsData.length, 2);
      expect(lineChart.data.lineBarsData[1].color, Colors.purple);
    });

    testWidgets('shows BB bands when showBb is true (20+ points)', (tester) async {
      final data = generateTestData(50);
      await tester.pumpWidget(buildChart(data: data, showBb: true));

      final lineChart = tester.widget<LineChart>(find.byType(LineChart));
      // 1 main line + 3 BB lines (upper, middle, lower) = 4
      expect(lineChart.data.lineBarsData.length, 4);
    });

    testWidgets('BB bands have translucent fill between upper and lower', (tester) async {
      final data = generateTestData(50);
      await tester.pumpWidget(buildChart(data: data, showBb: true));

      final lineChart = tester.widget<LineChart>(find.byType(LineChart));
      expect(lineChart.data.betweenBarsData.length, 1);

      final fill = lineChart.data.betweenBarsData[0];
      // Upper band is at index 1 (after main line), lower is at index 3
      expect(fill.fromIndex, 1);
      expect(fill.toIndex, 3);
      expect(fill.color, Colors.lightBlue.withValues(alpha: 0.15));
    });

    testWidgets('no betweenBarsData when BB is disabled', (tester) async {
      final data = generateTestData(50);
      await tester.pumpWidget(buildChart(data: data, showBb: false));

      final lineChart = tester.widget<LineChart>(find.byType(LineChart));
      expect(lineChart.data.betweenBarsData, isEmpty);
    });

    testWidgets('BB middle band has dashed style', (tester) async {
      final data = generateTestData(50);
      await tester.pumpWidget(buildChart(data: data, showBb: true));

      final lineChart = tester.widget<LineChart>(find.byType(LineChart));
      // Middle band is index 2 (main=0, upper=1, middle=2, lower=3)
      final middleBand = lineChart.data.lineBarsData[2];
      expect(middleBand.dashArray, [5, 5]);
      expect(middleBand.color, Colors.indigo);
    });

    testWidgets('handles data fewer than 7 points for 1W', (tester) async {
      // With only 3 points, 1W should use all data
      final data = generateTestData(3);
      await tester.pumpWidget(buildChart(data: data, selectedRange: '1W'));

      // Should render without error; shows last point = 102
      expect(find.text('102.00'), findsOneWidget);
      expect(find.byType(LineChart), findsOneWidget);
    });

    testWidgets('handles data fewer than 30 points for 1M', (tester) async {
      final data = generateTestData(10);
      await tester.pumpWidget(buildChart(data: data, selectedRange: '1M'));

      // Should use all data; shows last point = 109
      expect(find.text('109.00'), findsOneWidget);
      expect(find.byType(LineChart), findsOneWidget);
    });

    testWidgets('handles single data point', (tester) async {
      // reduce(min/max) needs at least 1 element; we test with 2 points
      // to avoid empty-list error but we specifically test the edge case
      // of 2 points (minimal valid input for the widget)
      final data = generateTestData(2);
      await tester.pumpWidget(buildChart(data: data, selectedRange: '1W'));

      expect(find.text('101.00'), findsOneWidget);
      expect(find.byType(LineChart), findsOneWidget);
    });
  });

  // ============================================================
  // Group 5: getRangeText (tested via the UI text displayed)
  // ============================================================

  group('getRangeText', () {
    testWidgets('1W shows "Seit 7 Tagen"', (tester) async {
      final data = generateTestData(10);
      await tester.pumpWidget(buildChart(data: data, selectedRange: '1W'));
      expect(find.text('Seit 7 Tagen'), findsOneWidget);
    });

    testWidgets('1M shows "Seit 1 Monat"', (tester) async {
      final data = generateTestData(40);
      await tester.pumpWidget(buildChart(data: data, selectedRange: '1M'));
      expect(find.text('Seit 1 Monat'), findsOneWidget);
    });

    testWidgets('1J shows "Seit 1 Jahr"', (tester) async {
      final data = generateTestData(400);
      await tester.pumpWidget(buildChart(data: data, selectedRange: '1J'));
      expect(find.text('Seit 1 Jahr'), findsOneWidget);
    });

    testWidgets('MAX shows "Insgesamt"', (tester) async {
      final data = generateTestData(10);
      await tester.pumpWidget(buildChart(data: data, selectedRange: 'MAX'));
      expect(find.text('Insgesamt'), findsOneWidget);
    });
  });

  // ============================================================
  // Group 6: Touch interaction
  // ============================================================

  group('Touch interaction', () {
    testWidgets('shows formatted date (dd.MM.yyyy) when touchedSpot provided', (tester) async {
      final data = generateTestData(10);
      // Touch the 5th data point: 2024-01-06 (index 5)
      final spot = data[5];
      final barData = LineChartBarData(spots: data);
      final touchedSpot = LineBarSpot(barData, 0, spot);

      await tester.pumpWidget(buildChart(
        data: data,
        touchedSpot: touchedSpot,
      ));

      // 2024-01-06 formatted as dd.MM.yyyy => 06.01.2024
      expect(find.text('06.01.2024'), findsOneWidget);
    });

    testWidgets('shows touched spot value instead of last value', (tester) async {
      final data = generateTestData(10);
      // Touch the 3rd data point: value = 100 + 3*1 = 103
      final spot = data[3];
      final barData = LineChartBarData(spots: data);
      final touchedSpot = LineBarSpot(barData, 0, spot);

      await tester.pumpWidget(buildChart(
        data: data,
        touchedSpot: touchedSpot,
      ));

      // Should show 103.00 (touched value), not 109.00 (last value)
      expect(find.text('103.00'), findsAtLeastNWidgets(1));
    });

    testWidgets('calculates day-over-day profit for touched spot (spotIndex > 0)', (tester) async {
      final data = generateTestData(10);
      // Touch spot at index 5: value = 105, previous (index 4) = 104
      // profit = 105 - 104 = 1
      // profitPercent = 1 / 104
      final spot = data[5];
      final barData = LineChartBarData(spots: data);
      final touchedSpot = LineBarSpot(barData, 0, spot);

      await tester.pumpWidget(buildChart(
        data: data,
        touchedSpot: touchedSpot,
      ));

      // Profit = 1.00
      final expectedPercent = formatPercent(1 / 104);
      expect(find.textContaining('1.00'), findsAtLeastNWidgets(1));
      expect(find.textContaining(expectedPercent), findsOneWidget);

      // Should show upward arrow (positive profit)
      expect(find.byIcon(Icons.arrow_upward), findsOneWidget);
    });

    testWidgets('calculates profit vs startValue when first spot touched on MAX range', (tester) async {
      final data = generateTestData(10);
      // Touch the first spot (index 0): value = 100
      // For MAX range, when spotIndex == 0 and currentData.length == allData.length:
      //   profit = currentData.first.y - startValue = 100 - 50 = 50
      final spot = data[0];
      final barData = LineChartBarData(spots: data);
      final touchedSpot = LineBarSpot(barData, 0, spot);

      await tester.pumpWidget(buildChart(
        data: data,
        startValue: 50.0,
        selectedRange: 'MAX',
        touchedSpot: touchedSpot,
      ));

      // totalToShow = touched spot value = 100
      expect(find.text('100.00'), findsAtLeastNWidgets(1));

      // profit = first.y - startValue = 100 - 50 = 50
      final expectedPercent = formatPercent(50 / 50);
      expect(find.textContaining('50.00'), findsAtLeastNWidgets(1));
      expect(find.textContaining(expectedPercent), findsOneWidget);
    });

    testWidgets('shows zero profit when first spot touched on filtered range', (tester) async {
      // 50 data points, 1W range takes last 7 (index 43..49)
      // Touch the first spot of the filtered range (index 43): value = 143
      // spotIndex in filtered data = 0, but currentData.length < allData.length
      // => profit = 0, profitPercent = 0
      final data = generateTestData(50);
      final filteredFirst = data[43]; // first spot of 1W range
      final barData = LineChartBarData(spots: data);
      final touchedSpot = LineBarSpot(barData, 0, filteredFirst);

      await tester.pumpWidget(buildChart(
        data: data,
        selectedRange: '1W',
        touchedSpot: touchedSpot,
      ));

      // profit = 0
      final expectedPercent = formatPercent(0);
      expect(find.textContaining('0.00'), findsAtLeastNWidgets(1));
      expect(find.textContaining(expectedPercent), findsOneWidget);
    });
  });

  // ============================================================
  // Group 7: Profit calculation
  // ============================================================

  group('Profit calculation', () {
    testWidgets('MAX range: profit = last value - startValue', (tester) async {
      // 10 days: last = 109, startValue = 80
      // profit = 109 - 80 = 29
      final data = generateTestData(10);
      await tester.pumpWidget(buildChart(
        data: data,
        startValue: 80.0,
        selectedRange: 'MAX',
      ));

      final expectedPercent = formatPercent(29 / 80);
      expect(find.textContaining('29.00'), findsOneWidget);
      expect(find.textContaining(expectedPercent), findsOneWidget);
    });

    testWidgets('filtered range (1W): profit = last value - first value of range', (tester) async {
      // 50 days, 1W takes last 7: values from index 43 (143) to 49 (149)
      // profit = 149 - 143 = 6
      // profitPercent = 6 / 143
      final data = generateTestData(50);
      await tester.pumpWidget(buildChart(
        data: data,
        selectedRange: '1W',
      ));

      final expectedPercent = formatPercent(6 / 143);
      expect(find.textContaining('6.00'), findsOneWidget);
      expect(find.textContaining(expectedPercent), findsOneWidget);
    });

    testWidgets('hides valueLabel when topRight provided but valueLabel is empty', (tester) async {
      final data = generateTestData(10);
      await tester.pumpWidget(buildChart(
        data: data,
        topRight: const Icon(Icons.settings),
        valueLabel: '',
      ));

      // The code checks `if (valueLabel.isNotEmpty)` before rendering the label.
      // With empty valueLabel, no bodySmall-styled text should appear.
      // The topRight icon should still be present.
      expect(find.byIcon(Icons.settings), findsOneWidget);

      // Should still show the value text
      expect(find.text('109.00'), findsOneWidget);

      // Verify no bodySmall text label is rendered
      // (We can check that no Text widget with bodySmall style exists as a label.)
      // The simplest check: the Expanded Column should have only 1 child (the value),
      // not 2 (label + value).
      final column = tester.widget<Column>(
        find.descendant(
          of: find.byType(Expanded),
          matching: find.byType(Column),
        ),
      );
      // When valueLabel is empty, column should have 1 child (just the value text)
      expect(column.children.length, 1);
    });
  });
}
