import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xfin/l10n/app_localizations.dart';

import '../database/daos/assets_dao.dart';
import '../providers/database_provider.dart';
import '../utils/format.dart';
import '../widgets/analysis_line_chart_section.dart';
import '../widgets/charts.dart';
import '../widgets/common_widgets.dart';
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
  bool _showSma200 = false;
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
    AppLocalizations l10n = AppLocalizations.of(context)!;
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
                      showSma200: _showSma200,
                      showEma: _showEma,
                      showBb: _showBb,
                      showSma200Toggle: true,
                      onShowSmaChanged: (value) => setState(() => _showSma = value),
                      onShowSma200Changed: (value) => setState(() => _showSma200 = value),
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
                      valueLabel: l10n.total,
                      topRight: Wrap(
                        alignment: WrapAlignment.end,
                        spacing: 8,
                        children: [
                          ChoiceChip(
                            label: Text(l10n.value),
                            selected: !_showShares,
                            showCheckmark: false,
                            onSelected: (_) => setState(() => _showShares = false),
                          ),
                          ChoiceChip(
                            label: Text(l10n.shares),
                            selected: _showShares,
                            showCheckmark: false,
                            onSelected: (_) => setState(() => _showShares = true),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    SectionTitle(title: 'Trading stats', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    StatTile(label: 'Buys', value: data.buys.toString()),
                    StatTile(label: 'Sells', value: data.sells.toString()),
                    StatTile(label: 'Total profit', value: formatCurrency(data.totalProfit)),
                    StatTile(label: 'Total fees', value: formatCurrency(data.totalFees)),
                    StatTile(label: 'Trade volume', value: formatCurrency(data.tradeVolume)),
                    const SizedBox(height: 12),
                    SectionTitle(title: 'General stats', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    StatTile(label: 'Booking inflows', value: formatCurrency(data.bookingInflows)),
                    StatTile(label: 'Booking outflows', value: formatCurrency(data.bookingOutflows)),
                    StatTile(label: 'Transfers', value: data.transferCount.toString()),
                    StatTile(label: 'Transfer volume', value: formatCurrency(data.transferVolume)),
                    StatTile(label: 'Events per month', value: data.eventFrequency.toStringAsFixed(1)),
                    const SizedBox(height: 12),
                    SectionTitle(title: 'Held on accounts', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 32),
                    if (data.accountHoldings.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(8),
                        child: Text('No account positions.'),
                      )
                    else
                      AllocationBreakdownSection(
                        items: data.accountHoldings
                            .map((h) => AllocationItem(label: h.label, value: h.value))
                            .toList(),
                        title: l10n.investments,
                      ),
                  ],
                ),
              ),
              buildLiquidGlassAppBar(context, title: Text(data.asset.name)),
            ],
          );
        },
      ),
    );
  }
}
