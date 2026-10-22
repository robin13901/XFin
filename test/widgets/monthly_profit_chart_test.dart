import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:xfin/providers/base_currency_provider.dart';
import 'package:xfin/utils/format.dart';
import 'package:xfin/widgets/monthly_profit_chart.dart';

double _ms(DateTime date) => date.millisecondsSinceEpoch.toDouble();

/// Daily cumulative-average series: last point = 30.
List<FlSpot> _cumulative() => [
      FlSpot(_ms(DateTime(2024, 1, 1)), 10),
      FlSpot(_ms(DateTime(2024, 1, 2)), 20),
      FlSpot(_ms(DateTime(2024, 1, 3)), 30),
    ];

/// Per-month series: last point = 300.
List<FlSpot> _perMonth() => [
      FlSpot(_ms(DateTime(2024, 1, 1)), 100),
      FlSpot(_ms(DateTime(2024, 2, 1)), 300),
    ];

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(child: child),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('de_DE');
  });

  setUp(() {
    BaseCurrencyProvider.symbol = '€'; // Euro sign
  });

  testWidgets('renders chart, title and both series toggles', (tester) async {
    await tester.pumpWidget(_wrap(MonthlyProfitChart(
      perMonthProfit: _perMonth(),
      movingAverage: _cumulative(),
    )));

    expect(find.text('Monatlicher Gewinn'), findsOneWidget);
    expect(find.byType(LineChart), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, '100-SMA'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'Je Monat'), findsOneWidget);
  });

  testWidgets('defaults to the cumulative average (last point)',
      (tester) async {
    await tester.pumpWidget(_wrap(MonthlyProfitChart(
      perMonthProfit: _perMonth(),
      movingAverage: _cumulative(),
    )));

    expect(find.text(formatCurrency(30)), findsOneWidget);
  });

  testWidgets('switching to "Je Monat" shows the per-month profit',
      (tester) async {
    await tester.pumpWidget(_wrap(MonthlyProfitChart(
      perMonthProfit: _perMonth(),
      movingAverage: _cumulative(),
    )));

    await tester.tap(find.text('Je Monat'));
    await tester.pumpAndSettle();

    expect(find.text(formatCurrency(300)), findsOneWidget);
  });

  testWidgets('blurs the header value when hidden', (tester) async {
    await tester.pumpWidget(_wrap(MonthlyProfitChart(
      perMonthProfit: _perMonth(),
      movingAverage: _cumulative(),
      hidden: true,
    )));

    expect(find.byType(ImageFiltered), findsOneWidget);
  });

  testWidgets('handles a single data point without crashing', (tester) async {
    await tester.pumpWidget(_wrap(MonthlyProfitChart(
      perMonthProfit: const [],
      movingAverage: [FlSpot(_ms(DateTime(2024, 1, 1)), 42)],
    )));

    expect(find.byType(LineChart), findsOneWidget);
    expect(find.text(formatCurrency(42)), findsOneWidget);
  });

  testWidgets('shows a placeholder when the selected series is empty',
      (tester) async {
    await tester.pumpWidget(_wrap(MonthlyProfitChart(
      perMonthProfit: const [],
      movingAverage: _cumulative(),
    )));

    // Default (cumulative) renders a chart; switching to the empty per-month
    // series shows the placeholder instead.
    await tester.tap(find.text('Je Monat'));
    await tester.pumpAndSettle();

    expect(find.text('Keine Daten verfügbar.'), findsOneWidget);
    expect(find.byType(LineChart), findsNothing);
  });
}
