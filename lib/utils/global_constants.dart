import 'dart:collection';

import 'package:flutter/material.dart';

import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xfin/providers/theme_provider.dart';

Stopwatch stopwatch = Stopwatch();

// Values from Shared Preferences
int filterStartDate = 0;
int filterEndDate = 99999999;
bool isBaseCurrencySelected = false;
String? baseCurrencyTickerSymbol;

class PrefKeys {
  static const String filterStartDate = 'filterStartDate'; // stored as yyyyMMdd or "0"
  static const String filterEndDate = 'filterEndDate'; // stored as yyyyMMdd or "99999999"
  static const String isBaseCurrencySelected = 'isBaseCurrencySelected';
  static const String baseCurrencyTickerSymbol = 'baseCurrencyTickerSymbol';
}

Future<void> loadPrefs() async {
  final prefs = await SharedPreferences.getInstance();
  filterStartDate = prefs.getInt(PrefKeys.filterStartDate) ?? 0;
  filterEndDate = prefs.getInt(PrefKeys.filterEndDate) ?? 99999999;
  isBaseCurrencySelected = prefs.getBool(PrefKeys.isBaseCurrencySelected) ?? false;
  baseCurrencyTickerSymbol = prefs.getString(PrefKeys.baseCurrencyTickerSymbol);
}

double normalize(num value) {
  const int decimals = 12; // globally consistent, high precision
  const double epsilon = 1e-12; // treat anything below as zero

  if (value.abs() < epsilon) return 0.0;
  return double.parse(value.toStringAsFixed(decimals));
}

void showToast2(String msg) {
  final isDark = ThemeProvider.isDark();

  Fluttertoast.showToast(
    msg: msg,
    toastLength: Toast.LENGTH_SHORT,
    gravity: ToastGravity.BOTTOM,
    backgroundColor: isDark ? Colors.white : Colors.black,
    textColor: isDark ? Colors.black : Colors.white,
    fontSize: 14,
  );
}

String preciseDecimal(double d) {
  if (d.isNaN) return 'NaN';
  if (d == double.infinity) return 'Infinity';
  if (d == double.negativeInfinity) return '-Infinity';

  // Use 12 fractional digits (safe for double precision)
  final s = d.toStringAsPrecision(12);

  // Remove trailing zeros and an optional trailing decimal point:
  // - If the string ends with ".000..." it becomes just the integer part.
  // - If there are meaningful fractional digits they are preserved.
  return s.replaceFirst(RegExp(r'\.?0+$'), '').replaceAll('.', ',');
}

int cmpKey(int dtA, String typeA, int idA, int dtB, String typeB, int idB) {
  if (dtA != dtB) return dtA < dtB ? -1 : 1;
  final tc = typeA.compareTo(typeB);
  if (tc != 0) return tc < 0 ? -1 : 1;
  if (idA != idB) return idA < idB ? -1 : 1;
  return 0;
}

(double, double) consumeFiFo(ListQueue<Map<String, double>> fifo, shares) {
  double consumedValue = 0, consumedFee = 0;
  while (shares > 0 && fifo.isNotEmpty) {
    final currentLot = fifo.first;
    final lotShares = currentLot['shares']!;
    final lotCostBasis = currentLot['costBasis']!;
    final lotFee = currentLot['fee'] ?? 0.0;

    if (lotShares <= shares + 1e-12) {
      consumedValue -= lotShares * lotCostBasis;
      consumedFee -= lotFee;
      shares -= lotShares;
      fifo.removeFirst();
    } else {
      consumedValue -= shares * lotCostBasis;
      consumedFee -= (shares / lotShares) * lotFee;
      currentLot['shares'] = lotShares - shares;
      currentLot['fee'] = lotFee - (shares / lotShares) * lotFee;
      shares = 0;
    }
  }

  return (consumedValue, consumedFee);
}

class CategoryAutocompleteHelper {
  final List<String> _categories;
  final int maxResults;

  CategoryAutocompleteHelper(
    List<String> categories, {
    this.maxResults = 6,
  }) : _categories = categories;

  Iterable<String> suggestions(String query) {
    final q = query.toLowerCase().trim();
    if (q.isEmpty) return const [];

    int score(String c) {
      final lc = c.toLowerCase();

      if (lc == q) return 0; // exact match
      if (lc.startsWith(q)) return 1; // prefix match

      // word prefix match (e.g. "ins" → "Health Insurance")
      final words = lc.split(RegExp(r'\s+'));
      if (words.any((w) => w.startsWith(q))) return 2;

      if (lc.contains(q)) return 3; // substring match
      return 999;
    }

    final matches =
        _categories.where((c) => c.toLowerCase().contains(q)).toList();

    matches.sort((a, b) {
      final sa = score(a);
      final sb = score(b);
      if (sa != sb) return sa.compareTo(sb);
      return a.compareTo(b); // stable fallback
    });

    return matches.take(maxResults);
  }
}
