import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xfin/database/app_database.dart';
import 'package:xfin/database/tables.dart';
import 'package:xfin/models/filter/filter_rule.dart';
import 'package:xfin/models/filter/transfer_filter_config.dart';

import 'filter_config_test_helper.dart';

void main() {
  final l10n = getTestLocalizations();

  group('buildTransferFilterConfig', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test('returns FilterConfig with correct title', () {
      final config = buildTransferFilterConfig(l10n, db);
      expect(config.title, l10n.filterTransfers);
    });

    test('has 7 fields', () {
      final config = buildTransferFilterConfig(l10n, db);
      expect(config.fields.length, 7);
    });

    test('fields have correct ids', () {
      final config = buildTransferFilterConfig(l10n, db);
      final ids = config.fields.map((f) => f.id).toList();
      expect(ids, [
        'value',
        'shares',
        'notes',
        'assetId',
        'sendingAccountId',
        'receivingAccountId',
        'date',
      ]);
    });

    test('field types are correct (2 numeric, 1 text, 3 dropdown, 1 date)',
        () {
      final config = buildTransferFilterConfig(l10n, db);
      final types = config.fields.map((f) => f.type).toList();
      expect(types, [
        FilterFieldType.numeric,
        FilterFieldType.numeric,
        FilterFieldType.text,
        FilterFieldType.dropdown,
        FilterFieldType.dropdown,
        FilterFieldType.dropdown,
        FilterFieldType.date,
      ]);
    });

    test('loadDropdownOptions for assetId returns assets used in transfers',
        () async {
      final config = buildTransferFilterConfig(l10n, db);

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

      // Insert accounts
      await db.into(db.accounts).insert(const AccountsCompanion(
            name: Value('Account A'),
            type: Value(AccountTypes.cash),
            balance: Value(1000),
          ));
      await db.into(db.accounts).insert(const AccountsCompanion(
            name: Value('Account B'),
            type: Value(AccountTypes.bankAccount),
            balance: Value(2000),
          ));

      // Insert transfer using asset 1
      await db.into(db.transfers).insert(const TransfersCompanion(
            value: Value(100),
            shares: Value(1),
            assetId: Value(1),
            sendingAccountId: Value(1),
            receivingAccountId: Value(2),
            date: Value(20260308),
          ));

      final options = await config.loadDropdownOptions!('assetId');
      expect(options.length, 1);
      expect(options.first.id, 1);
      expect(options.first.displayName, 'EUR');
    });

    test(
        'loadDropdownOptions for sendingAccountId returns non-archived accounts',
        () async {
      final config = buildTransferFilterConfig(l10n, db);

      await db.into(db.accounts).insert(const AccountsCompanion(
            name: Value('Active'),
            type: Value(AccountTypes.cash),
            balance: Value(1000),
          ));
      await db.into(db.accounts).insert(const AccountsCompanion(
            name: Value('Archived'),
            type: Value(AccountTypes.bankAccount),
            balance: Value(0),
            isArchived: Value(true),
          ));

      final options =
          await config.loadDropdownOptions!('sendingAccountId');
      expect(options.length, 1);
      expect(options.first.displayName, 'Active');
    });

    test(
        'loadDropdownOptions for receivingAccountId returns non-archived accounts',
        () async {
      final config = buildTransferFilterConfig(l10n, db);

      await db.into(db.accounts).insert(const AccountsCompanion(
            name: Value('Account 1'),
            type: Value(AccountTypes.cash),
            balance: Value(500),
          ));

      final options =
          await config.loadDropdownOptions!('receivingAccountId');
      expect(options.length, 1);
      expect(options.first.displayName, 'Account 1');
    });

    test('loadDropdownOptions for unknown field returns empty list', () async {
      final config = buildTransferFilterConfig(l10n, db);
      final options = await config.loadDropdownOptions!('unknown');
      expect(options, isEmpty);
    });
  });
}
