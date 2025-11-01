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
}
