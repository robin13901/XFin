import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xfin/database/app_database.dart';
import 'package:xfin/database/daos/trades_dao.dart' as gen_trades_dao;
import 'package:xfin/database/tables.dart';
import 'package:xfin/l10n/app_localizations.dart';
import 'package:xfin/providers/base_currency_provider.dart';
import 'package:xfin/providers/database_provider.dart';
import 'package:xfin/widgets/trade_form.dart';

/// A tiny TradesDao subclass that throws on insertTrade — used to test error path.
class ThrowingTradesDao extends gen_trades_dao.TradesDao {
  ThrowingTradesDao(super.db);

  @override
  Future<int> insertTrade(TradesCompanion entry, AppLocalizations l10n) {
    throw Exception('boom');
  }
}

/// AppDatabase subclass that uses ThrowingTradesDao for the tradesDao getter.
class ThrowingTradesDatabase extends AppDatabase {
  ThrowingTradesDatabase(super.e);

  late final gen_trades_dao.TradesDao _throwing = ThrowingTradesDao(this);

  @override
  gen_trades_dao.TradesDao get tradesDao => _throwing;
}

void main() {
  late AppDatabase db;
  late AppLocalizations l10n;
  late BaseCurrencyProvider currencyProvider;

  // Shared assets/accounts used by all tests and also passed as "preloaded" lists
  late Asset eurAsset;
  late Asset acmeAsset;
  late Account cashAcc;
  late Account portAcc;
  late List<Asset> preloadedAssets;
  late List<Account> preloadedAccounts;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  setUp(() async {
    // In-memory DB and provider
    db = AppDatabase(NativeDatabase.memory());
    DatabaseProvider.instance.initialize(db);

    // l10n + currency provider
    const locale = Locale('en');
    l10n = await AppLocalizations.delegate.load(locale);
    currencyProvider = BaseCurrencyProvider();
    await currencyProvider.initialize(locale);

    // Prepare shared assets/accounts (IDs chosen to match previous tests)
    eurAsset = const Asset(
      id: 1,
      name: 'EUR',
      tickerSymbol: 'EUR',
      type: AssetTypes.fiat,
      currencySymbol: '€',
      value: 0,
      shares: 0,
      netCostBasis: 1,
      brokerCostBasis: 1,
      buyFeeTotal: 0,
      isArchived: false,
    );

    acmeAsset = const Asset(
      id: 2,
      name: 'ACME',
      tickerSymbol: 'ACME',
      type: AssetTypes.stock,
      currencySymbol: '',
      value: 0,
      shares: 0,
      netCostBasis: 1,
      brokerCostBasis: 1,
      buyFeeTotal: 0,
      isArchived: false,
    );

    cashAcc = const Account(
      id: 11,
      name: 'Cash A',
      balance: 1000.0,
      initialBalance: 1000.0,
      type: AccountTypes.cash,
      isArchived: false,
    );

    portAcc = const Account(
      id: 12,
      name: 'Portfolio A',
      balance: 0.0,
      initialBalance: 0.0,
      type: AccountTypes.portfolio,
      isArchived: false,
    );

    // Insert into DB so DAO async loads succeed
    await db.into(db.assets).insert(eurAsset.toCompanion(false));
    await db.into(db.assets).insert(acmeAsset.toCompanion(false));
    await db.into(db.accounts).insert(cashAcc.toCompanion(false));
    await db.into(db.accounts).insert(portAcc.toCompanion(false));

    // No default assetsOnAccounts inserted here; tests insert when needed.

    preloadedAssets = [eurAsset, acmeAsset];
    preloadedAccounts = [cashAcc, portAcc];
  });

  tearDown(() async {
    await db.close();
  });

  /// Wait for heavy widgets (assets dropdown, clearing dropdown, portfolio dropdown)
  /// to appear after the TradeForm defers loading them.
  Future<void> waitForHeavyRender(WidgetTester tester,
      {int timeoutMs = 3000, int intervalMs = 50}) async {
    final tries = (timeoutMs / intervalMs).ceil();
    for (var i = 0; i < tries; i++) {
      await tester.pump(Duration(milliseconds: intervalMs));
      final hasAssets = find.byKey(const Key('assets_dropdown')).evaluate().isNotEmpty;
      final hasClearing = find.byKey(const Key('clearing_dropdown')).evaluate().isNotEmpty;
      final hasPortfolio = find.byKey(const Key('portfolio_dropdown')).evaluate().isNotEmpty;
      if (hasAssets && hasClearing && hasPortfolio) return;
    }
    // final settle to produce useful failure logs if something went wrong
    await tester.pumpAndSettle();
  }

  /// Pump the app and show the trade form inside a modal bottom sheet.
  Future<void> pumpWidget(WidgetTester tester, {Trade? trade, List<Asset>? preloadedAssetsParam, List<Account>? preloadedAccountsParam}) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<DatabaseProvider>.value(value: DatabaseProvider.instance),
            ChangeNotifierProvider<BaseCurrencyProvider>(create: (_) => currencyProvider),
          ],
          child: Builder(builder: (context) {
            return Scaffold(
              body: Center(
                child: ElevatedButton(
                  child: const Text('Show Trade Form'),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => MultiProvider(
                        providers: [
                          ChangeNotifierProvider<DatabaseProvider>.value(value: DatabaseProvider.instance),
                          ChangeNotifierProvider<BaseCurrencyProvider>.value(value: currencyProvider),
                        ],
                        child: TradeForm(
                          trade: trade,
                          preloadedAssets: preloadedAssetsParam,
                          preloadedAccounts: preloadedAccountsParam,
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          }),
        ),
      ),
    );

    // open the sheet and let animations finish
    await tester.tap(find.text('Show Trade Form'));
    await tester.pumpAndSettle();

    // wait for deferred heavy widgets to finish loading
    await waitForHeavyRender(tester);
  }

  /// Open form directly in the widget tree (not in a sheet) — useful for dialog tests.
  Future<void> pumpWidgetInPlace(WidgetTester tester, {Trade? trade, List<Asset>? preloadedAssetsParam, List<Account>? preloadedAccountsParam}) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<DatabaseProvider>.value(value: DatabaseProvider.instance),
          ChangeNotifierProvider<BaseCurrencyProvider>.value(value: currencyProvider),
        ],
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: TradeForm(trade: trade, preloadedAssets: preloadedAssetsParam, preloadedAccounts: preloadedAccountsParam)),
        ),
      ),
    );

    await waitForHeavyRender(tester);
  }

  // Helper: tap date field and accept default date/time pickers if present.
  Future<void> pickDateIfPossible(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(TextFormField, l10n.datetime));
    await tester.pumpAndSettle();
    if (find.text('OK').evaluate().isNotEmpty) {
      final dayCandidates = find.byWidgetPredicate(
              (w) => w is Text && RegExp(r'^\d+$').hasMatch((w.data ?? '')));
      if (dayCandidates.evaluate().isNotEmpty) {
        await tester.tap(dayCandidates.first);
        await tester.pumpAndSettle();
        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();
        if (find.text('OK').evaluate().isNotEmpty) {
          await tester.tap(find.text('OK'));
          await tester.pumpAndSettle();
        }
      }
    }
  }

  group('TradeForm - initial loading & UI', () {
    testWidgets('loads assets/accounts and excludes base currency asset', (tester) async {
      // Show form, pass preloaded lists so TradeForm uses them synchronously
      await pumpWidget(tester, preloadedAssetsParam: preloadedAssets, preloadedAccountsParam: preloadedAccounts);

      // Open assets dropdown and assert ACME visible and EUR filtered out
      final assetDropdown = find.byKey(const Key('assets_dropdown'));
      await tester.ensureVisible(assetDropdown);
      await tester.tap(assetDropdown);
      await tester.pumpAndSettle();

      expect(find.text('ACME'), findsOneWidget);
      expect(find.text('EUR'), findsNothing);

      // Select ACME to close the dropdown
      await tester.tap(find.text('ACME'));
      await tester.pumpAndSettle();

      // Clearing account dropdown
      final clearingDropdown = find.byKey(const Key('clearing_dropdown'));
      await tester.ensureVisible(clearingDropdown);
      await tester.tap(clearingDropdown);
      await tester.pumpAndSettle();

      expect(find.text('Cash A'), findsOneWidget);
      await tester.tap(find.text('Cash A'));
      await tester.pumpAndSettle();

      // Portfolio dropdown
      final portfolioDropdown = find.byKey(const Key('portfolio_dropdown'));
      await tester.ensureVisible(portfolioDropdown);
      await tester.tap(portfolioDropdown);
      await tester.pumpAndSettle();

      expect(find.text('Portfolio A'), findsOneWidget);

      await tester.pumpWidget(Container());
    });

    testWidgets('shows tax field only when tradeType is sell', (tester) async {
      await pumpWidget(tester, preloadedAssetsParam: preloadedAssets, preloadedAccountsParam: preloadedAccounts);

      // Initially tax field not visible
      expect(find.widgetWithText(TextFormField, l10n.tax), findsNothing);

      // Choose trade type = sell
      await tester.tap(find.byType(DropdownButtonFormField<TradeTypes>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text(TradeTypes.sell.name).last);
      await tester.pumpAndSettle();

      expect(find.widgetWithText(TextFormField, l10n.tax), findsOneWidget);

      await tester.pumpWidget(Container());
    });
  });

  group('TradeForm - fetching owned shares', () {
    testWidgets('fetchOwnedShares sets ownedShares when asset on account exists', (tester) async {
      // Insert an AssetOnAccount with shares = 5.0 for portAcc & acmeAsset
      await db.into(db.assetsOnAccounts).insert(AssetsOnAccountsCompanion.insert(
          accountId: portAcc.id, assetId: acmeAsset.id, shares: const Value(5.0), value: const Value(0.0)));

      await pumpWidget(tester, preloadedAssetsParam: preloadedAssets, preloadedAccountsParam: preloadedAccounts);

      // Select asset and portfolio account to trigger _fetchOwnedShares
      await tester.tap(find.byKey(const Key('assets_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ACME').last);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('portfolio_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Portfolio A').last);
      await tester.pumpAndSettle();

      // Now choose sell so shares validation checks ownedShares
      await tester.tap(find.byType(DropdownButtonFormField<TradeTypes>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text(TradeTypes.sell.name).last);
      await tester.pumpAndSettle();

      // Enter shares greater than owned
      await tester.enterText(find.widgetWithText(TextFormField, l10n.shares), '10');
      await tester.pump();

      // Press Save to trigger validation
      await tester.tap(find.widgetWithText(ElevatedButton, l10n.save));
      await tester.pump();

      expect(find.text(l10n.insufficientShares), findsOneWidget);

      await tester.pumpWidget(Container());
    });

    testWidgets('fetchOwnedShares sets 0 when asset not in account (exception path)', (tester) async {
      // Do not insert AssetOnAccount -> ownedShares should be treated as 0

      await pumpWidget(tester, preloadedAssetsParam: preloadedAssets, preloadedAccountsParam: preloadedAccounts);

      await tester.tap(find.byKey(const Key('assets_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ACME').last);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('portfolio_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Portfolio A').last);
      await tester.pumpAndSettle();

      // Choose sell
      await tester.tap(find.byType(DropdownButtonFormField<TradeTypes>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text(TradeTypes.sell.name).last);
      await tester.pumpAndSettle();

      // Enter shares > 0 but ownedShares is 0 so should trigger insufficientShares
      await tester.enterText(find.widgetWithText(TextFormField, l10n.shares), '1');
      await tester.pump();

      await tester.tap(find.widgetWithText(ElevatedButton, l10n.save));
      await tester.pump();

      expect(find.text(l10n.insufficientShares), findsOneWidget);

      await tester.pumpWidget(Container());
    });
  });

  group('TradeForm - field validators (fees, price, tax, clearing account)', () {
    testWidgets('costBasis validator rejects zero and negatives', (tester) async {
      await pumpWidget(tester, preloadedAssetsParam: preloadedAssets, preloadedAccountsParam: preloadedAccounts);

      // pick date if visible
      await pickDateIfPossible(tester);

      // choose buy
      await tester.tap(find.byType(DropdownButtonFormField<TradeTypes>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text(TradeTypes.buy.name).last);
      await tester.pumpAndSettle();

      // choose asset
      await tester.tap(find.byKey(const Key('assets_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ACME').last);
      await tester.pumpAndSettle();

      // choose clearing + portfolio
      await tester.tap(find.byKey(const Key('clearing_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cash A').last);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('portfolio_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Portfolio A').last);
      await tester.pumpAndSettle();

      // price = 0
      await tester.enterText(find.widgetWithText(TextFormField, l10n.costBasis), '0');
      await tester.pump();

      // shares and fee required for clearing account calc; enter valid values
      await tester.enterText(find.widgetWithText(TextFormField, l10n.shares), '1');
      await tester.enterText(find.widgetWithText(TextFormField, l10n.fee), '0');

      await tester.tap(find.widgetWithText(ElevatedButton, l10n.save));
      await tester.pump();

      expect(find.text(l10n.valueMustBeGreaterZero), findsOneWidget);

      // negative price
      await tester.enterText(find.widgetWithText(TextFormField, l10n.costBasis), '-1');
      await tester.pump();
      await tester.tap(find.widgetWithText(ElevatedButton, l10n.save));
      await tester.pump();
      expect(find.text(l10n.valueMustBeGreaterZero), findsOneWidget);

      await tester.pumpWidget(Container());
    });

    testWidgets('clearing account validator detects insufficient balance for buy', (tester) async {
      await pumpWidget(tester, preloadedAssetsParam: preloadedAssets, preloadedAccountsParam: preloadedAccounts);

      // pick date if present
      await pickDateIfPossible(tester);

      // choose buy
      await tester.tap(find.byType(DropdownButtonFormField<TradeTypes>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text(TradeTypes.buy.name).last);
      await tester.pumpAndSettle();

      // choose asset
      await tester.tap(find.byKey(const Key('assets_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ACME').last);
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextFormField, l10n.shares), '2');
      await tester.enterText(find.widgetWithText(TextFormField, l10n.costBasis), '1000');
      await tester.enterText(find.widgetWithText(TextFormField, l10n.fee), '0');
      await tester.pumpAndSettle();

      // choose clearing account with small balance and portfolio account
      await tester.tap(find.byKey(const Key('clearing_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cash A').last);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('portfolio_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Portfolio A').last);
      await tester.pumpAndSettle();

      // Save should detect insufficientBalance on clearingAccount
      await tester.tap(find.widgetWithText(ElevatedButton, l10n.save));
      await tester.pumpAndSettle();
      expect(find.text(l10n.insufficientBalance), findsOneWidget);

      await tester.pumpWidget(Container());
    });
  });

  group('TradeForm - saving and processTrade errors', () {
    testWidgets('successful save inserts trade and closes the sheet', (tester) async {
      await pumpWidget(tester, preloadedAssetsParam: preloadedAssets, preloadedAccountsParam: preloadedAccounts);

      // pick date if present
      await pickDateIfPossible(tester);

      // choose buy
      await tester.tap(find.byType(DropdownButtonFormField<TradeTypes>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text(TradeTypes.buy.name).last);
      await tester.pumpAndSettle();

      // choose asset and accounts
      await tester.tap(find.byKey(const Key('assets_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ACME').last);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('clearing_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cash A').last);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('portfolio_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Portfolio A').last);
      await tester.pumpAndSettle();

      // enter numeric fields
      await tester.enterText(find.widgetWithText(TextFormField, l10n.shares), '1');
      await tester.enterText(find.widgetWithText(TextFormField, l10n.costBasis), '10');
      await tester.enterText(find.widgetWithText(TextFormField, l10n.fee), '0');
      await tester.pump();

      // Save: should insert a trade and the modal should close
      await tester.tap(find.widgetWithText(ElevatedButton, l10n.save));
      await tester.pumpAndSettle();

      // Confirm a trade was created in DB
      final trades = await (db.select(db.trades)).get();
      expect(trades.length, 1);

      // The modal should have closed: TradeForm not present
      expect(find.byType(TradeForm), findsNothing);

      await tester.pumpWidget(Container());
    });

    testWidgets('processTrade throws -> shows error dialog', (tester) async {
      // Create a throwing DB and copy preloaded assets/accounts into it
      final throwingDb = ThrowingTradesDatabase(NativeDatabase.memory());
      for (final a in preloadedAssets) {
        await throwingDb.into(throwingDb.assets).insert(a.toCompanion(false));
      }
      for (final ac in preloadedAccounts) {
        await throwingDb.into(throwingDb.accounts).insert(ac.toCompanion(false));
      }

      // Reinitialize provider to point to throwing DB
      DatabaseProvider.instance.initialize(throwingDb);

      // Pump widget in-place (makes dialog assertions straightforward)
      await pumpWidgetInPlace(tester, preloadedAssetsParam: preloadedAssets, preloadedAccountsParam: preloadedAccounts);

      // pick date if present
      await pickDateIfPossible(tester);

      // choose buy branch and valid inputs
      await tester.tap(find.byType(DropdownButtonFormField<TradeTypes>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text(TradeTypes.buy.name).last);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('assets_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ACME').last);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('clearing_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cash A').last);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('portfolio_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Portfolio A').last);
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextFormField, l10n.shares), '1');
      await tester.enterText(find.widgetWithText(TextFormField, l10n.costBasis), '10');
      await tester.enterText(find.widgetWithText(TextFormField, l10n.fee), '0');
      await tester.pump();

      // Tap save — the ThrowingTradesDao will throw and the form catches and shows an error dialog
      await tester.tap(find.widgetWithText(ElevatedButton, l10n.save));
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsOneWidget);
      expect(find.text(l10n.error), findsOneWidget);

      // Restore original DB provider and close throwing DB
      DatabaseProvider.instance.initialize(db);
      await throwingDb.close();

      await tester.pumpWidget(Container());
    });
  });
}
