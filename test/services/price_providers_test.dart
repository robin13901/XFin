import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:xfin/services/coingecko_provider.dart';
import 'package:xfin/services/frankfurter_provider.dart';
import 'package:xfin/services/twelve_data_provider.dart';

void main() {
  group('CoinGeckoProvider', () {
    test('getCurrentPrices parses response correctly', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'bitcoin': {'eur': 42000.5},
            'ethereum': {'eur': 2800.0},
          }),
          200,
        );
      });

      final provider = CoinGeckoProvider(client: mockClient);
      final prices =
          await provider.getCurrentPrices(['bitcoin', 'ethereum'], 'EUR');

      expect(prices['bitcoin'], 42000.5);
      expect(prices['ethereum'], 2800.0);
      provider.dispose();
    });

    test('getCurrentPrices returns empty on error', () async {
      final mockClient = MockClient((request) async {
        return http.Response('', 500);
      });

      final provider = CoinGeckoProvider(client: mockClient);
      final prices =
          await provider.getCurrentPrices(['bitcoin'], 'EUR');

      expect(prices, isEmpty);
      provider.dispose();
    });

    test('getCurrentPrices returns empty for empty identifiers', () async {
      final mockClient = MockClient((request) async {
        return http.Response('{}', 200);
      });

      final provider = CoinGeckoProvider(client: mockClient);
      final prices = await provider.getCurrentPrices([], 'EUR');
      expect(prices, isEmpty);
      provider.dispose();
    });

    test('getHistoricalDailyPrices parses time series', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'prices': [
              [1704067200000, 42000.0],
              [1704153600000, 43000.0],
            ],
          }),
          200,
        );
      });

      final provider = CoinGeckoProvider(client: mockClient);
      final prices = await provider.getHistoricalDailyPrices(
        'bitcoin',
        DateTime(2024, 1, 1),
        DateTime(2024, 1, 2),
        'EUR',
      );

      expect(prices.length, 2);
      provider.dispose();
    });

    test('search parses coin results', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'coins': [
              {
                'id': 'bitcoin',
                'name': 'Bitcoin',
                'symbol': 'BTC',
              }
            ],
          }),
          200,
        );
      });

      final provider = CoinGeckoProvider(client: mockClient);
      final results = await provider.search('bitcoin');

      expect(results.length, 1);
      expect(results[0].symbol, 'bitcoin');
      expect(results[0].name, 'Bitcoin');
      provider.dispose();
    });
  });

  group('TwelveDataProvider', () {
    test('getCurrentPrices parses single symbol', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({'price': '185.50'}),
          200,
        );
      });

      final provider =
          TwelveDataProvider(apiKey: 'test', client: mockClient);
      final prices =
          await provider.getCurrentPrices(['AAPL'], 'USD');

      expect(prices['AAPL'], 185.5);
      provider.dispose();
    });

    test('getCurrentPrices parses multiple symbols', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'AAPL': {'price': '185.50'},
            'MSFT': {'price': '380.00'},
          }),
          200,
        );
      });

      final provider =
          TwelveDataProvider(apiKey: 'test', client: mockClient);
      final prices =
          await provider.getCurrentPrices(['AAPL', 'MSFT'], 'USD');

      expect(prices['AAPL'], 185.5);
      expect(prices['MSFT'], 380.0);
      provider.dispose();
    });

    test('getCurrentPrices returns empty without API key', () async {
      final provider = TwelveDataProvider(apiKey: '');
      final prices =
          await provider.getCurrentPrices(['AAPL'], 'USD');
      expect(prices, isEmpty);
      provider.dispose();
    });

    test('getHistoricalDailyPrices parses time series', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'values': [
              {'datetime': '2024-01-02', 'close': '185.50'},
              {'datetime': '2024-01-01', 'close': '180.00'},
            ],
          }),
          200,
        );
      });

      final provider =
          TwelveDataProvider(apiKey: 'test', client: mockClient);
      final prices = await provider.getHistoricalDailyPrices(
        'AAPL',
        DateTime(2024, 1, 1),
        DateTime(2024, 1, 2),
        'USD',
      );

      expect(prices[20240101], 180.0);
      expect(prices[20240102], 185.5);
      provider.dispose();
    });

    test('search parses symbol results', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'data': [
              {
                'symbol': 'AAPL',
                'instrument_name': 'Apple Inc.',
                'exchange': 'NASDAQ',
                'instrument_type': 'Common Stock',
              }
            ],
          }),
          200,
        );
      });

      final provider =
          TwelveDataProvider(apiKey: 'test', client: mockClient);
      final results = await provider.search('Apple');

      expect(results.length, 1);
      expect(results[0].symbol, 'AAPL');
      expect(results[0].name, 'Apple Inc.');
      expect(results[0].exchange, 'NASDAQ');
      provider.dispose();
    });
  });

  group('FrankfurterProvider', () {
    test('getCurrentPrices parses forex rates', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'rates': {'USD': 1.08, 'CHF': 0.95},
          }),
          200,
        );
      });

      final provider = FrankfurterProvider(client: mockClient);
      final prices =
          await provider.getCurrentPrices(['USD', 'CHF'], 'EUR');

      expect(prices['USD'], closeTo(0.926, 0.001));
      expect(prices['CHF'], closeTo(1.053, 0.001));
      provider.dispose();
    });

    test('getExchangeRate returns correct rate', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'rates': {'EUR': 0.92},
          }),
          200,
        );
      });

      final provider = FrankfurterProvider(client: mockClient);
      final rate = await provider.getExchangeRate('USD', 'EUR');

      expect(rate, 0.92);
      provider.dispose();
    });

    test('getHistoricalDailyPrices parses time series', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'rates': {
              '2024-01-01': {'EUR': 0.92},
              '2024-01-02': {'EUR': 0.91},
            },
          }),
          200,
        );
      });

      final provider = FrankfurterProvider(client: mockClient);
      final prices = await provider.getHistoricalDailyPrices(
        'USD',
        DateTime(2024, 1, 1),
        DateTime(2024, 1, 2),
        'EUR',
      );

      expect(prices[20240101], 0.92);
      expect(prices[20240102], 0.91);
      provider.dispose();
    });

    test('getCurrentPrices returns empty for empty identifiers', () async {
      final provider = FrankfurterProvider();
      final prices = await provider.getCurrentPrices([], 'EUR');
      expect(prices, isEmpty);
      provider.dispose();
    });
  });
}
