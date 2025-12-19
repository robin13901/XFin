import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:xfin/database/app_database.dart';
import 'package:xfin/database/daos/accounts_dao.dart';
import 'package:xfin/database/daos/assets_dao.dart';
import 'package:xfin/database/daos/assets_on_accounts_dao.dart';
import 'package:xfin/database/daos/trades_dao.dart';
import 'package:xfin/database/tables.dart';
import 'package:xfin/l10n/app_localizations.dart';
import 'package:xfin/providers/base_currency_provider.dart';
import 'package:xfin/widgets/trade_form.dart';

class MockAppDatabase extends Mock implements AppDatabase {}

class MockAssetsDao extends Mock implements AssetsDao {}

class MockAccountsDao extends Mock implements AccountsDao {}

class MockAssetsOnAccountsDao extends Mock implements AssetsOnAccountsDao {}

class MockTradesDao extends Mock implements TradesDao {}

class MockBaseCurrencyProvider extends Mock
    with ChangeNotifier
    implements BaseCurrencyProvider {}

class MockNavigatorObserver extends Mock implements NavigatorObserver {}

class FakeRoute extends Fake implements Route<dynamic> {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAppDatabase mockDb;
  late MockAssetsDao mockAssetsDao;
  late MockAccountsDao mockAccountsDao;
  late MockAssetsOnAccountsDao mockAssetsOnAccountsDao;
  late MockTradesDao mockTradesDao;
  late MockBaseCurrencyProvider mockCurrencyProvider;
  late AppLocalizations l10n;
  late MockNavigatorObserver mockObserver;

  setUpAll(() {
    registerFallbackValue(FakeRoute());
    registerFallbackValue(const TradesCompanion());
    // Also fallback Locale if needed by mocktail anywhere
    registerFallbackValue(const Locale('en', 'US'));
  });

  setUp(() async {
    mockDb = MockAppDatabase();
    mockAssetsDao = MockAssetsDao();
    mockAccountsDao = MockAccountsDao();
    mockAssetsOnAccountsDao = MockAssetsOnAccountsDao();
    mockTradesDao = MockTradesDao();
    mockCurrencyProvider = MockBaseCurrencyProvider();
    mockObserver = MockNavigatorObserver();

    // default currency provider values
    when(() => mockCurrencyProvider.symbol).thenReturn('€');
    when(() => mockCurrencyProvider.tickerSymbol).thenReturn('EUR');

    // wire DAOs on the database
    when(() => mockDb.assetsDao).thenReturn(mockAssetsDao);
    when(() => mockDb.accountsDao).thenReturn(mockAccountsDao);
    when(() => mockDb.assetsOnAccountsDao).thenReturn(mockAssetsOnAccountsDao);
    when(() => mockDb.tradesDao).thenReturn(mockTradesDao);

    // real localization
    const locale = Locale('en');
    l10n = await AppLocalizations.delegate.load(locale);

    // Default behavior: by default have empty asset/account lists (tests will override)
    when(() => mockAssetsDao.watchAllAssets())
        .thenAnswer((_) => Stream.value(<Asset>[]));
    when(() => mockAccountsDao.watchAllAccounts())
        .thenAnswer((_) => Stream.value(<Account>[]));
  });

