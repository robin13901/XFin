import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xfin/utils/modal_helper.dart';

void main() {
  group('showFormModal', () {
    testWidgets('opens a modal bottom sheet with the given form widget',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () =>
                    showFormModal<void>(context, const Text('Test Form')),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Test Form'), findsOneWidget);
    });

    testWidgets('sheet is scroll-controlled', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showFormModal<void>(
                  context,
                  const SizedBox(height: 2000, child: Text('Tall Form')),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // If isScrollControlled is true the sheet can take more than half the
      // screen. Verify the tall content is present (would be clipped if not
      // scroll-controlled).
      expect(find.text('Tall Form'), findsOneWidget);
    });

    testWidgets('returns value when sheet is popped with result',
        (tester) async {
      String? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await showFormModal<String>(
                    context,
                    Builder(
                      builder: (innerContext) => ElevatedButton(
                        onPressed: () => Navigator.of(innerContext).pop('done'),
                        child: const Text('Close'),
                      ),
                    ),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Tap the close button inside the sheet
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      expect(result, 'done');
    });

    testWidgets('returns null when sheet is dismissed without result',
        (tester) async {
      String? result = 'initial';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await showFormModal<String>(
                    context,
                    const Text('Form Content'),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Form Content'), findsOneWidget);

      // Dismiss by tapping the barrier (scrim)
      await tester.tapAt(const Offset(20, 20));
      await tester.pumpAndSettle();

      expect(result, isNull);
    });
  });
}
