import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xfin/database/app_database.dart';
import 'package:xfin/l10n/app_localizations.dart';
import 'package:xfin/providers/database_provider.dart';
import 'package:xfin/providers/language_provider.dart';
import 'package:xfin/providers/theme_provider.dart';
import 'package:xfin/screens/settings_screen.dart';
import 'package:xfin/utils/global_constants.dart' as globals;
import 'package:xfin/utils/format.dart' show dateFormat, dateTimeToInt;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SettingsScreen (extended)', () {
    late ThemeProvider themeProvider;
    late LanguageProvider languageProvider;
    late AppLocalizations l10n;
    late AppDatabase db;

    final origFilterStart = globals.filterStartDate;
    final origFilterEnd = globals.filterEndDate;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      themeProvider = ThemeProvider.instance;
      languageProvider = LanguageProvider();
      await themeProvider.loadTheme();
      await languageProvider.loadLocale();
      l10n = await AppLocalizations.delegate.load(const Locale('en'));

      db = AppDatabase(NativeDatabase.memory());
      DatabaseProvider.instance.initialize(db);

      globals.filterStartDate = 0;
      globals.filterEndDate = 99999999;
    });

    tearDown(() async {
      globals.filterStartDate = origFilterStart;
      globals.filterEndDate = origFilterEnd;
      await db.close();
    });

    Future<void> pumpSettingsScreen(WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: themeProvider),
            ChangeNotifierProvider.value(value: languageProvider),
            ChangeNotifierProvider.value(value: DatabaseProvider.instance),
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
      await tester.pumpAndSettle();
    }

    testWidgets('renders base items', (WidgetTester tester) async {
      await pumpSettingsScreen(tester);
      expect(find.text(l10n.settings), findsOneWidget);
      expect(find.text(l10n.theme), findsOneWidget);
      expect(find.text(l10n.language), findsOneWidget);
    });

    testWidgets('export tile triggers export (ignore exceptions)', (WidgetTester tester) async {
      await pumpSettingsScreen(tester);

      final exportTile = find.text(l10n.exportDatabase);
      expect(exportTile, findsOneWidget);

      await tester.tap(exportTile);
      await tester.pumpAndSettle();

      // If export throws (platform channels, share, etc.), capture and ignore it.
      final exception = tester.takeException();
      if (exception != null) {
        // ignore - DB backup errors are tested elsewhere per your instruction
      }
    });

    testWidgets('import tile shows confirmation, confirm, and proceeds (ignore exceptions)', (WidgetTester tester) async {
      await pumpSettingsScreen(tester);

      final importTile = find.text(l10n.importDatabase);
      expect(importTile, findsOneWidget);

      // Tap import tile -> shows confirmation dialog
      await tester.tap(importTile);
      await tester.pumpAndSettle();

      // Dialog should show title and warning
      expect(find.text(l10n.importDatabase), findsWidgets); // list tile + dialog title
      expect(find.text(l10n.importDatabaseWarning), findsOneWidget);

      // Confirm import
      await tester.tap(find.text(l10n.confirm));
      await tester.pumpAndSettle();

      // The import flow tries to read DatabaseProvider and call DbBackup.importDatabaseFromPicker.
      // We capture and ignore any exceptions that may occur inside.
      final exception = tester.takeException();
      if (exception != null) {
        // ignore according to instructions
      }
    });

    testWidgets('since start branch persists start=0 and toggles button state', (WidgetTester tester) async {
      await pumpSettingsScreen(tester);

      // The "Since start" OutlinedButton should be present.
      final sinceStartBtn = find.widgetWithText(OutlinedButton, l10n.sinceStart);
      expect(sinceStartBtn, findsOneWidget);

      await tester.tap(sinceStartBtn);
      await tester.pumpAndSettle();

      // Check SharedPreferences and global variable
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt(globals.PrefKeys.filterStartDate), 0);
      expect(globals.filterStartDate, 0);

      // The UI should show "pick date" on the other button (still present)
      expect(find.widgetWithText(OutlinedButton, l10n.pickDate), findsWidgets);
    });

    testWidgets('pick start date branch: pick a date and persist, also cancel branch', (WidgetTester tester) async {
      await pumpSettingsScreen(tester);

      // Initially _isSinceStartSelected is true (default), so the text on second button is pickDate.
      // Find the second OutlinedButton in Start Date row by finding the OutlinedButton whose text is either pickDate or a formatted date.
      // We'll search for any OutlinedButton descendant within the Start Date ListTile.
      final startListTile = find.widgetWithText(ListTile, l10n.startDate);
      expect(startListTile, findsOneWidget);

      // Within that ListTile, find all OutlinedButtons and pick the second one (index 1).
      final outlinedButtonsInStart = find.descendant(
        of: startListTile,
        matching: find.byType(OutlinedButton),
      );
      expect(outlinedButtonsInStart, findsNWidgets(2));

      // Tap the pick-date button (second OutlinedButton)
      await tester.tap(outlinedButtonsInStart.at(1));
      await tester.pumpAndSettle();

      // DatePicker should be visible. Pick today's day.
      final now = DateTime.now();
      final dayStr = now.day.toString();

      // Tap the day tile (may find multiple; take first)
      final dayFinder = find.text(dayStr);
      expect(dayFinder, findsWidgets);
      await tester.tap(dayFinder.first);
      await tester.pumpAndSettle();

      // Press the OK button on the date picker
      final okFinder = find.text('OK');
      expect(okFinder, findsOneWidget);
      await tester.tap(okFinder);
      await tester.pumpAndSettle();

      // If any exception occurred inside saving or side-effects, capture and ignore.
      var exception = tester.takeException();
      if (exception != null) {
        // ignore per instruction
      }

      // Now verify SharedPreferences saved the selected date
      final prefs = await SharedPreferences.getInstance();
      // expected date is the day we selected in current month/year
      final expectedInt = dateTimeToInt(DateTime(now.year, now.month, now.day));
      expect(prefs.getInt(globals.PrefKeys.filterStartDate), expectedInt);
      expect(globals.filterStartDate, expectedInt);

      // Now test canceling the date picker: tap pick button again and press CANCEL
      await tester.tap(outlinedButtonsInStart.at(1));
      await tester.pumpAndSettle();

      final cancelFinder = find.text('CANCEL');
      // Some locales may use 'CANCEL' or 'Cancel' — try a couple.
      if (cancelFinder.evaluate().isNotEmpty) {
        await tester.tap(cancelFinder.first);
      } else {
        final cancelLower = find.text('Cancel');
        if (cancelLower.evaluate().isNotEmpty) {
          await tester.tap(cancelLower.first);
        }
      }
      await tester.pumpAndSettle();

      // No change expected beyond previous persisted value — re-check
      final prefsAfter = await SharedPreferences.getInstance();
      expect(prefsAfter.getInt(globals.PrefKeys.filterStartDate), expectedInt);
    });

    testWidgets('today branch persists end=99999999 and toggle', (WidgetTester tester) async {
      await pumpSettingsScreen(tester);

      final endListTile = find.widgetWithText(ListTile, l10n.endDate);
      expect(endListTile, findsOneWidget);

      final todayBtn = find.descendant(of: endListTile, matching: find.widgetWithText(OutlinedButton, l10n.today));
      expect(todayBtn, findsOneWidget);

      await tester.tap(todayBtn);
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt(globals.PrefKeys.filterEndDate), 99999999);
      expect(globals.filterEndDate, 99999999);
    });

    testWidgets('pick end date branch: pick a date and persist, also cancel', (WidgetTester tester) async {
      await pumpSettingsScreen(tester);

      // Find the two OutlinedButtons in the End Date ListTile and pick the second (pick-date)
      final endListTile = find.widgetWithText(ListTile, l10n.endDate);
      expect(endListTile, findsOneWidget);

      final outlinedButtonsInEnd = find.descendant(of: endListTile, matching: find.byType(OutlinedButton));
      expect(outlinedButtonsInEnd, findsNWidgets(2));

      // Tap the pick-date button (second OutlinedButton)
      await tester.tap(outlinedButtonsInEnd.at(1));
      await tester.pumpAndSettle();

      // DatePicker should be visible. Pick today's day.
      final now = DateTime.now();
      final dayStr = now.day.toString();

      final dayFinder = find.text(dayStr);
      expect(dayFinder, findsWidgets);
      await tester.tap(dayFinder.first);
      await tester.pumpAndSettle();

      // Press OK
      final okFinder = find.text('OK');
      expect(okFinder, findsOneWidget);
      await tester.tap(okFinder);
      await tester.pumpAndSettle();

      // Capture any incidental exception thrown in handlers and ignore
      var exception = tester.takeException();
      if (exception != null) {
        // ignore as instructed
      }

      // Verify persistence
      final prefs = await SharedPreferences.getInstance();
      final expectedInt = dateTimeToInt(DateTime(now.year, now.month, now.day));
      expect(prefs.getInt(globals.PrefKeys.filterEndDate), expectedInt);
      expect(globals.filterEndDate, expectedInt);

      // Now test canceling the date picker: tap pick button again and press CANCEL (no change)
      await tester.tap(outlinedButtonsInEnd.at(1));
      await tester.pumpAndSettle();

      final cancelFinder = find.text('CANCEL');
      if (cancelFinder.evaluate().isNotEmpty) {
        await tester.tap(cancelFinder.first);
      } else {
        final cancelLower = find.text('Cancel');
        if (cancelLower.evaluate().isNotEmpty) {
          await tester.tap(cancelLower.first);
        }
      }
      await tester.pumpAndSettle();

      final prefsAfter = await SharedPreferences.getInstance();
      expect(prefsAfter.getInt(globals.PrefKeys.filterEndDate), expectedInt);
    });

    testWidgets('pre-set start/end filters show formatted dates', (WidgetTester tester) async {
      // Set global filter ints to represent concrete dates before pumping the screen
      final startDate = DateTime(2020, 1, 2);
      final endDate = DateTime(2021, 12, 31);
      globals.filterStartDate = dateTimeToInt(startDate);
      globals.filterEndDate = dateTimeToInt(endDate);

      await pumpSettingsScreen(tester);

      final expectedStartText = dateFormat.format(startDate);
      final expectedEndText = dateFormat.format(endDate);

      expect(find.text(expectedStartText), findsOneWidget);
      expect(find.text(expectedEndText), findsOneWidget);
    });
  });
}