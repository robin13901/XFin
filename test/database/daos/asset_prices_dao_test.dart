import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xfin/database/app_database.dart';
import 'package:xfin/database/tables.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await db.into(db.assets).insert(AssetsCompanion.insert(
          name: 'EUR',
          type: AssetTypes.fiat,
          tickerSymbol: 'EUR',
        ));
    await db.into(db.assets).insert(AssetsCompanion.insert(
          name: 'Bitcoin',
          type: AssetTypes.crypto,
          tickerSymbol: 'BTC',
          apiIdentifier: const Value('bitcoin'),
        ));
    await db.into(db.assets).insert(AssetsCompanion.insert(
          name: 'Apple',
          type: AssetTypes.stock,
          tickerSymbol: 'AAPL',
        ));
  });

  tearDown(() => db.close());

  group('AssetPricesDao', () {
    test('insertPrice and getPrice', () async {
      await db.assetPricesDao.insertPrice(const AssetPricesCompanion(
        assetId: Value(2),
        date: Value(20260101),
        price: Value(42000.0),
      ));

      final price = await db.assetPricesDao.getPrice(2, 20260101);
      expect(price, isNotNull);
      expect(price!.price, 42000.0);
      expect(price.assetId, 2);
      expect(price.date, 20260101);
    });

    test('getPrice returns null for non-existent entry', () async {
      final price = await db.assetPricesDao.getPrice(2, 20260101);
      expect(price, isNull);
    });

    test('insertPrices batch inserts multiple prices', () async {
      await db.assetPricesDao.insertPrices([
        const AssetPricesCompanion(
          assetId: Value(2),
          date: Value(20260101),
          price: Value(42000.0),
        ),
        const AssetPricesCompanion(
          assetId: Value(2),
          date: Value(20260102),
          price: Value(43000.0),
        ),
        const AssetPricesCompanion(
          assetId: Value(2),
          date: Value(20260103),
          price: Value(41000.0),
        ),
      ]);

      final prices = await db.assetPricesDao.getPricesForRange(
          2, 20260101, 20260103);
      expect(prices.length, 3);
      expect(prices[0].price, 42000.0);
      expect(prices[1].price, 43000.0);
      expect(prices[2].price, 41000.0);
    });

    test('getPricesForRange filters by date range', () async {
      await db.assetPricesDao.insertPrices([
        const AssetPricesCompanion(
          assetId: Value(2),
          date: Value(20260101),
          price: Value(42000.0),
        ),
        const AssetPricesCompanion(
          assetId: Value(2),
          date: Value(20260105),
          price: Value(43000.0),
        ),
        const AssetPricesCompanion(
          assetId: Value(2),
          date: Value(20260110),
          price: Value(44000.0),
        ),
      ]);

      final prices = await db.assetPricesDao.getPricesForRange(
          2, 20260102, 20260109);
      expect(prices.length, 1);
      expect(prices[0].date, 20260105);
    });

    test('getLatestPriceDate returns max date', () async {
      await db.assetPricesDao.insertPrices([
        const AssetPricesCompanion(
          assetId: Value(2),
          date: Value(20260101),
          price: Value(42000.0),
        ),
        const AssetPricesCompanion(
          assetId: Value(2),
          date: Value(20260115),
          price: Value(43000.0),
        ),
      ]);

      final latest = await db.assetPricesDao.getLatestPriceDate(2);
      expect(latest, 20260115);
    });

    test('getLatestPriceDate returns null for no data', () async {
      final latest = await db.assetPricesDao.getLatestPriceDate(2);
      expect(latest, isNull);
    });

    test('getFirstAssetUsageDate from bookings', () async {
      await db.into(db.accounts).insert(AccountsCompanion.insert(
            name: 'Test',
            type: AccountTypes.bankAccount,
          ));
      await db.into(db.bookings).insert(BookingsCompanion.insert(
            date: 20250601,
            accountId: 1,
            assetId: const Value(2),
            category: 'Investment',
            shares: 0.5,
            value: 21000.0,
          ));
      await db.into(db.bookings).insert(BookingsCompanion.insert(
            date: 20251201,
            accountId: 1,
            assetId: const Value(2),
            category: 'Investment',
            shares: 0.3,
            value: 13000.0,
          ));

      final first = await db.assetPricesDao.getFirstAssetUsageDate(2);
      expect(first, 20250601);
    });

    test('getFirstAssetUsageDate returns null when no usage', () async {
      final first = await db.assetPricesDao.getFirstAssetUsageDate(3);
      expect(first, isNull);
    });

    test('getAssetsWithApiIdentifier returns only assets with identifier',
        () async {
      final assets = await db.assetPricesDao.getAssetsWithApiIdentifier();
      expect(assets.length, 1);
      expect(assets[0].name, 'Bitcoin');
      expect(assets[0].apiIdentifier, 'bitcoin');
    });

    test('getExistingPriceDates returns dates in range', () async {
      await db.assetPricesDao.insertPrices([
        const AssetPricesCompanion(
          assetId: Value(2),
          date: Value(20260101),
          price: Value(42000.0),
        ),
        const AssetPricesCompanion(
          assetId: Value(2),
          date: Value(20260103),
          price: Value(43000.0),
        ),
        const AssetPricesCompanion(
          assetId: Value(2),
          date: Value(20260105),
          price: Value(44000.0),
        ),
      ]);

      final dates =
          await db.assetPricesDao.getExistingPriceDates(2, 20260101, 20260105);
      expect(dates, {20260101, 20260103, 20260105});
    });

    test('getExistingPriceDates returns empty set when no data', () async {
      final dates =
          await db.assetPricesDao.getExistingPriceDates(2, 20260101, 20260110);
      expect(dates, isEmpty);
    });

    test('getExistingPriceDates filters by date range', () async {
      await db.assetPricesDao.insertPrices([
        const AssetPricesCompanion(
          assetId: Value(2),
          date: Value(20260101),
          price: Value(42000.0),
        ),
        const AssetPricesCompanion(
          assetId: Value(2),
          date: Value(20260110),
          price: Value(43000.0),
        ),
        const AssetPricesCompanion(
          assetId: Value(2),
          date: Value(20260120),
          price: Value(44000.0),
        ),
      ]);

      final dates =
          await db.assetPricesDao.getExistingPriceDates(2, 20260105, 20260115);
      expect(dates, {20260110});
    });

    test('getExistingPriceDates filters by asset id', () async {
      await db.assetPricesDao.insertPrices([
        const AssetPricesCompanion(
          assetId: Value(2),
          date: Value(20260101),
          price: Value(42000.0),
        ),
        const AssetPricesCompanion(
          assetId: Value(3),
          date: Value(20260101),
          price: Value(150.0),
        ),
      ]);

      final dates =
          await db.assetPricesDao.getExistingPriceDates(2, 20260101, 20260101);
      expect(dates, {20260101});
    });

    test('getLatestPriceOnOrBefore returns price for exact date', () async {
      await db.assetPricesDao.insertPrice(const AssetPricesCompanion(
        assetId: Value(2),
        date: Value(20260110),
        price: Value(42000.0),
      ));

      final price =
          await db.assetPricesDao.getLatestPriceOnOrBefore(2, 20260110);
      expect(price, 42000.0);
    });

    test('getLatestPriceOnOrBefore returns most recent earlier price',
        () async {
      await db.assetPricesDao.insertPrices([
        const AssetPricesCompanion(
          assetId: Value(2),
          date: Value(20260108),
          price: Value(41000.0),
        ),
        const AssetPricesCompanion(
          assetId: Value(2),
          date: Value(20260110),
          price: Value(42000.0),
        ),
      ]);

      final price =
          await db.assetPricesDao.getLatestPriceOnOrBefore(2, 20260112);
      expect(price, 42000.0);
    });

    test('getLatestPriceOnOrBefore returns null when no earlier price',
        () async {
      await db.assetPricesDao.insertPrice(const AssetPricesCompanion(
        assetId: Value(2),
        date: Value(20260110),
        price: Value(42000.0),
      ));

      final price =
          await db.assetPricesDao.getLatestPriceOnOrBefore(2, 20260105);
      expect(price, isNull);
    });

    test('getLatestPriceOnOrBefore filters by asset id', () async {
      await db.assetPricesDao.insertPrices([
        const AssetPricesCompanion(
          assetId: Value(2),
          date: Value(20260110),
          price: Value(42000.0),
        ),
        const AssetPricesCompanion(
          assetId: Value(3),
          date: Value(20260110),
          price: Value(150.0),
        ),
      ]);

      final price =
          await db.assetPricesDao.getLatestPriceOnOrBefore(3, 20260115);
      expect(price, 150.0);
    });

    test('getLatestPricePerAsset returns latest price for each asset',
        () async {
      await db.assetPricesDao.insertPrices([
        const AssetPricesCompanion(
          assetId: Value(2),
          date: Value(20260101),
          price: Value(40000.0),
        ),
        const AssetPricesCompanion(
          assetId: Value(2),
          date: Value(20260110),
          price: Value(42000.0),
        ),
        const AssetPricesCompanion(
          assetId: Value(3),
          date: Value(20260105),
          price: Value(150.0),
        ),
        const AssetPricesCompanion(
          assetId: Value(3),
          date: Value(20260108),
          price: Value(155.0),
        ),
      ]);

      final map = await db.assetPricesDao.getLatestPricePerAsset();
      expect(map.length, 2);
      expect(map[2], 42000.0);
      expect(map[3], 155.0);
    });

    test('getLatestPricePerAsset returns empty map when no prices', () async {
      final map = await db.assetPricesDao.getLatestPricePerAsset();
      expect(map, isEmpty);
    });

    test('deleteAllForAsset removes all prices for asset', () async {
      await db.assetPricesDao.insertPrices([
        const AssetPricesCompanion(
          assetId: Value(2),
          date: Value(20260101),
          price: Value(42000.0),
        ),
        const AssetPricesCompanion(
          assetId: Value(2),
          date: Value(20260102),
          price: Value(43000.0),
        ),
      ]);

      await db.assetPricesDao.deleteAllForAsset(2);
      final prices = await db.assetPricesDao.getPricesForRange(
          2, 20260101, 20261231);
      expect(prices, isEmpty);
    });

    test('insertOnConflictUpdate updates existing price', () async {
      await db.assetPricesDao.insertPrice(const AssetPricesCompanion(
        assetId: Value(2),
        date: Value(20260101),
        price: Value(42000.0),
      ));

      await db.assetPricesDao.insertPrice(const AssetPricesCompanion(
        assetId: Value(2),
        date: Value(20260101),
        price: Value(45000.0),
      ));

      final price = await db.assetPricesDao.getPrice(2, 20260101);
      expect(price!.price, 45000.0);
    });

    test('watchPricesForAsset emits updates', () async {
      final stream = db.assetPricesDao.watchPricesForAsset(2);

      await db.assetPricesDao.insertPrice(const AssetPricesCompanion(
        assetId: Value(2),
        date: Value(20260101),
        price: Value(42000.0),
      ));

      await expectLater(
        stream,
        emits(isA<List<AssetPrice>>().having((l) => l.length, 'length', 1)),
      );
    });
  });

  group('Schema migration', () {
    test('assets table has apiIdentifier column', () async {
      final asset = await (db.select(db.assets)
            ..where((t) => t.name.equals('Bitcoin')))
          .getSingle();
      expect(asset.apiIdentifier, 'bitcoin');
    });

    test('assets without apiIdentifier have null', () async {
      final asset = await (db.select(db.assets)
            ..where((t) => t.name.equals('Apple')))
          .getSingle();
      expect(asset.apiIdentifier, isNull);
    });
  });
}
