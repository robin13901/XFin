import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xfin/database/app_database.dart';
import 'package:xfin/database/daos/accounts_dao.dart';
import 'package:xfin/database/tables.dart';
import 'package:xfin/l10n/app_localizations.dart';
import 'package:xfin/providers/base_currency_provider.dart';
import 'package:xfin/screens/bookings_screen.dart';
import 'package:xfin/widgets/booking_form.dart';
import 'package:xfin/widgets/delete_booking_dialog.dart';
import 'package:flutter/gestures.dart';

class MockAccountsDao extends Mock implements AccountsDao {}

void main() {
  late AppDatabase db;
  late BaseCurrencyProvider currencyProvider;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    const locale = Locale('en');
    currencyProvider = BaseCurrencyProvider();
    await currencyProvider.initialize(locale);
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
          home: BookingsScreen(),
        ),
      ),
    );
    return AppLocalizations.of(tester.element(find.byType(BookingsScreen)))!;
  }

  testWidgets(
      'shows loading indicator and then empty message',
      (tester) => tester.runAsync(() async {
            final l10n = await pumpWidget(tester);
            expect(find.byType(CircularProgressIndicator), findsOneWidget);

            await tester.pumpAndSettle();

            expect(find.text(l10n.noBookingsYet), findsOneWidget);
            expect(find.byType(ListView), findsNothing);

            await tester.pumpWidget(Container());
          }));

  // TODO: move to main_screen_test.dart
  // testWidgets(
  //     'tapping FAB opens BookingForm for new booking',
  //     (tester) => tester.runAsync(() async {
  //           await pumpWidget(tester);
  //           await tester.pumpAndSettle();
  //
  //           await tester.tap(find.byIcon(Icons.add));
  //           await tester.pumpAndSettle();
  //
  //           expect(find.byType(BookingForm), findsOneWidget);
  //           final form = tester.widget<BookingForm>(find.byType(BookingForm));
  //           expect(form.booking, isNull);
  //
  //           await tester.pumpWidget(Container());
  //         }));

  group('with initial bookings', () {
    late Account account;
    late Booking booking1, booking2;

    setUp(() async {
      account = const Account(
          id: 1,
          name: 'A',
          balance: 0,
          initialBalance: 0,
          type: AccountTypes.cash,
          isArchived: false);

      await db.into(db.accounts).insert(account.toCompanion(false));

      await db.into(db.assets).insert(AssetsCompanion.insert(
          name: 'EUR', type: AssetTypes.fiat, tickerSymbol: 'EUR'));
      await db.into(db.assetsOnAccounts).insert(
          AssetsOnAccountsCompanion.insert(accountId: account.id, assetId: 1));

      booking1 = Booking(
        id: 1,
        date: 20250101,
        shares: 1,
        costBasis: 1,
        assetId: 1,
        value: 1,
        category: 'Income',
        accountId: account.id,
        excludeFromAverage: false,
        isGenerated: false,
      );

      booking2 = Booking(
        id: 2,
        date: 20250101,
        shares: -1,
        costBasis: 1,
        assetId: 1,
        value: -1,
        category: 'Expense',
        accountId: account.id,
        excludeFromAverage: false,
        isGenerated: false,
      );

      await db.into(db.bookings).insert(booking1.toCompanion(false));
      await db.into(db.bookings).insert(booking2.toCompanion(false));
    });

    testWidgets(
        'displays bookings correctly',
        (tester) => tester.runAsync(() async {
              final l10n = await pumpWidget(tester);
              await tester.pumpAndSettle();

              expect(find.byType(ListView), findsOneWidget);
              expect(find.text(l10n.noBookingsYet), findsNothing);
              expect(find.text('A'), findsNWidgets(2));

              // Income Booking
              expect(find.widgetWithText(ListTile, 'Income'), findsOneWidget);
              final incomeAmountFinder = find.text(
                  NumberFormat.currency(locale: 'de_DE', symbol: '€')
                      .format(1));
              expect(incomeAmountFinder, findsOneWidget);
              final incomeAmountWidget =
                  tester.widget<Text>(incomeAmountFinder);
              expect(incomeAmountWidget.style!.color, Colors.green);

              // Expense Booking
              expect(find.widgetWithText(ListTile, 'Expense'), findsOneWidget);
              final expenseAmountFinder = find.text(
                  NumberFormat.currency(locale: 'de_DE', symbol: '€')
                      .format(-1));
              expect(expenseAmountFinder, findsOneWidget);
              final expenseAmountWidget =
                  tester.widget<Text>(expenseAmountFinder);
              expect(expenseAmountWidget.style!.color, Colors.red);

              await tester.pumpWidget(Container());
            }));

    testWidgets(
        'tapping a list item opens BookingForm for editing',
        (tester) => tester.runAsync(() async {
              await pumpWidget(tester);
              await tester.pumpAndSettle();

              await tester.tap(find.text('Income'));
              await tester.pumpAndSettle();

              expect(find.byType(BookingForm), findsOneWidget);
              final form = tester.widget<BookingForm>(find.byType(BookingForm));
              expect(form.booking, isNotNull);
              expect(form.booking!.id, booking1.id);
              expect(form.booking!.category, 'Income');

              await tester.pumpWidget(Container());
            }));

    testWidgets(
        'long-pressing a list item opens DeleteBookingDialog',
        (tester) => tester.runAsync(() async {
              final l10n = await pumpWidget(tester);
              await tester.pumpAndSettle();

              // Manually simulate a long press gesture
              final offset = tester.getCenter(find.text('Income'));
              final gesture = await tester.startGesture(offset);
              await tester.pump();
              await Future.delayed(kLongPressTimeout);
              await gesture.up();
              await tester.pumpAndSettle();

              expect(find.byType(DeleteBookingDialog), findsOneWidget);
              expect(find.text(l10n.deleteBookingConfirmation), findsOneWidget);
              expect(find.text('Income'), findsWidgets);

              await tester.pumpWidget(Container());
            }));

    // testWidgets(
    //     'deletes booking after confirming in dialog',
    //         (tester) => tester.runAsync(() async {
    //           final l10n = await pumpWidget(tester);
    //           await tester.pumpAndSettle();
    //
    //           expect(find.text('Expense'), findsOneWidget);
    //
    //           // Manually simulate a long press gesture
    //           final offset = tester.getCenter(find.text('Expense'));
    //           final gesture = await tester.startGesture(offset);
    //           await tester.pump();
    //           await Future.delayed(kLongPressTimeout);
    //           await gesture.up();
    //           await tester.pumpAndSettle();
    //
    //           final dialogTitleFinder =
    //               find.text(l10n.deleteBookingConfirmation);
    //           expect(dialogTitleFinder, findsOneWidget);
    //
    //           await tester.tap(find.widgetWithText(FilledButton, l10n.delete));
    //           await tester.pump();          // schedules microtasks
    //           await tester.pumpAndSettle(); // waits for async & animations
    //
    //           expect(dialogTitleFinder, findsNothing);
    //           expect(find.text('Expense'), findsNothing);
    //
    //           await tester.pumpWidget(Container());
    //         }));
  });
}
