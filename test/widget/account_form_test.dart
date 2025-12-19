import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:xfin/database/app_database.dart';
import 'package:xfin/database/tables.dart';
import 'package:xfin/l10n/app_localizations.dart';
import 'package:xfin/providers/base_currency_provider.dart';
import 'package:xfin/widgets/account_form.dart';

// Mocks / fakes used in multiple tests
class MockNavigatorObserver extends Mock implements NavigatorObserver {}

class FakeRoute extends Fake implements Route<dynamic> {}

void main() {
  late AppDatabase db;
  late AppLocalizations l10n;
  late BaseCurrencyProvider currencyProvider;
  late MockNavigatorObserver mockObserver;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    registerFallbackValue(FakeRoute());
  });

  setUp(() async {
    // In-memory drift database
    db = AppDatabase(NativeDatabase.memory());
    mockObserver = MockNavigatorObserver();

    // Load english localizations
    const locale = Locale('en');
    l10n = await AppLocalizations.delegate.load(locale);

    // Base currency provider (reads from DB as well)
    currencyProvider = BaseCurrencyProvider();
    await currencyProvider.initialize(locale);

    // Insert base currency asset so it will have id = 1
    await db.into(db.assets).insert(
          AssetsCompanion.insert(
              name: 'EUR', type: AssetTypes.fiat, tickerSymbol: 'EUR'),
        );

    // Insert additional assets of various types
    await db.into(db.assets).insert(
          AssetsCompanion.insert(
            name: 'USD',
            type: AssetTypes.fiat,
            tickerSymbol: 'USD',
            value: const Value(1000),
            shares: const Value(10),
            brokerCostBasis: const Value(100),
            netCostBasis: const Value(100),
          ),
        );

    await db.into(db.assets).insert(
          const AssetsCompanion(
            name: Value('BTC'),
            type: Value(AssetTypes.crypto),
            tickerSymbol: Value('BTC'),
            value: Value(50000),
            shares: Value(1),
            brokerCostBasis: Value(50000),
            netCostBasis: Value(50000),
          ),
        );

    // Insert a stock (portfolio type)
    await db.into(db.assets).insert(
          const AssetsCompanion(
            name: Value('AAPL'),
            type: Value(AssetTypes.stock),
            tickerSymbol: Value('AAPL'),
            value: Value(150),
            shares: Value(2),
            brokerCostBasis: Value(150),
            netCostBasis: Value(150),
          ),
        );

    // Insert an existing account to test uniqueness validator
    await db.into(db.accounts).insert(
          AccountsCompanion.insert(
            name: 'Existing Account',
            type: AccountTypes.cash,
          ),
        );
  });

  tearDown(() async {
    // close if not already closed; ignore errors if already closed
    try {
      await db.close();
    } catch (_) {}
  });

  // Helper to pump the AccountForm inside a MaterialApp + Providers
  Future<void> pumpAccountForm(WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<AppDatabase>.value(value: db),
          ChangeNotifierProvider<BaseCurrencyProvider>.value(
              value: currencyProvider),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          navigatorObservers: [mockObserver],
          home: const Scaffold(body: AccountForm()),
        ),
      ),
    );

    // Let any async initState fetches finish
    await tester.pumpAndSettle();

    // ensure the zero-duration timers get a chance to run
    await tester.pump();
    await tester.pumpAndSettle();

    // close DB early so Drift does not schedule cleanup timers after the test finishes
    // await db.close();
  }

  testWidgets(
      'renders step 1 and shows validators for name uniqueness and type',
      (tester) async {
    await pumpAccountForm(tester);

    // Step 1 should be visible initially
    expect(find.byKey(const Key('account_name_field')), findsOneWidget);
    expect(find.byKey(const Key('account_type_dropdown')), findsOneWidget);

    // Try to proceed with existing account name -> validation error
    await tester.enterText(
        find.byKey(const Key('account_name_field')), 'Existing Account');
    await tester.tap(find.widgetWithText(ElevatedButton, l10n.next));
    await tester.pumpAndSettle();

    // The form validator should show the localised duplicate error message
    expect(find.textContaining('already'), findsOneWidget);

    // Now enter a unique name but clear the account type (simulate null) -> validator should still check
    await tester.enterText(
        find.byKey(const Key('account_name_field')), 'Brand New');
    // We can't directly set dropdown to null easily; instead ensure onChanged works by selecting another value
    await tester.tap(find.byKey(const Key('account_type_dropdown')));
    await tester.pumpAndSettle();
    // Choose portfolio (should be available)
    await tester.tap(find.textContaining(l10n.portfolio).last);
    await tester.pumpAndSettle();

    // Now Next should navigate to step 2
    await tester.tap(find.widgetWithText(ElevatedButton, l10n.next));
    await tester.pumpAndSettle();

    // Step 2 should now be visible
    expect(find.textContaining('Brand New ('), findsOneWidget);

    await db.close();
  });

  testWidgets('type info dialog displays correct text for each account type',
      (tester) async {
    await pumpAccountForm(tester);

    // iterate all types and check dialog content
    for (final type in AccountTypes.values) {
      // select the type in dropdown
      await tester.tap(find.byKey(const Key('account_type_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(_getTypeNameForTest(type, l10n)).last);
      await tester.pumpAndSettle();

      // Enter a unique name and go next so step2 is shown
      await tester.enterText(
          find.byKey(const Key('account_name_field')), 'Test ${type.name}');
      await tester.tap(find.widgetWithText(ElevatedButton, l10n.next));
      await tester.pumpAndSettle();

      // Tap info icon to show dialog
      await tester.tap(find.byTooltip(l10n.info));
      await tester.pumpAndSettle();

      // Dialog should contain correct title and content
      expect(
          find.text(_getTypeNameForTest(type, l10n)), findsAtLeastNWidgets(1));
      expect(find.text(_getTypeInfoForTest(type, l10n)), findsOneWidget);

      // Close dialog
      await tester.tap(find.widgetWithText(TextButton, l10n.ok));
      await tester.pumpAndSettle();

      // Navigate back to step 1 to try next type
      await tester.tap(find.widgetWithText(TextButton, l10n.back));
      await tester.pumpAndSettle();

      await db.close();
    }
  });

  testWidgets('asset filtering respects account type', (tester) async {
    await pumpAccountForm(tester);

    // When account type = bankAccount -> only asset id == 1 should be shown
    await tester.tap(find.byKey(const Key('account_type_dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.bankAccount).hitTestable());
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byKey(const Key('account_name_field')), 'BankTest');

    final nextFinder = find.widgetWithText(ElevatedButton, l10n.next);
    await tester.ensureVisible(nextFinder);
    await tester.pumpAndSettle();
    await tester.tap(nextFinder);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('assets_dropdown')));
    await tester.pumpAndSettle();
    // Only EUR should be visible
    expect(find.text('EUR'), findsOneWidget);
    await tester.tap(find.text('EUR').last.hitTestable());

    // Back to step 1 and test cash -> currency assets only (EUR, USD)
    final backFinder = find.widgetWithText(TextButton, l10n.back);
    await tester.ensureVisible(backFinder);
    await tester.pumpAndSettle();
    await tester.tap(backFinder);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('account_type_dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.cash).hitTestable());
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byKey(const Key('account_name_field')), 'CashTest');
    await tester.ensureVisible(nextFinder);
    await tester.pumpAndSettle();
    await tester.tap(nextFinder);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('assets_dropdown')));
    await tester.pumpAndSettle();
    expect(find.text('EUR'), findsWidgets);
    expect(find.text('USD'), findsOneWidget);
    await tester.tap(find.text('EUR').last.hitTestable());

    // Crypto wallet -> only BTC
    await tester.ensureVisible(backFinder);
    await tester.pumpAndSettle();
    await tester.tap(backFinder);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('account_type_dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.cryptoWallet).hitTestable());
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byKey(const Key('account_name_field')), 'CryptoTest');
    await tester.ensureVisible(nextFinder);
    await tester.pumpAndSettle();
    await tester.tap(nextFinder);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('assets_dropdown')));
    await tester.pumpAndSettle();
    expect(find.text('BTC'), findsOneWidget);
    await tester.tap(find.text('BTC').last.hitTestable());

    // Portfolio -> all assets (EUR, USD, BTC, AAPL)
    await tester.ensureVisible(backFinder);
    await tester.pumpAndSettle();
    await tester.tap(backFinder);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('account_type_dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.portfolio).hitTestable());
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byKey(const Key('account_name_field')), 'PortTest');
    await tester.ensureVisible(nextFinder);
    await tester.pumpAndSettle();
    await tester.tap(nextFinder);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('assets_dropdown')));
    await tester.pumpAndSettle();
    expect(find.text('EUR'), findsOneWidget);
    expect(find.text('USD'), findsOneWidget);
    expect(find.text('BTC'), findsOneWidget);
    expect(find.text('AAPL'), findsOneWidget);

    // final cleanup
    await tester.pump();
    await tester.pumpAndSettle();
    try {
      await db.close();
    } catch (_) {}
  });

  testWidgets('add asset to buffer, show in list and remove', (tester) async {
    await pumpAccountForm(tester);

    // Use portfolio type to show all assets
    await tester.tap(find.byKey(const Key('account_type_dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.portfolio).last);
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const Key('account_name_field')), 'BufferTest');
    await tester.tap(find.widgetWithText(ElevatedButton, l10n.next));
    await tester.pumpAndSettle();

    // Open assets dropdown and select USD (should be present)
    await tester.tap(find.byKey(const Key('assets_dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('USD').last);
    await tester.pumpAndSettle();

    // Enter shares and price
    await tester.enterText(find.byType(TextFormField).at(1), '2.5');
    await tester.enterText(find.byType(TextFormField).at(2), '100');

    // Add asset
    await tester.tap(find.widgetWithText(OutlinedButton, l10n.addAsset));
    await tester.pumpAndSettle();

    // The pending asset list should show an entry (USD)
    expect(find.textContaining('USD'), findsOneWidget);

    // Remove it using the delete icon
    await tester.tap(find.byIcon(Icons.delete));
    await tester.pumpAndSettle();

    // Now the "no assets" message should be visible
    expect(find.text(l10n.noAssetsAddedYet), findsOneWidget);

    await db.close();
  });

  testWidgets('prevent adding duplicate asset shows snackbar', (tester) async {
    await pumpAccountForm(tester);

    await tester.tap(find.byKey(const Key('account_type_dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.portfolio).last);
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const Key('account_name_field')), 'DupTest');
    await tester.tap(find.widgetWithText(ElevatedButton, l10n.next));
    await tester.pumpAndSettle();

    // Select USD and add it twice
    await tester.tap(find.byKey(const Key('assets_dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('USD').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(1), '1');
    await tester.enterText(find.byType(TextFormField).at(2), '100');
    await tester.tap(find.widgetWithText(OutlinedButton, l10n.addAsset));
    await tester.pumpAndSettle();

    // Add the same asset again
    await tester.tap(find.byKey(const Key('assets_dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('USD').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(1), '1');
    await tester.enterText(find.byType(TextFormField).at(2), '100');
    await tester.tap(find.widgetWithText(OutlinedButton, l10n.addAsset));
    await tester.pumpAndSettle();

    // SnackBar should appear with assetAlreadyAdded message
    expect(find.text(l10n.assetAlreadyAdded), findsOneWidget);

    await db.close();
  });

  testWidgets('adding base-currency asset uses pricePerShare = 1.0',
      (tester) async {
    await pumpAccountForm(tester);

    // BankAccount will limit to base currency (EUR id=1)
    await tester.tap(find.byKey(const Key('account_type_dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.bankAccount).last);
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const Key('account_name_field')), 'BankBase');
    await tester.tap(find.widgetWithText(ElevatedButton, l10n.next));
    await tester.pumpAndSettle();

    // Select EUR (base, id == 1)
    await tester.tap(find.byKey(const Key('assets_dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('EUR').last);
    await tester.pumpAndSettle();

    // Enter shares only
    await tester.enterText(find.byKey(const Key('shares_field')), '10');

    // Add asset
    await tester.tap(find.widgetWithText(OutlinedButton, l10n.addAsset));
    await tester.pumpAndSettle();

    // Verify the list displays approx value = shares * 1.0 => 10
    expect(find.textContaining('10.0 EUR'), findsOneWidget);

    await db.close();
  });

  testWidgets('saveForm inserts account and updates assets & assetsOnAccounts',
      (tester) async {
    await pumpAccountForm(tester);

    // Use portfolio type
    await tester.tap(find.byKey(const Key('account_type_dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.portfolio).last);
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const Key('account_name_field')), 'SaveTest');
    await tester.tap(find.widgetWithText(ElevatedButton, l10n.next));
    await tester.pumpAndSettle();

    // Select USD and add asset with shares 2 and price 100 -> value 200
    await tester.tap(find.byKey(const Key('assets_dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('USD').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(1), '2');
    await tester.enterText(find.byType(TextFormField).at(2), '100');
    await tester.tap(find.widgetWithText(OutlinedButton, l10n.addAsset));
    await tester.pumpAndSettle();

    // Select BTC and add asset with shares 0.5 and price 50000 -> value 25000
    await tester.tap(find.byKey(const Key('assets_dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('BTC').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(1), '0.5');
    await tester.enterText(find.byType(TextFormField).at(2), '50000');
    await tester.tap(find.widgetWithText(OutlinedButton, l10n.addAsset));
    await tester.pumpAndSettle();

    // Now press Save
    await tester.tap(find.widgetWithText(ElevatedButton, l10n.save));
    await tester.pumpAndSettle();

    // Verify that an account with name SaveTest exists and has initialBalance = 25200
    final accounts = await db.accountsDao.getAllAccounts();
    final saved = accounts.firstWhere((a) => a.name == 'SaveTest');
    expect(saved.initialBalance, closeTo(25200, 0.001));

    // Verify assetsOnAccounts updated: there should be two entries referencing this account id
    final joined = await db.assetsOnAccountsDao.getAOAsForAccount(saved.id);
    expect(joined.length, 2);

    // Verify assets table updated for USD (shares increased by 2) and BTC (shares increased by 0.5)
    final usd = await db.assetsDao.getAssetByTickerSymbol('USD');
    expect(usd.shares, greaterThanOrEqualTo(12)); // initial 10 + 2
    final btc = await db.assetsDao.getAssetByTickerSymbol('BTC');
    expect(btc.shares, greaterThanOrEqualTo(1.5)); // initial 1 + 0.5
  });
}

// Helpers used within tests to translate enum -> l10n text (mirrors AccountForm private methods)
String _getTypeNameForTest(AccountTypes type, AppLocalizations l10n) {
  switch (type) {
    case AccountTypes.cash:
      return l10n.cash;
    case AccountTypes.bankAccount:
      return l10n.bankAccount;
    case AccountTypes.portfolio:
      return l10n.portfolio;
    case AccountTypes.cryptoWallet:
      return l10n.cryptoWallet;
  }
}

String _getTypeInfoForTest(AccountTypes type, AppLocalizations l10n) {
  switch (type) {
    case AccountTypes.cash:
      return l10n.cashInfo;
    case AccountTypes.bankAccount:
      return l10n.bankAccountInfo;
    case AccountTypes.portfolio:
      return l10n.portfolioInfo;
    case AccountTypes.cryptoWallet:
      return l10n.cryptoWalletInfo;
  }
}
