import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:xfin/database/app_database.dart';
import 'package:xfin/widgets/account_form.dart';

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
          child: const Scaffold(body: AccountForm()),
        ),
      ),
    );
  }

  // Helper to find a text field by its label
  Finder findTextFieldByLabel(String label) {
    return find.byWidgetPredicate(
      (widget) => widget is TextField && widget.decoration?.labelText == label,
    );
  }

  // Helper to find a dropdown by its label
  Finder findDropdownFieldByLabel(String label) {
    return find.byWidgetPredicate(
      (widget) => widget is DropdownButtonFormField<String> && widget.decoration.labelText == label,
    );
  }

  testWidgets('New account form submits with correct data', (tester) => tester.runAsync(() async {
    await pumpWidget(tester);
    await tester.pumpAndSettle(); // Wait for async operations in initState

    // Enter data into the form
    await tester.enterText(findTextFieldByLabel('Account Name'), 'Test Account');
    await tester.enterText(findTextFieldByLabel('Initial Balance'), '150.50');

    // Save the form
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    // Verify the data was saved correctly
    final account = await (database.select(database.accounts)..where((a) => a.id.equals(1))).getSingle();
    expect(account.name, 'Test Account');
    expect(account.balance, 150.50);
    expect(account.initialBalance, 150.50);
    expect(account.type, 'Cash');
    final expectedDate = int.parse(DateFormat('yyyyMMdd').format(DateTime.now()));
    expect(account.creationDate, expectedDate);
  }));

  group('AccountForm validation', () {
    testWidgets('shows error when name is empty', (tester) => tester.runAsync(() async {
      await pumpWidget(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save'));
      await tester.pump(); // a single frame for validation message

      expect(find.text('Please enter a name'), findsOneWidget);
    }));

    testWidgets('shows error when name is not unique', (tester) => tester.runAsync(() async {
      await database.accountsDao.addAccount(const AccountsCompanion(
        name: Value('Existing Account'),
        balance: Value(100),
        initialBalance: Value(100),
        type: Value('Cash'),
        creationDate: Value(20230101)
      ));

      await pumpWidget(tester);
      await tester.pumpAndSettle();

      await tester.enterText(findTextFieldByLabel('Account Name'), 'Existing Account');
      await tester.tap(find.text('Save'));
      await tester.pump();

      expect(find.text('An account with this name already exists.'), findsOneWidget);
    }));

    testWidgets('shows error when initial balance is empty', (tester) => tester.runAsync(() async {
      await pumpWidget(tester);
       await tester.pumpAndSettle();

      await tester.enterText(findTextFieldByLabel('Account Name'), 'My Account');
      await tester.enterText(findTextFieldByLabel('Initial Balance'), '');
      await tester.tap(find.text('Save'));
      await tester.pump();

      expect(find.text('Please enter a balance'), findsOneWidget);
    }));
    
    testWidgets('shows error when initial balance is not a number', (tester) => tester.runAsync(() async {
      await pumpWidget(tester);
       await tester.pumpAndSettle();

      await tester.enterText(findTextFieldByLabel('Account Name'), 'My Account');
      await tester.enterText(findTextFieldByLabel('Initial Balance'), 'abc');
      await tester.tap(find.text('Save'));
      await tester.pump();

      expect(find.text('Invalid number'), findsOneWidget);
    }));

    testWidgets('shows error when initial balance is negative', (tester) => tester.runAsync(() async {
      await pumpWidget(tester);
      await tester.pumpAndSettle();

      await tester.enterText(findTextFieldByLabel('Account Name'), 'My Account');
      await tester.enterText(findTextFieldByLabel('Initial Balance'), '-50');
      await tester.tap(find.text('Save'));
      await tester.pump();

      expect(find.text('Initial balance cannot be negative.'), findsOneWidget);
    }));

    testWidgets('dropdown selection updates account type', (tester) => tester.runAsync(() async {
      await pumpWidget(tester);
      await tester.pumpAndSettle();

      // Tap on the dropdown to open it
      await tester.tap(findDropdownFieldByLabel('Type'));
      await tester.pumpAndSettle();

      // Tap on 'Bank' to select it
      await tester.tap(find.text('Bank').last); // Use .last if multiple 'Bank' texts exist
      await tester.pumpAndSettle();

      // Enter data for other fields
      await tester.enterText(findTextFieldByLabel('Account Name'), 'Bank Account');
      await tester.enterText(findTextFieldByLabel('Initial Balance'), '200.00');

      // Save the form
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Verify the data was saved correctly with the updated type
      final account = await (database.select(database.accounts)..where((a) => a.name.equals('Bank Account'))).getSingle();
      expect(account.type, 'Bank');
    }));

    testWidgets('cancel button pops the form', (tester) => tester.runAsync(() async {
      await pumpWidget(tester);
      await tester.pumpAndSettle();

      // Verify the form is present
      expect(find.byType(AccountForm), findsOneWidget);

      // Tap the cancel button
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Verify the form is no longer present
      expect(find.byType(AccountForm), findsNothing);
    }));
  });
}
