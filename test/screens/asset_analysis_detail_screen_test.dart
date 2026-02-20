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
        expect(find.text('Trading stats'), findsOneWidget);
        expect(find.text('General stats'), findsOneWidget);
        expect(find.text('Held on accounts'), findsOneWidget);

        await tester.tap(find.text('Shares'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('SMA'));
        await tester.pumpAndSettle();

        expect(find.text('Buys'), findsOneWidget);
        expect(find.text('Broker'), findsOneWidget);
      }));
}
