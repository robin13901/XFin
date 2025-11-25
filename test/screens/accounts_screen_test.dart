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
import 'package:xfin/screens/accounts_screen.dart';
import 'package:xfin/widgets/account_form.dart';
import 'package:flutter/gestures.dart';

void main() {
  late AppDatabase db;
  late BaseCurrencyProvider currencyProvider;
  late Account cashAccount, portfolioAccount, archivedAccount;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    const locale = Locale('en');
    currencyProvider = BaseCurrencyProvider();
    await currencyProvider.initialize(locale);

    await db.into(db.assets).insert(AssetsCompanion.insert(
        name: 'EUR', type: AssetTypes.currency, tickerSymbol: 'EUR'));

    cashAccount = const Account(
      id: 1,
      name: 'Test Account',
      balance: 1000,
      initialBalance: 1000,
      type: AccountTypes.cash,
      isArchived: false,
    );

    portfolioAccount = const Account(
      id: 2,
      name: 'Portfolio Account',
      balance: 0,
      initialBalance: 0,
      type: AccountTypes.portfolio,
      isArchived: false,
    );

    archivedAccount = const Account(
      id: 2,
      name: 'Archived Account',
      balance: 500,
      initialBalance: 500,
      type: AccountTypes.cash,
      isArchived: true,
    );
  });

  tearDown(() async {
    await db.close();
  });

  Future<AppLocalizations> pumpWidget(WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<AppDatabase>.value(
            value: db,
          ),
          ChangeNotifierProvider<BaseCurrencyProvider>.value(
            value: currencyProvider,
          ),
        ],
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: AccountsScreen(),
        ),
      ),
    );
    return AppLocalizations.of(tester.element(find.byType(AccountsScreen)))!;
  }

  group('AccountsScreen', () {
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

    group('with active accounts', () {
      setUp(() async {
        await db.into(db.accounts).insert(cashAccount.toCompanion(true));
      });

      testWidgets(
          'should display active accounts',
          (tester) => tester.runAsync(() async {
                await pumpWidget(tester);
                await tester.pumpAndSettle();

                expect(find.text('Test Account'), findsOneWidget);

                await tester.pumpWidget(Container());
              }));

      testWidgets(
          'test delete dialog for account without references on long press',
          (tester) => tester.runAsync(() async {
                final l10n = await pumpWidget(tester);
                await tester.pumpAndSettle();

                // Cancel deletion
                Offset offset = tester.getCenter(find.text('Test Account'));
                TestGesture gesture = await tester.startGesture(offset);
                await tester.pump();
                await Future.delayed(kLongPressTimeout);
                await gesture.up();
                await tester.pumpAndSettle();

                expect(find.text(l10n.deleteAccount), findsOneWidget);
                expect(find.text(l10n.confirmDeleteAccount), findsOneWidget);

                await tester.tap(find.text(l10n.cancel));
                await tester.pumpAndSettle();

                expect(find.text('Test Account'), findsOneWidget);

                // Confirm deletion
                offset = tester.getCenter(find.text('Test Account'));
                gesture = await tester.startGesture(offset);
                await tester.pump();
                await Future.delayed(kLongPressTimeout);
                await gesture.up();
                await tester.pumpAndSettle();

                expect(find.text(l10n.deleteAccount), findsOneWidget);
                expect(find.text(l10n.confirmDeleteAccount), findsOneWidget);

                await tester.tap(find.text(l10n.confirm));
                await tester.pumpAndSettle();

                expect(find.text('Test Account'), findsNothing);

                await tester.pumpWidget(Container());
              }));
    });

    group('with accounts with references', () {
      setUp(() async {
        await db.into(db.accounts).insert(cashAccount.toCompanion(true));
        await db.into(db.accounts).insert(portfolioAccount.toCompanion(true));
        await db.into(db.bookings).insert(BookingsCompanion.insert(
            date: 20230101,
            category: 'Food',
            amount: -50,
            accountId: cashAccount.id));
        await db.into(db.goals).insert(GoalsCompanion.insert(
            createdOn: 20250101,
            targetDate: 20260101,
            targetAmount: 1000,
            accountId: const Value(2)));
      });

      testWidgets(
          'should show archive dialog for cash account with references on long press',
          (tester) => tester.runAsync(() async {
                final l10n = await pumpWidget(tester);
                await tester.pumpAndSettle();

                // Cancel archiving
                Offset offset = tester.getCenter(find.text('Test Account'));
                TestGesture gesture = await tester.startGesture(offset);
                await tester.pump();
                await Future.delayed(kLongPressTimeout);
                await gesture.up();
                await tester.pumpAndSettle();

                expect(find.text(l10n.cannotDeleteAccount), findsOneWidget);
                expect(find.text(l10n.accountHasReferencesArchiveInstead),
                    findsOneWidget);

                await tester.tap(find.text(l10n.cancel));
                await tester.pumpAndSettle();

                expect(find.text('Test Account'), findsOneWidget);

                // Confirm archiving
                offset = tester.getCenter(find.text('Test Account'));
                gesture = await tester.startGesture(offset);
                await tester.pump();
                await Future.delayed(kLongPressTimeout);
                await gesture.up();
                await tester.pumpAndSettle();

                expect(find.text(l10n.cannotDeleteAccount), findsOneWidget);
                expect(find.text(l10n.accountHasReferencesArchiveInstead),
                    findsOneWidget);

                await tester.tap(find.text(l10n.archive));
                await tester.pumpAndSettle();

                expect(find.text('Test Account'), findsNothing);

                await tester.pumpWidget(Container());
              }));

      testWidgets(
          'should show archive dialog for portfolio account with references on long press',
          (tester) => tester.runAsync(() async {
                final l10n = await pumpWidget(tester);
                await tester.pumpAndSettle();

                // Cancel archiving
                Offset offset =
                    tester.getCenter(find.text('Portfolio Account'));
                TestGesture gesture = await tester.startGesture(offset);
                await tester.pump();
                await Future.delayed(kLongPressTimeout);
                await gesture.up();
                await tester.pumpAndSettle();

                expect(find.text(l10n.cannotDeleteAccount), findsOneWidget);
                expect(find.text(l10n.accountHasReferencesArchiveInstead),
                    findsOneWidget);

                await tester.tap(find.text(l10n.cancel));
                await tester.pumpAndSettle();

                expect(find.text('Portfolio Account'), findsOneWidget);

                offset = tester.getCenter(find.text('Portfolio Account'));
                gesture = await tester.startGesture(offset);
                await tester.pump();
                await Future.delayed(kLongPressTimeout);
                await gesture.up();
                await tester.pumpAndSettle();

                expect(find.text(l10n.cannotDeleteAccount), findsOneWidget);
                expect(find.text(l10n.accountHasReferencesArchiveInstead),
                    findsOneWidget);

                await tester.tap(find.text(l10n.archive));
                await tester.pumpAndSettle();

                expect(find.text('Portfolio Account'), findsNothing);

                await tester.pumpWidget(Container());
              }));
    });

    group('with archived accounts', () {
      setUp(() async {
        await db.into(db.accounts).insert(archivedAccount.toCompanion(true));
      });

      testWidgets(
          'should show unarchive dialog on archived account tap',
          (tester) => tester.runAsync(() async {
                final l10n = await pumpWidget(tester);
                await tester.pumpAndSettle();

                // Tap on the ExpansionTile to reveal archived accounts
                await tester.tap(find.byType(ExpansionTile));
                await tester.pumpAndSettle();

                expect(find.text('Archived Account'), findsOneWidget);

                await tester.tap(find.text('Archived Account'));
                await tester.pumpAndSettle();

                expect(find.text(l10n.unarchiveAccount), findsOneWidget);
                expect(find.text(l10n.confirmUnarchiveAccount), findsOneWidget);

                await tester.tap(find.text(l10n.confirm));
                await tester.pumpAndSettle();

                // After unarchiving, it should appear in the active accounts list
                expect(find.text('Archived Account'), findsOneWidget);

                await tester.pumpWidget(Container());
              }));
    });
  });
}
