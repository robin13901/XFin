import 'package:drift/drift.dart';
import '../../utils/global_constants.dart';
import '../app_database.dart';
import '../tables.dart';

part 'assets_dao.g.dart';

@DriftAccessor(tables: [Assets, Trades, AssetsOnAccounts])
class AssetsDao extends DatabaseAccessor<AppDatabase> with _$AssetsDaoMixin {
  AssetsDao(super.db);

  Future<int> insert(AssetsCompanion entry) => into(assets).insert(entry);

  Future<void> deleteAsset(int assetId) {
    return transaction(() async {
      await (delete(assetsOnAccounts)
        ..where((a) => a.assetId.equals(assetId)))
          .go();

      await (delete(assets)
        ..where((a) => a.id.equals(assetId)))
          .go();
    });
  }

  Future<Asset> getAsset(int id) =>
      (select(assets)..where((a) => a.id.equals(id))).getSingle();

  Future<List<Asset>> getAllAssets() async => (select(assets)).get();

  Future getAssetByTickerSymbol(String tickerSymbol) async =>
      (select(assets)..where((a) => a.tickerSymbol.equals(tickerSymbol)))
          .getSingle();

  Future<bool> hasAssetsOnAccounts(int assetId) async {
    final result = await (select(assetsOnAccounts)
      ..where((a) => a.assetId.equals(assetId) & a.shares.isBiggerThanValue(1e-12)))
        .get();
    return result.isNotEmpty;
  }

  Future<bool> hasTrades(int assetId) async {
    final result =
        await (select(trades)..where((t) => t.assetId.equals(assetId))).get();
    return result.isNotEmpty;
  }

  Future<void> updateAsset(int assetId, double sharesDelta, double valueDelta, buyFeeTotalDelta) async {
    Asset asset = await getAsset(assetId);

    final newShares = asset.shares + sharesDelta;
    final newValue = asset.value + valueDelta;
    final newBuyFeeTotal = asset.buyFeeTotal + buyFeeTotalDelta;
    final newNetCostBasis = newShares == 0 ? 1 : newValue / newShares;
    final newBrokerCostBasis = newShares == 0 ? 1 : (newValue + newBuyFeeTotal) / newShares;

    await (update(assets)..where((a) => a.id.equals(assetId))).write(
      AssetsCompanion(
        shares: Value(normalize(newShares)),
        value: Value(normalize(newValue)),//newValue < 0 ? 0 : normalize(newValue)),
        netCostBasis: Value(normalize(newNetCostBasis)),
        brokerCostBasis: Value(normalize(newBrokerCostBasis)),
        buyFeeTotal: Value(normalize(newBuyFeeTotal))
      ),
    );
  }

  Stream<List<Asset>> watchAllAssets() =>
      (select(assets)..orderBy([(t) => OrderingTerm.desc(t.value)])).watch();

}
