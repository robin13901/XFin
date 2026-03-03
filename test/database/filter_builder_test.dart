import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xfin/database/app_database.dart';
import 'package:xfin/database/filter_builder.dart';
import 'package:xfin/database/tables.dart';
import 'package:xfin/models/filter/filter_rule.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());

    // Insert base currency asset
    await db.into(db.assets).insert(AssetsCompanion.insert(
          name: 'EUR',
          type: AssetTypes.fiat,
          tickerSymbol: 'EUR',
        ));

    // Insert test account
    await db.into(db.accounts).insert(AccountsCompanion.insert(
          name: 'Test Account',
          type: AccountTypes.cash,
        ));

    // Insert test bookings
    await db.into(db.bookings).insert(BookingsCompanion.insert(
          date: 20240101,
          shares: 100.0,
          value: 100.0,
          category: 'Salary',
          accountId: 1,
          assetId: const Value(1),
        ));

    await db.into(db.bookings).insert(BookingsCompanion.insert(
          date: 20240115,
          shares: -50.0,
          value: -50.0,
          category: 'Groceries',
          accountId: 1,
          assetId: const Value(1),
          notes: const Value('Weekly shopping'),
        ));

    await db.into(db.bookings).insert(BookingsCompanion.insert(
          date: 20240201,
          shares: 200.0,
          value: 200.0,
          category: 'Freelance',
          accountId: 1,
          assetId: const Value(1),
        ));
  });

  tearDown(() async {
    await db.close();
  });

  group('BookingFilterBuilder', () {
    test('buildExpression returns null for empty rules', () {
      final builder = BookingFilterBuilder(db.bookings);
      final expr = builder.buildExpression([]);
      expect(expr, equals(null));
    });

    test('numeric greaterThan filter works', () async {
      final rules = [
        const FilterRule(
          fieldId: 'value',
          operator: FilterOperator.greaterThan,
          value: 50.0,
        ),
      ];

      final results = await db.bookingsDao.watchBookingsPage(
        limit: 100,
        filterRules: rules,
      ).first;

      expect(results.length, 2);
      expect(results.every((r) => r.booking.value > 50), isTrue);
    });

    test('numeric lessThan filter works', () async {
      final rules = [
        const FilterRule(
          fieldId: 'value',
          operator: FilterOperator.lessThan,
          value: 150.0,
        ),
      ];

      final results = await db.bookingsDao.watchBookingsPage(
        limit: 100,
        filterRules: rules,
      ).first;

      expect(results.length, 2);
      expect(results.every((r) => r.booking.value < 150), isTrue);
    });

    test('numeric between filter works', () async {
      final rules = [
        const FilterRule(
          fieldId: 'value',
          operator: FilterOperator.between,
          value: [50.0, 150.0],
        ),
      ];

      final results = await db.bookingsDao.watchBookingsPage(
        limit: 100,
        filterRules: rules,
      ).first;

      expect(results.length, 1);
      expect(results.first.booking.value, 100.0);
    });

    test('text contains filter works', () async {
      final rules = [
        const FilterRule(
          fieldId: 'category',
          operator: FilterOperator.contains,
          value: 'lar',
        ),
      ];

      final results = await db.bookingsDao.watchBookingsPage(
        limit: 100,
        filterRules: rules,
      ).first;

      expect(results.length, 1);
      expect(results.first.booking.category, 'Salary');
    });

    test('text contains filter is case-insensitive', () async {
      final rules = [
        const FilterRule(
          fieldId: 'category',
          operator: FilterOperator.contains,
          value: 'SALARY',
        ),
      ];

      final results = await db.bookingsDao.watchBookingsPage(
        limit: 100,
        filterRules: rules,
      ).first;

      expect(results.length, 1);
      expect(results.first.booking.category, 'Salary');
    });

    test('text startsWith filter works', () async {
      final rules = [
        const FilterRule(
          fieldId: 'category',
          operator: FilterOperator.startsWith,
          value: 'Free',
        ),
      ];

      final results = await db.bookingsDao.watchBookingsPage(
        limit: 100,
        filterRules: rules,
      ).first;

      expect(results.length, 1);
      expect(results.first.booking.category, 'Freelance');
    });

    test('date before filter works', () async {
      final rules = [
        const FilterRule(
          fieldId: 'date',
          operator: FilterOperator.before,
          value: 20240115,
        ),
      ];

      final results = await db.bookingsDao.watchBookingsPage(
        limit: 100,
        filterRules: rules,
      ).first;

      expect(results.length, 1);
      expect(results.first.booking.date, 20240101);
    });

    test('date after filter works', () async {
      final rules = [
        const FilterRule(
          fieldId: 'date',
          operator: FilterOperator.after,
          value: 20240115,
        ),
      ];

      final results = await db.bookingsDao.watchBookingsPage(
        limit: 100,
        filterRules: rules,
      ).first;

      expect(results.length, 1);
      expect(results.first.booking.date, 20240201);
    });

    test('date between filter works', () async {
      final rules = [
        const FilterRule(
          fieldId: 'date',
          operator: FilterOperator.dateBetween,
          value: [20240101, 20240131],
        ),
      ];

      final results = await db.bookingsDao.watchBookingsPage(
        limit: 100,
        filterRules: rules,
      ).first;

      expect(results.length, 2);
    });

    test('dropdown inList filter works', () async {
      final rules = [
        const FilterRule(
          fieldId: 'accountId',
          operator: FilterOperator.inList,
          value: [1],
        ),
      ];

      final results = await db.bookingsDao.watchBookingsPage(
        limit: 100,
        filterRules: rules,
      ).first;

      expect(results.length, 3);
      expect(results.every((r) => r.booking.accountId == 1), isTrue);
    });

    test('multiple filters combine with AND', () async {
      final rules = [
        const FilterRule(
          fieldId: 'value',
          operator: FilterOperator.greaterThan,
          value: 0.0,
        ),
        const FilterRule(
          fieldId: 'date',
          operator: FilterOperator.after,
          value: 20240101,
        ),
      ];

      final results = await db.bookingsDao.watchBookingsPage(
        limit: 100,
        filterRules: rules,
      ).first;

      expect(results.length, 1);
      expect(results.first.booking.category, 'Freelance');
    });
  });

  group('Search query', () {
    test('search query filters by category', () async {
      final results = await db.bookingsDao.watchBookingsPage(
        limit: 100,
        searchQuery: 'Salary',
      ).first;

      expect(results.length, 1);
      expect(results.first.booking.category, 'Salary');
    });

    test('search query filters by notes', () async {
      final results = await db.bookingsDao.watchBookingsPage(
        limit: 100,
        searchQuery: 'shopping',
      ).first;

      expect(results.length, 1);
      expect(results.first.booking.notes, 'Weekly shopping');
    });

    test('search query is case-insensitive', () async {
      final results = await db.bookingsDao.watchBookingsPage(
        limit: 100,
        searchQuery: 'GROCERIES',
      ).first;

      expect(results.length, 1);
      expect(results.first.booking.category, 'Groceries');
    });

    test('search query with partial match', () async {
      final results = await db.bookingsDao.watchBookingsPage(
        limit: 100,
        searchQuery: 'ree',
      ).first;

      // Should match 'Freelance' only ('ree' is in 'Freelance')
      expect(results.length, 1);
      expect(results.first.booking.category, 'Freelance');
    });

    test('search and filter combine correctly', () async {
      final results = await db.bookingsDao.watchBookingsPage(
        limit: 100,
        searchQuery: 'ance',
        filterRules: [
          const FilterRule(
            fieldId: 'value',
            operator: FilterOperator.greaterThan,
            value: 0.0,
          ),
        ],
      ).first;

      // Only 'Freelance' (value 200) should match
      expect(results.length, 1);
      expect(results.first.booking.category, 'Freelance');
    });
  });
}
