import 'dart:convert';

import 'package:http/http.dart' as http;

import 'price_provider.dart';

class FrankfurterProvider implements RestPriceProvider {
  static const _baseUrl = 'https://api.frankfurter.dev';
  final http.Client _client;

  FrankfurterProvider({http.Client? client})
      : _client = client ?? http.Client();

  @override
  Future<Map<String, double>> getCurrentPrices(
      List<String> identifiers, String baseCurrency) async {
    if (identifiers.isEmpty) return {};

    final to = identifiers.join(',');
    final uri =
        Uri.parse('$_baseUrl/latest?from=${baseCurrency.toUpperCase()}&to=$to');

    final response = await _client.get(uri);
    if (response.statusCode != 200) return {};

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final rates = data['rates'] as Map<String, dynamic>?;
    if (rates == null) return {};

    final prices = <String, double>{};
    for (final entry in rates.entries) {
      final rate = (entry.value as num?)?.toDouble();
      if (rate != null && rate > 0) {
        prices[entry.key] = 1.0 / rate;
      }
    }
    return prices;
  }

  Future<double?> getExchangeRate(String from, String to) async {
    final uri =
        Uri.parse('$_baseUrl/latest?from=${from.toUpperCase()}&to=${to.toUpperCase()}');
    final response = await _client.get(uri);
    if (response.statusCode != 200) return null;

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final rates = data['rates'] as Map<String, dynamic>?;
    return (rates?[to.toUpperCase()] as num?)?.toDouble();
  }

  @override
  Future<Map<int, double>> getHistoricalDailyPrices(
      String identifier, DateTime from, DateTime to, String baseCurrency) async {
    final startDate =
        '${from.year}-${from.month.toString().padLeft(2, '0')}-${from.day.toString().padLeft(2, '0')}';
    final endDate =
        '${to.year}-${to.month.toString().padLeft(2, '0')}-${to.day.toString().padLeft(2, '0')}';
    final uri = Uri.parse(
        '$_baseUrl/$startDate..$endDate?from=${identifier.toUpperCase()}&to=${baseCurrency.toUpperCase()}');

    final response = await _client.get(uri);
    if (response.statusCode != 200) return {};

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final rates = data['rates'] as Map<String, dynamic>?;
    if (rates == null) return {};

    final prices = <int, double>{};
    for (final entry in rates.entries) {
      final parts = entry.key.split('-');
      if (parts.length >= 3) {
        final dateKey = int.parse(parts[0]) * 10000 +
            int.parse(parts[1]) * 100 +
            int.parse(parts[2]);
        final rateMap = entry.value as Map<String, dynamic>?;
        final rate =
            (rateMap?[baseCurrency.toUpperCase()] as num?)?.toDouble();
        if (rate != null) {
          prices[dateKey] = rate;
        }
      }
    }
    return prices;
  }

  void dispose() {
    _client.close();
  }
}
