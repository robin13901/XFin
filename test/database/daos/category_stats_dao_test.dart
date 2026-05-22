import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:xfin/database/app_database.dart';
import 'package:xfin/database/daos/analysis_dao.dart';
import 'package:xfin/database/tables.dart';

/// Inserts a single Booking row with the minimum required fields.
Future<void> _insertBooking(
  AppDatabase db, {
  required int dateInt,
  required String category,
  required double value,
  bool isGenerated = false,
  bool excludeFromAverage = false,
}) async {
  await db.into(db.bookings).insert(BookingsCompanion.insert(
        date: dateInt,
        accountId: 1,
        category: category,
        shares: value,
        value: value,
        isGenerated: Value(isGenerated),
        excludeFromAverage: Value(excludeFromAverage),
      ));
}

void main() {
  late AppDatabase db;
  late AnalysisDao dao;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase(NativeDatabase.memory());
    dao = db.analysisDao;

    // Base currency asset (id=1) — required by Bookings.assetId default.
    await db.into(db.assets).insert(AssetsCompanion.insert(
          name: 'EUR',
          type: AssetTypes.fiat,
          tickerSymbol: 'EUR',
        ));
    // One account so accountId references resolve.
    await db.into(db.accounts).insert(AccountsCompanion.insert(
          name: 'Test',
          type: AccountTypes.cash,
          initialBalance: const Value(0),
        ));
  });

  tearDown(() async {
    await db.close();
  });

  group('AnalysisDao.getCategoryStats', () {
    test('returns empty stats when no bookings exist for the category',
        () async {
      final stats = await dao.getCategoryStats('Salary');

      expect(stats.category, 'Salary');
      expect(stats.totalCount, 0);
      expect(stats.totalSum, 0);
      expect(stats.monthlyBuckets, isEmpty);
      expect(stats.dailyBuckets, isEmpty);
      expect(stats.earliestBookingDate, isNull);
    });

    test('returns aggregated totals for a category', () async {
      await _insertBooking(db,
          dateInt: 20240115, category: 'Salary', value: 1000.0);
      await _insertBooking(db,
          dateInt: 20240215, category: 'Salary', value: 1100.0);
      await _insertBooking(db,
          dateInt: 20240315, category: 'Salary', value: 1200.0);
      // Different category - must not pollute results
      await _insertBooking(db,
          dateInt: 20240115, category: 'Rent', value: -500.0);

      final stats = await dao.getCategoryStats('Salary');

      expect(stats.totalCount, 3);
      expect(stats.totalSum, 3300.0);
    });

    test('groups multiple bookings on the same day into one daily bucket',
        () async {
      await _insertBooking(db,
          dateInt: 20240115, category: 'Food', value: -10.0);
      await _insertBooking(db,
          dateInt: 20240115, category: 'Food', value: -25.0);
      await _insertBooking(db,
          dateInt: 20240116, category: 'Food', value: -7.5);

      final stats = await dao.getCategoryStats('Food');

      expect(stats.dailyBuckets.length, 2);
      expect(stats.dailyBuckets[20240115]!.count, 2);
      expect(stats.dailyBuckets[20240115]!.sum, -35.0);
      expect(stats.dailyBuckets[20240116]!.count, 1);
      expect(stats.dailyBuckets[20240116]!.sum, -7.5);
    });

    test('aggregates per-month and fills gap months with zero buckets',
        () async {
      // January and March, but no February
      await _insertBooking(db,
          dateInt: 20230110, category: 'Salary', value: 100.0);
      await _insertBooking(db,
          dateInt: 20230320, category: 'Salary', value: 200.0);

      final stats = await dao.getCategoryStats('Salary');

      // Find the February bucket — must exist with count=0, sum=0.
      final feb = stats.monthlyBuckets
          .where((b) => b.year == 2023 && b.month == 2)
          .toList();
      expect(feb.length, 1);
      expect(feb.first.count, 0);
      expect(feb.first.sum, 0.0);

      final jan = stats.monthlyBuckets
          .firstWhere((b) => b.year == 2023 && b.month == 1);
      expect(jan.count, 1);
      expect(jan.sum, 100.0);

      final mar = stats.monthlyBuckets
          .firstWhere((b) => b.year == 2023 && b.month == 3);
      expect(mar.count, 1);
      expect(mar.sum, 200.0);
    });

    test('monthlyBuckets extends from earliest booking month to current month',
        () async {
      // Booking 12 months ago and now should produce 12+ contiguous buckets.
      final now = DateTime.now();
      final twoMonthsAgo = DateTime(now.year, now.month - 2, 5);
      final oldDateInt =
          twoMonthsAgo.year * 10000 + twoMonthsAgo.month * 100 + twoMonthsAgo.day;
      final nowDateInt = now.year * 10000 + now.month * 100 + 1;

      await _insertBooking(db,
          dateInt: oldDateInt, category: 'C', value: 1.0);
      await _insertBooking(db,
          dateInt: nowDateInt, category: 'C', value: 2.0);

      final stats = await dao.getCategoryStats('C');

      // First bucket = month of oldest booking, last bucket = current month.
      expect(stats.monthlyBuckets.first.year, twoMonthsAgo.year);
      expect(stats.monthlyBuckets.first.month, twoMonthsAgo.month);
      expect(stats.monthlyBuckets.last.year, now.year);
      expect(stats.monthlyBuckets.last.month, now.month);
      // 3 contiguous months: -2, -1, 0
      expect(stats.monthlyBuckets.length, greaterThanOrEqualTo(3));
    });

    test('excludes generated bookings (from periodic templates)', () async {
      await _insertBooking(db,
          dateInt: 20240101, category: 'Salary', value: 1000.0);
      await _insertBooking(
        db,
        dateInt: 20240201,
        category: 'Salary',
        value: 1000.0,
        isGenerated: true,
      );

      final stats = await dao.getCategoryStats('Salary');

      expect(stats.totalCount, 1);
      expect(stats.totalSum, 1000.0);
    });

    test('earliestBookingDate equals the actual day of the earliest booking',
        () async {
      await _insertBooking(db,
          dateInt: 20240520, category: 'Test', value: 1.0);
      await _insertBooking(db,
          dateInt: 20240310, category: 'Test', value: 1.0);
      await _insertBooking(db,
          dateInt: 20240805, category: 'Test', value: 1.0);

      final stats = await dao.getCategoryStats('Test');

      expect(stats.earliestBookingDate, DateTime(2024, 3, 10));
    });

    test('handles a single-day single-booking category', () async {
      await _insertBooking(db,
          dateInt: 20240315, category: 'OneOff', value: 42.5);

      final stats = await dao.getCategoryStats('OneOff');

      expect(stats.totalCount, 1);
      expect(stats.totalSum, 42.5);
      expect(stats.dailyBuckets.length, 1);
      expect(stats.dailyBuckets[20240315]!.sum, 42.5);
      // Earliest is march, current is at least march → at least 1 bucket
      expect(stats.monthlyBuckets, isNotEmpty);
      expect(stats.monthlyBuckets.first.year, 2024);
      expect(stats.monthlyBuckets.first.month, 3);
    });

    test('handles negative-value bookings (outflows) without abs collapsing',
        () async {
      await _insertBooking(db,
          dateInt: 20240115, category: 'Rent', value: -800.0);
      await _insertBooking(db,
          dateInt: 20240215, category: 'Rent', value: -800.0);

      final stats = await dao.getCategoryStats('Rent');

      expect(stats.totalCount, 2);
      expect(stats.totalSum, -1600.0);
      // Histogram code uses .abs() on the value side; the DAO must not.
      expect(stats.monthlyBuckets
              .where((b) => b.count > 0)
              .every((b) => b.sum < 0),
          true);
    });

    test('different categories do not bleed into each other', () async {
      await _insertBooking(db,
          dateInt: 20240115, category: 'A', value: 100.0);
      await _insertBooking(db,
          dateInt: 20240115, category: 'B', value: 200.0);
      await _insertBooking(db,
          dateInt: 20240215, category: 'A', value: 300.0);

      final statsA = await dao.getCategoryStats('A');
      final statsB = await dao.getCategoryStats('B');

      expect(statsA.totalSum, 400.0);
      expect(statsA.totalCount, 2);
      expect(statsB.totalSum, 200.0);
      expect(statsB.totalCount, 1);
    });
  });
}