  Widget buildTestWidget() {
    return MaterialApp(
      navigatorObservers: [mockObserver],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: MultiProvider(
        providers: [
          Provider<AppDatabase>.value(value: mockDb),
          ChangeNotifierProvider<BaseCurrencyProvider>.value(
              value: mockCurrencyProvider),
        ],
        child: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                child: const Text('Show Trade Form'),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => MultiProvider(
                      providers: [
                        Provider<AppDatabase>.value(value: mockDb),
                        ChangeNotifierProvider<BaseCurrencyProvider>.value(
                          value: mockCurrencyProvider,
                        ),
                      ],
                      child: const TradeForm(),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> openForm(WidgetTester tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.tap(find.text('Show Trade Form'));
    await tester.pumpAndSettle();
  }

  group('TradeForm - initial loading & UI', () {
    testWidgets('loads assets/accounts and excludes base currency asset',
        (tester) async {
      const eur = Asset(
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
          isArchived: false);
      const acme = Asset(
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
          isArchived: false);

      const cashAcc = Account(
          id: 11,
          name: 'Cash A',
          balance: 1000.0,
          initialBalance: 1000.0,
          type: AccountTypes.cash,
          isArchived: false);
      const portAcc = Account(
          id: 12,
          name: 'Portfolio A',
          balance: 0.0,
          initialBalance: 0.0,
          type: AccountTypes.portfolio,
          isArchived: false);

      when(() => mockAssetsDao.watchAllAssets())
          .thenAnswer((_) => Stream.value([eur, acme]));
      when(() => mockAccountsDao.watchAllAccounts())
          .thenAnswer((_) => Stream.value([cashAcc, portAcc]));

      await openForm(tester);
      await tester.pumpAndSettle();

      final assetDropdown = find.byWidgetPredicate(
        (w) => w is DropdownButtonFormField<Asset>,
      );

      await tester.ensureVisible(assetDropdown);
      await tester.tap(assetDropdown);
      await tester.pumpAndSettle();

      expect(find.text('ACME'), findsOneWidget);
      expect(find.text('EUR'), findsNothing);

      // Close menu by selecting ACME
      await tester.tap(find.text('ACME'));
      await tester.pumpAndSettle();

      final clearingDropdown = find.byWidgetPredicate(
        (w) =>
            w is DropdownButtonFormField<Account> &&
            (w.decoration.labelText?.contains('Clearing') ?? false),
      );

      await tester.ensureVisible(clearingDropdown);
      await tester.tap(clearingDropdown);
      await tester.pumpAndSettle();

      expect(find.text('Cash A'), findsOneWidget);

      // Close menu by selecting Cash A
      await tester.tap(find.text('Cash A'));
      await tester.pumpAndSettle();

      final portfolioDropdown = find.byWidgetPredicate(
        (w) =>
            w is DropdownButtonFormField<Account> &&
            (w.decoration.labelText?.contains(l10n.investmentAccount) ?? false),
      );

      await tester.ensureVisible(portfolioDropdown);
      await tester.tap(portfolioDropdown);
      await tester.pumpAndSettle();

      expect(find.text('Portfolio A'), findsOneWidget);
    });

    testWidgets('shows tax field only when tradeType is sell', (tester) async {
      const asset = Asset(
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
          isArchived: false);
      const cashAcc = Account(
          id: 11,
          name: 'Cash A',
          balance: 1000.0,
          initialBalance: 1000.0,
          type: AccountTypes.cash,
          isArchived: false);
      const portAcc = Account(
          id: 12,
          name: 'Portfolio A',
          balance: 0.0,
          initialBalance: 0.0,
          type: AccountTypes.portfolio,
          isArchived: false);

      when(() => mockAssetsDao.watchAllAssets())
          .thenAnswer((_) => Stream.value([asset]));
      when(() => mockAccountsDao.watchAllAccounts())
          .thenAnswer((_) => Stream.value([cashAcc, portAcc]));

      await openForm(tester);

      // Initially tradeType null -> tax field not visible
      expect(find.widgetWithText(TextFormField, l10n.tax), findsNothing);

      // Choose trade type = sell
      await tester.tap(find.byType(DropdownButtonFormField<TradeTypes>).first);
      await tester.pumpAndSettle();

      // The dropdown for types uses type.name; pick 'sell' (TradeTypes.sell.name == 'sell')
      await tester.tap(find.text(TradeTypes.sell.name).last);
      await tester.pumpAndSettle();

      // Now tax field should be present
      expect(find.widgetWithText(TextFormField, l10n.tax), findsOneWidget);
    });
  });

  group('TradeForm - fetching owned shares', () {
    testWidgets(
        'fetchOwnedShares sets ownedShares when asset on account exists',
        (tester) async {
      const asset = Asset(
          id: 2,
          name: 'ACME',
          tickerSymbol: 'ACME',
          currencySymbol: '',
          type: AssetTypes.stock,
          value: 0,
          shares: 0,
          netCostBasis: 1,
          brokerCostBasis: 1,
          buyFeeTotal: 0,
          isArchived: false);
      const cashAcc = Account(
          id: 11,
          name: 'Cash A',
          balance: 1000.0,
          initialBalance: 1000.0,
          type: AccountTypes.cash,
          isArchived: false);
      const portAcc = Account(
          id: 12,
          name: 'Portfolio A',
          balance: 0.0,
          initialBalance: 0.0,
          type: AccountTypes.portfolio,
          isArchived: false);

      when(() => mockAssetsDao.watchAllAssets())
          .thenAnswer((_) => Stream.value([asset]));
      when(() => mockAccountsDao.watchAllAccounts())
          .thenAnswer((_) => Stream.value([cashAcc, portAcc]));

      // when getAssetOnAccount called with portfolio id and asset id, return an object with shares = 5
      final aOnAcc = AssetOnAccount(
        assetId: asset.id,
        accountId: portAcc.id,
        shares: 5.0,
        value: 0.0,
        netCostBasis: 0.0,
        brokerCostBasis: 0.0,
        buyFeeTotal: 0.0,
      );
      when(() =>
              mockAssetsOnAccountsDao.getAOA(portAcc.id, asset.id))
          .thenAnswer((_) async => aOnAcc);

      await openForm(tester);

      // Select asset and portfolio account to trigger _fetchOwnedShares
      await tester.tap(find.byType(DropdownButtonFormField<Asset>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('ACME').last);
      await tester.pumpAndSettle();

      await tester.tap(find.byType(DropdownButtonFormField<Account>).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Portfolio A').last);
      await tester.pumpAndSettle();

      // Now enter trade type = sell so shares validation will consider ownedShares
      await tester.tap(find.byType(DropdownButtonFormField<TradeTypes>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text(TradeTypes.sell.name).last);
      await tester.pumpAndSettle();

      // Enter shares greater than owned
      await tester.enterText(
          find.widgetWithText(TextFormField, l10n.shares), '10');
      await tester.pump();

      // Press Save to trigger validation
      await tester.tap(find.widgetWithText(ElevatedButton, l10n.save));
      await tester.pump();

      // Expect insufficientShares message (from l10n via Validator)
      expect(find.text(l10n.insufficientShares), findsOneWidget);
    });

    testWidgets(
        'fetchOwnedShares sets 0 when asset not in account (exception path)',
        (tester) async {
      const asset = Asset(
          id: 2,
          name: 'ACME',
          tickerSymbol: 'ACME',
          currencySymbol: '',
          type: AssetTypes.stock,
          value: 0,
          shares: 0,
          netCostBasis: 1,
          brokerCostBasis: 1,
          buyFeeTotal: 0,
          isArchived: false);
      const cashAcc = Account(
          id: 11,
          name: 'Cash A',
          balance: 1000.0,
          initialBalance: 1000.0,
          type: AccountTypes.cash,
          isArchived: false);
      const portAcc = Account(
          id: 12,
          name: 'Portfolio A',
          balance: 0.0,
          initialBalance: 0.0,
          type: AccountTypes.portfolio,
          isArchived: false);

      when(() => mockAssetsDao.watchAllAssets())
          .thenAnswer((_) => Stream.value([asset]));
      when(() => mockAccountsDao.watchAllAccounts())
          .thenAnswer((_) => Stream.value([cashAcc, portAcc]));

      // Simulate asset not present by throwing
      when(() =>
              mockAssetsOnAccountsDao.getAOA(portAcc.id, asset.id))
          .thenThrow(Exception('not found'));

      await openForm(tester);

      await tester.tap(find.byType(DropdownButtonFormField<Asset>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('ACME').last);
      await tester.pumpAndSettle();

      await tester.tap(find.byType(DropdownButtonFormField<Account>).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Portfolio A').last);
      await tester.pumpAndSettle();

      // Choose sell
      await tester.tap(find.byType(DropdownButtonFormField<TradeTypes>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text(TradeTypes.sell.name).last);
      await tester.pumpAndSettle();

      // Enter shares > 0 but since ownedShares=0 should get insufficientShares
      await tester.enterText(
          find.widgetWithText(TextFormField, l10n.shares), '1');
      await tester.pump();

      await tester.tap(find.widgetWithText(ElevatedButton, l10n.save));
      await tester.pump();

      expect(find.text(l10n.insufficientShares), findsOneWidget);
    });
  });

  group('TradeForm - field validators (fees, price, tax, clearing account)',
      () {

    testWidgets('costBasis validator rejects zero and negatives',
        (tester) async {
      const asset = Asset(
          id: 2,
          name: 'ACME',
          tickerSymbol: 'ACME',
          currencySymbol: '',
          type: AssetTypes.stock,
          value: 0,
          shares: 0,
          netCostBasis: 1,
          brokerCostBasis: 1,
          buyFeeTotal: 0,
          isArchived: false);
      const cashAcc = Account(
          id: 11,
          name: 'Cash A',
          balance: 1000.0,
          initialBalance: 1000.0,
          type: AccountTypes.cash,
          isArchived: false);
      const portAcc = Account(
          id: 12,
          name: 'Portfolio A',
          balance: 0.0,
          initialBalance: 0.0,
          type: AccountTypes.portfolio,
          isArchived: false);

      when(() => mockAssetsDao.watchAllAssets())
          .thenAnswer((_) => Stream.value([asset]));
      when(() => mockAccountsDao.watchAllAccounts())
          .thenAnswer((_) => Stream.value([cashAcc, portAcc]));

      await openForm(tester);

      // fill required fields except price
      // pick date as above (best effort)
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

      await tester.tap(find.byType(DropdownButtonFormField<TradeTypes>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text(TradeTypes.buy.name).last);
      await tester.pumpAndSettle();

      await tester.tap(find.byType(DropdownButtonFormField<Asset>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('ACME').last);
      await tester.pumpAndSettle();

      await tester.tap(find.byType(DropdownButtonFormField<Account>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cash A').last);
      await tester.pumpAndSettle();

      await tester.tap(find.byType(DropdownButtonFormField<Account>).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Portfolio A').last);
      await tester.pumpAndSettle();

      // price = 0
      await tester.enterText(
          find.widgetWithText(TextFormField, l10n.costBasis), '0');
      await tester.pump();

      // shares and fee required for clearing account calc; enter valid values
      await tester.enterText(
          find.widgetWithText(TextFormField, l10n.shares), '1');
      await tester.enterText(
          find.widgetWithText(TextFormField, l10n.fee), '0');

      await tester.tap(find.widgetWithText(ElevatedButton, l10n.save));
      await tester.pump();

      expect(find.text(l10n.valueMustBeGreaterZero), findsOneWidget);

      // negative price
      await tester.enterText(
          find.widgetWithText(TextFormField, l10n.costBasis), '-1');
      await tester.pump();
      await tester.tap(find.widgetWithText(ElevatedButton, l10n.save));
      await tester.pump();
      expect(find.text(l10n.valueMustBeGreaterZero), findsOneWidget);
    });

    testWidgets(
        'clearing account validator detects insufficient balance for buy',
        (tester) async {
      const asset = Asset(
          id: 2,
          name: 'ACME',
          tickerSymbol: 'ACME',
          currencySymbol: '',
          type: AssetTypes.stock,
          value: 0,
          shares: 0,
          netCostBasis: 1,
          brokerCostBasis: 1,
          buyFeeTotal: 0,
          isArchived: false);
      // cash account with low balance
      const cashAcc = Account(
          id: 11,
          name: 'Cash A',
          balance: 5.0,
          initialBalance: 5.0,
          type: AccountTypes.cash,
          isArchived: false);
      const portAcc = Account(
          id: 12,
          name: 'Portfolio A',
          balance: 0.0,
          initialBalance: 0.0,
          type: AccountTypes.portfolio,
          isArchived: false);

      when(() => mockAssetsDao.watchAllAssets())
          .thenAnswer((_) => Stream.value([asset]));
      when(() => mockAccountsDao.watchAllAccounts())
          .thenAnswer((_) => Stream.value([cashAcc, portAcc]));

      await openForm(tester);

      // pick date
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

      // choose buy
      await tester.tap(find.byType(DropdownButtonFormField<TradeTypes>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text(TradeTypes.buy.name).last);
      await tester.pumpAndSettle();

      // choose asset
      await tester.tap(find.byType(DropdownButtonFormField<Asset>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('ACME').last);
      await tester.pumpAndSettle();

      // enter shares=1 costBasis=10 fee=0 => needed 10
      await tester.enterText(
          find.widgetWithText(TextFormField, l10n.shares), '1');
      await tester.enterText(
          find.widgetWithText(TextFormField, l10n.costBasis), '10');
      await tester.enterText(
          find.widgetWithText(TextFormField, l10n.fee), '0');
      await tester.pump();

      // choose clearing account with small balance and portfolio account
      await tester.tap(find.byType(DropdownButtonFormField<Account>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cash A').last);
      await tester.pumpAndSettle();

      await tester.tap(find.byType(DropdownButtonFormField<Account>).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Portfolio A').last);
      await tester.pumpAndSettle();

      // Save should detect insufficientBalance on clearingAccount
      await tester.tap(find.widgetWithText(ElevatedButton, l10n.save));
      await tester.pump();

      expect(find.text(l10n.insufficientBalance), findsOneWidget);
    });
  });

  group('TradeForm - saving and processTrade errors', () {
    testWidgets('successful save calls tradesDao.processTrade and pops',
        (tester) async {
      const asset = Asset(
          id: 2,
          name: 'ACME',
          tickerSymbol: 'ACME',
          currencySymbol: '',
          type: AssetTypes.stock,
          value: 0,
          shares: 0,
          netCostBasis: 1,
          brokerCostBasis: 1,
          buyFeeTotal: 0,
          isArchived: false);
      const cashAcc = Account(
          id: 11,
          name: 'Cash A',
          balance: 1000.0,
          initialBalance: 1000.0,
          type: AccountTypes.cash,
          isArchived: false);
      const portAcc = Account(
          id: 12,
          name: 'Portfolio A',
          balance: 0.0,
          initialBalance: 0.0,
          type: AccountTypes.portfolio,
          isArchived: false);

      when(() => mockAssetsDao.watchAllAssets())
          .thenAnswer((_) => Stream.value([asset]));
      when(() => mockAccountsDao.watchAllAccounts())
          .thenAnswer((_) => Stream.value([cashAcc, portAcc]));

      // stub getAssetOnAccount to return 0 shares so sell validations fail if used; tests will choose buy flow
      when(() => mockAssetsOnAccountsDao.getAOA(any(), any()))
          .thenAnswer((_) async {
        return AssetOnAccount(
            assetId: asset.id,
            accountId: portAcc.id,
            shares: 0.0,
            value: 0.0,
            netCostBasis: 0.0,
            brokerCostBasis: 0.0,
            buyFeeTotal: 0.0);
      });

      // stub tradesDao.processTrade to succeed
      when(() => mockTradesDao.processTrade(any())).thenAnswer((_) async => 1);

      when(() => mockAccountsDao.leadsToInconsistentBalanceHistory(
          newTrade: any(named: 'newTrade'))).thenAnswer((_) async => false);

      await openForm(tester);

      // pick date
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

      // choose buy flow
      await tester.tap(find.byType(DropdownButtonFormField<TradeTypes>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text(TradeTypes.buy.name).last);
      await tester.pumpAndSettle();

      // choose asset and accounts
      await tester.tap(find.byType(DropdownButtonFormField<Asset>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('ACME').last);
      await tester.pumpAndSettle();

      await tester.tap(find.byType(DropdownButtonFormField<Account>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cash A').last);
      await tester.pumpAndSettle();

      await tester.tap(find.byType(DropdownButtonFormField<Account>).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Portfolio A').last);
      await tester.pumpAndSettle();

      // enter numeric fields
      await tester.enterText(
          find.widgetWithText(TextFormField, l10n.shares), '1');
      await tester.enterText(
          find.widgetWithText(TextFormField, l10n.costBasis), '10');
      await tester.enterText(
          find.widgetWithText(TextFormField, l10n.fee), '0');
      await tester.pump();

      // Save: should call processTrade and then pop
      await tester.tap(find.widgetWithText(ElevatedButton, l10n.save));
      await tester.pumpAndSettle();

      verify(() => mockTradesDao.processTrade(any())).called(1);
      verify(() => mockObserver.didPop(any(), any())).called(greaterThan(0));
    });

    testWidgets('processTrade throws -> shows SnackBar with error',
        (tester) async {
      const asset = Asset(
          id: 2,
          name: 'ACME',
          tickerSymbol: 'ACME',
          currencySymbol: '',
          type: AssetTypes.stock,
          value: 0,
          shares: 0,
          netCostBasis: 1,
          brokerCostBasis: 1,
          buyFeeTotal: 0,
          isArchived: false);
      const cashAcc = Account(
          id: 11,
          name: 'Cash A',
          balance: 1000.0,
          initialBalance: 1000.0,
          type: AccountTypes.cash,
          isArchived: false);
      const portAcc = Account(
          id: 12,
          name: 'Portfolio A',
          balance: 0.0,
          initialBalance: 0.0,
          type: AccountTypes.portfolio,
          isArchived: false);

      when(() => mockAssetsDao.watchAllAssets())
          .thenAnswer((_) => Stream.value([asset]));
      when(() => mockAccountsDao.watchAllAccounts())
          .thenAnswer((_) => Stream.value([cashAcc, portAcc]));

      // stub getAssetOnAccount for completeness
      when(() => mockAssetsOnAccountsDao.getAOA(any(), any()))
          .thenAnswer((_) async {
        return AssetOnAccount(
            assetId: asset.id,
            accountId: portAcc.id,
            shares: 0.0,
            value: 0.0,
            netCostBasis: 0.0,
            brokerCostBasis: 0.0,
            buyFeeTotal: 0.0);
      });

      // Make processTrade throw
      when(() => mockTradesDao.processTrade(any()))
          .thenThrow(Exception('boom'));

      when(() => mockAccountsDao.leadsToInconsistentBalanceHistory(
          newTrade: any(named: 'newTrade'))).thenAnswer((_) async => false);

      await openForm(tester);

      // pick date
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

      // choose buy branch and valid inputs
      await tester.tap(find.byType(DropdownButtonFormField<TradeTypes>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text(TradeTypes.buy.name).last);
      await tester.pumpAndSettle();

      await tester.tap(find.byType(DropdownButtonFormField<Asset>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('ACME').last);
      await tester.pumpAndSettle();

      await tester.tap(find.byType(DropdownButtonFormField<Account>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cash A').last);
      await tester.pumpAndSettle();

      await tester.tap(find.byType(DropdownButtonFormField<Account>).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Portfolio A').last);
      await tester.pumpAndSettle();

      await tester.enterText(
          find.widgetWithText(TextFormField, l10n.shares), '1');
      await tester.enterText(
          find.widgetWithText(TextFormField, l10n.costBasis), '10');
      await tester.enterText(
          find.widgetWithText(TextFormField, l10n.fee), '0');
      await tester.pump();

      await tester.tap(find.widgetWithText(ElevatedButton, l10n.save));
      await tester.pumpAndSettle();

      // An error SnackBar should display
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.textContaining('Error processing trade:'), findsOneWidget);
    });
  });
}
