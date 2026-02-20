import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xfin/database/tables.dart';

import '../database/app_database.dart';
import '../providers/database_provider.dart';
import '../utils/format.dart';
import '../utils/indicator_calculator.dart';
import '../widgets/liquid_glass_widgets.dart';

class AssetAnalysisDetailScreen extends StatefulWidget {
  final int assetId;

  const AssetAnalysisDetailScreen({super.key, required this.assetId});

  @override
  State<AssetAnalysisDetailScreen> createState() => _AssetAnalysisDetailScreenState();
}

class _AssetAnalysisDetailScreenState extends State<AssetAnalysisDetailScreen> {
  late Future<_AssetAnalysisData> _future;
  String _range = '1M';
  bool _showShares = false;
  bool _showSma = false;
  bool _showEma = false;
  bool _showBb = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_AssetAnalysisData> _load() async {
    final db = context.read<DatabaseProvider>().db;
    final asset = await db.assetsDao.getAsset(widget.assetId);
    final trades = await (db.select(db.trades)..where((t) => t.assetId.equals(widget.assetId))).get();
    final bookings = await (db.select(db.bookings)..where((b) => b.assetId.equals(widget.assetId))).get();
    final transfers = await (db.select(db.transfers)..where((t) => t.assetId.equals(widget.assetId))).get();
    final accountRows = await (db.select(db.assetsOnAccounts)..where((a) => a.assetId.equals(widget.assetId))).get();

    final accounts = await db.accountsDao.getAllAccounts();
    final accountMap = {for (final account in accounts) account.id: account};

    final events = <_Event>[];
    for (final trade in trades) {
      events.add(_Event(
        ts: intToDateTime(trade.datetime)?.millisecondsSinceEpoch ?? 0,
        shares: trade.type == TradeTypes.buy ? trade.shares : -trade.shares,
        value: trade.targetAccountValueDelta,
      ));
    }
    for (final booking in bookings) {
      events.add(_Event(
        ts: intToDateTime(booking.date)?.millisecondsSinceEpoch ?? 0,
        shares: booking.shares,
        value: booking.value,
      ));
    }
    events.sort((a, b) => a.ts.compareTo(b.ts));

    double s = 0;
    double v = 0;
    final sharesHistory = <FlSpot>[];
    final valueHistory = <FlSpot>[];
    for (final event in events) {
      s += event.shares;
      v += event.value;
      sharesHistory.add(FlSpot(event.ts.toDouble(), s));
      valueHistory.add(FlSpot(event.ts.toDouble(), v));
    }
    if (sharesHistory.isEmpty) {
      final now = DateTime.now().millisecondsSinceEpoch.toDouble();
      sharesHistory.add(FlSpot(now, asset.shares));
      valueHistory.add(FlSpot(now, asset.value));
    }

    final buyTrades = trades.where((t) => t.type == TradeTypes.buy).toList();
    final sellTrades = trades.where((t) => t.type == TradeTypes.sell).toList();

    final accountHoldings = accountRows
        .where((r) => r.shares.abs() > 1e-9)
        .map((r) => _AccountHolding(
              label: accountMap[r.accountId]?.name ?? 'Account ${r.accountId}',
              value: r.value,
            ))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final inflow = bookings.where((b) => b.value > 0).fold<double>(0, (p, e) => p + e.value.abs());
    final outflow = bookings.where((b) => b.value < 0).fold<double>(0, (p, e) => p + e.value.abs());
    final firstTs = events.isEmpty ? DateTime.now().millisecondsSinceEpoch : events.first.ts;
    final lastTs = events.isEmpty ? DateTime.now().millisecondsSinceEpoch : events.last.ts;
    final monthSpan = max(1.0, (lastTs - firstTs) / const Duration(days: 30).inMilliseconds);

    return _AssetAnalysisData(
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
      eventFrequency: events.length / monthSpan,
      accountHoldings: accountHoldings,
    );
  }

  List<FlSpot> _forRange(List<FlSpot> data) {
    if (data.isEmpty) return data;
    final now = DateTime.now().millisecondsSinceEpoch;
    final ranges = {
      '1W': now - const Duration(days: 7).inMilliseconds,
      '1M': now - const Duration(days: 30).inMilliseconds,
      '1Y': now - const Duration(days: 365).inMilliseconds,
      'MAX': 0,
    };
    final threshold = ranges[_range] ?? 0;
    final filtered = data.where((e) => e.x >= threshold).toList();
    return filtered.isEmpty ? [data.last] : filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<_AssetAnalysisData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Center(child: Text(snapshot.error.toString()));
          }
          final data = snapshot.data!;
          final lineData = _forRange(_showShares ? data.sharesHistory : data.valueHistory);
          final barData = <LineChartBarData>[
            LineChartBarData(
              spots: lineData,
              color: Theme.of(context).colorScheme.primary,
              barWidth: 3,
              dotData: const FlDotData(show: false),
            ),
          ];
          final minX = lineData.first.x;
          if (_showSma) {
            barData.add(LineChartBarData(
              spots: IndicatorCalculator.calculateSma(_showShares ? data.sharesHistory : data.valueHistory, 7)
                  .where((s) => s.x >= minX)
                  .toList(),
              color: Colors.orange,
              barWidth: 2,
              dotData: const FlDotData(show: false),
            ));
          }
          if (_showEma) {
            barData.add(LineChartBarData(
              spots: IndicatorCalculator.calculateEma(_showShares ? data.sharesHistory : data.valueHistory, 7)
                  .where((s) => s.x >= minX)
                  .toList(),
              color: Colors.purple,
              barWidth: 2,
              dotData: const FlDotData(show: false),
            ));
          }
          if (_showBb) {
            barData.addAll(IndicatorCalculator.calculateBb(_showShares ? data.sharesHistory : data.valueHistory, 10)
                .map((e) => e.copyWith(spots: e.spots.where((s) => s.x >= minX).toList())));
          }

