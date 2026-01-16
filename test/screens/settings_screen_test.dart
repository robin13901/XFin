import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xfin/l10n/app_localizations.dart';
import 'package:xfin/providers/language_provider.dart';
import 'package:xfin/providers/theme_provider.dart';
import 'package:xfin/screens/settings_screen.dart';

void main() {
  group('SettingsScreen', () {
    late ThemeProvider themeProvider;
    late LanguageProvider languageProvider;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      themeProvider = ThemeProvider.instance;
      languageProvider = LanguageProvider();
      await themeProvider.loadTheme();
      await languageProvider.loadLocale();
    });

    Future<void> pumpSettingsScreen(WidgetTester tester) async {
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
                home: const SettingsScreen(),
              );
            },
          ),
        ),
      );
    }

    testWidgets('renders correctly with default settings', (WidgetTester tester) async {
      await pumpSettingsScreen(tester);

      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Theme'), findsOneWidget);
      expect(find.text('Language'), findsOneWidget);
      expect(find.text('System'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);
    });

    testWidgets('changes theme and persists it', (WidgetTester tester) async {
      await pumpSettingsScreen(tester);

      // Change to Light theme
      await tester.tap(find.text('System'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Light').last);
      await tester.pumpAndSettle();
      expect(themeProvider.themeMode, ThemeMode.light);
      expect(find.text('Light'), findsOneWidget);

      // Change to Dark theme
      await tester.tap(find.text('Light'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dark').last);
      await tester.pumpAndSettle();
      expect(themeProvider.themeMode, ThemeMode.dark);
      expect(find.text('Dark'), findsOneWidget);

      // Change back to System theme
      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('System').last);
      await tester.pumpAndSettle();
      expect(themeProvider.themeMode, ThemeMode.system);
      expect(find.text('System'), findsOneWidget);
    });

    testWidgets('changes language and persists it', (WidgetTester tester) async {
      await pumpSettingsScreen(tester);

      // Change to German
      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('German').last);
      await tester.pumpAndSettle();
      expect(languageProvider.appLocale, const Locale('de'));
      expect(find.text('Einstellungen'), findsOneWidget);
      expect(find.text('Thema'), findsOneWidget);
      expect(find.text('Sprache'), findsOneWidget);

      // Change back to English
      await tester.tap(find.text('Deutsch'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Englisch').last);
      await tester.pumpAndSettle();
      expect(languageProvider.appLocale, const Locale('en'));
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Theme'), findsOneWidget);
      expect(find.text('Language'), findsOneWidget);
    });

    testWidgets('theme and language changes work together', (WidgetTester tester) async {
      await pumpSettingsScreen(tester);

      // Change to German
      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('German').last);
      await tester.pumpAndSettle();

      // Change to Dark theme
      await tester.tap(find.text('System'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dunkel').last);
      await tester.pumpAndSettle();

      expect(languageProvider.appLocale, const Locale('de'));
      expect(themeProvider.themeMode, ThemeMode.dark);
      expect(find.text('Einstellungen'), findsOneWidget);
      expect(find.text('Dunkel'), findsOneWidget);
    });
  });
}
