import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';


class BaseCurrencyProvider with ChangeNotifier {
  static String symbol = '€';
  String? _tickerSymbol = 'EUR';
  final int _assetId = 1;

  String? get tickerSymbol => _tickerSymbol;
  int get assetId => _assetId;

  Future<void> initialize(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    _tickerSymbol = prefs.getString('selected_currency');
    if (_tickerSymbol != null) {
      final format = NumberFormat.simpleCurrency(name: _tickerSymbol);
      symbol = format.currencySymbol;
      notifyListeners();
    }
  }

}