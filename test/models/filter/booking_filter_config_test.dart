import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xfin/database/app_database.dart';
import 'package:xfin/database/tables.dart';
import 'package:xfin/models/filter/booking_filter_config.dart';
import 'package:xfin/models/filter/filter_rule.dart';

import 'filter_config_test_helper.dart';

void main() {
  final l10n = getTestLocalizations();

  group('buildBookingFilterConfig', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test('returns FilterConfig with correct title', () {
      final config = buildBookingFilterConfig(l10n, db);
      expect(config.title, l10n.filterBookings);
    });

    test('has 7 fields', () {
      final config = buildBookingFilterConfig(l10n, db);
      expect(config.fields.length, 7);
    });

    test('fields have correct ids', () {
      final config = buildBookingFilterConfig(l10n, db);
      final ids = config.fields.map((f) => f.id).toList();
      expect(ids, [
        'value',
        'shares',
        'category',
        'notes',
        'assetId',
        'accountId',
        'date',
      ]);
    });

    test('field types are correct (2 numeric, 2 text, 2 dropdown, 1 date)',
        () {
      final config = buildBookingFilterConfig(l10n, db);
      final types = config.fields.map((f) => f.type).toList();
      expect(types, [
        FilterFieldType.numeric,
        FilterFieldType.numeric,
        FilterFieldType.text,
        FilterFieldType.text,
        FilterFieldType.dropdown,
        FilterFieldType.dropdown,
        FilterFieldType.date,
      ]);
    });

    test('loadDropdownOptions for assetId returns assets used in bookings',
        () async {
      final config = buildBookingFilterConfig(l10n, db);

      // Insert base currency
      await db.into(db.assets).insert(const AssetsCompanion(
            name: Value('EUR'),
            type: Value(AssetTypes.fiat),
            tickerSymbol: Value('EUR'),
            value: Value(0),
            shares: Value(0),
            brokerCostBasis: Value(1),
            netCostBasis: Value(1),
            buyFeeTotal: Value(0),
          ));

      // Insert another asset
      await db.into(db.assets).insert(const AssetsCompanion(
            name: Value('Apple'),
            type: Value(AssetTypes.stock),
            tickerSymbol: Value('AAPL'),
            value: Value(0),
            shares: Value(0),
            brokerCostBasis: Value(150),
            netCostBasis: Value(150),
            buyFeeTotal: Value(0),
          ));

      // Insert account
      await db.into(db.accounts).insert(const AccountsCompanion(
            name: Value('Cash'),
            type: Value(AccountTypes.cash),
            balance: Value(1000),
          ));

      // Insert booking using asset 1
      await db.into(db.bookings).insert(const BookingsCompanion(
            value: Value(100),
            shares: Value(1),
            category: Value('Test'),
            assetId: Value(1),
            accountId: Value(1),
            date: Value(20260308),
          ));

      final options = await config.loadDropdownOptions!('assetId');
      expect(options.length, 1);
      expect(options.first.id, 1);
      expect(options.first.displayName, 'EUR');
    });

    test('loadDropdownOptions for accountId returns non-archived accounts',
        () async {
      final config = buildBookingFilterConfig(l10n, db);

      // Insert accounts
      await db.into(db.accounts).insert(const AccountsCompanion(
            name: Value('Active Account'),
            type: Value(AccountTypes.cash),
            balance: Value(1000),
          ));
      await db.into(db.accounts).insert(const AccountsCompanion(
            name: Value('Archived Account'),
            type: Value(AccountTypes.bankAccount),
            balance: Value(0),
            isArchived: Value(true),
          ));

      final options = await config.loadDropdownOptions!('accountId');
      expect(options.length, 1);
      expect(options.first.displayName, 'Active Account');
    });

    test('loadDropdownOptions for unknown field returns empty list', () async {
      final config = buildBookingFilterConfig(l10n, db);
      final options = await config.loadDropdownOptions!('unknown');
      expect(options, isEmpty);
    });
  });
}
