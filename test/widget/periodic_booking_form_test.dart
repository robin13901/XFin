import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:xfin/database/app_database.dart';
import 'package:xfin/database/tables.dart';
import 'package:xfin/l10n/app_localizations.dart';
import 'package:xfin/providers/database_provider.dart';
import 'package:xfin/utils/format.dart';
import 'package:xfin/utils/global_constants.dart';
import 'package:xfin/widgets/periodic_booking_form.dart';

void main() {
  late AppDatabase db;
  late AppLocalizations l10n;
  late List<Asset> preloadedAssets;
  late List<Account> preloadedAccounts;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    DatabaseProvider.instance.initialize(db);

    const locale = Locale('en');
    l10n = await AppLocalizations.delegate.load(locale);

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

    // Add a secondary asset for tests
    final otherAssetId = await db.into(db.assets).insert(const AssetsCompanion(
      name: Value('USD'),
      type: Value(AssetTypes.fiat),
      tickerSymbol: Value('USD'),
      value: Value(0),
      shares: Value(0),
      brokerCostBasis: Value(1),
      netCostBasis: Value(1),
      buyFeeTotal: Value(0),
    ));

    // Create two accounts
    final aid1 = await db.accountsDao.insert(const AccountsCompanion(
      name: Value('Account A'),
      balance: Value(100.0),
      initialBalance: Value(100.0),
      type: Value(AccountTypes.cash),
    ));
    final aid2 = await db.accountsDao.insert(const AccountsCompanion(
      name: Value('Account B'),
      balance: Value(200.0),
      initialBalance: Value(200.0),
      type: Value(AccountTypes.cash),
    ));

    preloadedAssets = [
      (await db.assetsDao.getAsset(1)),
      (await db.assetsDao.getAsset(otherAssetId)),
    ];
    preloadedAccounts = [
      (await db.accountsDao.getAccount(aid1)),
      (await db.accountsDao.getAccount(aid2)),
    ];
  });

  tearDown(() async {
    await db.close();
  });

  Finder dropdownByLabel(String label) {
    return find.byWidgetPredicate((w) {
      if (w is DropdownButtonFormField) {
        try {
          final dec = (w as dynamic).decoration as InputDecoration?;
          return dec != null && dec.labelText == label;
        } catch (_) {
          return false;
        }
      }
      return false;
    }, description: 'DropdownButtonFormField with label "$label"');
  }

  Future<void> pumpSheet(WidgetTester tester, {PeriodicBooking? pb}) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: ChangeNotifierProvider<DatabaseProvider>.value(
          value: DatabaseProvider.instance,
          child: Builder(
            builder: (context) {
              return Scaffold(
                body: Center(
                  child: ElevatedButton(
                    child: const Text('Show'),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (_) => ChangeNotifierProvider<DatabaseProvider>.value(
                          value: DatabaseProvider.instance,
                          child: PeriodicBookingForm(
                            periodicBooking: pb,
                            preloadedAssets: preloadedAssets,
                            preloadedAccounts: preloadedAccounts,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Show'));
    await tester.pumpAndSettle();
  }

  group('PeriodicBookingForm - initialization', () {
    testWidgets('initializes empty for a new periodic booking',
            (tester) async {
          await pumpSheet(tester);

          // Next execution date should show today's formatted date
          final nextMonthTxt = dateFormat.format(addMonths(DateTime.now(), 1));
          expect(find.text(nextMonthTxt), findsOneWidget);

          // Shares field exists (shares_field key used by FormFields)
          final shares = find.byKey(const Key('shares_field'));
          expect(shares, findsOneWidget);

          // Account dropdown should be present
          expect(dropdownByLabel(l10n.account), findsOneWidget);

          // Cycles dropdown should be present (label depends on FormFields; we search for DropdownButtonFormField presence)
          expect(find.byKey(const Key('cycles_dropdown')), findsWidgets);

          // Category autocomplete key exists
          final cat = find.byKey(const Key('category_field'));
          expect(cat, findsOneWidget);

          // Save button present
          expect(find.text(l10n.save), findsOneWidget);

          await tester.pumpWidget(Container());
        });

    testWidgets('initializes with existing periodic booking', (tester) async {
      // Insert a periodic booking into db to edit
      final id = await db.into(db.periodicBookings).insert(PeriodicBookingsCompanion.insert(
        nextExecutionDate: dateTimeToInt(DateTime(2024, 01, 01)),
        assetId: const Value(1),
        accountId: preloadedAccounts[0].id,
        shares: 10.0,
        value: 10.0,
        category: 'PB existing',
        cycle: const Value(Cycles.weekly),
      ));

      final pb = (await db.select(db.periodicBookings).get()).first.copyWith(id: id);

      await pumpSheet(tester, pb: pb);

      // Check date displays the stored date
      expect(find.text('01.01.2024'), findsOneWidget);

      // Shares and category shown
      expect(find.text('10.0'), findsOneWidget);
      expect(find.text('PB existing'), findsOneWidget);

      // Account dropdown initial value should equal account id
      final accDropdown = dropdownByLabel(l10n.account);
      expect(accDropdown, findsOneWidget);
      final accWidget = tester.widget<DropdownButtonFormField>(accDropdown);
      expect((accWidget as dynamic).initialValue, preloadedAccounts[0].id);

      await tester.pumpWidget(Container());
    });
  });

  group('PeriodicBookingForm - saving and monthly factor', () {
    testWidgets('creates a new periodic booking with correct monthlyAverageFactor',
            (tester) async {
          await pumpSheet(tester);

          // Fill shares
          final shares = find.byKey(const Key('shares_field'));
          await tester.enterText(shares, '20');

          // Fill category
          final catAuto = find.byKey(const Key('category_field'));
          final catInner = find.descendant(of: catAuto, matching: find.byType(TextFormField));
          await tester.enterText(catInner, 'Salary');

          // Select account
          final acc = dropdownByLabel(l10n.account);
          await tester.tap(acc);
          await tester.pumpAndSettle();
          // choose the first account text
          await tester.tap(find.text(preloadedAccounts[0].name).last);
          await tester.pumpAndSettle();

          // Save
          await tester.tap(find.text(l10n.save));
          await tester.pumpAndSettle();

          final all = await db.select(db.periodicBookings).get();
          expect(all.length, 1);
          final saved = all.first;
          // Default cycle is monthly -> monthlyAverageFactor == 1.0
          expect(saved.monthlyAverageFactor, 1.0);
          expect(saved.category, 'Salary');

          await tester.pumpWidget(Container());
        });

    testWidgets('editing preserves id and updates monthlyAverageFactor for cycles',
            (tester) async {
          // Insert different pb entries with each cycle so we can edit and verify factor logic
          final now = DateTime.now();
          final cyclesToExpect = {
            Cycles.daily: 30.436875,
            Cycles.weekly: 30.436875 / 7,
            Cycles.monthly: 1.0,
            Cycles.quarterly: 1.0 / 3.0,
            Cycles.yearly: 1.0 / 12.0,
          };

          for (final entry in cyclesToExpect.entries) {
            final cycle = entry.key;
            final expected = entry.value;

            final id = await db.into(db.periodicBookings).insert(PeriodicBookingsCompanion.insert(
              nextExecutionDate: dateTimeToInt(now),
              assetId: const Value(1),
              accountId: preloadedAccounts[0].id,
              shares: 5.0,
              value: 5.0,
              category: 'C${cycle.name}',
              cycle: Value(cycle),
              monthlyAverageFactor: Value(entry.value),
            ));

            final pb = (await db.select(db.periodicBookings).get()).firstWhere((p) => p.id == id);

            await pumpSheet(tester, pb: pb);

            // Change shares to force update
            final shares = find.byKey(const Key('shares_field'));
            await tester.enterText(shares, '10');

            // Save
            await tester.tap(find.text(l10n.save));
            await tester.pumpAndSettle();

            final updated = (await db.select(db.periodicBookings).get()).firstWhere((p) => p.id == id);
            // monthlyAverageFactor should equal expected
            // Allow a tiny delta for floating point (though these are exact constants)
            expect((updated.monthlyAverageFactor - expected).abs() < 1e-9, isTrue);

            await tester.pumpWidget(Container());
          }
        });

    testWidgets('shows info dialog when there are pending standing orders executed',
            (tester) async {
          // pre-insert a periodic booking with a past nextExecutionDate so executePending will find it
          final pastDate = DateTime.now().subtract(const Duration(days: 10));
          await db.into(db.periodicBookings).insert(PeriodicBookingsCompanion.insert(
            nextExecutionDate: dateTimeToInt(pastDate),
            assetId: const Value(1),
            accountId: preloadedAccounts[0].id,
            shares: 1.0,
            value: 1.0,
            category: 'PastPB',
          ));

          // Now open the form and create a new valid periodic booking
          await pumpSheet(tester);

          final shares = find.byKey(const Key('shares_field'));
          await tester.enterText(shares, '2');

          final catAuto = find.byKey(const Key('category_field'));
          final catInner = find.descendant(of: catAuto, matching: find.byType(TextFormField));
          await tester.enterText(catInner, 'NewPB');

          final acc = dropdownByLabel(l10n.account);
          await tester.tap(acc);
          await tester.pumpAndSettle();
          await tester.tap(find.text(preloadedAccounts[0].name).last);
          await tester.pumpAndSettle();

          await tester.tap(find.text(l10n.save));
          await tester.pumpAndSettle();

          // Because executePending should have executed the pre-inserted past PB, an info dialog is shown
          expect(find.text(l10n.standingOrdersExecuted), findsOneWidget);
          // and the localized nStandingOrdersExecuted should contain a number (we just look for the label text)
          expect(find.textContaining(l10n.nStandingOrdersExecuted(1).split(' ').first), findsWidgets);

          await tester.pumpWidget(Container());
        });
  });
}