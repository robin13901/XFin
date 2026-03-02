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

/// Test helper class that provides common test setup and utilities.
///
/// This eliminates duplicated test code across multiple screen test files.
class TestHelpers {
  /// Initializes test environment with mock SharedPreferences.
  static void setupTestEnvironment() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  }

  /// Creates an in-memory database for testing.
  static AppDatabase createTestDatabase() {
    return AppDatabase(NativeDatabase.memory());
  }

  /// Initializes the database provider with the given database.
  static void initializeDatabaseProvider(AppDatabase db) {
    DatabaseProvider.instance.initialize(db);
  }

  /// Creates and initializes a currency provider with the given locale.
  static Future<BaseCurrencyProvider> createCurrencyProvider([
    Locale locale = const Locale('en'),
  ]) async {
    final provider = BaseCurrencyProvider();
    await provider.initialize(locale);
    return provider;
  }

  /// Inserts the default EUR asset (id=1) required by most tests.
  static Future<void> insertDefaultAsset(AppDatabase db) async {
    await db.into(db.assets).insert(AssetsCompanion.insert(
          name: 'EUR',
          type: AssetTypes.fiat,
          tickerSymbol: 'EUR',
        ));
  }

  /// Pumps a widget with all required providers and localization delegates.
  ///
  /// Returns the AppLocalizations instance for accessing localized strings.
  static Future<AppLocalizations> pumpWidgetWithProviders({
    required WidgetTester tester,
    required Widget child,
    required BaseCurrencyProvider currencyProvider,
    List<Locale> supportedLocales = const [Locale('en'), Locale('de')],
  }) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<DatabaseProvider>.value(
            value: DatabaseProvider.instance,
          ),
          ChangeNotifierProvider<BaseCurrencyProvider>.value(
            value: currencyProvider,
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: supportedLocales,
          home: child,
        ),
      ),
    );

    // Return localization instance
    final context = tester.element(find.byWidget(child));
    return AppLocalizations.of(context)!;
  }

  /// Simulates a long press gesture on a widget found by the given finder.
  static Future<void> simulateLongPress(
    WidgetTester tester,
    Finder finder,
  ) async {
    final center = tester.getCenter(finder);
    final gesture = await tester.startGesture(center);
    await tester.pump();
    await Future.delayed(kLongPressTimeout);
    await gesture.up();
    await tester.pumpAndSettle();
  }

  /// Creates a complete test setup with database, providers, and default asset.
  ///
  /// Returns a [TestSetup] object containing all test dependencies.
  static Future<TestSetup> createCompleteSetup({
    Locale locale = const Locale('en'),
    bool insertDefaultAsset = true,
  }) async {
    final db = createTestDatabase();
    initializeDatabaseProvider(db);
    final currencyProvider = await createCurrencyProvider(locale);

    if (insertDefaultAsset) {
      await TestHelpers.insertDefaultAsset(db);
    }

    return TestSetup(
      db: db,
      currencyProvider: currencyProvider,
    );
  }
}

/// Container for test setup dependencies.
class TestSetup {
  final AppDatabase db;
  final BaseCurrencyProvider currencyProvider;

  TestSetup({
    required this.db,
    required this.currencyProvider,
  });

  /// Cleans up all resources.
  Future<void> dispose() async {
    await db.close();
  }
}

/// Extension methods for WidgetTester to improve test readability.
extension WidgetTesterExtensions on WidgetTester {
  /// Waits for all async operations and animations to complete.
  Future<void> pumpAndSettleWithAsync() async {
    await pump();
    await pumpAndSettle();
  }

  /// Taps a widget and waits for animations to complete.
  Future<void> tapAndSettle(Finder finder) async {
    await tap(finder);
    await pumpAndSettle();
  }

  /// Verifies that a widget exists exactly once.
  void expectSingle(Finder finder, {String? reason}) {
    expect(finder, findsOneWidget, reason: reason);
  }

  /// Verifies that a widget does not exist.
  void expectNone(Finder finder, {String? reason}) {
    expect(finder, findsNothing, reason: reason);
  }
}

/// Common test data fixtures.
class TestFixtures {
  static const Account cashAccount = Account(
    id: 1,
    name: 'Test Cash Account',
    balance: 1000,
    initialBalance: 1000,
    type: AccountTypes.cash,
    isArchived: false,
  );

  static const Account portfolioAccount = Account(
    id: 2,
    name: 'Test Portfolio',
    balance: 5000,
    initialBalance: 5000,
    type: AccountTypes.portfolio,
    isArchived: false,
  );

  static const Account archivedAccount = Account(
    id: 3,
    name: 'Archived Account',
    balance: 500,
    initialBalance: 500,
    type: AccountTypes.cash,
    isArchived: true,
  );

  static Booking createBooking({
    required int id,
    required int accountId,
    int assetId = 1,
    int date = 20250101,
    String category = 'Test Category',
    double shares = 100,
    double value = 100,
    double costBasis = 1,
    bool excludeFromAverage = false,
    bool isGenerated = false,
  }) {
    return Booking(
      id: id,
      date: date,
      shares: shares,
      costBasis: costBasis,
      assetId: assetId,
      value: value,
      category: category,
      accountId: accountId,
      excludeFromAverage: excludeFromAverage,
      isGenerated: isGenerated,
    );
  }

  static Trade createTrade({
    required int id,
    int sourceAccountId = 1,
    int targetAccountId = 2,
    int assetId = 1,
    TradeTypes type = TradeTypes.buy,
    int datetime = 20250101120000,
    double shares = 10,
    double costBasis = 100,
    double fee = 5,
    double tax = 0,
  }) {
    return Trade(
      id: id,
      datetime: datetime,
      type: type,
      shares: shares,
      costBasis: costBasis,
      assetId: assetId,
      fee: fee,
      tax: tax,
      sourceAccountValueDelta: -(shares * costBasis + fee + tax),
      targetAccountValueDelta: shares * costBasis + fee + tax,
      profitAndLoss: 0,
      returnOnInvest: 0,
      sourceAccountId: sourceAccountId,
      targetAccountId: targetAccountId,
    );
  }

  static Transfer createTransfer({
    required int id,
    int sendingAccountId = 1,
    int receivingAccountId = 2,
    int assetId = 1,
    int date = 20250101,
    double shares = 100,
    double costBasis = 1,
    String? notes,
    bool isGenerated = false,
  }) {
    return Transfer(
      id: id,
      date: date,
      shares: shares,
      costBasis: costBasis,
      value: shares * costBasis,
      assetId: assetId,
      sendingAccountId: sendingAccountId,
      receivingAccountId: receivingAccountId,
      notes: notes,
      isGenerated: isGenerated,
    );
  }
}
