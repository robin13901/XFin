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
      await (delete(assetsOnAccounts)..where((a) => a.assetId.equals(assetId))).go();
      await (delete(assets)..where((a) => a.id.equals(assetId))).go();
    });
  }

  Future<Asset> getAsset(int id) => (select(assets)..where((a) => a.id.equals(id))).getSingle();

  Future<List<Asset>> getAllAssets() async => (select(assets)).get();

  Future getAssetByTickerSymbol(String tickerSymbol) async =>
      (select(assets)..where((a) => a.tickerSymbol.equals(tickerSymbol))).getSingle();

  Future<bool> hasAssetsOnAccounts(int assetId) async {
    final result = await (select(assetsOnAccounts)..where((a) => a.assetId.equals(assetId) & a.shares.isBiggerThanValue(1e-12))).get();
    return result.isNotEmpty;
  }

  Future<bool> hasTrades(int assetId) async {
    final result = await (select(trades)..where((t) => t.assetId.equals(assetId))).get();
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
        value: Value(normalize(newValue)),
        netCostBasis: Value(normalize(newNetCostBasis)),
        brokerCostBasis: Value(normalize(newBrokerCostBasis)),
        buyFeeTotal: Value(normalize(newBuyFeeTotal)),
      ),
    );
  }

  Future<AssetAnalysisDbData> getAssetAnalysisDbData(int assetId) async {
    final assetFuture = getAsset(assetId);
    final tradesFuture = (select(trades)..where((t) => t.assetId.equals(assetId))).get();
    final bookingsFuture = (select(db.bookings)..where((b) => b.assetId.equals(assetId))).get();
    final transfersFuture = (select(db.transfers)..where((t) => t.assetId.equals(assetId))).get();

    final accountRows = await (select(assetsOnAccounts)..where((a) => a.assetId.equals(assetId))).get();
    final accountIds = accountRows.map((e) => e.accountId).toSet().toList();
    final accountNameById = <int, String>{};
    if (accountIds.isNotEmpty) {
      final accountRows = await (select(db.accounts)..where((a) => a.id.isIn(accountIds))).get();
      for (final account in accountRows) {
        accountNameById[account.id] = account.name;
      }
    }

    return AssetAnalysisDbData(
      asset: await assetFuture,
      trades: await tradesFuture,
      bookings: await bookingsFuture,
      transfers: await transfersFuture,
      holdings: accountRows
          .where((row) => row.shares.abs() > 1e-9)
          .map((row) => AssetAccountHolding(
                accountId: row.accountId,
                accountName: accountNameById[row.accountId] ?? 'Account ${row.accountId}',
                shares: row.shares,
                value: row.value,
              ))
          .toList()
        ..sort((a, b) => b.value.compareTo(a.value)),
    );
  }

  Stream<List<Asset>> watchAllAssets() => (select(assets)..orderBy([(t) => OrderingTerm.desc(t.value)])).watch();
}

class AssetAnalysisDbData {
  final Asset asset;
  final List<Trade> trades;
  final List<Booking> bookings;
  final List<Transfer> transfers;
  final List<AssetAccountHolding> holdings;

  const AssetAnalysisDbData({
    required this.asset,
    required this.trades,
    required this.bookings,
    required this.transfers,
    required this.holdings,
  });
}

class AssetAccountHolding {
  final int accountId;
  final String accountName;
  final double shares;
  final double value;

  const AssetAccountHolding({
    required this.accountId,
    required this.accountName,
    required this.shares,
    required this.value,
  });
}
