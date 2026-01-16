import 'package:drift/drift.dart';
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
import 'package:xfin/screens/assets_screen.dart';
import 'package:xfin/widgets/asset_form.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late BaseCurrencyProvider currencyProvider;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  // Helper to pump AssetsScreen wrapped with required providers + localization.
  Future<AppLocalizations> pumpWidget(WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<DatabaseProvider>.value(value: DatabaseProvider.instance),
          ChangeNotifierProvider<BaseCurrencyProvider>.value(
              value: currencyProvider),
        ],
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [Locale('en'), Locale('de')],
          home: AssetsScreen(),
        ),
      ),
    );

    // Return localization obtained from the rendered screen so tests can use localized strings.
    return AppLocalizations.of(tester.element(find.byType(AssetsScreen)))!;
  }

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    DatabaseProvider.instance.initialize(db);
    currencyProvider = BaseCurrencyProvider();
    await currencyProvider.initialize(const Locale('en'));

    // Insert base currency (id = 1) used throughout the app.
    await db.into(db.assets).insert(AssetsCompanion.insert(
          name: 'EUR',
          type: AssetTypes.fiat,
          tickerSymbol: 'EUR',
        ));
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets(
      'displays asset items and trailing type uppercase',
      (tester) => tester.runAsync(() async {
            // Insert a couple of assets with different properties
            const a2 = Asset(
              id: 2,
              name: 'ZeroShares',
              type: AssetTypes.stock,
              tickerSymbol: 'ZSH',
              currencySymbol: '',
              value: 0.0,
              shares: 0.0,
              netCostBasis: 1.0,
              brokerCostBasis: 1.0,
              buyFeeTotal: 0.0,
              isArchived: false,
            );

            const a3 = Asset(
              id: 3,
              name: 'EqualCosts',
              type: AssetTypes.crypto,
              tickerSymbol: 'EQT',
              currencySymbol: '',
              value: 50.0,
              shares: 5.0,
              netCostBasis: 10.0,
              brokerCostBasis: 10.005,
              // diff < 0.01 -> should show single costBasis
              buyFeeTotal: 0.0,
              isArchived: false,
            );

            const a4 = Asset(
              id: 4,
              name: 'DifferentCosts',
              type: AssetTypes.etf,
              tickerSymbol: 'DIF',
              currencySymbol: '',
              value: 300.0,
              shares: 10.0,
              netCostBasis: 28.0,
              brokerCostBasis: 30.0,
              // diff >= 0.01 -> show both net and broker
              buyFeeTotal: 0.0,
              isArchived: false,
            );

            await db.into(db.assets).insert(a2.toCompanion(false));
            await db.into(db.assets).insert(a3.toCompanion(false));
            await db.into(db.assets).insert(a4.toCompanion(false));

            await pumpWidget(tester);
            await tester.pumpAndSettle();

            // Each name present
            expect(find.text('ZeroShares'), findsOneWidget);
            expect(find.text('EqualCosts'), findsOneWidget);
            expect(find.text('DifferentCosts'), findsOneWidget);

            // Trailing type labels uppercase
            expect(
                find.text(AssetTypes.stock.name.toUpperCase()), findsOneWidget);
            expect(find.text(AssetTypes.crypto.name.toUpperCase()),
                findsOneWidget);
            expect(
                find.text(AssetTypes.etf.name.toUpperCase()), findsOneWidget);

            // ZeroShares: shares displayed, cost lines should NOT be present because shares==0
            final l10n =
                AppLocalizations.of(tester.element(find.byType(AssetsScreen)))!;
            expect(
                find.byWidgetPredicate((w) =>
                    w is Text &&
                    w.data != null &&
                    w.data!.contains('${l10n.shares}:')),
                findsAtLeastNWidgets(1)); // shares lines exist at least once

            expect(
                find.byWidgetPredicate((w) =>
                    w is Text &&
                    w.data != null &&
                    w.data!.contains('${l10n.costBasis}: 1')),
                findsOneWidget); // EqualCosts shows costBasis

            // EqualCosts should only show costBasis (single line) — net/broker should NOT be present
            expect(
                find.byWidgetPredicate((w) =>
                    w is Text &&
                    w.data != null &&
                    w.data!.contains('EqualCosts') &&
                    w.data!.contains(l10n.netCostBasis)),
                findsNothing);
            expect(
                find.byWidgetPredicate((w) =>
                    w is Text &&
                    w.data != null &&
                    w.data!.contains('EqualCosts') &&
                    w.data!.contains(l10n.brokerCostBasis)),
                findsNothing);

            // DifferentCosts should show both netCostBasis and brokerCostBasis
            expect(
                find.byWidgetPredicate((w) =>
                    w is Text &&
                    w.data != null &&
                    w.data!.contains(l10n.netCostBasis) &&
                    w.data!.contains('28')),
                findsOneWidget);
            expect(
                find.byWidgetPredicate((w) =>
                    w is Text &&
                    w.data != null &&
                    w.data!.contains(l10n.brokerCostBasis) &&
                    w.data!.contains('30')),
                findsOneWidget);

            await tester.pumpWidget(Container());
          }));

  testWidgets(
      'tapping FAB opens AssetForm modal',
      (tester) => tester.runAsync(() async {
            // Insert one non-base asset so the list is not empty (not strictly required)
            const a2 = Asset(
              id: 2,
              name: 'SomeAsset',
              type: AssetTypes.stock,
              tickerSymbol: 'SA',
              currencySymbol: '',
              value: 10.0,
              shares: 1.0,
              netCostBasis: 10.0,
              brokerCostBasis: 10.0,
              buyFeeTotal: 0.0,
              isArchived: false,
            );
            await db.into(db.assets).insert(a2.toCompanion(false));

            await pumpWidget(tester);
            await tester.pumpAndSettle();

            // The FAB built by buildFAB uses Key('fab'), so we can find and tap it.
            final fabFinder = find.byKey(const Key('fab'));
            expect(fabFinder, findsOneWidget);

            await tester.tap(fabFinder);
            await tester.pumpAndSettle();

            // AssetForm should be present in the bottom sheet
            expect(find.byType(AssetForm), findsOneWidget);

            await tester.pumpWidget(Container());
          }));

  group('long-press deletion flow', () {
    testWidgets(
        'base asset (id=1) long-press shows cannot-delete dialog',
        (tester) => tester.runAsync(() async {
              final l10n = await pumpWidget(tester);
              await tester.pumpAndSettle();

              // Base asset 'EUR' should be present
              expect(find.text('EUR'), findsOneWidget);

              // Long press the item
              final center = tester.getCenter(find.text('EUR'));
              TestGesture gesture = await tester.startGesture(center);
              await tester.pump();
              await Future.delayed(kLongPressTimeout);
              await gesture.up();
              await tester.pumpAndSettle();

              // Confirm cannot-delete dialog appears
              expect(find.text(l10n.cannotDeleteAsset), findsOneWidget);
              expect(find.text(l10n.assetHasReferences), findsOneWidget);

              // Dismiss with OK
              await tester.tap(find.text(l10n.ok));
              await tester.pumpAndSettle();

              // Still present
              expect(find.text('EUR'), findsOneWidget);

              await tester.pumpWidget(Container());
            }));

    testWidgets(
        'asset with trades or assets-on-accounts shows cannot-delete dialog',
        (tester) => tester.runAsync(() async {
              final l10n = await pumpWidget(tester);

              // create accounts required by trades foreign keys
              final acc1 = await db.into(db.accounts).insert(
                    AccountsCompanion.insert(
                        name: 'A1', type: AccountTypes.cash),
                  );
              final acc2 = await db.into(db.accounts).insert(
                    AccountsCompanion.insert(
                        name: 'A2', type: AccountTypes.cash),
                  );

              // Insert asset that will be referenced
              const asset = Asset(
                id: 5,
                name: 'ReferencedAsset',
                type: AssetTypes.stock,
                tickerSymbol: 'RFA',
                currencySymbol: '',
                value: 0.0,
                shares: 0.0,
                netCostBasis: 1.0,
                brokerCostBasis: 1.0,
                buyFeeTotal: 0.0,
                isArchived: false,
              );
              await db.into(db.assets).insert(asset.toCompanion(false));

              // Insert a trade referencing the asset (makes hasTrades true)
              await db.into(db.trades).insert(TradesCompanion.insert(
                    datetime: 20240101,
                    assetId: asset.id,
                    type: TradeTypes.buy,
                    sourceAccountId: acc1,
                    targetAccountId: acc2,
                    shares: 1.0,
                    costBasis: 1.0,
                    fee: const Value(0.0),
                    tax: const Value(0.0),
                    sourceAccountValueDelta: -1.0,
                    targetAccountValueDelta: 1.0,
                    profitAndLoss: const Value(0.0),
                    returnOnInvest: const Value(0.0),
                  ));

              await tester.pumpAndSettle();

              // Long press the asset tile
              expect(find.text('ReferencedAsset'), findsOneWidget);
              final center = tester.getCenter(find.text('ReferencedAsset'));
              TestGesture gesture = await tester.startGesture(center);
              await tester.pump();
              await Future.delayed(kLongPressTimeout);
              await gesture.up();
              await tester.pumpAndSettle();

              // Cannot-delete dialog should appear (ok button)
              expect(find.text(l10n.cannotDeleteAsset), findsOneWidget);
              expect(find.text(l10n.assetHasReferences), findsOneWidget);

              await tester.tap(find.text(l10n.ok));
              await tester.pumpAndSettle();

              // Now also test hasAssetsOnAccounts reference path:
              // insert assetsOnAccounts referencing a new asset and verify same dialog
              const asset2 = Asset(
                id: 6,
                name: 'Referenced2',
                type: AssetTypes.stock,
                tickerSymbol: 'RFA2',
                currencySymbol: '',
                value: 0.0,
                shares: 1.0,
                netCostBasis: 1.0,
                brokerCostBasis: 1.0,
                buyFeeTotal: 0.0,
                isArchived: false,
              );
              await db.into(db.assets).insert(asset2.toCompanion(false));
              await db
                  .into(db.assetsOnAccounts)
                  .insert(AssetsOnAccountsCompanion.insert(
                    accountId: acc1,
                    assetId: asset2.id,
                    shares: const Value(1.0),
                    value: const Value(1.0),
                  ));

              await tester.pumpAndSettle();

              // Long press Referenced2
              expect(find.text('Referenced2'), findsOneWidget);
              final center2 = tester.getCenter(find.text('Referenced2'));
              gesture = await tester.startGesture(center2);
              await tester.pump();
              await Future.delayed(kLongPressTimeout);
              await gesture.up();
              await tester.pumpAndSettle();

              expect(find.text(l10n.cannotDeleteAsset), findsOneWidget);
              expect(find.text(l10n.assetHasReferences), findsOneWidget);

              await tester.tap(find.text(l10n.ok));
              await tester.pumpAndSettle();

              await tester.pumpWidget(Container());
            }));

    testWidgets(
        'deletable asset shows delete dialog and is removed when confirmed',
        (tester) => tester.runAsync(() async {
              final l10n = await pumpWidget(tester);

              // Insert an asset with no references and id != 1
              const asset = Asset(
                id: 7,
                name: 'DeletableAsset',
                type: AssetTypes.stock,
                tickerSymbol: 'DEL',
                currencySymbol: '',
                value: 0.0,
                shares: 0.0,
                netCostBasis: 1.0,
                brokerCostBasis: 1.0,
                buyFeeTotal: 0.0,
                isArchived: false,
              );
              await db.into(db.assets).insert(asset.toCompanion(false));
              await tester.pumpAndSettle();

              // Long press -> should show delete dialog (cancel/confirm)
              final center = tester.getCenter(find.text('DeletableAsset'));
              TestGesture gesture = await tester.startGesture(center);
              await tester.pump();
              await Future.delayed(kLongPressTimeout);
              await gesture.up();
              await tester.pumpAndSettle();

              expect(find.text(l10n.deleteAsset), findsOneWidget);
              expect(find.text(l10n.deleteAssetConfirmation), findsOneWidget);

              // Cancel first -> still present
              await tester.tap(find.text(l10n.cancel));
              await tester.pumpAndSettle();
              expect(find.text('DeletableAsset'), findsOneWidget);

              // Trigger long press again and confirm deletion
              gesture = await tester.startGesture(center);
              await tester.pump();
              await Future.delayed(kLongPressTimeout);
              await gesture.up();
              await tester.pumpAndSettle();

              expect(find.text(l10n.deleteAsset), findsOneWidget);
              await tester.tap(find.text(l10n.delete));
              await tester.pumpAndSettle();
              await tester.pump();

              // Asset should be removed from the list
              expect(find.text('DeletableAsset'), findsNothing);

              await tester.pumpWidget(Container());
            }));
  });
}
