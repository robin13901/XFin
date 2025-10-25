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

  Future<void> pumpWidget(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Provider<AppDatabase>(
          create: (_) => database,
          child: const Scaffold(body: BookingForm()),
        ),
      ),
    );
  }

  testWidgets('form submits with correct data', (tester) => tester.runAsync(() async {
    await database.accountsDao.addAccount(const AccountsCompanion(name: Value('Test'), balance: Value(100)));
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
      await database.accountsDao.addAccount(const AccountsCompanion(name: Value('Test1'), balance: Value(100)));
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
      await database.accountsDao.addAccount(const AccountsCompanion(name: Value('Test1'), balance: Value(100)));
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
}