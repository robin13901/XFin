import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:xfin/database/app_database.dart';
import 'package:xfin/widgets/booking_form.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  Future<Account> getAccount(int id) {
    return (database.select(database.accounts)..where((a) => a.id.equals(id))).getSingle();
  }

  Future<void> pumpWidget(WidgetTester tester, {Booking? booking}) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Provider<AppDatabase>(
          create: (_) => database,
          child: Scaffold(body: BookingForm(booking: booking)),
        ),
      ),
    );
  }

  testWidgets('form submits with correct data', (tester) => tester.runAsync(() async {
    await database.accountsDao.addAccount(const AccountsCompanion(name: Value('Test'), balance: Value(100), initialBalance: Value(100), type: Value('Cash'), creationDate: Value(20230101)));
    await pumpWidget(tester);

    // Change date to something other than today
    await tester.tap(find.byIcon(Icons.calendar_today));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(1), '10');
    await tester.enterText(find.byType(TextFormField).at(2), 'Test Reason');
    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Test').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Speichern'));
    await tester.pumpAndSettle();

    final booking = await database.bookingsDao.getBooking(1);
    final expectedDate = int.parse(DateFormat('yyyyMMdd').format(DateTime.now()));

    expect(booking.date, expectedDate);
    await tester.pumpWidget(const SizedBox.shrink());
  }));

  group('BookingForm validation', () {
    testWidgets('shows error when amount is empty', (tester) => tester.runAsync(() async {
      await pumpWidget(tester);

      await tester.tap(find.text('Speichern'));
      await tester.pumpAndSettle();

      expect(find.text('Bitte gib einen Betrag an!'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    }));

    testWidgets('shows error when amount is invalid', (tester) => tester.runAsync(() async {
      await pumpWidget(tester);

      await tester.enterText(find.byType(TextFormField).at(1), 'invalid');
      await tester.tap(find.text('Speichern'));
      await tester.pumpAndSettle();

      expect(find.text('Ungültige Eingabe!'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    }));

    testWidgets('shows error for negative amount on transfer', (tester) => tester.runAsync(() async {
      await pumpWidget(tester);

      await tester.tap(find.text('Überweisung'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(1), '-10');
      await tester.tap(find.text('Speichern'));
      await tester.pumpAndSettle();

      expect(find.text('Überweisungen müssen positiv sein!'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    }));

    testWidgets('shows error for too many decimal places in amount', (tester) => tester.runAsync(() async {
      await pumpWidget(tester);

      await tester.enterText(find.byType(TextFormField).at(1), '10.123');
      await tester.tap(find.text('Speichern'));
      await tester.pumpAndSettle();

      expect(find.text('Zu viele Nachkommastellen!'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    }));

    testWidgets('shows error when reason is empty for non-transfer', (tester) => tester.runAsync(() async {
      await pumpWidget(tester);

      await tester.enterText(find.byType(TextFormField).at(1), '10');
      await tester.tap(find.text('Speichern'));
      await tester.pumpAndSettle();

      expect(find.text('Bitte gib einen Grund an!'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    }));

    testWidgets('shows error when reason is disallowed', (tester) => tester.runAsync(() async {
      await pumpWidget(tester);

      await tester.enterText(find.byType(TextFormField).at(1), '10');
      await tester.enterText(find.byType(TextFormField).at(2), 'Überweisung');
      await tester.tap(find.text('Speichern'));
      await tester.pumpAndSettle();

      expect(find.text('Dieser Grund ist für Überweisungen reserviert.'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    }));

    testWidgets('shows error when no account is selected', (tester) => tester.runAsync(() async {
      await pumpWidget(tester);
      await tester.enterText(find.byType(TextFormField).at(1), '10');
      await tester.enterText(find.byType(TextFormField).at(2), 'Test');
      await tester.tap(find.text('Speichern'));
      await tester.pumpAndSettle();

      expect(find.text('Bitte wähle ein Konto!'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    }));

    testWidgets('shows error when sender account is not selected for transfer', (tester) => tester.runAsync(() async {
      await pumpWidget(tester);
      await tester.tap(find.text('Überweisung'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(1), '10');
      await tester.tap(find.text('Speichern'));
      await tester.pumpAndSettle();

      expect(find.text('Bitte wähle ein Senderkonto'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    }));

    testWidgets('shows error when receiver account is not selected for transfer', (tester) => tester.runAsync(() async {
      await database.accountsDao.addAccount(const AccountsCompanion(name: Value('Test1'), balance: Value(100), initialBalance: Value(100), type: Value('Cash'), creationDate: Value(20230101)));
      await pumpWidget(tester);
      await tester.tap(find.text('Überweisung'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(1), '10');

      await tester.tap(find.byType(DropdownButtonFormField<int>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Test1').last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Speichern'));
      await tester.pumpAndSettle();

      expect(find.text('Bitte wähle ein Empfängerkonto!'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    }));

    testWidgets('shows error when sender and receiver accounts are the same', (tester) => tester.runAsync(() async {
      await database.accountsDao.addAccount(const AccountsCompanion(name: Value('Test1'), balance: Value(100), initialBalance: Value(100), type: Value('Cash'), creationDate: Value(20230101)));
      await pumpWidget(tester);

      await tester.tap(find.text('Überweisung'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(1), '10');

      // Select same account for both
      for (var i = 0; i < 2; i++) {
        await tester.tap(find.byType(DropdownButtonFormField<int>).at(i));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Test1').last);
        await tester.pumpAndSettle();
      }

      await tester.tap(find.text('Speichern'));
      await tester.pumpAndSettle();

      expect(find.text('Konten müssen verschieden sein!'), findsNWidgets(2));
      await tester.pumpWidget(const SizedBox.shrink());
    }));
  });

  group('Booking merge functionality', () {
    testWidgets('shows merge dialog and merges non-transfer booking on confirm', (tester) => tester.runAsync(() async {
      // ARRANGE
      final accountId = await database.accountsDao.addAccount(const AccountsCompanion(name: Value('Test'), balance: Value(100), initialBalance: Value(100), type: Value('Cash'), creationDate: Value(20230101)));
      final dateAsInt = int.parse(DateFormat('yyyyMMdd').format(DateTime.now()));
      await database.bookingsDao.createBooking(BookingsCompanion(
        date: Value(dateAsInt),
        reason: const Value('Drinks'),
        amount: const Value(-8.0),
        receivingAccountId: Value(accountId),
      ));
      await pumpWidget(tester);

      // ACT
      // Fill form to match the existing booking
      await tester.enterText(find.byType(TextFormField).at(1), '-7.0');
      await tester.enterText(find.byType(TextFormField).at(2), 'Drinks');
      await tester.tap(find.byType(DropdownButtonFormField<int>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Test').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Speichern'));
      await tester.pumpAndSettle();

      // Confirm dialog
      expect(find.text('Buchungen zusammenführen?'), findsOneWidget);
      await tester.tap(find.text('Zusammenführen'));
      await tester.pumpAndSettle();

      // ASSERT
      final bookings = await database.select(database.bookings).get();
      expect(bookings.length, 1);
      expect(bookings.first.amount, -15.0); // -8.0 + -7.0
      final account = await getAccount(accountId);
      expect(account.balance, 85.0); // 100 - 15
      await tester.pumpWidget(const SizedBox.shrink());
    }));

    testWidgets('shows merge dialog and creates new booking on decline', (tester) => tester.runAsync(() async {
      // ARRANGE
      final accountId = await database.accountsDao.addAccount(const AccountsCompanion(name: Value('Test'), balance: Value(100), initialBalance: Value(100), type: Value('Cash'), creationDate: Value(20230101)));
      final dateAsInt = int.parse(DateFormat('yyyyMMdd').format(DateTime.now()));
      await database.bookingsDao.createBooking(BookingsCompanion(
        date: Value(dateAsInt),
        reason: const Value('Drinks'),
        amount: const Value(-8.0),
        receivingAccountId: Value(accountId),
      ));
      await pumpWidget(tester);

      // ACT
      await tester.enterText(find.byType(TextFormField).at(1), '-7.0');
      await tester.enterText(find.byType(TextFormField).at(2), 'Drinks');
      await tester.tap(find.byType(DropdownButtonFormField<int>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Test').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Speichern'));
      await tester.pumpAndSettle();

      // Decline dialog
      expect(find.text('Buchungen zusammenführen?'), findsOneWidget);
      await tester.tap(find.text('Neu erstellen'));
      await tester.pumpAndSettle();

      // ASSERT
      final bookings = await database.select(database.bookings).get();
      expect(bookings.length, 2);
      final account = await getAccount(accountId);
      expect(account.balance, 85.0); // 100 - 8 - 7
      await tester.pumpWidget(const SizedBox.shrink());
    }));

    testWidgets('merges swapped-account transfer correctly', (tester) => tester.runAsync(() async {
      // ARRANGE
      final fromId = await database.accountsDao.addAccount(const AccountsCompanion(name: Value('From'), balance: Value(100), initialBalance: Value(100), type: Value('Cash'), creationDate: Value(20230101)));
      final toId = await database.accountsDao.addAccount(const AccountsCompanion(name: Value('To'), balance: Value(100), initialBalance: Value(100), type: Value('Cash'), creationDate: Value(20230101)));
      final dateAsInt = int.parse(DateFormat('yyyyMMdd').format(DateTime.now()));
      // From -> To: 10
      await database.bookingsDao.createBooking(BookingsCompanion(
        date: Value(dateAsInt),
        amount: const Value(10.0),
        sendingAccountId: Value(fromId),
        receivingAccountId: Value(toId),
      ));
      await pumpWidget(tester);

      // ACT
      // Create new transfer To -> From: 3
      await tester.tap(find.text('Überweisung'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(1), '3');
      // 'Von Konto'
      await tester.tap(find.byType(DropdownButtonFormField<int>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('To').last);
      await tester.pumpAndSettle();
      // 'Auf Konto'
      await tester.tap(find.byType(DropdownButtonFormField<int>).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('From').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Speichern'));
      await tester.pumpAndSettle();

      // Confirm merge
      expect(find.text('Buchungen zusammenführen?'), findsOneWidget);
      await tester.tap(find.text('Zusammenführen'));
      await tester.pumpAndSettle();

      // ASSERT
      final bookings = await database.select(database.bookings).get();
      expect(bookings.length, 1);
      final booking = bookings.first;
      expect(booking.amount, 7.0); // 10 - 3
      expect(booking.sendingAccountId, fromId);
      expect(booking.receivingAccountId, toId);
      await tester.pumpWidget(const SizedBox.shrink());
    }));

    testWidgets('cancels out and deletes swapped-account transfer', (tester) => tester.runAsync(() async {
      // ARRANGE
      final fromId = await database.accountsDao.addAccount(const AccountsCompanion(name: Value('From'), balance: Value(100), initialBalance: Value(100), type: Value('Cash'), creationDate: Value(20230101)));
      final toId = await database.accountsDao.addAccount(const AccountsCompanion(name: Value('To'), balance: Value(100), initialBalance: Value(100), type: Value('Cash'), creationDate: Value(20230101)));
      final dateAsInt = int.parse(DateFormat('yyyyMMdd').format(DateTime.now()));
      // From -> To: 10
      await database.bookingsDao.createBooking(BookingsCompanion(
        date: Value(dateAsInt),
        amount: const Value(10.0),
        sendingAccountId: Value(fromId),
        receivingAccountId: Value(toId),
      ));
      await pumpWidget(tester);

      // ACT
      // Create new transfer To -> From: 10
      await tester.tap(find.text('Überweisung'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(1), '10');
      // 'Von Konto'
      await tester.tap(find.byType(DropdownButtonFormField<int>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('To').last);
      await tester.pumpAndSettle();
      // 'Auf Konto'
      await tester.tap(find.byType(DropdownButtonFormField<int>).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('From').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Speichern'));
      await tester.pumpAndSettle();

      // Confirm merge
      expect(find.text('Buchungen zusammenführen?'), findsOneWidget);
      await tester.tap(find.text('Zusammenführen'));
      await tester.pumpAndSettle();

      // ASSERT
      final bookings = await database.select(database.bookings).get();
      expect(bookings.isEmpty, isTrue);
      await tester.pumpWidget(const SizedBox.shrink());
    }));

    testWidgets('does not show merge dialog if notes are not empty', (tester) => tester.runAsync(() async {
      // ARRANGE
      final accountId = await database.accountsDao.addAccount(const AccountsCompanion(name: Value('Test'), balance: Value(100), initialBalance: Value(100), type: Value('Cash'), creationDate: Value(20230101)));
      final dateAsInt = int.parse(DateFormat('yyyyMMdd').format(DateTime.now()));
      await database.bookingsDao.createBooking(BookingsCompanion(
        date: Value(dateAsInt),
        reason: const Value('Drinks'),
        amount: const Value(-8.0),
        receivingAccountId: Value(accountId),
      ));
      await pumpWidget(tester);

      // ACT
      // Fill form to match the existing booking but add notes
      await tester.enterText(find.byType(TextFormField).at(1), '-7.0');
      await tester.enterText(find.byType(TextFormField).at(2), 'Drinks');
      await tester.enterText(find.byType(TextFormField).at(3), 'Some notes'); // Add notes
      await tester.tap(find.byType(DropdownButtonFormField<int>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Test').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Speichern'));
      await tester.pumpAndSettle();

      // ASSERT
      expect(find.text('Buchungen zusammenführen?'), findsNothing);
      final bookings = await database.select(database.bookings).get();
      expect(bookings.length, 2);
      await tester.pumpWidget(const SizedBox.shrink());
    }));
  });
}
