import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:xfin/database/app_database.dart';
import 'package:xfin/database/tables.dart';
import 'package:xfin/l10n/app_localizations.dart';
import 'package:xfin/widgets/account_form.dart';

void main() {
  late AppDatabase database;
  late AppLocalizations l10n;

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    const locale = Locale('en');
    l10n = await AppLocalizations.delegate.load(locale);
  });

  tearDown(() async {
    await database.close();
  });

  Future<void> pumpWidget(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Provider<AppDatabase>(
          create: (_) => database,
          child: Builder(builder: (context) {
            return Scaffold(
              body: Center(
                child: ElevatedButton(
                  child: const Text('Show Form'),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => Provider<AppDatabase>.value(
                        value: database,
                        child: const AccountForm(),
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

    await tester.tap(find.text('Show Form'));
    await tester.pumpAndSettle();
  }

  group('AccountForm', () {
    testWidgets('Submitting a cash account saves correct data',
        (tester) => tester.runAsync(() async {
              await pumpWidget(tester);

              await tester.enterText(
                  find.byKey(const Key('account_name_field')), 'Cash Account');
              await tester.enterText(
                  find.byKey(const Key('initial_balance_field')), '150.50');
              await tester.tap(find.text(l10n.save));
              await tester.pumpAndSettle();

              final account = await (database.select(database.accounts)
                    ..where((a) => a.name.equals('Cash Account')))
                  .getSingle();
              expect(account.balance, 150.50);
              expect(account.initialBalance, 150.50);
              expect(account.type, AccountTypes.cash);
            }));

    testWidgets('Submitting a portfolio account saves correct data',
        (tester) => tester.runAsync(() async {
              await pumpWidget(tester);

              await tester.enterText(find.byKey(const Key('account_name_field')),
                  'Portfolio Account');
              await tester.tap(find.byKey(const Key('account_type_dropdown')));
              await tester.pumpAndSettle();
              await tester.tap(find.text(l10n.portfolio).last);
              await tester.pumpAndSettle();

              await tester.tap(find.text(l10n.save));
              await tester.pumpAndSettle();

              final account = await (database.select(database.accounts)
                    ..where((a) => a.name.equals('Portfolio Account')))
                  .getSingle();
              expect(account.balance, 0.0);
              expect(account.initialBalance, 0.0);
              expect(account.type, AccountTypes.portfolio);
            }));

    testWidgets('Balance field is hidden for portfolio accounts',
        (tester) => tester.runAsync(() async {
              await pumpWidget(tester);

              await tester.enterText(find.byKey(const Key('account_name_field')),
                  'Portfolio Account');
              await tester.tap(find.byKey(const Key('account_type_dropdown')));
              await tester.pumpAndSettle();
              await tester.tap(find.text(l10n.portfolio).last);
              await tester.pumpAndSettle();

              expect(find.byKey(const Key('initial_balance_field')), findsNothing);
            }));

    testWidgets('Cancel button pops the form',
        (tester) => tester.runAsync(() async {
              await pumpWidget(tester);

              expect(find.byType(AccountForm), findsOneWidget);

              await tester.tap(find.text(l10n.cancel));
              await tester.pumpAndSettle();

              expect(find.byType(AccountForm), findsNothing);
            }));

    group('Validation', () {
      testWidgets('Shows error for empty name',
          (tester) => tester.runAsync(() async {
                await pumpWidget(tester);

                await tester.tap(find.text(l10n.save));
                await tester.pump();

                expect(find.text(l10n.pleaseEnterAName), findsOneWidget);
              }));

      testWidgets('Shows error for duplicate name',
          (tester) => tester.runAsync(() async {
                await database.into(database.accounts).insert(
                    const AccountsCompanion(
                        name: Value('Existing Account'),
                        balance: Value(100),
                        initialBalance: Value(100),
                        type: Value(AccountTypes.cash)));

                await pumpWidget(tester);

                await tester.enterText(
                    find.byKey(const Key('account_name_field')),
                    'Existing Account');
                await tester.tap(find.text(l10n.save));
                await tester.pump();

                expect(find.text(l10n.accountAlreadyExists), findsOneWidget);
              }));

      testWidgets('Shows error for empty balance on cash account',
          (tester) => tester.runAsync(() async {
                await pumpWidget(tester);

                await tester.enterText(
                    find.byKey(const Key('account_name_field')), 'My Account');
                await tester.enterText(
                    find.byKey(const Key('initial_balance_field')), '');
                await tester.tap(find.text(l10n.save));
                await tester.pump();

                expect(find.text(l10n.pleaseEnterABalance), findsOneWidget);
              }));

      testWidgets('Shows error for invalid balance',
          (tester) => tester.runAsync(() async {
                await pumpWidget(tester);

                await tester.enterText(
                    find.byKey(const Key('account_name_field')), 'My Account');
                await tester.enterText(
                    find.byKey(const Key('initial_balance_field')), 'abc');
                await tester.tap(find.text(l10n.save));
                await tester.pump();

                expect(find.text(l10n.invalidNumber), findsOneWidget);
              }));

      testWidgets('Shows error for negative balance',
          (tester) => tester.runAsync(() async {
                await pumpWidget(tester);

                await tester.enterText(
                    find.byKey(const Key('account_name_field')), 'My Account');
                await tester.enterText(
                    find.byKey(const Key('initial_balance_field')), '-50');
                await tester.tap(find.text(l10n.save));
                await tester.pump();

                expect(
                    find.text(l10n.initialBalanceCannotBeNegative),
                    findsOneWidget);
              }));

      testWidgets('Shows error for too many decimal places',
          (tester) => tester.runAsync(() async {
                await pumpWidget(tester);

                await tester.enterText(
                    find.byKey(const Key('account_name_field')), 'My Account');
                await tester.enterText(
                    find.byKey(const Key('initial_balance_field')), '10.123');
                await tester.tap(find.text(l10n.save));
                await tester.pump();

                expect(
                    find.text(l10n.amountTooManyDecimalPlaces),
                    findsOneWidget);
              }));
    });
  });
}
