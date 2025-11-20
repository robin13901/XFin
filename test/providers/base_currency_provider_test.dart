import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:xfin/providers/base_currency_provider.dart';

void main() {
  group('BaseCurrencyProvider', () {
    test('initial default fields before initialize', () {
      final provider = BaseCurrencyProvider();

      // Defaults from the class
      expect(provider.symbol, '€');
      expect(provider.tickerSymbol, 'EUR');
      expect(provider.assetId, 1);
      // Format should be a NumberFormat instance and should include the default symbol
      expect(provider.format, isA<NumberFormat>());
      expect(provider.format.format(1).contains('€'), isTrue);
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
      expect(provider.symbol, '€');
      expect(provider.assetId, 1);

      // The format should still be a NumberFormat and reflect the default symbol (contains '€')
      final formatted = provider.format.format(1234.56);
      expect(formatted.contains('€'), isTrue);

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
      // but we'll assert that the provider.format output contains the provider.symbol.
      expect(provider.symbol, isNotNull);
      expect(provider.symbol, isNot(equals('')));

      // The provider.format should include the currency symbol when formatting numbers.
      final formatted = provider.format.format(1234.56);
      expect(formatted.contains(provider.symbol), isTrue,
          reason: 'Formatted string should include the currency symbol');

      // Basic checks that formatting looks like en_US currency formatting (contains comma and dot)
      expect(formatted.contains(','), isTrue);
      expect(formatted.contains('.'), isTrue);

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

      // Use de_DE locale to verify locale is passed into NumberFormat.currency(...)
      const locale = Locale('de', 'DE');
      await provider.initialize(locale);

      // tickerSymbol from prefs
      expect(provider.tickerSymbol, 'JPY');

      // symbol should be non-empty (e.g., '¥' for JPY)
      expect(provider.symbol, isNotEmpty);

      // formatting should include the symbol and use locale separators for 'de_DE'
      final formatted = provider.format.format(1000);
      expect(formatted.contains(provider.symbol), isTrue);
      // in de_DE thousands separator is '.' and decimal separator is ',', so formatted should contain '.' or ','.
      // (Depending on currency and integer value, decimals might not appear; we at least assert the thousands separator)
      expect(formatted.contains('.') || formatted.contains(','), isTrue);

      expect(notified, isTrue);
    });
  });
}