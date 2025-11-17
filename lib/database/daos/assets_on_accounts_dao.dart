import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables.dart';

part 'assets_on_accounts_dao.g.dart';

@DriftAccessor(tables: [AssetsOnAccounts, Accounts, Assets])
class AssetsOnAccountsDao extends DatabaseAccessor<AppDatabase> with _$AssetsOnAccountsDaoMixin {
  AssetsOnAccountsDao(super.db);

  Future<int> addAssetOnAccount(AssetsOnAccountsCompanion entry) => into(assetsOnAccounts).insert(entry);

  Future<AssetOnAccount> getAssetOnAccount(int accountId, int assetId) {
    return (select(assetsOnAccounts)
          ..where((a) => a.accountId.equals(accountId) & a.assetId.equals(assetId)))
        .getSingle();
  }

  Future<void> updateBaseCurrencyAssetOnAccount(int accountId, double amount) async {
    AssetOnAccount baseCurrencyAssetOnAccount = await getAssetOnAccount(accountId, 1);
    await (update(assetsOnAccounts)..where((a) => a.assetId.equals(1) & a.accountId.equals(accountId))).write(
      AssetsOnAccountsCompanion(
        sharesOwned: Value(baseCurrencyAssetOnAccount.sharesOwned + amount),
        value: Value(baseCurrencyAssetOnAccount.value + amount)
      ),
    );
  }
}
