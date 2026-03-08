import 'package:flutter_test/flutter_test.dart';

import 'package:xfin/utils/timeframe_helper.dart';

void main() {
  group('getMonthStartEnd', () {
    test('returns correct range for a regular month', () {
      final (start, end) = getMonthStartEnd(DateTime(2024, 3, 15));
      expect(start, 20240301);
      expect(end, 20240331);
    });

    test('returns correct range for February in a leap year', () {
      final (start, end) = getMonthStartEnd(DateTime(2024, 2, 10));
      expect(start, 20240201);
      expect(end, 20240229);
    });

    test('returns correct range for February in a non-leap year', () {
      final (start, end) = getMonthStartEnd(DateTime(2023, 2, 10));
      expect(start, 20230201);
      expect(end, 20230228);
    });

    test('returns correct range for December (year boundary)', () {
      final (start, end) = getMonthStartEnd(DateTime(2024, 12, 25));
      expect(start, 20241201);
      expect(end, 20241231);
    });

    test('returns correct range for January', () {
      final (start, end) = getMonthStartEnd(DateTime(2024, 1, 1));
      expect(start, 20240101);
      expect(end, 20240131);
    });

    test('returns correct range for April (30-day month)', () {
      final (start, end) = getMonthStartEnd(DateTime(2024, 4, 20));
      expect(start, 20240401);
      expect(end, 20240430);
    });
  });

  group('getMonthTimeframeIntersection', () {
    test('returns full month range when filter fully contains the month', () {
      // Filter: all of 2024, month: March 2024
      final result = getMonthTimeframeIntersection(
        DateTime(2024, 3, 15),
        filterStart: 20240101,
        filterEnd: 20241231,
      );
      expect(result, isNotNull);
      expect(result!.$1, 20240301);
      expect(result.$2, 20240331);
    });

    test('returns null when month is entirely before filter range', () {
      // Filter: Feb-Dec 2024, month: January 2024
      final result = getMonthTimeframeIntersection(
        DateTime(2024, 1, 15),
        filterStart: 20240201,
        filterEnd: 20241231,
      );
      expect(result, isNull);
    });

    test('returns null when month is entirely after filter range', () {
      // Filter: Jan-Feb 2024, month: March 2024
      final result = getMonthTimeframeIntersection(
        DateTime(2024, 3, 15),
        filterStart: 20240101,
        filterEnd: 20240228,
      );
      expect(result, isNull);
    });

    test('returns partial overlap when filter starts mid-month', () {
      // Filter starts Jan 15, month: January 2024
      final result = getMonthTimeframeIntersection(
        DateTime(2024, 1, 10),
        filterStart: 20240115,
        filterEnd: 20241231,
      );
      expect(result, isNotNull);
      expect(result!.$1, 20240115); // effective start is filter start
      expect(result.$2, 20240131); // effective end is month end
    });

    test('returns partial overlap when filter ends mid-month', () {
      // Filter ends Mar 15, month: March 2024
      final result = getMonthTimeframeIntersection(
        DateTime(2024, 3, 20),
        filterStart: 20240101,
        filterEnd: 20240315,
      );
      expect(result, isNotNull);
      expect(result!.$1, 20240301); // effective start is month start
      expect(result.$2, 20240315); // effective end is filter end
    });

    test('returns full month with default-like unrestricted range', () {
      // Filter: 0 to 99999999 (the app default)
      final result = getMonthTimeframeIntersection(
        DateTime(2024, 6, 10),
        filterStart: 0,
        filterEnd: 99999999,
      );
      expect(result, isNotNull);
      expect(result!.$1, 20240601);
      expect(result.$2, 20240630);
    });

    test('handles filter range exactly matching one month', () {
      final result = getMonthTimeframeIntersection(
        DateTime(2024, 3, 15),
        filterStart: 20240301,
        filterEnd: 20240331,
      );
      expect(result, isNotNull);
      expect(result!.$1, 20240301);
      expect(result.$2, 20240331);
    });

    test('handles single-day filter within the month', () {
      final result = getMonthTimeframeIntersection(
        DateTime(2024, 3, 15),
        filterStart: 20240315,
        filterEnd: 20240315,
      );
      expect(result, isNotNull);
      expect(result!.$1, 20240315);
      expect(result.$2, 20240315);
    });
  });

  group('monthStartDateTimeInt', () {
    test('converts date integer to start-of-day datetime integer', () {
      expect(monthStartDateTimeInt(20240301), 20240301000000);
    });

    test('converts first day of year', () {
      expect(monthStartDateTimeInt(20240101), 20240101000000);
    });

    test('converts last day of year', () {
      expect(monthStartDateTimeInt(20241231), 20241231000000);
    });
  });

  group('monthEndDateTimeInt', () {
    test('converts date integer to end-of-day datetime integer', () {
      expect(monthEndDateTimeInt(20240331), 20240331235959);
    });

    test('converts first day of year', () {
      expect(monthEndDateTimeInt(20240101), 20240101235959);
    });

    test('converts last day of year', () {
      expect(monthEndDateTimeInt(20241231), 20241231235959);
    });
  });
}
