import 'dart:async';

import 'package:flutter/material.dart';

import '../database/app_database.dart';
import '../services/price_service.dart';
import '../services/price_sync_service.dart';

class LivePriceProvider with ChangeNotifier {
  static final LivePriceProvider instance = LivePriceProvider._();

  LivePriceProvider._();

  AppDatabase? _db;
  PriceService? _priceService;
  PriceSyncService? _priceSyncService;
  String _baseCurrency = 'EUR';

  bool _isLive = false;
  bool _isConnected = false;
  bool _isSyncing = false;
  final Map<int, double> _livePrices = {};
  StreamSubscription? _priceSubscription;

  bool get isLive => _isLive;
  bool get isConnected => _isConnected;
  bool get isSyncing => _isSyncing;
  Map<int, double> get livePrices => Map.unmodifiable(_livePrices);

  PriceService? get priceService => _priceService;

  Future<void> initialize(AppDatabase db, String baseCurrency) async {
    _db = db;
    _baseCurrency = baseCurrency;
    _priceService = PriceService();
    await _priceService!.initialize(baseCurrency);
    _priceSyncService = PriceSyncService(
      db: db,
      priceService: _priceService!,
      baseCurrency: baseCurrency,
    );
  }

  double? getLivePrice(int assetId) => _livePrices[assetId];

  double getLiveValue(int assetId, double shares) {
    final price = _livePrices[assetId];
    if (price == null) return shares;
    return shares * price;
  }

  Future<void> toggle() async {
    if (_isLive) {
      await _stopLive();
    } else {
      await _startLive();
    }
  }

  Future<void> _startLive() async {
    if (_db == null || _priceService == null) return;

    _isLive = true;
    notifyListeners();

    final assets = await _db!.assetPricesDao.getAssetsWithApiIdentifier();
    if (assets.isEmpty) {
      _isLive = false;
      notifyListeners();
      return;
    }

    final requests = assets
        .map((a) => AssetPriceRequest(
              assetId: a.id,
              apiIdentifier: a.apiIdentifier!,
              assetType: a.type,
            ))
        .toList();

    _priceSubscription = _priceService!.livePriceUpdates.listen((prices) {
      _livePrices.addAll(prices);
      _isConnected = true;
      notifyListeners();
    });

    await _priceService!.startLiveStreams(requests, _baseCurrency);
  }

  Future<void> _stopLive() async {
    _isLive = false;
    _isConnected = false;
    _livePrices.clear();
    await _priceSubscription?.cancel();
    _priceSubscription = null;
    await _priceService?.stopLiveStreams();
    notifyListeners();
  }

  Future<SyncProgress?> syncHistoricalPrices({
    void Function(int current, int total, String assetName)? onProgress,
  }) async {
    if (_priceSyncService == null) return null;

    _isSyncing = true;
    notifyListeners();

    try {
      final result =
          await _priceSyncService!.syncAllAssets(onProgress: onProgress);
      return result;
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _stopLive();
    _priceService?.dispose();
    super.dispose();
  }
}
