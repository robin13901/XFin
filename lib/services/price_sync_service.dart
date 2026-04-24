import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import '../database/app_database.dart';
import '../database/daos/asset_prices_dao.dart';
import 'price_service.dart';

class PriceSyncService {
  final AppDatabase _db;
  final PriceService _priceService;
  final String _baseCurrency;

  PriceSyncService({
    required AppDatabase db,
    required PriceService priceService,
    required String baseCurrency,
  })  : _db = db,
        _priceService = priceService,
        _baseCurrency = baseCurrency;

  AssetPricesDao get _dao => _db.assetPricesDao;

  Future<SyncProgress> syncAllAssets({
    void Function(int current, int total, String assetName)? onProgress,
  }) async {
    final assets = await _dao.getAssetsWithApiIdentifier();
    if (assets.isEmpty) return const SyncProgress(total: 0, synced: 0, failed: 0);

    int synced = 0;
    int failed = 0;
    final yesterday = DateTime.now().subtract(const Duration(days: 1));

    for (int i = 0; i < assets.length; i++) {
      final asset = assets[i];
      onProgress?.call(i + 1, assets.length, asset.name);

      try {
        await _syncAsset(asset, yesterday);
        synced++;
      } catch (e) {
        debugPrint('Sync failed for ${asset.name}: $e');
        failed++;
      }
    }

    return SyncProgress(total: assets.length, synced: synced, failed: failed);
  }

  Future<int> _syncAsset(Asset asset, DateTime upTo) async {
    final firstUsageDate = await _dao.getFirstAssetUsageDate(asset.id);
    if (firstUsageDate == null) return 0;

    final firstUsageDt = _intToDate(firstUsageDate);
    final latestPriceDate = await _dao.getLatestPriceDate(asset.id);
    final earliestPriceDate = await _dao.getEarliestPriceDate(asset.id);

    final request = AssetPriceRequest(
      assetId: asset.id,
      apiIdentifier: asset.apiIdentifier!,
      assetType: asset.type,
    );

    int totalSynced = 0;

    // Fill backward gap: first usage date → earliest price date - 1
    if (earliestPriceDate != null) {
      final earliestDt = _intToDate(earliestPriceDate);
      if (firstUsageDt.isBefore(earliestDt)) {
        final backwardEnd = DateTime(earliestDt.year, earliestDt.month, earliestDt.day - 1);
        totalSynced += await _fetchAndStore(request, asset.id, firstUsageDt, backwardEnd);
      }
    }

    // Fill forward gap: latest price date + 1 → yesterday
    final DateTime forwardFrom;
    if (latestPriceDate != null) {
      final latestDt = _intToDate(latestPriceDate);
      forwardFrom = DateTime(latestDt.year, latestDt.month, latestDt.day + 1);
    } else {
      forwardFrom = firstUsageDt;
    }

    if (!forwardFrom.isAfter(upTo)) {
      totalSynced += await _fetchAndStore(request, asset.id, forwardFrom, upTo);
    }

    return totalSynced;
  }

  Future<int> _fetchAndStore(AssetPriceRequest request, int assetId,
      DateTime from, DateTime to) async {
    if (from.isAfter(to)) return 0;

    final prices = await _priceService.getHistoricalPrices(
        request, from, to, _baseCurrency);

    if (prices.isNotEmpty) {
      final companions = prices.entries.map((e) {
        return AssetPricesCompanion(
          assetId: Value(assetId),
          date: Value(e.key),
          price: Value(e.value),
        );
      }).toList();

      await _dao.insertPrices(companions);
    }
    return prices.length;
  }

  static DateTime _intToDate(int dateInt) {
    final y = dateInt ~/ 10000;
    final m = (dateInt % 10000) ~/ 100;
    final d = dateInt % 100;
    return DateTime(y, m, d);
  }

  Future<int> syncSingleAsset(Asset asset) async {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return _syncAsset(asset, yesterday);
  }
}

class SyncProgress {
  final int total;
  final int synced;
  final int failed;

  const SyncProgress({
    required this.total,
    required this.synced,
    required this.failed,
  });
}
