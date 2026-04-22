import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

import '../database/tables.dart';
import 'binance_ws_provider.dart';
import 'coingecko_provider.dart';
import 'finnhub_ws_provider.dart';
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
  TwelveDataProvider? _twelveData;
  BinanceWsProvider? _binanceWs;
  FinnhubWsProvider? _finnhubWs;

  final _livePriceController =
      StreamController<Map<int, double>>.broadcast();
  final Map<String, int> _symbolToAssetId = {};
  StreamSubscription? _binanceSub;
  StreamSubscription? _finnhubSub;

  double? _usdToBaseCurrencyRate;
  Timer? _forexRefreshTimer;

  PriceService({
    CoinGeckoProvider? coinGecko,
    FrankfurterProvider? frankfurter,
  })  : _coinGecko = coinGecko ?? CoinGeckoProvider(),
        _frankfurter = frankfurter ?? FrankfurterProvider();

  Stream<Map<int, double>> get livePriceUpdates => _livePriceController.stream;

  Future<void> initialize(String baseCurrency) async {
    final prefs = await SharedPreferences.getInstance();

    final finnhubKey = prefs.getString('finnhub_api_key') ?? '';
    final twelveDataKey = prefs.getString('twelve_data_api_key') ?? '';

    if (finnhubKey.isNotEmpty) {
      _finnhubWs = FinnhubWsProvider(apiKey: finnhubKey);
    }
    if (twelveDataKey.isNotEmpty) {
      _twelveData = TwelveDataProvider(apiKey: twelveDataKey);
    }

    await _refreshForexRate(baseCurrency);
  }

  Future<void> _refreshForexRate(String baseCurrency) async {
    if (baseCurrency.toUpperCase() == 'USD') {
      _usdToBaseCurrencyRate = 1.0;
      return;
    }
    try {
      final rate =
          await _frankfurter.getExchangeRate('USD', baseCurrency)
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
    _symbolToAssetId.clear();

    final cryptoSymbols = <String>[];
    final stockSymbols = <String>[];
    final fiatIdentifiers = <String>[];
    final fiatAssetIds = <String, int>{};

    for (final req in requests) {
      switch (req.assetType) {
        case AssetTypes.crypto:
          final binanceSymbol =
              '${req.apiIdentifier.toLowerCase()}${baseCurrency.toLowerCase()}';
          cryptoSymbols.add(binanceSymbol);
          _symbolToAssetId[binanceSymbol] = req.assetId;
        case AssetTypes.stock:
        case AssetTypes.etf:
        case AssetTypes.fund:
        case AssetTypes.derivative:
          stockSymbols.add(req.apiIdentifier);
          _symbolToAssetId[req.apiIdentifier] = req.assetId;
        case AssetTypes.fiat:
          fiatIdentifiers.add(req.apiIdentifier);
          fiatAssetIds[req.apiIdentifier] = req.assetId;
      }
    }

    _binanceWs = BinanceWsProvider();
    if (cryptoSymbols.isNotEmpty) {
      await _binanceWs!.connect(cryptoSymbols);
      _binanceSub = _binanceWs!.priceUpdates.listen((prices) {
        final mapped = <int, double>{};
        for (final entry in prices.entries) {
          final assetId = _symbolToAssetId[entry.key];
          if (assetId != null) {
            mapped[assetId] = entry.value;
          }
        }
        if (mapped.isNotEmpty) _livePriceController.add(mapped);
      });
    }

    if (stockSymbols.isNotEmpty && _finnhubWs != null) {
      await _finnhubWs!.connect(stockSymbols);
      _finnhubSub = _finnhubWs!.priceUpdates.listen((prices) {
        final mapped = <int, double>{};
        final rate = _usdToBaseCurrencyRate ?? 1.0;
        for (final entry in prices.entries) {
          final assetId = _symbolToAssetId[entry.key];
          if (assetId != null) {
            mapped[assetId] = entry.value * rate;
          }
        }
        if (mapped.isNotEmpty) _livePriceController.add(mapped);
      });
    }

    if (fiatIdentifiers.isNotEmpty) {
      _forexRefreshTimer?.cancel();
      _forexRefreshTimer =
          Timer.periodic(const Duration(minutes: 5), (_) async {
        await _fetchForexPrices(fiatIdentifiers, fiatAssetIds, baseCurrency);
      });
      await _fetchForexPrices(fiatIdentifiers, fiatAssetIds, baseCurrency);
    }
  }

  Future<void> _fetchForexPrices(List<String> identifiers,
      Map<String, int> assetIds, String baseCurrency) async {
    try {
      final prices =
          await _frankfurter.getCurrentPrices(identifiers, baseCurrency);
      final mapped = <int, double>{};
      for (final entry in prices.entries) {
        final assetId = assetIds[entry.key];
        if (assetId != null) {
          mapped[assetId] = entry.value;
        }
      }
      if (mapped.isNotEmpty) _livePriceController.add(mapped);
    } catch (_) {}
  }

  Future<void> stopLiveStreams() async {
    _forexRefreshTimer?.cancel();
    _forexRefreshTimer = null;
    await _binanceSub?.cancel();
    _binanceSub = null;
    await _finnhubSub?.cancel();
    _finnhubSub = null;
    await _binanceWs?.disconnect();
    _binanceWs = null;
    await _finnhubWs?.disconnect();
  }

  Future<Map<String, double>> getCurrentPricesFallback(
      List<AssetPriceRequest> requests, String baseCurrency) async {
    final cryptoIds = <String>[];
    final stockIds = <String>[];

    for (final req in requests) {
      switch (req.assetType) {
        case AssetTypes.crypto:
          cryptoIds.add(req.apiIdentifier);
        case AssetTypes.stock:
        case AssetTypes.etf:
        case AssetTypes.fund:
        case AssetTypes.derivative:
          stockIds.add(req.apiIdentifier);
        case AssetTypes.fiat:
          break;
      }
    }

    final results = <String, double>{};

    if (cryptoIds.isNotEmpty) {
      final prices = await _coinGecko.getCurrentPrices(cryptoIds, baseCurrency);
      results.addAll(prices);
    }

    if (stockIds.isNotEmpty && _twelveData != null) {
      final prices =
          await _twelveData!.getCurrentPrices(stockIds, baseCurrency);
      final rate = _usdToBaseCurrencyRate ?? 1.0;
      for (final entry in prices.entries) {
        results[entry.key] = entry.value * rate;
      }
    }

    return results;
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
        if (_twelveData == null) return {};
        final usdPrices = await _twelveData!.getHistoricalDailyPrices(
            request.apiIdentifier, from, to, 'USD');
        if (baseCurrency.toUpperCase() == 'USD') return usdPrices;
        final forexHistory = await _frankfurter.getHistoricalDailyPrices(
            'USD', from, to, baseCurrency);
        final converted = <int, double>{};
        for (final entry in usdPrices.entries) {
          final rate = forexHistory[entry.key] ?? _usdToBaseCurrencyRate ?? 1.0;
          converted[entry.key] = entry.value * rate;
        }
        return converted;
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
        if (_twelveData == null) return [];
        return _twelveData!.search(query);
      case AssetTypes.fiat:
        return [];
    }
  }

  void dispose() {
    stopLiveStreams();
    _livePriceController.close();
    _coinGecko.dispose();
    _frankfurter.dispose();
    _twelveData?.dispose();
  }
}
