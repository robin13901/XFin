import 'dart:collection';

import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables.dart';

part 'trades_dao.g.dart';

class TradeWithAsset {
  final Trade trade;
  final Asset asset;

  TradeWithAsset({required this.trade, required this.asset});
}

@DriftAccessor(tables: [Trades, Assets, Accounts, AssetsOnAccounts])
class TradesDao extends DatabaseAccessor<AppDatabase> with _$TradesDaoMixin {
  TradesDao(super.db);

  Stream<List<TradeWithAsset>> watchAllTrades() {
    return (select(trades)
          ..orderBy([(t) => OrderingTerm.desc(t.datetime)]))
        .join([
          innerJoin(assets, assets.id.equalsExp(trades.assetId)),
        ])
        .watch()
        .map((rows) {
          return rows.map((row) {
            return TradeWithAsset(
              trade: row.readTable(trades),
              asset: row.readTable(assets),
            );
          }).toList();
        });
  }

  Future<void> processTrade(TradesCompanion entry) {
    return db.transaction(() async {
      final assetId = entry.assetId.value;
      final portfolioAccountId = entry.portfolioAccountId.value;
      final clearingAccountId = entry.clearingAccountId.value;
      final shares = entry.shares.value;
      final pricePerShare = entry.pricePerShare.value;
      final tradingFee = entry.tradingFee.value;
      final tradeType = entry.type.value;
      final tax = tradeType == TradeTypes.sell ? entry.tax.value : 0;

      // 1. Ensure AssetOnAccount exists
      var assetOnAccount = await (select(assetsOnAccounts)
            ..where((a) =>
                a.assetId.equals(assetId) &
                a.accountId.equals(portfolioAccountId)))
          .getSingleOrNull();

      if (assetOnAccount == null) {
        final newAssetOnAccount = AssetsOnAccountsCompanion(
          assetId: Value(assetId),
          accountId: Value(portfolioAccountId),
          value: const Value(0),
          sharesOwned: const Value(0),
          netCostBasis: const Value(0),
          brokerCostBasis: const Value(0),
          buyFeeTotal: const Value(0),
        );
        await into(assetsOnAccounts).insert(newAssetOnAccount);
        assetOnAccount = await (select(assetsOnAccounts)
              ..where((a) =>
                  a.assetId.equals(assetId) &
                  a.accountId.equals(portfolioAccountId)))
            .getSingle();
      }
      final asset = await (select(assets)..where((a) => a.id.equals(assetId))).getSingle();

      // 2. Process Trade
      double movedValue = shares * pricePerShare;
      double clearingAccountValueDelta = 0;
      double portfolioAccountValueDelta = 0;
      double profitAndLossAbs = 0;
      double profitAndLossRel = 0;

      double updatedAOAShares, updatedAOAValue, updatedAOABuyFeeTotal;
      double updatedAssetShares, updatedAssetValue, updatedAssetBuyFeeTotal;

      if (tradeType == TradeTypes.buy) {
        clearingAccountValueDelta = -movedValue - tradingFee - tax;
        portfolioAccountValueDelta = movedValue;

        updatedAOAShares = assetOnAccount.sharesOwned + shares;
        updatedAOABuyFeeTotal = assetOnAccount.buyFeeTotal + tradingFee;

        updatedAssetShares = asset.sharesOwned + shares;
        updatedAssetBuyFeeTotal = asset.buyFeeTotal + tradingFee;
      } else { // Sell
        final fifo = await _buildFiFoQueue(assetId, portfolioAccountId);
        
        var sharesToSell = shares;
        clearingAccountValueDelta = movedValue - tradingFee - tax;
        double buyFeeTotalDelta = 0;

        // Consume FIFO queue
        while (sharesToSell > 0 && fifo.isNotEmpty) {
          var currentLot = fifo.first;
          if (currentLot['shares']! <= sharesToSell) {
            portfolioAccountValueDelta -= currentLot['shares']! * currentLot['pricePerShare']!;
            sharesToSell -= currentLot['shares']!;
            buyFeeTotalDelta -= currentLot['tradingFee']!;
            fifo.removeFirst();
          } else {
            buyFeeTotalDelta -= (sharesToSell / currentLot['shares']!) * currentLot['tradingFee']!;
            portfolioAccountValueDelta -= sharesToSell * currentLot['pricePerShare']!;
            currentLot['shares'] = currentLot['shares']! - sharesToSell;
            sharesToSell = 0;
          }
        }

        // Calculate P&L
        profitAndLossAbs = clearingAccountValueDelta + portfolioAccountValueDelta - tradingFee + tax;
        profitAndLossRel = -profitAndLossAbs / portfolioAccountValueDelta;

        // Update AssetOnAccount
        updatedAOAShares = assetOnAccount.sharesOwned - shares;
        updatedAOABuyFeeTotal = assetOnAccount.buyFeeTotal + buyFeeTotalDelta;
        if(updatedAOAShares.abs() < 1e-9) {
          updatedAOAShares = 0;
          updatedAOAValue = 0;
          updatedAOABuyFeeTotal = 0;
        }

        // Update Asset
        updatedAssetShares = asset.sharesOwned - shares;
        updatedAssetBuyFeeTotal = asset.buyFeeTotal + buyFeeTotalDelta;
      }

      // Update AssetOnAccount
      updatedAOAValue = assetOnAccount.value + portfolioAccountValueDelta;
      await (update(assetsOnAccounts)..where((a) => a.assetId.equals(assetId) & a.accountId.equals(portfolioAccountId))).write(
        AssetsOnAccountsCompanion(
          sharesOwned: Value(updatedAOAShares),
          value: Value(updatedAOAValue),
          buyFeeTotal: Value(updatedAOABuyFeeTotal),
          netCostBasis: Value(updatedAOAShares > 0 ? updatedAOAValue / updatedAOAShares : 0),
          brokerCostBasis: Value(updatedAOAShares > 0 ? (updatedAOAValue + updatedAOABuyFeeTotal) / updatedAOAShares : 0),
        ),
      );

      // Update Asset
      updatedAssetValue = asset.value + portfolioAccountValueDelta;
      await (update(assets)..where((a) => a.id.equals(assetId))).write(AssetsCompanion(
        sharesOwned: Value(updatedAssetShares),
        value: Value(updatedAssetValue),
        buyFeeTotal: Value(updatedAssetBuyFeeTotal),
        netCostBasis: Value(updatedAssetShares > 0 ? updatedAssetValue / updatedAssetShares : 0),
        brokerCostBasis: Value(updatedAssetShares > 0 ? (updatedAssetValue + updatedAssetBuyFeeTotal) / updatedAssetShares : 0),
      ));

      // Update Base Currency Asset
      await db.assetsOnAccountsDao.updateBaseCurrencyAssetOnAccount(clearingAccountId, clearingAccountValueDelta);
      await db.assetsDao.updateBaseCurrencyAsset(clearingAccountValueDelta);

      // 3. Insert Trade
      final tradeWithCalculatedValues = entry.copyWith(
        clearingAccountValueDelta: Value(clearingAccountValueDelta),
        portfolioAccountValueDelta: Value(portfolioAccountValueDelta),
        profitAndLossAbs: Value(profitAndLossAbs),
        profitAndLossRel: Value(profitAndLossRel)
      );
      await into(trades).insert(tradeWithCalculatedValues);

      // 5. Update Account Balances
      final clearingAccount = await (select(accounts)..where((a) => a.id.equals(clearingAccountId))).getSingle();
      await (update(accounts)..where((a) => a.id.equals(clearingAccountId))).write(
        AccountsCompanion(balance: Value(clearingAccount.balance + clearingAccountValueDelta)),
      );

      final portfolioAccount = await (select(accounts)..where((a) => a.id.equals(portfolioAccountId))).getSingle();
      await (update(accounts)..where((a) => a.id.equals(portfolioAccountId))).write(
        AccountsCompanion(balance: Value(portfolioAccount.balance + portfolioAccountValueDelta)),
      );
    });
  }

