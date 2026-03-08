import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xfin/database/app_database.dart';
import 'package:xfin/database/tables.dart';
import 'package:xfin/models/filter/filter_rule.dart';
import 'package:xfin/models/filter/trade_filter_config.dart';

import 'filter_config_test_helper.dart';

void main() {
  final l10n = getTestLocalizations();

  group('buildTradeFilterConfig', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test('returns FilterConfig with correct title', () {
      final config = buildTradeFilterConfig(l10n, db);
      expect(config.title, l10n.filterTrades);
    });

    test('has 10 fields', () {
      final config = buildTradeFilterConfig(l10n, db);
      expect(config.fields.length, 10);
    });

    test('fields have correct ids', () {
      final config = buildTradeFilterConfig(l10n, db);
      final ids = config.fields.map((f) => f.id).toList();
      expect(ids, [
        'type',
        'shares',
        'costBasis',
        'fee',
        'tax',
        'profitAndLoss',
        'assetId',
        'sourceAccountId',
        'targetAccountId',
        'datetime',
      ]);
    });

    test(
        'field types are correct (5 numeric, 4 dropdown, 1 date)',
        () {
      final config = buildTradeFilterConfig(l10n, db);
      final types = config.fields.map((f) => f.type).toList();
      expect(types, [
        FilterFieldType.dropdown, // type
        FilterFieldType.numeric, // shares
        FilterFieldType.numeric, // costBasis
        FilterFieldType.numeric, // fee
        FilterFieldType.numeric, // tax
        FilterFieldType.numeric, // profitAndLoss
        FilterFieldType.dropdown, // assetId
        FilterFieldType.dropdown, // sourceAccountId
        FilterFieldType.dropdown, // targetAccountId
        FilterFieldType.date, // datetime
      ]);
    });

    test(
        'loadDropdownOptions for type returns all TradeTypes with localized names',
        () async {
      final config = buildTradeFilterConfig(l10n, db);
      final options = await config.loadDropdownOptions!('type');
      expect(options.length, TradeTypes.values.length);
      expect(options[0].id, 0); // buy
      expect(options[1].id, 1); // sell
      expect(options[0].displayName, l10n.calendarTradeBuy);
      expect(options[1].displayName, l10n.calendarTradeSell);
    });

    test('loadDropdownOptions for assetId returns assets used in trades',
        () async {
      final config = buildTradeFilterConfig(l10n, db);

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

      // Insert stock asset
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

      // Insert accounts
      await db.into(db.accounts).insert(const AccountsCompanion(
            name: Value('Cash'),
            type: Value(AccountTypes.cash),
            balance: Value(10000),
          ));
      await db.into(db.accounts).insert(const AccountsCompanion(
            name: Value('Portfolio'),
            type: Value(AccountTypes.portfolio),
            balance: Value(0),
          ));

      // Insert trade using asset 2 (Apple)
      await db.into(db.trades).insert(const TradesCompanion(
            type: Value(TradeTypes.buy),
            shares: Value(10),
            costBasis: Value(150),
            fee: Value(5),
            tax: Value(0),
            profitAndLoss: Value(0),
            assetId: Value(2),
            sourceAccountId: Value(1),
            targetAccountId: Value(2),
            datetime: Value(20260308120000),
            sourceAccountValueDelta: Value(-1505),
            targetAccountValueDelta: Value(1500),
          ));

      final options = await config.loadDropdownOptions!('assetId');
      expect(options.length, 1);
      expect(options.first.id, 2);
      expect(options.first.displayName, 'Apple');
    });

    test(
        'loadDropdownOptions for sourceAccountId returns non-archived accounts',
        () async {
      final config = buildTradeFilterConfig(l10n, db);

      await db.into(db.accounts).insert(const AccountsCompanion(
            name: Value('Active'),
            type: Value(AccountTypes.cash),
            balance: Value(1000),
          ));
      await db.into(db.accounts).insert(const AccountsCompanion(
            name: Value('Archived'),
            type: Value(AccountTypes.portfolio),
            balance: Value(0),
            isArchived: Value(true),
          ));

      final options =
          await config.loadDropdownOptions!('sourceAccountId');
      expect(options.length, 1);
      expect(options.first.displayName, 'Active');
    });

    test(
        'loadDropdownOptions for targetAccountId returns non-archived accounts',
        () async {
      final config = buildTradeFilterConfig(l10n, db);

      await db.into(db.accounts).insert(const AccountsCompanion(
            name: Value('Portfolio'),
            type: Value(AccountTypes.portfolio),
            balance: Value(5000),
          ));

      final options =
          await config.loadDropdownOptions!('targetAccountId');
      expect(options.length, 1);
      expect(options.first.displayName, 'Portfolio');
    });

    test('loadDropdownOptions for unknown field returns empty list', () async {
      final config = buildTradeFilterConfig(l10n, db);
      final options = await config.loadDropdownOptions!('unknown');
      expect(options, isEmpty);
    });
  });
}
