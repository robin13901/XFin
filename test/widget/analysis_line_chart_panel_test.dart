import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xfin/widgets/analysis_line_chart_panel.dart';

void main() {
  testWidgets('renders range buttons and indicator toggles', (tester) async {
    String selectedRange = '1W';
    bool showSma = false;
    bool showEma = false;
    bool showBb = false;

    final now = DateTime.now().millisecondsSinceEpoch.toDouble();
    final data = List.generate(10, (i) => FlSpot(now + i * 86400000, 100 + i * 2));

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) => Scaffold(
            body: AnalysisLineChartPanel(
              allData: data,
              baselineValue: data.first.y,
              selectedRange: selectedRange,
              onRangeSelected: (v) => setState(() => selectedRange = v),
              touchedSpot: null,
              onTouchedSpotChanged: (_) {},
              showSma: showSma,
              showEma: showEma,
              showBb: showBb,
              onShowSmaChanged: (v) => setState(() => showSma = v),
              onShowEmaChanged: (v) => setState(() => showEma = v),
              onShowBbChanged: (v) => setState(() => showBb = v),
              valueFormatter: (v) => v.toStringAsFixed(2),
            ),
          ),
        ),
      ),
    );

    expect(find.text('1W'), findsOneWidget);
    expect(find.text('1M'), findsOneWidget);
    expect(find.text('1J'), findsOneWidget);
    expect(find.text('MAX'), findsOneWidget);

    await tester.tap(find.text('1M'));
    await tester.pumpAndSettle();
    expect(find.text('Seit 1 Monat'), findsOneWidget);

    await tester.tap(find.text('30-SMA'));
    await tester.pumpAndSettle();
    expect(showSma, isTrue);

    await tester.tap(find.text('30-EMA'));
    await tester.pumpAndSettle();
    expect(showEma, isTrue);

    await tester.tap(find.text('20-BB'));
    await tester.pumpAndSettle();
    expect(showBb, isTrue);
  });
}