          final minY = barData
              .expand((b) => b.spots)
              .map((e) => e.y)
              .reduce(min);
          final maxY = barData
              .expand((b) => b.spots)
              .map((e) => e.y)
              .reduce(max);
          final pad = (maxY - minY).abs() * 0.1 + 0.1;

          return Stack(
            children: [
              SingleChildScrollView(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + kToolbarHeight + 12,
                  left: 12,
                  right: 12,
                  bottom: 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data.asset.name, style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: ['1W', '1M', '1Y', 'MAX'].map((range) {
                        return ChoiceChip(
                          label: Text(range),
                          selected: _range == range,
                          onSelected: (_) => setState(() => _range = range),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('Shares'),
                          selected: _showShares,
                          onSelected: (_) => setState(() => _showShares = true),
                        ),
                        ChoiceChip(
                          label: const Text('Value'),
                          selected: !_showShares,
                          onSelected: (_) => setState(() => _showShares = false),
                        ),
                        FilterChip(label: const Text('SMA'), selected: _showSma, onSelected: (v) => setState(() => _showSma = v)),
                        FilterChip(label: const Text('EMA'), selected: _showEma, onSelected: (v) => setState(() => _showEma = v)),
                        FilterChip(label: const Text('BB'), selected: _showBb, onSelected: (v) => setState(() => _showBb = v)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 240,
                      child: LineChart(
                        LineChartData(
                          minY: minY - pad,
                          maxY: maxY + pad,
                          gridData: const FlGridData(show: true),
                          borderData: FlBorderData(show: false),
                          titlesData: const FlTitlesData(
                            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          ),
                          lineBarsData: barData,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _sectionTitle(context, 'Trading stats'),
                    _statTile('Buys', data.buys.toString()),
                    _statTile('Sells', data.sells.toString()),
                    _statTile('Total profit', formatCurrency(data.totalProfit)),
                    _statTile('Total fees', formatCurrency(data.totalFees)),
                    _statTile('Trade volume', formatCurrency(data.tradeVolume)),
                    const SizedBox(height: 16),
                    _sectionTitle(context, 'General stats'),
                    _statTile('Booking inflows', formatCurrency(data.bookingInflows)),
                    _statTile('Booking outflows', formatCurrency(data.bookingOutflows)),
                    _statTile('Transfers', data.transferCount.toString()),
                    _statTile('Transfer volume', formatCurrency(data.transferVolume)),
                    _statTile('Events per month', data.eventFrequency.toStringAsFixed(1)),
                    const SizedBox(height: 16),
                    _sectionTitle(context, 'Held on accounts'),
                    if (data.accountHoldings.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(8),
                        child: Text('No account positions.'),
                      )
                    else ...[
                      SizedBox(
                        height: 220,
                        child: PieChart(
                          PieChartData(
                            centerSpaceRadius: 40,
                            sectionsSpace: 3,
                            sections: List.generate(data.accountHoldings.length, (i) {
                              final h = data.accountHoldings[i];
                              return PieChartSectionData(
                                value: h.value,
                                color: [
                                  const Color(0xFF3B82F6),
                                  const Color(0xFF2563EB),
                                  const Color(0xFF1D4ED8),
                                  const Color(0xFF1E40AF),
                                ][i % 4],
                                title: '',
                                radius: 78,
                              );
                            }),
                          ),
                        ),
                      ),
                      ...data.accountHoldings.map((h) => ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: Text(h.label),
                            trailing: Text(formatCurrency(h.value)),
                          )),
                    ],
                  ],
                ),
              ),
              buildLiquidGlassAppBar(context, title: const Text('Asset analysis')),
            ],
          );
        },
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700));
  }

  Widget _statTile(String label, String value) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      trailing: Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}

class _AssetAnalysisData {
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
  final List<_AccountHolding> accountHoldings;

  const _AssetAnalysisData({
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

class _Event {
  final int ts;
  final double shares;
  final double value;

  const _Event({required this.ts, required this.shares, required this.value});
}

class _AccountHolding {
  final String label;
  final double value;

  const _AccountHolding({required this.label, required this.value});
}
