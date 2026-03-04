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
import 'package:xfin/screens/account_detail_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late BaseCurrencyProvider currencyProvider;
  late int testAccountId;

  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<DatabaseProvider>.value(
              value: DatabaseProvider.instance),
          ChangeNotifierProvider<BaseCurrencyProvider>.value(
              value: currencyProvider),
        ],
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en'), Locale('de')],
          home: AccountDetailScreen(accountId: testAccountId),
        ),
      ),
    );
  }

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    DatabaseProvider.instance.initialize(db);
    currencyProvider = BaseCurrencyProvider();
    await currencyProvider.initialize(const Locale('en'));

    // Insert base currency
    await db.into(db.assets).insert(AssetsCompanion.insert(
          name: 'EUR',
          type: AssetTypes.fiat,
          tickerSymbol: 'EUR',
        ));

    // Insert test account
    testAccountId = await db.into(db.accounts).insert(AccountsCompanion.insert(
          name: 'Test Bank Account',
          type: AccountTypes.bankAccount,
          balance: const Value(1000.0),
          initialBalance: const Value(500.0),
        ));

    // Insert some bookings for statistics
    await db.into(db.bookings).insert(BookingsCompanion.insert(
          date: 20240101,
          assetId: const Value(1),
          accountId: testAccountId,
          category: 'Income',
          shares: 500,
          value: 500,
        ));
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets('renders account name and statistics',
      (tester) => tester.runAsync(() async {
            await pumpScreen(tester);
            await tester.pumpAndSettle();

            expect(find.text('Test Bank Account'), findsOneWidget);
            expect(find.text('Account Information'), findsOneWidget);
            expect(find.text('Transaction Statistics'), findsOneWidget);
            expect(find.text('Asset Holdings'), findsOneWidget);
          }));

  testWidgets('shows chart with time range buttons',
      (tester) => tester.runAsync(() async {
            await pumpScreen(tester);
            await tester.pumpAndSettle();

            expect(find.text('1W'), findsOneWidget);
            expect(find.text('1M'), findsOneWidget);
            expect(find.text('1J'), findsOneWidget);
            expect(find.text('MAX'), findsOneWidget);
          }));

  testWidgets('displays balance and statistics values',
      (tester) => tester.runAsync(() async {
            await pumpScreen(tester);
            await tester.pumpAndSettle();

            expect(find.text('Current Balance'), findsOneWidget);
            expect(find.text('Initial Balance'), findsOneWidget);
            expect(find.text('Net Change'), findsOneWidget);
            expect(find.text('Account Type'), findsOneWidget);
            expect(find.text('Bank Account'), findsOneWidget);
          }));

  testWidgets('shows transaction statistics',
      (tester) => tester.runAsync(() async {
            await pumpScreen(tester);
            await tester.pumpAndSettle();

            expect(find.text('Bookings'), findsOneWidget);
            expect(find.text('Transfers'), findsOneWidget);
            expect(find.text('Total Inflows'), findsOneWidget);
            expect(find.text('Total Outflows'), findsOneWidget);
            expect(find.text('Events per Month'), findsOneWidget);
          }));

  testWidgets('handles error state gracefully',
      (tester) => tester.runAsync(() async {
            await db.close();

            await pumpScreen(tester);
            await tester.pumpAndSettle();

            expect(find.byType(CircularProgressIndicator), findsNothing);

            await tester.pumpWidget(Container());
          }));

  testWidgets('shows empty holdings message when no assets',
      (tester) => tester.runAsync(() async {
            await pumpScreen(tester);
            await tester.pumpAndSettle();

            expect(find.text('Asset Holdings'), findsOneWidget);
            expect(find.text('No asset holdings'), findsOneWidget);
          }));

  testWidgets('shows trades count for portfolio accounts',
      (tester) => tester.runAsync(() async {
            // Create a portfolio account instead
            db = AppDatabase(NativeDatabase.memory());
            DatabaseProvider.instance.initialize(db);

            await db.into(db.assets).insert(AssetsCompanion.insert(
                  name: 'EUR',
                  type: AssetTypes.fiat,
                  tickerSymbol: 'EUR',
                ));

            testAccountId =
                await db.into(db.accounts).insert(AccountsCompanion.insert(
                      name: 'Test Portfolio',
                      type: AccountTypes.portfolio,
                      balance: const Value(5000.0),
                      initialBalance: const Value(1000.0),
                    ));

            await pumpScreen(tester);
            await tester.pumpAndSettle();

            expect(find.text('Test Portfolio'), findsOneWidget);
            expect(find.text('Trades'), findsOneWidget);
          }));

  testWidgets('shows asset holdings when account has assets',
      (tester) => tester.runAsync(() async {
            // Create a portfolio account with assets
            db = AppDatabase(NativeDatabase.memory());
            DatabaseProvider.instance.initialize(db);

            await db.into(db.assets).insert(AssetsCompanion.insert(
                  name: 'EUR',
                  type: AssetTypes.fiat,
                  tickerSymbol: 'EUR',
                ));

            await db.into(db.assets).insert(AssetsCompanion.insert(
                  name: 'Apple Inc.',
                  type: AssetTypes.stock,
                  tickerSymbol: 'AAPL',
                ));

            testAccountId =
                await db.into(db.accounts).insert(AccountsCompanion.insert(
                      name: 'Investment Account',
                      type: AccountTypes.portfolio,
                      balance: const Value(5000.0),
                      initialBalance: const Value(1000.0),
                    ));

            // Add asset on account (non-base currency)
            await db.into(db.assetsOnAccounts).insert(
                  AssetsOnAccountsCompanion.insert(
                    accountId: testAccountId,
                    assetId: 2,
                    shares: const Value(10),
                    value: const Value(1500),
                  ),
                );

            await pumpScreen(tester);
            await tester.pumpAndSettle();

            expect(find.text('Investment Account'), findsOneWidget);
            expect(find.text('Apple Inc.'), findsOneWidget);
          }));

  testWidgets('time range selection updates chart',
      (tester) => tester.runAsync(() async {
            await pumpScreen(tester);
            await tester.pumpAndSettle();

            // Tap 1M range button
            await tester.tap(find.text('1M'));
            await tester.pumpAndSettle();

            // Screen should still be visible after interaction
            expect(find.text('Test Bank Account'), findsOneWidget);

            // Tap MAX range button
            await tester.tap(find.text('MAX'));
            await tester.pumpAndSettle();

            expect(find.text('Test Bank Account'), findsOneWidget);
          }));
}
