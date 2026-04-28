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
      String query, AssetTypes assetType, {String locale = 'en'}) async {
    switch (assetType) {
      case AssetTypes.crypto:
        return _coinGecko.search(query);
      case AssetTypes.stock:
      case AssetTypes.etf:
      case AssetTypes.fund:
      case AssetTypes.derivative:
        return _yahoo.search(query);
      case AssetTypes.fiat:
        return _searchFiat(query, locale);
    }
  }

  List<SymbolSearchResult> _searchFiat(String query, String locale) {
    final names = locale == 'de' ? _currencyNamesDe : _currencyNamesEn;
    final q = query.toUpperCase();
    return names.entries
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

  static const _currencyNamesEn = {
    // Major
    'USD': 'US Dollar',
    'CHF': 'Swiss Franc',
    'GBP': 'British Pound',
    'JPY': 'Japanese Yen',
    'CAD': 'Canadian Dollar',
    'AUD': 'Australian Dollar',
    // Europe
    'SEK': 'Swedish Krona',
    'NOK': 'Norwegian Krone',
    'DKK': 'Danish Krone',
    'PLN': 'Polish Zloty',
    'CZK': 'Czech Koruna',
    'HUF': 'Hungarian Forint',
    'RON': 'Romanian Leu',
    'BGN': 'Bulgarian Lev',
    'HRK': 'Croatian Kuna',
    'RSD': 'Serbian Dinar',
    'ISK': 'Icelandic Króna',
    'GEL': 'Georgian Lari',
    'UAH': 'Ukrainian Hryvnia',
    'RUB': 'Russian Ruble',
    'MDL': 'Moldovan Leu',
    'ALL': 'Albanian Lek',
    'MKD': 'North Macedonian Denar',
    'BAM': 'Bosnian Convertible Mark',
    // Middle East & Africa
    'TRY': 'Turkish Lira',
    'ILS': 'Israeli Shekel',
    'AED': 'UAE Dirham',
    'SAR': 'Saudi Riyal',
    'QAR': 'Qatari Riyal',
    'KWD': 'Kuwaiti Dinar',
    'BHD': 'Bahraini Dinar',
    'OMR': 'Omani Rial',
    'JOD': 'Jordanian Dinar',
    'EGP': 'Egyptian Pound',
    'MAD': 'Moroccan Dirham',
    'TND': 'Tunisian Dinar',
    'DZD': 'Algerian Dinar',
    'LYD': 'Libyan Dinar',
    'ZAR': 'South African Rand',
    'NGN': 'Nigerian Naira',
    'KES': 'Kenyan Shilling',
    'TZS': 'Tanzanian Shilling',
    'GHS': 'Ghanaian Cedi',
    'GHC': 'Ghanaian Cedi (old)',
    // Asia & Pacific
    'CNY': 'Chinese Yuan',
    'INR': 'Indian Rupee',
    'SGD': 'Singapore Dollar',
    'HKD': 'Hong Kong Dollar',
    'NZD': 'New Zealand Dollar',
    'KRW': 'South Korean Won',
    'THB': 'Thai Baht',
    'TWD': 'Taiwan Dollar',
    'MYR': 'Malaysian Ringgit',
    'IDR': 'Indonesian Rupiah',
    'PHP': 'Philippine Peso',
    'VND': 'Vietnamese Dong',
    'PKR': 'Pakistani Rupee',
    'BDT': 'Bangladeshi Taka',
    'LKR': 'Sri Lankan Rupee',
    // Americas
    'BRL': 'Brazilian Real',
    'MXN': 'Mexican Peso',
    'ARS': 'Argentine Peso',
    'CLP': 'Chilean Peso',
    'COP': 'Colombian Peso',
    'PEN': 'Peruvian Sol',
    'UYU': 'Uruguayan Peso',
    // Historical (Euro predecessors)
    'DEM': 'German Mark',
    'FRF': 'French Franc',
    'ITL': 'Italian Lira',
    'ESP': 'Spanish Peseta',
    'NLG': 'Dutch Guilder',
    'ATS': 'Austrian Schilling',
    'BEF': 'Belgian Franc',
    'FIM': 'Finnish Markka',
    'GRD': 'Greek Drachma',
    'IEP': 'Irish Pound',
    'PTE': 'Portuguese Escudo',
    'LUF': 'Luxembourgish Franc',
    'EEK': 'Estonian Kroon',
    'LVL': 'Latvian Lats',
    'LTL': 'Lithuanian Litas',
    'SKK': 'Slovak Koruna',
    'SIT': 'Slovenian Tolar',
    'CYP': 'Cypriot Pound',
    'MTL': 'Maltese Lira',
  };

  static const _currencyNamesDe = {
    // Major
    'USD': 'US Dollar',
    'CHF': 'Schweizer Franken',
    'GBP': 'Britisches Pfund',
    'JPY': 'Japanischer Yen',
    'CAD': 'Kanadischer Dollar',
    'AUD': 'Australischer Dollar',
    // Europe
    'SEK': 'Schwedische Krone',
    'NOK': 'Norwegische Krone',
    'DKK': 'Dänische Krone',
    'PLN': 'Polnischer Zloty',
    'CZK': 'Tschechische Krone',
    'HUF': 'Ungarischer Forint',
    'RON': 'Rumänischer Leu',
    'BGN': 'Bulgarischer Lew',
    'HRK': 'Kroatische Kuna',
    'RSD': 'Serbischer Dinar',
    'ISK': 'Isländische Krone',
    'GEL': 'Georgischer Lari',
    'UAH': 'Ukrainische Hrywnja',
    'RUB': 'Russischer Rubel',
    'MDL': 'Moldauischer Leu',
    'ALL': 'Albanischer Lek',
    'MKD': 'Nordmazedonischer Denar',
    'BAM': 'Bosnische Konvertible Mark',
    // Middle East & Africa
    'TRY': 'Türkische Lira',
    'ILS': 'Israelischer Schekel',
    'AED': 'VAE-Dirham',
    'SAR': 'Saudi-Riyal',
    'QAR': 'Katar-Riyal',
    'KWD': 'Kuwaitischer Dinar',
    'BHD': 'Bahrain-Dinar',
    'OMR': 'Omanischer Rial',
    'JOD': 'Jordanischer Dinar',
    'EGP': 'Ägyptisches Pfund',
    'MAD': 'Marokkanischer Dirham',
    'TND': 'Tunesischer Dinar',
    'DZD': 'Algerischer Dinar',
    'LYD': 'Libyscher Dinar',
    'ZAR': 'Südafrikanischer Rand',
    'NGN': 'Nigerianischer Naira',
    'KES': 'Kenianischer Schilling',
    'TZS': 'Tansanischer Schilling',
    'GHS': 'Ghanaischer Cedi',
    'GHC': 'Ghanaischer Cedi (alt)',
    // Asia & Pacific
    'CNY': 'Chinesischer Yuan',
    'INR': 'Indische Rupie',
    'SGD': 'Singapur-Dollar',
    'HKD': 'Hongkong-Dollar',
    'NZD': 'Neuseeland-Dollar',
    'KRW': 'Südkoreanischer Won',
    'THB': 'Thailändischer Baht',
    'TWD': 'Taiwanesischer Dollar',
    'MYR': 'Malaysischer Ringgit',
    'IDR': 'Indonesische Rupiah',
    'PHP': 'Philippinischer Peso',
    'VND': 'Vietnamesischer Dong',
    'PKR': 'Pakistanische Rupie',
    'BDT': 'Bangladeschischer Taka',
    'LKR': 'Sri-Lanka-Rupie',
    // Americas
    'BRL': 'Brasilianischer Real',
    'MXN': 'Mexikanischer Peso',
    'ARS': 'Argentinischer Peso',
    'CLP': 'Chilenischer Peso',
    'COP': 'Kolumbianischer Peso',
    'PEN': 'Peruanischer Sol',
    'UYU': 'Uruguayischer Peso',
    // Historical (Euro-Vorgänger)
    'DEM': 'Deutsche Mark',
    'FRF': 'Französischer Franc',
    'ITL': 'Italienische Lira',
    'ESP': 'Spanische Peseta',
    'NLG': 'Niederländischer Gulden',
    'ATS': 'Österreichischer Schilling',
    'BEF': 'Belgischer Franc',
    'FIM': 'Finnische Mark',
    'GRD': 'Griechische Drachme',
    'IEP': 'Irisches Pfund',
    'PTE': 'Portugiesischer Escudo',
    'LUF': 'Luxemburgischer Franc',
    'EEK': 'Estnische Krone',
    'LVL': 'Lettischer Lats',
    'LTL': 'Litauischer Litas',
    'SKK': 'Slowakische Krone',
    'SIT': 'Slowenischer Tolar',
    'CYP': 'Zyprisches Pfund',
    'MTL': 'Maltesische Lira',
  };

  void dispose() {
    stopLiveStreams();
    _livePriceController.close();
    _coinGecko.dispose();
    _yahoo.dispose();
  }
}
