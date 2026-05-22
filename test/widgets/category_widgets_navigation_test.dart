import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:xfin/widgets/category_widgets.dart';

void main() {
  group('CategoryListItem onTap', () {
    testWidgets('invokes onTap callback when tapped', (tester) async {
      String? tapped;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryListItem(
              category: 'Food',
              amount: 100.0,
              percentage: 50.0,
              color: Colors.blue,
              onTap: () => tapped = 'Food',
            ),
          ),
        ),
      );

      await tester.tap(find.text('Food'));
      await tester.pumpAndSettle();

      expect(tapped, 'Food');
    });

    testWidgets('does not wrap in InkWell when onTap is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CategoryListItem(
              category: 'Food',
              amount: 100.0,
              percentage: 50.0,
              color: Colors.blue,
            ),
          ),
        ),
      );

      expect(find.byType(InkWell), findsNothing);
    });
  });

  group('CategoryList onCategoryTap', () {
    testWidgets('forwards taps on items to onCategoryTap', (tester) async {
      String? tapped;

      const data = CategoryDisplayData(
        entries: [
          MapEntry('Food', 100.0),
          MapEntry('Transport', 50.0),
        ],
        totalAmount: 150.0,
        hasOther: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryList(
              data: data,
              noCategoriesMessage: 'No data',
              showAllLabel: 'Show all',
              showLessLabel: 'Show less',
              onCategoryTap: (cat) => tapped = cat,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Transport'));
      await tester.pumpAndSettle();

      expect(tapped, 'Transport');
    });

    testWidgets('does not invoke onCategoryTap for synthetic "..." aggregator',
        (tester) async {
      String? tapped;

      const data = CategoryDisplayData(
        entries: [
          MapEntry('Major', 100.0),
          MapEntry('...', 5.0),
        ],
        totalAmount: 105.0,
        hasOther: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryList(
              data: data,
              noCategoriesMessage: 'No data',
              showAllLabel: 'Show all',
              showLessLabel: 'Show less',
              onCategoryTap: (cat) => tapped = cat,
            ),
          ),
        ),
      );

      // Tapping the "..." row must not fire the callback.
      await tester.tap(find.text('...'));
      await tester.pumpAndSettle();

      expect(tapped, isNull);

      // But tapping a real category still works.
      await tester.tap(find.text('Major'));
      await tester.pumpAndSettle();
      expect(tapped, 'Major');
    });
  });
}
