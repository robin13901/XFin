import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables.dart';

part 'assets_on_accounts_dao.g.dart';

@DriftAccessor(tables: [AssetsOnAccounts, Accounts, Assets])
class AssetsOnAccountsDao extends DatabaseAccessor<AppDatabase> with _$AssetsOnAccountsDaoMixin {
  AssetsOnAccountsDao(super.db);

  Future<void> validate(AssetOnAccount assetOnAccount) async {
    if (assetOnAccount.value < 0) {
      throw Exception('Value must be greater than or equal to 0.');
    }
    if (assetOnAccount.sharesOwned < 0) {
      throw Exception('Shares owned must be greater than or equal to 0.');
    }
    if (assetOnAccount.netBuyIn < 0) {
      throw Exception('Net buy in must be greater than or equal to 0.');
    }
    if (assetOnAccount.brokerBuyIn < 0) {
      throw Exception('Broker buy in must be greater than or equal to 0.');
    }
    if (assetOnAccount.buyFeeTotal < 0) {
      throw Exception('Buy fee total must be greater than or equal to 0.');
    }

    final account = await (select(accounts)..where((a) => a.id.equals(assetOnAccount.accountId))).getSingle();
    if (account.type != AccountTypes.portfolio) {
      throw Exception('Account must be of type portfolio.');
    }
  }
}
