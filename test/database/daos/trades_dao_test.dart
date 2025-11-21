import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xfin/database/app_database.dart';
import 'package:xfin/database/daos/trades_dao.dart';
import 'package:xfin/database/tables.dart';

void main() {
  late AppDatabase db;
  late TradesDao tradesDao;

  late Asset baseCurrencyAsset;
  late Asset assetOne;
  late Asset assetTwo;
  late Account clearingAccount;
  late Account portfolioAccount;
  late AssetOnAccount baseCurrencyAssetOnClearingAccount;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    tradesDao = db.tradesDao;

    baseCurrencyAsset = const Asset(
        id: 1,
        name: 'US Dollar',
        type: AssetTypes.currency,
        tickerSymbol: 'USD',
        value: 0,
        sharesOwned: 0,
        netCostBasis: 0,
        brokerCostBasis: 0,
        buyFeeTotal: 0);

    assetOne = const Asset(
        id: 2,
        name: 'Asset One',
        type: AssetTypes.stock,
        tickerSymbol: 'ONE',
        value: 0,
        sharesOwned: 0,
        netCostBasis: 0,
        brokerCostBasis: 0,
        buyFeeTotal: 0);

    assetTwo = const Asset(
        id: 3,
        name: 'Asset Two',
        type: AssetTypes.crypto,
        tickerSymbol: 'TWO',
        value: 0,
        sharesOwned: 0,
        netCostBasis: 0,
        brokerCostBasis: 0,
        buyFeeTotal: 0);

    clearingAccount = const Account(
        id: 1,
        name: 'Clearing Account',
        balance: 5000,
        initialBalance: 5000,
        type: AccountTypes.cash,
        isArchived: false);

    portfolioAccount = const Account(
        id: 2,
        name: 'Portfolio Account',
        balance: 0,
        initialBalance: 0,
        type: AccountTypes.portfolio,
        isArchived: false);

    baseCurrencyAssetOnClearingAccount = const AssetOnAccount(
        assetId: 1,
        accountId: 1,
        sharesOwned: 5000,
        value: 5000,
        netCostBasis: 1,
        brokerCostBasis: 1,
        buyFeeTotal: 0);

    await db.into(db.assets).insert(baseCurrencyAsset.toCompanion(false));
    await db.into(db.assets).insert(assetOne.toCompanion(false));
    await db.into(db.assets).insert(assetTwo.toCompanion(false));
    await db.into(db.accounts).insert(clearingAccount.toCompanion(false));
    await db.into(db.accounts).insert(portfolioAccount.toCompanion(false));
    await db
        .into(db.assetsOnAccounts)
        .insert(baseCurrencyAssetOnClearingAccount.toCompanion(false));
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
          pricePerShare: const drift.Value(10.0),
          tradingFee: const drift.Value(0.0),
          tax: const drift.Value(0.0),
          clearingAccountId: drift.Value(clearingAccount.id),
          portfolioAccountId: drift.Value(portfolioAccount.id),
          clearingAccountValueDelta: const drift.Value(-10.0),
          portfolioAccountValueDelta: const drift.Value(10.0),
          profitAndLossAbs: const drift.Value(0),
          profitAndLossRel: const drift.Value(0)));

      final rows = await tradesDao.watchAllTrades().first;
      expect(rows, isNotEmpty);
      expect(rows.first.asset.name, 'Asset One');
      expect(rows.first.trade.shares, 1.0);
    });
  });

  group('processTrade (buy)', () {
    test(
        'when assetsOnAccounts exists -> updates assetsOnAccounts and accounts and inserts trade',
        () async {
      // Existing assetsOnAccounts (10 shares, value 100)
      await db.into(db.assetsOnAccounts).insert(AssetsOnAccountsCompanion(
          assetId: drift.Value(assetOne.id),
          accountId: drift.Value(portfolioAccount.id),
          sharesOwned: const drift.Value(10.0),
          value: const drift.Value(100.0),
          netCostBasis: const drift.Value(10.0),
          brokerCostBasis: const drift.Value(9.5),
          buyFeeTotal: const drift.Value(5.0)));
      await (db.update(db.assets)..where((a) => a.id.equals(assetOne.id)))
          .write(const AssetsCompanion(
              sharesOwned: drift.Value(10),
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
        pricePerShare: const drift.Value(10.0),
        tradingFee: const drift.Value(1.0),
        tax: const drift.Value(0.0),
        clearingAccountId: drift.Value(clearingAccount.id),
        portfolioAccountId: drift.Value(portfolioAccount.id),
      );

      await tradesDao.processTrade(buyEntry);

      // Check assetOnAccount updated
      final updatedAOA = await (db.select(db.assetsOnAccounts)
            ..where((a) =>
                a.assetId.equals(assetOne.id) &
                a.accountId.equals(portfolioAccount.id)))
          .getSingle();
      expect(updatedAOA.sharesOwned, closeTo(10 + 2, 1e-9));
      expect(updatedAOA.value, closeTo(100 + 2 * 10, 1e-9));
      expect(updatedAOA.buyFeeTotal, closeTo(5 + 1, 1e-9));
      expect(updatedAOA.netCostBasis, closeTo(120.0 / 12.0, 1e-9));
      expect(updatedAOA.brokerCostBasis, closeTo((120.0 + 6.0) / 12.0, 1e-9));

      // Check asset updated
      final updatedAsset = await (db.select(db.assets)
            ..where((a) => a.id.equals(assetOne.id)))
          .getSingle();
      expect(updatedAsset.sharesOwned, closeTo(10 + 2, 1e-9));
      expect(updatedAsset.value, closeTo(100 + 2 * 10, 1e-9));
      expect(updatedAsset.buyFeeTotal, closeTo(5 + 1, 1e-9));
      expect(updatedAsset.netCostBasis, closeTo(120.0 / 12.0, 1e-9));
      expect(updatedAsset.brokerCostBasis, closeTo((120.0 + 6.0) / 12.0, 1e-9));

      // Check accounts updated
      final clearing = await (db.select(db.accounts)
            ..where((a) => a.id.equals(clearingAccount.id)))
          .getSingle();
      expect(clearing.balance, closeTo(5000 - 21, 1e-9));
      final portfolio = await (db.select(db.accounts)
            ..where((a) => a.id.equals(portfolioAccount.id)))
          .getSingle();
      expect(portfolio.balance, closeTo(0 + 20, 1e-9));

      // Check trades inserted and values computed
      final insertedTrade = await (db.select(db.trades)
            ..where((t) =>
                t.assetId.equals(assetOne.id) &
                t.datetime.equals(20250101120001)))
          .getSingle();
      expect(insertedTrade.clearingAccountValueDelta, closeTo(-20 - 1, 1e-9));
      expect(insertedTrade.portfolioAccountValueDelta, closeTo(20, 1e-9));
      expect(insertedTrade.profitAndLossAbs, closeTo(0.0, 1e-9));
      expect(insertedTrade.profitAndLossRel, closeTo(0.0, 1e-9));
    });

    test(
        'when assetsOnAccounts does not exist -> creates it then processes buy',
        () async {
      final newAssetId = await db.into(db.assets).insert(const AssetsCompanion(
            name: drift.Value('New Asset'),
            type: drift.Value(AssetTypes.stock),
            tickerSymbol: drift.Value('NEW'),
            value: drift.Value(0.0),
            sharesOwned: drift.Value(0.0),
            netCostBasis: drift.Value(0.0),
            brokerCostBasis: drift.Value(0.0),
            buyFeeTotal: drift.Value(0.0),
          ));

      // Ensure no assetsOnAccounts row exists initially
      final rowBefore = await (db.select(db.assetsOnAccounts)
            ..where((a) =>
                a.assetId.equals(newAssetId) &
                a.accountId.equals(portfolioAccount.id)))
          .get();
      expect(rowBefore, isEmpty);

      final buyEntry = TradesCompanion(
        datetime: const drift.Value(20250101121000),
        assetId: drift.Value(newAssetId),
        type: const drift.Value(TradeTypes.buy),
        shares: const drift.Value(0.001),
        pricePerShare: const drift.Value(40000),
        tradingFee: const drift.Value(1),
        tax: const drift.Value(0.0),
        clearingAccountId: drift.Value(clearingAccount.id),
        portfolioAccountId: drift.Value(portfolioAccount.id),
      );

      await tradesDao.processTrade(buyEntry);

      // Now assetsOnAccounts should exist and be updated
      final newAssetOnAccount = await (db.select(db.assetsOnAccounts)
            ..where((a) =>
                a.assetId.equals(newAssetId) &
                a.accountId.equals(portfolioAccount.id)))
          .getSingle();

      expect(newAssetOnAccount.sharesOwned, closeTo(0.001, 1e-9));
      expect(newAssetOnAccount.value, closeTo(0.001 * 40000, 1e-9));
      expect(newAssetOnAccount.netCostBasis, closeTo(40 / 0.001, 1e-9));
      expect(
          newAssetOnAccount.brokerCostBasis, closeTo((40 + 1) / 0.001, 1e-9));
      expect(newAssetOnAccount.buyFeeTotal, closeTo(1, 1e-9));
    });
  });

  group('processTrade (sell) and FIFO', () {
    test('complex scenario', () async {
      // Trade 1
      await tradesDao.processTrade(TradesCompanion(
        datetime: const drift.Value(20250101000000),
        assetId: drift.Value(assetOne.id),
        type: const drift.Value(TradeTypes.buy),
        shares: const drift.Value(50),
        pricePerShare: const drift.Value(16.054),
        tradingFee: const drift.Value(1),
        tax: const drift.Value(0),
        clearingAccountId: drift.Value(clearingAccount.id),
        portfolioAccountId: drift.Value(portfolioAccount.id),
      ));

      final aoaOne1 = await (db.select(db.assetsOnAccounts)
            ..where((a) =>
                a.assetId.equals(assetOne.id) &
                a.accountId.equals(portfolioAccount.id)))
          .getSingle();
      expect(aoaOne1.sharesOwned, closeTo(50, 1e-9));
      expect(aoaOne1.value, closeTo(802.7, 1e-9));
      expect(aoaOne1.buyFeeTotal, closeTo(1, 1e-9));
      expect(aoaOne1.brokerCostBasis, closeTo((802.7 + 1) / 50, 1e-9));
      expect(aoaOne1.netCostBasis, closeTo(802.7 / 50, 1e-9));

      final assetOne1 = await (db.select(db.assets)
            ..where((a) => a.id.equals(assetOne.id)))
          .getSingle();
      expect(assetOne1.sharesOwned, closeTo(50, 1e-9));
      expect(assetOne1.value, closeTo(802.7, 1e-9));
      expect(assetOne1.buyFeeTotal, closeTo(1, 1e-9));
      expect(assetOne1.brokerCostBasis, closeTo((802.7 + 1) / 50, 1e-9));
      expect(assetOne1.netCostBasis, closeTo(802.7 / 50, 1e-9));

      final clearing1 = await (db.select(db.accounts)
            ..where((a) => a.id.equals(clearingAccount.id)))
          .getSingle();
      expect(clearing1.balance, closeTo(5000 - 802.7 - 1, 1e-9));

      final portfolio1 = await (db.select(db.accounts)
            ..where((a) => a.id.equals(portfolioAccount.id)))
          .getSingle();
      expect(portfolio1.balance, closeTo(0 + 802.7, 1e-9));

      // Trade 2
      await tradesDao.processTrade(TradesCompanion(
        datetime: const drift.Value(20250102000000),
        assetId: drift.Value(assetTwo.id),
        type: const drift.Value(TradeTypes.buy),
        shares: const drift.Value(4.936808),
        pricePerShare: const drift.Value(101.2395053646),
        tradingFee: const drift.Value(1),
        tax: const drift.Value(0),
        clearingAccountId: drift.Value(clearingAccount.id),
        portfolioAccountId: drift.Value(portfolioAccount.id),
      ));

      final aoaTwo2 = await (db.select(db.assetsOnAccounts)
            ..where((a) =>
                a.assetId.equals(assetTwo.id) &
                a.accountId.equals(portfolioAccount.id)))
          .getSingle();
      expect(aoaTwo2.sharesOwned, closeTo(4.936808, 1e-9));
      expect(aoaTwo2.value, closeTo(499.8, 1e-9));
      expect(aoaTwo2.buyFeeTotal, closeTo(1, 1e-9));
      expect(aoaTwo2.brokerCostBasis, closeTo((499.8 + 1) / 4.936808, 1e-9));
      expect(aoaTwo2.netCostBasis, closeTo(499.8 / 4.936808, 1e-9));

      final assetTwo2 = await (db.select(db.assets)
            ..where((a) => a.id.equals(assetTwo.id)))
          .getSingle();
      expect(assetTwo2.sharesOwned, closeTo(4.936808, 1e-9));
      expect(assetTwo2.value, closeTo(499.8, 1e-9));
      expect(assetTwo2.buyFeeTotal, closeTo(1, 1e-9));
      expect(assetTwo2.brokerCostBasis, closeTo((499.8 + 1) / 4.936808, 1e-9));
      expect(assetTwo2.netCostBasis, closeTo(499.8 / 4.936808, 1e-9));

      final clearing2 = await (db.select(db.accounts)
            ..where((a) => a.id.equals(clearingAccount.id)))
          .getSingle();
      expect(clearing2.balance, closeTo(4196.3 - 499.8 - 1, 1e-9));

      final portfolio2 = await (db.select(db.accounts)
            ..where((a) => a.id.equals(portfolioAccount.id)))
          .getSingle();
      expect(portfolio2.balance, closeTo(802.7 + 499.8, 1e-9));

      // Trade 3
      await tradesDao.processTrade(TradesCompanion(
        datetime: const drift.Value(20250103000000),
        assetId: drift.Value(assetOne.id),
        type: const drift.Value(TradeTypes.buy),
        shares: const drift.Value(34),
        pricePerShare: const drift.Value(11.2541176470588),
        tradingFee: const drift.Value(1),
        tax: const drift.Value(0),
        clearingAccountId: drift.Value(clearingAccount.id),
        portfolioAccountId: drift.Value(portfolioAccount.id),
      ));

      final aoaOne3 = await (db.select(db.assetsOnAccounts)
            ..where((a) =>
                a.assetId.equals(assetOne.id) &
                a.accountId.equals(portfolioAccount.id)))
          .getSingle();
      expect(aoaOne3.sharesOwned, closeTo(50 + 34, 1e-9));
      expect(aoaOne3.value, closeTo(802.7 + 382.64, 1e-9));
      expect(aoaOne3.buyFeeTotal, closeTo(1 + 1, 1e-9));
      expect(aoaOne3.brokerCostBasis, closeTo((802.7 + 382.64 + 2) / 84, 1e-9));
      expect(aoaOne3.netCostBasis, closeTo((802.7 + 382.64) / 84, 1e-9));

      final assetOne3 = await (db.select(db.assets)
            ..where((a) => a.id.equals(assetOne.id)))
          .getSingle();
      expect(assetOne3.sharesOwned, closeTo(50 + 34, 1e-9));
      expect(assetOne3.value, closeTo(802.7 + 382.64, 1e-9));
      expect(assetOne3.buyFeeTotal, closeTo(1 + 1, 1e-9));
      expect(
          assetOne3.brokerCostBasis, closeTo((802.7 + 382.64 + 2) / 84, 1e-9));
      expect(assetOne3.netCostBasis, closeTo((802.7 + 382.64) / 84, 1e-9));

      final clearing3 = await (db.select(db.accounts)
            ..where((a) => a.id.equals(clearingAccount.id)))
          .getSingle();
      expect(clearing3.balance, closeTo(3695.5 - 382.64 - 1, 1e-9));

      final portfolio3 = await (db.select(db.accounts)
            ..where((a) => a.id.equals(portfolioAccount.id)))
          .getSingle();
      expect(portfolio3.balance, closeTo(1302.5 + 382.64, 1e-9));

      // Trade 4
      await tradesDao.processTrade(TradesCompanion(
        datetime: const drift.Value(20250104000000),
        assetId: drift.Value(assetTwo.id),
        type: const drift.Value(TradeTypes.sell),
        shares: const drift.Value(1.936808),
        pricePerShare: const drift.Value(205.69927426983),
        tradingFee: const drift.Value(1),
        tax: const drift.Value(0),
        clearingAccountId: drift.Value(clearingAccount.id),
        portfolioAccountId: drift.Value(portfolioAccount.id),
      ));

      final aoaTwo4 = await (db.select(db.assetsOnAccounts)
            ..where((a) =>
                a.assetId.equals(assetTwo.id) &
                a.accountId.equals(portfolioAccount.id)))
          .getSingle();
      expect(aoaTwo4.sharesOwned, closeTo(3, 1e-9));
      expect(aoaTwo4.value, closeTo(499.8 - 196.0814839062, 1e-9));
      expect(aoaTwo4.buyFeeTotal,
          closeTo(1 - (1.936808 / 4.936808), 1e-9)); // = 0.607680104229291
      expect(aoaTwo4.brokerCostBasis,
          closeTo((499.8 - 196.0814839062 + 0.607680104229291) / 3, 1e-9));
      expect(aoaTwo4.netCostBasis, closeTo((499.8 - 196.0814839062) / 3, 1e-9));

      final assetTwo4 = await (db.select(db.assets)
            ..where((a) => a.id.equals(assetTwo.id)))
          .getSingle();
      expect(assetTwo4.sharesOwned, closeTo(3, 1e-9));
      expect(assetTwo4.value, closeTo(499.8 - 196.0814839062, 1e-9));
      expect(assetTwo4.buyFeeTotal,
          closeTo(1 - (1.936808 / 4.936808), 1e-9)); // = 0.607680104229291
      expect(assetTwo4.brokerCostBasis,
          closeTo((499.8 - 196.0814839062 + 0.607680104229291) / 3, 1e-9));
      expect(
          assetTwo4.netCostBasis, closeTo((499.8 - 196.0814839062) / 3, 1e-9));

      final clearing4 = await (db.select(db.accounts)
            ..where((a) => a.id.equals(clearingAccount.id)))
          .getSingle();
      expect(clearing4.balance, closeTo(3311.86 + 397.4, 1e-9));

      final portfolio4 = await (db.select(db.accounts)
            ..where((a) => a.id.equals(portfolioAccount.id)))
          .getSingle();
      expect(portfolio4.balance, closeTo(1685.14 - 196.0814839062, 1e-9));

      // Trade 5
      await tradesDao.processTrade(TradesCompanion(
        datetime: const drift.Value(20250105000000),
        assetId: drift.Value(assetOne.id),
        type: const drift.Value(TradeTypes.sell),
        shares: const drift.Value(84),
        pricePerShare: const drift.Value(6.655),
        tradingFee: const drift.Value(1),
        tax: const drift.Value(0),
        clearingAccountId: drift.Value(clearingAccount.id),
        portfolioAccountId: drift.Value(portfolioAccount.id),
      ));

      final aoaOne5 = await (db.select(db.assetsOnAccounts)
            ..where((a) =>
                a.assetId.equals(assetOne.id) &
                a.accountId.equals(portfolioAccount.id)))
          .getSingle();
      expect(aoaOne5.sharesOwned, closeTo(0, 1e-9));
      expect(aoaOne5.value, closeTo(0, 1e-9));
      expect(aoaOne5.buyFeeTotal, closeTo(0, 1e-9));
      expect(aoaOne5.brokerCostBasis, closeTo(0, 1e-9));
      expect(aoaOne5.netCostBasis, closeTo(0, 1e-9));

      final assetOne5 = await (db.select(db.assets)
            ..where((a) => a.id.equals(assetOne.id)))
          .getSingle();
      expect(assetOne5.sharesOwned, closeTo(0, 1e-9));
      expect(assetOne5.value, closeTo(0, 1e-9));
      expect(assetOne5.buyFeeTotal, closeTo(0, 1e-9));
      expect(assetOne5.brokerCostBasis, closeTo(0, 1e-9));
      expect(assetOne5.netCostBasis, closeTo(0, 1e-9));

      final clearing5 = await (db.select(db.accounts)
            ..where((a) => a.id.equals(clearingAccount.id)))
          .getSingle();
      expect(clearing5.balance, closeTo(3709.26 + 558.02, 1e-9));

      final portfolio5 = await (db.select(db.accounts)
            ..where((a) => a.id.equals(portfolioAccount.id)))
          .getSingle();
      expect(portfolio5.balance, closeTo(1489.0585160938 - 1185.34, 1e-9));

      // Add new account to test differentiation of Asset and AssetsOnAccount
      Account portfolioAccount2 = const Account(
          id: 3,
          name: 'Portfolio Account 2',
          balance: 0,
          initialBalance: 0,
          type: AccountTypes.portfolio,
          isArchived: false);
      await db.into(db.accounts).insert(portfolioAccount2.toCompanion(false));

      // Trade 6
      await tradesDao.processTrade(TradesCompanion(
        datetime: const drift.Value(20250106000000),
        assetId: drift.Value(assetTwo.id),
        type: const drift.Value(TradeTypes.buy),
        shares: const drift.Value(10),
        pricePerShare: const drift.Value(200),
        tradingFee: const drift.Value(1),
        tax: const drift.Value(0),
        clearingAccountId: drift.Value(clearingAccount.id),
        portfolioAccountId: drift.Value(portfolioAccount2.id),
      ));

      final aoaTwo6 = await (db.select(db.assetsOnAccounts)
            ..where((a) =>
                a.assetId.equals(assetTwo.id) &
                a.accountId.equals(portfolioAccount2.id)))
          .getSingle();
      expect(aoaTwo6.sharesOwned, closeTo(10, 1e-9));
      expect(aoaTwo6.value, closeTo(2000, 1e-9));
      expect(aoaTwo6.buyFeeTotal, closeTo(1, 1e-9));
      expect(aoaTwo6.brokerCostBasis, closeTo((2000 + 1) / 10, 1e-9));
      expect(aoaTwo6.netCostBasis, closeTo(2000 / 10, 1e-9));

      final assetTwo6 = await (db.select(db.assets)
            ..where((a) => a.id.equals(assetTwo.id)))
          .getSingle();
      expect(assetTwo6.sharesOwned, closeTo(3 + 10, 1e-9));
      expect(assetTwo6.value, closeTo(303.7185160938 + 2000, 1e-9));
      expect(assetTwo6.buyFeeTotal, closeTo(0.607680104229291 + 1, 1e-9));
      expect(assetTwo6.brokerCostBasis,
          closeTo((303.7185160938 + 2000 + 1.607680104229291) / 13, 1e-9));
      expect(
          assetTwo6.netCostBasis, closeTo((303.7185160938 + 2000) / 13, 1e-9));

      final clearing6 = await (db.select(db.accounts)
            ..where((a) => a.id.equals(clearingAccount.id)))
          .getSingle();
      expect(clearing6.balance, closeTo(4267.28 - 2000 - 1, 1e-9));

      final portfolio2_6 = await (db.select(db.accounts)
            ..where((a) => a.id.equals(portfolioAccount2.id)))
          .getSingle();
      expect(portfolio2_6.balance, closeTo(2000, 1e-9));

      // Trade 7
      await tradesDao.processTrade(TradesCompanion(
        datetime: const drift.Value(20250107000000),
        assetId: drift.Value(assetTwo.id),
        type: const drift.Value(TradeTypes.sell),
        shares: const drift.Value(3),
        pricePerShare: const drift.Value(208),
        tradingFee: const drift.Value(1),
        tax: const drift.Value(18.82),
        clearingAccountId: drift.Value(clearingAccount.id),
        portfolioAccountId: drift.Value(portfolioAccount.id),
      ));

      final aoaTwo7 = await (db.select(db.assetsOnAccounts)
            ..where((a) =>
                a.assetId.equals(assetTwo.id) &
                a.accountId.equals(portfolioAccount.id)))
          .getSingle();
      expect(aoaTwo7.sharesOwned, closeTo(0, 1e-9));
      expect(aoaTwo7.value, closeTo(0, 1e-9));
      expect(aoaTwo7.buyFeeTotal, closeTo(0, 1e-9));
      expect(aoaTwo7.brokerCostBasis, closeTo(0, 1e-9));
      expect(aoaTwo7.netCostBasis, closeTo(0, 1e-9));

      final aoaTwo2_7 = await (db.select(db.assetsOnAccounts)
            ..where((a) =>
                a.assetId.equals(assetTwo.id) &
                a.accountId.equals(portfolioAccount2.id)))
          .getSingle();
      expect(aoaTwo2_7.sharesOwned, closeTo(10, 1e-9));
      expect(aoaTwo2_7.value, closeTo(2000, 1e-9));
      expect(aoaTwo2_7.buyFeeTotal, closeTo(1, 1e-9));
      expect(aoaTwo2_7.brokerCostBasis, closeTo((2000 + 1) / 10, 1e-9));
      expect(aoaTwo2_7.netCostBasis, closeTo(2000 / 10, 1e-9));

      final assetTwo7 = await (db.select(db.assets)
            ..where((a) => a.id.equals(assetTwo.id)))
          .getSingle();
      expect(assetTwo7.sharesOwned, closeTo(10, 1e-9));
      expect(assetTwo7.value, closeTo(2000, 1e-9));
      expect(assetTwo7.buyFeeTotal, closeTo(1.607680104229291 - 1, 1e-9));
      expect(assetTwo7.brokerCostBasis,
          closeTo((2000 + 0.607680104229291) / 10, 1e-9));
      expect(assetTwo7.netCostBasis, closeTo(2000 / 10, 1e-9));

      final clearing7 = await (db.select(db.accounts)
            ..where((a) => a.id.equals(clearingAccount.id)))
          .getSingle();
      expect(clearing7.balance, closeTo(2267.28 + 604.18 - 1, 1e-9));

      final portfolio7 = await (db.select(db.accounts)
            ..where((a) => a.id.equals(portfolioAccount.id)))
          .getSingle();
      expect(portfolio7.balance, closeTo(0, 1e-9));
    });

    test('buy 2, buy 2, sell 3 - test one sell consumes more than one lot',
        () async {
      await tradesDao.processTrade(TradesCompanion(
        datetime: const drift.Value(20250101000000),
        assetId: drift.Value(assetOne.id),
        type: const drift.Value(TradeTypes.buy),
        shares: const drift.Value(2),
        pricePerShare: const drift.Value(10),
        tradingFee: const drift.Value(1),
        tax: const drift.Value(0),
        clearingAccountId: drift.Value(clearingAccount.id),
        portfolioAccountId: drift.Value(portfolioAccount.id),
      ));

      await tradesDao.processTrade(TradesCompanion(
        datetime: const drift.Value(20250102000000),
        assetId: drift.Value(assetOne.id),
        type: const drift.Value(TradeTypes.buy),
        shares: const drift.Value(2),
        pricePerShare: const drift.Value(15),
        tradingFee: const drift.Value(1),
        tax: const drift.Value(0),
        clearingAccountId: drift.Value(clearingAccount.id),
        portfolioAccountId: drift.Value(portfolioAccount.id),
      ));

      await tradesDao.processTrade(TradesCompanion(
        datetime: const drift.Value(20250103000000),
        assetId: drift.Value(assetOne.id),
        type: const drift.Value(TradeTypes.sell),
        shares: const drift.Value(3),
        pricePerShare: const drift.Value(20),
        tradingFee: const drift.Value(1),
        tax: const drift.Value(0),
        clearingAccountId: drift.Value(clearingAccount.id),
        portfolioAccountId: drift.Value(portfolioAccount.id),
      ));

      final aoaOne1 = await (db.select(db.assetsOnAccounts)
            ..where((a) =>
                a.assetId.equals(assetOne.id) &
                a.accountId.equals(portfolioAccount.id)))
          .getSingle();
      expect(aoaOne1.sharesOwned, closeTo(1, 1e-9));
      expect(aoaOne1.value, closeTo(15, 1e-9));
      expect(aoaOne1.buyFeeTotal, closeTo(0.5, 1e-9));
      expect(aoaOne1.brokerCostBasis, closeTo((15 + 0.5) / 1, 1e-9));
      expect(aoaOne1.netCostBasis, closeTo(15 / 1, 1e-9));

      final assetOne1 = await (db.select(db.assets)
            ..where((a) => a.id.equals(assetOne.id)))
          .getSingle();
      expect(assetOne1.sharesOwned, closeTo(1, 1e-9));
      expect(assetOne1.value, closeTo(15, 1e-9));
      expect(assetOne1.buyFeeTotal, closeTo(0.5, 1e-9));
      expect(assetOne1.brokerCostBasis, closeTo((15 + 0.5) / 1, 1e-9));
      expect(assetOne1.netCostBasis, closeTo(15 / 1, 1e-9));

      final clearing1 = await (db.select(db.accounts)
            ..where((a) => a.id.equals(clearingAccount.id)))
          .getSingle();
      expect(clearing1.balance, closeTo(5000 - 20 - 30 + 60 - 3, 1e-9));

      final portfolio1 = await (db.select(db.accounts)
            ..where((a) => a.id.equals(portfolioAccount.id)))
          .getSingle();
      expect(portfolio1.balance, closeTo(0 + 20 + 30 - 20 - 15, 1e-9));
    });
  });

  group('getTrade', () {
    test('insert trade then getTrade returns it', () async {
      final assetId = await db.into(db.assets).insert(const AssetsCompanion(
            name: drift.Value('DEL'),
            type: drift.Value(AssetTypes.stock),
            tickerSymbol: drift.Value('DEL'),
            value: drift.Value(0.0),
            sharesOwned: drift.Value(0.0),
            netCostBasis: drift.Value(0.0),
            brokerCostBasis: drift.Value(0.0),
            buyFeeTotal: drift.Value(0.0),
          ));

      final clearingId =
          await db.into(db.accounts).insert(const AccountsCompanion(
                name: drift.Value('Cdel'),
                balance: drift.Value(10.0),
                initialBalance: drift.Value(10.0),
                type: drift.Value(AccountTypes.cash),
              ));

      final portfolioId =
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
          pricePerShare: const drift.Value(1.0),
          tradingFee: const drift.Value(0.0),
          tax: const drift.Value(0.0),
          clearingAccountId: drift.Value(clearingId),
          portfolioAccountId: drift.Value(portfolioId),
          clearingAccountValueDelta: const drift.Value(-1.0),
          portfolioAccountValueDelta: const drift.Value(1.0),
          profitAndLossAbs: const drift.Value(0),
          profitAndLossRel: const drift.Value(0)));

      final fetched = await tradesDao.getTrade(id);
      expect(fetched.id, id);
    });
  });
}
