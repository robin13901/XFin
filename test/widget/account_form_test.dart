import 'package:drift/drift.dart' hide isNotNull, isNull;
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
import 'package:xfin/widgets/account_form.dart';

void main() {
  late AppDatabase db;
  late AppLocalizations l10n;
  late BaseCurrencyProvider currencyProvider;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    const locale = Locale('en');
    l10n = await AppLocalizations.delegate.load(locale);

    currencyProvider = BaseCurrencyProvider();
    await currencyProvider.initialize(locale);

    // Base currency asset (ID 1) expected by the app
    await db.into(db.assets).insert(const AssetsCompanion(
      name: Value('EUR'),
      type: Value(AssetTypes.fiat),
      tickerSymbol: Value('EUR'),
      value: Value(0),
      shares: Value(0),
      brokerCostBasis: Value(1),
      netCostBasis: Value(1),
      buyFeeTotal: Value(0),
    ));
  });

  tearDown(() async {
    await db.close();
  });

  /// Pumps the AccountForm inside a Scaffold + MaterialApp
  Future<void> pumpAccountForm(WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<AppDatabase>.value(value: db),
          ChangeNotifierProvider<BaseCurrencyProvider>.value(value: currencyProvider),
        ],
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Center(child: AccountForm()),
          ),
        ),
      ),
    );

    // First frame + post-frame callbacks
    await tester.pump();
  }

  group('AccountForm', () {
    testWidgets(
      'shows validation error when name is empty and prevents next',
          (tester) async {
        await pumpAccountForm(tester);

        // Step 1 visible
        expect(find.byKey(const Key('account_name_field')), findsOneWidget);
        expect(find.byKey(const Key('account_type_dropdown')), findsOneWidget);

        // Tap Next without name
        await tester.tap(find.text(l10n.next));
        await tester.pump();

        expect(find.text(l10n.requiredField), findsWidgets);
      },
    );

    testWidgets(
      'navigates to step 2 when name and type are valid',
          (tester) async {
        await pumpAccountForm(tester);

        await tester.enterText(
          find.byKey(const Key('account_name_field')),
          'My Account',
        );

        // Change type
        await tester.tap(find.byKey(const Key('account_type_dropdown')));
        await tester.pumpAndSettle();
        await tester.tap(find.text(l10n.portfolio).last);
        await tester.pumpAndSettle();

        // Go to step 2
        await tester.tap(find.text(l10n.next));
        await tester.pumpAndSettle();

        // Step 2 UI should be visible
        expect(find.byKey(const Key('assets_dropdown')), findsOneWidget);
        expect(find.text(l10n.addAsset), findsOneWidget);
      },
    );

    testWidgets(
      'can add an asset to buffer and prevents duplicates (SnackBar)',
          (tester) async {
        // Extra asset
        await db.into(db.assets).insert(const AssetsCompanion(
          name: Value('US Dollar'),
          type: Value(AssetTypes.fiat),
          tickerSymbol: Value('USD'),
          value: Value(0),
          shares: Value(0),
          brokerCostBasis: Value(1),
          netCostBasis: Value(1),
          buyFeeTotal: Value(0),
        ));

        await pumpAccountForm(tester);

        // Step 1
        await tester.enterText(
          find.byKey(const Key('account_name_field')),
          'Account A',
        );
        await tester.tap(find.text(l10n.next));
        await tester.pumpAndSettle();

        // Select asset
        await tester.tap(find.byKey(const Key('assets_dropdown')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('US Dollar').last);
        await tester.pumpAndSettle();

        // Enter values
        await tester.enterText(find.byKey(const Key('shares_field')), '10');
        await tester.enterText(find.byKey(const Key('cost_basis_field')), '2');

        // Add asset
        await tester.tap(find.text(l10n.addAsset));
        await tester.pump();

        expect(find.byType(ListTile), findsWidgets);

        // Try to add same asset again
        await tester.tap(find.byKey(const Key('assets_dropdown')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('US Dollar').last);
        await tester.pumpAndSettle();

        await tester.enterText(find.byKey(const Key('shares_field')), '5');
        await tester.enterText(find.byKey(const Key('cost_basis_field')), '1');

        await tester.tap(find.text(l10n.addAsset));
        await tester.pump();

        expect(find.text(l10n.assetAlreadyAdded), findsOneWidget);
      },
    );

    testWidgets(
      'save form creates account and writes assetsOnAccounts and updates assets',
          (tester) async {
        final assetId = await db.into(db.assets).insert(const AssetsCompanion(
          name: Value('Stock X'),
          type: Value(AssetTypes.stock),
          tickerSymbol: Value('STX'),
          value: Value(0),
          shares: Value(0),
          brokerCostBasis: Value(1),
          netCostBasis: Value(1),
          buyFeeTotal: Value(0),
        ));

        await pumpAccountForm(tester);

        // Step 1
        await tester.enterText(
          find.byKey(const Key('account_name_field')),
          'Portfolio Acc',
        );
        await tester.tap(find.byKey(const Key('account_type_dropdown')));
        await tester.pumpAndSettle();
        await tester.tap(find.text(l10n.portfolio).last);
        await tester.pumpAndSettle();

        await tester.tap(find.text(l10n.next));
        await tester.pumpAndSettle();

        // Step 2: add asset
        await tester.tap(find.byKey(const Key('assets_dropdown')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Stock X').last);
        await tester.pumpAndSettle();

        await tester.enterText(find.byKey(const Key('shares_field')), '3');
        await tester.enterText(find.byKey(const Key('cost_basis_field')), '5');

        await tester.tap(find.text(l10n.addAsset));
        await tester.pump();

        // Save
        await tester.tap(find.text(l10n.save));
        await tester.pump();

        // Verify DB state
        final accounts = await db.select(db.accounts).get();
        expect(accounts, hasLength(1));
        expect(accounts.first.initialBalance, 15.0);
        expect(accounts.first.balance, 15.0);

        final aoas = await db.select(db.assetsOnAccounts).get();
        expect(aoas.where((a) => a.accountId == accounts.first.id), isNotEmpty);

        final updatedAsset = await db.assetsDao.getAsset(assetId);
        expect(updatedAsset.shares >= 3, isTrue);
        expect(updatedAsset.value >= 15, isTrue);
      },
    );
  });
}