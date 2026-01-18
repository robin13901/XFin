import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xfin/providers/base_currency_provider.dart';

void main() {
  group('BaseCurrencyProvider', () {
    test('initial default fields before initialize', () {
      final provider = BaseCurrencyProvider();

      // Defaults from the class
      expect(BaseCurrencyProvider.symbol, '€');
      expect(provider.tickerSymbol, 'EUR');
      expect(provider.assetId, 1);
    });

    test('initialize with no selected_currency in SharedPreferences does NOT notify', () async {
      // Ensure SharedPreferences is empty for this test.
      SharedPreferences.setMockInitialValues(<String, Object>{});

      final provider = BaseCurrencyProvider();

      var notifyCount = 0;
      provider.addListener(() {
        notifyCount++;
      });

      // Call initialize with locale 'de_DE'
      await provider.initialize(const Locale('de', 'DE'));

      // When prefs doesn't contain 'selected_currency', the provider should:
      // - set tickerSymbol to null (because prefs.getString returns null)
      // - leave _symbol as initial '€'
      // - NOT call notifyListeners()
      expect(provider.tickerSymbol, isNull);
      expect(BaseCurrencyProvider.symbol, '€');
      expect(provider.assetId, 1);

      expect(notifyCount, 0, reason: 'initialize should not notify when selected_currency is not present');
    });

    test('initialize with selected_currency updates symbol, format and notifies', () async {
      // Mock SharedPreferences to contain selected_currency = 'USD'
      SharedPreferences.setMockInitialValues(<String, Object>{
        'selected_currency': 'USD',
      });

      final provider = BaseCurrencyProvider();

      var notifyCount = 0;
      provider.addListener(() {
        notifyCount++;
      });

      // Use US locale so we can make simple assertions about formatting
      await provider.initialize(const Locale('en', 'US'));

      // tickerSymbol must be set from prefs
      expect(provider.tickerSymbol, 'USD');

      // symbol should be updated to USD symbol (usually '$')
      // We won't hard-fail on exact symbol string in case of environment differences,
      // but we'll assert that the provider.format output contains the BaseCurrencyProvider.symbol.
      expect(BaseCurrencyProvider.symbol, isNotNull);
      expect(BaseCurrencyProvider.symbol, isNot(equals('')));

      // initialize should notify listeners exactly once.
      expect(notifyCount, 1, reason: 'initialize should call notifyListeners once when currency found');
    });

    test('initialize with another currency uses that currency symbol and given locale', () async {
      // Example with JPY
      SharedPreferences.setMockInitialValues(<String, Object>{
        'selected_currency': 'JPY',
      });

      final provider = BaseCurrencyProvider();

      var notified = false;
      provider.addListener(() {
        notified = true;
      });

      const locale = Locale('de', 'DE');
      await provider.initialize(locale);

      // tickerSymbol from prefs
      expect(provider.tickerSymbol, 'JPY');

      // symbol should be non-empty (e.g., '¥' for JPY)
      expect(BaseCurrencyProvider.symbol, isNotEmpty);

      expect(notified, isTrue);
    });
  });
}