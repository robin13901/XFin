import 'dart:ui';

import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xfin/database/app_database.dart';
import 'package:xfin/database/daos/trades_dao.dart';
import 'package:xfin/database/tables.dart';
import 'package:xfin/l10n/app_localizations.dart';

void main() {
  late AppDatabase db;
  late TradesDao tradesDao;

  late Asset baseCurrencyAsset;
  late Asset assetOne;
  late Asset assetTwo;
  late Account sourceAccount;
  late Account targetAccount;
  late AssetOnAccount baseCurrencyAssetOnSourceAccount;
  late AppLocalizations l10n;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    tradesDao = db.tradesDao;

    const locale = Locale('en');
    l10n = await AppLocalizations.delegate.load(locale);

    baseCurrencyAsset = const Asset(
        id: 1,
        name: 'US Dollar',
        type: AssetTypes.fiat,
        tickerSymbol: 'USD',
        currencySymbol: '\$',
        value: 0,
        shares: 0,
        netCostBasis: 0,
        brokerCostBasis: 0,
        buyFeeTotal: 0,
        isArchived: false);

    assetOne = const Asset(
        id: 2,
        name: 'Asset One',
        type: AssetTypes.stock,
        tickerSymbol: 'ONE',
        currencySymbol: '',
        value: 0,
        shares: 0,
        netCostBasis: 0,
        brokerCostBasis: 0,
        buyFeeTotal: 0,
        isArchived: false);

    assetTwo = const Asset(
        id: 3,
        name: 'Asset Two',
        type: AssetTypes.crypto,
        tickerSymbol: 'TWO',
        currencySymbol: '',
        value: 0,
        shares: 0,
        netCostBasis: 0,
        brokerCostBasis: 0,
        buyFeeTotal: 0,
        isArchived: false);

    sourceAccount = const Account(
        id: 1,
        name: 'Source Account',
        balance: 5000,
        initialBalance: 5000,
        type: AccountTypes.cash,
        isArchived: false);

    targetAccount = const Account(
        id: 2,
        name: 'Target Account',
        balance: 0,
        initialBalance: 0,
        type: AccountTypes.portfolio,
        isArchived: false);

    baseCurrencyAssetOnSourceAccount = const AssetOnAccount(
        assetId: 1,
        accountId: 1,
        shares: 5000,
        value: 5000,
        netCostBasis: 1,
        brokerCostBasis: 1,
        buyFeeTotal: 0);

    await db.into(db.assets).insert(baseCurrencyAsset.toCompanion(false));
    await db.into(db.assets).insert(assetOne.toCompanion(false));
    await db.into(db.assets).insert(assetTwo.toCompanion(false));
    await db.into(db.accounts).insert(sourceAccount.toCompanion(false));
    await db.into(db.accounts).insert(targetAccount.toCompanion(false));
    await db
        .into(db.assetsOnAccounts)
        .insert(baseCurrencyAssetOnSourceAccount.toCompanion(false));
  });

  tearDown(() async {
    await db.close();
  });

  group('watchAllTrades', () {
    test('maps joined rows to TradeWithAsset', () async {
      // Insert a trade
      await db.into(db.trades).insert(TradesCompanion(
          datetime: const drift.Value(20250101120000),
          assetId: drift.Value(assetOne.id),
          type: const drift.Value(TradeTypes.buy),
          shares: const drift.Value(1.0),
          costBasis: const drift.Value(10.0),
          fee: const drift.Value(0.0),
          tax: const drift.Value(0.0),
          sourceAccountId: drift.Value(sourceAccount.id),
          targetAccountId: drift.Value(targetAccount.id),
          sourceAccountValueDelta: const drift.Value(-10.0),
          targetAccountValueDelta: const drift.Value(10.0),
          profitAndLoss: const drift.Value(0),
          returnOnInvest: const drift.Value(0)));

      final rows = await tradesDao.watchAllTrades().first;
      expect(rows, isNotEmpty);
      expect(rows.first.asset.name, 'Asset One');
      expect(rows.first.trade.shares, 1.0);
    });

    test('returns trades sorted desc by datetime then id', () async {
      // insert three trades at different datetimes
      await db.into(db.trades).insert(TradesCompanion(
            datetime: const drift.Value(20250101000001),
            assetId: drift.Value(assetOne.id),
            type: const drift.Value(TradeTypes.buy),
            shares: const drift.Value(1),
            costBasis: const drift.Value(1),
            fee: const drift.Value(0),
            tax: const drift.Value(0),
            sourceAccountId: drift.Value(sourceAccount.id),
            targetAccountId: drift.Value(targetAccount.id),
            sourceAccountValueDelta: const drift.Value(-1.0),
            targetAccountValueDelta: const drift.Value(1.0),
          ));

      await db.into(db.trades).insert(TradesCompanion(
            datetime: const drift.Value(20250101000003),
            assetId: drift.Value(assetOne.id),
            type: const drift.Value(TradeTypes.buy),
            shares: const drift.Value(1),
            costBasis: const drift.Value(1),
            fee: const drift.Value(0),
            tax: const drift.Value(0),
            sourceAccountId: drift.Value(sourceAccount.id),
            targetAccountId: drift.Value(targetAccount.id),
            sourceAccountValueDelta: const drift.Value(-1.0),
            targetAccountValueDelta: const drift.Value(1.0),
          ));

      await db.into(db.trades).insert(TradesCompanion(
            datetime: const drift.Value(20250101000002),
            assetId: drift.Value(assetOne.id),
            type: const drift.Value(TradeTypes.buy),
            shares: const drift.Value(1),
            costBasis: const drift.Value(1),
            fee: const drift.Value(0),
            tax: const drift.Value(0),
            sourceAccountId: drift.Value(sourceAccount.id),
            targetAccountId: drift.Value(targetAccount.id),
            sourceAccountValueDelta: const drift.Value(-1.0),
            targetAccountValueDelta: const drift.Value(1.0),
          ));

      final rows = await tradesDao.watchAllTrades().first;
      // expected order: datetime 20250101000003, 20250101000002, 20250101000001
      expect(rows.map((r) => r.trade.datetime).toList(),
          equals([20250101000003, 20250101000002, 20250101000001]));
    });
  });

  group('insertTrade (buy)', () {
    test(
        'when assetsOnAccounts exists -> updates assetsOnAccounts and accounts and inserts trade',
        () async {
      // Existing assetsOnAccounts (10 shares, value 100)
      await db.into(db.assetsOnAccounts).insert(AssetsOnAccountsCompanion(
          assetId: drift.Value(assetOne.id),
          accountId: drift.Value(targetAccount.id),
          shares: const drift.Value(10.0),
          value: const drift.Value(100.0),
          netCostBasis: const drift.Value(10.0),
          brokerCostBasis: const drift.Value(9.5),
          buyFeeTotal: const drift.Value(5.0)));
      await (db.update(db.assets)..where((a) => a.id.equals(assetOne.id)))
          .write(const AssetsCompanion(
              shares: drift.Value(10),
              value: drift.Value(100.0),
              netCostBasis: drift.Value(10.0),
              brokerCostBasis: drift.Value(9.5),
              buyFeeTotal: drift.Value(5.0)));

      // Build a buy TradesCompanion: buy 2 shares at 10 each, fee 1, tax 0
      final buyEntry = TradesCompanion(
        datetime: const drift.Value(20250101120001),
        assetId: drift.Value(assetOne.id),
        type: const drift.Value(TradeTypes.buy),
        shares: const drift.Value(2.0),
        costBasis: const drift.Value(10.0),
        fee: const drift.Value(1.0),
        tax: const drift.Value(0.0),
        sourceAccountId: drift.Value(sourceAccount.id),
        targetAccountId: drift.Value(targetAccount.id),
      );

      await tradesDao.insertTrade(buyEntry, l10n);

      // Check assetOnAccount updated
      final updatedAOA = await (db.select(db.assetsOnAccounts)
            ..where((a) =>
                a.assetId.equals(assetOne.id) &
                a.accountId.equals(targetAccount.id)))
          .getSingle();
      expect(updatedAOA.shares, closeTo(10 + 2, 1e-9));
      expect(updatedAOA.value, closeTo(100 + 2 * 10, 1e-9));
      expect(updatedAOA.buyFeeTotal, closeTo(5 + 1, 1e-9));
      expect(updatedAOA.netCostBasis, closeTo(120.0 / 12.0, 1e-9));
      expect(updatedAOA.brokerCostBasis, closeTo((120.0 + 6.0) / 12.0, 1e-9));

      // Check asset updated
      final updatedAsset = await (db.select(db.assets)
            ..where((a) => a.id.equals(assetOne.id)))
          .getSingle();
      expect(updatedAsset.shares, closeTo(10 + 2, 1e-9));
      expect(updatedAsset.value, closeTo(100 + 2 * 10, 1e-9));
      expect(updatedAsset.buyFeeTotal, closeTo(5 + 1, 1e-9));
      expect(updatedAsset.netCostBasis, closeTo(120.0 / 12.0, 1e-9));
      expect(updatedAsset.brokerCostBasis, closeTo((120.0 + 6.0) / 12.0, 1e-9));

      // Check accounts updated
      final source = await (db.select(db.accounts)
            ..where((a) => a.id.equals(sourceAccount.id)))
          .getSingle();
      expect(source.balance, closeTo(5000 - 21, 1e-9));
      final target = await (db.select(db.accounts)
            ..where((a) => a.id.equals(targetAccount.id)))
          .getSingle();
      expect(target.balance, closeTo(0 + 20, 1e-9));

      // Check trades inserted and values computed
      final insertedTrade = await (db.select(db.trades)
            ..where((t) =>
                t.assetId.equals(assetOne.id) &
                t.datetime.equals(20250101120001)))
          .getSingle();
      expect(insertedTrade.sourceAccountValueDelta, closeTo(-20 - 1, 1e-9));
      expect(insertedTrade.targetAccountValueDelta, closeTo(20, 1e-9));
      expect(insertedTrade.profitAndLoss, closeTo(0.0, 1e-9));
      expect(insertedTrade.returnOnInvest, closeTo(0.0, 1e-9));
    });

    test(
        'when assetsOnAccounts does not exist -> creates it then processes buy',
        () async {
      final newAssetId = await db.into(db.assets).insert(const AssetsCompanion(
            name: drift.Value('New Asset'),
            type: drift.Value(AssetTypes.stock),
            tickerSymbol: drift.Value('NEW'),
            value: drift.Value(0.0),
            shares: drift.Value(0.0),
            netCostBasis: drift.Value(0.0),
            brokerCostBasis: drift.Value(0.0),
            buyFeeTotal: drift.Value(0.0),
          ));

      // Ensure no assetsOnAccounts row exists initially
      final rowBefore = await (db.select(db.assetsOnAccounts)
            ..where((a) =>
                a.assetId.equals(newAssetId) &
                a.accountId.equals(targetAccount.id)))
          .get();
      expect(rowBefore, isEmpty);

      final buyEntry = TradesCompanion(
        datetime: const drift.Value(20250101121000),
        assetId: drift.Value(newAssetId),
        type: const drift.Value(TradeTypes.buy),
        shares: const drift.Value(0.001),
        costBasis: const drift.Value(40000),
        fee: const drift.Value(1),
        tax: const drift.Value(0.0),
        sourceAccountId: drift.Value(sourceAccount.id),
        targetAccountId: drift.Value(targetAccount.id),
      );

      await tradesDao.insertTrade(buyEntry, l10n);

      // Now assetsOnAccounts should exist and be updated
      final newAssetOnAccount = await (db.select(db.assetsOnAccounts)
            ..where((a) =>
                a.assetId.equals(newAssetId) &
                a.accountId.equals(targetAccount.id)))
          .getSingle();

      expect(newAssetOnAccount.shares, closeTo(0.001, 1e-9));
      expect(newAssetOnAccount.value, closeTo(0.001 * 40000, 1e-9));
      expect(newAssetOnAccount.netCostBasis, closeTo(40 / 0.001, 1e-9));
      expect(
          newAssetOnAccount.brokerCostBasis, closeTo((40 + 1) / 0.001, 1e-9));
      expect(newAssetOnAccount.buyFeeTotal, closeTo(1, 1e-9));
    });
  });

  test('buyFeeTotal calculation/consumption', () async {
    // We use 1% fee on buy value throughout the test
    Asset asset;
    AssetOnAccount aoa;

    await db.tradesDao.insertTrade(
        TradesCompanion(
          datetime: const drift.Value(20250101000000),
          assetId: drift.Value(assetOne.id),
          type: const drift.Value(TradeTypes.buy),
          shares: const drift.Value(1),
          costBasis: const drift.Value(100),
          fee: const drift.Value(1),
          tax: const drift.Value(0),
          sourceAccountId: drift.Value(sourceAccount.id),
          targetAccountId: drift.Value(targetAccount.id),
        ),
        l10n);

    asset = await db.assetsDao.getAsset(assetOne.id);
    expect(asset.buyFeeTotal, closeTo(1, 1e-9));
    aoa = await db.assetsOnAccountsDao.getAOA(targetAccount.id, assetOne.id);
    expect(aoa.buyFeeTotal, closeTo(1, 1e-9));

    await db.tradesDao.insertTrade(
        TradesCompanion(
          datetime: const drift.Value(20250102000000),
          assetId: drift.Value(assetOne.id),
          type: const drift.Value(TradeTypes.buy),
          shares: const drift.Value(1),
          costBasis: const drift.Value(65),
          fee: const drift.Value(0.65),
          tax: const drift.Value(0),
          sourceAccountId: drift.Value(sourceAccount.id),
          targetAccountId: drift.Value(targetAccount.id),
        ),
        l10n);

    asset = await db.assetsDao.getAsset(assetOne.id);
    expect(asset.buyFeeTotal, closeTo(1.65, 1e-9));
    aoa = await db.assetsOnAccountsDao.getAOA(targetAccount.id, assetOne.id);
    expect(aoa.buyFeeTotal, closeTo(1.65, 1e-9));

    await db.tradesDao.insertTrade(
        TradesCompanion(
          datetime: const drift.Value(20250103000000),
          assetId: drift.Value(assetOne.id),
          type: const drift.Value(TradeTypes.buy),
          shares: const drift.Value(1),
          costBasis: const drift.Value(15),
          fee: const drift.Value(0.15),
          tax: const drift.Value(0),
          sourceAccountId: drift.Value(sourceAccount.id),
          targetAccountId: drift.Value(targetAccount.id),
        ),
        l10n);

    asset = await db.assetsDao.getAsset(assetOne.id);
    expect(asset.buyFeeTotal, closeTo(1.8, 1e-9));
    aoa = await db.assetsOnAccountsDao.getAOA(targetAccount.id, assetOne.id);
    expect(aoa.buyFeeTotal, closeTo(1.8, 1e-9));

    await db.tradesDao.insertTrade(
        TradesCompanion(
          datetime: const drift.Value(20250104000000),
          assetId: drift.Value(assetOne.id),
          type: const drift.Value(TradeTypes.sell),
          shares: const drift.Value(1.5),
          costBasis: const drift.Value(100),
          fee: const drift.Value(1.5), // should not have any influence
          tax: const drift.Value(0),
          sourceAccountId: drift.Value(sourceAccount.id),
          targetAccountId: drift.Value(targetAccount.id),
        ),
        l10n);

    asset = await db.assetsDao.getAsset(assetOne.id);
    expect(asset.buyFeeTotal, closeTo(0.475, 1e-9));
    aoa = await db.assetsOnAccountsDao.getAOA(targetAccount.id, assetOne.id);
    expect(aoa.buyFeeTotal, closeTo(0.475, 1e-9));

    await db.tradesDao.insertTrade(
        TradesCompanion(
          datetime: const drift.Value(20250105000000),
          assetId: drift.Value(assetOne.id),
          type: const drift.Value(TradeTypes.sell),
          shares: const drift.Value(1),
          costBasis: const drift.Value(100),
          fee: const drift.Value(1), // should not have any influence
          tax: const drift.Value(0),
          sourceAccountId: drift.Value(sourceAccount.id),
          targetAccountId: drift.Value(targetAccount.id),
        ),
        l10n);

    asset = await db.assetsDao.getAsset(assetOne.id);
    expect(asset.buyFeeTotal, closeTo(0.075, 1e-9));
    aoa = await db.assetsOnAccountsDao.getAOA(targetAccount.id, assetOne.id);
    expect(aoa.buyFeeTotal, closeTo(0.075, 1e-9));

    await db.tradesDao.insertTrade(
        TradesCompanion(
          datetime: const drift.Value(20250106000000),
          assetId: drift.Value(assetOne.id),
          type: const drift.Value(TradeTypes.sell),
          shares: const drift.Value(0.5),
          costBasis: const drift.Value(100),
          fee: const drift.Value(0.5), // should not have any influence
          tax: const drift.Value(0),
          sourceAccountId: drift.Value(sourceAccount.id),
          targetAccountId: drift.Value(targetAccount.id),
        ),
        l10n);

    asset = await db.assetsDao.getAsset(assetOne.id);
    expect(asset.buyFeeTotal, closeTo(0, 1e-9));
    aoa = await db.assetsOnAccountsDao.getAOA(targetAccount.id, assetOne.id);
    expect(aoa.buyFeeTotal, closeTo(0, 1e-9));
  });

  group('insertTrade (sell) and FIFO', () {
    test('complex scenario', () async {
      // Trade 1
      await tradesDao.insertTrade(
          TradesCompanion(
            datetime: const drift.Value(20250101000000),
            assetId: drift.Value(assetOne.id),
            type: const drift.Value(TradeTypes.buy),
            shares: const drift.Value(50),
            costBasis: const drift.Value(16.054),
            fee: const drift.Value(1),
            tax: const drift.Value(0),
            sourceAccountId: drift.Value(sourceAccount.id),
            targetAccountId: drift.Value(targetAccount.id),
          ),
          l10n);

      final trade1 = await (db.select(db.trades)..where((t) => t.id.equals(1)))
          .getSingle();
      expect(trade1.sourceAccountValueDelta, closeTo(-803.7, 1e-9));
      expect(trade1.targetAccountValueDelta, closeTo(802.7, 1e-9));

      final aoaOne1 = await (db.select(db.assetsOnAccounts)
            ..where((a) =>
                a.assetId.equals(assetOne.id) &
                a.accountId.equals(targetAccount.id)))
          .getSingle();
      expect(aoaOne1.shares, closeTo(50, 1e-9));
      expect(aoaOne1.value, closeTo(802.7, 1e-9));
      expect(aoaOne1.buyFeeTotal, closeTo(1, 1e-9));
      expect(aoaOne1.brokerCostBasis, closeTo((802.7 + 1) / 50, 1e-9));
      expect(aoaOne1.netCostBasis, closeTo(802.7 / 50, 1e-9));

      final assetOne1 = await (db.select(db.assets)
            ..where((a) => a.id.equals(assetOne.id)))
          .getSingle();
      expect(assetOne1.shares, closeTo(50, 1e-9));
      expect(assetOne1.value, closeTo(802.7, 1e-9));
      expect(assetOne1.buyFeeTotal, closeTo(1, 1e-9));
      expect(assetOne1.brokerCostBasis, closeTo((802.7 + 1) / 50, 1e-9));
      expect(assetOne1.netCostBasis, closeTo(802.7 / 50, 1e-9));

      final source1 = await (db.select(db.accounts)
            ..where((a) => a.id.equals(sourceAccount.id)))
          .getSingle();
      expect(source1.balance, closeTo(5000 - 802.7 - 1, 1e-9));

      final target1 = await (db.select(db.accounts)
            ..where((a) => a.id.equals(targetAccount.id)))
          .getSingle();
      expect(target1.balance, closeTo(0 + 802.7, 1e-9));

      // Trade 2
      await tradesDao.insertTrade(
          TradesCompanion(
            datetime: const drift.Value(20250102000000),
            assetId: drift.Value(assetTwo.id),
            type: const drift.Value(TradeTypes.buy),
            shares: const drift.Value(4.936808),
            costBasis: const drift.Value(101.2395053646),
            fee: const drift.Value(1),
            tax: const drift.Value(0),
            sourceAccountId: drift.Value(sourceAccount.id),
            targetAccountId: drift.Value(targetAccount.id),
          ),
          l10n);

      final trade2 = await (db.select(db.trades)..where((t) => t.id.equals(2)))
          .getSingle();
      expect(trade2.sourceAccountValueDelta, closeTo(-500.8, 1e-9));
      expect(trade2.targetAccountValueDelta, closeTo(499.8, 1e-9));

      final aoaTwo2 = await (db.select(db.assetsOnAccounts)
            ..where((a) =>
                a.assetId.equals(assetTwo.id) &
                a.accountId.equals(targetAccount.id)))
          .getSingle();
      expect(aoaTwo2.shares, closeTo(4.936808, 1e-9));
      expect(aoaTwo2.value, closeTo(499.8, 1e-9));
      expect(aoaTwo2.buyFeeTotal, closeTo(1, 1e-9));
      expect(aoaTwo2.brokerCostBasis, closeTo((499.8 + 1) / 4.936808, 1e-9));
      expect(aoaTwo2.netCostBasis, closeTo(499.8 / 4.936808, 1e-9));

      final assetTwo2 = await (db.select(db.assets)
            ..where((a) => a.id.equals(assetTwo.id)))
          .getSingle();
      expect(assetTwo2.shares, closeTo(4.936808, 1e-9));
      expect(assetTwo2.value, closeTo(499.8, 1e-9));
      expect(assetTwo2.buyFeeTotal, closeTo(1, 1e-9));
      expect(assetTwo2.brokerCostBasis, closeTo((499.8 + 1) / 4.936808, 1e-9));
      expect(assetTwo2.netCostBasis, closeTo(499.8 / 4.936808, 1e-9));

      final source2 = await (db.select(db.accounts)
            ..where((a) => a.id.equals(sourceAccount.id)))
          .getSingle();
      expect(source2.balance, closeTo(4196.3 - 499.8 - 1, 1e-9));

      final target2 = await (db.select(db.accounts)
            ..where((a) => a.id.equals(targetAccount.id)))
          .getSingle();
      expect(target2.balance, closeTo(802.7 + 499.8, 1e-9));

      // Trade 3
      await tradesDao.insertTrade(
          TradesCompanion(
            datetime: const drift.Value(20250103000000),
            assetId: drift.Value(assetOne.id),
            type: const drift.Value(TradeTypes.buy),
            shares: const drift.Value(34),
            costBasis: const drift.Value(11.2541176470588),
            fee: const drift.Value(1),
            tax: const drift.Value(0),
            sourceAccountId: drift.Value(sourceAccount.id),
            targetAccountId: drift.Value(targetAccount.id),
          ),
          l10n);

      final trade3 = await (db.select(db.trades)..where((t) => t.id.equals(3)))
          .getSingle();
      expect(trade3.sourceAccountValueDelta, closeTo(-383.64, 1e-9));
      expect(trade3.targetAccountValueDelta, closeTo(382.64, 1e-9));

      final aoaOne3 = await (db.select(db.assetsOnAccounts)
            ..where((a) =>
                a.assetId.equals(assetOne.id) &
                a.accountId.equals(targetAccount.id)))
          .getSingle();
      expect(aoaOne3.shares, closeTo(50 + 34, 1e-9));
      expect(aoaOne3.value, closeTo(802.7 + 382.64, 1e-9));
      expect(aoaOne3.buyFeeTotal, closeTo(1 + 1, 1e-9));
      expect(aoaOne3.brokerCostBasis, closeTo((802.7 + 382.64 + 2) / 84, 1e-9));
      expect(aoaOne3.netCostBasis, closeTo((802.7 + 382.64) / 84, 1e-9));

      final assetOne3 = await (db.select(db.assets)
            ..where((a) => a.id.equals(assetOne.id)))
          .getSingle();
      expect(assetOne3.shares, closeTo(50 + 34, 1e-9));
      expect(assetOne3.value, closeTo(802.7 + 382.64, 1e-9));
      expect(assetOne3.buyFeeTotal, closeTo(1 + 1, 1e-9));
      expect(
          assetOne3.brokerCostBasis, closeTo((802.7 + 382.64 + 2) / 84, 1e-9));
      expect(assetOne3.netCostBasis, closeTo((802.7 + 382.64) / 84, 1e-9));

      final source3 = await (db.select(db.accounts)
            ..where((a) => a.id.equals(sourceAccount.id)))
          .getSingle();
      expect(source3.balance, closeTo(3695.5 - 382.64 - 1, 1e-9));

      final target3 = await (db.select(db.accounts)
            ..where((a) => a.id.equals(targetAccount.id)))
          .getSingle();
      expect(target3.balance, closeTo(1302.5 + 382.64, 1e-9));

      // Trade 4 (sell assetTwo)
      await tradesDao.insertTrade(
          TradesCompanion(
            datetime: const drift.Value(20250104000000),
            assetId: drift.Value(assetTwo.id),
            type: const drift.Value(TradeTypes.sell),
            shares: const drift.Value(1.936808),
            costBasis: const drift.Value(205.69927426983),
            fee: const drift.Value(1),
            tax: const drift.Value(0),
            sourceAccountId: drift.Value(sourceAccount.id),
            targetAccountId: drift.Value(targetAccount.id),
          ),
          l10n);

      final trade4 = await (db.select(db.trades)..where((t) => t.id.equals(4)))
          .getSingle();
      expect(trade4.sourceAccountValueDelta, closeTo(397.4, 1e-9));
      expect(trade4.targetAccountValueDelta, closeTo(-196.0814839062, 1e-9));
      expect(trade4.profitAndLoss, closeTo(200.31851609380072, 1e-9));
      expect(trade4.returnOnInvest, closeTo(1.0195685746263912, 1e-9));

      final aoaTwo4 = await (db.select(db.assetsOnAccounts)
            ..where((a) =>
                a.assetId.equals(assetTwo.id) &
                a.accountId.equals(targetAccount.id)))
          .getSingle();
      expect(aoaTwo4.shares, closeTo(3, 1e-9));
      expect(aoaTwo4.value, closeTo(499.8 - 196.0814839062, 1e-9));
      expect(aoaTwo4.buyFeeTotal,
          closeTo(1 - (1.936808 / 4.936808), 1e-9)); // = 0.607680104229291
      expect(aoaTwo4.brokerCostBasis,
          closeTo((499.8 - 196.0814839062 + 0.607680104229291) / 3, 1e-9));
      expect(aoaTwo4.netCostBasis, closeTo((499.8 - 196.0814839062) / 3, 1e-9));

      final assetTwo4 = await (db.select(db.assets)
            ..where((a) => a.id.equals(assetTwo.id)))
          .getSingle();
      expect(assetTwo4.shares, closeTo(3, 1e-9));
      expect(assetTwo4.value, closeTo(499.8 - 196.0814839062, 1e-9));
      expect(assetTwo4.buyFeeTotal, closeTo(1 - (1.936808 / 4.936808), 1e-9));
      expect(assetTwo4.brokerCostBasis,
          closeTo((499.8 - 196.0814839062 + 0.607680104229291) / 3, 1e-9));
      expect(
          assetTwo4.netCostBasis, closeTo((499.8 - 196.0814839062) / 3, 1e-9));

      final source4 = await (db.select(db.accounts)
            ..where((a) => a.id.equals(sourceAccount.id)))
          .getSingle();
      expect(source4.balance, closeTo(3311.86 + 397.4, 1e-9));

      final target4 = await (db.select(db.accounts)
            ..where((a) => a.id.equals(targetAccount.id)))
          .getSingle();
      expect(target4.balance, closeTo(1685.14 - 196.0814839062, 1e-9));

      // Trade 5
      await tradesDao.insertTrade(
          TradesCompanion(
            datetime: const drift.Value(20250105000000),
            assetId: drift.Value(assetOne.id),
            type: const drift.Value(TradeTypes.sell),
            shares: const drift.Value(84),
            costBasis: const drift.Value(6.655),
            fee: const drift.Value(1),
            tax: const drift.Value(0),
            sourceAccountId: drift.Value(sourceAccount.id),
            targetAccountId: drift.Value(targetAccount.id),
          ),
          l10n);

      final trade5 = await (db.select(db.trades)..where((t) => t.id.equals(5)))
          .getSingle();
      expect(trade5.sourceAccountValueDelta, closeTo(558.02, 1e-9));
      expect(trade5.targetAccountValueDelta, closeTo(-1185.34, 1e-9));
      expect(trade5.profitAndLoss, closeTo(-628.3199999999993, 1e-9));
      expect(trade5.returnOnInvest, closeTo(-0.529182879377, 1e-9));

      final aoaOne5 = await (db.select(db.assetsOnAccounts)
            ..where((a) =>
                a.assetId.equals(assetOne.id) &
                a.accountId.equals(targetAccount.id)))
          .getSingle();
      expect(aoaOne5.shares, closeTo(0, 1e-9));
      expect(aoaOne5.value, closeTo(0, 1e-9));
      expect(aoaOne5.buyFeeTotal, closeTo(0, 1e-9));
      expect(aoaOne5.brokerCostBasis, closeTo(0, 1e-9));
      expect(aoaOne5.netCostBasis, closeTo(0, 1e-9));

      final assetOne5 = await (db.select(db.assets)
            ..where((a) => a.id.equals(assetOne.id)))
          .getSingle();
      expect(assetOne5.shares, closeTo(0, 1e-9));
      expect(assetOne5.value, closeTo(0, 1e-9));
      expect(assetOne5.buyFeeTotal, closeTo(0, 1e-9));
      expect(assetOne5.brokerCostBasis, closeTo(0, 1e-9));
      expect(assetOne5.netCostBasis, closeTo(0, 1e-9));

      final source5 = await (db.select(db.accounts)
            ..where((a) => a.id.equals(sourceAccount.id)))
          .getSingle();
      expect(source5.balance, closeTo(3709.26 + 558.02, 1e-9));

      final target5 = await (db.select(db.accounts)
            ..where((a) => a.id.equals(targetAccount.id)))
          .getSingle();
      expect(target5.balance, closeTo(1489.0585160938 - 1185.34, 1e-9));

      // Add new account to test differentiation of Asset and AssetsOnAccount
      Account targetAccount2 = const Account(
          id: 3,
          name: 'Target Account 2',
          balance: 0,
          initialBalance: 0,
          type: AccountTypes.portfolio,
          isArchived: false);
      await db.into(db.accounts).insert(targetAccount2.toCompanion(false));

      // Trade 6
      await tradesDao.insertTrade(
          TradesCompanion(
            datetime: const drift.Value(20250106000000),
            assetId: drift.Value(assetTwo.id),
            type: const drift.Value(TradeTypes.buy),
            shares: const drift.Value(10),
            costBasis: const drift.Value(200),
            fee: const drift.Value(1),
            tax: const drift.Value(0),
            sourceAccountId: drift.Value(sourceAccount.id),
            targetAccountId: drift.Value(targetAccount2.id),
          ),
          l10n);

      final trade6 = await (db.select(db.trades)..where((t) => t.id.equals(6)))
          .getSingle();
      expect(trade6.sourceAccountValueDelta, closeTo(-2001, 1e-9));
      expect(trade6.targetAccountValueDelta, closeTo(2000, 1e-9));

      final aoaTwo6 = await (db.select(db.assetsOnAccounts)
            ..where((a) =>
                a.assetId.equals(assetTwo.id) &
                a.accountId.equals(targetAccount2.id)))
          .getSingle();
      expect(aoaTwo6.shares, closeTo(10, 1e-9));
      expect(aoaTwo6.value, closeTo(2000, 1e-9));
      expect(aoaTwo6.buyFeeTotal, closeTo(1, 1e-9));
      expect(aoaTwo6.brokerCostBasis, closeTo((2000 + 1) / 10, 1e-9));
      expect(aoaTwo6.netCostBasis, closeTo(2000 / 10, 1e-9));

      final assetTwo6 = await (db.select(db.assets)
            ..where((a) => a.id.equals(assetTwo.id)))
          .getSingle();
      expect(assetTwo6.shares, closeTo(3 + 10, 1e-9));
      expect(assetTwo6.value, closeTo(303.7185160938 + 2000, 1e-9));
      expect(assetTwo6.buyFeeTotal, closeTo(0.607680104229291 + 1, 1e-9));
      expect(assetTwo6.brokerCostBasis,
          closeTo((303.7185160938 + 2000 + 1.607680104229291) / 13, 1e-9));
      expect(
          assetTwo6.netCostBasis, closeTo((303.7185160938 + 2000) / 13, 1e-9));

      final source6 = await (db.select(db.accounts)
            ..where((a) => a.id.equals(sourceAccount.id)))
          .getSingle();
      expect(source6.balance, closeTo(4267.28 - 2000 - 1, 1e-9));

      final target2_6 = await (db.select(db.accounts)
            ..where((a) => a.id.equals(targetAccount2.id)))
          .getSingle();
      expect(target2_6.balance, closeTo(2000, 1e-9));

      // Trade 7
      await tradesDao.insertTrade(
          TradesCompanion(
            datetime: const drift.Value(20250107000000),
            assetId: drift.Value(assetTwo.id),
            type: const drift.Value(TradeTypes.sell),
            shares: const drift.Value(3),
            costBasis: const drift.Value(208),
            fee: const drift.Value(1),
            tax: const drift.Value(18.82),
            sourceAccountId: drift.Value(sourceAccount.id),
            targetAccountId: drift.Value(targetAccount.id),
          ),
          l10n);

      final trade7 = await (db.select(db.trades)..where((t) => t.id.equals(7)))
          .getSingle();
      expect(trade7.sourceAccountValueDelta, closeTo(604.18, 1e-9));
      expect(trade7.targetAccountValueDelta, closeTo(-303.7185160938, 1e-9));
      expect(trade7.profitAndLoss, closeTo(318.2814839061999, 1e-9));
      expect(trade7.returnOnInvest, closeTo(1.045856347178, 1e-9));

      final aoaTwo7 = await (db.select(db.assetsOnAccounts)
            ..where((a) =>
                a.assetId.equals(assetTwo.id) &
                a.accountId.equals(targetAccount.id)))
          .getSingle();
      expect(aoaTwo7.shares, closeTo(0, 1e-9));
      expect(aoaTwo7.value, closeTo(0, 1e-9));
      expect(aoaTwo7.buyFeeTotal, closeTo(0, 1e-9));
      expect(aoaTwo7.brokerCostBasis, closeTo(0, 1e-9));
      expect(aoaTwo7.netCostBasis, closeTo(0, 1e-9));

      final aoaTwo2_7 = await (db.select(db.assetsOnAccounts)
            ..where((a) =>
                a.assetId.equals(assetTwo.id) &
                a.accountId.equals(targetAccount2.id)))
          .getSingle();
      expect(aoaTwo2_7.shares, closeTo(10, 1e-9));
      expect(aoaTwo2_7.value, closeTo(2000, 1e-9));
      expect(aoaTwo2_7.buyFeeTotal, closeTo(1, 1e-9));
      expect(aoaTwo2_7.brokerCostBasis, closeTo((2000 + 1) / 10, 1e-9));
      expect(aoaTwo2_7.netCostBasis, closeTo(2000 / 10, 1e-9));

      final assetTwo7 = await (db.select(db.assets)
            ..where((a) => a.id.equals(assetTwo.id)))
          .getSingle();
      expect(assetTwo7.shares, closeTo(10, 1e-9));
      expect(assetTwo7.value, closeTo(2000, 1e-9));
      expect(assetTwo7.buyFeeTotal, closeTo(1.0, 1e-9));
      expect(assetTwo7.brokerCostBasis, closeTo(200.1, 1e-9));
      expect(assetTwo7.netCostBasis, closeTo(2000 / 10, 1e-9));

      final source7 = await (db.select(db.accounts)
            ..where((a) => a.id.equals(sourceAccount.id)))
          .getSingle();
      expect(source7.balance, closeTo(2267.28 + 604.18 - 1, 1e-9));

      final target7 = await (db.select(db.accounts)
            ..where((a) => a.id.equals(targetAccount.id)))
          .getSingle();
      expect(target7.balance, closeTo(0, 1e-9));
    });

    test('complex scenario 2', () async {
      // Trade 1
      await tradesDao.insertTrade(
          TradesCompanion(
            datetime: const drift.Value(20241210111501),
            assetId: drift.Value(assetOne.id),
            type: const drift.Value(TradeTypes.buy),
            shares: const drift.Value(1233.32544),
            costBasis: const drift.Value(0.038475),
            fee: const drift.Value(0.047499696),
            tax: const drift.Value(0),
            sourceAccountId: drift.Value(sourceAccount.id),
            targetAccountId: drift.Value(targetAccount.id),
          ),
          l10n);

      final trade1 = await (db.select(db.trades)..where((t) => t.id.equals(1)))
          .getSingle();
      expect(trade1.sourceAccountValueDelta, closeTo(-47.499696, 1e-9));
      expect(trade1.targetAccountValueDelta, closeTo(47.452196304, 1e-9));

      final aoaOne1 = await (db.select(db.assetsOnAccounts)
            ..where((a) =>
                a.assetId.equals(assetOne.id) &
                a.accountId.equals(targetAccount.id)))
          .getSingle();
      expect(aoaOne1.shares, closeTo(1233.32544, 1e-9));
      expect(aoaOne1.value, closeTo(47.452196304, 1e-9));
      expect(aoaOne1.buyFeeTotal, closeTo(0.047499696, 1e-9));
      expect(aoaOne1.brokerCostBasis,
          closeTo((47.452196304 + 0.047499696) / 1233.32544, 1e-9));
      expect(aoaOne1.netCostBasis, closeTo(47.452196304 / 1233.32544, 1e-9));

      final assetOne1 = await (db.select(db.assets)
            ..where((a) => a.id.equals(assetOne.id)))
          .getSingle();
      expect(assetOne1.shares, closeTo(1233.32544, 1e-9));
      expect(assetOne1.value, closeTo(47.452196304, 1e-9));
      expect(assetOne1.buyFeeTotal, closeTo(0.047499696, 1e-9));
      expect(assetOne1.brokerCostBasis,
          closeTo((47.452196304 + 0.047499696) / 1233.32544, 1e-9));
      expect(assetOne1.netCostBasis, closeTo(47.452196304 / 1233.32544, 1e-9));

      final source1 = await (db.select(db.accounts)
            ..where((a) => a.id.equals(sourceAccount.id)))
          .getSingle();
      expect(source1.balance, closeTo(5000 - 47.452196304 - 0.047499696, 1e-9));

      final target1 = await (db.select(db.accounts)
            ..where((a) => a.id.equals(targetAccount.id)))
          .getSingle();
      expect(target1.balance, closeTo(0 + 47.452196304, 1e-9));

      // Trade 2
      await tradesDao.insertTrade(
          TradesCompanion(
            datetime: const drift.Value(20241210143623),
            assetId: drift.Value(assetOne.id),
            type: const drift.Value(TradeTypes.sell),
            shares: const drift.Value(233.32),
            costBasis: const drift.Value(0.042433032),
            fee: const drift.Value(0),
            tax: const drift.Value(0),
            sourceAccountId: drift.Value(sourceAccount.id),
            targetAccountId: drift.Value(targetAccount.id),
          ),
          l10n);

      final trade2 = await (db.select(db.trades)..where((t) => t.id.equals(2)))
          .getSingle();
      expect(trade2.sourceAccountValueDelta, closeTo(9.90047502624, 1e-9));
      expect(trade2.targetAccountValueDelta, closeTo(-8.976987, 1e-9));
      expect(trade2.profitAndLoss, closeTo(0.92348802624, 1e-9));
      // expect(trade2.returnOnInvest, closeTo(0.92348802624, 1e-9));

      final aoaOne2 = await (db.select(db.assetsOnAccounts)
            ..where((a) =>
                a.assetId.equals(assetOne.id) &
                a.accountId.equals(targetAccount.id)))
          .getSingle();
      expect(aoaOne2.shares, closeTo(1000.00544, 1e-9));
      expect(aoaOne2.value, closeTo(38.475209304, 1e-9));
      expect(aoaOne2.buyFeeTotal, closeTo(0.03851372303, 1e-9));
      expect(aoaOne2.brokerCostBasis,
          closeTo((38.4752093 + 0.03851372303) / 1000.00544, 1e-9));
      expect(aoaOne2.netCostBasis, closeTo(38.4752093 / 1000.00544, 1e-9));

      final assetOne2 = await (db.select(db.assets)
            ..where((a) => a.id.equals(assetOne.id)))
          .getSingle();
      expect(assetOne2.shares, closeTo(1000.00544, 1e-9));
      expect(assetOne2.value, closeTo(38.475209304, 1e-9));
      expect(assetOne2.buyFeeTotal, closeTo(0.03851372303, 1e-9));
      expect(assetOne2.brokerCostBasis,
          closeTo((38.4752093 + 0.03851372303) / 1000.00544, 1e-9));
      expect(assetOne2.netCostBasis, closeTo(38.4752093 / 1000.00544, 1e-9));

      final source2 = await (db.select(db.accounts)
            ..where((a) => a.id.equals(sourceAccount.id)))
          .getSingle();
      expect(source2.balance, closeTo(4952.500304 + 9.90047502624, 1e-9));

      final target2 = await (db.select(db.accounts)
            ..where((a) => a.id.equals(targetAccount.id)))
          .getSingle();
      expect(target2.balance, closeTo(47.452196304 - 8.976987, 1e-9));

      // Trade 3
      await tradesDao.insertTrade(
          TradesCompanion(
            datetime: const drift.Value(20241210143623),
            assetId: drift.Value(assetOne.id),
            type: const drift.Value(TradeTypes.sell),
            shares: const drift.Value(1000),
            costBasis: const drift.Value(0.042433032),
            fee: const drift.Value(0),
            tax: const drift.Value(0),
            sourceAccountId: drift.Value(sourceAccount.id),
            targetAccountId: drift.Value(targetAccount.id),
          ),
          l10n);

      final trade3 = await (db.select(db.trades)..where((t) => t.id.equals(3)))
          .getSingle();
      expect(trade3.sourceAccountValueDelta, closeTo(42.433032, 1e-9));
      expect(trade3.targetAccountValueDelta, closeTo(-38.475, 1e-9));

      final aoaOne3 = await (db.select(db.assetsOnAccounts)
            ..where((a) =>
                a.assetId.equals(assetOne.id) &
                a.accountId.equals(targetAccount.id)))
          .getSingle();
      expect(aoaOne3.shares, closeTo(0.00544, 1e-9));
      expect(aoaOne3.value, closeTo(0.000209304, 1e-9));
      expect(aoaOne3.buyFeeTotal, closeTo(0.00000020951, 1e-9));
      expect(aoaOne3.brokerCostBasis,
          closeTo((0.000209304 + 0.00000020951) / 0.00544, 1e-9));
      expect(aoaOne3.netCostBasis, closeTo(0.000209304 / 0.00544, 1e-9));

      final assetOne3 = await (db.select(db.assets)
            ..where((a) => a.id.equals(assetOne.id)))
          .getSingle();
      expect(assetOne3.shares, closeTo(0.00544, 1e-9));
      expect(assetOne3.value, closeTo(0.000209304, 1e-9));
      expect(assetOne3.buyFeeTotal, closeTo(0.00000020951, 1e-9));
      expect(assetOne3.brokerCostBasis,
          closeTo((0.000209304 + 0.00000020951) / 0.00544, 1e-9));
      expect(assetOne3.netCostBasis, closeTo(0.000209304 / 0.00544, 1e-9));

      final source3 = await (db.select(db.accounts)
            ..where((a) => a.id.equals(sourceAccount.id)))
          .getSingle();
      expect(source3.balance, closeTo(5004.83381102624, 1e-9));

      final target3 = await (db.select(db.accounts)
            ..where((a) => a.id.equals(targetAccount.id)))
          .getSingle();
      expect(target3.balance, closeTo(0.000209304, 1e-9));
    });

    test('buy 2, buy 2, sell 3 - test one sell consumes more than one lot',
        () async {
      await tradesDao.insertTrade(
          TradesCompanion(
            datetime: const drift.Value(20250101000000),
            assetId: drift.Value(assetOne.id),
            type: const drift.Value(TradeTypes.buy),
            shares: const drift.Value(2),
            costBasis: const drift.Value(10),
            fee: const drift.Value(1),
            tax: const drift.Value(0),
            sourceAccountId: drift.Value(sourceAccount.id),
            targetAccountId: drift.Value(targetAccount.id),
          ),
          l10n);

      await tradesDao.insertTrade(
          TradesCompanion(
            datetime: const drift.Value(20250102000000),
            assetId: drift.Value(assetOne.id),
            type: const drift.Value(TradeTypes.buy),
            shares: const drift.Value(2),
            costBasis: const drift.Value(15),
            fee: const drift.Value(1),
            tax: const drift.Value(0),
            sourceAccountId: drift.Value(sourceAccount.id),
            targetAccountId: drift.Value(targetAccount.id),
          ),
          l10n);

      await tradesDao.insertTrade(
          TradesCompanion(
            datetime: const drift.Value(20250103000000),
            assetId: drift.Value(assetOne.id),
            type: const drift.Value(TradeTypes.sell),
            shares: const drift.Value(3),
            costBasis: const drift.Value(20),
            fee: const drift.Value(1),
            tax: const drift.Value(0),
            sourceAccountId: drift.Value(sourceAccount.id),
            targetAccountId: drift.Value(targetAccount.id),
          ),
          l10n);

      final aoaOne1 = await (db.select(db.assetsOnAccounts)
            ..where((a) =>
                a.assetId.equals(assetOne.id) &
                a.accountId.equals(targetAccount.id)))
          .getSingle();
      expect(aoaOne1.shares, closeTo(1, 1e-9));
      expect(aoaOne1.value, closeTo(15, 1e-9));
      expect(aoaOne1.buyFeeTotal, closeTo(0.5, 1e-9));
      expect(aoaOne1.brokerCostBasis, closeTo((15 + 0.5) / 1, 1e-9));
      expect(aoaOne1.netCostBasis, closeTo(15 / 1, 1e-9));

      final assetOne1 = await (db.select(db.assets)
            ..where((a) => a.id.equals(assetOne.id)))
          .getSingle();
      expect(assetOne1.shares, closeTo(1, 1e-9));
      expect(assetOne1.value, closeTo(15, 1e-9));
      expect(assetOne1.buyFeeTotal, closeTo(0.5, 1e-9));
      expect(assetOne1.brokerCostBasis, closeTo((15 + 0.5) / 1, 1e-9));
      expect(assetOne1.netCostBasis, closeTo(15 / 1, 1e-9));

      final source1 = await (db.select(db.accounts)
            ..where((a) => a.id.equals(sourceAccount.id)))
          .getSingle();
      expect(source1.balance, closeTo(5000 - 20 - 30 + 60 - 3, 1e-9));

      final target1 = await (db.select(db.accounts)
            ..where((a) => a.id.equals(targetAccount.id)))
          .getSingle();
      expect(target1.balance, closeTo(0 + 20 + 30 - 20 - 15, 1e-9));
    });
  });

  group('getTrade', () {
    test('insert trade then getTrade returns it', () async {
      final assetId = await db.into(db.assets).insert(const AssetsCompanion(
            name: drift.Value('DEL'),
            type: drift.Value(AssetTypes.stock),
            tickerSymbol: drift.Value('DEL'),
            value: drift.Value(0.0),
            shares: drift.Value(0.0),
            netCostBasis: drift.Value(0.0),
            brokerCostBasis: drift.Value(0.0),
            buyFeeTotal: drift.Value(0.0),
          ));

      final sourceId =
          await db.into(db.accounts).insert(const AccountsCompanion(
                name: drift.Value('Cdel'),
                balance: drift.Value(10.0),
                initialBalance: drift.Value(10.0),
                type: drift.Value(AccountTypes.cash),
              ));

      final targetId =
          await db.into(db.accounts).insert(const AccountsCompanion(
                name: drift.Value('Pdel'),
                balance: drift.Value(0.0),
                initialBalance: drift.Value(0.0),
                type: drift.Value(AccountTypes.portfolio),
              ));

      final id = await db.into(db.trades).insert(TradesCompanion(
          datetime: const drift.Value(20250103120000),
          assetId: drift.Value(assetId),
          type: const drift.Value(TradeTypes.buy),
          shares: const drift.Value(1.0),
          costBasis: const drift.Value(1.0),
          fee: const drift.Value(0.0),
          tax: const drift.Value(0.0),
          sourceAccountId: drift.Value(sourceId),
          targetAccountId: drift.Value(targetId),
          sourceAccountValueDelta: const drift.Value(-1.0),
          targetAccountValueDelta: const drift.Value(1.0),
          profitAndLoss: const drift.Value(0),
          returnOnInvest: const drift.Value(0)));

      final fetched = await tradesDao.getTrade(id);
      expect(fetched.id, id);
    });
  });

  // ------------------------
  // New tests for backdated flows => now insertTrade/updateTrade/deleteTrade
  // ------------------------
  group('backdated trades (insert/update/delete) — renamed public API', () {
    test('backdated insert (buy) before sell updates later sell P&L', () async {
      // Initial buy at 2025-01-02: 2 shares @10
      await tradesDao.insertTrade(
          TradesCompanion(
            datetime: const drift.Value(20250102000000),
            assetId: drift.Value(assetOne.id),
            type: const drift.Value(TradeTypes.buy),
            shares: const drift.Value(2.0),
            costBasis: const drift.Value(10.0),
            fee: const drift.Value(0.0),
            tax: const drift.Value(0.0),
            sourceAccountId: drift.Value(sourceAccount.id),
            targetAccountId: drift.Value(targetAccount.id),
          ),
          l10n);

      // Sell at 2025-01-03: 1 share @20 -> consumes 1@10, P&L = 20 - 10 = 10
      await tradesDao.insertTrade(
          TradesCompanion(
            datetime: const drift.Value(20250103000000),
            assetId: drift.Value(assetOne.id),
            type: const drift.Value(TradeTypes.sell),
            shares: const drift.Value(1.0),
            costBasis: const drift.Value(20.0),
            fee: const drift.Value(0.0),
            tax: const drift.Value(0.0),
            sourceAccountId: drift.Value(sourceAccount.id),
            targetAccountId: drift.Value(targetAccount.id),
          ),
          l10n);

      // Verify initial sell profit
      final sellBefore = await (db.select(db.trades)
            ..where((t) =>
                t.assetId.equals(assetOne.id) &
                t.type.equals(TradeTypes.sell.name) &
                t.datetime.equals(20250103000000)))
          .getSingle();
      expect(sellBefore.profitAndLoss, closeTo(10.0, 1e-9));

      // Now insert a backdated buy at 2025-01-01: 1 share @5
      final backdatedBuy = TradesCompanion(
        datetime: const drift.Value(20250101000000),
        assetId: drift.Value(assetOne.id),
        type: const drift.Value(TradeTypes.buy),
        shares: const drift.Value(1.0),
        costBasis: const drift.Value(5.0),
        fee: const drift.Value(0.0),
        tax: const drift.Value(0.0),
        sourceAccountId: drift.Value(sourceAccount.id),
        targetAccountId: drift.Value(targetAccount.id),
      );

      await tradesDao.insertTrade(backdatedBuy, l10n);

      // After backdated insert, the sell should now consume the cheaper lot (1@5) -> new profit 20 - 5 = 15
      final sellAfter = await (db.select(db.trades)
            ..where((t) =>
                t.assetId.equals(assetOne.id) &
                t.type.equals(TradeTypes.sell.name) &
                t.datetime.equals(20250103000000)))
          .getSingle();
      expect(sellAfter.profitAndLoss, closeTo(15.0, 1e-9));
    });

    test('backdated insert (sell) that is impossible is rejected', () async {
      // Setup: a buy at 2025-01-02 of 1 share
      await tradesDao.insertTrade(
          TradesCompanion(
            datetime: const drift.Value(20250102000000),
            assetId: drift.Value(assetOne.id),
            type: const drift.Value(TradeTypes.buy),
            shares: const drift.Value(1.0),
            costBasis: const drift.Value(10.0),
            fee: const drift.Value(0.0),
            tax: const drift.Value(0.0),
            sourceAccountId: drift.Value(sourceAccount.id),
            targetAccountId: drift.Value(targetAccount.id),
          ),
          l10n);

      // Try to insert a backdated sell at 2025-01-01 of 2 shares -> impossible (0 shares at that time)
      final backdatedImpossibleSell = TradesCompanion(
        datetime: const drift.Value(20250101000000),
        assetId: drift.Value(assetOne.id),
        type: const drift.Value(TradeTypes.sell),
        shares: const drift.Value(2.0),
        costBasis: const drift.Value(20.0),
        fee: const drift.Value(0.0),
        tax: const drift.Value(0.0),
        sourceAccountId: drift.Value(sourceAccount.id),
        targetAccountId: drift.Value(targetAccount.id),
      );

      expect(
          () async =>
              await tradesDao.insertTrade(backdatedImpossibleSell, l10n),
          throwsA(isA<Exception>()));
    });

    test('backdated update (move buy after sell) recomputes later sell P&L',
        () async {
      // buy1 @2025-01-01 (1@10)
      await tradesDao.insertTrade(
          TradesCompanion(
            datetime: const drift.Value(20250101000000),
            assetId: drift.Value(assetOne.id),
            type: const drift.Value(TradeTypes.buy),
            shares: const drift.Value(1.0),
            costBasis: const drift.Value(10.0),
            fee: const drift.Value(0.0),
            tax: const drift.Value(0.0),
            sourceAccountId: drift.Value(sourceAccount.id),
            targetAccountId: drift.Value(targetAccount.id),
          ),
          l10n);

      // buy2 @2025-01-03 (1@20)
      await tradesDao.insertTrade(
          TradesCompanion(
            datetime: const drift.Value(20250103000000),
            assetId: drift.Value(assetOne.id),
            type: const drift.Value(TradeTypes.buy),
            shares: const drift.Value(1.0),
            costBasis: const drift.Value(20.0),
            fee: const drift.Value(0.0),
            tax: const drift.Value(0.0),
            sourceAccountId: drift.Value(sourceAccount.id),
            targetAccountId: drift.Value(targetAccount.id),
          ),
          l10n);

      // sell @2025-01-04 (1@30) -> consumes buy1 (10) => profit 20
      await tradesDao.insertTrade(
          TradesCompanion(
            datetime: const drift.Value(20250104000000),
            assetId: drift.Value(assetOne.id),
            type: const drift.Value(TradeTypes.sell),
            shares: const drift.Value(1.0),
            costBasis: const drift.Value(30.0),
            fee: const drift.Value(0.0),
            tax: const drift.Value(0.0),
            sourceAccountId: drift.Value(sourceAccount.id),
            targetAccountId: drift.Value(targetAccount.id),
          ),
          l10n);

      // Check initial profit (should be 30 - 10 = 20)
      final sellBefore = await (db.select(db.trades)
            ..where((t) =>
                t.assetId.equals(assetOne.id) &
                t.type.equals(TradeTypes.sell.name) &
                t.datetime.equals(20250104000000)))
          .getSingle();
      expect(sellBefore.profitAndLoss, closeTo(20.0, 1e-9));

      // Now move buy1 to 2025-01-05 (after the sell) via updateTrade -> the sell should now consume buy2 (20) => profit 10
      const updateComp = TradesCompanion(
        datetime: drift.Value(20250105000000),
      );

      // original buy1 has id 1
      await tradesDao.updateTrade(1, updateComp, l10n);

      final sellAfter = await (db.select(db.trades)
            ..where((t) =>
                t.assetId.equals(assetOne.id) &
                t.type.equals(TradeTypes.sell.name) &
                t.datetime.equals(20250104000000)))
          .getSingle();
      expect(sellAfter.profitAndLoss, closeTo(10.0, 1e-9));
    });

    test('trade gets correctly updated', () async {
      // first trade, so id = 1
      await tradesDao.insertTrade(
          TradesCompanion(
            datetime: const drift.Value(20250101000000),
            assetId: drift.Value(assetOne.id),
            type: const drift.Value(TradeTypes.buy),
            shares: const drift.Value(1.0),
            costBasis: const drift.Value(10.0),
            fee: const drift.Value(0.0),
            tax: const drift.Value(0.0),
            sourceAccountId: drift.Value(sourceAccount.id),
            targetAccountId: drift.Value(targetAccount.id),
          ),
          l10n);

      // Pre-update checks
      final preUpdateTradeList = await db.tradesDao.getAllTrades();
      expect(preUpdateTradeList.length, 1);
      final preUpdateTrade = preUpdateTradeList[0];
      expect(preUpdateTrade.id, 1);
      expect(preUpdateTrade.datetime, 20250101000000);
      expect(preUpdateTrade.shares, 1);
      expect(preUpdateTrade.costBasis, 10);
      expect(preUpdateTrade.fee, 0);
      expect(preUpdateTrade.tax, 0);
      expect(preUpdateTrade.sourceAccountValueDelta, -10);
      expect(preUpdateTrade.targetAccountValueDelta, 10);

      await tradesDao.updateTrade(
          1,
          const TradesCompanion(
              datetime: drift.Value(20250102000000),
              shares: drift.Value(1.5),
              costBasis: drift.Value(12.0),
              fee: drift.Value(1.0),
              tax: drift.Value(1.0)),
          l10n);

      // Post-update checks
      final postUpdateTradeList = await db.tradesDao.getAllTrades();
      expect(postUpdateTradeList.length, 1);
      final postUpdateTrade = postUpdateTradeList[0];
      expect(postUpdateTrade.id, 1);
      expect(postUpdateTrade.datetime, 20250102000000);
      expect(postUpdateTrade.shares, 1.5);
      expect(postUpdateTrade.costBasis, 12);
      expect(postUpdateTrade.fee, 1);
      expect(postUpdateTrade.tax, 1);
      expect(postUpdateTrade.sourceAccountValueDelta, -19);
      expect(postUpdateTrade.targetAccountValueDelta, 18);
    });

    test('backdated delete adjusts later sell P&L', () async {
      // buy1 @2025-01-01 (1@10)
      await tradesDao.insertTrade(
          TradesCompanion(
            datetime: const drift.Value(20250101000000),
            assetId: drift.Value(assetOne.id),
            type: const drift.Value(TradeTypes.buy),
            shares: const drift.Value(1.0),
            costBasis: const drift.Value(10.0),
            fee: const drift.Value(0.0),
            tax: const drift.Value(0.0),
            sourceAccountId: drift.Value(sourceAccount.id),
            targetAccountId: drift.Value(targetAccount.id),
          ),
          l10n);

      // buy2 @2025-01-03 (1@20)
      await tradesDao.insertTrade(
          TradesCompanion(
            datetime: const drift.Value(20250103000000),
            assetId: drift.Value(assetOne.id),
            type: const drift.Value(TradeTypes.buy),
            shares: const drift.Value(1.0),
            costBasis: const drift.Value(20.0),
            fee: const drift.Value(0.0),
            tax: const drift.Value(0.0),
            sourceAccountId: drift.Value(sourceAccount.id),
            targetAccountId: drift.Value(targetAccount.id),
          ),
          l10n);

      // sell @2025-01-04 (1@30) -> consumes buy1 (10) => profit 20
      await tradesDao.insertTrade(
          TradesCompanion(
            datetime: const drift.Value(20250104000000),
            assetId: drift.Value(assetOne.id),
            type: const drift.Value(TradeTypes.sell),
            shares: const drift.Value(1.0),
            costBasis: const drift.Value(30.0),
            fee: const drift.Value(0.0),
            tax: const drift.Value(0.0),
            sourceAccountId: drift.Value(sourceAccount.id),
            targetAccountId: drift.Value(targetAccount.id),
          ),
          l10n);

      // Confirm initial profit
      final sellBefore = await (db.select(db.trades)
            ..where((t) =>
                t.assetId.equals(assetOne.id) &
                t.type.equals(TradeTypes.sell.name) &
                t.datetime.equals(20250104000000)))
          .getSingle();
      expect(sellBefore.profitAndLoss, closeTo(20.0, 1e-9));

      // Delete buy1 (id 1). The sell should then consume buy2 (20) -> profit 10
      await tradesDao.deleteTrade(1, l10n);

      final sellAfter = await (db.select(db.trades)
            ..where((t) =>
                t.assetId.equals(assetOne.id) &
                t.type.equals(TradeTypes.sell.name) &
                t.datetime.equals(20250104000000)))
          .getSingle();
      expect(sellAfter.profitAndLoss, closeTo(10.0, 1e-9));
    });

    test(
        'bookings and transfers are included in FIFO (booking -> sell allowed)',
        () async {
      // Create a booking that gives targetAccount 5 shares of assetOne at date 20250101
      await db.bookingsDao.createBooking(
          BookingsCompanion.insert(
            date: 20250101,
            assetId: drift.Value(assetOne.id),
            accountId: targetAccount.id,
            category: 'test-booking',
            shares: 5.0,
            value: 50.0,
          ),
          l10n);

      // Now attempt to sell 5 shares later -> should be possible and consume booking lot
      await tradesDao.insertTrade(
          TradesCompanion(
            datetime: const drift.Value(20250102000000),
            assetId: drift.Value(assetOne.id),
            type: const drift.Value(TradeTypes.sell),
            shares: const drift.Value(5.0),
            costBasis: const drift.Value(12.0),
            fee: const drift.Value(0.0),
            tax: const drift.Value(0.0),
            sourceAccountId: drift.Value(sourceAccount.id),
            targetAccountId: drift.Value(targetAccount.id),
          ),
          l10n);

      final sold = await (db.select(db.trades)
            ..where((t) =>
                t.assetId.equals(assetOne.id) &
                t.type.equals(TradeTypes.sell.name) &
                t.datetime.equals(20250102000000)))
          .getSingle();
      expect(sold.sourceAccountValueDelta, closeTo(60.0, 1e-9));
    });

    test(
        'transfers into account are considered by FIFO (transfer -> sell allowed)',
        () async {
      // Create a second account that holds assetOne previously
      Account other = const Account(
        id: 4,
        name: 'Other',
        balance: 0,
        initialBalance: 0,
        type: AccountTypes.portfolio,
        isArchived: false,
      );
      await db.accountsDao.insert(other.toCompanion(false));

      // Put 3 shares of assetOne on the other account
      await db.into(db.assetsOnAccounts).insert(AssetsOnAccountsCompanion(
            assetId: drift.Value(assetOne.id),
            accountId: drift.Value(other.id),
            shares: const drift.Value(3.0),
            value: const drift.Value(30.0),
            netCostBasis: const drift.Value(10.0),
            brokerCostBasis: const drift.Value(10.0),
            buyFeeTotal: const drift.Value(0.0),
          ));
      await (db.update(db.assets)..where((a) => a.id.equals(assetOne.id)))
          .write(const AssetsCompanion(
              shares: drift.Value(3.0),
              value: drift.Value(30.0),
              buyFeeTotal: drift.Value(0.0)));

      // Transfer those 3 shares into targetAccount on date 20250101
      await db.transfersDao.createTransfer(
          TransfersCompanion.insert(
            date: 20250101,
            sendingAccountId: other.id,
            receivingAccountId: targetAccount.id,
            assetId: drift.Value(assetOne.id),
            shares: 3.0,
            costBasis: const drift.Value(10.0),
            value: 30.0,
          ),
          l10n);

      // Now sell 3 shares from targetAccount later -> should be allowed (consumes transfer)
      await tradesDao.insertTrade(
          TradesCompanion(
            datetime: const drift.Value(20250102000000),
            assetId: drift.Value(assetOne.id),
            type: const drift.Value(TradeTypes.sell),
            shares: const drift.Value(3.0),
            costBasis: const drift.Value(15.0),
            fee: const drift.Value(0.0),
            tax: const drift.Value(0.0),
            sourceAccountId: drift.Value(sourceAccount.id),
            targetAccountId: drift.Value(targetAccount.id),
          ),
          l10n);

      final sold = await (db.select(db.trades)
            ..where((t) =>
                t.assetId.equals(assetOne.id) &
                t.type.equals(TradeTypes.sell.name) &
                t.datetime.equals(20250102000000)))
          .getSingle();
      expect(sold.sourceAccountValueDelta, closeTo(45.0, 1e-9));
    });
  });

  // ----------------------------
  // extra coverage — more branches & edge cases
  // ----------------------------
  group('extra coverage — more branches & edge cases', () {
    test(
        'updateTrade that moves a buy after an existing sell with no other coverage throws (insufficient shares)',
        () async {
      // Setup: single buy (id 1) and single sell (id 2)
      await tradesDao.insertTrade(
          TradesCompanion(
            datetime: const drift.Value(20250101000000),
            assetId: drift.Value(assetOne.id),
            type: const drift.Value(TradeTypes.buy),
            shares: const drift.Value(1.0),
            costBasis: const drift.Value(10.0),
            fee: const drift.Value(0.0),
            tax: const drift.Value(0.0),
            sourceAccountId: drift.Value(sourceAccount.id),
            targetAccountId: drift.Value(targetAccount.id),
          ),
          l10n);

      await tradesDao.insertTrade(
          TradesCompanion(
            datetime: const drift.Value(20250102000000),
            assetId: drift.Value(assetOne.id),
            type: const drift.Value(TradeTypes.sell),
            shares: const drift.Value(1.0),
            costBasis: const drift.Value(20.0),
            fee: const drift.Value(0.0),
            tax: const drift.Value(0.0),
            sourceAccountId: drift.Value(sourceAccount.id),
            targetAccountId: drift.Value(targetAccount.id),
          ),
          l10n);

      // Move buy (id=1) after the sell -> should make the sell invalid and updateTrade should throw
      const updateToAfterSell = TradesCompanion(
        datetime: drift.Value(20250103000000),
      );

      expect(
          () async => await tradesDao.updateTrade(1, updateToAfterSell, l10n),
          throwsA(isA<Exception>()));
    });

    test(
        'deleteTrade that would leave later sells without coverage throws (cannot reapply)',
        () async {
      // buy id1, sell id2
      await tradesDao.insertTrade(
          TradesCompanion(
            datetime: const drift.Value(20250101000000),
            assetId: drift.Value(assetOne.id),
            type: const drift.Value(TradeTypes.buy),
            shares: const drift.Value(1.0),
            costBasis: const drift.Value(10.0),
            fee: const drift.Value(0.0),
            tax: const drift.Value(0.0),
            sourceAccountId: drift.Value(sourceAccount.id),
            targetAccountId: drift.Value(targetAccount.id),
          ),
          l10n);

      await tradesDao.insertTrade(
          TradesCompanion(
            datetime: const drift.Value(20250102000000),
            assetId: drift.Value(assetOne.id),
            type: const drift.Value(TradeTypes.sell),
            shares: const drift.Value(1.0),
            costBasis: const drift.Value(20.0),
            fee: const drift.Value(0.0),
            tax: const drift.Value(0.0),
            sourceAccountId: drift.Value(sourceAccount.id),
            targetAccountId: drift.Value(targetAccount.id),
          ),
          l10n);

      // Deleting buy id1 would leave the sell uncovered -> deleteTrade should throw
      expect(() async => await tradesDao.deleteTrade(1, l10n),
          throwsA(isA<Exception>()));
    });

    test('sell with fee and tax calculates profit and deltas correctly',
        () async {
      // buy 1@10
      await tradesDao.insertTrade(
          TradesCompanion(
            datetime: const drift.Value(20250101000000),
            assetId: drift.Value(assetOne.id),
            type: const drift.Value(TradeTypes.buy),
            shares: const drift.Value(1.0),
            costBasis: const drift.Value(10.0),
            fee: const drift.Value(0.0),
            tax: const drift.Value(0.0),
            sourceAccountId: drift.Value(sourceAccount.id),
            targetAccountId: drift.Value(targetAccount.id),
          ),
          l10n);

      // sell 1@20 with fee=1 tax=2
      await tradesDao.insertTrade(
          TradesCompanion(
            datetime: const drift.Value(20250102000000),
            assetId: drift.Value(assetOne.id),
            type: const drift.Value(TradeTypes.sell),
            shares: const drift.Value(1.0),
            costBasis: const drift.Value(20.0),
            fee: const drift.Value(1.0),
            tax: const drift.Value(2.0),
            sourceAccountId: drift.Value(sourceAccount.id),
            targetAccountId: drift.Value(targetAccount.id),
          ),
          l10n);

      final sell = await (db.select(db.trades)
            ..where((t) =>
                t.assetId.equals(assetOne.id) &
                t.type.equals(TradeTypes.sell.name) &
                t.datetime.equals(20250102000000)))
          .getSingle();

      // calculations from code:
      // sourceAccountValueDelta = movedValue - fee - tax = 20 -1 -2 = 17
      // targetAccountValueDelta = -costBasisConsumed = -10
      // profitAndLoss = source + target - fee + tax = 17 + (-10) -1 +2 = 8
      expect(sell.sourceAccountValueDelta, closeTo(17.0, 1e-9));
      expect(sell.targetAccountValueDelta, closeTo(-10.0, 1e-9));
      expect(sell.profitAndLoss, closeTo(8.0, 1e-9));
    });

    test('updateTrade changing a buy costBasis recomputes later sell P&L',
        () async {
      // buy1 @day1: 1@10 (id 1)
      await tradesDao.insertTrade(
          TradesCompanion(
            datetime: const drift.Value(20250101000000),
            assetId: drift.Value(assetOne.id),
            type: const drift.Value(TradeTypes.buy),
            shares: const drift.Value(1.0),
            costBasis: const drift.Value(10.0),
            fee: const drift.Value(0.0),
            tax: const drift.Value(0.0),
            sourceAccountId: drift.Value(sourceAccount.id),
            targetAccountId: drift.Value(targetAccount.id),
          ),
          l10n);

      // buy2 @day2: 2@15 (id 2)
      await tradesDao.insertTrade(
          TradesCompanion(
            datetime: const drift.Value(20250102000000),
            assetId: drift.Value(assetOne.id),
            type: const drift.Value(TradeTypes.buy),
            shares: const drift.Value(2.0),
            costBasis: const drift.Value(15.0),
            fee: const drift.Value(0.0),
            tax: const drift.Value(0.0),
            sourceAccountId: drift.Value(sourceAccount.id),
            targetAccountId: drift.Value(targetAccount.id),
          ),
          l10n);

      // sell @day3: 2@20 (consumes buy1 (1@10) + 1 from buy2 (1@15))
      await tradesDao.insertTrade(
          TradesCompanion(
            datetime: const drift.Value(20250103000000),
            assetId: drift.Value(assetOne.id),
            type: const drift.Value(TradeTypes.sell),
            shares: const drift.Value(2.0),
            costBasis: const drift.Value(20.0),
            fee: const drift.Value(0.0),
            tax: const drift.Value(0.0),
            sourceAccountId: drift.Value(sourceAccount.id),
            targetAccountId: drift.Value(targetAccount.id),
          ),
          l10n);

      final sellBefore = await (db.select(db.trades)
            ..where((t) =>
                t.assetId.equals(assetOne.id) &
                t.type.equals(TradeTypes.sell.name) &
                t.datetime.equals(20250103000000)))
          .getSingle();

      // Expected cost consumed = 10 + 15 = 25, proceeds = 40 -> profit = 15
      expect(sellBefore.profitAndLoss, closeTo(15.0, 1e-9));

      // Now change buy2's costBasis to 5 via updateTrade (id 2)
      await tradesDao.updateTrade(
          2, const TradesCompanion(costBasis: drift.Value(5.0)), l10n);

      final sellAfter = await (db.select(db.trades)
            ..where((t) =>
                t.assetId.equals(assetOne.id) &
                t.type.equals(TradeTypes.sell.name) &
                t.datetime.equals(20250103000000)))
          .getSingle();

      // Now expected cost consumed = 10 + 5 = 15, proceeds = 40 -> profit = 25
      expect(sellAfter.profitAndLoss, closeTo(25.0, 1e-9));
    });
  });

  group('TradesDao – trade reordering, validation and balance consistency', () {
    test(
        'reordering trades correctly reapplies FIFO lots and preserves balances',
        () async {
      // Initial buy
      await tradesDao.insertTrade(
          TradesCompanion(
            datetime: const drift.Value(20250101000000),
            assetId: drift.Value(assetOne.id),
            type: const drift.Value(TradeTypes.buy),
            shares: const drift.Value(10),
            costBasis: const drift.Value(10),
            fee: const drift.Value(5),
            tax: const drift.Value(0),
            sourceAccountId: drift.Value(sourceAccount.id),
            targetAccountId: drift.Value(targetAccount.id),
          ),
          l10n);

      // Two sells that will later be undone and reapplied
      await tradesDao.insertTrade(
          TradesCompanion(
            datetime: const drift.Value(20250102000000),
            assetId: drift.Value(assetOne.id),
            type: const drift.Value(TradeTypes.sell),
            shares: const drift.Value(4),
            costBasis: const drift.Value(12),
            fee: const drift.Value(0),
            tax: const drift.Value(0),
            sourceAccountId: drift.Value(sourceAccount.id),
            targetAccountId: drift.Value(targetAccount.id),
          ),
          l10n);

      await tradesDao.insertTrade(
          TradesCompanion(
            datetime: const drift.Value(20250103000000),
            assetId: drift.Value(assetOne.id),
            type: const drift.Value(TradeTypes.sell),
            shares: const drift.Value(4),
            costBasis: const drift.Value(11),
            fee: const drift.Value(0),
            tax: const drift.Value(0),
            sourceAccountId: drift.Value(sourceAccount.id),
            targetAccountId: drift.Value(targetAccount.id),
          ),
          l10n);

      // Backdated buy forces undo/reapply with partial FIFO lot consumption
      await tradesDao.insertTrade(
          TradesCompanion(
            datetime: const drift.Value(20250101500000),
            assetId: drift.Value(assetOne.id),
            type: const drift.Value(TradeTypes.buy),
            shares: const drift.Value(1),
            costBasis: const drift.Value(9),
            fee: const drift.Value(1),
            tax: const drift.Value(0),
            sourceAccountId: drift.Value(sourceAccount.id),
            targetAccountId: drift.Value(targetAccount.id),
          ),
          l10n);

      final aoa = await (db.select(db.assetsOnAccounts)
            ..where((a) =>
                a.assetId.equals(assetOne.id) &
                a.accountId.equals(targetAccount.id)))
          .getSingle();

      // 10 + 1 − 4 − 4 = 3
      expect(aoa.shares, closeTo(3, 1e-9));

      final asset = await (db.select(db.assets)
            ..where((a) => a.id.equals(assetOne.id)))
          .getSingle();
      expect(asset.shares, closeTo(3, 1e-9));

      final source = await (db.select(db.accounts)
            ..where((a) => a.id.equals(sourceAccount.id)))
          .getSingle();
      final target = await (db.select(db.accounts)
            ..where((a) => a.id.equals(targetAccount.id)))
          .getSingle();

      expect(source.balance.isFinite, true);
      expect(target.balance.isFinite, true);
      expect(aoa.buyFeeTotal >= 0, true);
    });

    test(
        'updating a sell to an earlier datetime that would be invalid is rejected',
        () async {
      // buy (id = 1)
      await tradesDao.insertTrade(
          TradesCompanion(
            datetime: const drift.Value(20250103000000),
            assetId: drift.Value(assetOne.id),
            type: const drift.Value(TradeTypes.buy),
            shares: const drift.Value(1),
            costBasis: const drift.Value(10),
            fee: const drift.Value(0),
            tax: const drift.Value(0),
            sourceAccountId: drift.Value(sourceAccount.id),
            targetAccountId: drift.Value(targetAccount.id),
          ),
          l10n);

      // sell (id = 2) — initially valid because it consumes the buy above
      await tradesDao.insertTrade(
          TradesCompanion(
            datetime: const drift.Value(20250104000000),
            assetId: drift.Value(assetOne.id),
            type: const drift.Value(TradeTypes.sell),
            shares: const drift.Value(1),
            costBasis: const drift.Value(20),
            fee: const drift.Value(0),
            tax: const drift.Value(0),
            sourceAccountId: drift.Value(sourceAccount.id),
            targetAccountId: drift.Value(targetAccount.id),
          ),
          l10n);

      // Try to move the existing SELL (id = 2) earlier than the buy -> should fail validation
      expect(
        () async => await tradesDao.updateTrade(
            2,
            const TradesCompanion(
              datetime: drift.Value(20250101000000), // earlier than the buy
            ),
            l10n),
        throwsA(isA<Exception>()),
      );

      // DB must remain consistent: combined effect of buy+sell still leaves zero holdings
      final assetRow = await (db.select(db.assets)
            ..where((a) => a.id.equals(assetOne.id)))
          .getSingle();
      expect(assetRow.shares, closeTo(0, 1e-9));

      final source = await (db.select(db.accounts)
            ..where((a) => a.id.equals(sourceAccount.id)))
          .getSingle();
      expect(source.balance.isFinite, true);
    });

    test(
        'deleting a trade that supports later sells preserves account and asset consistency',
        () async {
      await tradesDao.insertTrade(
          TradesCompanion(
            datetime: const drift.Value(20250101000000),
            assetId: drift.Value(assetOne.id),
            type: const drift.Value(TradeTypes.buy),
            shares: const drift.Value(1),
            costBasis: const drift.Value(10),
            fee: const drift.Value(0),
            tax: const drift.Value(0),
            sourceAccountId: drift.Value(sourceAccount.id),
            targetAccountId: drift.Value(targetAccount.id),
          ),
          l10n);

      await tradesDao.insertTrade(
          TradesCompanion(
            datetime: const drift.Value(20250102000000),
            assetId: drift.Value(assetOne.id),
            type: const drift.Value(TradeTypes.sell),
            shares: const drift.Value(1),
            costBasis: const drift.Value(20),
            fee: const drift.Value(0),
            tax: const drift.Value(0),
            sourceAccountId: drift.Value(sourceAccount.id),
            targetAccountId: drift.Value(targetAccount.id),
          ),
          l10n);

      expect(
        () async => tradesDao.deleteTrade(1, l10n),
        throwsA(isA<Exception>()),
      );

      final aoa = await (db.select(db.assetsOnAccounts)
            ..where((a) =>
                a.assetId.equals(assetOne.id) &
                a.accountId.equals(targetAccount.id)))
          .getSingle();
      expect(aoa.shares, closeTo(0, 1e-9));

      final asset = await (db.select(db.assets)
            ..where((a) => a.id.equals(assetOne.id)))
          .getSingle();
      expect(asset.shares, closeTo(0, 1e-9));

      final source = await (db.select(db.accounts)
            ..where((a) => a.id.equals(sourceAccount.id)))
          .getSingle();
      expect(source.balance.isFinite, true);
    });
  });
}
