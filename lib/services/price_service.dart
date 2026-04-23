import 'dart:async';

import 'package:flutter/foundation.dart';

import '../database/tables.dart';
import 'coingecko_provider.dart';
import 'price_provider.dart';
import 'yahoo_finance_provider.dart';

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
  final YahooFinanceProvider _yahoo;

  final _livePriceController =
      StreamController<Map<int, double>>.broadcast();

  Timer? _refreshTimer;
  List<AssetPriceRequest> _activeRequests = [];
  String _baseCurrency = 'EUR';
  bool _isStreaming = false;

  PriceService({
    CoinGeckoProvider? coinGecko,
    YahooFinanceProvider? yahoo,
  })  : _coinGecko = coinGecko ?? CoinGeckoProvider(),
        _yahoo = yahoo ?? YahooFinanceProvider();

  Stream<Map<int, double>> get livePriceUpdates => _livePriceController.stream;

  Future<void> initialize(String baseCurrency) async {
    _baseCurrency = baseCurrency;
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
    final mapped = <int, double>{};

    for (final req in _activeRequests) {
      try {
        final yahooSymbol = _toYahooSymbol(req);
        final price = await _yahoo.getCurrentPrice(yahooSymbol);
        if (price != null) {
          mapped[req.assetId] = price;
          debugPrint('Live ${req.apiIdentifier} ($yahooSymbol): $price');
        }
      } catch (e) {
        debugPrint('Live fetch error for ${req.apiIdentifier}: $e');
      }
    }

    if (mapped.isNotEmpty) {
      _livePriceController.add(mapped);
    }
  }

  String _toYahooSymbol(AssetPriceRequest req) {
    final id = req.apiIdentifier;

    // If it already looks like a Yahoo symbol (contains . or -), use as-is
    if (id.contains('.') || id.contains('-')) return id;

    switch (req.assetType) {
      case AssetTypes.crypto:
        // CoinGecko IDs like "bitcoin" → Yahoo format "BTC-EUR"
        // Common mappings for well-known cryptos
        final ticker = _cryptoIdToTicker(id);
        return '$ticker-${_baseCurrency.toUpperCase()}';
      case AssetTypes.fiat:
        return '${id.toUpperCase()}${_baseCurrency.toUpperCase()}=X';
      case AssetTypes.stock:
      case AssetTypes.etf:
      case AssetTypes.fund:
      case AssetTypes.derivative:
        return id.toUpperCase();
    }
  }

  String _cryptoIdToTicker(String coinGeckoId) {
    const map = {
      'bitcoin': 'BTC',
      'ethereum': 'ETH',
      'solana': 'SOL',
      'cardano': 'ADA',
      'ripple': 'XRP',
      'dogecoin': 'DOGE',
      'polkadot': 'DOT',
      'avalanche-2': 'AVAX',
      'chainlink': 'LINK',
      'litecoin': 'LTC',
      'uniswap': 'UNI',
      'stellar': 'XLM',
      'cosmos': 'ATOM',
      'near': 'NEAR',
      'tron': 'TRX',
      'sui': 'SUI',
      'pepe': 'PEPE',
      'shiba-inu': 'SHIB',
      'bitcoin-cash': 'BCH',
      'toncoin': 'TON',
      'hedera-hashgraph': 'HBAR',
    };
    return map[coinGeckoId.toLowerCase()] ??
        coinGeckoId.toUpperCase();
  }

  Future<void> stopLiveStreams() async {
    _isStreaming = false;
    _refreshTimer?.cancel();
    _refreshTimer = null;
    _activeRequests = [];
  }

  Future<Map<int, double>> getHistoricalPrices(AssetPriceRequest request,
      DateTime from, DateTime to, String baseCurrency) async {
    final yahooSymbol = _toYahooSymbol(request);
    return _yahoo.getHistoricalDailyPrices(yahooSymbol, from, to, baseCurrency);
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
        // Yahoo has no search API — use CoinGecko for crypto,
        // for stocks the user enters the Yahoo ticker directly
        return _searchYahooViaValidation(query);
      case AssetTypes.fiat:
        return _searchFiat(query);
    }
  }

  Future<List<SymbolSearchResult>> _searchYahooViaValidation(
      String query) async {
    // Try the query as a Yahoo symbol directly
    final symbol = query.toUpperCase();
    final price = await _yahoo.getCurrentPrice(symbol);
    if (price != null) {
      return [
        SymbolSearchResult(
          symbol: symbol,
          name: '$symbol (${price.toStringAsFixed(2)})',
          type: 'Yahoo Finance',
        ),
      ];
    }
    // Try with .DE suffix for German exchange
    final deSymbol = '$symbol.DE';
    final dePrice = await _yahoo.getCurrentPrice(deSymbol);
    if (dePrice != null) {
      return [
        SymbolSearchResult(
          symbol: deSymbol,
          name: '$deSymbol (${dePrice.toStringAsFixed(2)})',
          exchange: 'XETRA',
          type: 'Yahoo Finance',
        ),
      ];
    }
    return [];
  }

  List<SymbolSearchResult> _searchFiat(String query) {
    const currencies = {
      'USD': 'US Dollar',
      'CHF': 'Schweizer Franken',
      'GBP': 'Britisches Pfund',
      'JPY': 'Japanischer Yen',
      'CAD': 'Kanadischer Dollar',
      'AUD': 'Australischer Dollar',
      'SEK': 'Schwedische Krone',
      'NOK': 'Norwegische Krone',
      'DKK': 'Dänische Krone',
      'PLN': 'Polnischer Zloty',
      'CZK': 'Tschechische Krone',
      'HUF': 'Ungarischer Forint',
      'TRY': 'Türkische Lira',
      'CNY': 'Chinesischer Yuan',
      'INR': 'Indische Rupie',
      'BRL': 'Brasilianischer Real',
      'MXN': 'Mexikanischer Peso',
      'ZAR': 'Südafrikanischer Rand',
      'SGD': 'Singapur-Dollar',
      'HKD': 'Hongkong-Dollar',
      'NZD': 'Neuseeland-Dollar',
      'KRW': 'Südkoreanischer Won',
      'THB': 'Thailändischer Baht',
    };
    final q = query.toUpperCase();
    return currencies.entries
        .where((e) =>
            e.key.contains(q) ||
            e.value.toUpperCase().contains(q))
        .map((e) => SymbolSearchResult(
              symbol: e.key,
              name: e.value,
              type: 'Fiat',
            ))
        .toList();
  }

  void dispose() {
    stopLiveStreams();
    _livePriceController.close();
    _coinGecko.dispose();
    _yahoo.dispose();
  }
}
