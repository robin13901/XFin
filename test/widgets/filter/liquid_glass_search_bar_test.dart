import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xfin/widgets/filter/liquid_glass_search_bar.dart';

void main() {
  group('LiquidGlassSearchBar', () {
    late TextEditingController controller;
    String lastChangedValue = '';

    setUp(() {
      controller = TextEditingController();
      lastChangedValue = '';
    });

    tearDown(() {
      controller.dispose();
    });

    Widget buildTestWidget() {
      return MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: LiquidGlassSearchBar(
              controller: controller,
              hintText: 'Search...',
              onChanged: (value) => lastChangedValue = value,
            ),
          ),
        ),
      );
    }

    testWidgets('displays hint text', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.text('Search...'), findsOneWidget);
    });

    testWidgets('calls onChanged when text is entered', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      await tester.enterText(find.byType(TextField), 'test query');
      await tester.pump();

      expect(lastChangedValue, 'test query');
    });

    testWidgets('shows clear button when text is present', (tester) async {
      controller.text = 'some text';
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.byIcon(Icons.clear), findsOneWidget);
    });

    testWidgets('clears text and calls onChanged when clear is tapped',
        (tester) async {
      controller.text = 'some text';
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      await tester.tap(find.byIcon(Icons.clear));
      await tester.pump();

      expect(controller.text, '');
      expect(lastChangedValue, '');
    });

    testWidgets('has search icon', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('has TextCapitalization.words', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.textCapitalization, TextCapitalization.words);
    });

    testWidgets('hides clear button when text is empty', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.byIcon(Icons.clear), findsNothing);
    });

    testWidgets('uses custom focusNode when provided', (tester) async {
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: LiquidGlassSearchBar(
                controller: controller,
                hintText: 'Search...',
                onChanged: (value) => lastChangedValue = value,
                focusNode: focusNode,
              ),
            ),
          ),
        ),
      );

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.focusNode, same(focusNode));
    });
  });
}
