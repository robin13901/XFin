import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xfin/l10n/app_localizations.dart';

import '../app_theme.dart';
import '../database/daos/assets_dao.dart';
import '../providers/database_provider.dart';
import '../providers/live_price_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/format.dart';
import '../widgets/analysis_line_chart_section.dart';
import '../widgets/aurora_background.dart';
import '../widgets/charts.dart';
import '../widgets/common_widgets.dart';
import '../widgets/live_toggle_button.dart';
import '../widgets/liquid_glass_widgets.dart';

class AssetAnalysisDetailScreen extends StatefulWidget {
  final int assetId;

  const AssetAnalysisDetailScreen({super.key, required this.assetId});

  @override
  State<AssetAnalysisDetailScreen> createState() => _AssetAnalysisDetailScreenState();
}

class _AssetAnalysisDetailScreenState extends State<AssetAnalysisDetailScreen>
    with SingleTickerProviderStateMixin {
  late Future<AssetAnalysisDetailsData> _future;
  String _range = '1W';
  bool _showShares = false;
  bool _showSma = false;
  bool _showEma = false;
  bool _showBb = false;
  bool _showSma200 = false;
  LineBarSpot? _touchedSpot;
  int _chartPointerCount = 0;

  List<FlSpot>? _marketValueHistory;

  late final AnimationController _livePulseController;
  late final Animation<double> _livePulseAnimation;

  @override
  void initState() {
    super.initState();
    _future = _load();
    _livePulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _livePulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _livePulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _livePulseController.dispose();
    super.dispose();
  }

  Future<AssetAnalysisDetailsData> _load() async {
    final db = context.read<DatabaseProvider>().db;
    final data = await db.assetsDao.getAssetAnalysisDetails(widget.assetId);

    final priceMap = await db.assetPricesDao.getPriceMapForAsset(widget.assetId);
    _marketValueHistory = _computeMarketValueHistory(data.sharesHistory, priceMap);

    return data;
  }

  List<FlSpot> _computeMarketValueHistory(
      List<FlSpot> sharesHistory, Map<int, double> priceMap) {
    final result = <FlSpot>[];

    for (final spot in sharesHistory) {
      final date = DateTime.fromMillisecondsSinceEpoch(spot.x.toInt());
      final dateInt = dateTimeToInt(date);
      if (!priceMap.containsKey(dateInt)) continue;
      result.add(FlSpot(spot.x, spot.y * priceMap[dateInt]!));
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    AppLocalizations l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor:
          context.watch<ThemeProvider>().isAurora ? Colors.transparent : null,
      body: FutureBuilder<AssetAnalysisDetailsData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Center(child: Text(l10n.errorLoadingData));
          }
          final data = snapshot.data!;
          return Consumer<LivePriceProvider>(
            builder: (context, liveProvider, _) {
              final isLive = liveProvider.isLive && liveProvider.isConnected;
              final livePrice = liveProvider.getLivePrice(widget.assetId);
              final currentShares = data.asset.shares;
              final liveValue = isLive && livePrice != null
                  ? livePrice * currentShares
                  : null;

              // Append today's live price to the green market-value line
              List<FlSpot>? effectiveMarketValueData;
              if (isLive && !_showShares && _marketValueHistory != null) {
                effectiveMarketValueData = [..._marketValueHistory!];
                if (livePrice != null && currentShares > 0) {
                  final now = DateTime.now();
                  final todayMs = DateTime(now.year, now.month, now.day)
                      .millisecondsSinceEpoch
                      .toDouble();
                  final todayValue = livePrice * currentShares;
                  if (effectiveMarketValueData.isNotEmpty &&
                      effectiveMarketValueData.last.x == todayMs) {
                    effectiveMarketValueData.last = FlSpot(todayMs, todayValue);
                  } else {
                    effectiveMarketValueData.add(FlSpot(todayMs, todayValue));
                  }
                }
              }

              if (isLive && !_livePulseController.isAnimating) {
                _livePulseController.repeat(reverse: true);
              } else if (!isLive && _livePulseController.isAnimating) {
                _livePulseController.stop();
                _livePulseController.value = 0.0;
              }

              final unrealizedProfit = isLive && livePrice != null
                  ? (livePrice - data.asset.netCostBasis) * currentShares
                  : null;

              return Stack(
                children: [
                  buildAuroraLayer(context),
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

                        AnimatedBuilder(
                          animation: _livePulseAnimation,
                          builder: (context, _) {
                            final showLivePulse = isLive && !_showShares;
                            final pulseColor = showLivePulse
                                ? Color.lerp(
                                    AppColors.green.withValues(alpha: 0.5),
                                    AppColors.green,
                                    _livePulseAnimation.value,
                                  )
                                : null;
                            return AnalysisLineChartSection(
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
                              liveOverrideValue: !_showShares ? liveValue : null,
                              marketValueData: effectiveMarketValueData,
                              valueLabelStyle: pulseColor != null
                                  ? TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: pulseColor,
                                    )
                                  : null,
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
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        SectionTitle(title: 'Trading stats', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                        StatTile(label: 'Buys', value: data.buys.toString()),
                        StatTile(label: 'Sells', value: data.sells.toString()),
                        StatTile(label: 'Total profit', value: formatCurrency(data.totalProfit)),
                        if (unrealizedProfit != null)
                          StatTile(
                            label: 'Total unrealized P&L',
                            value: formatCurrency(unrealizedProfit),
                            valueStyle: const TextStyle(
                              color: AppColors.green,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
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
                          _buildAccountHoldingsSection(data, isLive, livePrice, l10n),
                      ],
                    ),
                  ),
                  buildLiquidGlassAppBar(
                    context,
                    title: Text(data.asset.name),
                    actions: const [LiveToggleButton()],
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildAccountHoldingsSection(
    AssetAnalysisDetailsData data,
    bool isLive,
    double? livePrice,
    AppLocalizations l10n,
  ) {
    if (_showShares) {
      return AllocationBreakdownSection(
        items: data.accountHoldings
            .map((h) => AllocationItem(label: h.label, value: h.shares))
            .toList(),
        title: l10n.investments,
        valueFormatter: (value) => value.toStringAsFixed(4),
      );
    }

    if (isLive && livePrice != null) {
      return AllocationBreakdownSection(
        items: data.accountHoldings
            .map((h) => AllocationItem(
                  label: h.label,
                  value: h.shares * livePrice,
                ))
            .toList(),
        title: l10n.investments,
        valueColor: AppColors.green,
      );
    }

    return AllocationBreakdownSection(
      items: data.accountHoldings
          .map((h) => AllocationItem(label: h.label, value: h.value))
          .toList(),
      title: l10n.investments,
    );
  }
}
