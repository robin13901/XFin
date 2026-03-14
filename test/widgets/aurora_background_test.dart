import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xfin/widgets/aurora_background.dart';

void main() {
  group('AuroraBackground', () {
    testWidgets('renders without errors with default parameters',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: AuroraBackground()),
        ),
      );

      expect(find.byType(AuroraBackground), findsOneWidget);
      expect(find.byType(RepaintBoundary), findsWidgets);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('renders with custom colours and parameters',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuroraBackground(
              colors: [Colors.red, Colors.green, Colors.blue],
              speed: 2.0,
              opacity: 0.5,
            ),
          ),
        ),
      );

      expect(find.byType(AuroraBackground), findsOneWidget);

      final opacityWidget = tester.widget<Opacity>(find.byType(Opacity));
      expect(opacityWidget.opacity, 0.5);
    });

    testWidgets('no ImageFiltered widget (soft gradients, no blur pass)',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: AuroraBackground()),
        ),
      );

      expect(find.byType(ImageFiltered), findsNothing);
    });

    testWidgets('animation progresses over time',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: AuroraBackground()),
        ),
      );

      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 5));

      expect(find.byType(AuroraBackground), findsOneWidget);
    });

    testWidgets('disposes animation controller without errors',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: AuroraBackground()),
        ),
      );

      await tester.pump(const Duration(seconds: 1));

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: SizedBox()),
        ),
      );

      expect(find.byType(AuroraBackground), findsNothing);
    });

    testWidgets('single colour in list works (wraps around)',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuroraBackground(colors: [Colors.teal]),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(AuroraBackground), findsOneWidget);
    });

    testWidgets('can stack child widgets on top',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                AuroraBackground(),
                Center(child: Text('Hello')),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Hello'), findsOneWidget);
      expect(find.byType(AuroraBackground), findsOneWidget);
    });
  });
}
