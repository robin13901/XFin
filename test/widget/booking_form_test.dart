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
import 'package:xfin/widgets/booking_form.dart';

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

    // Create base currency asset
    await db.into(db.assets).insert(const AssetsCompanion(
        name: Value('EUR'),
        type: Value(AssetTypes.fiat),
        tickerSymbol: Value('EUR'),
        value: Value(0),
        shares: Value(0),
        brokerCostBasis: Value(1),
        netCostBasis: Value(1),
        buyFeeTotal: Value(0)));
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> pumpWidget(WidgetTester tester, {Booking? booking}) async {
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
            Provider<AppDatabase>(
              create: (_) => db,
            ),
            ChangeNotifierProvider<BaseCurrencyProvider>(
              create: (_) => currencyProvider,
            ),
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
                          Provider<AppDatabase>.value(
                            value: db,
                          ),
                          ChangeNotifierProvider<BaseCurrencyProvider>.value(
                            value: currencyProvider,
                          ),
                        ],
                        child: BookingForm(booking: booking),
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
      {Booking? booking}) async {
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
      accountId1 = await db.accountsDao.insert(
        const AccountsCompanion(
          name: Value('Test Account'),
          balance: Value(100.0),
          initialBalance: Value(100.0),
          type: Value(AccountTypes.cash),
        ),
      );

      await db.into(db.assetsOnAccounts).insert(
          AssetsOnAccountsCompanion.insert(
              accountId: 1,
              assetId: 1,
              shares: const Value(100),
              value: const Value(100)));
    });

    testWidgets(
        'form initializes empty for new booking',
        (tester) => tester.runAsync(() async {
              await pumpWidget(tester);

              expect(find.byType(BookingForm), findsOneWidget);
              expect(find.text(l10n.save), findsOneWidget);
              expect(
                  tester
                      .widget<TextFormField>(
                          find.byKey(const Key('date_field')))
                      .controller!
                      .text,
                  DateFormat('dd.MM.yyyy').format(DateTime.now()));
              expect(
                  tester
                      .widget<DropdownButtonFormField>(
                          find.byKey(const Key('assets_dropdown')))
                      .initialValue,
                  1);
              expect(
                  tester
                      .widget<TextFormField>(
                          find.byKey(const Key('shares_field')))
                      .controller!
                      .text,
                  '');
              expect(
                  tester
                      .widget<TextFormField>(find.descendant(
                          of: find.byKey(const Key('category_field')),
                          matching: find.byType(TextFormField)))
                      .controller!
                      .text,
                  '');
              expect(
                  tester
                      .widget<DropdownButtonFormField>(
                          find.byKey(const Key('account_dropdown')))
                      .initialValue,
                  null);
              expect(
                  tester
                      .widget<CheckboxListTile>(
                          find.byKey(const Key('exclude_checkbox')))
                      .value,
                  isFalse);

              await tester.pumpWidget(Container());
            }));

    testWidgets(
        'form initializes with data for existing booking',
        (tester) => tester.runAsync(() async {
              final booking = Booking(
                id: 1,
                date: 20230501,
                category: 'Existing Booking',
                shares: -50.0,
                costBasis: 1,
                assetId: 1,
                value: -50,
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

              await tester.pumpWidget(Container());
            }));

    testWidgets(
        'category field shows autocomplete suggestions',
        (tester) => tester.runAsync(() async {
              await db.into(db.bookings).insert(BookingsCompanion.insert(
                  date: 20250101,
                  accountId: accountId1,
                  category: 'Food',
                  shares: 10,
                  value: 10));
              await db.into(db.bookings).insert(BookingsCompanion.insert(
                  date: 20250102,
                  accountId: accountId1,
                  category: 'Transport',
                  shares: 20,
                  value: 20));
              await db.into(db.bookings).insert(BookingsCompanion.insert(
                  date: 20250103,
                  accountId: accountId1,
                  category: 'Food expenses',
                  shares: 30,
                  value: 30));

              await pumpWidget(tester);

              final categoryField = find.byKey(const Key('category_field'));
              await tester.enterText(categoryField, 'F');
              await tester.pumpAndSettle();

              expect(find.text('Food'), findsOneWidget);
              expect(find.text('Food expenses'), findsOneWidget);
              expect(find.text('Transport'), findsNothing);

              await tester.tap(find.text('Food'));
              await tester.pumpAndSettle();

              expect(
                  tester
                      .widget<TextFormField>(find.descendant(
                          of: categoryField,
                          matching: find.byType(TextFormField)))
                      .controller!
                      .text,
                  'Food');

              await tester.pumpWidget(Container());
            }));

    group('Validation', () {
      testWidgets(
          'shows errors for invalid amount',
          (tester) => tester.runAsync(() async {
                await pumpWidget(tester);

                await tester.tap(find.text(l10n.save));
                await tester.pumpAndSettle();
                expect(find.text(l10n.requiredField), findsWidgets);

                await tester.enterText(
                    find.byKey(const Key('shares_field')), 'invalid');
                await tester.tap(find.text(l10n.save));
                await tester.pumpAndSettle();
                expect(find.text(l10n.invalidInput), findsOneWidget);

                await tester.enterText(
                    find.byKey(const Key('shares_field')), '1.234');
                await tester.tap(find.text(l10n.save));
                await tester.pumpAndSettle();
                expect(find.text(l10n.tooManyDecimalPlaces), findsOneWidget);

                await tester.pumpWidget(Container());
              }));

      testWidgets(
          'shows errors for invalid category',
          (tester) => tester.runAsync(() async {
                await pumpWidget(tester);

                await tester.tap(find.text(l10n.save));
                await tester.pumpAndSettle();
                expect(find.text(l10n.requiredField), findsWidgets);

                await tester.pumpWidget(Container());
              }));

      testWidgets(
          'shows error if account is not selected',
          (tester) => tester.runAsync(() async {
                await pumpWidget(tester);

                await tester.tap(find.text(l10n.save));
                await tester.pumpAndSettle();
                expect(find.text(l10n.pleaseSelectAnAccount), findsOneWidget);

                await tester.pumpWidget(Container());
              }));
    });

    group('Form Submission', () {
      testWidgets(
          'Create new booking successfully',
          (tester) => tester.runAsync(() async {
                await pumpWidget(tester);

                await tester.enterText(
                    find.byKey(const Key('shares_field')), '-50.50');
                await tester.enterText(
                    find.byKey(const Key('category_field')), 'Groceries');
                await tester.tap(find.byKey(const Key('account_dropdown')));
                await tester.pumpAndSettle();
                await tester.tap(find.text('Test Account').last);
                await tester.pumpAndSettle();

                await tester.tap(find.text(l10n.save));
                await tester.pumpAndSettle();

                final bookings = await (db.select(db.bookings)).get();
                expect(bookings.length, 1);

                await tester.pumpWidget(Container());
              }));

      testWidgets(
          'shows toast for insufficient balance',
          (tester) => tester.runAsync(() async {
                await pumpWidgetWithToast(tester);

                await tester.enterText(
                    find.byKey(const Key('shares_field')), '-150');
                await tester.enterText(
                    find.byKey(const Key('category_field')), 'Too Expensive');
                await tester.tap(find.byKey(const Key('account_dropdown')));
                await tester.pumpAndSettle();
                await tester.tap(find.text('Test Account').last);
                await tester.pumpAndSettle();

                await tester.tap(find.text(l10n.save));
                await tester.pumpAndSettle(); // Let toast appear

                expect(find.text(l10n.insufficientBalance), findsOneWidget);

                await tester.pumpAndSettle(
                    const Duration(seconds: 3)); // let toast disappear

                await tester.pumpWidget(Container());
              }));

      testWidgets(
          'Update existing booking successfully',
          (tester) => tester.runAsync(() async {
                Booking bookingWithoutId = Booking(
                    id: -1,
                    date: 20250101,
                    assetId: 1,
                    accountId: accountId1,
                    category: 'Initial',
                    shares: 50,
                    costBasis: 1,
                    value: 50,
                    excludeFromAverage: false,
                    isGenerated: false);
                final id = await db
                    .into(db.bookings)
                    .insert(bookingWithoutId.toCompanion(false));
                final booking = bookingWithoutId.copyWith(id: id);

                await pumpWidget(tester, booking: booking);

                await tester.enterText(
                    find.byKey(const Key('shares_field')), '-25');
                await tester.enterText(
                    find.byKey(const Key('category_field')), 'Updated');

                await tester.tap(find.text(l10n.save));
                await tester.pumpAndSettle();

                final updatedBooking =
                    await db.bookingsDao.getBooking(booking.id);
                expect(updatedBooking.shares, -25);

                await tester.pumpWidget(Container());
              }));

      testWidgets(
          'Merge dialog appears and merge is successful',
          (tester) => tester.runAsync(() async {
                await db.into(db.bookings).insert(BookingsCompanion.insert(
                    date: dateTimeToInt(DateTime.now()),
                    accountId: accountId1,
                    category: 'Groceries',
                    shares: -30,
                    value: -30));

                await pumpWidget(tester);

                await tester.enterText(
                    find.byKey(const Key('shares_field')), '-20');
                await tester.enterText(
                    find.byKey(const Key('category_field')), 'Groceries');
                await tester.tap(find.byKey(const Key('account_dropdown')));
                await tester.pumpAndSettle();
                await tester.tap(find.text('Test Account').last);
                await tester.pumpAndSettle();

                await tester.tap(find.text(l10n.save));
                await tester.pumpAndSettle();

                expect(find.text(l10n.mergeBookings), findsOneWidget);

                await tester.tap(find.text(l10n.merge));
                await tester.pumpAndSettle();

                final bookings = await (db.select(db.bookings)).get();
                expect(bookings.length, 1);
                expect(bookings[0].shares, -50);
                expect(bookings[0].costBasis, 1);
                expect(bookings[0].value, -50);

                await tester.pumpWidget(Container());
              }));
    });
  });
}
