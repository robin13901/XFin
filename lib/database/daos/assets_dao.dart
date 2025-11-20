import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables.dart';

part 'assets_dao.g.dart';

@DriftAccessor(tables: [Assets, Trades, AssetsOnAccounts])
class AssetsDao extends DatabaseAccessor<AppDatabase> with _$AssetsDaoMixin {
  AssetsDao(super.db);

  Stream<List<Asset>> watchAllAssets() => select(assets).watch();

  Future<int> addAsset(AssetsCompanion entry) {
    return into(assets).insert(entry);
  }

  Future<void> updateAsset(Asset asset) {
    return update(assets).replace(asset);
  }

  Future<void> deleteAsset(int id) {
    return (delete(assets)..where((a) => a.id.equals(id))).go();
  }

  Future<Asset> getAsset(int id) {
    return (select(assets)..where((a) => a.id.equals(id))).getSingle();
  }

  Future<bool> hasTrades(int assetId) async {
    final count = await (select(trades)..where((t) => t.assetId.equals(assetId))).get().then((value) => value.length);
    return count > 0;
  }

  Future<bool> hasAssetsOnAccounts(int assetId) async {
    final count = await (select(assetsOnAccounts)..where((a) => a.assetId.equals(assetId))).get().then((value) => value.length);
    return count > 0;
  }

  Future getAssetByTickerSymbol(String tickerSymbol) async {
    return (select(assets)..where((a) => a.tickerSymbol.equals(tickerSymbol))).getSingle();
  }

  Future<void> updateBaseCurrencyAsset(double amount) async {
    Asset baseCurrencyAsset = await getAsset(1);
    await (update(assets)..where((a) => a.id.equals(1))).write(
      AssetsCompanion(
        sharesOwned: Value(baseCurrencyAsset.sharesOwned + amount),
        value: Value(baseCurrencyAsset.value + amount)
      ),
    );
  }
}