  Future<ListQueue<Map<String, double>>> _buildFiFoQueue(int assetId, int portfolioAccountId) async {
    final pastTrades = await (select(trades)
      ..where((t) =>
      t.assetId.equals(assetId) &
      t.portfolioAccountId.equals(portfolioAccountId))
      ..orderBy([(t) => OrderingTerm(expression: t.datetime)]))
        .get();

    final fifo = ListQueue<Map<String, double>>();
    for (var pastTrade in pastTrades) {
      if (pastTrade.type == TradeTypes.buy) {
        fifo.add({'shares': pastTrade.shares, 'pricePerShare': pastTrade.pricePerShare, 'tradingFee': pastTrade.tradingFee});
      } else {
        var sharesToConsume = pastTrade.shares;
        while (sharesToConsume > 0 && fifo.isNotEmpty) {
          var currentLot = fifo.first;
          if (currentLot['shares']! <= sharesToConsume) {
            sharesToConsume -= currentLot['shares']!;
            fifo.removeFirst();
          } else {
            currentLot['shares'] = currentLot['shares']! - sharesToConsume;
            sharesToConsume = 0;
          }
        }
      }
    }
    return fifo;
  }

  Future<Trade> getTrade(int id) {
    return (select(trades)..where((a) => a.id.equals(id))).getSingle();
  }
}
