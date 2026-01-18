import 'package:flutter_test/flutter_test.dart';
import 'package:xfin/utils/format.dart';

void main() {
  group('formatPercent', () {
    test('formats percent with one decimal and de_DE style', () {
      // 0.12345 -> 12.345% -> rounded/displayed as 12,3 %
      expect(formatPercent(0.12345), '12,3 %');
    });

    test('zero percent', () {
      expect(formatPercent(0.0), '0,0 %');
    });
  });
}