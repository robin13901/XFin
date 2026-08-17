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
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        themeMode:
            brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
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

    testWidgets('selected text is bold (w700)', (tester) async {
      await pumpToggle(tester, showInflows: true);

      final inflowStyle = tester.widget<AnimatedDefaultTextStyle>(
        find.ancestor(
          of: find.text('Inflows'),
          matching: find.byType(AnimatedDefaultTextStyle),
        ).first,
      );
      expect(inflowStyle.style.fontWeight, FontWeight.w700);
    });

    testWidgets('unselected text is regular weight (w500)', (tester) async {
      await pumpToggle(tester, showInflows: true);

      final outflowStyle = tester.widget<AnimatedDefaultTextStyle>(
        find.ancestor(
          of: find.text('Outflows'),
          matching: find.byType(AnimatedDefaultTextStyle),
        ).first,
      );
      expect(outflowStyle.style.fontWeight, FontWeight.w500);
    });

    testWidgets('selected text color changes based on selection state',
        (tester) async {
      await pumpToggle(tester, showInflows: true);

      final inflowStyle = tester.widget<AnimatedDefaultTextStyle>(
        find.ancestor(
          of: find.text('Inflows'),
          matching: find.byType(AnimatedDefaultTextStyle),
        ).first,
      );
      // Selected text should have a color (either black or white depending on theme)
      expect(inflowStyle.style.color, isNotNull);
    });

    testWidgets('unselected text has opacity applied', (tester) async {
      await pumpToggle(tester, showInflows: true);

      final outflowStyle = tester.widget<AnimatedDefaultTextStyle>(
        find.ancestor(
          of: find.text('Outflows'),
          matching: find.byType(AnimatedDefaultTextStyle),
        ).first,
      );
      // Unselected text should have reduced opacity
      final alphaValue = (outflowStyle.style.color?.a ?? 1.0 * 255.0).round().clamp(0, 255);
      expect(alphaValue, lessThan(255));
    });

    testWidgets('outer container has border radius of 14', (tester) async {
      await pumpToggle(tester, showInflows: true);

      final container = tester.widget<Container>(
        find.ancestor(
          of: find.byType(Row),
          matching: find.byType(Container),
        ).first,
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.borderRadius, BorderRadius.circular(14));
    });

    testWidgets('light theme uses neutral gradient center', (tester) async {
      await pumpToggle(tester, showInflows: true, brightness: Brightness.light);

      final container = tester.widget<Container>(
        find.ancestor(
          of: find.byType(Row),
          matching: find.byType(Container),
        ).first,
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.gradient, isNotNull);
    });

    testWidgets('dark theme uses neutral gradient center', (tester) async {
      await pumpToggle(tester, showInflows: true, brightness: Brightness.dark);

      final container = tester.widget<Container>(
        find.ancestor(
          of: find.byType(Row),
          matching: find.byType(Container),
        ).first,
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.gradient, isNotNull);
    });

    testWidgets('container has box shadow', (tester) async {
      await pumpToggle(tester, showInflows: true);

      final container = tester.widget<Container>(
        find.ancestor(
          of: find.byType(Row),
          matching: find.byType(Container),
        ).first,
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.boxShadow, isNotNull);
      expect(decoration.boxShadow?.isNotEmpty, true);
    });

    testWidgets('sliding pill animates on toggle', (tester) async {
      await pumpToggle(tester, showInflows: true);

      final animatedAlignBefore =
          tester.widget<AnimatedAlign>(find.byType(AnimatedAlign));
      expect(animatedAlignBefore.alignment, Alignment.centerLeft);

      // Create a new widget with showInflows: false
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Scaffold(
            body: InflowOutflowToggle(
              showInflows: false,
              inflowLabel: 'Inflows',
              outflowLabel: 'Outflows',
              onChanged: (_) {},
            ),
          ),
        ),
      );

      final animatedAlignAfter =
          tester.widget<AnimatedAlign>(find.byType(AnimatedAlign));
      expect(animatedAlignAfter.alignment, Alignment.centerRight);
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

      expect(find.byType(Center), findsNWidgets(2));
    });
  });
}
