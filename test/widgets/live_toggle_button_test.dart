import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:xfin/l10n/app_localizations.dart';
import 'package:xfin/providers/live_price_provider.dart';
import 'package:xfin/widgets/live_toggle_button.dart';

void main() {
  group('LiveToggleButton', () {
    Widget buildTestWidget() {
      return MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en')],
        home: ChangeNotifierProvider<LivePriceProvider>.value(
          value: LivePriceProvider.instance,
          child: const Scaffold(body: LiveToggleButton()),
        ),
      );
    }

    testWidgets('renders cell_tower icon', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.cell_tower), findsOneWidget);
      expect(find.byKey(const Key('live_toggle')), findsOneWidget);
    });

    testWidgets('tapping toggle calls toggle on provider',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final iconButton = find.byKey(const Key('live_toggle'));
      expect(iconButton, findsOneWidget);

      await tester.tap(iconButton);
      await tester.pump();
    });
  });
}
