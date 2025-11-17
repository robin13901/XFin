import 'dart:collection';

import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables.dart';

part 'trades_dao.g.dart';

// New data class to hold a trade and its associated asset
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

      // 2. Process Trade
      double movedValue = shares * pricePerShare;
      double clearingAccountValueDelta = 0;
      double portfolioAccountValueDelta = 0;
      double profitAndLossAbs = 0;
      double profitAndLossRel = 0;

      if (tradeType == TradeTypes.buy) {
        clearingAccountValueDelta = -movedValue - tradingFee - tax;
        portfolioAccountValueDelta = movedValue;

        // Update AssetOnAccount
        final updatedShares = assetOnAccount.sharesOwned + shares;
        final updatedValue = assetOnAccount.value + portfolioAccountValueDelta;
        final updatedBuyFeeTotal = assetOnAccount.buyFeeTotal + tradingFee;

        await (update(assetsOnAccounts)..where((a) => a.assetId.equals(assetId) & a.accountId.equals(portfolioAccountId))).write(
          AssetsOnAccountsCompanion(
            sharesOwned: Value(updatedShares),
            value: Value(updatedValue),
            buyFeeTotal: Value(updatedBuyFeeTotal),
            netCostBasis: Value(updatedShares > 0 ? updatedValue / updatedShares : 0),
            brokerCostBasis: Value(updatedShares > 0 ? (updatedValue - updatedBuyFeeTotal) / updatedShares : 0),
          ),
        );

      } else { // Sell

        if (assetOnAccount.sharesOwned < shares) {
          throw Exception('Not enough shares to sell.');
        }

        final pastTrades = await (select(trades)
              ..where((t) =>
                  t.assetId.equals(assetId) &
                  t.portfolioAccountId.equals(portfolioAccountId))
              ..orderBy([(t) => OrderingTerm(expression: t.datetime)]))
            .get();

        final fifo = ListQueue<Map<String, double>>();
        for (var pastTrade in pastTrades) {
          if (pastTrade.type == TradeTypes.buy) {
            fifo.add({'shares': pastTrade.shares, 'pricePerShare': pastTrade.pricePerShare});
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
        
        var sharesToSell = shares;
        clearingAccountValueDelta = movedValue - tradingFee - tax;

        while (sharesToSell > 0 && fifo.isNotEmpty) {
          var currentLot = fifo.first;
          if (currentLot['shares']! <= sharesToSell) {
            portfolioAccountValueDelta -= currentLot['shares']! * currentLot['pricePerShare']!;
            sharesToSell -= currentLot['shares']!;
            fifo.removeFirst();
          } else {
            portfolioAccountValueDelta -= sharesToSell * currentLot['pricePerShare']!;
            currentLot['shares'] = currentLot['shares']! - sharesToSell;
            sharesToSell = 0;
          }
        }

        profitAndLossAbs = clearingAccountValueDelta + portfolioAccountValueDelta - tradingFee + tax;
        profitAndLossRel = -profitAndLossAbs / portfolioAccountValueDelta;

        // Update AssetOnAccount
        var updatedShares = assetOnAccount.sharesOwned - shares;
        var updatedValue = assetOnAccount.value + portfolioAccountValueDelta;
        var updatedBuyFeeTotal = assetOnAccount.buyFeeTotal;
        if(updatedShares.abs() < 1e-9) {
          updatedShares = 0;
          updatedValue = 0;
          updatedBuyFeeTotal = 0;
        }

        await (update(assetsOnAccounts)..where((a) => a.assetId.equals(assetId) & a.accountId.equals(portfolioAccountId))).write(
          AssetsOnAccountsCompanion(
            sharesOwned: Value(updatedShares),
            value: Value(updatedValue),
            buyFeeTotal: Value(updatedBuyFeeTotal),
            netCostBasis: Value(updatedShares > 0 ? updatedValue / updatedShares : 0),
            brokerCostBasis: Value(updatedShares > 0 ? (updatedValue - updatedBuyFeeTotal) / updatedShares : 0),
          ),
        );
      }

      // 3. Insert Trade
      final tradeWithCalculatedValues = entry.copyWith(
        clearingAccountValueDelta: Value(clearingAccountValueDelta),
        portfolioAccountValueDelta: Value(portfolioAccountValueDelta),
        profitAndLossAbs: Value(profitAndLossAbs),
        profitAndLossRel: Value(profitAndLossRel)
      );
      await into(trades).insert(tradeWithCalculatedValues);

      // 4. Update Asset global values
      final allAssetOnAccounts = await (select(assetsOnAccounts)..where((a) => a.assetId.equals(assetId))).get();
      final totalShares = allAssetOnAccounts.fold<double>(0, (sum, item) => sum + item.sharesOwned);
      final totalValue = allAssetOnAccounts.fold<double>(0, (sum, item) => sum + item.value);
      final totalBuyFee = allAssetOnAccounts.fold<double>(0, (sum, item) => sum + item.buyFeeTotal);

      await (update(assets)..where((a) => a.id.equals(assetId))).write(AssetsCompanion(
        sharesOwned: Value(totalShares),
        value: Value(totalValue),
        buyFeeTotal: Value(totalBuyFee),
        netCostBasis: Value(totalShares > 0 ? totalValue / totalShares : 0),
        brokerCostBasis: Value(totalShares > 0 ? (totalValue - totalBuyFee) / totalShares : 0),
      ));

      // 5. Update Account Balances
      final clearingAccount = await (select(accounts)..where((a) => a.id.equals(clearingAccountId))).getSingle();
      await (update(accounts)..where((a) => a.id.equals(clearingAccountId))).write(
        AccountsCompanion(balance: Value(clearingAccount.balance + clearingAccountValueDelta)),
      );

      final portfolioAccount = await (select(accounts)..where((a) => a.id.equals(portfolioAccountId))).getSingle();
      await (update(accounts)..where((a) => a.id.equals(portfolioAccountId))).write(
        AccountsCompanion(balance: Value(portfolioAccount.balance + portfolioAccountValueDelta)),
      );

      // 6. Update Base Currency Asset
      await db.assetsOnAccountsDao.updateBaseCurrencyAssetOnAccount(clearingAccountId, clearingAccountValueDelta);
      await db.assetsDao.updateBaseCurrencyAsset(clearingAccountValueDelta);
    });
  }

  Future<void> deleteTrade(int id) {
    // Note: Deleting trades can have complex repercussions on asset values and cost basis.
    // A full implementation would require recalculating all subsequent trades.
    // This simplified version just deletes the trade record.
    return (delete(trades)..where((t) => t.id.equals(id))).go();
  }

  Future<Trade> getTrade(int id) {
    return (select(trades)..where((a) => a.id.equals(id))).getSingle();
  }
}
