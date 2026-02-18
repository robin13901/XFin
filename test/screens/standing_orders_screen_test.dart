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
import 'package:xfin/screens/standing_orders_screen.dart';
import 'package:xfin/utils/format.dart';
import 'package:xfin/widgets/periodic_booking_form.dart';
import 'package:xfin/widgets/periodic_transfer_form.dart';

void main() {
  late AppDatabase db;
  late AppLocalizations l10n;
  late List<Asset> assets;
  late List<Account> accounts;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    DatabaseProvider.instance.initialize(db);

    const locale = Locale('en');
    l10n = await AppLocalizations.delegate.load(locale);

    // Insert base currency asset (id = 1)
    final baseId = await db.into(db.assets).insert(const AssetsCompanion(
          name: Value('EUR'),
          type: Value(AssetTypes.fiat),
          tickerSymbol: Value('EUR'),
          value: Value(0),
          shares: Value(0),
          brokerCostBasis: Value(1),
          netCostBasis: Value(1),
          buyFeeTotal: Value(0),
        ));

    // Insert second asset
    final otherId = await db.into(db.assets).insert(const AssetsCompanion(
          name: Value('USD'),
          type: Value(AssetTypes.fiat),
          tickerSymbol: Value('USD'),
          value: Value(0),
          shares: Value(0),
          brokerCostBasis: Value(1),
          netCostBasis: Value(1),
          buyFeeTotal: Value(0),
          currencySymbol: Value('\$'),
        ));

    final a1 = await db.accountsDao.insert(const AccountsCompanion(
      name: Value('Account A'),
      balance: Value(100.0),
      initialBalance: Value(100.0),
      type: Value(AccountTypes.cash),
    ));
    final a2 = await db.accountsDao.insert(const AccountsCompanion(
      name: Value('Account B'),
      balance: Value(200.0),
      initialBalance: Value(200.0),
      type: Value(AccountTypes.cash),
    ));

    assets = [
      (await db.assetsDao.getAsset(baseId)),
      (await db.assetsDao.getAsset(otherId)),
    ];

    accounts = [
      (await db.accountsDao.getAccount(a1)),
      (await db.accountsDao.getAccount(a2)),
    ];
  });

  tearDown(() async {
    await db.close();
  });

  Future<AppLocalizations> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<DatabaseProvider>.value(
        value: DatabaseProvider.instance,
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: StandingOrdersScreen(),
        ),
      ),
    );

    // IMPORTANT:
    // Do NOT call pumpAndSettle here.
    // Just pump one frame so initState runs.
    await tester.pump();

    return AppLocalizations.of(
      tester.element(find.byType(StandingOrdersScreen)),
    )!;
  }

  testWidgets('shows empty messages when no periodic bookings/transfers exist',
      (tester) async {
    await pumpScreen(tester);

    // Initially on bookings tab (index 0)
    expect(find.text(l10n.noPeriodicBookingsYet), findsOneWidget);

    // Switch to transfers via nav key (the LiquidGlassBottomNav exposes keys on its children)
    final transfersNavKey = find.byKey(const Key('nav_periodic_transfers'));
    expect(transfersNavKey, findsOneWidget);
    await tester.tap(transfersNavKey);
    await tester.pumpAndSettle();
    expect(find.text(l10n.noPeriodicTransfersYet), findsOneWidget);

    await tester.pumpWidget(Container());
    await tester.pumpAndSettle();
  });

  testWidgets(
      'displays periodic bookings with base asset and other asset formatting, and opens booking form on tap',
      (tester) async {
    // Insert two periodic bookings:
    // 1) assetId = 1 (base) -> trailing shows only formatted currency
    // 2) assetId = other -> trailing shows shares + ≈ + formatted currency
    final now = DateTime.now();
    await db.into(db.periodicBookings).insert(PeriodicBookingsCompanion.insert(
          nextExecutionDate: dateTimeToInt(now.add(const Duration(days: 1))),
          assetId: const Value(1),
          accountId: accounts[0].id,
          shares: 5.0,
          value: 50.0,
          category: 'PB Base',
        ));

    await db.into(db.periodicBookings).insert(PeriodicBookingsCompanion.insert(
          nextExecutionDate: dateTimeToInt(now.add(const Duration(days: 2))),
          assetId: Value(assets[1].id),
          accountId: accounts[1].id,
          shares: 2.5,
          value: 25.0,
          category: 'PB Other',
        ));

    await pumpScreen(tester);

    // Ensure both categories are visible
    expect(find.text('PB Base'), findsOneWidget);
    expect(find.text('PB Other'), findsOneWidget);

    // Check formatted currency presence for pb1 (base asset)
    expect(find.text(formatCurrency(50.0)), findsOneWidget);

    // For pb2 there should be text containing shares and ticker (USD) and approximate sign
    expect(
        find.textContaining(
            '2.5 ${assets[1].currencySymbol ?? assets[1].tickerSymbol}'),
        findsOneWidget);
    expect(find.textContaining(formatCurrency(25.0)), findsOneWidget);

    // Tap the PB Other list tile: should open PeriodicBookingForm in a modal sheet
    final pbOtherTile = find.widgetWithText(ListTile, 'PB Other');
    expect(pbOtherTile, findsOneWidget);
    await tester.tap(pbOtherTile);
    await tester.pumpAndSettle();

    // The PeriodicBookingForm should be present inside the bottom sheet
    expect(find.byType(PeriodicBookingForm), findsOneWidget);

    // Close sheet
    await tester.tap(find.widgetWithText(TextButton, l10n.cancel));

    await tester.pumpWidget(Container());
    await tester.pumpAndSettle();
  });

  testWidgets(
      'displays periodic transfers and opens transfer form on tap, long press shows delete dialog',
      (tester) async {
    // Insert a periodic transfer
    final now = DateTime.now();
    await db
        .into(db.periodicTransfers)
        .insert(PeriodicTransfersCompanion.insert(
          nextExecutionDate: dateTimeToInt(now.add(const Duration(days: 1))),
          assetId: const Value(1),
          sendingAccountId: accounts[0].id,
          receivingAccountId: accounts[1].id,
          shares: 1.0,
          value: 10.0,
          notes: const Value('PT Note'),
        ));

    await pumpScreen(tester);

    // Switch to transfers tab
    final transfersNavKey = find.byKey(const Key('nav_periodic_transfers'));
    await tester.tap(transfersNavKey);
    await tester.pumpAndSettle();

    // The transfer list should show an entry labeled "Account A -> Account B"
    expect(find.text('${accounts[0].name} -> ${accounts[1].name}'),
        findsOneWidget);
    expect(find.text(formatCurrency(10.0)), findsOneWidget);

    // Tap the list tile to open PeriodicTransferForm
    final tile = find.widgetWithText(
        ListTile, '${accounts[0].name} -> ${accounts[1].name}');
    expect(tile, findsOneWidget);
    await tester.tap(tile);
    await tester.pumpAndSettle();

    expect(find.byType(PeriodicTransferForm), findsOneWidget);

    // Close sheet
    await tester.tap(find.widgetWithText(TextButton, l10n.cancel));
    await tester.pumpAndSettle();

    // Long press to show delete confirmation dialog
    await tester.longPress(tile);
    await tester.pumpAndSettle();

    // Expect an AlertDialog (delete dialog) to appear
    expect(find.byType(AlertDialog), findsOneWidget);

    // Close dialog by tapping the cancel/close area: press the default dialog action if present, otherwise tap barrier
    // Try to find typical localized cancel text (best-effort)
    final cancelFinder = find.text(l10n.cancel);
    if (cancelFinder.evaluate().isNotEmpty) {
      await tester.tap(cancelFinder);
    } else {
      await tester.tap(find.widgetWithText(TextButton, l10n.cancel));
    }

    await tester.pumpWidget(Container());
    await tester.pumpAndSettle();
  });

  testWidgets(
      'bottom nav right-add button opens booking form on bookings tab and transfer form on transfers tab',
      (tester) async {
    await pumpScreen(tester);

    // Initially on bookings tab (index 0). Tap the add icon
    final addIcon = find.byIcon(Icons.add);
    expect(addIcon, findsOneWidget);
    await tester.tap(addIcon);
    await tester.pumpAndSettle();

    // Booking form should open
    expect(find.byType(PeriodicBookingForm), findsOneWidget);

    // Close
    await tester.tap(find.widgetWithText(TextButton, l10n.cancel));
    await tester.pumpAndSettle();

    // Switch to transfers
    final transfersNavKey = find.byKey(const Key('nav_periodic_transfers'));
    await tester.tap(transfersNavKey);
    await tester.pumpAndSettle();

    // Tap add icon again
    await tester.tap(addIcon);
    await tester.pumpAndSettle();

    // Transfer form should open
    expect(find.byType(PeriodicTransferForm), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, l10n.cancel));

    await tester.pumpWidget(Container());
    await tester.pumpAndSettle();
  });
}
