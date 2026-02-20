import 'dart:math';
import 'package:drift/drift.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../utils/global_constants.dart';
import '../../utils/format.dart';
import '../app_database.dart';
import '../tables.dart';

part 'assets_dao.g.dart';

@DriftAccessor(tables: [Assets, Trades, AssetsOnAccounts])
class AssetsDao extends DatabaseAccessor<AppDatabase> with _$AssetsDaoMixin {
  AssetsDao(super.db);

  Future<AssetAnalysisDetailsData> getAssetAnalysisDetails(int assetId) async {
    final futures = await Future.wait([
      getAsset(assetId),
      (db.select(db.trades)..where((t) => t.assetId.equals(assetId))).get(),
      (db.select(db.bookings)..where((b) => b.assetId.equals(assetId))).get(),
      (db.select(db.transfers)..where((t) => t.assetId.equals(assetId))).get(),
      (db.select(db.assetsOnAccounts)..where((a) => a.assetId.equals(assetId))).get(),
      db.accountsDao.getAllAccounts(),
    ]);

    final asset = futures[0] as Asset;
    final trades = futures[1] as List<Trade>;
    final bookings = futures[2] as List<Booking>;
    final transfers = futures[3] as List<Transfer>;
    final accountRows = futures[4] as List<AssetOnAccount>;
    final accounts = futures[5] as List<Account>;

    final accountMap = {for (final account in accounts) account.id: account};

    final Map<DateTime, _AssetValueDelta> dailyDeltas = {};

    for (final trade in trades) {
      final date = intToDateTime(trade.datetime ~/ 1000000)!;
      final dateOnly = DateTime(date.year, date.month, date.day);
      final signedShares =
          trade.type == TradeTypes.buy ? trade.shares : -trade.shares;

      final current = dailyDeltas[dateOnly] ?? const _AssetValueDelta();
      dailyDeltas[dateOnly] = _AssetValueDelta(
        shares: current.shares + signedShares,
        value: current.value + trade.targetAccountValueDelta,
      );
    }

    for (final booking in bookings) {
      final date = intToDateTime(booking.date)!;
      final dateOnly = DateTime(date.year, date.month, date.day);
      final current = dailyDeltas[dateOnly] ?? const _AssetValueDelta();
      dailyDeltas[dateOnly] = _AssetValueDelta(
        shares: current.shares + booking.shares,
        value: current.value + booking.value,
      );
    }

    final sharesHistory = <FlSpot>[];
    final valueHistory = <FlSpot>[];

    if (dailyDeltas.isEmpty) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      sharesHistory.add(FlSpot(today.millisecondsSinceEpoch.toDouble(), asset.shares));
      valueHistory.add(FlSpot(today.millisecondsSinceEpoch.toDouble(), asset.value));
    } else {
      final sortedDates = dailyDeltas.keys.toList()..sort();
      final firstDate = sortedDates.first;
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));

      double runningShares = 0;
      double runningValue = 0;

      for (var date = firstDate;
          date.isBefore(tomorrow);
          date = date.add(const Duration(days: 1))) {
        final dateOnly = DateTime(date.year, date.month, date.day);
        final delta = dailyDeltas[dateOnly] ?? const _AssetValueDelta();
        runningShares += delta.shares;
        runningValue += delta.value;

        sharesHistory.add(FlSpot(dateOnly.millisecondsSinceEpoch.toDouble(), normalize(runningShares)));
        valueHistory.add(FlSpot(dateOnly.millisecondsSinceEpoch.toDouble(), normalize(runningValue)));
      }
    }

    final buyTrades = trades.where((t) => t.type == TradeTypes.buy).toList();
    final sellTrades = trades.where((t) => t.type == TradeTypes.sell).toList();

    final accountHoldings = accountRows
        .where((r) => r.shares.abs() > 1e-9)
        .map((r) => AssetAccountHolding(
              label: accountMap[r.accountId]?.name ?? 'Account ${r.accountId}',
              value: r.value,
            ))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final inflow = bookings
        .where((b) => b.value > 0)
        .fold<double>(0, (p, e) => p + e.value.abs());
    final outflow = bookings
        .where((b) => b.value < 0)
        .fold<double>(0, (p, e) => p + e.value.abs());

    final firstTs = sharesHistory.first.x.toInt();
    final lastTs = sharesHistory.last.x.toInt();
    final monthSpan = max(1.0, (lastTs - firstTs) / const Duration(days: 30).inMilliseconds);

    return AssetAnalysisDetailsData(
      asset: asset,
      sharesHistory: sharesHistory,
      valueHistory: valueHistory,
      buys: buyTrades.length,
      sells: sellTrades.length,
      totalProfit: trades.fold<double>(0, (p, t) => p + t.profitAndLoss),
      totalFees: trades.fold<double>(0, (p, t) => p + t.fee + t.tax),
      tradeVolume: trades.fold<double>(0, (p, t) => p + (t.costBasis * t.shares).abs()),
      bookingInflows: inflow,
      bookingOutflows: outflow,
      transferCount: transfers.length,
      transferVolume: transfers.fold<double>(0, (p, t) => p + t.value.abs()),
      eventFrequency: (trades.length + bookings.length) / monthSpan,
      accountHoldings: accountHoldings,
    );
  }

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

class AssetAnalysisDetailsData {
  final Asset asset;
  final List<FlSpot> sharesHistory;
  final List<FlSpot> valueHistory;
  final int buys;
  final int sells;
  final double totalProfit;
  final double totalFees;
  final double tradeVolume;
  final double bookingInflows;
  final double bookingOutflows;
  final int transferCount;
  final double transferVolume;
  final double eventFrequency;
  final List<AssetAccountHolding> accountHoldings;

  const AssetAnalysisDetailsData({
    required this.asset,
    required this.sharesHistory,
    required this.valueHistory,
    required this.buys,
    required this.sells,
    required this.totalProfit,
    required this.totalFees,
    required this.tradeVolume,
    required this.bookingInflows,
    required this.bookingOutflows,
    required this.transferCount,
    required this.transferVolume,
    required this.eventFrequency,
    required this.accountHoldings,
  });
}

class AssetAccountHolding {
  final String label;
  final double value;

  const AssetAccountHolding({required this.label, required this.value});
}

class _AssetValueDelta {
  final double shares;
  final double value;

  const _AssetValueDelta({this.shares = 0, this.value = 0});
}
