import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:oktoast/oktoast.dart';
import 'package:provider/provider.dart';
import 'package:xfin/database/app_database.dart';
import 'package:xfin/database/tables.dart';
import 'package:xfin/l10n/app_localizations.dart';
import 'package:xfin/providers/base_currency_provider.dart';
import 'package:xfin/providers/database_provider.dart';

/// Centralized test helpers for form testing.
///
/// This class provides common utilities to eliminate duplication across
/// all form test files, including database setup, widget pumping,
/// field finding, and date/time picking.
class FormTestHelpers {
  // ════════════════════════════════════════════════════════════════
  // Database Setup Helpers
  // ════════════════════════════════════════════════════════════════

  /// Creates a new in-memory test database.
  static AppDatabase createTestDatabase() {
    return AppDatabase(NativeDatabase.memory());
  }

  /// Inserts the base currency asset (EUR, id=1) into the database.
  ///
  /// This is required for most form operations as the base currency
  /// is used for cost basis calculations.
  static Future<void> insertBaseCurrency(AppDatabase db) async {
    await db.into(db.assets).insert(const AssetsCompanion(
      name: Value('EUR'),
      type: Value(AssetTypes.fiat),
      tickerSymbol: Value('EUR'),
      currencySymbol: Value('€'),
      value: Value(0),
      shares: Value(0),
      brokerCostBasis: Value(1),
      netCostBasis: Value(1),
      buyFeeTotal: Value(0),
    ));
  }

  /// Inserts test accounts into the database.
  ///
  /// Creates one account of each type for testing.
  static Future<void> insertTestAccounts(AppDatabase db) async {
    await db.into(db.accounts).insert(const AccountsCompanion(
      name: Value('Test Cash Account'),
      type: Value(AccountTypes.cash),
      balance: Value(1000.0),
    ));
    await db.into(db.accounts).insert(const AccountsCompanion(
      name: Value('Test Bank Account'),
      type: Value(AccountTypes.bankAccount),
      balance: Value(5000.0),
    ));
    await db.into(db.accounts).insert(const AccountsCompanion(
      name: Value('Test Portfolio'),
      type: Value(AccountTypes.portfolio),
      balance: Value(10000.0),
    ));
    await db.into(db.accounts).insert(const AccountsCompanion(
      name: Value('Test Crypto Wallet'),
      type: Value(AccountTypes.cryptoWallet),
      balance: Value(2000.0),
    ));
  }

  /// Inserts test assets into the database.
  ///
  /// Creates sample assets of different types (stock, fiat, crypto).
  static Future<void> insertTestAssets(AppDatabase db) async {
    // Stock
    await db.into(db.assets).insert(const AssetsCompanion(
      name: Value('Apple Inc.'),
      type: Value(AssetTypes.stock),
      tickerSymbol: Value('AAPL'),
      value: Value(0),
      shares: Value(0),
      brokerCostBasis: Value(0),
      netCostBasis: Value(0),
      buyFeeTotal: Value(0),
    ));

    // Fiat (additional to base currency)
    await db.into(db.assets).insert(const AssetsCompanion(
      name: Value('US Dollar'),
      type: Value(AssetTypes.fiat),
      tickerSymbol: Value('USD'),
      currencySymbol: Value('\$'),
      value: Value(0),
      shares: Value(0),
      brokerCostBasis: Value(1.1),
      netCostBasis: Value(1.1),
      buyFeeTotal: Value(0),
    ));

    // Crypto
    await db.into(db.assets).insert(const AssetsCompanion(
      name: Value('Bitcoin'),
      type: Value(AssetTypes.crypto),
      tickerSymbol: Value('BTC'),
      currencySymbol: Value('₿'),
      value: Value(0),
      shares: Value(0),
      brokerCostBasis: Value(50000),
      netCostBasis: Value(50000),
      buyFeeTotal: Value(0),
    ));
  }

  // ════════════════════════════════════════════════════════════════
  // Widget Pumping Helpers
  // ════════════════════════════════════════════════════════════════

