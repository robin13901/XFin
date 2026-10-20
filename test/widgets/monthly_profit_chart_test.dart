import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:xfin/database/models/analysis_models.dart';
import 'package:xfin/providers/base_currency_provider.dart';
import 'package:xfin/utils/format.dart';
import 'package:xfin/widgets/monthly_profit_chart.dart';

/// Builds a short, deterministic monthly-profit history:
///   Jan  profit 100  runningAvg 100
///   Feb  profit   0  runningAvg  50
///   Mar  profit 300  runningAvg 400/3 (≈ 133.33)
List<MonthlyProfitPoint> _sampleHistory() => [
      MonthlyProfitPoint(
          monthDate: DateTime(2024, 1, 1), profit: 100, runningAverage: 100),
      MonthlyProfitPoint(
          monthDate: DateTime(2024, 2, 1), profit: 0, runningAverage: 50),
      MonthlyProfitPoint(
          monthDate: DateTime(2024, 3, 1),
          profit: 300,
          runningAverage: 400 / 3),
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
    await tester.pumpWidget(_wrap(MonthlyProfitChart(points: _sampleHistory())));

    expect(find.text('Monatlicher Gewinn'), findsOneWidget);
    expect(find.byType(LineChart), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'Ø kumuliert'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'Je Monat'), findsOneWidget);
  });

  testWidgets('defaults to the running average (last point)', (tester) async {
    await tester.pumpWidget(_wrap(MonthlyProfitChart(points: _sampleHistory())));

    // runningAverage of the last month = 400 / 3 ≈ 133.33
    expect(find.text(formatCurrency(400 / 3)), findsOneWidget);
  });

  testWidgets('switching to "Je Monat" shows the per-month profit',
      (tester) async {
    await tester.pumpWidget(_wrap(MonthlyProfitChart(points: _sampleHistory())));

    await tester.tap(find.text('Je Monat'));
    await tester.pumpAndSettle();

    // Last month's raw profit = 300
    expect(find.text(formatCurrency(300)), findsOneWidget);
  });

  testWidgets('blurs the header value when hidden', (tester) async {
    await tester.pumpWidget(
      _wrap(MonthlyProfitChart(points: _sampleHistory(), hidden: true)),
    );

    expect(find.byType(ImageFiltered), findsOneWidget);
  });

  testWidgets('handles a single data point without crashing', (tester) async {
    await tester.pumpWidget(_wrap(MonthlyProfitChart(points: [
      MonthlyProfitPoint(
          monthDate: DateTime(2024, 1, 1), profit: 42, runningAverage: 42),
    ])));

    expect(find.byType(LineChart), findsOneWidget);
    expect(find.text(formatCurrency(42)), findsOneWidget);
  });
}
