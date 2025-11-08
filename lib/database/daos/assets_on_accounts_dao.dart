import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables.dart';

part 'assets_on_accounts_dao.g.dart';

@DriftAccessor(tables: [AssetsOnAccounts, Accounts, Assets])
class AssetsOnAccountsDao extends DatabaseAccessor<AppDatabase> with _$AssetsOnAccountsDaoMixin {
  AssetsOnAccountsDao(super.db);

  Future<void> updateAssetsOnAccount(AssetsOnAccountsCompanion entry) {
    return into(assetsOnAccounts).insertOnConflictUpdate(entry);
  }

  Future<AssetOnAccount> getAssetOnAccount(int accountId, int assetId) {
    return (select(assetsOnAccounts)
          ..where((a) => a.accountId.equals(accountId) & a.assetId.equals(assetId)))
        .getSingle();
  }
}