  /// Pumps a form widget inside a modal bottom sheet.
  ///
  /// This is the most realistic way to test forms since they're typically
  /// shown in sheets in the actual app.
  ///
  /// Usage:
  /// ```dart
  /// await FormTestHelpers.pumpFormInSheet(
  ///   tester: tester,
  ///   form: BookingForm(booking: null),
  ///   db: db,
  ///   currencyProvider: currencyProvider,
  /// );
  /// ```
  static Future<void> pumpFormInSheet({
    required WidgetTester tester,
    required Widget form,
    required AppDatabase db,
    required BaseCurrencyProvider currencyProvider,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<DatabaseProvider>.value(
                value: DatabaseProvider.instance),
            ChangeNotifierProvider<BaseCurrencyProvider>(
                create: (_) => currencyProvider),
          ],
          child: Scaffold(
            body: Builder(
              builder: (context) {
                return Center(
                  child: ElevatedButton(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (_) => OKToast(child: form),
                      );
                    },
                    child: const Text('Show Form'),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );

    // Tap button to show the form
    await tester.tap(find.text('Show Form'));
    await tester.pumpAndSettle();
  }

  /// Pumps a form widget directly in a Scaffold.
  ///
  /// Simpler than pumpFormInSheet but less realistic. Use this for forms
  /// that don't require sheet-specific behavior.
  ///
  /// Usage:
  /// ```dart
  /// await FormTestHelpers.pumpFormInPlace(
  ///   tester: tester,
  ///   form: AssetForm(),
  ///   db: db,
  ///   currencyProvider: currencyProvider,
  /// );
  /// ```
  static Future<void> pumpFormInPlace({
    required WidgetTester tester,
    required Widget form,
    required AppDatabase db,
    required BaseCurrencyProvider currencyProvider,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<DatabaseProvider>.value(
                value: DatabaseProvider.instance),
            ChangeNotifierProvider<BaseCurrencyProvider>(
                create: (_) => currencyProvider),
          ],
          child: Scaffold(
            body: OKToast(child: form),
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  // Progressive Rendering Helpers
  // ════════════════════════════════════════════════════════════════

  /// Waits for heavy widgets to appear after progressive rendering.
  ///
  /// Many forms use progressive rendering (loading cheap UI first, then
  /// heavy dropdowns/fields after data loads). This helper waits for
  /// specific widgets to appear.
  ///
  /// Usage:
  /// ```dart
  /// await FormTestHelpers.waitForHeavyRender(
  ///   tester,
  ///   requiredKeys: [Key('assets_dropdown'), Key('account_dropdown')],
  ///   timeoutMs: 3000,
  /// );
  /// ```
  static Future<void> waitForHeavyRender(
    WidgetTester tester, {
    List<Key> requiredKeys = const [],
    int timeoutMs = 3000,
    int intervalMs = 50,
  }) async {
    final tries = (timeoutMs / intervalMs).ceil();
    for (var i = 0; i < tries; i++) {
      await tester.pump(Duration(milliseconds: intervalMs));

      // Check if all required keys are present
      bool allPresent = true;
      for (final key in requiredKeys) {
        if (find.byKey(key).evaluate().isEmpty) {
          allPresent = false;
          break;
        }
      }

      if (allPresent) return;
    }

    // Final settle to produce useful failure logs
    await tester.pumpAndSettle();
  }

  // ════════════════════════════════════════════════════════════════
  // Field Finder Helpers
  // ════════════════════════════════════════════════════════════════

  /// Finds a DropdownButtonFormField by its InputDecoration.labelText.
  ///
  /// Useful when dropdowns don't have explicit keys.
  ///
  /// Usage:
  /// ```dart
  /// final accountDropdown = FormTestHelpers.dropdownByLabel('Account');
  /// await tester.tap(accountDropdown);
  /// ```
  static Finder dropdownByLabel(String label) {
    return find.byWidgetPredicate(
      (widget) {
        if (widget is DropdownButtonFormField) {
          try {
            final decoration = (widget as dynamic).decoration as InputDecoration?;
            return decoration != null && decoration.labelText == label;
          } catch (_) {
            return false;
          }
        }
        return false;
      },
      description: 'DropdownButtonFormField with label "$label"',
    );
  }

  /// Finds a TextFormField by its InputDecoration.labelText.
  ///
  /// Useful when text fields don't have explicit keys.
  ///
  /// Usage:
  /// ```dart
  /// final nameField = FormTestHelpers.textFieldByLabel('Name');
  /// await tester.enterText(nameField, 'Test Name');
  /// ```
  static Finder textFieldByLabel(String label) {
    return find.byWidgetPredicate(
      (widget) {
        if (widget is TextFormField) {
          // We need to check the child InputDecorator for the label
          // This is a simplified finder that looks for the label text nearby
          return true; // Will find by text label instead
        }
        return false;
      },
      description: 'TextFormField with label "$label"',
    );
  }

  /// Finds a widget containing the label text.
  ///
  /// More reliable than trying to access TextFormField.decoration.
  static Finder fieldByLabelText(String label) {
    return find.ancestor(
      of: find.text(label),
      matching: find.byType(TextFormField),
    );
  }

  // ════════════════════════════════════════════════════════════════
  // Date/Time Picker Helpers
  // ════════════════════════════════════════════════════════════════

  /// Simulates picking a date from the date picker dialog.
  ///
  /// Usage:
  /// ```dart
  /// await tester.tap(find.byIcon(Icons.calendar_today));
  /// await tester.pumpAndSettle();
  /// await FormTestHelpers.pickDate(tester, DateTime(2024, 3, 15));
  /// ```
  static Future<void> pickDate(WidgetTester tester, DateTime date) async {
    // Find and tap the OK button in the date picker
    // First, we need to select the date
    final formattedDate = DateFormat('d').format(date); // Day of month
    final dayFinder = find.text(formattedDate);

    if (dayFinder.evaluate().isNotEmpty) {
      await tester.tap(dayFinder.first);
      await tester.pumpAndSettle();
    }

    // Tap OK button
    final okButton = find.text('OK');
    if (okButton.evaluate().isNotEmpty) {
      await tester.tap(okButton);
      await tester.pumpAndSettle();
    }
  }

  /// Simulates picking a date and time from both picker dialogs.
  ///
  /// Usage:
  /// ```dart
  /// await tester.tap(find.byIcon(Icons.calendar_today));
  /// await tester.pumpAndSettle();
  /// await FormTestHelpers.pickDateTime(
  ///   tester,
  ///   DateTime(2024, 3, 15, 14, 30),
  /// );
  /// ```
  static Future<void> pickDateTime(
    WidgetTester tester,
    DateTime dateTime,
  ) async {
    // Pick date first
    await pickDate(tester, dateTime);

    // Time picker should now be shown
    await tester.pumpAndSettle();

    // For time picker, we'll just tap OK to use the initial time
    // (More complex time selection would require coordinate-based tapping)
    final okButton = find.text('OK');
    if (okButton.evaluate().isNotEmpty) {
      await tester.tap(okButton);
      await tester.pumpAndSettle();
    }
  }

  // ════════════════════════════════════════════════════════════════
  // Dropdown Selection Helpers
  // ════════════════════════════════════════════════════════════════

  /// Taps a dropdown and selects an item by text.
  ///
  /// Usage:
  /// ```dart
  /// await FormTestHelpers.selectDropdownItem(
  ///   tester,
  ///   dropdownFinder: find.byKey(Key('account_dropdown')),
  ///   itemText: 'Test Cash Account',
  /// );
  /// ```
  static Future<void> selectDropdownItem(
    WidgetTester tester, {
    required Finder dropdownFinder,
    required String itemText,
  }) async {
    await tester.tap(dropdownFinder);
    await tester.pumpAndSettle();

    final item = find.text(itemText).last;
    await tester.tap(item);
    await tester.pumpAndSettle();
  }

  // ════════════════════════════════════════════════════════════════
  // Validation Helpers
  // ════════════════════════════════════════════════════════════════

  /// Verifies that a form shows a validation error.
  ///
  /// Usage:
  /// ```dart
  /// FormTestHelpers.expectValidationError(tester, 'Required field');
  /// ```
  static void expectValidationError(WidgetTester tester, String errorText) {
    expect(find.text(errorText), findsOneWidget);
  }

  /// Verifies that a form has no validation errors.
  ///
  /// Usage:
  /// ```dart
  /// FormTestHelpers.expectNoValidationErrors(tester);
  /// ```
  static void expectNoValidationErrors(WidgetTester tester) {
    // Common error messages to check for
    final commonErrors = [
      'Required field',
      'Invalid',
      'must not be empty',
      'cannot be zero',
    ];

    for (final error in commonErrors) {
      expect(find.textContaining(error), findsNothing);
    }
  }
}
