import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:xfin/database/app_database.dart';
import 'package:xfin/database/tables.dart';
import 'package:xfin/l10n/app_localizations.dart';
import 'package:xfin/screens/bookings_screen.dart';
import 'package:xfin/widgets/booking_form.dart';
import 'package:intl/date_symbol_data_local.dart';

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
        type: const Value(AccountTypes.cash)
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
      category: Value(reason),
      amount: Value(amount),
      accountId: Value(accountId),
      isGenerated: const Value(false),
    );
    await appDatabase.bookingsDao.createBookingAndUpdateAccount(companion);
    return await (appDatabase.select(appDatabase.bookings)
          ..where((tbl) => tbl.category.equals(reason)))
        .getSingle();
  }
}

void main() {
  late TestDatabase db;

  setUpAll(() async {
    await initializeDateFormatting('de_DE', null);
  });

  setUp(() {
    db = TestDatabase();
  });

  tearDown(() async {
    await db.close();
  });

  Future<AppLocalizations> pumpWidget(WidgetTester tester) async {
    await tester.pumpWidget(
      Provider<AppDatabase>.value(
        value: db.appDatabase,
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

  group('BookingsScreen Tests', () {
    testWidgets('shows loading indicator and then empty message',
        (tester) => tester.runAsync(() async {
              final l10n = await pumpWidget(tester);
              expect(find.byType(CircularProgressIndicator), findsOneWidget);

              await tester.pumpAndSettle();

              expect(find.text(l10n.noBookingsYet), findsOneWidget);
              expect(find.byType(ListView), findsNothing);

              await tester.pumpWidget(Container());
            }));

    testWidgets('displays bookings correctly',
        (tester) => tester.runAsync(() async {
              // Arrange
              final accountId =
                  await db.createAccount('Test Account');
              await db.createBooking(
                  accountId: accountId,
                  reason: 'Income',
                  amount: 1000,
                  date: DateTime(2023, 5, 1));
              await db.createBooking(
                  accountId: accountId,
                  reason: 'Expense',
                  amount: -50.55,
                  date: DateTime(2023, 5, 2));

              // Act
              final l10n = await pumpWidget(tester);
              await tester.pumpAndSettle(); // Wait for the stream

              // Assert
              expect(find.byType(ListView), findsOneWidget);
              expect(find.text(l10n.noBookingsYet), findsNothing);

              // Verify first item (Expense, because of ordering)
              expect(find.widgetWithText(ListTile, 'Expense'), findsOneWidget);
              expect(find.text('Test Account'), findsNWidgets(2)); // Subtitle for both
              final expenseAmountFinder =
                  find.text(NumberFormat.currency(locale: 'de_DE', symbol: '€').format(-50.55));
              expect(expenseAmountFinder, findsOneWidget);
              final expenseAmountWidget = tester.widget<Text>(expenseAmountFinder);
              expect(expenseAmountWidget.style!.color, Colors.red);

              await tester.pumpWidget(Container());
            }));

    testWidgets('tapping FAB opens BookingForm for new booking',
        (tester) => tester.runAsync(() async {
              await pumpWidget(tester);
              await tester.pumpAndSettle();

              await tester.tap(find.byIcon(Icons.add));
              await tester.pumpAndSettle();

              expect(find.byType(BookingForm), findsOneWidget);
              final form = tester.widget<BookingForm>(find.byType(BookingForm));
              expect(form.booking, isNull); // New booking form has null booking

              await tester.pumpWidget(Container());
            }));

    testWidgets('tapping a list item opens BookingForm for editing',
        (tester) => tester.runAsync(() async {
              final accountId = await db.createAccount('Test Account');
              final booking = await db.createBooking(
                  accountId: accountId, reason: 'Editable', amount: 123);
              await pumpWidget(tester);
              await tester.pumpAndSettle();

              await tester.tap(find.text('Editable'));
              await tester.pumpAndSettle();

              expect(find.byType(BookingForm), findsOneWidget);
              final form = tester.widget<BookingForm>(find.byType(BookingForm));
              expect(form.booking, isNotNull);
              expect(form.booking!.id, booking.id);
              expect(form.booking!.category, 'Editable');

              await tester.pumpWidget(Container());
            }));
            
    // testWidgets('long-pressing a list item opens DeleteBookingDialog',
    //     (tester) => tester.runAsync(() async {
    //           final accountId = await db.createAccount('Test Account');
    //           await db.createBooking(
    //               accountId: accountId, reason: 'Deletable', amount: 456);
    //           final l10n = await pumpWidget(tester);
    //           await tester.pumpAndSettle();
    //
    //           await tester.longPress(find.text('Deletable'));
    //           await tester.pumpAndSettle();
    //
    //           // Find the dialog by its title text
    //           expect(find.text(l10n.deleteBookingConfirmation), findsOneWidget);
    //           // Also verify some content
    //           expect(find.text('Deletable'), findsOneWidget);
    //
    //           await tester.pumpWidget(Container());
    //         }));
    //
    // testWidgets('deletes booking after confirming in dialog',
    //     (tester) => tester.runAsync(() async {
    //           // Arrange
    //           final accountId = await db.createAccount('Test Account');
    //           await db.createBooking(
    //               accountId: accountId, reason: 'Will be deleted', amount: 999);
    //           final l10n = await pumpWidget(tester);
    //           await tester.pumpAndSettle();
    //
    //           // Pre-condition check
    //           expect(find.text('Will be deleted'), findsOneWidget);
    //
    //           // Act
    //           await tester.longPress(find.widgetWithText(ListTile, 'Will be deleted'));
    //           await tester.pumpAndSettle();
    //
    //           // Dialog is shown, find by title
    //           final dialogTitleFinder = find.text(l10n.deleteBookingConfirmation);
    //           expect(dialogTitleFinder, findsOneWidget);
    //
    //           // Tap the delete button
    //           await tester.tap(find.widgetWithText(FilledButton, l10n.delete));
    //           await tester.pumpAndSettle();
    //
    //           // Assert dialog is gone
    //           expect(dialogTitleFinder, findsNothing);
    //           // Item is removed from the list
    //           expect(find.text('Will be deleted'), findsNothing);
    //
    //           await tester.pumpWidget(Container());
    //         }));
  });
}