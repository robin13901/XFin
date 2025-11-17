import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oktoast/oktoast.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xfin/database/app_database.dart';
import 'package:xfin/database/tables.dart';
import 'package:xfin/l10n/app_localizations.dart';
import 'package:xfin/providers/base_currency_provider.dart';
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
    return await appDatabase.accountsDao.createAccount(
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
    required String category,
    DateTime? date,
  }) async {
    final dateAsInt = date != null
        ? int.parse(date.toIso8601String().substring(0, 10).replaceAll('-', ''))
        : 20230101;
    final companion = BookingsCompanion(
        date: Value(dateAsInt),
        category: Value(category),
        amount: Value(amount),
        accountId: Value(accountId),
        isGenerated: const Value(false));
    await appDatabase.bookingsDao.createBooking(companion);
    return await (appDatabase.select(appDatabase.bookings)
          ..where((tbl) => tbl.category.equals(category)))
        .getSingle();
  }
}

void main() {
  late TestDatabase db;
  late AppLocalizations l10n;
  late BaseCurrencyProvider currencyProvider;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  setUp(() async {
    db = TestDatabase();
    const locale = Locale('en');
    l10n = await AppLocalizations.delegate.load(locale);
    currencyProvider = BaseCurrencyProvider();
    await currencyProvider.initialize(locale);

    // Create base currency asset
    await db.appDatabase.into(db.appDatabase.assets).insert(const AssetsCompanion(
        name: Value('EUR'),
        type: Value(AssetTypes.currency),
        tickerSymbol: Value('EUR'),
        value: Value(0),
        sharesOwned: Value(0),
        brokerCostBasis: Value(1),
        netCostBasis: Value(1),
        buyFeeTotal: Value(0)
    ));
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
              create: (_) => db.appDatabase,
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
                            value: db.appDatabase,
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

  Future<void> pumpWidgetWithToast(WidgetTester tester, {Booking? booking}) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<AppDatabase>.value(
            value: db.appDatabase,
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
      accountId1 = await db.appDatabase.accountsDao.createAccount(
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
                      .widget<TextFormField>(find.descendant(of: find.byKey(const Key('category_field')), matching: find.byType(TextFormField)))
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
                category: 'Existing Booking',
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

    testWidgets('category field shows autocomplete suggestions',
        (tester) => tester.runAsync(() async {
              await db.createBooking(
                  accountId: accountId1, amount: 10, category: 'Food');
              await db.createBooking(
                  accountId: accountId1, amount: 20, category: 'Transport');
              await db.createBooking(
                  accountId: accountId1, amount: 30, category: 'Food expenses');

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
                      .widget<TextFormField>(find.descendant(of: categoryField, matching: find.byType(TextFormField)))
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
                expect(find.text(l10n.pleaseEnterAValue), findsOneWidget);

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

      testWidgets('shows errors for invalid category',
          (tester) => tester.runAsync(() async {
                await pumpWidget(tester);

                await tester.tap(find.text(l10n.save));
                await tester.pumpAndSettle();
                expect(find.text(l10n.pleaseEnterACategory), findsOneWidget);

                await tester.enterText(
                    find.byKey(const Key('category_field')), 'Überweisung');
                await tester.tap(find.text(l10n.save));
                await tester.pumpAndSettle();
                expect(find.text(l10n.categoryReservedForTransfer), findsOneWidget);

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
                    find.byKey(const Key('category_field')), 'Groceries');
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

                // Dispose the widget to ensure streams are cancelled.
                await tester.pumpWidget(Container());
              }));

      testWidgets('Update existing booking successfully',
          (tester) => tester.runAsync(() async {
                final booking = await db.createBooking(
                    accountId: accountId1, amount: 50, category: 'Initial');

                await pumpWidget(tester, booking: booking);

                await tester.enterText(find.byKey(const Key('amount_field')), '-25');
                await tester.enterText(
                    find.byKey(const Key('category_field')), 'Updated');

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
                    category: 'Groceries',
                    date: DateTime.now());

                await pumpWidget(tester);

                await tester.enterText(find.byKey(const Key('amount_field')), '-20');
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

                final bookings =
                    await (db.appDatabase.select(db.appDatabase.bookings)).get();
                expect(bookings.length, 1);

                // Dispose the widget to ensure streams are cancelled.
                await tester.pumpWidget(Container());
              }));
    });
  });
}
