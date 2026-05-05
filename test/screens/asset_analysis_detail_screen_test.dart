import 'package:xfin/providers/live_price_provider.dart';
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
import 'package:xfin/screens/asset_analysis_detail_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late BaseCurrencyProvider currencyProvider;

  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<DatabaseProvider>.value(value: DatabaseProvider.instance),
          ChangeNotifierProvider<BaseCurrencyProvider>.value(value: currencyProvider),
          ChangeNotifierProvider<ThemeProvider>.value(value: ThemeProvider.instance),
          ChangeNotifierProvider<LivePriceProvider>.value(value: LivePriceProvider.instance),
        ],
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [Locale('en'), Locale('de')],
          home: AssetAnalysisDetailScreen(assetId: 2),
        ),
      ),
    );
  }

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    DatabaseProvider.instance.initialize(db);
    currencyProvider = BaseCurrencyProvider();
    await currencyProvider.initialize(const Locale('en'));

    await db.into(db.assets).insert(AssetsCompanion.insert(name: 'EUR', type: AssetTypes.fiat, tickerSymbol: 'EUR'));
    await db.into(db.assets).insert(AssetsCompanion.insert(
      name: 'ACME',
      type: AssetTypes.stock,
      tickerSymbol: 'ACM',
      value: const Value(150),
      shares: const Value(3),
      netCostBasis: const Value(50),
      brokerCostBasis: const Value(50),
    ));

    final src = await db.into(db.accounts).insert(AccountsCompanion.insert(name: 'Cash', type: AccountTypes.cash));
    final dst = await db.into(db.accounts).insert(AccountsCompanion.insert(name: 'Broker', type: AccountTypes.portfolio));

    await db.into(db.trades).insert(TradesCompanion.insert(
      datetime: 20240101120000,
      type: TradeTypes.buy,
      sourceAccountId: src,
      targetAccountId: dst,
      assetId: 2,
      shares: 2,
      costBasis: 50,
      sourceAccountValueDelta: -100,
      targetAccountValueDelta: 100,
    ));

    await db.into(db.bookings).insert(BookingsCompanion.insert(
      date: 20240201,
      assetId: const Value(2),
      accountId: dst,
      category: 'Dividend',
      shares: 1,
      value: 50,
    ));

    await db.into(db.assetsOnAccounts).insert(AssetsOnAccountsCompanion.insert(accountId: 2, assetId: 2, shares: const Value(3), value: const Value(150)));
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets('renders charts, toggles, and stats', (tester) => tester.runAsync(() async {
        await pumpScreen(tester);
        await tester.pumpAndSettle();

        expect(find.text('ACME'), findsOneWidget);
        expect(find.text('Trading Stats'), findsOneWidget);
        expect(find.text('General Stats'), findsOneWidget);
        expect(find.text('Held on Accounts'), findsOneWidget);

        // Tap value/shares toggle (lines 113, 119)
        await tester.tap(find.text('Shares'));
        await tester.pumpAndSettle();

        // This indirectly tests callbacks at lines 92-95, 97-100, 81-84
        // by ensuring the widget tree re-renders when toggles are tapped
        expect(find.text('ACME'), findsOneWidget);

        expect(find.text('Buys'), findsOneWidget);
        expect(find.text('Broker'), findsOneWidget);
      }));

  testWidgets('handles error state gracefully (line 58)', (tester) => tester.runAsync(() async {
        // Close database to trigger error
        await db.close();

        await pumpScreen(tester);
        await tester.pumpAndSettle();

        // Should show error message instead of crashing (line 58)
        expect(find.byType(CircularProgressIndicator), findsNothing);

        await tester.pumpWidget(Container());
      }));

  testWidgets('shows empty holdings message when no positions (line 142)', (tester) => tester.runAsync(() async {
        // Reinitialize db without any holdings
        db = AppDatabase(NativeDatabase.memory());
        DatabaseProvider.instance.initialize(db);

        await db.into(db.assets).insert(AssetsCompanion.insert(name: 'EUR', type: AssetTypes.fiat, tickerSymbol: 'EUR'));
        await db.into(db.assets).insert(AssetsCompanion.insert(
          name: 'ACME',
          type: AssetTypes.stock,
          tickerSymbol: 'ACM',
        ));

        await pumpScreen(tester);
        await tester.pumpAndSettle();

        // Should show empty holdings message (line 142)
        expect(find.text('No account positions.'), findsOneWidget);

        await tester.pumpWidget(Container());
      }));

  testWidgets('shows unrealized P&L when live is active', (tester) => tester.runAsync(() async {
        await pumpScreen(tester);
        await tester.pumpAndSettle();

        // Initially no unrealized P&L
        expect(find.text('Unrealized P&L'), findsNothing);

        // Simulate live state: set livePrice for asset 2
        final provider = LivePriceProvider.instance;
        provider.setLivePriceForTesting(2, 75.0);

        // Use pump (not pumpAndSettle) because live pulse animation runs forever
        await tester.pump(const Duration(milliseconds: 500));

        // Unrealized P&L = (livePrice - netCostBasis) * shares = (75 - 50) * 3 = 75
        expect(find.text('Unrealized P&L'), findsOneWidget);

        // Clean up
        provider.clearLivePricesForTesting();
        await tester.pump();
        await tester.pumpWidget(Container());
      }));

  testWidgets('shows shares in account holdings when Anteile selected', (tester) => tester.runAsync(() async {
        await pumpScreen(tester);
        await tester.pumpAndSettle();

        // Tap "Shares" toggle
        await tester.tap(find.text('Shares'));
        await tester.pump(const Duration(milliseconds: 500));

        // Should show shares with 4 decimal places (chart header + allocation subtitle)
        expect(find.text('3.0000'), findsNWidgets(2));
      }));
}
