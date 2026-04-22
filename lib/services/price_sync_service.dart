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

  Future<void> _syncAsset(Asset asset, DateTime upTo) async {
    final firstUsageDate = await _dao.getFirstAssetUsageDate(asset.id);
    if (firstUsageDate == null) return;

    final latestPriceDate = await _dao.getLatestPriceDate(asset.id);

    final DateTime from;
    if (latestPriceDate != null) {
      final y = latestPriceDate ~/ 10000;
      final m = (latestPriceDate % 10000) ~/ 100;
      final d = latestPriceDate % 100;
      from = DateTime(y, m, d).add(const Duration(days: 1));
    } else {
      final y = firstUsageDate ~/ 10000;
      final m = (firstUsageDate % 10000) ~/ 100;
      final d = firstUsageDate % 100;
      from = DateTime(y, m, d);
    }

    if (from.isAfter(upTo)) return;

    final request = AssetPriceRequest(
      assetId: asset.id,
      apiIdentifier: asset.apiIdentifier!,
      assetType: asset.type,
    );

    final prices = await _priceService.getHistoricalPrices(
        request, from, upTo, _baseCurrency);

    if (prices.isNotEmpty) {
      final companions = prices.entries.map((e) {
        return AssetPricesCompanion(
          assetId: Value(asset.id),
          date: Value(e.key),
          price: Value(e.value),
        );
      }).toList();

      await _dao.insertPrices(companions);
    }
  }

  Future<void> syncSingleAsset(Asset asset) async {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    await _syncAsset(asset, yesterday);
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
