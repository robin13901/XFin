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

const double _cardGap = 8;

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

  List<FlSpot>? _marketValueHistory;

  @override
  void initState() {
    super.initState();
    _future = _load();
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
          // IMPORTANT: keep buildAuroraLayer and buildLiquidGlassAppBar OUTSIDE
          // any LivePriceProvider subscription. Both are GPU-expensive
          // (gradient + BackdropFilter) and would cause whole-screen flicker
          // if rebuilt at the live-price tick rate.
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
                    Consumer<LivePriceProvider>(
                      builder: (context, liveProvider, _) {
                        final isLive =
                            liveProvider.isLive && liveProvider.isConnected;
                        final livePrice =
                            liveProvider.getLivePrice(widget.assetId);
                        final currentShares = data.asset.shares;
                        final liveValue = isLive && livePrice != null
                            ? livePrice * currentShares
                            : null;

                        // Append today's live price to the green market-value
                        // line. Only this list mutates per tick; the white
                        // (sharesHistory/valueHistory) line stays stable.
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
                              effectiveMarketValueData.last =
                                  FlSpot(todayMs, todayValue);
                            } else {
                              effectiveMarketValueData
                                  .add(FlSpot(todayMs, todayValue));
                            }
                          }
                        }

                        return AnalysisLineChartSection(
                          allData: _showShares
                              ? data.sharesHistory
                              : data.valueHistory,
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
                          onShowSmaChanged: (value) =>
                              setState(() => _showSma = value),
                          onShowSma200Changed: (value) =>
                              setState(() => _showSma200 = value),
                          onShowEmaChanged: (value) =>
                              setState(() => _showEma = value),
                          onShowBbChanged: (value) =>
                              setState(() => _showBb = value),
                          touchedSpot: _touchedSpot,
                          onTouchedSpotChanged: (spot) =>
                              setState(() => _touchedSpot = spot),
                          onPointerDown: () =>
                              setState(() => _chartPointerCount += 1),
                          onPointerUpOrCancel: () => setState(() =>
                              _chartPointerCount =
                                  max(0, _chartPointerCount - 1)),
                          valueFormatter: _showShares
                              ? (value) => value.toStringAsFixed(4)
                              : formatCurrency,
                          valueLabel: l10n.total,
                          liveOverrideValue: !_showShares ? liveValue : null,
                          marketValueData: effectiveMarketValueData,
                          isLive: isLive,
                          valueLabelStyle: isLive && !_showShares
                              ? const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.green,
                                )
                              : null,
                          chartTransitionDuration:
                              isLive ? Duration.zero : null,
                          topRight: Wrap(
                            alignment: WrapAlignment.end,
                            spacing: 8,
                            children: [
                              ChoiceChip(
                                label: Text(l10n.value),
                                selected: !_showShares,
                                showCheckmark: false,
                                onSelected: (_) =>
                                    setState(() => _showShares = false),
                              ),
                              ChoiceChip(
                                label: Text(l10n.shares),
                                selected: _showShares,
                                showCheckmark: false,
                                onSelected: (_) =>
                                    setState(() => _showShares = true),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    SectionTitle(
                        title: l10n.tradingStats,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Consumer<LivePriceProvider>(
                      builder: (context, liveProvider, _) {
                        final isLive =
                            liveProvider.isLive && liveProvider.isConnected;
                        final livePrice =
                            liveProvider.getLivePrice(widget.assetId);
                        final unrealizedProfit = isLive && livePrice != null
                            ? (livePrice - data.asset.netCostBasis) *
                                data.asset.shares
                            : null;
                        return _buildTradingStatsCards(
                            data, unrealizedProfit, l10n);
                      },
                    ),
                    const SizedBox(height: 12),
                    SectionTitle(
                        title: l10n.generalStats,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    _buildGeneralStatsCards(data, l10n),
                    const SizedBox(height: 12),
                    SectionTitle(
                        title: l10n.heldOnAccounts,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 32),
                    if (data.accountHoldings.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(l10n.noAccountPositions),
                      )
                    else
                      Consumer<LivePriceProvider>(
                        builder: (context, liveProvider, _) {
                          final isLive =
                              liveProvider.isLive && liveProvider.isConnected;
                          final livePrice =
                              liveProvider.getLivePrice(widget.assetId);
                          return _buildAccountHoldingsSection(
                              data, isLive, livePrice, l10n);
                        },
                      ),
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
      ),
    );
  }

  Widget _statCard(String label, String value, double width, {Color? valueColor}) {
    final isDark = ThemeProvider.isDark();
    return SizedBox(
      width: width,
      child: FrostedGlassCard(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: valueColor ?? (isDark ? Colors.white : Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTradingStatsCards(
    AssetAnalysisDetailsData data,
    double? unrealizedProfit,
    AppLocalizations l10n,
  ) {
    return LayoutBuilder(builder: (context, constraints) {
      final cardWidth = (constraints.maxWidth - _cardGap) / 2;
      return Wrap(
        spacing: _cardGap,
        runSpacing: _cardGap,
        children: [
          _statCard(l10n.buys, data.buys.toString(), cardWidth),
          _statCard(l10n.sells, data.sells.toString(), cardWidth),
          _statCard(l10n.totalProfit, formatCurrency(data.totalProfit), cardWidth,
              valueColor: data.totalProfit >= 0 ? AppColors.green : Colors.red),
          if (unrealizedProfit != null)
            _statCard(l10n.totalUnrealizedPnl, formatCurrency(unrealizedProfit), cardWidth,
                valueColor: unrealizedProfit >= 0 ? AppColors.green : Colors.red),
          _statCard(l10n.totalFees, formatCurrency(data.totalFees), cardWidth),
          _statCard(l10n.tradeVolume, formatCurrency(data.tradeVolume), cardWidth),
        ],
      );
    });
  }

  Widget _buildGeneralStatsCards(AssetAnalysisDetailsData data, AppLocalizations l10n) {
    return LayoutBuilder(builder: (context, constraints) {
      final cardWidth = (constraints.maxWidth - _cardGap) / 2;
      return Wrap(
        spacing: _cardGap,
        runSpacing: _cardGap,
        children: [
          _statCard(l10n.bookingInflows, formatCurrency(data.bookingInflows), cardWidth),
          _statCard(l10n.bookingOutflows, formatCurrency(data.bookingOutflows), cardWidth),
          _statCard(l10n.transfers, data.transferCount.toString(), cardWidth),
          _statCard(l10n.transferVolume, formatCurrency(data.transferVolume), cardWidth),
          _statCard(l10n.eventsPerMonth, data.eventFrequency.toStringAsFixed(1), cardWidth),
        ],
      );
    });
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
        title: l10n.accounts,
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
        title: l10n.accounts,
        valueColor: AppColors.green,
      );
    }

    return AllocationBreakdownSection(
      items: data.accountHoldings
          .map((h) => AllocationItem(label: h.label, value: h.value))
          .toList(),
      title: l10n.accounts,
    );
  }
}
