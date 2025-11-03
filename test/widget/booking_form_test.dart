import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oktoast/oktoast.dart';
import 'package:provider/provider.dart';
import 'package:xfin/database/app_database.dart';
import 'package:xfin/database/tables.dart';
import 'package:xfin/l10n/app_localizations.dart';
import 'package:xfin/widgets/booking_form.dart';

// A test database that uses an in-memory sqlite database.
class TestDatabase {
  late final AppDatabase appDatabase;

  TestDatabase() {
    appDatabase = AppDatabase(NativeDatabase.memory());
  }

  Future<void> close() {
    return appDatabase.close();
  }

  Future<int> createAccount(String name, {double balance = 100.0}) async {
    return await appDatabase.accountsDao.addAccount(
      AccountsCompanion(
        name: Value(name),
        balance: Value(balance),
        initialBalance: Value(balance),
        type: const Value(AccountTypes.cash),
      ),
    );
  }

  Future<Booking> createBooking({
    required int accountId,
    required double amount,
    required String reason,
    DateTime? date,
  }) async {
    final dateAsInt = date != null
        ? int.parse(date.toIso8601String().substring(0, 10).replaceAll('-', ''))
        : 20230101;
    final companion = BookingsCompanion(
        date: Value(dateAsInt),
        reason: Value(reason),
        amount: Value(amount),
        accountId: Value(accountId),
        isGenerated: const Value(false));
    await appDatabase.bookingsDao.createBookingAndUpdateAccount(companion);
    return await (appDatabase.select(appDatabase.bookings)
          ..where((tbl) => tbl.reason.equals(reason)))
        .getSingle();
  }
}

Future<AppLocalizations> setupL10n() {
  // You might need to adjust this depending on how your l10n is generated/loaded.
  // This is a common way to load it in tests.
  return AppLocalizations.delegate.load(const Locale('en'));
}

