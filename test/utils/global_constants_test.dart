// test/global_constants_test.dart
import 'dart:collection';

import 'package:flutter_test/flutter_test.dart';
import 'package:xfin/utils/global_constants.dart';

void main() {
  group('normalize', () {
    test('treats very small numbers as zero', () {
      expect(normalize(1e-13), 0.0);
      expect(normalize(-1e-13), 0.0);
    });

    test('rounds to 12 decimals', () {
      const v = 1.234567890123456;
      // toStringAsFixed(12) -> '1.234567890123'
      expect(normalize(v), 1.234567890123);
    });
  });

  group('formatPercent', () {
    test('formats percent with one decimal and de_DE style', () {
      // 0.12345 -> 12.345% -> rounded/displayed as 12,3 %
      expect(formatPercent(0.12345), '12,3 %');
    });

    test('zero percent', () {
      expect(formatPercent(0.0), '0,0 %');
    });
  });

  group('preciseDecimal', () {
    test('handles NaN and infinities', () {
      expect(preciseDecimal(double.nan), 'NaN');
      expect(preciseDecimal(double.infinity), 'Infinity');
      expect(preciseDecimal(double.negativeInfinity), '-Infinity');
    });

    test('returns comma as decimal separator and removes trailing zeros', () {
      // 1234.5 -> "1234,5"
      expect(preciseDecimal(1234.5), '1234,5');

      // value that would have trailing zeros after formatting
      const v = 1.230000;
      // toStringAsPrecision(12) will produce '1.23' and replace '.'->',' => '1,23'
      expect(preciseDecimal(v), '1,23');
    });
  });

  group('cmpKey', () {
    test('compares by dt, then type, then id', () {
      // equal dt
      expect(cmpKey(1, 'A', 1, 1, 'A', 1), 0);

      // dt differs
      expect(cmpKey(1, 'A', 1, 2, 'A', 1) < 0, true);
      expect(cmpKey(3, 'A', 1, 2, 'A', 1) > 0, true);

      // type compare if dt equal
      expect(cmpKey(1, 'A', 1, 1, 'B', 1) < 0, true);
      expect(cmpKey(1, 'C', 1, 1, 'B', 1) > 0, true);

      // id compare if dt and type equal
      expect(cmpKey(1, 'A', 1, 1, 'A', 2) < 0, true);
      expect(cmpKey(1, 'A', 3, 1, 'A', 2) > 0, true);
    });
  });

  group('consumeFiFo', () {
    test('consumes FIFO lots correctly and returns consumed value & fee', () {
      final fifo = ListQueue<Map<String, double>>();
      fifo.add({
        'shares': 2.0,
        'costBasis': 10.0,
        'fee': 1.0,
      });
      fifo.add({
        'shares': 3.0,
        'costBasis': 20.0,
        'fee': 2.0,
      });

      // consume 4 shares: consumes entire first lot (2 @ 10) and 2 from second lot (2 @ 20)
      final (consumedValue, consumedFee) = consumeFiFo(fifo, 4.0);

      // consumedValue uses negative convention in the function
      // expected: -(2*10) - (2*20) = -20 - 40 = -60
      expect(consumedValue, closeTo(-60.0, 1e-9));

      // consumedFee: -(1) - (2 * (2/3)) = -1 - 1.333333... = -2.3333333...
      expect(consumedFee, closeTo(-2.333333333333333, 1e-9));

      // fifo should have remaining lot reduced: second lot should now have 1.0 shares left
      expect(fifo.length, 1);
      expect(fifo.first['shares']!, closeTo(1.0, 1e-9));
    });

    test('consumes partial lot when shares less than first lot', () {
      final fifo = ListQueue<Map<String, double>>();
      fifo.add({'shares': 5.0, 'costBasis': 7.0, 'fee': 1.5});

      final (consumedValue, consumedFee) = consumeFiFo(fifo, 2.0);

      // consumedValue: -(2 * 7) = -14
      expect(consumedValue, closeTo(-14.0, 1e-9));

      // consumedFee: -(2/5 * 1.5) = -0.6
      expect(consumedFee, closeTo(-0.6, 1e-9));

      // fifo should still contain the lot with shares reduced to 3.0
      expect(fifo.length, 1);
      expect(fifo.first['shares']!, closeTo(3.0, 1e-9));
    });
  });

  group('CategoryAutocompleteHelper', () {
    final categories = [
      'Rent',
      'Restaurant',
      'Real Estate',
      'Car Repair',
      'Health Insurance',
      'Insurance',
      'Groceries',
      'Car Rental',
      'Car Wash'
    ];
    final helper = CategoryAutocompleteHelper(categories, maxResults: 5);

    test('empty query returns empty list', () {
      expect(helper.suggestions(''), isEmpty);
      expect(helper.suggestions('   '), isEmpty);
    });

    test('case-insensitive and prefix/word-prefix ranking', () {
      // exact match should be first
      final exact = helper.suggestions('rent').toList();
      expect(exact, isNotEmpty);
      expect(exact.first, 'Rent');

      // prefix: 're' should return items that start with 're' before contains
      final re = helper.suggestions('re').toList();
      // should contain at least these three (order: by score then alpha)
      expect(re, containsAll(<String>['Rent', 'Real Estate', 'Restaurant'] as Iterable<String>));

      // word-prefix: 'ins' should prefer 'Insurance' (prefix) over 'Health Insurance' (word-prefix)
      final ins = helper.suggestions('ins').toList();
      expect(ins.first, 'Insurance');
      expect(ins, contains('Health Insurance'));
    });

    test('limits results to maxResults', () {
      final r = helper.suggestions('c').toList();
      // there are multiple 'Car ...' entries; ensure we don't return more than maxResults
      expect(r.length <= 5, true);
    });

    test('stable alphabetical fallback for same scores', () {
      // two items starting with 'car ' will have same score for query 'car'
      final carHelper = CategoryAutocompleteHelper(['Car A', 'Car B', 'Car C'], maxResults: 10);
      final res = carHelper.suggestions('car').toList();
      // alphabetical order expected since all scores equal: 'Car A', 'Car B', 'Car C'
      expect(res, ['Car A', 'Car B', 'Car C']);
    });
  });
}