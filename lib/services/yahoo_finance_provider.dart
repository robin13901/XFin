import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'price_provider.dart';

class YahooFinanceProvider implements RestPriceProvider {
  static const _baseUrl = 'https://query1.finance.yahoo.com/v8/finance/chart';
  static const _searchUrl = 'https://query1.finance.yahoo.com/v1/finance/search';
  final http.Client _client;

  YahooFinanceProvider({http.Client? client})
      : _client = client ?? http.Client();

  Future<double?> getCurrentPrice(String symbol) async {
    try {
      final uri = Uri.parse('$_baseUrl/$symbol?interval=1d&range=1d');
      final response = await _client
          .get(uri)
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        debugPrint('Yahoo: $symbol returned ${response.statusCode}');
        return null;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final result = (data['chart']?['result'] as List?)?.firstOrNull
          as Map<String, dynamic>?;
      if (result == null) return null;

      final meta = result['meta'] as Map<String, dynamic>?;
      return (meta?['regularMarketPrice'] as num?)?.toDouble();
    } catch (e) {
      debugPrint('Yahoo price error for $symbol: $e');
      return null;
    }
  }

  @override
  Future<Map<String, double>> getCurrentPrices(
      List<String> identifiers, String baseCurrency) async {
    final prices = <String, double>{};
    // Yahoo v8 doesn't support batch — call sequentially but fast
    for (final symbol in identifiers) {
      final price = await getCurrentPrice(symbol);
      if (price != null) prices[symbol] = price;
    }
    return prices;
  }

  @override
  Future<Map<int, double>> getHistoricalDailyPrices(
      String identifier, DateTime from, DateTime to, String baseCurrency) async {
    try {
      final fromTs = from.millisecondsSinceEpoch ~/ 1000;
      final toTs = to.millisecondsSinceEpoch ~/ 1000;
      final uri = Uri.parse(
          '$_baseUrl/$identifier?interval=1d&period1=$fromTs&period2=$toTs');
      final response = await _client
          .get(uri)
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return {};

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final result = (data['chart']?['result'] as List?)?.firstOrNull
          as Map<String, dynamic>?;
      if (result == null) return {};

      final timestamps = result['timestamp'] as List<dynamic>?;
      final quotes =
          (result['indicators']?['quote'] as List?)?.firstOrNull
              as Map<String, dynamic>?;
      final closes = quotes?['close'] as List<dynamic>?;

      if (timestamps == null || closes == null) return {};

      final prices = <int, double>{};
      for (int i = 0; i < timestamps.length && i < closes.length; i++) {
        final ts = (timestamps[i] as num).toInt();
        final close = closes[i];
        if (close == null) continue;
        final dt = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
        final dateKey = dt.year * 10000 + dt.month * 100 + dt.day;
        prices[dateKey] = (close as num).toDouble();
      }
      return prices;
    } catch (e) {
      debugPrint('Yahoo historical error for $identifier: $e');
      return {};
    }
  }

  Future<List<SymbolSearchResult>> search(String query) async {
    try {
      final uri = Uri.parse(
          '$_searchUrl?q=${Uri.encodeComponent(query)}&quotesCount=10&newsCount=0');
      final response = await _client
          .get(uri)
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return [];

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final quotes = data['quotes'] as List<dynamic>?;
      if (quotes == null || quotes.isEmpty) return [];

      return quotes.map((q) {
        final item = q as Map<String, dynamic>;
        final symbol = item['symbol'] as String? ?? '';
        final name = item['longname'] as String? ??
            item['shortname'] as String? ??
            symbol;
        final exchange = item['exchange'] as String?;
        final quoteType = item['quoteType'] as String?;
        return SymbolSearchResult(
          symbol: symbol,
          name: name,
          exchange: exchange,
          type: quoteType,
        );
      }).toList();
    } catch (e) {
      debugPrint('Yahoo search error: $e');
      return [];
    }
  }

  void dispose() {
    _client.close();
  }
}
