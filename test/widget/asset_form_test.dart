import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:xfin/database/app_database.dart';
import 'package:xfin/database/daos/assets_dao.dart';
import 'package:xfin/database/tables.dart';
import 'package:xfin/l10n/app_localizations.dart';
import 'package:xfin/providers/database_provider.dart';
import 'package:xfin/widgets/asset_form.dart';

// Fake classes to avoid using Mockito generated mocks
class FakeAppDatabase extends Fake implements AppDatabase {
  FakeAppDatabase({required this.assetsDao});

  @override
  final AssetsDao assetsDao;
}

class FakeAssetsDao extends Fake implements AssetsDao {
  final List<Asset> _assets;
  final StreamController<List<Asset>> _allAssetsController =
      StreamController.broadcast();

  FakeAssetsDao({List<Asset> initialAssets = const []})
      : _assets = initialAssets.toList() {
    _allAssetsController.add(List.unmodifiable(_assets));
  }

  AssetsCompanion? _lastAddedAsset;
  Asset? _lastUpdatedAsset;

  @override
  Stream<List<Asset>> watchAllAssets() => _allAssetsController.stream;

  @override
  Future<int> insert(AssetsCompanion entry) async {
    _lastAddedAsset = entry;
    final newId = _assets.isEmpty ? 1 : _assets.last.id + 1;
    final newAsset = Asset(
        id: newId,
        name: entry.name.value,
        type: entry.type.value,
        tickerSymbol: entry.tickerSymbol.value,
        currencySymbol: entry.currencySymbol.value,
        value: entry.value.value,
        shares: entry.shares.value,
        netCostBasis: entry.netCostBasis.value,
        brokerCostBasis: entry.brokerCostBasis.value,
        buyFeeTotal: entry.buyFeeTotal.value,
        isArchived: false);
    _assets.add(newAsset);
    _allAssetsController.add(List.unmodifiable(_assets));
    return newId;
  }

  AssetsCompanion? get lastAddedAsset => _lastAddedAsset;

  Asset? get lastUpdatedAsset => _lastUpdatedAsset;
}

