import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables.dart';

part 'assets_dao.g.dart';

@DriftAccessor(tables: [Assets, Trades, AssetsOnAccounts])
class AssetsDao extends DatabaseAccessor<AppDatabase> with _$AssetsDaoMixin {
  AssetsDao(super.db);

  Future<int> insert(AssetsCompanion entry) => into(assets).insert(entry);

  Future<Asset> getAsset(int id) =>
      (select(assets)..where((a) => a.id.equals(id))).getSingle();

  Future getAssetByTickerSymbol(String tickerSymbol) async =>
      (select(assets)..where((a) => a.tickerSymbol.equals(tickerSymbol)))
          .getSingle();

  Future<bool> hasTrades(int assetId) async {
    final result =
        await (select(trades)..where((t) => t.assetId.equals(assetId))).get();
    return result.isNotEmpty;
  }

  Future<bool> hasAssetsOnAccounts(int assetId) async {
    final result = await (select(assetsOnAccounts)
          ..where((a) => a.assetId.equals(assetId)))
        .get();
    return result.isNotEmpty;
  }

  Stream<List<Asset>> watchAllAssets() => select(assets).watch();

  Future<void> updateAsset(Asset asset) => update(assets).replace(asset);

  Future<void> updateBaseCurrencyAsset(double amount) async {
    Asset baseCurrencyAsset = await getAsset(1);
    await (update(assets)..where((a) => a.id.equals(1))).write(
      AssetsCompanion(
          sharesOwned: Value(baseCurrencyAsset.sharesOwned + amount),
          value: Value(baseCurrencyAsset.value + amount)),
    );
  }

  Future<void> deleteAsset(int id) =>
      (delete(assets)..where((a) => a.id.equals(id))).go();

}
