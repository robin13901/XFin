double normalize(num value) {
  const int decimals = 12;      // globally consistent, high precision
  const double epsilon = 1e-12; // treat anything below as zero

  if (value.abs() < epsilon) return 0.0;
  return double.parse(value.toStringAsFixed(decimals));
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