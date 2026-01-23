import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:xfin/utils/global_constants.dart';


class BaseCurrencyProvider with ChangeNotifier {
  static String symbol = '€';
  String? _tickerSymbol = 'EUR';
  final int _assetId = 1;

  String? get tickerSymbol => _tickerSymbol;
  int get assetId => _assetId;

  Future<void> initialize(Locale locale) async {
    _tickerSymbol = baseCurrencyTickerSymbol;
    if (_tickerSymbol != null) {
      final format = NumberFormat.simpleCurrency(name: _tickerSymbol);
      symbol = format.currencySymbol;
      notifyListeners();
    }
  }

}