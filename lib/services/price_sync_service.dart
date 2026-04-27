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
    final upToInt = _dateToInt(upTo);

    final existingDates =
        await _dao.getExistingPriceDates(asset.id, firstUsageDate, upToInt);

    final missingDateInts = <int>[];
    DateTime current = firstUsageDt;
    while (!current.isAfter(upTo)) {
      final dateInt = _dateToInt(current);
      if (!existingDates.contains(dateInt)) {
        missingDateInts.add(dateInt);
      }
      current = DateTime(current.year, current.month, current.day + 1);
    }

    if (missingDateInts.isEmpty) return 0;

    final request = AssetPriceRequest(
      assetId: asset.id,
      apiIdentifier: asset.apiIdentifier!,
      assetType: asset.type,
    );

    final ranges = _groupConsecutiveDates(missingDateInts);
    int totalSynced = 0;
    for (final (from, to) in ranges) {
      totalSynced += await _fetchAndStore(request, asset.id, from, to);
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

  static int _dateToInt(DateTime date) {
    return date.year * 10000 + date.month * 100 + date.day;
  }

  static List<(DateTime, DateTime)> _groupConsecutiveDates(
      List<int> sortedDates) {
    if (sortedDates.isEmpty) return [];
    final groups = <(DateTime, DateTime)>[];
    int rangeStartInt = sortedDates.first;
    int prevInt = rangeStartInt;

    for (int i = 1; i < sortedDates.length; i++) {
      final currentInt = sortedDates[i];
      final prevDate = _intToDate(prevInt);
      final nextDayInt =
          _dateToInt(DateTime(prevDate.year, prevDate.month, prevDate.day + 1));

      if (currentInt == nextDayInt) {
        prevInt = currentInt;
      } else {
        groups.add((_intToDate(rangeStartInt), _intToDate(prevInt)));
        rangeStartInt = currentInt;
        prevInt = currentInt;
      }
    }
    groups.add((_intToDate(rangeStartInt), _intToDate(prevInt)));
    return groups;
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
