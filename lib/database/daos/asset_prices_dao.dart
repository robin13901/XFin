import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables.dart';

part 'asset_prices_dao.g.dart';

@DriftAccessor(tables: [AssetPrices, Assets, Bookings, Trades, Transfers])
class AssetPricesDao extends DatabaseAccessor<AppDatabase>
    with _$AssetPricesDaoMixin {
  AssetPricesDao(super.db);

  Future<List<AssetPrice>> getPricesForRange(
      int assetId, int fromDate, int toDate) {
    return (select(assetPrices)
          ..where((t) =>
              t.assetId.equals(assetId) &
              t.date.isBiggerOrEqualValue(fromDate) &
              t.date.isSmallerOrEqualValue(toDate))
          ..orderBy([(t) => OrderingTerm.asc(t.date)]))
        .get();
  }

  Future<AssetPrice?> getPrice(int assetId, int date) {
    return (select(assetPrices)
          ..where(
              (t) => t.assetId.equals(assetId) & t.date.equals(date)))
        .getSingleOrNull();
  }

  Future<int?> getLatestPriceDate(int assetId) async {
    final query = selectOnly(assetPrices)
      ..addColumns([assetPrices.date.max()])
      ..where(assetPrices.assetId.equals(assetId));
    final row = await query.getSingleOrNull();
    return row?.read(assetPrices.date.max());
  }

  Future<int?> getFirstAssetUsageDate(int assetId) async {
    final bookingMin = selectOnly(bookings)
      ..addColumns([bookings.date.min()])
      ..where(bookings.assetId.equals(assetId));
    final tradeMin = selectOnly(trades)
      ..addColumns([trades.datetime.min()])
      ..where(trades.assetId.equals(assetId));
    final transferMin = selectOnly(transfers)
      ..addColumns([transfers.date.min()])
      ..where(transfers.assetId.equals(assetId));

    final bRow = await bookingMin.getSingleOrNull();
    final tRow = await tradeMin.getSingleOrNull();
    final xRow = await transferMin.getSingleOrNull();

    final dates = <int>[
      if (bRow?.read(bookings.date.min()) != null)
        bRow!.read(bookings.date.min())!,
      if (tRow?.read(trades.datetime.min()) != null)
        tRow!.read(trades.datetime.min())!,
      if (xRow?.read(transfers.date.min()) != null)
        xRow!.read(transfers.date.min())!,
    ];

    if (dates.isEmpty) return null;
    dates.sort();
    return dates.first;
  }

  Future<void> insertPrices(List<AssetPricesCompanion> prices) async {
    await batch((b) {
      for (final price in prices) {
        b.insert(assetPrices, price,
            onConflict: DoUpdate(
              (old) => AssetPricesCompanion(price: price.price),
              target: [assetPrices.assetId, assetPrices.date],
            ));
      }
    });
  }

  Future<void> insertPrice(AssetPricesCompanion price) {
    return into(assetPrices).insert(price,
        onConflict: DoUpdate(
          (old) => AssetPricesCompanion(price: price.price),
          target: [assetPrices.assetId, assetPrices.date],
        ));
  }

  Future<int> deleteAllForAsset(int assetId) {
    return (delete(assetPrices)..where((t) => t.assetId.equals(assetId))).go();
  }

  Future<List<Asset>> getAssetsWithApiIdentifier() {
    return (select(assets)
          ..where((t) => t.apiIdentifier.isNotNull()))
        .get();
  }

  Stream<List<AssetPrice>> watchPricesForAsset(int assetId) {
    return (select(assetPrices)
          ..where((t) => t.assetId.equals(assetId))
          ..orderBy([(t) => OrderingTerm.asc(t.date)]))
        .watch();
  }

  Future<Map<int, double>> getPriceMapForAsset(int assetId) async {
    final rows = await (select(assetPrices)
          ..where((t) => t.assetId.equals(assetId)))
        .get();
    return {for (final r in rows) r.date: r.price};
  }

  Future<Map<int, Map<int, double>>> getAllPricesByAssetAndDate() async {
    final all = await select(assetPrices).get();
    final result = <int, Map<int, double>>{};
    for (final p in all) {
      result.putIfAbsent(p.assetId, () => {})[p.date] = p.price;
    }
    return result;
  }
}
