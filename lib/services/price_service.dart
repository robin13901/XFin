import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/tables.dart';
import 'coingecko_provider.dart';
import 'frankfurter_provider.dart';
import 'price_provider.dart';
import 'twelve_data_provider.dart';

class AssetPriceRequest {
  final int assetId;
  final String apiIdentifier;
  final AssetTypes assetType;

  const AssetPriceRequest({
    required this.assetId,
    required this.apiIdentifier,
    required this.assetType,
  });
}

class PriceService {
  final CoinGeckoProvider _coinGecko;
  final FrankfurterProvider _frankfurter;

  final _livePriceController =
      StreamController<Map<int, double>>.broadcast();

  double? _usdToBaseCurrencyRate;
  Timer? _refreshTimer;
  List<AssetPriceRequest> _activeRequests = [];
  String _baseCurrency = 'EUR';
  bool _isStreaming = false;

  PriceService({
    CoinGeckoProvider? coinGecko,
    FrankfurterProvider? frankfurter,
  })  : _coinGecko = coinGecko ?? CoinGeckoProvider(),
        _frankfurter = frankfurter ?? FrankfurterProvider();

  Stream<Map<int, double>> get livePriceUpdates => _livePriceController.stream;

  Future<void> initialize(String baseCurrency) async {
    _baseCurrency = baseCurrency;
    await _refreshForexRate(baseCurrency);
  }

  Future<TwelveDataProvider?> _getTwelveData() async {
    final prefs = await SharedPreferences.getInstance();
    final key = prefs.getString('twelve_data_api_key') ?? '';
    if (key.isEmpty) return null;
    return TwelveDataProvider(apiKey: key);
  }

  Future<void> _refreshForexRate(String baseCurrency) async {
    if (baseCurrency.toUpperCase() == 'USD') {
      _usdToBaseCurrencyRate = 1.0;
      return;
    }
    try {
      final rate = await _frankfurter
          .getExchangeRate('USD', baseCurrency)
          .timeout(const Duration(seconds: 5));
      if (rate != null) {
        _usdToBaseCurrencyRate = rate;
      }
    } catch (_) {
      _usdToBaseCurrencyRate ??= 1.0;
    }
  }

  Future<void> startLiveStreams(
      List<AssetPriceRequest> requests, String baseCurrency) async {
    _activeRequests = requests;
    _baseCurrency = baseCurrency;
    _isStreaming = true;

    await _fetchAndEmitPrices();

    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (_isStreaming) _fetchAndEmitPrices();
    });
  }

  Future<void> _fetchAndEmitPrices() async {
    final cryptoIds = <String, int>{};
    final stockIds = <String, int>{};
    final fiatIds = <String, int>{};

    for (final req in _activeRequests) {
      switch (req.assetType) {
        case AssetTypes.crypto:
          cryptoIds[req.apiIdentifier] = req.assetId;
        case AssetTypes.stock:
        case AssetTypes.etf:
        case AssetTypes.fund:
        case AssetTypes.derivative:
          stockIds[req.apiIdentifier] = req.assetId;
        case AssetTypes.fiat:
          fiatIds[req.apiIdentifier] = req.assetId;
      }
    }

    final mapped = <int, double>{};

    if (cryptoIds.isNotEmpty) {
      try {
        final prices = await _coinGecko.getCurrentPrices(
            cryptoIds.keys.toList(), _baseCurrency);
        for (final entry in prices.entries) {
          final assetId = cryptoIds[entry.key];
          if (assetId != null) mapped[assetId] = entry.value;
        }
      } catch (e) {
        debugPrint('CoinGecko error: $e');
      }
    }

    if (stockIds.isNotEmpty) {
      try {
        final twelveData = await _getTwelveData();
        if (twelveData != null) {
          final prices = await twelveData.getCurrentPrices(
              stockIds.keys.toList(), 'USD');
          final rate = _usdToBaseCurrencyRate ?? 1.0;
          for (final entry in prices.entries) {
            final assetId = stockIds[entry.key];
            if (assetId != null) mapped[assetId] = entry.value * rate;
          }
          twelveData.dispose();
        }
      } catch (e) {
        debugPrint('TwelveData error: $e');
      }
    }

    if (fiatIds.isNotEmpty) {
      try {
        final prices = await _frankfurter.getCurrentPrices(
            fiatIds.keys.toList(), _baseCurrency);
        for (final entry in prices.entries) {
          final assetId = fiatIds[entry.key];
          if (assetId != null) mapped[assetId] = entry.value;
        }
      } catch (e) {
        debugPrint('Frankfurter error: $e');
      }
    }

    if (mapped.isNotEmpty) {
      _livePriceController.add(mapped);
    }
  }

  Future<void> stopLiveStreams() async {
    _isStreaming = false;
    _refreshTimer?.cancel();
    _refreshTimer = null;
    _activeRequests = [];
  }

  Future<Map<int, double>> getHistoricalPrices(AssetPriceRequest request,
      DateTime from, DateTime to, String baseCurrency) async {
    switch (request.assetType) {
      case AssetTypes.crypto:
        return _coinGecko.getHistoricalDailyPrices(
            request.apiIdentifier, from, to, baseCurrency);
      case AssetTypes.stock:
      case AssetTypes.etf:
      case AssetTypes.fund:
      case AssetTypes.derivative:
        final twelveData = await _getTwelveData();
        if (twelveData == null) return {};
        try {
          final usdPrices = await twelveData.getHistoricalDailyPrices(
              request.apiIdentifier, from, to, 'USD');
          if (baseCurrency.toUpperCase() == 'USD') return usdPrices;
          final forexHistory = await _frankfurter.getHistoricalDailyPrices(
              'USD', from, to, baseCurrency);
          final converted = <int, double>{};
          for (final entry in usdPrices.entries) {
            final rate =
                forexHistory[entry.key] ?? _usdToBaseCurrencyRate ?? 1.0;
            converted[entry.key] = entry.value * rate;
          }
          return converted;
        } finally {
          twelveData.dispose();
        }
      case AssetTypes.fiat:
        return _frankfurter.getHistoricalDailyPrices(
            request.apiIdentifier, from, to, baseCurrency);
    }
  }

  Future<List<SymbolSearchResult>> searchSymbols(
      String query, AssetTypes assetType) async {
    switch (assetType) {
      case AssetTypes.crypto:
        return _coinGecko.search(query);
      case AssetTypes.stock:
      case AssetTypes.etf:
      case AssetTypes.fund:
      case AssetTypes.derivative:
        final twelveData = await _getTwelveData();
        if (twelveData == null) return [];
        try {
          return await twelveData.search(query);
        } finally {
          twelveData.dispose();
        }
      case AssetTypes.fiat:
        return [];
    }
  }

  void dispose() {
    stopLiveStreams();
    _livePriceController.close();
    _coinGecko.dispose();
    _frankfurter.dispose();
  }
}
