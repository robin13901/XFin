import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xfin/widgets/category_widgets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CategoryDisplayData', () {
    test('creates instance with correct properties', () {

      const data = CategoryDisplayData(
        entries: [
          MapEntry('Category1', 100.0),
          MapEntry('Category2', 50.0),
        ],
        totalAmount: 150.0,
        hasOther: true,
      );

      expect(data.entries.length, 2);
      expect(data.totalAmount, 150.0);
      expect(data.hasOther, true);
    });

    test('creates instance with empty entries', () {
      const data = CategoryDisplayData(
        entries: [],
        totalAmount: 0.0,
        hasOther: false,
      );

      expect(data.entries.isEmpty, true);
      expect(data.totalAmount, 0.0);
      expect(data.hasOther, false);
    });
  });

  group('calculateCategoryData', () {
    test('calculates data correctly with normal categories', () {
      final categories = {
        'Food': 100.0,
        'Transport': 50.0,
        'Entertainment': 30.0,
      };

      final result = calculateCategoryData(
        categories: categories,
        showAllCategories: false,
      );

      expect(result.totalAmount, 180.0);
      expect(result.entries.length, 3);
      expect(result.entries[0].key, 'Food'); // Sorted by value
      expect(result.entries[1].key, 'Transport');
      expect(result.entries[2].key, 'Entertainment');
    });

    test('aggregates categories below 1% into "..." when not showing all', () {
      final categories = {
        'Major': 990.0,
        'Minor1': 5.0, // 0.5% - should be aggregated
        'Minor2': 3.0, // 0.3% - should be aggregated
        'Minor3': 2.0, // 0.2% - should be aggregated
      };

      final result = calculateCategoryData(
        categories: categories,
        showAllCategories: false,
      );

      expect(result.totalAmount, 1000.0);
      expect(result.entries.length, 2); // Major + "..."
      expect(result.entries[0].key, 'Major');
      expect(result.entries[1].key, '...');
      expect(result.entries[1].value, 10.0);
      expect(result.hasOther, true);
    });

    test('shows all categories when showAllCategories is true', () {
      final categories = {
        'Major': 990.0,
        'Minor1': 5.0,
        'Minor2': 3.0,
        'Minor3': 2.0,
      };

      final result = calculateCategoryData(
        categories: categories,
        showAllCategories: true,
      );

      expect(result.entries.length, 4);
      expect(result.hasOther, false);
      expect(result.entries.any((e) => e.key == '...'), false);
    });

    test('handles empty categories map', () {
      final result = calculateCategoryData(
        categories: {},
        showAllCategories: false,
      );

      expect(result.totalAmount, 0.0);
      expect(result.entries.isEmpty, true);
      expect(result.hasOther, false);
    });

    test('handles negative values correctly', () {
      final categories = {
        'Income': 1000.0,
        'Expense': -500.0,
      };

      final result = calculateCategoryData(
        categories: categories,
        showAllCategories: false,
      );

      expect(result.totalAmount, 1500.0); // Sum of absolute values
      expect(result.entries.length, 2);
    });

    test('sorts categories by absolute value descending', () {
      final categories = {
        'Small': 10.0,
        'Large': 100.0,
        'Medium': 50.0,
      };

      final result = calculateCategoryData(
        categories: categories,
        showAllCategories: true,
      );

      expect(result.entries[0].key, 'Large');
      expect(result.entries[1].key, 'Medium');
      expect(result.entries[2].key, 'Small');
    });

    test('handles all small equal-value categories', () {
      final categories = {
        'Tiny1': 1.0,
        'Tiny2': 1.0,
        'Tiny3': 1.0,
      };

      final result = calculateCategoryData(
        categories: categories,
        showAllCategories: false,
      );

      // Each category is 33.3% of total, so all are shown (not below 1%)
      expect(result.totalAmount, 3.0);
      expect(result.entries.length, 3);
      expect(result.hasOther, false);
    });

    test('does not add "..." when aggregated amount is zero', () {
      final categories = {
        'Category': 100.0,
      };

      final result = calculateCategoryData(
        categories: categories,
        showAllCategories: false,
      );

      expect(result.entries.length, 1);
      expect(result.entries.any((e) => e.key == '...'), false);
      expect(result.hasOther, false);
    });

    test('handles exactly 1% threshold category', () {
      final categories = {
        'Major': 99.0,
        'Exactly1Percent': 1.0, // Exactly 1%
      };

      final result = calculateCategoryData(
        categories: categories,
        showAllCategories: false,
      );

      // At exactly 1%, should be included (not aggregated)
      expect(result.entries.length, 2);
      expect(result.entries.any((e) => e.key == 'Exactly1Percent'), true);
    });
  });

  group('CategoryPieChart', () {
    testWidgets('renders pie chart with valid data', (tester) async {
      const data = CategoryDisplayData(
        entries: [
          MapEntry('Food', 100.0),
          MapEntry('Transport', 50.0),
        ],
        totalAmount: 150.0,
        hasOther: false,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CategoryPieChart(data: data),
          ),
        ),
      );

      expect(find.byType(CategoryPieChart), findsOneWidget);
      // PieChart widget should be present
      final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox));
      expect(sizedBox.height, 220);
    });

    testWidgets('renders nothing when data is empty', (tester) async {
      const data = CategoryDisplayData(
        entries: [],
        totalAmount: 0.0,
        hasOther: false,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CategoryPieChart(data: data),
          ),
        ),
      );

      // Should render SizedBox.shrink()
      final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox));
      expect(sizedBox.width, 0.0);
      expect(sizedBox.height, 0.0);
    });

    testWidgets('renders with single category', (tester) async {
      const data = CategoryDisplayData(
        entries: [MapEntry('Only', 100.0)],
        totalAmount: 100.0,
        hasOther: false,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CategoryPieChart(data: data),
          ),
        ),
      );

      expect(find.byType(CategoryPieChart), findsOneWidget);
    });

    testWidgets('renders with many categories', (tester) async {
      const data = CategoryDisplayData(
        entries: [
          MapEntry('Cat1', 100.0),
          MapEntry('Cat2', 90.0),
          MapEntry('Cat3', 80.0),
          MapEntry('Cat4', 70.0),
          MapEntry('Cat5', 60.0),
        ],
        totalAmount: 400.0,
        hasOther: false,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CategoryPieChart(data: data),
          ),
        ),
      );

      expect(find.byType(CategoryPieChart), findsOneWidget);
    });
  });

  group('CategoryList', () {
    testWidgets('renders list with valid data', (tester) async {
      const data = CategoryDisplayData(
        entries: [
          MapEntry('Food', 100.0),
          MapEntry('Transport', 50.0),
        ],
        totalAmount: 150.0,
        hasOther: false,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CategoryList(
              data: data,
              noCategoriesMessage: 'No data',
              showAllLabel: 'Show all',
              showLessLabel: 'Show less',
            ),
          ),
        ),
      );

      expect(find.byType(CategoryListItem), findsNWidgets(2));
    });

    testWidgets('shows no categories message when data is empty', (tester) async {
      const data = CategoryDisplayData(
        entries: [],
        totalAmount: 0.0,
        hasOther: false,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CategoryList(
              data: data,
              noCategoriesMessage: 'No data available',
              showAllLabel: 'Show all',
              showLessLabel: 'Show less',
            ),
          ),
        ),
      );

      expect(find.text('No data available'), findsOneWidget);
      expect(find.byType(CategoryListItem), findsNothing);
    });

    testWidgets('shows "Show all" button when hasOther is true', (tester) async {
      const data = CategoryDisplayData(
        entries: [
          MapEntry('Major', 100.0),
          MapEntry('...', 10.0),
        ],
        totalAmount: 110.0,
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
              onShowAllChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Show all'), findsOneWidget);
      expect(find.text('Show less'), findsNothing);
    });

    testWidgets('shows "Show less" button when hasOther is false and callback provided', (tester) async {
      const data = CategoryDisplayData(
        entries: [
          MapEntry('Cat1', 100.0),
          MapEntry('Cat2', 50.0),
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
              onShowAllChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Show less'), findsOneWidget);
      expect(find.text('Show all'), findsNothing);
    });

    testWidgets('calls onShowAllChanged(true) when "Show all" tapped', (tester) async {
      const data = CategoryDisplayData(
        entries: [
          MapEntry('Major', 100.0),
          MapEntry('...', 10.0),
        ],
        totalAmount: 110.0,
        hasOther: true,
      );

      bool? capturedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryList(
              data: data,
              noCategoriesMessage: 'No data',
              showAllLabel: 'Show all',
              showLessLabel: 'Show less',
              onShowAllChanged: (value) {
                capturedValue = value;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show all'));
      await tester.pumpAndSettle();

      expect(capturedValue, true);
    });

    testWidgets('calls onShowAllChanged(false) when "Show less" tapped', (tester) async {
      const data = CategoryDisplayData(
        entries: [
          MapEntry('Cat1', 100.0),
          MapEntry('Cat2', 50.0),
        ],
        totalAmount: 150.0,
        hasOther: false,
      );

      bool? capturedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryList(
              data: data,
              noCategoriesMessage: 'No data',
              showAllLabel: 'Show all',
              showLessLabel: 'Show less',
              onShowAllChanged: (value) {
                capturedValue = value;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show less'));
      await tester.pumpAndSettle();

      expect(capturedValue, false);
    });

    testWidgets('does not show buttons when onShowAllChanged is null', (tester) async {
      const data = CategoryDisplayData(
        entries: [
          MapEntry('Cat1', 100.0),
          MapEntry('...', 10.0),
        ],
        totalAmount: 110.0,
        hasOther: true,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CategoryList(
              data: data,
              noCategoriesMessage: 'No data',
              showAllLabel: 'Show all',
              showLessLabel: 'Show less',
            ),
          ),
        ),
      );

      expect(find.text('Show all'), findsNothing);
      expect(find.text('Show less'), findsNothing);
    });
  });

  group('CategoryListItem', () {
    testWidgets('renders category name, amount, and percentage', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CategoryListItem(
              category: 'Food',
              amount: 150.50,
              percentage: 33.5,
              color: Colors.blue,
            ),
          ),
        ),
      );

      expect(find.text('Food'), findsOneWidget);
      expect(find.text('150.50'), findsOneWidget);
      expect(find.text('33.5%'), findsOneWidget);
    });

    testWidgets('renders color indicator with correct color', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CategoryListItem(
              category: 'Test',
              amount: 100.0,
              percentage: 50.0,
              color: Colors.red,
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(CategoryListItem),
          matching: find.byType(Container),
        ).first,
      );

      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, Colors.red);
      expect(decoration.shape, BoxShape.circle);
    });

    testWidgets('renders with zero percentage', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CategoryListItem(
              category: 'Empty',
              amount: 0.0,
              percentage: 0.0,
              color: Colors.grey,
            ),
          ),
        ),
      );

      expect(find.text('Empty'), findsOneWidget);
      expect(find.text('0.00'), findsOneWidget);
      expect(find.text('0.0%'), findsOneWidget);
    });

    testWidgets('renders with 100 percentage', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CategoryListItem(
              category: 'All',
              amount: 1000.0,
              percentage: 100.0,
              color: Colors.green,
            ),
          ),
        ),
      );

      expect(find.text('All'), findsOneWidget);
      expect(find.text('1000.00'), findsOneWidget);
      expect(find.text('100.0%'), findsOneWidget);
    });

    testWidgets('renders with negative amount', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CategoryListItem(
              category: 'Refund',
              amount: -50.0,
              percentage: 10.0,
              color: Colors.orange,
            ),
          ),
        ),
      );

      expect(find.text('Refund'), findsOneWidget);
      expect(find.text('-50.00'), findsOneWidget);
      expect(find.text('10.0%'), findsOneWidget);
    });

    testWidgets('renders with very small percentage', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CategoryListItem(
              category: 'Tiny',
              amount: 0.01,
              percentage: 0.05,
              color: Colors.purple,
            ),
          ),
        ),
      );

      expect(find.text('Tiny'), findsOneWidget);
      expect(find.text('0.01'), findsOneWidget);
      expect(find.text('0.1%'), findsOneWidget); // Formatted to 1 decimal
    });

    testWidgets('has correct layout structure', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CategoryListItem(
              category: 'Test',
              amount: 100.0,
              percentage: 50.0,
              color: Colors.blue,
            ),
          ),
        ),
      );

      // Check padding
      final padding = tester.widget<Padding>(find.byType(Padding).first);
      expect(padding.padding, const EdgeInsets.symmetric(vertical: 4));

      // Check main row layout
      final mainRow = tester.widget<Row>(
        find.descendant(
          of: find.byType(Padding),
          matching: find.byType(Row),
        ).first,
      );
      expect(mainRow.mainAxisAlignment, MainAxisAlignment.spaceBetween);
    });

    testWidgets('color indicator has correct size', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CategoryListItem(
              category: 'Test',
              amount: 100.0,
              percentage: 50.0,
              color: Colors.blue,
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(CategoryListItem),
          matching: find.byType(Container),
        ).first,
      );

      expect(container.constraints?.minWidth, 10);
      expect(container.constraints?.minHeight, 10);
    });

    testWidgets('category name is expandable in layout', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CategoryListItem(
              category: 'Very Long Category Name That Should Wrap',
              amount: 100.0,
              percentage: 50.0,
              color: Colors.blue,
            ),
          ),
        ),
      );

      expect(find.text('Very Long Category Name That Should Wrap'), findsOneWidget);
      expect(find.byType(Expanded), findsAtLeastNWidgets(1));
    });

    testWidgets('percentage text has hint color', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(hintColor: Colors.grey),
          home: const Scaffold(
            body: CategoryListItem(
              category: 'Test',
              amount: 100.0,
              percentage: 50.0,
              color: Colors.blue,
            ),
          ),
        ),
      );

      final percentageText = tester.widget<Text>(find.text('50.0%'));
      expect(percentageText.style?.color, Colors.grey);
    });
  });
}
