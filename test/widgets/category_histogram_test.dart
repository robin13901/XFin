import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:xfin/database/models/analysis_models.dart';
import 'package:xfin/widgets/category_histogram.dart';

List<CategoryMonthBucket> _buckets(List<(int, int, int, double)> tuples) {
  return tuples
      .map((t) => CategoryMonthBucket(
            year: t.$1,
            month: t.$2,
            count: t.$3,
            sum: t.$4,
          ))
      .toList();
}

Widget _wrap(Widget child, {Locale locale = const Locale('en')}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [Locale('en'), Locale('de')],
    home: Scaffold(
      body: SizedBox(width: 360, child: child),
    ),
  );
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('de');
    await initializeDateFormatting('en');
  });

  group('CategoryHistogram', () {
    testWidgets('renders placeholder when no buckets', (tester) async {
      await tester.pumpWidget(_wrap(
        CategoryHistogram(
          buckets: const [],
          mode: CategoryHistogramMode.sum,
          sumFormatter: (v) => v.toString(),
        ),
      ));

      expect(find.text('—'), findsOneWidget);
    });

    testWidgets('renders one month label per bucket', (tester) async {
      final buckets = _buckets([
        (2024, 1, 1, 100),
        (2024, 2, 0, 0),
        (2024, 3, 2, 250),
      ]);

      await tester.pumpWidget(_wrap(
        CategoryHistogram(
          buckets: buckets,
          mode: CategoryHistogramMode.sum,
          sumFormatter: (v) => v.toStringAsFixed(0),
        ),
      ));
      await tester.pumpAndSettle();

      // January labels include the year suffix; other months use just MMM.
      expect(find.text("Jan '24"), findsOneWidget);
      expect(find.text('Feb'), findsOneWidget);
      expect(find.text('Mar'), findsOneWidget);
    });

    testWidgets('shows tooltip on tap and dismisses on outside tap',
        (tester) async {
      final buckets = _buckets([
        (2024, 1, 1, 100),
        (2024, 2, 3, 300),
      ]);

      await tester.pumpWidget(_wrap(
        CategoryHistogram(
          buckets: buckets,
          mode: CategoryHistogramMode.sum,
          sumFormatter: (v) => v.toStringAsFixed(0),
        ),
      ));
      await tester.pumpAndSettle();

      // No tooltip initially.
      expect(find.text('Feb 2024'), findsNothing);

      // Tap on the second bar (index 1).
      await tester.tap(find.byKey(const ValueKey('bar-1')));
      await tester.pump();

      expect(find.text('Feb 2024'), findsOneWidget);
      expect(find.text('300'), findsOneWidget); // value rendering

      // Tap the same bar again to toggle off.
      await tester.tap(find.byKey(const ValueKey('bar-1')));
      await tester.pump();
      expect(find.text('Feb 2024'), findsNothing);
    });

    testWidgets('switches displayed values when mode changes', (tester) async {
      final buckets = _buckets([
        (2024, 1, 5, 1000),
      ]);

      Widget build(CategoryHistogramMode mode) => _wrap(
            CategoryHistogram(
              key: const Key('hist'),
              buckets: buckets,
              mode: mode,
              sumFormatter: (v) => v.toStringAsFixed(0),
            ),
          );

      await tester.pumpWidget(build(CategoryHistogramMode.sum));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('bar-0')));
      await tester.pump();
      expect(find.text('1000'), findsOneWidget);

      // Re-pump with count mode → tooltip resets, but tapping again uses
      // the new mode's value.
      await tester.pumpWidget(build(CategoryHistogramMode.count));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('bar-0')));
      await tester.pump();
      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('uses German month abbreviations under de locale',
        (tester) async {
      final buckets = _buckets([
        (2024, 10, 1, 100), // October -> "Okt" (de) vs "Oct" (en)
        (2024, 12, 1, 100), // December -> "Dez" (de) vs "Dec" (en)
      ]);

      await tester.pumpWidget(_wrap(
        CategoryHistogram(
          buckets: buckets,
          mode: CategoryHistogramMode.sum,
          sumFormatter: (v) => v.toStringAsFixed(0),
        ),
        locale: const Locale('de'),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Okt'), findsOneWidget);
      expect(find.text('Dez'), findsOneWidget);
      // English forms must NOT appear.
      expect(find.text('Oct'), findsNothing);
      expect(find.text('Dec'), findsNothing);
    });

    testWidgets('uses English month abbreviations under en locale',
        (tester) async {
      final buckets = _buckets([
        (2024, 10, 1, 100),
      ]);

      await tester.pumpWidget(_wrap(
        CategoryHistogram(
          buckets: buckets,
          mode: CategoryHistogramMode.sum,
          sumFormatter: (v) => v.toStringAsFixed(0),
        ),
        locale: const Locale('en'),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Oct'), findsOneWidget);
      expect(find.text('Okt'), findsNothing);
    });
  });
}
