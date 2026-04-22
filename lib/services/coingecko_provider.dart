import 'dart:convert';

import 'package:http/http.dart' as http;

import 'price_provider.dart';

class CoinGeckoProvider implements RestPriceProvider, SymbolSearchProvider {
  static const _baseUrl = 'https://api.coingecko.com/api/v3';
  final http.Client _client;

  CoinGeckoProvider({http.Client? client}) : _client = client ?? http.Client();

  @override
  Future<Map<String, double>> getCurrentPrices(
      List<String> identifiers, String baseCurrency) async {
    if (identifiers.isEmpty) return {};

    final ids = identifiers.join(',');
    final currency = baseCurrency.toLowerCase();
    final uri =
        Uri.parse('$_baseUrl/simple/price?ids=$ids&vs_currencies=$currency');

    final response = await _client.get(uri);
    if (response.statusCode != 200) return {};

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final prices = <String, double>{};
    for (final entry in data.entries) {
      final priceData = entry.value as Map<String, dynamic>?;
      final price = (priceData?[currency] as num?)?.toDouble();
      if (price != null) {
        prices[entry.key] = price;
      }
    }
    return prices;
  }

  @override
  Future<Map<int, double>> getHistoricalDailyPrices(
      String identifier, DateTime from, DateTime to, String baseCurrency) async {
    final fromTs = from.millisecondsSinceEpoch ~/ 1000;
    final toTs = to.millisecondsSinceEpoch ~/ 1000;
    final currency = baseCurrency.toLowerCase();
    final uri = Uri.parse(
        '$_baseUrl/coins/$identifier/market_chart/range?vs_currency=$currency&from=$fromTs&to=$toTs');

    final response = await _client.get(uri);
    if (response.statusCode != 200) return {};

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final pricesList = data['prices'] as List<dynamic>?;
    if (pricesList == null) return {};

    final prices = <int, double>{};
    for (final point in pricesList) {
      final list = point as List<dynamic>;
      final timestamp = (list[0] as num).toInt();
      final price = (list[1] as num).toDouble();
      final dt = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final dateKey = dt.year * 10000 + dt.month * 100 + dt.day;
      prices[dateKey] = price;
    }
    return prices;
  }

  @override
  Future<List<SymbolSearchResult>> search(String query) async {
    final uri = Uri.parse('$_baseUrl/search?query=$query');
    final response = await _client.get(uri);
    if (response.statusCode != 200) return [];

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final coins = data['coins'] as List<dynamic>?;
    if (coins == null) return [];

    return coins.take(10).map((c) {
      final item = c as Map<String, dynamic>;
      return SymbolSearchResult(
        symbol: item['id'] as String? ?? '',
        name: item['name'] as String? ?? '',
        type: 'crypto',
      );
    }).toList();
  }

  void dispose() {
    _client.close();
  }
}
