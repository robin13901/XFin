import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:xfin/database/app_database.dart';
import 'package:xfin/database/tables.dart';
import 'package:xfin/database/daos/assets_dao.dart';
import 'package:xfin/l10n/app_localizations.dart';
import 'package:xfin/screens/assets_screen.dart';
import 'package:intl/intl.dart';

// Fake classes to avoid using Mockito generated mocks
class FakeAppDatabase extends Fake implements AppDatabase {
  FakeAppDatabase({required this.assetsDao});

  @override
  final AssetsDao assetsDao;
}

class FakeAssetsDao extends Fake implements AssetsDao {
  final StreamController<List<Asset>> _allAssetsController =
      StreamController.broadcast();
  bool _hasTradesValue = false;
  bool _hasAssetsOnAccountsValue = false;
  int? _deletedAssetId;
  int? _addedAssetId;

  void emitAllAssets(List<Asset> assets) => _allAssetsController.add(assets);
  void setHasTrades(bool value) => _hasTradesValue = value;
  void setHasAssetsOnAccounts(bool value) => _hasAssetsOnAccountsValue = value;
  int? get deletedAssetId => _deletedAssetId;
  int? get addedAssetId => _addedAssetId;

  @override
  Stream<List<Asset>> watchAllAssets() => _allAssetsController.stream;

  @override
  Future<bool> hasTrades(int assetId) async => _hasTradesValue;

  @override
  Future<bool> hasAssetsOnAccounts(int assetId) async =>
      _hasAssetsOnAccountsValue;

  @override
  Future<void> deleteAsset(int id) async {
    _deletedAssetId = id;
    // Simulate updating the stream after deletion if needed, or rely on specific test setup
  }

  @override
  Future<int> addAsset(AssetsCompanion entry) async {
    _addedAssetId = 1; // Simulate a new ID
    _allAssetsController.add([
      Asset(
        id: _addedAssetId!,
        name: entry.name.value,
        type: entry.type.value,
        tickerSymbol: entry.tickerSymbol.value,
        value: entry.value.value,
        sharesOwned: entry.sharesOwned.value,
        netCostBasis: entry.netCostBasis.value,
        brokerCostBasis: entry.brokerCostBasis.value,
        buyFeeTotal: entry.buyFeeTotal.value,
      )
    ]);
    return _addedAssetId!;
  }
}

