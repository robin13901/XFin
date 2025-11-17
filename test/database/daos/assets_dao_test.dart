import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';

import 'package:xfin/database/app_database.dart';
import 'package:xfin/database/tables.dart';
import 'package:xfin/database/daos/assets_dao.dart';

void main() {
  late AppDatabase database;
  late AssetsDao assetsDao;

  // Setup a new in-memory database before each test
  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    assetsDao = database.assetsDao;
  });

  // Close the database after each test
  tearDown(() async {
    await database.close();
  });

  group('AssetsDao', () {
    test('watchAllAssets returns an empty stream initially', () async {
      final assets = await assetsDao.watchAllAssets().first;
      expect(assets, isEmpty);
    });

    test('addAsset inserts a new asset and watchAllAssets reflects it', () async {
      final newAsset = AssetsCompanion.insert(
        name: 'Test Asset',
        type: AssetTypes.stock,
        tickerSymbol: 'TEST',
        value: const Value(100.0),
        sharesOwned: const Value(10.0),
        netCostBasis: const Value(90.0),
        brokerCostBasis: const Value(8.0),
        buyFeeTotal: const Value(2.0),
      );
      await assetsDao.addAsset(newAsset);

      final assets = await assetsDao.watchAllAssets().first;
      expect(assets.length, 1);
      expect(assets.first.name, 'Test Asset');
      expect(assets.first.type, AssetTypes.stock);
      expect(assets.first.tickerSymbol, 'TEST');
      expect(assets.first.value, 100.0);
      expect(assets.first.sharesOwned, 10.0);
      expect(assets.first.netCostBasis, 90.0);
      expect(assets.first.brokerCostBasis, 8.0);
      expect(assets.first.buyFeeTotal, 2.0);
    });

    test('updateAsset updates an existing asset', () async {
      final assetToInsert = AssetsCompanion.insert(
        name: 'Original Asset',
        type: AssetTypes.stock,
        tickerSymbol: 'ORIG',
        value: const Value(50.0),
        sharesOwned: const Value(5.0),
        netCostBasis: const Value(40.0),
        brokerCostBasis: const Value(3.0),
        buyFeeTotal: const Value(1.0),
      );
      final id = await assetsDao.addAsset(assetToInsert);
      final originalAsset = (await assetsDao.getAsset(id));

      final updatedAsset = originalAsset.copyWith(
        name: 'Updated Asset',
        type: AssetTypes.crypto,
        tickerSymbol: 'UPDT',
        value: 150.0,
        sharesOwned: 15.0,
        netCostBasis: 130.0,
        brokerCostBasis: 10.0,
        buyFeeTotal: 5.0,
      );
      await assetsDao.updateAsset(updatedAsset);

      final assets = await assetsDao.watchAllAssets().first;
      expect(assets.length, 1);
      expect(assets.first.name, 'Updated Asset');
      expect(assets.first.type, AssetTypes.crypto);
      expect(assets.first.tickerSymbol, 'UPDT');
      expect(assets.first.value, 150.0);
      expect(assets.first.sharesOwned, 15.0);
      expect(assets.first.netCostBasis, 130.0);
      expect(assets.first.brokerCostBasis, 10.0);
      expect(assets.first.buyFeeTotal, 5.0);
    });

    test('deleteAsset deletes an asset', () async {
      final assetToInsert = AssetsCompanion.insert(
        name: 'Asset to Delete',
        type: AssetTypes.stock,
        tickerSymbol: 'DEL',
        value: const Value(1.0),
        sharesOwned: const Value(1.0),
        netCostBasis: const Value(1.0),
        brokerCostBasis: const Value(1.0),
        buyFeeTotal: const Value(1.0),
      );
      final id = await assetsDao.addAsset(assetToInsert);

      await assetsDao.deleteAsset(id);

      final assets = await assetsDao.watchAllAssets().first;
      expect(assets, isEmpty);
    });

    test('getAsset retrieves a single asset', () async {
      final assetToInsert = AssetsCompanion.insert(
        name: 'Unique Asset',
        type: AssetTypes.currency,
        tickerSymbol: 'UAS',
        value: const Value(99.0),
        sharesOwned: const Value(9.0),
        netCostBasis: const Value(89.0),
        brokerCostBasis: const Value(7.0),
        buyFeeTotal: const Value(3.0),
      );
      final id = await assetsDao.addAsset(assetToInsert);

      final retrievedAsset = await assetsDao.getAsset(id);
      expect(retrievedAsset.name, 'Unique Asset');
      expect(retrievedAsset.id, id);
    });

    test('hasTrades returns true if asset has trades', () async {
      final asset = AssetsCompanion.insert(
        name: 'Asset With Trades',
        type: AssetTypes.stock,
        tickerSymbol: 'AWT',
        value: const Value(100.0), 
        sharesOwned: const Value(10.0), 
        netCostBasis: const Value(1000.0), 
        brokerCostBasis: const Value(0.0), 
        buyFeeTotal: const Value(0.0),
      );
      final assetId = await assetsDao.addAsset(asset);
      final account = await database.into(database.accounts).insertReturning(
        AccountsCompanion.insert(
          name: 'Clearing Account',
          balance: 10000.0,
          initialBalance: 10000.0,
          type: AccountTypes.cash,
        ),
      );

      await database.into(database.trades).insert(TradesCompanion.insert(
        assetId: assetId,
        datetime: 20240101,
        type: TradeTypes.buy,
        clearingAccountValueDelta: -1001.0,
        portfolioAccountValueDelta: 1000.0,
        shares: 10.0,
        pricePerShare: 100.0,
        profitAndLossAbs: 0.0,
        profitAndLossRel: 0.0,
        tradingFee: -1.0,
        tax: 0.0,
        clearingAccountId: account.id,
        portfolioAccountId: account.id, // Using same for simplicity
      ));

      expect(await assetsDao.hasTrades(assetId), isTrue);
    });

    test('hasTrades returns false if asset has no trades', () async {
      final asset = AssetsCompanion.insert(
        name: 'Asset Without Trades',
        type: AssetTypes.stock,
        tickerSymbol: 'AWO',
        value: const Value(100.0), 
        sharesOwned: const Value(10.0), 
        netCostBasis: const Value(1000.0), 
        brokerCostBasis: const Value(0.0), 
        buyFeeTotal: const Value(0.0),
      );
      final assetId = await assetsDao.addAsset(asset);

      expect(await assetsDao.hasTrades(assetId), isFalse);
    });

    test('hasAssetsOnAccounts returns true if asset is on an account', () async {
      final asset = AssetsCompanion.insert(
        name: 'Asset On Account',
        type: AssetTypes.stock,
        tickerSymbol: 'AOA',
        value: const Value(100.0), 
        sharesOwned: const Value(10.0), 
        netCostBasis: const Value(1000.0), 
        brokerCostBasis: const Value(0.0), 
        buyFeeTotal: const Value(0.0),
      );
      final assetId = await assetsDao.addAsset(asset);
      
      final account = await database.into(database.accounts).insertReturning(
        AccountsCompanion.insert(
          name: 'Portfolio Account',
          balance: 0.0,
          initialBalance: 0.0,
          type: AccountTypes.portfolio,
        ),
      );

      await database.into(database.assetsOnAccounts).insert(AssetsOnAccountsCompanion.insert(
        assetId: assetId,
        accountId: account.id,
        value: 0.0,
        sharesOwned: 5.0,
        netCostBasis: 0.0,
        brokerCostBasis: 0.0,
        buyFeeTotal: 0.0,
      ));

      expect(await assetsDao.hasAssetsOnAccounts(assetId), isTrue);
    });

    test('hasAssetsOnAccounts returns false if asset is not on an account', () async {
      final asset = AssetsCompanion.insert(
        name: 'Asset Not On Account',
        type: AssetTypes.stock,
        tickerSymbol: 'ANOA',
        value: const Value(100.0), 
        sharesOwned: const Value(10.0), 
        netCostBasis: const Value(1000.0), 
        brokerCostBasis: const Value(0.0), 
        buyFeeTotal: const Value(0.0),
      );
      final assetId = await assetsDao.addAsset(asset);

      expect(await assetsDao.hasAssetsOnAccounts(assetId), isFalse);
    });
  });
}