import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables.dart';

part 'trades_dao.g.dart';

@DriftAccessor(tables: [Trades, Assets, Accounts])
class TradesDao extends DatabaseAccessor<AppDatabase> with _$TradesDaoMixin {
  TradesDao(super.db);

  void _validateDate(int dateInt) {
    final dateString = dateInt.toString();
    if (dateString.length != 8) {
      throw Exception('Date must be in yyyyMMdd format and a valid date.');
    }

    final year = int.tryParse(dateString.substring(0, 4)) ?? 0;
    final month = int.tryParse(dateString.substring(4, 6)) ?? 0;
    final day = int.tryParse(dateString.substring(6, 8)) ?? 0;

    try {
      final date = DateTime(year, month, day);
      if (date.year != year || date.month != month || date.day != day) {
        throw Exception('Date must be a valid date.');
      }
    } catch (e) {
      throw Exception('Date must be a valid date.');
    }
  }

  Future<void> validate(Trade trade) async {
    _validateDate(trade.date);
    if (trade.movedValue <= 0) {
      throw Exception('Moved value must be greater than 0.');
    }
    if (trade.shares <= 0) {
      throw Exception('Shares must be greater than 0.');
    }
    if (trade.pricePerShare <= 0) {
      throw Exception('Price per share must be greater than 0.');
    }
    if (trade.tradingFee >= 0) {
      throw Exception('Trading fee must be less than 0.');
    }

    final clearingAccount = await (select(accounts)
          ..where((a) => a.id.equals(trade.clearingAccountId)))
        .getSingle();
    if (clearingAccount.type != AccountTypes.cash) {
      throw Exception('Clearing account must be of type cash.');
    }

    final portfolioAccount = await (select(accounts)
          ..where((a) => a.id.equals(trade.portfolioAccountId)))
        .getSingle();
    if (portfolioAccount.type != AccountTypes.portfolio) {
      throw Exception('Portfolio account must be of type portfolio.');
    }
  }

  Future<int> _addTrade(TradesCompanion entry) => into(trades).insert(entry);

  Future<int> _deleteTrade(int id) => (delete(trades)..where((tbl) => tbl.id.equals(id))).go();

  Future<Trade> getTrade(int id) => (select(trades)..where((tbl) => tbl.id.equals(id))).getSingle();

  Future<int> createTradeAndUpdateAccounts(TradesCompanion entry) {
    return transaction(() async {
      final tradeId = await _addTrade(entry);
      final trade = await getTrade(tradeId);
      final isBuy = trade.type == TradeTypes.buy;

      await db.accountsDao.updateBalance(trade.clearingAccountId, isBuy ? -trade.movedValue : trade.movedValue);
      await db.accountsDao.updateBalance(trade.clearingAccountId, trade.tradingFee);

      final assetOnAccount = await db.assetsOnAccountsDao.getAssetOnAccount(trade.portfolioAccountId, trade.assetId);
      final newShares = assetOnAccount.sharesOwned + (isBuy ? trade.shares : -trade.shares);
      final newBrokerBuyIn = assetOnAccount.brokerBuyIn + (isBuy ? trade.movedValue : 0);
      final newNetBuyIn = newBrokerBuyIn / newShares;
      final newBuyFeeTotal = assetOnAccount.buyFeeTotal + (isBuy ? trade.tradingFee.abs() : 0);
      final newValue = newShares * trade.pricePerShare;

      final updatedAssetOnAccount = AssetsOnAccountsCompanion(
        accountId: Value(trade.portfolioAccountId),
        assetId: Value(trade.assetId),
        sharesOwned: Value(newShares),
        brokerBuyIn: Value(newBrokerBuyIn),
        netBuyIn: Value(newNetBuyIn),
        buyFeeTotal: Value(newBuyFeeTotal),
        value: Value(newValue),
      );
      await db.assetsOnAccountsDao.updateAssetsOnAccount(updatedAssetOnAccount);

      return tradeId;
    });
  }

  Future<void> deleteTradeAndUpdateAccounts(int id) {
    return transaction(() async {
      final trade = await getTrade(id);
      await _deleteTrade(id);
      final isBuy = trade.type == TradeTypes.buy;

      await db.accountsDao.updateBalance(trade.clearingAccountId, isBuy ? trade.movedValue : -trade.movedValue);
      await db.accountsDao.updateBalance(trade.clearingAccountId, -trade.tradingFee);

      final assetOnAccount = await db.assetsOnAccountsDao.getAssetOnAccount(trade.portfolioAccountId, trade.assetId);
      final newShares = assetOnAccount.sharesOwned - (isBuy ? trade.shares : -trade.shares);
      final newBrokerBuyIn = assetOnAccount.brokerBuyIn - (isBuy ? trade.movedValue : 0.0);
      final newNetBuyIn = newShares == 0 ? 0.0 : newBrokerBuyIn / newShares;
      final newBuyFeeTotal = assetOnAccount.buyFeeTotal - (isBuy ? trade.tradingFee.abs() : 0.0);
      final newValue = newShares * trade.pricePerShare;

      final updatedAssetOnAccount = AssetsOnAccountsCompanion(
        accountId: Value(trade.portfolioAccountId),
        assetId: Value(trade.assetId),
        sharesOwned: Value(newShares),
        brokerBuyIn: Value(newBrokerBuyIn),
        netBuyIn: Value(newNetBuyIn),
        buyFeeTotal: Value(newBuyFeeTotal),
        value: Value(newValue),
      );
      await db.assetsOnAccountsDao.updateAssetsOnAccount(updatedAssetOnAccount);
    });
  }
}
