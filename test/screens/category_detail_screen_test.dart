import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:xfin/database/app_database.dart';
import 'package:xfin/database/tables.dart';
import 'package:xfin/l10n/app_localizations.dart';
import 'package:xfin/providers/base_currency_provider.dart';
import 'package:xfin/providers/database_provider.dart';
import 'package:xfin/providers/theme_provider.dart';
import 'package:xfin/screens/category_detail_screen.dart';
import 'package:xfin/widgets/category_heatmap.dart';
import 'package:xfin/widgets/category_histogram.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late BaseCurrencyProvider currencyProvider;
  late int accountId;

  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpScreen(WidgetTester tester, String category) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<DatabaseProvider>.value(
              value: DatabaseProvider.instance),
          ChangeNotifierProvider<BaseCurrencyProvider>.value(
              value: currencyProvider),
          ChangeNotifierProvider<ThemeProvider>.value(
              value: ThemeProvider.instance),
        ],
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en'), Locale('de')],
          home: CategoryDetailScreen(category: category),
        ),
      ),
    );
  }

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    DatabaseProvider.instance.initialize(db);
    currencyProvider = BaseCurrencyProvider();
    await currencyProvider.initialize(const Locale('en'));

    await db.into(db.assets).insert(AssetsCompanion.insert(
          name: 'EUR',
          type: AssetTypes.fiat,
          tickerSymbol: 'EUR',
        ));

    accountId = await db.into(db.accounts).insert(AccountsCompanion.insert(
          name: 'Acc',
          type: AccountTypes.bankAccount,
          balance: const Value(0),
          initialBalance: const Value(0),
        ));
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> insertBooking({
    required int dateInt,
    required String category,
    required double value,
  }) async {
    await db.into(db.bookings).insert(BookingsCompanion.insert(
          date: dateInt,
          accountId: accountId,
          category: category,
          shares: value,
          value: value,
        ));
  }

  testWidgets('renders category name in app bar',
      (tester) => tester.runAsync(() async {
            await insertBooking(
                dateInt: 20240115, category: 'Salary', value: 1000);
            await pumpScreen(tester, 'Salary');
            await tester.pumpAndSettle();

            expect(find.text('Salary'), findsOneWidget);
          }));

  testWidgets('renders toggle, header, histogram, stat cards, and heatmap',
      (tester) => tester.runAsync(() async {
            await insertBooking(
                dateInt: 20240115, category: 'Food', value: -10);
            await insertBooking(
                dateInt: 20240220, category: 'Food', value: -20);
            await pumpScreen(tester, 'Food');
            await tester.pumpAndSettle();

            // Toggle labels
            expect(find.text('Anzahl'), findsOneWidget);
            expect(find.text('Summe'), findsOneWidget);

            // Section titles
            expect(find.text('Verlauf'), findsOneWidget);
            expect(find.text('Statistik'), findsOneWidget);
            expect(find.text('Aktivität'), findsOneWidget);

            // Stat-card labels
            expect(find.text('Ø pro Monat'), findsOneWidget);
            expect(find.text('Gesamt'), findsOneWidget);

            // Header label
            expect(find.text('Aktueller Monat'), findsOneWidget);

            // Sub-widgets are present
            expect(find.byType(CategoryHistogram), findsOneWidget);
            expect(find.byType(CategoryHeatmap), findsOneWidget);
          }));

  testWidgets('toggling Anzahl/Summe switches the displayed totals',
      (tester) => tester.runAsync(() async {
            await insertBooking(
                dateInt: 20240115, category: 'X', value: 100);
            await insertBooking(
                dateInt: 20240215, category: 'X', value: 200);
            await pumpScreen(tester, 'X');
            await tester.pumpAndSettle();

            // Default mode = Summe → "Gesamt" stat card shows formatted currency.
            // We don't pin the exact format string (locale-dependent), but the
            // count "2" must NOT be the gesamt value yet.
            // Switch to Anzahl.
            await tester.tap(find.text('Anzahl'));
            await tester.pumpAndSettle();

            // After switching, 'Gesamt' card value should be the count "2".
            expect(find.text('2'), findsWidgets);
          }));

  testWidgets('shows empty state gracefully when category has no bookings',
      (tester) => tester.runAsync(() async {
            await pumpScreen(tester, 'NonExistent');
            await tester.pumpAndSettle();

            // App bar still shows the category name.
            expect(find.text('NonExistent'), findsOneWidget);
            // Heatmap and histogram render the placeholder dash.
            expect(find.text('—'), findsAtLeastNWidgets(1));
          }));
}
