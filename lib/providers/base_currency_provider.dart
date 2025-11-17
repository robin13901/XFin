import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';


class BaseCurrencyProvider with ChangeNotifier {
  String _symbol = '€';
  String? _tickerSymbol = 'EUR';
  final int _assetId = 1;
  NumberFormat _format = NumberFormat.currency(locale: 'de_DE', symbol: '€');

  String get symbol => _symbol;
  String? get tickerSymbol => _tickerSymbol;
  int get assetId => _assetId;
  NumberFormat get format => _format;

  Future<void> initialize(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    _tickerSymbol = prefs.getString('selected_currency');
    if (_tickerSymbol != null) {
      final format = NumberFormat.simpleCurrency(name: _tickerSymbol);
      _symbol = format.currencySymbol;
      _format = NumberFormat.currency(locale: locale.toString(), symbol: _symbol);
      notifyListeners();
    }
  }

}