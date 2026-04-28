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
    for (final req in _activeRequests) {
      if (!_isStreaming) return;
      try {
        final yahooSymbol = _toYahooSymbol(req);
        final price = await _yahoo.getCurrentPrice(yahooSymbol);
        if (price != null) {
          _livePriceController.add({req.assetId: price});
        } else if (req.assetType == AssetTypes.crypto) {
          final cgPrices = await _coinGecko.getCurrentPrices(
              [req.apiIdentifier], _baseCurrency);
          final cgPrice = cgPrices[req.apiIdentifier];
          if (cgPrice != null) {
            _livePriceController.add({req.assetId: cgPrice});
          }
        }
      } catch (e) {
        debugPrint('Live fetch error for ${req.apiIdentifier}: $e');
      }
    }
  }

  String _toYahooSymbol(AssetPriceRequest req) {
    final id = req.apiIdentifier;

    if (req.assetType == AssetTypes.crypto) {
      final ticker = _cryptoIdToTicker(id);
      return '$ticker-${_baseCurrency.toUpperCase()}';
    }

    // Non-crypto: if it already looks like a Yahoo symbol, use as-is
    if (id.contains('.') || id.contains('-')) return id;

    switch (req.assetType) {
      case AssetTypes.crypto:
        throw StateError('unreachable');
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
      'binancecoin': 'BNB',
      'tether': 'USDT',
      'usd-coin': 'USDC',
      'polygon-ecosystem-token': 'POL',
      'matic-network': 'MATIC',
      'pi-network': 'PI',
      'turbo-eth': 'TURBO',
      'ethena-usde': 'USDE',
      'internet-computer': 'ICP',
      'render-token': 'RENDER',
      'fetch-ai': 'FET',
      'injective-protocol': 'INJ',
      'arbitrum': 'ARB',
      'optimism': 'OP',
      'aave': 'AAVE',
      'maker': 'MKR',
      'the-graph': 'GRT',
      'filecoin': 'FIL',
      'monero': 'XMR',
      'aptos': 'APT',
      'mantle': 'MNT',
      'kaspa': 'KAS',
      'fantom': 'FTM',
      'algorand': 'ALGO',
      'theta-token': 'THETA',
      'vechain': 'VET',
      'eos': 'EOS',
      'dai': 'DAI',
      'lido-dao': 'LDO',
      'bonk': 'BONK',
      'floki': 'FLOKI',
      'worldcoin-wld': 'WLD',
      'jupiter-exchange-solana': 'JUP',
      'ondo-finance': 'ONDO',
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
    final prices =
        await _yahoo.getHistoricalDailyPrices(yahooSymbol, from, to, baseCurrency);
    if (prices.isNotEmpty) return prices;

    // Fallback: CoinGecko for crypto assets using the original CoinGecko ID
    if (request.assetType == AssetTypes.crypto) {
      debugPrint('Yahoo empty for $yahooSymbol, trying CoinGecko: ${request.apiIdentifier}');
      return _coinGecko.getHistoricalDailyPrices(
          request.apiIdentifier, from, to, baseCurrency);
    }
    return prices;
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
        return _yahoo.search(query);
      case AssetTypes.fiat:
        return _searchFiat(query);
    }
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
