import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:xfin/utils/indicator_calculator.dart';

void main() {
  List<FlSpot> buildSpots(List<double> values) =>
      List.generate(values.length, (i) => FlSpot(i.toDouble(), values[i]));

  group('IndicatorCalculator.calculateSma', () {
    test('returns empty when not enough data', () {
      final data = buildSpots([1.0, 2.0]);
      expect(IndicatorCalculator.calculateSma(data, 3), isEmpty);
    });

    test('period 1 returns original values aligned to last index of window', () {
      final values = [2.0, 4.0, 6.0];
      final data = buildSpots(values);
      final sma = IndicatorCalculator.calculateSma(data, 1);
      // For period 1 SMA should be each value, x is the same index (i + period -1 = i)
      expect(sma.length, values.length);
      for (var i = 0; i < values.length; i++) {
        expect(sma[i].x, data[i].x);
        expect(sma[i].y, closeTo(values[i], 1e-12));
      }
    });

    test('computes correct SMA for simple dataset', () {
      // data values: [1, 2, 3, 4]; period 2 -> SMA points: for windows [1,2]=1.5 at x=1, [2,3]=2.5 at x=2, [3,4]=3.5 at x=3
      final data = buildSpots([1.0, 2.0, 3.0, 4.0]);
      final sma = IndicatorCalculator.calculateSma(data, 2);
      expect(sma.length, 3);
      expect(sma[0].x, 1.0);
      expect(sma[0].y, closeTo(1.5, 1e-12));
      expect(sma[1].x, 2.0);
      expect(sma[1].y, closeTo(2.5, 1e-12));
      expect(sma[2].x, 3.0);
      expect(sma[2].y, closeTo(3.5, 1e-12));
    });

    test('SMA length equals data.length - period + 1', () {
      const n = 7;
      const p = 3;
      final data = buildSpots(List.generate(n, (i) => i.toDouble()));
      final sma = IndicatorCalculator.calculateSma(data, p);
      expect(sma.length, n - p + 1);
    });
  });

  group('IndicatorCalculator.calculateEma', () {
    test('returns empty when not enough data', () {
      final data = buildSpots([10.0, 20.0]);
      expect(IndicatorCalculator.calculateEma(data, 3), isEmpty);
    });

    test('period 1 behaves as identity series (first point + subsequent equal to data)', () {
      final values = [5.0, 15.0, 25.0];
      final data = buildSpots(values);
      final ema = IndicatorCalculator.calculateEma(data, 1);
      // EMA for period 1: multiplier=1, initialSMA=data[0], then subsequent points equal to data[i]
      expect(ema.length, values.length);
      expect(ema[0].x, data[0].x);
      expect(ema[0].y, closeTo(5.0, 1e-12));
      for (var i = 1; i < values.length; i++) {
        expect(ema[i].x, data[i].x);
        expect(ema[i].y, closeTo(values[i], 1e-12));
      }
    });

    test('computes EMA correctly for a small dataset', () {
      // Use dataset [10, 11, 12, 13, 14], period=3
      // initial SMA = (10+11+12)/3 = 11 -> first EMA at x=2 is 11
      // multiplier = 2/(3+1) = 0.5
      // next EMA (for value 13): (13 - 11)*0.5 + 11 = 12
      // next EMA (for value 14): (14 - 12)*0.5 + 12 = 13
      final data = buildSpots([10.0, 11.0, 12.0, 13.0, 14.0]);
      final ema = IndicatorCalculator.calculateEma(data, 3);
      expect(ema.length, 3); // indices 2,3,4
      expect(ema[0].x, 2.0);
      expect(ema[0].y, closeTo(11.0, 1e-12));
      expect(ema[1].x, 3.0);
      expect(ema[1].y, closeTo(12.0, 1e-12));
      expect(ema[2].x, 4.0);
      expect(ema[2].y, closeTo(13.0, 1e-12));
    });

    test('EMA length equals data.length - period + 1', () {
      const n = 10;
      const p = 4;
      final data = buildSpots(List.generate(n, (i) => i.toDouble() + 1.0));
      final ema = IndicatorCalculator.calculateEma(data, p);
      expect(ema.length, n - p + 1);
    });
  });

  group('IndicatorCalculator.calculateBb (Bollinger Bands)', () {
    test('returns empty when not enough data', () {
      final data = buildSpots([1.0, 2.0]);
      expect(IndicatorCalculator.calculateBb(data, 3), isEmpty);
    });

    test('produces three bands with correct lengths and ordering', () {
      // Simple dataset with period 2:
      // data: [1, 3] -> SMA for window ending at index1 = 2.0
      // stdDev = sqrt(((1-2)^2 + (3-2)^2) / 2) = 1
      // upper = 2 + 2*1 = 4, lower = 2 - 2*1 = 0
      final data = buildSpots([1.0, 3.0]);
      final bands = IndicatorCalculator.calculateBb(data, 2);
      // Should return 3 LineChartBarData entries (upper, middle, lower)
      expect(bands.length, 3);

      final upper = bands[0].spots;
      final middle = bands[1].spots;
      final lower = bands[2].spots;

      // lengths should match SMA length = data.length - period + 1 = 1
      expect(upper.length, 1);
      expect(middle.length, 1);
      expect(lower.length, 1);

      // Check x positions and numeric relationships
      expect(middle[0].x, 1.0);
      expect(middle[0].y, closeTo(2.0, 1e-12));
      expect(upper[0].y, closeTo(4.0, 1e-12));
      expect(lower[0].y, closeTo(0.0, 1e-12));
      expect(upper[0].y > middle[0].y, isTrue);
      expect(middle[0].y > lower[0].y, isTrue);
    });

    test('bands lengths equal SMA length for larger sample', () {
      final values = List<double>.generate(6, (i) => (i + 1) * 1.0); // 1..6
      final data = buildSpots(values);
      const p = 3;
      final bands = IndicatorCalculator.calculateBb(data, p);
      final expectedLen = values.length - p + 1;
      expect(bands[0].spots.length, expectedLen);
      expect(bands[1].spots.length, expectedLen);
      expect(bands[2].spots.length, expectedLen);
    });

    test('upper - middle equals middle - lower (symmetry) for symmetric data', () {
      // Create symmetric windows around mean to test symmetry property.
      // For window [1,3] mean=2, upper=4, lower=0 as before.
      final data = buildSpots([1.0, 3.0, 1.0, 3.0]); // two windows of [1,3]
      final bands = IndicatorCalculator.calculateBb(data, 2);

      for (var i = 0; i < bands[1].spots.length; i++) {
        final u = bands[0].spots[i].y;
        final m = bands[1].spots[i].y;
        final l = bands[2].spots[i].y;
        expect(u - m, closeTo(m - l, 1e-12));
      }
    });
  });
}