import 'dart:async';

import 'package:flutter/foundation.dart';
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
  String? _lastError;
  final Map<int, double> _livePrices = {};
  StreamSubscription? _priceSubscription;

  bool get isLive => _isLive;
  bool get isConnected => _isConnected;
  bool get isSyncing => _isSyncing;
  String? get lastError => _lastError;
  Map<int, double> get livePrices => Map.unmodifiable(_livePrices);

  PriceService? get priceService => _priceService;

  @visibleForTesting
  void setPriceServiceForTesting(PriceService service) {
    _priceService = service;
  }

  @visibleForTesting
  void setLivePriceForTesting(int assetId, double price) {
    _livePrices[assetId] = price;
    _isLive = true;
    _isConnected = true;
    notifyListeners();
  }

  @visibleForTesting
  void clearLivePricesForTesting() {
    _livePrices.clear();
    _isLive = false;
    _isConnected = false;
    notifyListeners();
  }

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
    debugPrint('LivePriceProvider initialized (baseCurrency=$baseCurrency)');
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

  /// Refresh the asset list and restart polling.
  /// Call this after saving an apiIdentifier on an asset.
  Future<void> refreshAssets() async {
    if (!_isLive || _db == null || _priceService == null) return;
    await _priceService!.stopLiveStreams();
    await _loadAndStartStreams();
  }

  Future<void> _startLive() async {
    if (_db == null || _priceService == null) {
      _lastError = 'Service nicht initialisiert';
      notifyListeners();
      return;
    }

    _isLive = true;
    _lastError = null;
    notifyListeners();

    await _loadAndStartStreams();
  }

  Future<void> _loadAndStartStreams() async {
    final assets = await _db!.assetPricesDao.getAssetsWithApiIdentifier();
    debugPrint('Live: found ${assets.length} assets with apiIdentifier');
    if (assets.isEmpty) {
      _isLive = false;
      _lastError = 'Keine Assets mit API-Identifier gefunden';
      notifyListeners();
      return;
    }

    // Sort by value descending — highest value assets get fetched first
    final sorted = assets.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final requests = sorted
        .map((a) => AssetPriceRequest(
              assetId: a.id,
              apiIdentifier: a.apiIdentifier!,
              assetType: a.type,
            ))
        .toList();

    _priceSubscription?.cancel();
    _priceSubscription = _priceService!.livePriceUpdates.listen((prices) {
      _livePrices.addAll(prices);
      _isConnected = true;
      notifyListeners();
    });

    try {
      await _priceService!.startLiveStreams(requests, _baseCurrency);
    } catch (e) {
      debugPrint('Live stream error: $e');
      _lastError = e.toString();
      notifyListeners();
    }
  }

  Future<void> _stopLive() async {
    _isLive = false;
    _isConnected = false;
    _lastError = null;
    _livePrices.clear();
    await _priceSubscription?.cancel();
    _priceSubscription = null;
    await _priceService?.stopLiveStreams();
    notifyListeners();
  }

  Future<SyncProgress?> syncHistoricalPrices({
    void Function(int current, int total, String assetName)? onProgress,
  }) async {
    if (_priceSyncService == null) {
      debugPrint('syncHistoricalPrices: _priceSyncService is null');
      return null;
    }

    _isSyncing = true;
    notifyListeners();

    try {
      debugPrint('Starting historical price sync...');
      final result =
          await _priceSyncService!.syncAllAssets(onProgress: onProgress);
      debugPrint(
          'Sync done: ${result.synced}/${result.total} synced, ${result.failed} failed');
      return result;
    } catch (e) {
      debugPrint('Sync error: $e');
      return null;
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
