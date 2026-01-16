import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/gestures.dart';
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
import 'package:xfin/screens/accounts_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late BaseCurrencyProvider currencyProvider;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  // Example account objects used for inserts
  const cashAccount = Account(
    id: 1,
    name: 'Test Account',
    balance: 1000,
    initialBalance: 1000,
    type: AccountTypes.cash,
    isArchived: false,
  );

  const portfolioAccount = Account(
    id: 2,
    name: 'Portfolio Account',
    balance: 0,
    initialBalance: 0,
    type: AccountTypes.portfolio,
    isArchived: false,
  );

  const archivedAccount = Account(
    id: 3,
    name: 'Archived Account',
    balance: 500,
    initialBalance: 500,
    type: AccountTypes.cash,
    isArchived: true,
  );

  Future<AppLocalizations> pumpWidget(WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<DatabaseProvider>.value(value: DatabaseProvider.instance),
          ChangeNotifierProvider<BaseCurrencyProvider>.value(
              value: currencyProvider),
        ],
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [Locale('en'), Locale('de')],
          home: AccountsScreen(),
        ),
      ),
    );

    // Return the localization instance so tests can access localized strings
    return AppLocalizations.of(tester.element(find.byType(AccountsScreen)))!;
  }

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    DatabaseProvider.instance.initialize(db);
    currencyProvider = BaseCurrencyProvider();
    await currencyProvider.initialize(const Locale('en'));

    // Ensure base currency (id=1) exists, as other DB logic may expect it
    await db.into(db.assets).insert(AssetsCompanion.insert(
          name: 'EUR',
          type: AssetTypes.fiat,
          tickerSymbol: 'EUR',
        ));
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets(
      'shows loading indicator then empty message when no accounts',
      (tester) => tester.runAsync(() async {
            final l10n = await pumpWidget(tester);

            // Immediately after pumping, the StreamBuilder may still be waiting -> spinner present
            expect(find.byType(CircularProgressIndicator), findsOneWidget);

            await tester.pumpAndSettle();

            // After streams settle, no active accounts -> localized empty message
            expect(find.text(l10n.noActiveAccounts), findsOneWidget);
            expect(find.byType(ListView), findsNothing);

            // cleanup
            await tester.pumpWidget(Container());
          }));

  group('with active accounts', () {
    setUp(() async {
      // insert a single active cash account
      await db.into(db.accounts).insert(cashAccount.toCompanion(false));
    });

    testWidgets(
        'displays active account in list',
        (tester) => tester.runAsync(() async {
              await pumpWidget(tester);
              await tester.pumpAndSettle();

              expect(find.text('Test Account'), findsOneWidget);

              await tester.pumpWidget(Container());
            }));

    testWidgets(
        'long press on account without references shows delete dialog (cancel + confirm)',
        (tester) => tester.runAsync(() async {
              final l10n = await pumpWidget(tester);
              await tester.pumpAndSettle();

              // Ensure the tile exists
              expect(find.text('Test Account'), findsOneWidget);

              // Long press simulation (same technique used in other tests)
              final center = tester.getCenter(find.text('Test Account'));
              TestGesture gesture = await tester.startGesture(center);
              await tester.pump();
              // hold long press
              await Future.delayed(kLongPressTimeout);
              await gesture.up();
              await tester.pumpAndSettle();

              // Delete dialog should appear (no references => delete path)
              expect(find.text(l10n.deleteAccount), findsOneWidget);
              expect(find.text(l10n.deleteAccountConfirmation), findsOneWidget);

              // Cancel first -> account still present
              await tester.tap(find.text(l10n.cancel));
              await tester.pumpAndSettle();
              expect(find.text('Test Account'), findsOneWidget);

              // Trigger long press again and this time confirm deletion
              gesture = await tester.startGesture(center);
              await tester.pump();
              await Future.delayed(kLongPressTimeout);
              await gesture.up();
              await tester.pumpAndSettle();

              expect(find.text(l10n.deleteAccount), findsOneWidget);
              await tester.tap(find.text(l10n.delete));
              await tester.pumpAndSettle();
              await tester.pump();

              // Account should be removed from db
              final accounts = await db.accountsDao.getAllAccounts();
              expect(accounts.length, 0);

              // Account should be removed from UI list
              expect(find.text('Test Account'), findsNothing);

              await tester.pumpWidget(Container());
            }));
  });

  group('accounts with references (affects deletion/archive)', () {
    setUp(() async {
      // Insert both accounts: one cash (with balance >0) and one portfolio (balance 0)
      await db.into(db.accounts).insert(cashAccount.toCompanion(false));
      await db.into(db.accounts).insert(portfolioAccount.toCompanion(false));

      // Add a booking referencing cashAccount (this will make hasBookings true)
      await db.into(db.bookings).insert(BookingsCompanion.insert(
            date: 20230101,
            category: 'Food',
            shares: -50,
            value: -50,
            assetId: const Value(1),
            accountId: cashAccount.id,
          ));

      // Add a goal referencing portfolioAccount (this will make hasGoals true)
      await db.into(db.goals).insert(GoalsCompanion.insert(
            createdOn: 20250101,
            targetDate: 20260101,
            targetShares: 1000,
            targetValue: 1000,
            accountId: Value(portfolioAccount.id),
          ));
    });

    testWidgets(
        'long press on cash account with references shows cannot-delete-or-archive dialog (ok button)',
        (tester) => tester.runAsync(() async {
              final l10n = await pumpWidget(tester);
              await tester.pumpAndSettle();

              // long press the cash account (balance > 0 and has references)
              final center = tester.getCenter(find.text('Test Account'));
              TestGesture gesture = await tester.startGesture(center);
              await tester.pump();
              await Future.delayed(kLongPressTimeout);
              await gesture.up();
              await tester.pumpAndSettle();

              // It should show a dialog explaining we cannot delete/archive
              expect(
                  find.text(l10n.cannotDeleteOrArchiveAccount), findsOneWidget);
              expect(find.text(l10n.cannotDeleteOrArchiveAccountLong),
                  findsOneWidget);

              // Dismiss via OK
              await tester.tap(find.text(l10n.ok));
              await tester.pumpAndSettle();

              // The account still present
              expect(find.text('Test Account'), findsOneWidget);

              await tester.pumpWidget(Container());
            }));

    testWidgets(
        'long press on portfolio account with references and zero balance shows archive dialog (archive button archives it)',
        (tester) => tester.runAsync(() async {
              final l10n = await pumpWidget(tester);
              await tester.pumpAndSettle();

              // Ensure portfolio account is shown
              expect(find.text('Portfolio Account'), findsOneWidget);

              // Long press the portfolio account (has references; balance == 0)
              final center = tester.getCenter(find.text('Portfolio Account'));
              TestGesture gesture = await tester.startGesture(center);
              await tester.pump();
              await Future.delayed(kLongPressTimeout);
              await gesture.up();
              await tester.pumpAndSettle();

              // Archive dialog should be shown (cannot delete, offer to archive)
              expect(find.text(l10n.cannotDeleteAccount), findsOneWidget);
              expect(find.text(l10n.accountHasReferencesArchiveInstead),
                  findsOneWidget);

              // Cancel first -> still present
              await tester.tap(find.text(l10n.cancel));
              await tester.pumpAndSettle();
              expect(find.text('Portfolio Account'), findsOneWidget);

              // Trigger long press again and pick Archive
              final center2 = tester.getCenter(find.text('Portfolio Account'));
              gesture = await tester.startGesture(center2);
              await tester.pump();
              await Future.delayed(kLongPressTimeout);
              await gesture.up();
              await tester.pumpAndSettle();

              expect(find.text(l10n.cannotDeleteAccount), findsOneWidget);
              await tester.tap(find.text(l10n.archive));
              await tester.pumpAndSettle();

              // After archiving the account should no longer be in the active list
              expect(find.text('Portfolio Account'), findsNothing);

              await tester.pumpWidget(Container());
            }));
  });

  group('archived accounts behaviour', () {
    setUp(() async {
      // Insert an archived account
      await db.into(db.accounts).insert(archivedAccount.toCompanion(false));
    });

    testWidgets(
        'expansion tile reveals archived account which can be unarchived',
        (tester) => tester.runAsync(() async {
              final l10n = await pumpWidget(tester);
              await tester.pumpAndSettle();

              // At this point active list is empty; expansion tile should be present
              // Tap the ExpansionTile to expand archived accounts
              expect(find.byType(ExpansionTile), findsOneWidget);
              await tester.tap(find.byType(ExpansionTile));
              await tester.pumpAndSettle();

              // Archived account should be visible
              expect(find.text('Archived Account'), findsOneWidget);

              // Tap archived account to trigger unarchive dialog
              await tester.tap(find.text('Archived Account'));
              await tester.pumpAndSettle();

              expect(find.text(l10n.unarchiveAccount), findsOneWidget);
              expect(find.text(l10n.confirmUnarchiveAccount), findsOneWidget);

              // Confirm unarchive
              await tester.tap(find.text(l10n.confirm));
              await tester.pumpAndSettle();

              // After unarchiving it should appear in the active list
              expect(find.text('Archived Account'), findsOneWidget);

              await tester.pumpWidget(Container());
            }));
  });
}
