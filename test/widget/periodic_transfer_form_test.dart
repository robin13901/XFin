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
import 'package:xfin/widgets/periodic_transfer_form.dart';

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

    // Base currency (id = 1)
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

    final otherAssetId = await db.into(db.assets).insert(const AssetsCompanion(
      name: Value('BTC'),
      type: Value(AssetTypes.crypto),
      tickerSymbol: Value('BTC'),
      value: Value(0),
      shares: Value(0),
      brokerCostBasis: Value(1),
      netCostBasis: Value(1),
      buyFeeTotal: Value(0),
    ));

    final a1 = await db.accountsDao.insert(const AccountsCompanion(
      name: Value('Sender'),
      balance: Value(500),
      initialBalance: Value(500),
      type: Value(AccountTypes.bankAccount),
    ));
    final a2 = await db.accountsDao.insert(const AccountsCompanion(
      name: Value('Receiver'),
      balance: Value(200),
      initialBalance: Value(200),
      type: Value(AccountTypes.bankAccount),
    ));

    preloadedAssets = [
      (await db.assetsDao.getAsset(1)),
      (await db.assetsDao.getAsset(otherAssetId)),
    ];

    preloadedAccounts = [
      (await db.accountsDao.getAccount(a1)),
      (await db.accountsDao.getAccount(a2)),
    ];
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> pumpSheet(WidgetTester tester, {PeriodicTransfer? pt}) async {
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
                          child: PeriodicTransferForm(
                            periodicTransfer: pt,
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

  group('PeriodicTransferForm - initialization & saving', () {
    testWidgets('initializes empty for new periodic transfer', (tester) async {
      await pumpSheet(tester);

      // Date field shows today
      final todayTxt = dateFormat.format(addMonths(DateTime.now(), 1));
      expect(find.text(todayTxt), findsOneWidget);

      // Sending/Receiving dropdowns present (keys used in widget)
      expect(find.byKey(const Key('sending_account_dropdown')), findsOneWidget);
      expect(find.byKey(const Key('receiving_account_dropdown')), findsOneWidget);

      // Shares/value field exists (shares_field key used by FormFields)
      expect(find.byKey(const Key('shares_field')), findsOneWidget);

      // Save button present
      expect(find.text(l10n.save), findsOneWidget);

      await tester.pumpWidget(Container());
    });

    testWidgets('creates a new periodic transfer and stores monthlyAverageFactor',
            (tester) async {
          await pumpSheet(tester);

          // Fill value
          final valField = find.byKey(const Key('shares_field'));
          await tester.enterText(valField, '123.45');

          // Choose sending account
          await tester.tap(find.byKey(const Key('sending_account_dropdown')));
          await tester.pumpAndSettle();
          await tester.tap(find.text(preloadedAccounts[0].name).last);
          await tester.pumpAndSettle();

          // Choose receiving account
          await tester.tap(find.byKey(const Key('receiving_account_dropdown')));
          await tester.pumpAndSettle();
          await tester.tap(find.text(preloadedAccounts[1].name).last);
          await tester.pumpAndSettle();

          // Choose asset other than base (open assets dropdown - uses assets_dropdown key from Reusables)
          final assetsDropdown = find.byKey(const Key('assets_dropdown'));
          expect(assetsDropdown, findsOneWidget);
          await tester.tap(assetsDropdown);
          await tester.pumpAndSettle();
          await tester.tap(find.text(preloadedAssets[1].name).last);
          await tester.pumpAndSettle();

          // Save
          await tester.tap(find.text(l10n.save));
          await tester.pumpAndSettle();

          final all = await db.select(db.periodicTransfers).get();
          expect(all.length, 1);
          final saved = all.first;

          // Default cycle monthly => monthlyAverageFactor == 1.0
          expect(saved.monthlyAverageFactor, 1.0);
          expect(saved.value, 123.45);
          expect(saved.sendingAccountId, preloadedAccounts[0].id);
          expect(saved.receivingAccountId, preloadedAccounts[1].id);

          await tester.pumpWidget(Container());
        });

    testWidgets('editing periodic transfer preserves id and updates factor for cycle',
            (tester) async {
          // Insert transfer with quarterly cycle
          final id = await db.into(db.periodicTransfers).insert(PeriodicTransfersCompanion.insert(
            nextExecutionDate: dateTimeToInt(addMonths(DateTime.now(), 1)),
            assetId: const Value(1),
            sendingAccountId: preloadedAccounts[0].id,
            receivingAccountId: preloadedAccounts[1].id,
            shares: 10.0,
            value: 10.0,
            notes: const Value('PT-edit'),
            cycle: const Value(Cycles.quarterly),
            monthlyAverageFactor: const Value(1.0 / 3.0),
          ));

          final pt = (await db.select(db.periodicTransfers).get()).firstWhere((p) => p.id == id);

          await pumpSheet(tester, pt: pt);

          // Change value
          final valField = find.byKey(const Key('shares_field'));
          await tester.enterText(valField, '20');

          // Save
          await tester.tap(find.text(l10n.save));
          await tester.pumpAndSettle();

          final updated = (await db.select(db.periodicTransfers).get()).firstWhere((p) => p.id == id);
          // quarterly -> monthlyAverageFactor = 1/3
          expect((updated.monthlyAverageFactor - (1.0 / 3.0)).abs() < 1e-9, isTrue);
          expect(updated.value, 20.0);

          await tester.pumpWidget(Container());
        });

    testWidgets('shows error dialog when sending and receiving accounts are the same',
            (tester) async {
          await pumpSheet(tester);

          // Fill value
          final valField = find.byKey(const Key('shares_field'));
          await tester.enterText(valField, '10');

          // Select same account for sending and receiving
          await tester.tap(find.byKey(const Key('sending_account_dropdown')));
          await tester.pumpAndSettle();
          await tester.tap(find.text(preloadedAccounts[0].name).last);
          await tester.pumpAndSettle();

          await tester.tap(find.byKey(const Key('receiving_account_dropdown')));
          await tester.pumpAndSettle();
          await tester.tap(find.text(preloadedAccounts[0].name).last);
          await tester.pumpAndSettle();

          // Save
          await tester.tap(find.text(l10n.save));
          await tester.pumpAndSettle();

          // Check that the specific localized error text is shown
          expect(find.text(l10n.sendingAndReceivingMustDiffer), findsOneWidget);

          await tester.pumpWidget(Container());
        });

    testWidgets('shows info dialog when executePending executed prior standing orders',
            (tester) async {
          // pre-insert a periodic transfer with a past nextExecutionDate to be executed
          final pastDate = DateTime.now().subtract(const Duration(days: 20));
          await db.into(db.periodicTransfers).insert(PeriodicTransfersCompanion.insert(
            nextExecutionDate: dateTimeToInt(pastDate),
            assetId: const Value(1),
            sendingAccountId: preloadedAccounts[0].id,
            receivingAccountId: preloadedAccounts[1].id,
            shares: 1.0,
            value: 1.0,
          ));

          await pumpSheet(tester);

          // fill new transfer
          final valField = find.byKey(const Key('shares_field'));
          await tester.enterText(valField, '5');

          await tester.tap(find.byKey(const Key('sending_account_dropdown')));
          await tester.pumpAndSettle();
          await tester.tap(find.text(preloadedAccounts[0].name).last);
          await tester.pumpAndSettle();

          await tester.tap(find.byKey(const Key('receiving_account_dropdown')));
          await tester.pumpAndSettle();
          await tester.tap(find.text(preloadedAccounts[1].name).last);
          await tester.pumpAndSettle();

          await tester.tap(find.text(l10n.save));
          await tester.pumpAndSettle();

          expect(find.text(l10n.standingOrdersExecuted), findsOneWidget);

          await tester.pumpWidget(Container());
        });
  });
}
