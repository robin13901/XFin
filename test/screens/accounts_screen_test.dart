import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xfin/database/app_database.dart';
import 'package:xfin/database/tables.dart';
import 'package:xfin/l10n/app_localizations.dart';
import 'package:xfin/providers/base_currency_provider.dart';
import 'package:xfin/screens/accounts_screen.dart';
import 'package:xfin/widgets/account_form.dart';

// A test database that uses an in-memory sqlite database.
class TestDatabase {
  late final AppDatabase appDatabase;

  TestDatabase() {
    appDatabase = AppDatabase(NativeDatabase.memory());
  }

  Future<void> close() {
    return appDatabase.close();
  }

  Future<int> createAccount(String name,
      {double balance = 100.0, bool isArchived = false}) async {
    return await appDatabase.accountsDao.createAccount(
      AccountsCompanion(
        name: Value(name),
        balance: Value(balance),
        initialBalance: Value(balance),
        type: const Value(AccountTypes.cash),
        isArchived: Value(isArchived),
      ),
    );
  }

  Future<Booking> createBooking({
    required int accountId,
    required double amount,
    required String category,
    DateTime? date,
  }) async {
    final dateAsInt = date != null
        ? int.parse(date.toIso8601String().substring(0, 10).replaceAll('-', ''))
        : 20230101;
    final companion = BookingsCompanion(
      date: Value(dateAsInt),
      category: Value(category),
      amount: Value(amount),
      accountId: Value(accountId),
      isGenerated: const Value(false),
    );
    await appDatabase.bookingsDao.createBooking(companion);
    return await (appDatabase.select(appDatabase.bookings)
          ..where((tbl) => tbl.category.equals(category)))
        .getSingle();
  }
}

void main() {
  late BaseCurrencyProvider currencyProvider;
  late TestDatabase db;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  group('AccountsScreen', () {
    const account = Account(
      id: 1,
      // ID will be auto-incremented by drift, so this is just a placeholder
      name: 'Test Account',
      balance: 1000,
      initialBalance: 1000,
      type: AccountTypes.cash,
      isArchived: false,
    );

    const archivedAccount = Account(
      id: 2,
      // ID will be auto-incremented by drift, so this is just a placeholder
      name: 'Archived Account',
      balance: 500,
      initialBalance: 500,
      type: AccountTypes.cash,
      isArchived: true,
    );

    setUp(() async {
      db = TestDatabase();
      const locale = Locale('en');
      currencyProvider = BaseCurrencyProvider();
      await currencyProvider.initialize(locale);

      // Create base currency asset
      await db.appDatabase.into(db.appDatabase.assets).insert(
          const AssetsCompanion(
              name: Value('EUR'),
              type: Value(AssetTypes.currency),
              tickerSymbol: Value('EUR'),
              value: Value(0),
              sharesOwned: Value(0),
              brokerCostBasis: Value(1),
              netCostBasis: Value(1),
              buyFeeTotal: Value(0)));
    });

    tearDown(() async {
      await db.close();
    });

    Future<AppLocalizations> pumpWidget(WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<AppDatabase>.value(
              value: db.appDatabase,
            ),
            ChangeNotifierProvider<BaseCurrencyProvider>.value(
              value: currencyProvider,
            ),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: AccountsScreen(),
          ),
        ),
      );
      return AppLocalizations.of(tester.element(find.byType(AccountsScreen)))!;
    }

    testWidgets(
        'shows loading indicator and then empty message',
        (tester) => tester.runAsync(() async {
              final l10n = await pumpWidget(tester);
              expect(find.byType(CircularProgressIndicator), findsOneWidget);

              await tester.pumpAndSettle();

              expect(find.text(l10n.noActiveAccounts), findsOneWidget);
              expect(find.byType(ListView), findsNothing);

              await tester.pumpWidget(Container());
            }));

    testWidgets(
        'should display active accounts',
        (tester) => tester.runAsync(() async {
              await db.appDatabase.accountsDao
                  .createAccount(account.toCompanion(true));

              await pumpWidget(tester);
              await tester.pumpAndSettle();

              expect(find.text('Test Account'), findsOneWidget);
              expect(find.textContaining('1.000,00'), findsOneWidget);

              await tester.pumpWidget(Container());
            }));

    // testWidgets(
    //     'should show archive dialog for cash account with references on long press',
    //     (tester) => tester.runAsync(() async {
    //           final accountId =
    //               await db.createAccount('Test Account', balance: 1000);
    //           await db.createBooking(
    //               accountId: accountId, amount: -50, category: 'Food');
    //
    //           final l10n = await pumpWidget(tester);
    //           await tester.pumpAndSettle();
    //
    //           await tester.longPress(find.text('Test Account'));
    //           await tester.pumpAndSettle();
    //
    //           expect(find.text(l10n.cannotDeleteAccount), findsOneWidget);
    //           expect(find.text(l10n.accountHasReferencesArchiveInstead),
    //               findsOneWidget);
    //
    //           await tester.tap(find.text(l10n.archive));
    //           await tester.pumpAndSettle();
    //
    //           await tester.pumpWidget(Container());
    //         }));
    //
    // testWidgets(
    //     'should show delete dialog for account without references on long press',
    //     (tester) => tester.runAsync(() async {
    //           await db.appDatabase.accountsDao
    //               .createAccount(account.toCompanion(true));
    //
    //           final l10n = await pumpWidget(tester);
    //           await tester.pumpAndSettle();
    //
    //           await tester.longPress(find.text('Test Account'));
    //           await tester.pumpAndSettle();
    //
    //           expect(find.text(l10n.deleteAccount), findsOneWidget);
    //           expect(find.text(l10n.confirmDeleteAccount), findsOneWidget);
    //
    //           await tester.tap(find.text(l10n.confirm));
    //           await tester.pumpAndSettle();
    //
    //           await tester.pumpWidget(Container());
    //         }));

    testWidgets(
        'should show unarchive dialog on archived account tap',
        (tester) => tester.runAsync(() async {
              await db.appDatabase.accountsDao
                  .createAccount(archivedAccount.toCompanion(true));

              final l10n = await pumpWidget(tester);
              await tester.pumpAndSettle();

              await tester.tap(find.byType(ExpansionTile));
              await tester.pumpAndSettle();

              expect(find.text('Archived Account'), findsOneWidget);

              await tester.tap(find.text('Archived Account'));
              await tester.pumpAndSettle();

              expect(find.text(l10n.unarchiveAccount), findsOneWidget);
              expect(find.text(l10n.confirmUnarchiveAccount), findsOneWidget);

              await tester.tap(find.text(l10n.confirm));
              await tester.pumpAndSettle();

              await tester.pumpWidget(Container());
            }));

    testWidgets(
        'should display message when no active accounts exist',
        (tester) => tester.runAsync(() async {
              final l10n = await pumpWidget(tester);
              await tester.pumpAndSettle();

              expect(find.text(l10n.noActiveAccounts), findsOneWidget);

              await tester.pumpWidget(Container());
            }));

    testWidgets(
        'should open account form when FAB is tapped',
        (tester) => tester.runAsync(() async {
              await pumpWidget(tester);
              await tester.pumpAndSettle();

              await tester.tap(find.byType(FloatingActionButton));
              await tester.pumpAndSettle();

              expect(find.byType(AccountForm), findsOneWidget);

              await tester.pumpWidget(Container());
            }));
  });
}
