import 'dart:convert';

import 'package:http/http.dart' as http;

import 'price_provider.dart';

class TwelveDataProvider implements RestPriceProvider, SymbolSearchProvider {
  static const _baseUrl = 'https://api.twelvedata.com';
  final String apiKey;
  final http.Client _client;

  TwelveDataProvider({required this.apiKey, http.Client? client})
      : _client = client ?? http.Client();

  @override
  Future<Map<String, double>> getCurrentPrices(
      List<String> identifiers, String baseCurrency) async {
    if (identifiers.isEmpty || apiKey.isEmpty) return {};

    final symbols = identifiers.join(',');
    final uri =
        Uri.parse('$_baseUrl/price?symbol=$symbols&apikey=$apiKey');

    final response = await _client.get(uri);
    if (response.statusCode != 200) return {};

    final data = jsonDecode(response.body);
    final prices = <String, double>{};

    if (data is Map<String, dynamic>) {
      if (data.containsKey('price')) {
        final price = double.tryParse(data['price']?.toString() ?? '');
        if (price != null && identifiers.length == 1) {
          prices[identifiers.first] = price;
        }
      } else {
        for (final entry in data.entries) {
          final val = entry.value as Map<String, dynamic>?;
          final price = double.tryParse(val?['price']?.toString() ?? '');
          if (price != null) {
            prices[entry.key] = price;
          }
        }
      }
    }
    return prices;
  }

  @override
  Future<Map<int, double>> getHistoricalDailyPrices(
      String identifier, DateTime from, DateTime to, String baseCurrency) async {
    if (apiKey.isEmpty) return {};

    final startDate =
        '${from.year}-${from.month.toString().padLeft(2, '0')}-${from.day.toString().padLeft(2, '0')}';
    final endDate =
        '${to.year}-${to.month.toString().padLeft(2, '0')}-${to.day.toString().padLeft(2, '0')}';
    final uri = Uri.parse(
        '$_baseUrl/time_series?symbol=$identifier&interval=1day&start_date=$startDate&end_date=$endDate&apikey=$apiKey');

    final response = await _client.get(uri);
    if (response.statusCode != 200) return {};

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final values = data['values'] as List<dynamic>?;
    if (values == null) return {};

    final prices = <int, double>{};
    for (final point in values) {
      final map = point as Map<String, dynamic>;
      final dateStr = map['datetime'] as String?;
      final close = double.tryParse(map['close']?.toString() ?? '');
      if (dateStr != null && close != null) {
        final parts = dateStr.split('-');
        if (parts.length >= 3) {
          final dateKey = int.parse(parts[0]) * 10000 +
              int.parse(parts[1]) * 100 +
              int.parse(parts[2]);
          prices[dateKey] = close;
        }
      }
    }
    return prices;
  }

  @override
  Future<List<SymbolSearchResult>> search(String query) async {
    if (apiKey.isEmpty) return [];

    final uri =
        Uri.parse('$_baseUrl/symbol_search?symbol=$query&apikey=$apiKey');
    final response = await _client.get(uri);
    if (response.statusCode != 200) return [];

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final results = data['data'] as List<dynamic>?;
    if (results == null) return [];

    return results.take(10).map((r) {
      final item = r as Map<String, dynamic>;
      return SymbolSearchResult(
        symbol: item['symbol'] as String? ?? '',
        name: item['instrument_name'] as String? ?? '',
        exchange: item['exchange'] as String?,
        type: item['instrument_type'] as String?,
      );
    }).toList();
  }

  void dispose() {
    _client.close();
  }
}