void main() {
  late FakeAppDatabase fakeAppDatabase;
  late FakeAssetsDao fakeAssetsDao;

  setUp(() {
    fakeAssetsDao = FakeAssetsDao();
    fakeAppDatabase = FakeAppDatabase(assetsDao: fakeAssetsDao);
  });

  Future<AppLocalizations> setupWidget(WidgetTester tester) async {
    await tester.pumpWidget(
      Provider<AppDatabase>.value(
        value: fakeAppDatabase,
        child: const MaterialApp(
          locale: Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: AssetsScreen(),
        ),
      ),
    );
    return AppLocalizations.of(tester.element(find.byType(AssetsScreen)))!;
  }

  group('AssetsScreen', () {
    testWidgets('displays title', (tester) async {
      final l10n = await setupWidget(tester);
      expect(find.text(l10n.assets), findsOneWidget);
    });

    testWidgets('displays CircularProgressIndicator when loading',
        (tester) async {
      // Simulate loading by not emitting anything yet
      await setupWidget(tester);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      // Now emit an empty list to stop loading and settle
      fakeAssetsDao.emitAllAssets([]);
      await tester.pumpAndSettle();
    });

    testWidgets('displays error message when stream has error', (tester) async {
      final l10n = await setupWidget(tester);
      final exception = Exception('Test Error');
      fakeAssetsDao._allAssetsController.addError(exception);

      await tester.pumpAndSettle();

      expect(find.text(l10n.error(exception.toString())), findsOneWidget);
    });

    testWidgets('displays "No assets" message when assets list is empty',
        (tester) async {
      final l10n = await setupWidget(tester);
      fakeAssetsDao.emitAllAssets([]);
      await tester.pumpAndSettle();

      expect(find.text(l10n.noAssets), findsOneWidget);
    });

    testWidgets('displays a list of assets', (tester) async {
      final l10n = await setupWidget(tester);
      final assets = [
        const Asset(
          id: 1,
          name: 'AAPL Stock',
          type: AssetTypes.stock,
          tickerSymbol: 'AAPL',
          value: 150.75,
          sharesOwned: 10.5,
          netCostBasis: 1400.0,
          brokerCostBasis: 0.0,
          buyFeeTotal: 0.0,
        ),
        const Asset(
          id: 2,
          name: 'Bitcoin',
          type: AssetTypes.crypto,
          tickerSymbol: 'BTC',
          value: 30000.0,
          sharesOwned: 0.5,
          netCostBasis: 12000.0,
          brokerCostBasis: 0.0,
          buyFeeTotal: 0.0,
        ),
      ];
      fakeAssetsDao.emitAllAssets(assets);

      await tester.pumpAndSettle();

      expect(find.text('AAPL Stock'), findsOneWidget);
      expect(find.text('Bitcoin'), findsOneWidget);
      final currencyFormat =
          NumberFormat.currency(locale: 'de_DE', symbol: '€');
      expect(
          find.text('${l10n.value}: ${currencyFormat.format(150.75)}'), findsOneWidget);
      expect(find.text('${l10n.sharesOwned}: 10.50'), findsOneWidget);
      expect(find.text('${l10n.netCostBasis}: ${currencyFormat.format(1400.0)}'),
          findsOneWidget);
      expect(find.text(l10n.stock.toUpperCase()), findsOneWidget);
      expect(find.text(l10n.crypto.toUpperCase()), findsOneWidget);
    });

    testWidgets('tapping FloatingActionButton opens AssetForm', (tester) async {
      final l10n = await setupWidget(tester);
      fakeAssetsDao.emitAllAssets([]);
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.text(l10n.assetName), findsOneWidget);
      expect(find.text(l10n.save), findsOneWidget);
    });

    testWidgets(
        'long pressing an asset without references shows delete confirmation dialog',
        (tester) async {
      final l10n = await setupWidget(tester);
      const asset = Asset(
        id: 1,
        name: 'Asset to Delete',
        type: AssetTypes.stock,
        tickerSymbol: 'ATD',
        value: 1.0,
        sharesOwned: 1.0,
        netCostBasis: 1.0,
        brokerCostBasis: 0.0,
        buyFeeTotal: 0.0,
      );
      fakeAssetsDao.emitAllAssets([asset]);
      fakeAssetsDao.setHasTrades(false);
      fakeAssetsDao.setHasAssetsOnAccounts(false);

      await tester.pumpAndSettle();

      await tester.longPress(find.text('Asset to Delete'));
      await tester.pumpAndSettle();

      expect(find.text(l10n.deleteAsset), findsOneWidget);
      expect(find.text(l10n.confirmDeleteAsset), findsOneWidget);
      expect(find.text(l10n.cancel), findsOneWidget);
      expect(find.text(l10n.confirm), findsOneWidget);
    });

    testWidgets('long pressing an asset with trades shows info dialog',
        (tester) async {
      final l10n = await setupWidget(tester);
      const asset = Asset(
        id: 1,
        name: 'Asset With Trades',
        type: AssetTypes.stock,
        tickerSymbol: 'AWT',
        value: 1.0,
        sharesOwned: 1.0,
        netCostBasis: 1.0,
        brokerCostBasis: 0.0,
        buyFeeTotal: 0.0,
      );
      fakeAssetsDao.emitAllAssets([asset]);
      fakeAssetsDao.setHasTrades(true);
      fakeAssetsDao.setHasAssetsOnAccounts(false);

      await tester.pumpAndSettle();

      await tester.longPress(find.text('Asset With Trades'));
      await tester.pumpAndSettle();

      expect(find.text(l10n.cannotDeleteAsset), findsOneWidget);
      expect(find.text(l10n.assetHasReferences), findsOneWidget);
      expect(find.text(l10n.ok), findsOneWidget);
      expect(find.text(l10n.cancel), findsNothing);
    });

    testWidgets(
        'long pressing an asset with assets on accounts shows info dialog',
        (tester) async {
      final l10n = await setupWidget(tester);
      const asset = Asset(
        id: 1,
        name: 'Asset On Account',
        type: AssetTypes.stock,
        tickerSymbol: 'AOA',
        value: 1.0,
        sharesOwned: 1.0,
        netCostBasis: 1.0,
        brokerCostBasis: 0.0,
        buyFeeTotal: 0.0,
      );
      fakeAssetsDao.emitAllAssets([asset]);
      fakeAssetsDao.setHasTrades(false);
      fakeAssetsDao.setHasAssetsOnAccounts(true);

      await tester.pumpAndSettle();

      await tester.longPress(find.text('Asset On Account'));
      await tester.pumpAndSettle();

      expect(find.text(l10n.cannotDeleteAsset), findsOneWidget);
      expect(find.text(l10n.assetHasReferences), findsOneWidget);
      expect(find.text(l10n.ok), findsOneWidget);
      expect(find.text(l10n.cancel), findsNothing);
    });

    testWidgets('confirming deletion calls deleteAsset and dismisses dialog',
        (tester) async {
      final l10n = await setupWidget(tester);
      const asset = Asset(
        id: 1,
        name: 'Asset to Be Deleted',
        type: AssetTypes.stock,
        tickerSymbol: 'ATBD',
        value: 1.0,
        sharesOwned: 1.0,
        netCostBasis: 1.0,
        brokerCostBasis: 0.0,
        buyFeeTotal: 0.0,
      );
      fakeAssetsDao.emitAllAssets([asset]);
      fakeAssetsDao.setHasTrades(false);
      fakeAssetsDao.setHasAssetsOnAccounts(false);

      await tester.pumpAndSettle();

      await tester.longPress(find.text('Asset to Be Deleted'));
      await tester.pumpAndSettle();

      await tester.tap(find.text(l10n.confirm));
      await tester.pumpAndSettle();

      expect(fakeAssetsDao.deletedAssetId, 1);
      expect(find.text(l10n.deleteAsset), findsNothing); // Dialog should be dismissed
    });

    testWidgets('cancelling deletion dismisses dialog without deleting',
        (tester) async {
      final l10n = await setupWidget(tester);
      const asset = Asset(
        id: 1,
        name: 'Asset to Not Delete',
        type: AssetTypes.stock,
        tickerSymbol: 'ATND',
        value: 1.0,
        sharesOwned: 1.0,
        netCostBasis: 1.0,
        brokerCostBasis: 0.0,
        buyFeeTotal: 0.0,
      );
      fakeAssetsDao.emitAllAssets([asset]);
      fakeAssetsDao.setHasTrades(false);
      fakeAssetsDao.setHasAssetsOnAccounts(false);

      await tester.pumpAndSettle();

      await tester.longPress(find.text('Asset to Not Delete'));
      await tester.pumpAndSettle();

      await tester.tap(find.text(l10n.cancel));
      await tester.pumpAndSettle();

      expect(fakeAssetsDao.deletedAssetId, isNull);
      expect(find.text(l10n.deleteAsset), findsNothing); // Dialog should be dismissed
    });

    testWidgets('pressing OK on info dialog dismisses it', (tester) async {
      final l10n = await setupWidget(tester);
      const asset = Asset(
        id: 1,
        name: 'Asset With Trades',
        type: AssetTypes.stock,
        tickerSymbol: 'AWT',
        value: 1.0,
        sharesOwned: 1.0,
        netCostBasis: 1.0,
        brokerCostBasis: 0.0,
        buyFeeTotal: 0.0,
      );
      fakeAssetsDao.emitAllAssets([asset]);
      fakeAssetsDao.setHasTrades(true);

      await tester.pumpAndSettle();

      await tester.longPress(find.text('Asset With Trades'));
      await tester.pumpAndSettle();

      await tester.tap(find.text(l10n.ok));
      await tester.pumpAndSettle();

      expect(find.text(l10n.cannotDeleteAsset), findsNothing); // Dialog should be dismissed
    });
  });
}
