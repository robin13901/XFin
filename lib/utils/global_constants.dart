import 'dart:collection';

import 'package:intl/intl.dart';

double normalize(num value) {
  const int decimals = 12;      // globally consistent, high precision
  const double epsilon = 1e-12; // treat anything below as zero

  if (value.abs() < epsilon) return 0.0;
  return double.parse(value.toStringAsFixed(decimals));
}

final percentFormat = NumberFormat.decimalPattern('de_DE')
  ..minimumFractionDigits = 1
  ..maximumFractionDigits = 1;

String formatPercent(double value) {
  return '${percentFormat.format(value * 100)} %';
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