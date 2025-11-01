import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xfin/l10n/app_localizations.dart';
import 'package:xfin/providers/language_provider.dart';
import 'package:xfin/providers/theme_provider.dart';
import 'package:xfin/screens/more_screen.dart';
import 'package:xfin/screens/settings_screen.dart';

void main() {
  late ThemeProvider themeProvider;
  late LanguageProvider languageProvider;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    themeProvider = ThemeProvider();
    languageProvider = LanguageProvider();
    await themeProvider.loadTheme();
    await languageProvider.loadLocale();
  });

  Future<void> pumpMoreScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: themeProvider),
          ChangeNotifierProvider.value(value: languageProvider),
        ],
        child: Consumer<LanguageProvider>(
          builder: (context, languageProvider, child) {
            return MaterialApp(
              locale: languageProvider.appLocale,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: AppLocalizations.supportedLocales,
              home: const MoreScreen(),
            );
          },
        ),
      ),
    );
  }

  testWidgets('MoreScreen has a title and a settings card', (WidgetTester tester) async {
    await pumpMoreScreen(tester);

    // Verify the app bar title.
    expect(find.text('More'), findsOneWidget);

    // Verify the settings card is present.
    expect(find.widgetWithText(Card, 'Settings'), findsOneWidget);

    // Verify the settings icon is present.
    expect(find.byIcon(Icons.settings), findsOneWidget);
  });

  testWidgets('Tapping settings card navigates to SettingsScreen', (WidgetTester tester) async {
    await pumpMoreScreen(tester);

    // Tap the settings card.
    await tester.tap(find.widgetWithText(Card, 'Settings'));
    await tester.pumpAndSettle();

    // Verify that we've navigated to the SettingsScreen.
    expect(find.byType(SettingsScreen), findsOneWidget);
  });
}
