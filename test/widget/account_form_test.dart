import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xfin/database/app_database.dart';
import 'package:xfin/database/tables.dart';
import 'package:xfin/l10n/app_localizations.dart';
import 'package:xfin/providers/base_currency_provider.dart';
import 'package:xfin/widgets/account_form.dart';

// Mock classes
class MockNavigatorObserver extends Mock implements NavigatorObserver {}
class FakeRoute extends Fake implements Route<dynamic> {}

void main() {
  late AppDatabase db;
  late AppLocalizations l10n;
  late BaseCurrencyProvider currencyProvider;
  late MockNavigatorObserver mockObserver;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    registerFallbackValue(FakeRoute());
  });

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    mockObserver = MockNavigatorObserver();

    const locale = Locale('en');
    l10n = await AppLocalizations.delegate.load(locale);

    currencyProvider = BaseCurrencyProvider();
    await currencyProvider.initialize(locale);

    // Insert base currency asset so BaseCurrencyProvider has something to read
    await db.into(db.assets).insert(
      const AssetsCompanion(
        name: Value('EUR'),
        type: Value(AssetTypes.currency),
        tickerSymbol: Value('EUR'),
        value: Value(0),
        sharesOwned: Value(0),
        brokerCostBasis: Value(1),
        netCostBasis: Value(1),
        buyFeeTotal: Value(0),
      ),
    );
  });

  tearDown(() => db.close());

  Future<void> pumpForm(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
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
            Provider<AppDatabase>.value(value: db),
            ChangeNotifierProvider<BaseCurrencyProvider>.value(
              value: currencyProvider,
            ),
          ],
          child: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  child: const Text('Show Form'),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => MultiProvider(
                        providers: [
                          Provider<AppDatabase>.value(value: db),
                          ChangeNotifierProvider<BaseCurrencyProvider>.value(
                            value: currencyProvider,
                          ),
                        ],
                        child: const AccountForm(),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Show Form'));
    await tester.pumpAndSettle();
  }

  group('AccountForm - Save', () {
    testWidgets('Saving a cash account inserts correct values', (tester) async {
      await pumpForm(tester);

      await tester.enterText(find.byKey(const Key('account_name_field')), 'Cash A');
      await tester.enterText(find.byKey(const Key('initial_balance_field')), '150.50');

      await tester.tap(find.text(l10n.save));
      await tester.pumpAndSettle();

      final account = await (db.select(db.accounts)
        ..where((tbl) => tbl.name.equals('Cash A')))
          .getSingle();

      expect(account.balance, 150.50);
      expect(account.initialBalance, 150.50);
      expect(account.type, AccountTypes.cash);
    });

    testWidgets('Saving a portfolio account inserts 0 balance', (tester) async {
      await pumpForm(tester);

      await tester.enterText(find.byKey(const Key('account_name_field')), 'P A');

      await tester.tap(find.byKey(const Key('account_type_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.portfolio).last);
      await tester.pumpAndSettle();

      await tester.tap(find.text(l10n.save));
      await tester.pumpAndSettle();

      final account = await (db.select(db.accounts)
        ..where((tbl) => tbl.name.equals('P A')))
          .getSingle();

      expect(account.balance, 0);
      expect(account.initialBalance, 0);
      expect(account.type, AccountTypes.portfolio);
    });

    testWidgets('Navigator.pop is called on save', (tester) async {
      await pumpForm(tester);

      await tester.enterText(find.byKey(const Key('account_name_field')), 'TestPop');
      await tester.enterText(find.byKey(const Key('initial_balance_field')), '10');

      await tester.tap(find.text(l10n.save));
      await tester.pumpAndSettle();

      verify(() => mockObserver.didPop(any(), any())).called(greaterThan(0));
    });
  });

  group('UI Behavior', () {
    testWidgets('Balance field is hidden for portfolio accounts', (tester) async {
      await pumpForm(tester);

      await tester.tap(find.byKey(const Key('account_type_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.portfolio).last);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('initial_balance_field')), findsNothing);
    });

    testWidgets('Cancel closes the form', (tester) async {
      await pumpForm(tester);

      expect(find.byType(AccountForm), findsOneWidget);

      await tester.tap(find.text(l10n.cancel));
      await tester.pumpAndSettle();

      expect(find.byType(AccountForm), findsNothing);
    });
  });

  group('Validation', () {
    testWidgets('Empty name shows error', (tester) async {
      await pumpForm(tester);

      await tester.enterText(find.byKey(const Key('account_name_field')), '');
      await tester.enterText(find.byKey(const Key('initial_balance_field')), '5.0');

      await tester.tap(find.text(l10n.save));
      await tester.pump();

      expect(find.text(l10n.pleaseEnterAValue), findsOneWidget);
    });

    testWidgets('Duplicate name shows error', (tester) async {
      await db.into(db.accounts).insert(
        const AccountsCompanion(
          name: Value('Dup'),
          balance: Value(10),
          initialBalance: Value(10),
          type: Value(AccountTypes.cash),
        ),
      );

      await pumpForm(tester);

      await tester.enterText(find.byKey(const Key('account_name_field')), 'Dup');
      await tester.tap(find.text(l10n.save));
      await tester.pump();

      expect(find.text(l10n.accountAlreadyExists), findsOneWidget);
    });

    testWidgets('Empty balance shows error', (tester) async {
      await pumpForm(tester);

      await tester.enterText(find.byKey(const Key('account_name_field')), 'C1');
      await tester.enterText(find.byKey(const Key('initial_balance_field')), '');

      await tester.tap(find.text(l10n.save));
      await tester.pump();

      expect(find.text(l10n.pleaseEnterAValue), findsOneWidget);
    });

    testWidgets('Invalid balance shows error', (tester) async {
      await pumpForm(tester);

      await tester.enterText(find.byKey(const Key('account_name_field')), 'C1');
      await tester.enterText(find.byKey(const Key('initial_balance_field')), 'abc');

      await tester.tap(find.text(l10n.save));
      await tester.pump();

      expect(find.text(l10n.invalidInput), findsOneWidget);
    });

    testWidgets('Negative balance shows error', (tester) async {
      await pumpForm(tester);

      await tester.enterText(find.byKey(const Key('account_name_field')), 'C1');
      await tester.enterText(find.byKey(const Key('initial_balance_field')), '-5');

      await tester.tap(find.text(l10n.save));
      await tester.pump();

      expect(find.text(l10n.valueMustBeGreaterEqualZero), findsOneWidget);
    });

    testWidgets('Too many decimals shows error', (tester) async {
      await pumpForm(tester);

      await tester.enterText(find.byKey(const Key('account_name_field')), 'C1');
      await tester.enterText(find.byKey(const Key('initial_balance_field')), '10.123');

      await tester.tap(find.text(l10n.save));
      await tester.pump();

      expect(find.text(l10n.tooManyDecimalPlaces), findsOneWidget);
    });
  });

  group('_getAccountTypeName coverage', () {
    testWidgets('Returns correct label for each type', (tester) async {
      await pumpForm(tester);

      expect(find.text(l10n.cash), findsOneWidget);
      await tester.tap(find.byKey(const Key('account_type_dropdown')));
      await tester.pumpAndSettle();
      expect(find.text(l10n.portfolio), findsWidgets);
    });
  });
}