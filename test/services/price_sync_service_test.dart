import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:xfin/database/app_database.dart';
import 'package:xfin/database/tables.dart';
import 'package:xfin/services/price_service.dart';
import 'package:xfin/services/price_sync_service.dart';

class MockPriceService extends Mock implements PriceService {}

class FakeAssetPriceRequest extends Fake implements AssetPriceRequest {}

void main() {
  late AppDatabase db;
  late MockPriceService mockPriceService;
  late PriceSyncService syncService;

  setUpAll(() {
    registerFallbackValue(FakeAssetPriceRequest());
    registerFallbackValue(DateTime(2026));
  });

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    mockPriceService = MockPriceService();
    syncService = PriceSyncService(
      db: db,
      priceService: mockPriceService,
      baseCurrency: 'EUR',
    );

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

    await db.into(db.accounts).insert(AccountsCompanion.insert(
          name: 'Test',
          type: AccountTypes.bankAccount,
        ));
  });

  tearDown(() => db.close());

  group('PriceSyncService', () {
    test('syncAllAssets returns zero progress when no assets have apiId',
        () async {
      await (db.delete(db.assets)
            ..where((t) => t.apiIdentifier.isNotNull()))
          .go();

      final result = await syncService.syncAllAssets();
      expect(result.total, 0);
      expect(result.synced, 0);
      expect(result.failed, 0);
    });

    test('syncAllAssets skips asset without usage date', () async {
      final result = await syncService.syncAllAssets();
      expect(result.total, 1);
      expect(result.synced, 1);
      expect(result.failed, 0);
      verifyNever(() => mockPriceService.getHistoricalPrices(
          any(), any(), any(), any()));
    });

    test('syncAllAssets fetches prices for full range when no prices exist',
        () async {
      await db.into(db.bookings).insert(BookingsCompanion.insert(
            date: 20260420,
            accountId: 1,
            assetId: const Value(2),
            category: 'Investment',
            shares: 0.5,
            value: 21000.0,
          ));

      when(() => mockPriceService.getHistoricalPrices(
              any(), any(), any(), any()))
          .thenAnswer((_) async => {
                20260420: 42000.0,
                20260421: 42500.0,
                20260422: 43000.0,
              });

      final result = await syncService.syncAllAssets();
      expect(result.total, 1);
      expect(result.synced, 1);

      verify(() => mockPriceService.getHistoricalPrices(
          any(), any(), any(), any())).called(greaterThanOrEqualTo(1));
    });

    test('syncAllAssets detects internal gaps and fetches missing dates',
        () async {
      await db.into(db.bookings).insert(BookingsCompanion.insert(
            date: 20260420,
            accountId: 1,
            assetId: const Value(2),
            category: 'Investment',
            shares: 0.5,
            value: 21000.0,
          ));

      await db.assetPricesDao.insertPrices([
        const AssetPricesCompanion(
          assetId: Value(2),
          date: Value(20260420),
          price: Value(42000.0),
        ),
        const AssetPricesCompanion(
          assetId: Value(2),
          date: Value(20260422),
          price: Value(43000.0),
        ),
        const AssetPricesCompanion(
          assetId: Value(2),
          date: Value(20260425),
          price: Value(44000.0),
        ),
      ]);

      final capturedFromDates = <DateTime>[];
      final capturedToDates = <DateTime>[];

      when(() => mockPriceService.getHistoricalPrices(
              any(), any(), any(), any()))
          .thenAnswer((invocation) async {
        capturedFromDates.add(invocation.positionalArguments[1] as DateTime);
        capturedToDates.add(invocation.positionalArguments[2] as DateTime);
        return {};
      });

      await syncService.syncAllAssets();

      expect(capturedFromDates.isNotEmpty, true);

      final allRequestedDates = <int>{};
      for (int i = 0; i < capturedFromDates.length; i++) {
        DateTime d = capturedFromDates[i];
        while (!d.isAfter(capturedToDates[i])) {
          allRequestedDates
              .add(d.year * 10000 + d.month * 100 + d.day);
          d = DateTime(d.year, d.month, d.day + 1);
        }
      }

      expect(allRequestedDates.contains(20260421), true,
          reason: 'Should request gap between 20260420 and 20260422');
      expect(allRequestedDates.contains(20260423), true,
          reason: 'Should request gap between 20260422 and 20260425');
      expect(allRequestedDates.contains(20260424), true,
          reason: 'Should request gap between 20260422 and 20260425');

      expect(allRequestedDates.contains(20260420), false,
          reason: 'Should not request existing date 20260420');
      expect(allRequestedDates.contains(20260422), false,
          reason: 'Should not request existing date 20260422');
      expect(allRequestedDates.contains(20260425), false,
          reason: 'Should not request existing date 20260425');
    });

    test('syncAllAssets does not fetch when no gaps exist', () async {
      await db.into(db.bookings).insert(BookingsCompanion.insert(
            date: 20260424,
            accountId: 1,
            assetId: const Value(2),
            category: 'Investment',
            shares: 0.5,
            value: 21000.0,
          ));

      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final yesterdayInt =
          yesterday.year * 10000 + yesterday.month * 100 + yesterday.day;

      final prices = <AssetPricesCompanion>[];
      DateTime d = DateTime(2026, 4, 24);
      while (d.year * 10000 + d.month * 100 + d.day <= yesterdayInt) {
        prices.add(AssetPricesCompanion(
          assetId: const Value(2),
          date: Value(d.year * 10000 + d.month * 100 + d.day),
          price: const Value(42000.0),
        ));
        d = DateTime(d.year, d.month, d.day + 1);
      }
      await db.assetPricesDao.insertPrices(prices);

      final result = await syncService.syncAllAssets();
      expect(result.total, 1);
      expect(result.synced, 1);
      verifyNever(() => mockPriceService.getHistoricalPrices(
          any(), any(), any(), any()));
    });

    test('syncAllAssets groups consecutive missing dates into ranges',
        () async {
      await db.into(db.bookings).insert(BookingsCompanion.insert(
            date: 20260410,
            accountId: 1,
            assetId: const Value(2),
            category: 'Investment',
            shares: 0.5,
            value: 21000.0,
          ));

      await db.assetPricesDao.insertPrices([
        const AssetPricesCompanion(
          assetId: Value(2),
          date: Value(20260410),
          price: Value(42000.0),
        ),
        const AssetPricesCompanion(
          assetId: Value(2),
          date: Value(20260413),
          price: Value(43000.0),
        ),
        const AssetPricesCompanion(
          assetId: Value(2),
          date: Value(20260414),
          price: Value(43500.0),
        ),
        const AssetPricesCompanion(
          assetId: Value(2),
          date: Value(20260417),
          price: Value(44000.0),
        ),
      ]);

      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final yesterdayInt =
          yesterday.year * 10000 + yesterday.month * 100 + yesterday.day;
      final remaining = <AssetPricesCompanion>[];
      DateTime d = DateTime(2026, 4, 18);
      while (d.year * 10000 + d.month * 100 + d.day <= yesterdayInt) {
        remaining.add(AssetPricesCompanion(
          assetId: const Value(2),
          date: Value(d.year * 10000 + d.month * 100 + d.day),
          price: const Value(44500.0),
        ));
        d = DateTime(d.year, d.month, d.day + 1);
      }
      if (remaining.isNotEmpty) {
        await db.assetPricesDao.insertPrices(remaining);
      }

      int callCount = 0;
      when(() => mockPriceService.getHistoricalPrices(
              any(), any(), any(), any()))
          .thenAnswer((_) async {
        callCount++;
        return {};
      });

      await syncService.syncAllAssets();

      expect(callCount, 2,
          reason: 'Should make 2 API calls: '
              'gap 20260411-20260412 and gap 20260415-20260416');
    });

    test('syncAllAssets handles API failures gracefully', () async {
      await db.into(db.bookings).insert(BookingsCompanion.insert(
            date: 20260420,
            accountId: 1,
            assetId: const Value(2),
            category: 'Investment',
            shares: 0.5,
            value: 21000.0,
          ));

      when(() => mockPriceService.getHistoricalPrices(
              any(), any(), any(), any()))
          .thenThrow(Exception('API error'));

      final result = await syncService.syncAllAssets();
      expect(result.total, 1);
      expect(result.synced, 0);
      expect(result.failed, 1);
    });

    test('syncSingleAsset syncs a single asset', () async {
      await db.into(db.bookings).insert(BookingsCompanion.insert(
            date: 20260420,
            accountId: 1,
            assetId: const Value(2),
            category: 'Investment',
            shares: 0.5,
            value: 21000.0,
          ));

      when(() => mockPriceService.getHistoricalPrices(
              any(), any(), any(), any()))
          .thenAnswer((_) async => {20260420: 42000.0});

      final assets = await db.assetPricesDao.getAssetsWithApiIdentifier();
      final count = await syncService.syncSingleAsset(assets.first);
      expect(count, greaterThanOrEqualTo(1));
    });

    test('onProgress callback reports progress', () async {
      await db.into(db.bookings).insert(BookingsCompanion.insert(
            date: 20260420,
            accountId: 1,
            assetId: const Value(2),
            category: 'Investment',
            shares: 0.5,
            value: 21000.0,
          ));

      when(() => mockPriceService.getHistoricalPrices(
              any(), any(), any(), any()))
          .thenAnswer((_) async => {});

      final progressCalls = <(int, int, String)>[];
      await syncService.syncAllAssets(
        onProgress: (current, total, name) =>
            progressCalls.add((current, total, name)),
      );

      expect(progressCalls.length, 1);
      expect(progressCalls[0].$1, 1);
      expect(progressCalls[0].$2, 1);
      expect(progressCalls[0].$3, 'Bitcoin');
    });
  });
}