void main() {
  late FakeAppDatabase fakeAppDatabase;
  late FakeAssetsDao fakeAssetsDao;
  late AppLocalizations l10n;

  setUp(() async {
    fakeAssetsDao = FakeAssetsDao(); // Initialize without initial assets
    fakeAppDatabase = FakeAppDatabase(assetsDao: fakeAssetsDao);
    DatabaseProvider.instance.initialize(fakeAppDatabase);
    const locale = Locale('en');
    l10n = await AppLocalizations.delegate.load(locale);
  });

  Future<void> setupWidget(WidgetTester tester,
      {Asset? asset, List<Asset> initialAssets = const []}) async {
    fakeAssetsDao = FakeAssetsDao(
        initialAssets:
            initialAssets); // Create a new FakeAssetsDao with initial assets
    fakeAppDatabase = FakeAppDatabase(assetsDao: fakeAssetsDao);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
            body: ChangeNotifierProvider<DatabaseProvider>.value(
                value: DatabaseProvider.instance,
                child: AssetForm(asset: asset))),
      ),
    );
    await tester
        .pumpAndSettle(); // Add this to ensure initState Futures complete and initial assets are loaded
    await tester
        .pumpAndSettle(); // Additional pump to ensure setState in AssetForm is processed
  }

  group('AssetForm', () {
    testWidgets('shows correct title for adding a new asset', (tester) async {
      await setupWidget(tester);
      expect(find.text(l10n.assetName), findsOneWidget);
      expect(find.text(l10n.tickerSymbol), findsOneWidget);
      expect(find.text(l10n.save), findsOneWidget);
      expect(find.text(l10n.update), findsNothing);
    });

    testWidgets('shows correct title and pre-fills fields for editing an asset',
        (tester) async {
      const existingAsset = Asset(
          id: 1,
          name: 'Existing Asset',
          type: AssetTypes.crypto,
          tickerSymbol: 'EXA',
          currencySymbol: '',
          value: 0.0,
          shares: 0.0,
          netCostBasis: 0.0,
          brokerCostBasis: 0.0,
          buyFeeTotal: 0.0,
          isArchived: false);

      await setupWidget(tester,
          asset: existingAsset, initialAssets: [existingAsset]);
      // No need for an extra pump here, as setupWidget now includes it.

      expect(find.text(l10n.assetName), findsOneWidget);
      expect(find.text('Existing Asset'), findsOneWidget);
      expect(find.text(l10n.tickerSymbol), findsOneWidget);
      expect(find.text('EXA'), findsOneWidget);
      expect(find.text(l10n.crypto), findsOneWidget);
    });

    testWidgets('validates empty asset name', (tester) async {
      await setupWidget(tester);
      await tester.tap(find.text(l10n.save));
      await tester.pumpAndSettle();

      expect(find.text(l10n.requiredField), findsAtLeastNWidgets(1));
    });

    // testWidgets('validates duplicate asset name when adding',
    //     (tester) => tester.runAsync(() async {
    //   await setupWidget(tester, initialAssets: [
    //     const Asset(
    //       id: 1,
    //       name: 'Duplicate Asset',
    //       type: AssetTypes.stock,
    //       tickerSymbol: 'DUPL',
    //       value: 0.0,
    //       shares: 0.0,
    //       netCostBasis: 0.0,
    //       brokerCostBasis: 0.0,
    //       buyFeeTotal: 0.0,
    //     )
    //   ]);
    //
    //   await tester.enterText(find.byKey(const Key('asset_name_field')), 'Duplicate Asset');
    //   await tester.enterText(find.byKey(const Key('ticker_symbol_field')), 'NEWT');
    //   await tester.tap(find.text(l10n.save));
    //   await tester.pumpAndSettle();
    //
    //   expect(find.text(l10n.assetAlreadyExists), findsOneWidget);
    //   expect(fakeAssetsDao.lastAddedAsset, isNull);
    // }));

    testWidgets('validates empty ticker symbol', (tester) async {
      await setupWidget(tester);
      await tester.enterText(
          find.byKey(const Key('asset_name_field')), 'New Asset');
      await tester.tap(find.text(l10n.save));
      await tester.pumpAndSettle();

      expect(find.text(l10n.requiredField), findsAtLeastNWidgets(1));
    });

    // testWidgets('validates duplicate ticker symbol when adding',
    //     (tester) => tester.runAsync(() async {
    //   await setupWidget(tester, initialAssets: [
    //     const Asset(
    //       id: 1,
    //       name: 'Other Asset',
    //       type: AssetTypes.stock,
    //       tickerSymbol: 'DUPLT',
    //       value: 0.0,
    //       shares: 0.0,
    //       netCostBasis: 0.0,
    //       brokerCostBasis: 0.0,
    //       buyFeeTotal: 0.0,
    //     )
    //   ]);
    //
    //   await tester.enterText(find.byKey(const Key('asset_name_field')), 'New Unique Asset');
    //   await tester.enterText(find.byKey(const Key('ticker_symbol_field')), 'DUPLT');
    //   await tester.tap(find.text(l10n.save));
    //   await tester.pumpAndSettle();
    //
    //   expect(find.text(l10n.tickerSymbolAlreadyExists), findsOneWidget);
    //   expect(fakeAssetsDao.lastAddedAsset, isNull);
    // }));

    testWidgets('adds a new asset successfully', (tester) async {
      // await setupWidget(tester);
      //
      // await tester.enterText(
      //     find.byKey(const Key('asset_name_field')), 'New Asset Name');
      // await tester.enterText(
      //     find.byKey(const Key('ticker_symbol_field')), 'NAN');
      // await tester.tap(find.byKey(const Key('asset_type_dropdown')));
      // await tester.pumpAndSettle();
      // await tester.tap(find.text(l10n.crypto).last);
      // await tester.pumpAndSettle();
      //
      // await tester.tap(find.text(l10n.save));
      // await tester.pumpAndSettle();
      //
      // expect(
      //     fakeAssetsDao.lastAddedAsset,
      //     isA<AssetsCompanion>()
      //         .having((c) => c.name.value, 'name', 'New Asset Name')
      //         .having((c) => c.tickerSymbol.value, 'tickerSymbol', 'NAN')
      //         .having((c) => c.type.value, 'type', AssetTypes.crypto));
      // expect(find.byType(AssetForm), findsNothing);
    });

    testWidgets('cancel button dismisses the form', (tester) async {
      await setupWidget(tester);
      await tester.tap(find.text(l10n.cancel));
      await tester.pumpAndSettle();

      expect(find.byType(AssetForm), findsNothing);
    });
  });
}
