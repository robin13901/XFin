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

  Future<List<Trade>> getAllTrades() => select(trades).get();

  Stream<List<TradeWithAsset>> watchAllTrades() {
    return (select(trades)..orderBy([(t) => OrderingTerm.desc(t.datetime), (t) => OrderingTerm.desc(t.id)]))
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
      final targetAccountId = entry.targetAccountId.value;
      final sourceAccountId = entry.sourceAccountId.value;
      final shares = entry.shares.value;
      final costBasis = entry.costBasis.value;
      final fee = entry.fee.value;
      final tradeType = entry.type.value;
      final tax = tradeType == TradeTypes.sell ? entry.tax.value : 0;

      var assetOnAccount = await db.assetsOnAccountsDao
          .ensureAssetOnAccountExists(assetId, targetAccountId);
      final asset = await db.assetsDao.getAsset(assetId);

      // 2. Process Trade
      double movedValue = shares * costBasis;
      double sourceAccountValueDelta = 0;
      double targetAccountValueDelta = 0;
      double profitAndLoss = 0;
      double returnOnInvest = 0;

      double updatedAOAShares, updatedAOAValue, updatedAOABuyFeeTotal;
      double updatedAssetShares, updatedAssetValue, updatedAssetBuyFeeTotal;

      if (tradeType == TradeTypes.buy) {
        sourceAccountValueDelta = -movedValue - fee - tax;
        targetAccountValueDelta = movedValue;

        updatedAOAShares = assetOnAccount.shares + shares;
        updatedAOABuyFeeTotal = assetOnAccount.buyFeeTotal + fee;

        updatedAssetShares = asset.shares + shares;
        updatedAssetBuyFeeTotal = asset.buyFeeTotal + fee;
      } else {
        // Sell
        final fifo = await _buildFiFoQueue(assetId, targetAccountId);

        var sharesToSell = shares;
        sourceAccountValueDelta = movedValue - fee - tax;
        double buyFeeTotalDelta = 0;

        // Consume FIFO queue
        while (sharesToSell > 0 && fifo.isNotEmpty) {
          var currentLot = fifo.first;
          if (currentLot['shares']! <= sharesToSell) {
            targetAccountValueDelta -=
                currentLot['shares']! * currentLot['costBasis']!;
            sharesToSell -= currentLot['shares']!;
            buyFeeTotalDelta -= currentLot['fee']!;
            fifo.removeFirst();
          } else {
            buyFeeTotalDelta -= (sharesToSell / currentLot['shares']!) *
                currentLot['fee']!;
            targetAccountValueDelta -=
                sharesToSell * currentLot['costBasis']!;
            currentLot['shares'] = currentLot['shares']! - sharesToSell;
            sharesToSell = 0;
          }
        }

        // Calculate P&L
        profitAndLoss = sourceAccountValueDelta +
            targetAccountValueDelta -
            fee +
            tax;
        returnOnInvest = -profitAndLoss / targetAccountValueDelta;

        // Update AssetOnAccount
        updatedAOAShares = assetOnAccount.shares - shares;
        updatedAOABuyFeeTotal = assetOnAccount.buyFeeTotal + buyFeeTotalDelta;
        if (updatedAOAShares.abs() < 1e-9) {
          updatedAOAShares = 0;
          updatedAOAValue = 0;
          updatedAOABuyFeeTotal = 0;
        }

        // Update Asset
        updatedAssetShares = asset.shares - shares;
        updatedAssetBuyFeeTotal = asset.buyFeeTotal + buyFeeTotalDelta;
      }

      // Update AssetOnAccount
      updatedAOAValue = assetOnAccount.value + targetAccountValueDelta;
      await (update(assetsOnAccounts)
            ..where((a) =>
                a.assetId.equals(assetId) &
                a.accountId.equals(targetAccountId)))
          .write(
        AssetsOnAccountsCompanion(
          shares: Value(updatedAOAShares),
          value: Value(updatedAOAValue),
          buyFeeTotal: Value(updatedAOABuyFeeTotal),
          netCostBasis: Value(
              updatedAOAShares > 0 ? updatedAOAValue / updatedAOAShares : 0),
          brokerCostBasis: Value(updatedAOAShares > 0
              ? (updatedAOAValue + updatedAOABuyFeeTotal) / updatedAOAShares
              : 0),
        ),
      );

      // Update Asset
      updatedAssetValue = asset.value + targetAccountValueDelta;
      await (update(assets)..where((a) => a.id.equals(assetId)))
          .write(AssetsCompanion(
        shares: Value(updatedAssetShares),
        value: Value(updatedAssetValue),
        buyFeeTotal: Value(updatedAssetBuyFeeTotal),
        netCostBasis: Value(updatedAssetShares > 0
            ? updatedAssetValue / updatedAssetShares
            : 0),
        brokerCostBasis: Value(updatedAssetShares > 0
            ? (updatedAssetValue + updatedAssetBuyFeeTotal) / updatedAssetShares
            : 0),
      ));

      // Update Base Currency Asset
      await db.assetsOnAccountsDao.updateBaseCurrencyAssetOnAccount(
          sourceAccountId, sourceAccountValueDelta);
      await db.assetsDao
          .updateAsset(1, sourceAccountValueDelta, sourceAccountValueDelta);

      // 3. Insert Trade
      final tradeWithCalculatedValues = entry.copyWith(
          sourceAccountValueDelta: Value(sourceAccountValueDelta),
          targetAccountValueDelta: Value(targetAccountValueDelta),
          profitAndLoss: Value(profitAndLoss),
          returnOnInvest: Value(returnOnInvest));
      await into(trades).insert(tradeWithCalculatedValues);

      // 5. Update Account Balances
      final clearingAccount = await (select(accounts)
            ..where((a) => a.id.equals(sourceAccountId)))
          .getSingle();
      await (update(accounts)..where((a) => a.id.equals(sourceAccountId)))
          .write(
        AccountsCompanion(
            balance:
                Value(clearingAccount.balance + sourceAccountValueDelta)),
      );

      final portfolioAccount = await (select(accounts)
            ..where((a) => a.id.equals(targetAccountId)))
          .getSingle();
      await (update(accounts)..where((a) => a.id.equals(targetAccountId)))
          .write(
        AccountsCompanion(
            balance:
                Value(portfolioAccount.balance + targetAccountValueDelta)),
      );
    });
  }

  Future<ListQueue<Map<String, double>>> _buildFiFoQueue(
      int assetId, int targetAccountId) async {
    final pastTrades = await (select(trades)
          ..where((t) =>
              t.assetId.equals(assetId) &
              t.targetAccountId.equals(targetAccountId))
          ..orderBy([(t) => OrderingTerm(expression: t.datetime)]))
        .get();

    final fifo = ListQueue<Map<String, double>>();
    for (var pastTrade in pastTrades) {
      if (pastTrade.type == TradeTypes.buy) {
        fifo.add({
          'shares': pastTrade.shares,
          'costBasis': pastTrade.costBasis,
          'fee': pastTrade.fee
        });
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
