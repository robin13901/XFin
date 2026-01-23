import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:xfin/providers/base_currency_provider.dart';
import 'package:xfin/utils/global_constants.dart' as globals;

void main() {
  late String? origTicker;

  setUp(() {
    origTicker = globals.baseCurrencyTickerSymbol;
    // ensure known defaults
    globals.baseCurrencyTickerSymbol = 'EUR';
    BaseCurrencyProvider.symbol = '€';
  });

  tearDown(() {
    globals.baseCurrencyTickerSymbol = origTicker;
  });

  test('defaults', () {
    final p = BaseCurrencyProvider();
    expect(p.tickerSymbol, 'EUR');
    expect(p.assetId, 1);
    expect(BaseCurrencyProvider.symbol, '€');
  });

  test('initialize sets ticker, symbol and notifies when ticker present', () async {
    globals.baseCurrencyTickerSymbol = 'USD';
    final p = BaseCurrencyProvider();
    var notified = false;
    p.addListener(() => notified = true);

    await p.initialize(const Locale('en'));

    expect(p.tickerSymbol, 'USD');
    expect(BaseCurrencyProvider.symbol, NumberFormat.simpleCurrency(name: 'USD').currencySymbol);
    expect(notified, isTrue);
  });

  test('initialize with null ticker leaves symbol and does not notify', () async {
    globals.baseCurrencyTickerSymbol = null;
    BaseCurrencyProvider.symbol = '€';
    final p = BaseCurrencyProvider();
    var notified = false;
    p.addListener(() => notified = true);

    await p.initialize(const Locale('en'));

    expect(p.tickerSymbol, isNull);
    expect(BaseCurrencyProvider.symbol, '€');
    expect(notified, isFalse);
  });
}