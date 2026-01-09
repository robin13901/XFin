import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:oktoast/oktoast.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xfin/database/app_database.dart';
import 'package:xfin/database/tables.dart';
import 'package:xfin/l10n/app_localizations.dart';
import 'package:xfin/providers/base_currency_provider.dart';
import 'package:xfin/utils/format.dart';
import 'package:xfin/widgets/transfer_form.dart';

extension WidgetTesterX on WidgetTester {
  Future<void> pumpUntilNoLongerFound(Finder finder,
      {Duration timeout = const Duration(seconds: 5)}) async {
    final end = DateTime.now().add(timeout);

    while (DateTime.now().isBefore(end)) {
      await pump(const Duration(milliseconds: 20));
      if (any(finder) == false) return;
    }

    throw TestFailure('pumpUntilNoLongerFound timed out: $finder');
  }
}

void main() {
  late AppDatabase db;
  late AppLocalizations l10n;
  late BaseCurrencyProvider currencyProvider;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    const locale = Locale('en');
    l10n = await AppLocalizations.delegate.load(locale);
    currencyProvider = BaseCurrencyProvider();
    await currencyProvider.initialize(locale);

    // Create base currency asset (id = 1)
    await db.into(db.assets).insert(const AssetsCompanion(
      name: Value('EUR'),
      type: Value(AssetTypes.fiat),
      tickerSymbol: Value('EUR'),
      value: Value(0),
      shares: Value(0),
      brokerCostBasis: Value(1),
      netCostBasis: Value(1),
      buyFeeTotal: Value(0),
    ));
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> pumpWidget(WidgetTester tester, {Transfer? transfer}) async {
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
            Provider<AppDatabase>(create: (_) => db),
            ChangeNotifierProvider<BaseCurrencyProvider>(
                create: (_) => currencyProvider),
          ],
          child: Builder(builder: (context) {
            return Scaffold(
              body: Center(
                child: ElevatedButton(
                  child: const Text('Show Form'),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => MultiProvider(
                        providers: [
                          Provider<AppDatabase>.value(value: db),
                          ChangeNotifierProvider<BaseCurrencyProvider>.value(
                              value: currencyProvider),
                        ],
                        child: TransferForm(transfer: transfer),
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

  Future<void> pumpWidgetWithToast(WidgetTester tester,
      {Transfer? transfer}) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<AppDatabase>.value(value: db),
          ChangeNotifierProvider<BaseCurrencyProvider>.value(
              value: currencyProvider),
        ],
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
              body: TransferForm(transfer: transfer),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
  }

  group('TransferForm Tests', () {
    late int sendingAccountId;
    late int receivingAccountId;
    late int cryptoAssetId;

    setUp(() async {
      // Create accounts used in many tests
      sendingAccountId = await db.accountsDao.insert(const AccountsCompanion(
        name: Value('Sender'),
        balance: Value(100.0),
        initialBalance: Value(100.0),
        type: Value(AccountTypes.cash),
      ));

      receivingAccountId = await db.accountsDao.insert(const AccountsCompanion(
        name: Value('Receiver'),
        balance: Value(50.0),
        initialBalance: Value(50.0),
        type: Value(AccountTypes.cash),
      ));

      // Create a crypto asset (id will be 2)
      cryptoAssetId = await db.into(db.assets).insert(const AssetsCompanion(
        name: Value('BTC'),
        type: Value(AssetTypes.crypto),
        tickerSymbol: Value('BTC'),
        value: Value(0),
        shares: Value(0),
        brokerCostBasis: Value(0),
        netCostBasis: Value(0),
        buyFeeTotal: Value(0),
      ));

      // Give sender some base-currency shares in assets_on_accounts so getAOA finds them.
      await db.into(db.assetsOnAccounts).insert(AssetsOnAccountsCompanion.insert(
        accountId: sendingAccountId,
        assetId: 1,
        shares: const Value(100),
        value: const Value(100),
      ));

      // For crypto asset also give sender some shares (useful for crypto-related tests)
      await db.into(db.assetsOnAccounts).insert(AssetsOnAccountsCompanion.insert(
        accountId: sendingAccountId,
        assetId: cryptoAssetId,
        shares: const Value(10),
        value: const Value(10),
      ));
    });

    testWidgets('form initializes empty for new transfer',
            (tester) => tester.runAsync(() async {
          await pumpWidget(tester);

          // The bottom sheet contains the TransferForm
          expect(find.byType(TransferForm), findsOneWidget);

          // Date field default is today
          final dateField = tester.widget<TextFormField>(
              find.byType(TextFormField).first);
          expect(dateField.controller!.text,
              DateFormat('dd.MM.yyyy').format(DateTime.now()));

          // Assets dropdown default value should be 1 (base asset)
          expect(
              tester
                  .widget<DropdownButtonFormField>(find.byKey(
                  const Key('assets_dropdown')))
                  .initialValue,
              1);

          // Shares field empty
          expect(
              tester
                  .widget<TextFormField>(find.byKey(const Key('shares_field')))
                  .controller!
                  .text,
              '');

          // Sending & receiving initial values null
          expect(
              tester
                  .widget<DropdownButtonFormField<int>>(
                  find.byKey(const Key('sending_account_dropdown')))
                  .initialValue,
              null);
          expect(
              tester
                  .widget<DropdownButtonFormField<int>>(
                  find.byKey(const Key('receiving_account_dropdown')))
                  .initialValue,
              null);

          await tester.pumpWidget(Container());
        }));

    testWidgets('form initializes with data for existing transfer',
            (tester) => tester.runAsync(() async {
          // Insert a transfer and open form for editing
          final companion = TransfersCompanion.insert(
            date: dateTimeToInt(DateTime(2025, 5, 1)),
            shares: 5,
            costBasis: const Value(2.0),
            value: 10.0,
            assetId: Value(cryptoAssetId),
            sendingAccountId: sendingAccountId,
            receivingAccountId: receivingAccountId,
            isGenerated: const Value(false),
          );
          final id = await db.into(db.transfers).insert(companion);
          final transfer = Transfer(
            id: id,
            date: 20250501,
            shares: 5,
            costBasis: 2.0,
            value: 10.0,
            assetId: cryptoAssetId,
            sendingAccountId: sendingAccountId,
            receivingAccountId: receivingAccountId,
            notes: null,
            isGenerated: false,
          );

          await pumpWidget(tester, transfer: transfer);

          // Date shown correctly
          expect(find.text('01.05.2025'), findsOneWidget);

          // Shares shown
          expect(find.text('5.0'), findsOneWidget);

          // Dropdowns preselected
          expect(
              tester
                  .widget<DropdownButtonFormField<int>>(find.byKey(
                  const Key('sending_account_dropdown')))
                  .initialValue,
              sendingAccountId);
          expect(
              tester
                  .widget<DropdownButtonFormField<int>>(find.byKey(
                  const Key('receiving_account_dropdown')))
                  .initialValue,
              receivingAccountId);

          await tester.pumpWidget(Container());
        }));

    group('Validation', () {
      testWidgets('shows errors for invalid amount',
              (tester) => tester.runAsync(() async {
            await pumpWidget(tester);

            // Try save with empty form -> required errors
            await tester.tap(find.text(l10n.save));
            await tester.pumpAndSettle();
            expect(find.text(l10n.requiredField), findsWidgets);

            // Enter invalid shares text
            await tester.enterText(
                find.byKey(const Key('shares_field')), 'invalid');
            await tester.tap(find.text(l10n.save));
            await tester.pumpAndSettle();
            expect(find.text(l10n.invalidInput), findsOneWidget);

            // Too many decimal places (validator expects at most 2)
            await tester.enterText(
                find.byKey(const Key('shares_field')), '1.234');
            await tester.tap(find.text(l10n.save));
            await tester.pumpAndSettle();
            expect(find.text(l10n.tooManyDecimalPlaces), findsOneWidget);

            await tester.pumpWidget(Container());
          }));

      testWidgets('shows error if sending and receiving are the same',
              (tester) => tester.runAsync(() async {
            await pumpWidgetWithToast(tester);

            // Fill shares
            await tester.enterText(
                find.byKey(const Key('shares_field')), '10');

            // Select same account for sending and receiving
            await tester.tap(find.byKey(const Key('sending_account_dropdown')));
            await tester.pumpAndSettle();
            await tester.tap(find.text('Sender').last);
            await tester.pumpAndSettle();

            await tester.tap(find.byKey(const Key('receiving_account_dropdown')));
            await tester.pumpAndSettle();
            await tester.tap(find.text('Sender').last);
            await tester.pumpAndSettle();

            await tester.tap(find.text(l10n.save));
            await tester.pumpAndSettle();

            // Should show toast for same accounts
            expect(find.text(l10n.sendingAndReceivingMustDiffer), findsOneWidget);

            await tester.pumpWidget(Container());
          }));
    });

    group('Receiving account compatibility', () {
      testWidgets('cash account rejects non-fiat asset',
              (tester) => tester.runAsync(() async {
            // Make receiving account of type cash (already is)
            // Create a crypto transfer attempt
            await pumpWidgetWithToast(tester);

            // Select crypto asset
            await tester.tap(find.byKey(const Key('assets_dropdown')));
            await tester.pumpAndSettle();
            await tester.tap(find.text('BTC').last);
            await tester.pumpAndSettle();

            // Fill shares
            await tester.enterText(
                find.byKey(const Key('shares_field')), '1');

            // Choose distinct sending and receiving
            await tester.tap(find.byKey(const Key('sending_account_dropdown')));
            await tester.pumpAndSettle();
            await tester.tap(find.text('Sender').last);
            await tester.pumpAndSettle();

            await tester.tap(find.byKey(const Key('receiving_account_dropdown')));
            await tester.pumpAndSettle();
            await tester.tap(find.text('Receiver').last);
            await tester.pumpAndSettle();

            await tester.tap(find.text(l10n.save));
            await tester.pumpAndSettle();

            // Expect toast that only currencies can be booked on cash accounts
            expect(find.text(l10n.onlyCurrenciesCanBeBookedOnCashAccount), findsOneWidget);

            await tester.pumpWidget(Container());
          }));

      testWidgets('bank account rejects non-base-currency asset',
              (tester) => tester.runAsync(() async {
            // Change receiving account to bankAccount
            await db.accountsDao.insert(const AccountsCompanion(
              name: Value('Bank'),
              balance: Value(0),
              initialBalance: Value(0),
              type: Value(AccountTypes.bankAccount),
            ));

            await pumpWidgetWithToast(tester);

            // Select crypto asset (non-base currency)
            await tester.tap(find.byKey(const Key('assets_dropdown')));
            await tester.pumpAndSettle();
            await tester.tap(find.text('BTC').last);
            await tester.pumpAndSettle();

            // Fill shares
            await tester.enterText(
                find.byKey(const Key('shares_field')), '1');

            // Choose sending
            await tester.tap(find.byKey(const Key('sending_account_dropdown')));
            await tester.pumpAndSettle();
            await tester.tap(find.text('Sender').last);
            await tester.pumpAndSettle();

            // Choose receiving -> Bank
            await tester.tap(find.byKey(const Key('receiving_account_dropdown')));
            await tester.pumpAndSettle();
            await tester.tap(find.text('Bank').last);
            await tester.pumpAndSettle();

            await tester.tap(find.text(l10n.save));
            await tester.pumpAndSettle();

            expect(find.text(l10n.onlyBaseCurrencyCanBeBookedOnBankAccount), findsOneWidget);

            await tester.pumpWidget(Container());
          }));

      testWidgets('crypto wallet rejects non-crypto asset',
              (tester) => tester.runAsync(() async {
            // Create receiving crypto-wallet account
            await db.accountsDao.insert(const AccountsCompanion(
              name: Value('CW'),
              balance: Value(0),
              initialBalance: Value(0),
              type: Value(AccountTypes.cryptoWallet),
            ));

            await pumpWidgetWithToast(tester);

            // Select base asset (fiat) which is invalid for cryptoWallet
            // base asset is 'EUR' with id = 1 (fiat)
            await tester.tap(find.byKey(const Key('assets_dropdown')));
            await tester.pumpAndSettle();
            await tester.tap(find.text('EUR').last);
            await tester.pumpAndSettle();

            // Fill shares
            await tester.enterText(
                find.byKey(const Key('shares_field')), '1');

            // Choose sending
            await tester.tap(find.byKey(const Key('sending_account_dropdown')));
            await tester.pumpAndSettle();
            await tester.tap(find.text('Sender').last);
            await tester.pumpAndSettle();

            // Choose receiving -> CW
            await tester.tap(find.byKey(const Key('receiving_account_dropdown')));
            await tester.pumpAndSettle();
            await tester.tap(find.text('CW').last);
            await tester.pumpAndSettle();

            await tester.tap(find.text(l10n.save));
            await tester.pumpAndSettle();

            expect(find.text(l10n.onlyCryptoCanBeBookedOnCryptoWallet), findsOneWidget);

            await tester.pumpWidget(Container());
          }));
    });

    group('Form Submission', () {
      testWidgets('Create new transfer successfully (FIFO cost basis)',
              (tester) => tester.runAsync(() async {
            // To get a meaningful FIFO we create bookings (lots) for the sending account
            // booking 1: 30 shares @ costBasis 1
            await db.bookingsDao.createBooking(BookingsCompanion.insert(
              date: dateTimeToInt(DateTime.now().subtract(const Duration(days: 2))),
              accountId: sendingAccountId,
              category: 'lot1',
              shares: 30,
              costBasis: const Value(1.0),
              value: 30.0,
              assetId: const Value(1),
              excludeFromAverage: const Value(false),
              isGenerated: const Value(false),
            ), l10n);
            // booking 2: 70 shares @ costBasis 1
            await db.bookingsDao.createBooking(BookingsCompanion.insert(
              date: dateTimeToInt(DateTime.now().subtract(const Duration(days: 1))),
              accountId: sendingAccountId,
              category: 'lot2',
              shares: 70,
              costBasis: const Value(2.0),
              value: 70.0,
              assetId: const Value(1),
              excludeFromAverage: const Value(false),
              isGenerated: const Value(false),
            ), l10n);

            await pumpWidget(tester);

            // Transfer 50 shares -> should take 30@1 + 20@1 = value 30 + 20 = 50
            await tester.enterText(
                find.byKey(const Key('shares_field')), '50');

            // Choose accounts
            await tester.tap(find.byKey(const Key('sending_account_dropdown')));
            await tester.pumpAndSettle();
            await tester.tap(find.text('Sender').last);
            await tester.pumpAndSettle();

            await tester.tap(find.byKey(const Key('receiving_account_dropdown')));
            await tester.pumpAndSettle();
            await tester.tap(find.text('Receiver').last);
            await tester.pumpAndSettle();

            await tester.tap(find.text(l10n.save));
            await tester.pumpUntilNoLongerFound(find.byType(TransferForm));

            final transfers = await (db.select(db.transfers)).get();
            expect(transfers.length, 1);
            final t = transfers.first;
            expect(t.shares, 50);
            // value should be 70.0
            expect(t.value, closeTo(50.0, 0.0001));
            // costBasis per share
            expect(t.costBasis, closeTo(1.0, 0.0001));

            final senderAOA = await db.assetsOnAccountsDao.getAOA(sendingAccountId, 1);
            expect(senderAOA.shares, closeTo(150.0, 0.0001));
            expect(senderAOA.value, closeTo(150.0, 0.0001));
            expect(senderAOA.netCostBasis, closeTo(1, 0.0001));
            expect(senderAOA.brokerCostBasis, closeTo(1, 0.0001));

            final receiverAOA = await db.assetsOnAccountsDao.getAOA(receivingAccountId, 1);
            expect(receiverAOA.shares, closeTo(50.0, 0.0001));
            expect(receiverAOA.value, closeTo(50.0, 0.0001));
            expect(receiverAOA.netCostBasis, closeTo(1, 0.0001));
            expect(receiverAOA.brokerCostBasis, closeTo(1, 0.0001));

            await tester.pumpWidget(Container());
          }));

      testWidgets('shows toast for insufficient shares',
              (tester) => tester.runAsync(() async {
            await pumpWidgetWithToast(tester);

            // Sender has 100 base shares (AOA) — try to transfer more than available
            await tester.enterText(
                find.byKey(const Key('shares_field')), '150');

            await tester.tap(find.byKey(const Key('sending_account_dropdown')));
            await tester.pumpAndSettle();
            await tester.tap(find.text('Sender').last);
            await tester.pumpAndSettle();

            await tester.tap(find.byKey(const Key('receiving_account_dropdown')));
            await tester.pumpAndSettle();
            await tester.tap(find.text('Receiver').last);
            await tester.pumpAndSettle();

            await tester.tap(find.text(l10n.save));
            await tester.pumpAndSettle();

            expect(find.text(l10n.insufficientBalance), findsOneWidget);

            await tester.pumpAndSettle(const Duration(seconds: 3));
            await tester.pumpWidget(Container());
          }));

      testWidgets('Update existing transfer successfully',
              (tester) => tester.runAsync(() async {
            // Create a transfer record
            final companion = TransfersCompanion.insert(
              date: dateTimeToInt(DateTime(2025, 1, 1)),
              shares: 5,
              costBasis: const Value(1.0),
              value: 5.0,
              assetId: const Value(1),
              sendingAccountId: sendingAccountId,
              receivingAccountId: receivingAccountId,
            );
            final id = await db.into(db.transfers).insert(companion);

            final transfer = Transfer(
              id: id,
              date: 20250101,
              shares: 5,
              costBasis: 1.0,
              value: 5.0,
              assetId: 1,
              sendingAccountId: sendingAccountId,
              receivingAccountId: receivingAccountId,
              notes: null,
              isGenerated: false,
            );

            await pumpWidget(tester, transfer: transfer);

            // Change shares to 3 and save
            await tester.enterText(
                find.byKey(const Key('shares_field')), '3');

            await tester.tap(find.text(l10n.save));
            await tester.pumpUntilNoLongerFound(find.byType(TransferForm));

            final updated = await db.transfersDao.getTransfer(id);
            expect(updated.shares, 3);

            await tester.pumpWidget(Container());
          }));
    });
  });
}