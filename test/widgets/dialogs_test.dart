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
import 'package:xfin/providers/database_provider.dart';
import 'package:xfin/widgets/dialogs.dart';

import '../helpers/test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  late AppDatabase db;
  late BaseCurrencyProvider currencyProvider;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    DatabaseProvider.instance.initialize(db);
    currencyProvider = BaseCurrencyProvider();
    await currencyProvider.initialize(const Locale('en'));
    await TestHelpers.insertDefaultAsset(db);
  });

  tearDown(() async {
    await db.close();
  });

  /// Pumps a scaffold with providers and l10n, providing a button that
  /// triggers the given [onPressed] callback with a valid BuildContext.
  Future<void> pumpDialogTrigger(
    WidgetTester tester, {
    required void Function(BuildContext context) onPressed,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en'), Locale('de')],
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<DatabaseProvider>.value(
              value: DatabaseProvider.instance,
            ),
            ChangeNotifierProvider<BaseCurrencyProvider>.value(
              value: currencyProvider,
            ),
          ],
          child: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => onPressed(context),
                child: const Text('Trigger'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  // ══════════════════════════════════════════════════════════════════
  // showInfoDialog tests
  // ══════════════════════════════════════════════════════════════════

  group('showInfoDialog', () {
    testWidgets('renders title and content', (tester) async {
      await pumpDialogTrigger(tester, onPressed: (context) {
        showInfoDialog(context, 'Test Title', 'Test content message');
      });

      await tester.tap(find.text('Trigger'));
      await tester.pumpAndSettle();

      expect(find.text('Test Title'), findsOneWidget);
      expect(find.text('Test content message'), findsOneWidget);
    });

    testWidgets('displays OK button from l10n', (tester) async {
      await pumpDialogTrigger(tester, onPressed: (context) {
        showInfoDialog(context, 'Info', 'Some info');
      });

      await tester.tap(find.text('Trigger'));
      await tester.pumpAndSettle();

      expect(find.text('OK'), findsOneWidget);
    });

    testWidgets('dismisses when OK button is tapped', (tester) async {
      await pumpDialogTrigger(tester, onPressed: (context) {
        showInfoDialog(context, 'Dismissable', 'Should close');
      });

      await tester.tap(find.text('Trigger'));
      await tester.pumpAndSettle();

      expect(find.text('Dismissable'), findsOneWidget);

      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(find.text('Dismissable'), findsNothing);
    });

    testWidgets('is an AlertDialog', (tester) async {
      await pumpDialogTrigger(tester, onPressed: (context) {
        showInfoDialog(context, 'Alert', 'Check type');
      });

      await tester.tap(find.text('Trigger'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
    });
  });

  // ══════════════════════════════════════════════════════════════════
  // showErrorDialog tests
  // ══════════════════════════════════════════════════════════════════

  group('showErrorDialog', () {
    testWidgets('uses l10n error string as title', (tester) async {
      await pumpDialogTrigger(tester, onPressed: (context) {
        showErrorDialog(context, 'Something went wrong');
      });

      await tester.tap(find.text('Trigger'));
      await tester.pumpAndSettle();

      // l10n.error = "Error" in English
      expect(find.text('Error'), findsOneWidget);
      expect(find.text('Something went wrong'), findsOneWidget);
    });

    testWidgets('displays OK button and dismisses on tap', (tester) async {
      await pumpDialogTrigger(tester, onPressed: (context) {
        showErrorDialog(context, 'Oops');
      });

      await tester.tap(find.text('Trigger'));
      await tester.pumpAndSettle();

      expect(find.text('OK'), findsOneWidget);

      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(find.text('Error'), findsNothing);
    });
  });

  // ══════════════════════════════════════════════════════════════════
  // showDeleteDialog tests
  // ══════════════════════════════════════════════════════════════════

  group('showDeleteDialog', () {
    // ── Fixtures ──────────────────────────────────────────────────

    const testAccount = Account(
      id: 1,
      name: 'Test Account',
      balance: 100,
      initialBalance: 100,
      type: AccountTypes.cash,
      isArchived: false,
    );

    const testAsset = Asset(
      id: 2,
      name: 'Test Stock',
      type: AssetTypes.stock,
      tickerSymbol: 'TST',
      currencySymbol: null,
      value: 0,
      shares: 0,
      netCostBasis: 1,
      brokerCostBasis: 1,
      buyFeeTotal: 0,
      isArchived: false,
    );

    final testBooking = TestFixtures.createBooking(id: 1, accountId: 1);

    const testPeriodicBooking = PeriodicBooking(
      id: 1,
      nextExecutionDate: 20250401,
      assetId: 1,
      accountId: 1,
      shares: 50,
      costBasis: 1,
      value: 50,
      category: 'Rent',
      notes: null,
      cycle: Cycles.monthly,
      monthlyAverageFactor: 1,
    );

    final testTrade = TestFixtures.createTrade(id: 1);

    final testTransfer = TestFixtures.createTransfer(id: 1);

    const testPeriodicTransfer = PeriodicTransfer(
      id: 1,
      nextExecutionDate: 20250401,
      assetId: 1,
      sendingAccountId: 1,
      receivingAccountId: 2,
      shares: 100,
      costBasis: 1,
      value: 100,
      notes: null,
      cycle: Cycles.monthly,
      monthlyAverageFactor: 1,
    );

    // ── Returns early when no entity provided ─────────────────────

    testWidgets('returns early when no entity is provided', (tester) async {
      await pumpDialogTrigger(tester, onPressed: (context) {
        showDeleteDialog(context);
      });

      await tester.tap(find.text('Trigger'));
      await tester.pumpAndSettle();

      // No dialog should appear
      expect(find.byType(AlertDialog), findsNothing);
    });

    // ── Account branch ────────────────────────────────────────────

    group('account', () {
      testWidgets('shows correct title and confirmation text', (tester) async {
        await pumpDialogTrigger(tester, onPressed: (context) {
          showDeleteDialog(context, account: testAccount);
        });

        await tester.tap(find.text('Trigger'));
        await tester.pumpAndSettle();

        expect(find.text('Delete Account'), findsOneWidget);
        expect(
          find.text('Are you sure you want to delete this account?'),
          findsOneWidget,
        );
      });

      testWidgets('shows Cancel and Delete buttons', (tester) async {
        await pumpDialogTrigger(tester, onPressed: (context) {
          showDeleteDialog(context, account: testAccount);
        });

        await tester.tap(find.text('Trigger'));
        await tester.pumpAndSettle();

        expect(find.text('Cancel'), findsOneWidget);
        expect(find.text('Delete'), findsOneWidget);
      });

      testWidgets('cancel dismisses dialog without deleting', (tester) async {
        // Insert a real account into the DB so we can verify it still exists
        await db.into(db.accounts).insert(const AccountsCompanion(
              name: Value('To Keep'),
              type: Value(AccountTypes.cash),
              balance: Value(100),
            ));
        final accounts = await db.accountsDao.getAllAccounts();
        final account = accounts.first;

        await pumpDialogTrigger(tester, onPressed: (context) {
          showDeleteDialog(context, account: account);
        });

        await tester.tap(find.text('Trigger'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        // Dialog dismissed
        expect(find.byType(AlertDialog), findsNothing);

        // Account still exists
        final remaining = await db.accountsDao.getAllAccounts();
        expect(remaining.length, 1);
      });

      testWidgets('confirm deletes the account from the database',
          (tester) async {
        await db.into(db.accounts).insert(const AccountsCompanion(
              name: Value('To Delete'),
              type: Value(AccountTypes.cash),
              balance: Value(100),
            ));
        final accounts = await db.accountsDao.getAllAccounts();
        final account = accounts.first;

        await pumpDialogTrigger(tester, onPressed: (context) {
          showDeleteDialog(context, account: account);
        });

        await tester.tap(find.text('Trigger'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Delete'));
        await tester.pumpAndSettle();

        // Dialog dismissed
        expect(find.byType(AlertDialog), findsNothing);

        // Account deleted
        final remaining = await db.accountsDao.getAllAccounts();
        expect(remaining, isEmpty);
      });
    });

    // ── Asset branch ──────────────────────────────────────────────

    group('asset', () {
      testWidgets('shows correct title and confirmation text', (tester) async {
        await pumpDialogTrigger(tester, onPressed: (context) {
          showDeleteDialog(context, asset: testAsset);
        });

        await tester.tap(find.text('Trigger'));
        await tester.pumpAndSettle();

        expect(find.text('Delete Asset'), findsOneWidget);
        expect(
          find.text('Are you sure you want to delete this asset?'),
          findsOneWidget,
        );
      });

      testWidgets('confirm deletes the asset from the database',
          (tester) async {
        // Insert a test asset (id=2 because EUR is id=1)
        await db.into(db.assets).insert(const AssetsCompanion(
              name: Value('Delete Me Stock'),
              type: Value(AssetTypes.stock),
              tickerSymbol: Value('DEL'),
            ));
        final assets = await db.assetsDao.getAllAssets();
        // Find the one we just inserted (not the base currency)
        final asset = assets.firstWhere((a) => a.tickerSymbol == 'DEL');

        await pumpDialogTrigger(tester, onPressed: (context) {
          showDeleteDialog(context, asset: asset);
        });

        await tester.tap(find.text('Trigger'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Delete'));
        await tester.pumpAndSettle();

        final remaining = await db.assetsDao.getAllAssets();
        expect(remaining.any((a) => a.tickerSymbol == 'DEL'), isFalse);
      });
    });

    // ── Booking branch ────────────────────────────────────────────

    group('booking', () {
      testWidgets('shows correct title and confirmation text', (tester) async {
        await pumpDialogTrigger(tester, onPressed: (context) {
          showDeleteDialog(context, booking: testBooking);
        });

        await tester.tap(find.text('Trigger'));
        await tester.pumpAndSettle();

        expect(find.text('Delete Booking'), findsOneWidget);
        expect(
          find.text('Are you sure you want to delete this booking?'),
          findsOneWidget,
        );
      });

      testWidgets('confirm deletes the booking from the database',
          (tester) async {
        // Insert account first (for FK constraint)
        await db.into(db.accounts).insert(const AccountsCompanion(
              name: Value('Booking Account'),
              type: Value(AccountTypes.cash),
              balance: Value(1000),
            ));

        // Insert a booking
        await db.into(db.bookings).insert(BookingsCompanion.insert(
              date: 20250101,
              accountId: 1,
              category: 'Food',
              shares: 50,
              value: 50,
            ));

        final bookings = await db.bookingsDao.getAllBookings();
        final booking = bookings.first;

        await pumpDialogTrigger(tester, onPressed: (context) {
          showDeleteDialog(context, booking: booking);
        });

        await tester.tap(find.text('Trigger'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Delete'));
        await tester.pumpAndSettle();

        final remaining = await db.bookingsDao.getAllBookings();
        expect(remaining, isEmpty);
      });
    });

    // ── PeriodicBooking branch ────────────────────────────────────

    group('periodicBooking', () {
      testWidgets('shows standing order title and confirmation text',
          (tester) async {
        await pumpDialogTrigger(tester, onPressed: (context) {
          showDeleteDialog(context, periodicBooking: testPeriodicBooking);
        });

        await tester.tap(find.text('Trigger'));
        await tester.pumpAndSettle();

        expect(find.text('Delete Standing Order'), findsOneWidget);
        expect(
          find.text('Are you sure you want to delete this standing order?'),
          findsOneWidget,
        );
      });

      testWidgets('confirm deletes the periodic booking from the database',
          (tester) async {
        await db.into(db.accounts).insert(const AccountsCompanion(
              name: Value('PB Account'),
              type: Value(AccountTypes.cash),
              balance: Value(500),
            ));

        await db.into(db.periodicBookings).insert(
              PeriodicBookingsCompanion.insert(
                nextExecutionDate: 20250401,
                accountId: 1,
                shares: 50,
                value: 50,
                category: 'Rent',
              ),
            );

        final periodicBookings =
            await db.periodicBookingsDao.getAll();
        final pb = periodicBookings.first;

        await pumpDialogTrigger(tester, onPressed: (context) {
          showDeleteDialog(context, periodicBooking: pb);
        });

        await tester.tap(find.text('Trigger'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Delete'));
        await tester.pumpAndSettle();

        final remaining =
            await db.periodicBookingsDao.getAll();
        expect(remaining, isEmpty);
      });
    });

    // ── Trade branch ──────────────────────────────────────────────

    group('trade', () {
      testWidgets('shows correct title and confirmation text', (tester) async {
        await pumpDialogTrigger(tester, onPressed: (context) {
          showDeleteDialog(context, trade: testTrade);
        });

        await tester.tap(find.text('Trigger'));
        await tester.pumpAndSettle();

        expect(find.text('Delete Trade'), findsOneWidget);
        expect(
          find.text('Are you sure you want to delete this trade?'),
          findsOneWidget,
        );
      });

      testWidgets('confirm deletes the trade from the database',
          (tester) async {
        // Insert source and target accounts
        await db.into(db.accounts).insert(const AccountsCompanion(
              name: Value('Source Account'),
              type: Value(AccountTypes.cash),
              balance: Value(5000),
            ));
        await db.into(db.accounts).insert(const AccountsCompanion(
              name: Value('Target Portfolio'),
              type: Value(AccountTypes.portfolio),
              balance: Value(10000),
            ));

        // Insert a stock asset
        await db.into(db.assets).insert(const AssetsCompanion(
              name: Value('Trade Stock'),
              type: Value(AssetTypes.stock),
              tickerSymbol: Value('TRD'),
            ));

        // Insert a trade
        await db.into(db.trades).insert(TradesCompanion.insert(
              datetime: 20250101120000,
              type: TradeTypes.buy,
              sourceAccountId: 1,
              targetAccountId: 2,
              assetId: 2,
              shares: 10,
              costBasis: 100,
              sourceAccountValueDelta: -1000,
              targetAccountValueDelta: 1000,
            ));

        final trades = await db.tradesDao.getAllTrades();
        final trade = trades.first;

        await pumpDialogTrigger(tester, onPressed: (context) {
          showDeleteDialog(context, trade: trade);
        });

        await tester.tap(find.text('Trigger'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Delete'));
        await tester.pumpAndSettle();

        final remaining = await db.tradesDao.getAllTrades();
        expect(remaining, isEmpty);
      });
    });

    // ── Transfer branch ───────────────────────────────────────────

    group('transfer', () {
      testWidgets('shows correct title and confirmation text', (tester) async {
        await pumpDialogTrigger(tester, onPressed: (context) {
          showDeleteDialog(context, transfer: testTransfer);
        });

        await tester.tap(find.text('Trigger'));
        await tester.pumpAndSettle();

        expect(find.text('Delete Transfer'), findsOneWidget);
        expect(
          find.text('Are you sure you want to delete this transfer?'),
          findsOneWidget,
        );
      });

      testWidgets('confirm deletes the transfer from the database',
          (tester) async {
        await db.into(db.accounts).insert(const AccountsCompanion(
              name: Value('Sending Account'),
              type: Value(AccountTypes.cash),
              balance: Value(2000),
            ));
        await db.into(db.accounts).insert(const AccountsCompanion(
              name: Value('Receiving Account'),
              type: Value(AccountTypes.bankAccount),
              balance: Value(3000),
            ));

        await db.into(db.transfers).insert(TransfersCompanion.insert(
              date: 20250101,
              sendingAccountId: 1,
              receivingAccountId: 2,
              shares: 100,
              value: 100,
            ));

        final transfers = await db.transfersDao.getAllTransfers();
        final transfer = transfers.first;

        await pumpDialogTrigger(tester, onPressed: (context) {
          showDeleteDialog(context, transfer: transfer);
        });

        await tester.tap(find.text('Trigger'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Delete'));
        await tester.pumpAndSettle();

        final remaining = await db.transfersDao.getAllTransfers();
        expect(remaining, isEmpty);
      });
    });

    // ── PeriodicTransfer branch ───────────────────────────────────

    group('periodicTransfer', () {
      testWidgets('shows standing order title and confirmation text',
          (tester) async {
        await pumpDialogTrigger(tester, onPressed: (context) {
          showDeleteDialog(context, periodicTransfer: testPeriodicTransfer);
        });

        await tester.tap(find.text('Trigger'));
        await tester.pumpAndSettle();

        expect(find.text('Delete Standing Order'), findsOneWidget);
        expect(
          find.text('Are you sure you want to delete this standing order?'),
          findsOneWidget,
        );
      });

      testWidgets('confirm deletes the periodic transfer from the database',
          (tester) async {
        await db.into(db.accounts).insert(const AccountsCompanion(
              name: Value('PT Sending'),
              type: Value(AccountTypes.cash),
              balance: Value(1000),
            ));
        await db.into(db.accounts).insert(const AccountsCompanion(
              name: Value('PT Receiving'),
              type: Value(AccountTypes.bankAccount),
              balance: Value(2000),
            ));

        await db.into(db.periodicTransfers).insert(
              PeriodicTransfersCompanion.insert(
                nextExecutionDate: 20250401,
                sendingAccountId: 1,
                receivingAccountId: 2,
                shares: 100,
                value: 100,
              ),
            );

        final periodicTransfers =
            await db.periodicTransfersDao.getAll();
        final pt = periodicTransfers.first;

        await pumpDialogTrigger(tester, onPressed: (context) {
          showDeleteDialog(context, periodicTransfer: pt);
        });

        await tester.tap(find.text('Trigger'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Delete'));
        await tester.pumpAndSettle();

        final remaining =
            await db.periodicTransfersDao.getAll();
        expect(remaining, isEmpty);
      });
    });

    // ── Priority ordering (account takes precedence over others) ──

    testWidgets('account takes precedence when multiple entities are provided',
        (tester) async {
      await pumpDialogTrigger(tester, onPressed: (context) {
        showDeleteDialog(
          context,
          account: testAccount,
          booking: testBooking,
        );
      });

      await tester.tap(find.text('Trigger'));
      await tester.pumpAndSettle();

      // Account title should be shown, not booking
      expect(find.text('Delete Account'), findsOneWidget);
      expect(find.text('Delete Booking'), findsNothing);
    });
  });
}
