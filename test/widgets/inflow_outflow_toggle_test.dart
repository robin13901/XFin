import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xfin/widgets/inflow_outflow_toggle.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Helper to pump the toggle widget inside a MaterialApp with a given theme.
  Future<void> pumpToggle(
    WidgetTester tester, {
    required bool showInflows,
    Brightness brightness = Brightness.light,
    ValueChanged<bool>? onChanged,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: brightness == Brightness.dark
            ? ThemeData.dark()
            : ThemeData.light(),
        home: Scaffold(
          body: InflowOutflowToggle(
            showInflows: showInflows,
            inflowLabel: 'Inflows',
            outflowLabel: 'Outflows',
            onChanged: onChanged ?? (_) {},
          ),
        ),
      ),
    );
  }

  group('InflowOutflowToggle', () {
    testWidgets('renders both inflow and outflow labels', (tester) async {
      await pumpToggle(tester, showInflows: true);

      expect(find.text('Inflows'), findsOneWidget);
      expect(find.text('Outflows'), findsOneWidget);
    });

    testWidgets('renders with custom labels', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InflowOutflowToggle(
              showInflows: true,
              inflowLabel: 'Income',
              outflowLabel: 'Expense',
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Income'), findsOneWidget);
      expect(find.text('Expense'), findsOneWidget);
    });

    testWidgets('inflow segment is selected when showInflows is true (light)',
        (tester) async {
      await pumpToggle(tester, showInflows: true, brightness: Brightness.light);

      final animatedContainers =
          tester.widgetList<AnimatedContainer>(find.byType(AnimatedContainer));
      expect(animatedContainers.length, 2);

      // First segment (inflow) should have black (light theme selected color)
      final inflowContainer = animatedContainers.first;
      final inflowDecoration =
          inflowContainer.decoration as BoxDecoration;
      expect(inflowDecoration.color, Colors.black.withAlpha(15));

      // Second segment (outflow) should be transparent
      final outflowContainer = animatedContainers.last;
      final outflowDecoration =
          outflowContainer.decoration as BoxDecoration;
      expect(outflowDecoration.color, Colors.transparent);
    });

    testWidgets('inflow segment is selected when showInflows is true (dark)',
        (tester) async {
      await pumpToggle(tester, showInflows: true, brightness: Brightness.dark);

      final animatedContainers =
          tester.widgetList<AnimatedContainer>(find.byType(AnimatedContainer));
      expect(animatedContainers.length, 2);

      // First segment (inflow) should have white38 (dark theme selected color)
      final inflowContainer = animatedContainers.first;
      final inflowDecoration =
          inflowContainer.decoration as BoxDecoration;
      expect(inflowDecoration.color, Colors.white.withAlpha(15));

      // Second segment (outflow) should be transparent
      final outflowContainer = animatedContainers.last;
      final outflowDecoration =
          outflowContainer.decoration as BoxDecoration;
      expect(outflowDecoration.color, Colors.transparent);
    });

    testWidgets('outflow segment is selected when showInflows is false (light)',
        (tester) async {
      await pumpToggle(tester, showInflows: false, brightness: Brightness.light);

      final animatedContainers =
          tester.widgetList<AnimatedContainer>(find.byType(AnimatedContainer));
      expect(animatedContainers.length, 2);

      // First segment (inflow) should be transparent
      final inflowContainer = animatedContainers.first;
      final inflowDecoration =
          inflowContainer.decoration as BoxDecoration;
      expect(inflowDecoration.color, Colors.transparent);

      // Second segment (outflow) should have black (light theme selected color)
      final outflowContainer = animatedContainers.last;
      final outflowDecoration =
          outflowContainer.decoration as BoxDecoration;
      expect(outflowDecoration.color, Colors.black.withAlpha(15));
    });

    testWidgets('outflow segment is selected when showInflows is false (dark)',
        (tester) async {
      await pumpToggle(tester, showInflows: false, brightness: Brightness.dark);

      final animatedContainers =
          tester.widgetList<AnimatedContainer>(find.byType(AnimatedContainer));
      expect(animatedContainers.length, 2);

      // First segment (inflow) should be transparent
      final inflowContainer = animatedContainers.first;
      final inflowDecoration =
          inflowContainer.decoration as BoxDecoration;
      expect(inflowDecoration.color, Colors.transparent);

      // Second segment (outflow) should have white38 (dark theme selected color)
      final outflowContainer = animatedContainers.last;
      final outflowDecoration =
          outflowContainer.decoration as BoxDecoration;
      expect(outflowDecoration.color, Colors.white.withAlpha(15));
    });

    testWidgets('tapping inflow segment calls onChanged with true',
        (tester) async {
      bool? receivedValue;

      await pumpToggle(
        tester,
        showInflows: false,
        onChanged: (value) => receivedValue = value,
      );

      await tester.tap(find.text('Inflows'));
      await tester.pumpAndSettle();

      expect(receivedValue, isTrue);
    });

    testWidgets('tapping outflow segment calls onChanged with false',
        (tester) async {
      bool? receivedValue;

      await pumpToggle(
        tester,
        showInflows: true,
        onChanged: (value) => receivedValue = value,
      );

      await tester.tap(find.text('Outflows'));
      await tester.pumpAndSettle();

      expect(receivedValue, isFalse);
    });

    testWidgets('selected text color is black in light theme', (tester) async {
      await pumpToggle(tester, showInflows: true, brightness: Brightness.light);

      final inflowText = tester.widget<Text>(find.text('Inflows'));
      expect(inflowText.style?.color, Colors.black);
    });

    testWidgets('selected text color is white in dark theme', (tester) async {
      await pumpToggle(tester, showInflows: true, brightness: Brightness.dark);

      final inflowText = tester.widget<Text>(find.text('Inflows'));
      expect(inflowText.style?.color, Colors.white);
    });

    testWidgets('unselected text color comes from theme', (tester) async {
      await pumpToggle(tester, showInflows: true);

      // Outflow text should use theme color (not white)
      final outflowText = tester.widget<Text>(find.text('Outflows'));
      expect(outflowText.style?.color, isNot(Colors.white));
    });

    testWidgets('text uses bold font weight', (tester) async {
      await pumpToggle(tester, showInflows: true);

      final inflowText = tester.widget<Text>(find.text('Inflows'));
      expect(inflowText.style?.fontWeight, FontWeight.w700);

      final outflowText = tester.widget<Text>(find.text('Outflows'));
      expect(outflowText.style?.fontWeight, FontWeight.w700);
    });

    group('light theme', () {
      testWidgets('uses black border color', (tester) async {
        await pumpToggle(tester, showInflows: true, brightness: Brightness.light);

        // The outer Container has the border
        final container = tester.widget<Container>(
          find.ancestor(
            of: find.byType(Row),
            matching: find.byType(Container),
          ).first,
        );
        final decoration = container.decoration as BoxDecoration;
        expect(decoration.border, isNotNull);
        final border = decoration.border as Border;
        expect(border.top.color, Colors.black);
      });

      testWidgets('uses white unselected fill', (tester) async {
        await pumpToggle(tester, showInflows: true, brightness: Brightness.light);

        final container = tester.widget<Container>(
          find.ancestor(
            of: find.byType(Row),
            matching: find.byType(Container),
          ).first,
        );
        final decoration = container.decoration as BoxDecoration;
        expect(decoration.color, Colors.white);
      });
    });

    group('dark theme', () {
      testWidgets('uses white border color', (tester) async {
        await pumpToggle(tester, showInflows: true, brightness: Brightness.dark);

        final container = tester.widget<Container>(
          find.ancestor(
            of: find.byType(Row),
            matching: find.byType(Container),
          ).first,
        );
        final decoration = container.decoration as BoxDecoration;
        expect(decoration.border, isNotNull);
        final border = decoration.border as Border;
        expect(border.top.color, Colors.white);
      });

      testWidgets('uses dark unselected fill (0xFF151515)', (tester) async {
        await pumpToggle(tester, showInflows: true, brightness: Brightness.dark);

        final container = tester.widget<Container>(
          find.ancestor(
            of: find.byType(Row),
            matching: find.byType(Container),
          ).first,
        );
        final decoration = container.decoration as BoxDecoration;
        expect(decoration.color, const Color(0xFF151515));
      });
    });

    testWidgets('outer container has border radius of 10', (tester) async {
      await pumpToggle(tester, showInflows: true);

      final container = tester.widget<Container>(
        find.ancestor(
          of: find.byType(Row),
          matching: find.byType(Container),
        ).first,
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.borderRadius, BorderRadius.circular(10));
    });

    testWidgets('segment containers have border radius of 8', (tester) async {
      await pumpToggle(tester, showInflows: true);

      final animatedContainers =
          tester.widgetList<AnimatedContainer>(find.byType(AnimatedContainer));

      for (final container in animatedContainers) {
        final decoration = container.decoration as BoxDecoration;
        expect(decoration.borderRadius, BorderRadius.circular(8));
      }
    });

    testWidgets('border width is 1.1', (tester) async {
      await pumpToggle(tester, showInflows: true);

      final container = tester.widget<Container>(
        find.ancestor(
          of: find.byType(Row),
          matching: find.byType(Container),
        ).first,
      );
      final decoration = container.decoration as BoxDecoration;
      final border = decoration.border as Border;
      expect(border.top.width, 1.1);
    });

    testWidgets('animation duration is 180ms', (tester) async {
      await pumpToggle(tester, showInflows: true);

      final animatedContainers =
          tester.widgetList<AnimatedContainer>(find.byType(AnimatedContainer));

      for (final container in animatedContainers) {
        expect(container.duration, const Duration(milliseconds: 180));
      }
    });

    testWidgets('segments have vertical padding of 12', (tester) async {
      await pumpToggle(tester, showInflows: true);

      final animatedContainers =
          tester.widgetList<AnimatedContainer>(find.byType(AnimatedContainer));

      for (final container in animatedContainers) {
        expect(
          container.padding,
          const EdgeInsets.symmetric(vertical: 12),
        );
      }
    });

    testWidgets('contains two Expanded widgets for equal sizing',
        (tester) async {
      await pumpToggle(tester, showInflows: true);

      expect(find.byType(Expanded), findsNWidgets(2));
    });

    testWidgets('contains two GestureDetectors for tap handling',
        (tester) async {
      await pumpToggle(tester, showInflows: true);

      expect(find.byType(GestureDetector), findsNWidgets(2));
    });

    testWidgets('labels are centered', (tester) async {
      await pumpToggle(tester, showInflows: true);

      // Each segment wraps its Text in a Center widget
      expect(find.byType(Center), findsNWidgets(2));
    });
  });
}
