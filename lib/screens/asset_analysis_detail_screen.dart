import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../database/daos/assets_dao.dart';
import '../providers/database_provider.dart';
import '../utils/format.dart';
import '../widgets/analysis_line_chart_panel.dart';
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
  LineBarSpot? _touchedSpot;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_AssetAnalysisData> _load() async {
    final db = context.read<DatabaseProvider>().db;
    final raw = await db.assetsDao.getAssetAnalysisDbData(widget.assetId);

    final events = <_Event>[];
    for (final trade in raw.trades) {
      events.add(_Event(
        ts: intToDateTime(trade.datetime)?.millisecondsSinceEpoch ?? 0,
        shares: trade.type == TradeTypes.buy ? trade.shares : -trade.shares,
        value: trade.targetAccountValueDelta,
      ));
    }
    for (final booking in raw.bookings) {
      events.add(_Event(
        ts: intToDateTime(booking.date)?.millisecondsSinceEpoch ?? 0,
        shares: booking.shares,
        value: booking.value,
      ));
    }
    events.sort((a, b) => a.ts.compareTo(b.ts));

    double runningShares = 0;
    double runningValue = 0;
    final sharesHistory = <FlSpot>[];
    final valueHistory = <FlSpot>[];
    for (final event in events) {
      runningShares += event.shares;
      runningValue += event.value;
      sharesHistory.add(FlSpot(event.ts.toDouble(), runningShares));
      valueHistory.add(FlSpot(event.ts.toDouble(), runningValue));
    }
    if (sharesHistory.isEmpty) {
      final now = DateTime.now().millisecondsSinceEpoch.toDouble();
      sharesHistory.add(FlSpot(now, raw.asset.shares));
      valueHistory.add(FlSpot(now, raw.asset.value));
    }

    final buys = raw.trades.where((t) => t.type == TradeTypes.buy).length;
    final sells = raw.trades.where((t) => t.type == TradeTypes.sell).length;
    final inflow = raw.bookings.where((b) => b.value > 0).fold<double>(0, (p, e) => p + e.value.abs());
    final outflow = raw.bookings.where((b) => b.value < 0).fold<double>(0, (p, e) => p + e.value.abs());
    final firstTs = events.isEmpty ? DateTime.now().millisecondsSinceEpoch : events.first.ts;
    final lastTs = events.isEmpty ? DateTime.now().millisecondsSinceEpoch : events.last.ts;
    final monthSpan = max(1.0, (lastTs - firstTs) / const Duration(days: 30).inMilliseconds);

    return _AssetAnalysisData(
      name: raw.asset.name,
      sharesHistory: sharesHistory,
      valueHistory: valueHistory,
      buys: buys,
      sells: sells,
      totalProfit: raw.trades.fold<double>(0, (p, t) => p + t.profitAndLoss),
      totalFees: raw.trades.fold<double>(0, (p, t) => p + t.fee + t.tax),
      tradeVolume: raw.trades.fold<double>(0, (p, t) => p + (t.costBasis * t.shares).abs()),
      bookingInflows: inflow,
      bookingOutflows: outflow,
      transferCount: raw.transfers.length,
      transferVolume: raw.transfers.fold<double>(0, (p, t) => p + t.value.abs()),
      eventFrequency: events.length / monthSpan,
      accountHoldings: raw.holdings,
    );
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
          final lineData = _showShares ? data.sharesHistory : data.valueHistory;

          return Stack(
            children: [
              SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(12, MediaQuery.of(context).padding.top + kToolbarHeight + 12, 12, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data.name, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(label: const Text('Shares'), selected: _showShares, onSelected: (_) => setState(() => _showShares = true)),
                        ChoiceChip(label: const Text('Value'), selected: !_showShares, onSelected: (_) => setState(() => _showShares = false)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    AnalysisLineChartPanel(
                      allData: lineData,
                      baselineValue: lineData.first.y,
                      selectedRange: _range,
                      onRangeSelected: (v) => setState(() {
                        _range = v;
                        _touchedSpot = null;
                      }),
                      touchedSpot: _touchedSpot,
                      onTouchedSpotChanged: (spot) => setState(() => _touchedSpot = spot),
                      showSma: _showSma,
                      showEma: _showEma,
                      showBb: _showBb,
                      onShowSmaChanged: (v) => setState(() => _showSma = v),
                      onShowEmaChanged: (v) => setState(() => _showEma = v),
                      onShowBbChanged: (v) => setState(() => _showBb = v),
                      valueFormatter: _showShares ? (v) => v.toStringAsFixed(4) : formatCurrency,
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
                      const Padding(padding: EdgeInsets.all(8), child: Text('No account positions.'))
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
                      ...data.accountHoldings.map(
                        (h) => ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(h.accountName),
                          trailing: Text(formatCurrency(h.value)),
                        ),
                      ),
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
  final String name;
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

  const _AssetAnalysisData({
    required this.name,
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
