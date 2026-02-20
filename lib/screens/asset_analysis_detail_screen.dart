import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../database/daos/assets_dao.dart';
import '../providers/database_provider.dart';
import '../utils/format.dart';
import '../widgets/analysis_line_chart_section.dart';
import '../widgets/liquid_glass_widgets.dart';

class AssetAnalysisDetailScreen extends StatefulWidget {
  final int assetId;

  const AssetAnalysisDetailScreen({super.key, required this.assetId});

  @override
  State<AssetAnalysisDetailScreen> createState() => _AssetAnalysisDetailScreenState();
}

class _AssetAnalysisDetailScreenState extends State<AssetAnalysisDetailScreen> {
  late Future<AssetAnalysisDetailsData> _future;
  String _range = '1W';
  bool _showShares = false;
  bool _showSma = false;
  bool _showEma = false;
  bool _showBb = false;
  LineBarSpot? _touchedSpot;
  int _chartPointerCount = 0;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<AssetAnalysisDetailsData> _load() async {
    final db = context.read<DatabaseProvider>().db;
    return db.assetsDao.getAssetAnalysisDetails(widget.assetId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<AssetAnalysisDetailsData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Center(child: Text(snapshot.error.toString()));
          }
          final data = snapshot.data!;
          return Stack(
            children: [
              SingleChildScrollView(
                physics: _chartPointerCount > 0
                    ? const NeverScrollableScrollPhysics()
                    : null,
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
                      children: [
                        ChoiceChip(
                          label: const Text('Value'),
                          selected: !_showShares,
                          onSelected: (_) => setState(() => _showShares = false),
                        ),
                        ChoiceChip(
                          label: const Text('Shares'),
                          selected: _showShares,
                          onSelected: (_) => setState(() => _showShares = true),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    AnalysisLineChartSection(
                      allData: _showShares ? data.sharesHistory : data.valueHistory,
                      startValue: 0,
                      selectedRange: _range,
                      onRangeSelected: (range) {
                        setState(() {
                          _range = range;
                          _touchedSpot = null;
                        });
                      },
                      showSma: _showSma,
                      showEma: _showEma,
                      showBb: _showBb,
                      onShowSmaChanged: (value) => setState(() => _showSma = value),
                      onShowEmaChanged: (value) => setState(() => _showEma = value),
                      onShowBbChanged: (value) => setState(() => _showBb = value),
                      touchedSpot: _touchedSpot,
                      onTouchedSpotChanged: (spot) => setState(() => _touchedSpot = spot),
                      onPointerDown: () => setState(() => _chartPointerCount += 1),
                      onPointerUpOrCancel: () =>
                          setState(() => _chartPointerCount = max(0, _chartPointerCount - 1)),
                      valueFormatter: _showShares
                          ? (value) => value.toStringAsFixed(4)
                          : formatCurrency,
                      rangeTextBuilder: (range) {
                        switch (range) {
                          case '1W':
                            return 'Seit 7 Tagen';
                          case '1M':
                            return 'Seit 1 Monat';
                          case '1J':
                            return 'Seit 1 Jahr';
                          case 'MAX':
                            return 'Insgesamt';
                          default:
                            return '';
                        }
                      },
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
