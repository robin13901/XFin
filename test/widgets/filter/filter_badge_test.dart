import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xfin/widgets/filter/filter_badge.dart';

void main() {
  group('FilterBadge', () {
    Widget buildTestWidget({required int count, Widget? child}) {
      return MaterialApp(
        home: Scaffold(
          body: FilterBadge(
            count: count,
            child: child ?? const Icon(Icons.filter_list),
          ),
        ),
      );
    }

    testWidgets('does not show badge when count is 0', (tester) async {
      await tester.pumpWidget(buildTestWidget(count: 0));

      // Should only show the child, not the badge
      expect(find.byIcon(Icons.filter_list), findsOneWidget);
      expect(find.text('0'), findsNothing);
    });

    testWidgets('shows badge with count when count > 0', (tester) async {
      await tester.pumpWidget(buildTestWidget(count: 3));

      expect(find.byIcon(Icons.filter_list), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('shows 9+ when count > 9', (tester) async {
      await tester.pumpWidget(buildTestWidget(count: 15));

      expect(find.byIcon(Icons.filter_list), findsOneWidget);
      expect(find.text('9+'), findsOneWidget);
    });

    testWidgets('badge has white background with black text', (tester) async {
      await tester.pumpWidget(buildTestWidget(count: 1));

      final container = tester.widget<Container>(
        find.ancestor(
          of: find.text('1'),
          matching: find.byType(Container),
        ).first,
      );

      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, Colors.white);

      final text = tester.widget<Text>(find.text('1'));
      expect(text.style?.color, Colors.black);
    });
  });
}