void main() {
  late TestDatabase db;
  late AppLocalizations l10n;

  setUp(() async {
    db = TestDatabase();
    // Get the l10n instance
    l10n = await setupL10n();
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> pumpWidget(WidgetTester tester, {Booking? booking}) async {
    await tester.pumpWidget(
      Provider<AppDatabase>.value(
        value: db.appDatabase,
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: BookingForm(booking: booking),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle(); // Let the stream builders load
  }

  Future<void> pumpWidgetWithToast(WidgetTester tester, {Booking? booking}) async {
    await tester.pumpWidget(
      Provider<AppDatabase>.value(
        value: db.appDatabase,
        child: OKToast(
          child: MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: BookingForm(booking: booking),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('BookingForm Tests', () {
    late int accountId1;

    setUp(() async {
      accountId1 = await db.appDatabase.accountsDao.addAccount(
        const AccountsCompanion(
          name: Value('Test Account'),
          balance: Value(100.0),
          initialBalance: Value(100.0),
          type: Value(AccountTypes.cash),
        ),
      );
    });

    testWidgets('form initializes empty for new booking',
        (tester) => tester.runAsync(() async {
              await pumpWidget(tester);

              expect(find.byType(BookingForm), findsOneWidget);
              expect(find.text(l10n.save), findsOneWidget);
              expect(
                  tester
                      .widget<TextFormField>(find.descendant(of: find.byKey(const Key('reason_field')), matching: find.byType(TextFormField)))
                      .controller!
                      .text,
                  '');
              expect(
                  tester
                      .widget<TextFormField>(find.byKey(const Key('amount_field')))
                      .controller!
                      .text,
                  '');
              expect(
                  tester
                      .widget<CheckboxListTile>(
                          find.byKey(const Key('exclude_checkbox')))
                      .value,
                  isFalse);

              // Dispose the widget to ensure streams are cancelled.
              await tester.pumpWidget(Container());
            }));

    testWidgets('form initializes with data for existing booking',
        (tester) => tester.runAsync(() async {
              final booking = Booking(
                id: 1,
                date: 20230501,
                reason: 'Existing Booking',
                amount: -50.0,
                accountId: accountId1,
                excludeFromAverage: true,
                isGenerated: false,
                notes: 'Some notes',
              );
              await pumpWidget(tester, booking: booking);

              expect(find.text('01.05.2023'), findsOneWidget);
              expect(find.text('-50.0'), findsOneWidget);
              expect(find.text('Existing Booking'), findsOneWidget);
              expect(find.text('Some notes'), findsOneWidget);
              expect(
                  tester
                      .widget<CheckboxListTile>(
                          find.byKey(const Key('exclude_checkbox')))
                      .value,
                  isTrue);
              expect(
                  tester
                      .widget<DropdownButtonFormField<int>>(
                          find.byKey(const Key('account_dropdown')))
                      .initialValue,
                  accountId1);

              // Dispose the widget to ensure streams are cancelled.
              await tester.pumpWidget(Container());
            }));

    testWidgets('reason field shows autocomplete suggestions',
        (tester) => tester.runAsync(() async {
              await db.createBooking(
                  accountId: accountId1, amount: 10, reason: 'Food');
              await db.createBooking(
                  accountId: accountId1, amount: 20, reason: 'Transport');
              await db.createBooking(
                  accountId: accountId1, amount: 30, reason: 'Food expenses');

              await pumpWidget(tester);

              final reasonField = find.byKey(const Key('reason_field'));
              await tester.enterText(reasonField, 'F');
              await tester.pumpAndSettle();

              expect(find.text('Food'), findsOneWidget);
              expect(find.text('Food expenses'), findsOneWidget);
              expect(find.text('Transport'), findsNothing); 

              await tester.tap(find.text('Food'));
              await tester.pumpAndSettle();

              expect(
                  tester
                      .widget<TextFormField>(find.descendant(of: reasonField, matching: find.byType(TextFormField)))
                      .controller!
                      .text,
                  'Food');

              // Dispose the widget to ensure streams are cancelled.
              await tester.pumpWidget(Container());
            }));

    group('Validation', () {
      testWidgets('shows error if date is in the future',
          (tester) => tester.runAsync(() async {
                await pumpWidget(tester);

                await tester.tap(find.byIcon(Icons.calendar_today));
                await tester.pumpAndSettle();
                await tester.tap(find.text('OK')); // Select today
                await tester.pumpAndSettle();

                final dateField = tester
                    .widget<FormField<String>>(find.byKey(const Key('date_field')));
                expect(dateField.validator, isNotNull);

                // Dispose the widget to ensure streams are cancelled.
                await tester.pumpWidget(Container());
              }));

      testWidgets('shows errors for invalid amount',
          (tester) => tester.runAsync(() async {
                await pumpWidget(tester);

                await tester.tap(find.text(l10n.save));
                await tester.pumpAndSettle();
                expect(find.text(l10n.pleaseEnterAnAmount), findsOneWidget);

                await tester.enterText(
                    find.byKey(const Key('amount_field')), 'invalid');
                await tester.tap(find.text(l10n.save));
                await tester.pumpAndSettle();
                expect(find.text(l10n.invalidInput), findsOneWidget);

                await tester.enterText(
                    find.byKey(const Key('amount_field')), '1.234');
                await tester.tap(find.text(l10n.save));
                await tester.pumpAndSettle();
                expect(find.text(l10n.tooManyDecimalPlaces), findsOneWidget);

                // Dispose the widget to ensure streams are cancelled.
                await tester.pumpWidget(Container());
              }));

      testWidgets('shows errors for invalid reason',
          (tester) => tester.runAsync(() async {
                await pumpWidget(tester);

                await tester.tap(find.text(l10n.save));
                await tester.pumpAndSettle();
                expect(find.text(l10n.pleaseEnterAReason), findsOneWidget);

                await tester.enterText(
                    find.byKey(const Key('reason_field')), 'Überweisung');
                await tester.tap(find.text(l10n.save));
                await tester.pumpAndSettle();
                expect(find.text(l10n.reasonReservedForTransfer), findsOneWidget);

                // Dispose the widget to ensure streams are cancelled.
                await tester.pumpWidget(Container());
              }));

      testWidgets('shows error if account is not selected',
          (tester) => tester.runAsync(() async {
                await pumpWidget(tester);

                await tester.tap(find.text(l10n.save));
                await tester.pumpAndSettle();
                expect(find.text(l10n.pleaseSelectAnAccount), findsOneWidget);

                // Dispose the widget to ensure streams are cancelled.
                await tester.pumpWidget(Container());
              }));
    });

    group('Form Submission', () {
      testWidgets('Create new booking successfully',
          (tester) => tester.runAsync(() async {
                await pumpWidget(tester);

                await tester.enterText(
                    find.byKey(const Key('amount_field')), '-50.50');
                await tester.enterText(
                    find.byKey(const Key('reason_field')), 'Groceries');
                await tester.tap(find.byKey(const Key('account_dropdown')));
                await tester.pumpAndSettle();
                await tester.tap(find.text('Test Account').last);
                await tester.pumpAndSettle();
                await tester.tap(find.byKey(const Key('exclude_checkbox')));
                await tester.pumpAndSettle();

                await tester.tap(find.text(l10n.save));
                await tester.pumpAndSettle();

                final bookings =
                    await (db.appDatabase.select(db.appDatabase.bookings)).get();
                expect(bookings.length, 1);

                // Dispose the widget to ensure streams are cancelled.
                await tester.pumpWidget(Container());
              }));

      testWidgets('shows toast for insufficient balance',
          (tester) => tester.runAsync(() async {
                await pumpWidgetWithToast(tester);

                await tester.enterText(find.byKey(const Key('amount_field')), '-150');
                await tester.enterText(
                    find.byKey(const Key('reason_field')), 'Too Expensive');
                await tester.tap(find.byKey(const Key('account_dropdown')));
                await tester.pumpAndSettle();
                await tester.tap(find.text('Test Account').last);
                await tester.pumpAndSettle();

                await tester.tap(find.text(l10n.save));
                await tester.pumpAndSettle(); // Let toast appear

                expect(find.text(l10n.insufficientBalance), findsOneWidget);

                await tester.pumpAndSettle(
                    const Duration(seconds: 3)); // let toast disappear

                // Dispose the widget to ensure streams are cancelled.
                await tester.pumpWidget(Container());
              }));

      testWidgets('Update existing booking successfully',
          (tester) => tester.runAsync(() async {
                final booking = await db.createBooking(
                    accountId: accountId1, amount: 50, reason: 'Initial');

                await pumpWidget(tester, booking: booking);

                await tester.enterText(find.byKey(const Key('amount_field')), '-25');
                await tester.enterText(
                    find.byKey(const Key('reason_field')), 'Updated');

                await tester.tap(find.text(l10n.save));
                await tester.pumpAndSettle();

                final updatedBooking =
                    await db.appDatabase.bookingsDao.getBooking(booking.id);
                expect(updatedBooking.amount, -25);

                // Dispose the widget to ensure streams are cancelled.
                await tester.pumpWidget(Container());
              }));

      testWidgets('Merge dialog appears and merge is successful',
          (tester) => tester.runAsync(() async {
                await db.createBooking(
                    accountId: accountId1,
                    amount: -30,
                    reason: 'Groceries',
                    date: DateTime.now());

                await pumpWidget(tester);

                await tester.enterText(find.byKey(const Key('amount_field')), '-20');
                await tester.enterText(
                    find.byKey(const Key('reason_field')), 'Groceries');
                await tester.tap(find.byKey(const Key('account_dropdown')));
                await tester.pumpAndSettle();
                await tester.tap(find.text('Test Account').last);
                await tester.pumpAndSettle();

                await tester.tap(find.text(l10n.save));
                await tester.pumpAndSettle();

                expect(find.text(l10n.mergeBookings), findsOneWidget);

                await tester.tap(find.text(l10n.merge));
                await tester.pumpAndSettle();

                final bookings =
                    await (db.appDatabase.select(db.appDatabase.bookings)).get();
                expect(bookings.length, 1);

                // Dispose the widget to ensure streams are cancelled.
                await tester.pumpWidget(Container());
              }));
    });
  });
}
