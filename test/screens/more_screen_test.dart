import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xfin/database/app_database.dart';
import 'package:xfin/l10n/app_localizations.dart';
import 'package:xfin/providers/language_provider.dart';
import 'package:xfin/providers/theme_provider.dart';
import 'package:xfin/screens/assets_screen.dart';
import 'package:xfin/screens/more_screen.dart';
import 'package:xfin/screens/settings_screen.dart';
import 'package:xfin/screens/trades_screen.dart';
import 'package:drift/native.dart';

void main() {
  late ThemeProvider themeProvider;
  late LanguageProvider languageProvider;
  late AppLocalizations l10n;
  late AppDatabase db;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    themeProvider = ThemeProvider();
    languageProvider = LanguageProvider();
    await themeProvider.loadTheme();
    await languageProvider.loadLocale();

    l10n = await AppLocalizations.delegate.load(languageProvider.appLocale);

    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() => db.close());

  Future<void> pumpMoreScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: themeProvider),
          ChangeNotifierProvider.value(value: languageProvider),
          Provider<AppDatabase>.value(value: db),
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
    await tester.pumpAndSettle();
  }

  testWidgets('MoreScreen has a title and a all cards',
      (WidgetTester tester) async {
    await pumpMoreScreen(tester);

    // Verify title is present
    expect(find.text(l10n.more), findsOneWidget);

    // Verify the cards are present
    expect(find.widgetWithText(Card, l10n.settings), findsOneWidget);
    expect(find.widgetWithText(Card, l10n.assets), findsOneWidget);
    expect(find.widgetWithText(Card, l10n.trades), findsOneWidget);

    // Verify icons are present
    expect(find.byIcon(Icons.settings), findsOneWidget);
    expect(find.byIcon(Icons.monetization_on), findsOneWidget);
    expect(find.byIcon(Icons.swap_horiz), findsOneWidget);
  });

  group('Navigation', () {
    testWidgets('Tapping settings card navigates to SettingsScreen',
        (WidgetTester tester) async {
      await pumpMoreScreen(tester);
      await tester.tap(find.widgetWithText(Card, l10n.settings));
      await tester.pumpAndSettle();
      expect(find.byType(SettingsScreen), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
    });

    testWidgets('Tapping assets card navigates to AssetsScreen',
            (WidgetTester tester) async {
          await pumpMoreScreen(tester);
          await tester.tap(find.widgetWithText(Card, l10n.assets));
          await tester.pumpAndSettle();
          expect(find.byType(AssetsScreen), findsOneWidget);
          await tester.pageBack();
          await tester.pumpAndSettle();
        });

    testWidgets('Tapping trades card navigates to TradesScreen',
            (WidgetTester tester) async {
          await pumpMoreScreen(tester);
          // Scroll the screen to make the 'Trades' card visible
          await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -500));
          await tester.pumpAndSettle();
          await tester.tap(find.widgetWithText(Card, l10n.trades));
          await tester.pumpAndSettle();
          expect(find.byType(TradesScreen), findsOneWidget);
          await tester.pageBack();
          await tester.pumpAndSettle();
        });
  });
}
