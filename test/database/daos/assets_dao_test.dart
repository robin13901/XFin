import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';

import 'package:xfin/database/app_database.dart';
import 'package:xfin/database/tables.dart';
import 'package:xfin/database/daos/assets_dao.dart';

void main() {
  late AppDatabase db;
  late AssetsDao assetsDao;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    assetsDao = db.assetsDao;
  });

  tearDown(() async {
    await db.close();
  });

  group('AssetsDao', () {
    test('watchAllAssets returns an empty stream initially', () async {
      final assets = await assetsDao.watchAllAssets().first;
      expect(assets, isEmpty);
    });

    test('"insert" inserts a new asset and watchAllAssets reflects it',
        () async {
      final newAsset = AssetsCompanion.insert(
        name: 'Test Asset',
        type: AssetTypes.stock,
        tickerSymbol: 'TEST',
        value: const Value(100.0),
        shares: const Value(10.0),
        netCostBasis: const Value(90.0),
        brokerCostBasis: const Value(8.0),
        buyFeeTotal: const Value(2.0),
      );
      await assetsDao.insert(newAsset);

      final assets = await assetsDao.watchAllAssets().first;
      expect(assets.length, 1);
      expect(assets.first.name, 'Test Asset');
      expect(assets.first.type, AssetTypes.stock);
      expect(assets.first.tickerSymbol, 'TEST');
      expect(assets.first.value, 100.0);
      expect(assets.first.shares, 10.0);
      expect(assets.first.netCostBasis, 90.0);
      expect(assets.first.brokerCostBasis, 8.0);
      expect(assets.first.buyFeeTotal, 2.0);
    });

    test('deleteAsset deletes an asset', () async {
      final id = await assetsDao.insert(AssetsCompanion.insert(
        name: 'Asset to Delete',
        type: AssetTypes.stock,
        tickerSymbol: 'DEL',
        value: const Value(1.0),
        shares: const Value(1.0),
        netCostBasis: const Value(1.0),
        brokerCostBasis: const Value(1.0),
        buyFeeTotal: const Value(1.0),
      ));

      await assetsDao.deleteAsset(id);

      final assets = await assetsDao.watchAllAssets().first;
      expect(assets, isEmpty);
    });

    test('getAsset retrieves a single asset', () async {
      final assetToInsert = AssetsCompanion.insert(
        name: 'Unique Asset',
        type: AssetTypes.fiat,
        tickerSymbol: 'UAS',
        value: const Value(99.0),
        shares: const Value(9.0),
        netCostBasis: const Value(89.0),
        brokerCostBasis: const Value(7.0),
        buyFeeTotal: const Value(3.0),
      );
      final id = await assetsDao.insert(assetToInsert);

      final retrievedAsset = await assetsDao.getAsset(id);
      expect(retrievedAsset.name, 'Unique Asset');
      expect(retrievedAsset.id, id);
    });

    test('getAssetByTickerSymbol', () async {
      final assetToInsert = AssetsCompanion.insert(
        name: 'Unique Asset',
        type: AssetTypes.fiat,
        tickerSymbol: 'UAS',
        value: const Value(99.0),
        shares: const Value(9.0),
        netCostBasis: const Value(89.0),
        brokerCostBasis: const Value(7.0),
        buyFeeTotal: const Value(3.0),
      );
      final id = await assetsDao.insert(assetToInsert);

      final retrievedAsset = await assetsDao.getAssetByTickerSymbol('UAS');
      expect(retrievedAsset.name, 'Unique Asset');
      expect(retrievedAsset.id, id);
    });

    test('hasTrades returns true if asset has trades', () async {
      final asset = AssetsCompanion.insert(
        name: 'Asset With Trades',
        type: AssetTypes.stock,
        tickerSymbol: 'AWT',
        value: const Value(100.0),
        shares: const Value(10.0),
        netCostBasis: const Value(1000.0),
        brokerCostBasis: const Value(0.0),
        buyFeeTotal: const Value(0.0),
      );
      final assetId = await assetsDao.insert(asset);
      final account = await db.into(db.accounts).insertReturning(
            AccountsCompanion.insert(
              name: 'Source Account',
              balance: const Value(1000.0),
              initialBalance: const Value(1000.0),
              type: AccountTypes.cash,
            ),
          );

      await db.into(db.trades).insert(TradesCompanion.insert(
            assetId: assetId,
            datetime: 20240101,
            type: TradeTypes.buy,
            sourceAccountValueDelta: -1001.0,
            targetAccountValueDelta: 1000.0,
            shares: 10.0,
            costBasis: 100.0,
            sourceAccountId: account.id,
            targetAccountId: account.id, // Using same for simplicity
          ));

      expect(await assetsDao.hasTrades(assetId), isTrue);
    });

    test('hasTrades returns false if asset has no trades', () async {
      final asset = AssetsCompanion.insert(
        name: 'Asset Without Trades',
        type: AssetTypes.stock,
        tickerSymbol: 'AWO',
        value: const Value(100.0),
        shares: const Value(10.0),
        netCostBasis: const Value(1000.0),
        brokerCostBasis: const Value(0.0),
        buyFeeTotal: const Value(0.0),
      );
      final assetId = await assetsDao.insert(asset);

      expect(await assetsDao.hasTrades(assetId), isFalse);
    });

    test('hasAssetsOnAccounts returns true if asset is on an account',
        () async {
      final asset = AssetsCompanion.insert(
        name: 'Asset On Account',
        type: AssetTypes.stock,
        tickerSymbol: 'AOA',
        value: const Value(100.0),
        shares: const Value(10.0),
        netCostBasis: const Value(1000.0),
        brokerCostBasis: const Value(0.0),
        buyFeeTotal: const Value(0.0),
      );
      final assetId = await assetsDao.insert(asset);

      final account = await db.into(db.accounts).insertReturning(
            AccountsCompanion.insert(
              name: 'Target Account',
              type: AccountTypes.portfolio,
            ),
          );

      await db.into(db.assetsOnAccounts).insert(
          AssetsOnAccountsCompanion.insert(
              assetId: assetId, accountId: account.id, shares: const Value(0.00000001), value: const Value(0.5)));

      expect(await assetsDao.hasAssetsOnAccounts(assetId), isTrue);
    });

    test('hasAssetsOnAccounts returns false if asset is not on an account',
        () async {
      final asset = AssetsCompanion.insert(
        name: 'Asset Not On Account',
        type: AssetTypes.stock,
        tickerSymbol: 'ANOA',
        value: const Value(100.0),
        shares: const Value(10.0),
        netCostBasis: const Value(1000.0),
        brokerCostBasis: const Value(0.0),
        buyFeeTotal: const Value(0.0),
      );
      final assetId = await assetsDao.insert(asset);

      expect(await assetsDao.hasAssetsOnAccounts(assetId), isFalse);
    });
  });
}
