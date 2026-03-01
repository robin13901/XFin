import 'package:flutter_test/flutter_test.dart';
import 'package:xfin/database/tables.dart';
import 'package:xfin/utils/cycles_helper.dart';

void main() {
  group('CyclesHelper', () {
    group('monthlyFactorForCycle', () {
      test('returns correct factor for daily cycle', () {
        final factor = CyclesHelper.monthlyFactorForCycle(Cycles.daily);
        expect(factor, 30.436875);
      });

      test('returns correct factor for weekly cycle', () {
        final factor = CyclesHelper.monthlyFactorForCycle(Cycles.weekly);
        expect(factor, closeTo(30.436875 / 7, 0.0001));
        expect(factor, closeTo(4.348125, 0.0001));
      });

      test('returns correct factor for monthly cycle', () {
        final factor = CyclesHelper.monthlyFactorForCycle(Cycles.monthly);
        expect(factor, 1.0);
      });

      test('returns correct factor for quarterly cycle', () {
        final factor = CyclesHelper.monthlyFactorForCycle(Cycles.quarterly);
        expect(factor, closeTo(1.0 / 3.0, 0.0001));
        expect(factor, closeTo(0.333333, 0.0001));
      });

      test('returns correct factor for yearly cycle', () {
        final factor = CyclesHelper.monthlyFactorForCycle(Cycles.yearly);
        expect(factor, closeTo(1.0 / 12.0, 0.0001));
        expect(factor, closeTo(0.083333, 0.0001));
      });

      test('all cycle types are covered', () {
        // Ensure all Cycles enum values can be passed without error
        for (final cycle in Cycles.values) {
          expect(
            () => CyclesHelper.monthlyFactorForCycle(cycle),
            returnsNormally,
          );
        }
      });

      test('factors maintain expected relationships', () {
        final daily = CyclesHelper.monthlyFactorForCycle(Cycles.daily);
        final weekly = CyclesHelper.monthlyFactorForCycle(Cycles.weekly);
        final monthly = CyclesHelper.monthlyFactorForCycle(Cycles.monthly);
        final quarterly = CyclesHelper.monthlyFactorForCycle(Cycles.quarterly);
        final yearly = CyclesHelper.monthlyFactorForCycle(Cycles.yearly);

        // Daily > Weekly > Monthly > Quarterly > Yearly
        expect(daily > weekly, true);
        expect(weekly > monthly, true);
        expect(monthly > quarterly, true);
        expect(quarterly > yearly, true);

        // Weekly should be daily divided by 7
        expect(weekly, closeTo(daily / 7, 0.0001));

        // Quarterly should be monthly divided by 3
        expect(quarterly, closeTo(monthly / 3, 0.0001));

        // Yearly should be monthly divided by 12
        expect(yearly, closeTo(monthly / 12, 0.0001));
      });

      test('converts daily amount to monthly correctly', () {
        const dailyAmount = 10.0;
        final factor = CyclesHelper.monthlyFactorForCycle(Cycles.daily);
        final monthlyAmount = dailyAmount * factor;

        // 10 EUR per day * 30.436875 days/month ≈ 304.37 EUR/month
        expect(monthlyAmount, closeTo(304.36875, 0.0001));
      });

      test('converts yearly amount to monthly correctly', () {
        const yearlyAmount = 1200.0;
        final factor = CyclesHelper.monthlyFactorForCycle(Cycles.yearly);
        final monthlyAmount = yearlyAmount * factor;

        // 1200 EUR per year * (1/12) = 100 EUR/month
        expect(monthlyAmount, closeTo(100.0, 0.0001));
      });
    });
  });
}
