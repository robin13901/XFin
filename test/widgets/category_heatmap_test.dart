import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:xfin/database/models/analysis_models.dart';
import 'package:xfin/widgets/category_heatmap.dart';
import 'package:xfin/widgets/category_histogram.dart' show CategoryHistogramMode;

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: SizedBox(width: 360, child: child),
    ),
  );
}

void main() {
  group('CategoryHeatmap', () {
    testWidgets('renders placeholder when no daily buckets', (tester) async {
      await tester.pumpWidget(_wrap(
        CategoryHeatmap(
          dailyBuckets: const {},
          earliestDate: null,
          endDate: DateTime(2024, 6, 30),
          mode: CategoryHistogramMode.sum,
        ),
      ));

      expect(find.text('—'), findsOneWidget);
    });

    testWidgets('renders month labels for the displayed range', (tester) async {
      final dailyBuckets = <int, CategoryDayBucket>{
        20240115:
            const CategoryDayBucket(dateInt: 20240115, count: 1, sum: 10.0),
        20240220:
            const CategoryDayBucket(dateInt: 20240220, count: 1, sum: 20.0),
        20240310:
            const CategoryDayBucket(dateInt: 20240310, count: 1, sum: 30.0),
      };

      await tester.pumpWidget(_wrap(
        CategoryHeatmap(
          dailyBuckets: dailyBuckets,
          earliestDate: DateTime(2024, 1, 15),
          endDate: DateTime(2024, 3, 15),
          mode: CategoryHistogramMode.sum,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Jan'), findsOneWidget);
      expect(find.text('Feb'), findsOneWidget);
      expect(find.text('Mar'), findsOneWidget);
    });

    testWidgets('rebuilds without errors when mode changes', (tester) async {
      final dailyBuckets = <int, CategoryDayBucket>{
        20240115:
            const CategoryDayBucket(dateInt: 20240115, count: 5, sum: 100.0),
      };

      Widget build(CategoryHistogramMode mode) => _wrap(
            CategoryHeatmap(
              key: const Key('heatmap'),
              dailyBuckets: dailyBuckets,
              earliestDate: DateTime(2024, 1, 15),
              endDate: DateTime(2024, 1, 31),
              mode: mode,
            ),
          );

      await tester.pumpWidget(build(CategoryHistogramMode.sum));
      await tester.pumpAndSettle();

      await tester.pumpWidget(build(CategoryHistogramMode.count));
      await tester.pumpAndSettle();

      // Sanity: still rendered, no thrown exceptions.
      expect(find.byType(CategoryHeatmap), findsOneWidget);
    });
  });
}
