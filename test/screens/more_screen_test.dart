import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xfin/providers/theme_provider.dart';
import 'package:xfin/screens/more_screen.dart';
import 'package:xfin/screens/settings_screen.dart';

void main() {
  late ThemeProvider themeProvider;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    themeProvider = ThemeProvider();
    await themeProvider.loadTheme();
  });

  Future<void> pumpMoreScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: themeProvider,
        child: const MaterialApp(home: MoreScreen()),
      ),
    );
  }

  testWidgets('MoreScreen has a title and a settings card', (WidgetTester tester) async {
    await pumpMoreScreen(tester);

    // Verify the app bar title.
    expect(find.text('Mehr'), findsOneWidget);

    // Verify the settings card is present.
    expect(find.widgetWithText(Card, 'Einstellungen'), findsOneWidget);

    // Verify the settings icon is present.
    expect(find.byIcon(Icons.settings), findsOneWidget);
  });

  testWidgets('Tapping settings card navigates to SettingsScreen', (WidgetTester tester) async {
    await pumpMoreScreen(tester);

    // Tap the settings card.
    await tester.tap(find.widgetWithText(Card, 'Einstellungen'));
    await tester.pumpAndSettle();

    // Verify that we've navigated to the SettingsScreen.
    expect(find.byType(SettingsScreen), findsOneWidget);
  });
}
