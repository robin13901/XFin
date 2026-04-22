import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:xfin/providers/live_price_provider.dart';
import 'package:xfin/widgets/live_toggle_button.dart';

void main() {
  group('LiveToggleButton', () {
    testWidgets('renders cell_tower icon', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<LivePriceProvider>.value(
            value: LivePriceProvider.instance,
            child: const Scaffold(body: LiveToggleButton()),
          ),
        ),
      );

      expect(find.byIcon(Icons.cell_tower), findsOneWidget);
      expect(find.byKey(const Key('live_toggle')), findsOneWidget);
    });

    testWidgets('tapping toggle calls toggle on provider',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<LivePriceProvider>.value(
            value: LivePriceProvider.instance,
            child: const Scaffold(body: LiveToggleButton()),
          ),
        ),
      );

      final iconButton = find.byKey(const Key('live_toggle'));
      expect(iconButton, findsOneWidget);

      await tester.tap(iconButton);
      await tester.pump();
    });
  });
}
