import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xfin/l10n/app_localizations.dart';

import '../app_theme.dart';
import '../database/daos/accounts_dao.dart';
import '../database/tables.dart';
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
import 'asset_analysis_detail_screen.dart';

class AccountDetailScreen extends StatefulWidget {
  final int accountId;

  const AccountDetailScreen({super.key, required this.accountId});

  @override
  State<AccountDetailScreen> createState() => _AccountDetailScreenState();
}

class _AccountDetailScreenState extends State<AccountDetailScreen> {
  late Future<_LoadResult> _future;
  String _range = '1W';
  bool _showSma = false;
  bool _showSma200 = false;
  bool _showEma = false;
  bool _showBb = false;
  LineBarSpot? _touchedSpot;
  int _chartPointerCount = 0;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_LoadResult> _load() async {
    final db = context.read<DatabaseProvider>().db;
    final results = await Future.wait([
      db.accountsDao.getAccountDetails(widget.accountId),
      db.accountsDao.getMarketValueHistory(widget.accountId),
    ]);
    return _LoadResult(
      data: results[0] as AccountDetailsData,
      marketValueHistory: results[1] as List<FlSpot>,
    );
  }

  /// Compute live-adjusted aggregates without mutating [data].
  /// [data.balanceHistory] is left untouched so the chart's white line stays
  /// stable across price ticks; the live overlay line is built separately.
  _LiveSnapshot _computeLive(
      AccountDetailsData data, LivePriceProvider liveProvider) {
    final isLive = liveProvider.isLive && liveProvider.isConnected;
    if (!isLive) {
      return _LiveSnapshot(
        isLive: false,
        balance: data.account.balance,
        netChange: data.netChange,
        adjustedHoldings: data.assetHoldings,
        liveTotalDelta: 0.0,
      );
    }

    double totalDelta = 0.0;
    final adjustedHoldings = <AccountAssetHolding>[];

    for (final h in data.assetHoldings) {
      final livePrice = liveProvider.getLivePrice(h.assetId);
      if (livePrice != null && h.shares.abs() > 1e-9) {
        final storedPrice = h.value / h.shares;
        final delta = h.shares * (livePrice - storedPrice);
        totalDelta += delta;
        adjustedHoldings.add(AccountAssetHolding(
          label: h.label,
          value: h.value + delta,
          shares: h.shares,
          assetId: h.assetId,
        ));
      } else {
        adjustedHoldings.add(h);
      }
    }

    final liveBalance = data.account.balance + totalDelta;
    final liveNetChange = liveBalance - data.account.initialBalance;

    return _LiveSnapshot(
      isLive: true,
      balance: liveBalance,
      netChange: liveNetChange,
      adjustedHoldings: adjustedHoldings,
      liveTotalDelta: totalDelta,
    );
  }

  /// Builds the green market-value line shown alongside the white balance
  /// line. Historical points come from the precomputed market-value series
  /// (shares × historical price); when live is active, today's last point
  /// is overridden with the live total balance.
  List<FlSpot>? _buildMarketValueLine(
    _LoadResult result,
    _LiveSnapshot live,
  ) {
    final history = result.marketValueHistory;
    if (history.isEmpty) return null;

    final hasMeaningfulSpread = _diverges(history, result.data.balanceHistory);
    if (!live.isLive && !hasMeaningfulSpread) {
      // Cost basis ≈ market basis throughout (no historical price data) and
      // not live → drawing the line would just overlap the white one.
      return null;
    }

    if (!live.isLive) return history;

    final adjusted = List<FlSpot>.from(history);
    final now = DateTime.now();
    final todayMs = DateTime(now.year, now.month, now.day)
        .millisecondsSinceEpoch
        .toDouble();
    if (adjusted.isNotEmpty && adjusted.last.x == todayMs) {
      adjusted[adjusted.length - 1] = FlSpot(todayMs, live.balance);
    } else {
      adjusted.add(FlSpot(todayMs, live.balance));
    }
    return adjusted;
  }

  bool _diverges(List<FlSpot> a, List<FlSpot> b) {
    if (a.length != b.length) return true;
    for (var i = 0; i < a.length; i++) {
      if ((a[i].y - b[i].y).abs() > 1e-6) return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    AppLocalizations l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor:
          context.watch<ThemeProvider>().isAurora ? Colors.transparent : null,
      body: FutureBuilder<_LoadResult>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Center(child: Text(l10n.errorLoadingData));
          }
          final result = snapshot.data!;
          final data = result.data;
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
                  top: MediaQuery.of(context).padding.top +
                      kToolbarHeight +
                      12,
                  left: 12,
                  right: 12,
                  bottom: 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Consumer<LivePriceProvider>(
                      builder: (context, liveProvider, _) {
                        final live = _computeLive(data, liveProvider);
                        final marketValueLine =
                            _buildMarketValueLine(result, live);
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AnalysisLineChartSection(
                              allData: data.balanceHistory,
                              startValue: data.account.initialBalance,
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
                              liveOverrideValue:
                                  live.isLive ? live.balance : null,
                              marketValueData: marketValueLine,
                              isLive: live.isLive,
                              valueFormatter: formatCurrency,
                              valueLabel: l10n.total,
                              chartTransitionDuration:
                                  live.isLive ? Duration.zero : null,
                            ),
                            const SizedBox(height: 12),
                            SectionTitle(
                              title: l10n.accountInformation,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 12),
                            _buildInfoCards(data, l10n,
                                liveBalance: live.balance,
                                liveNetChange: live.netChange,
                                isLive: live.isLive),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    SectionTitle(
                      title: l10n.transactionStatistics,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    _buildStatCards(data, l10n),
                    const SizedBox(height: 20),
                    SectionTitle(
                      title: l10n.assetHoldings,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 32),
                    if (data.assetHoldings.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(l10n.noAssetHoldings),
                      )
                    else
                      Consumer<LivePriceProvider>(
                        builder: (context, liveProvider, _) {
                          final live = _computeLive(data, liveProvider);
                          return AllocationBreakdownSection(
                            items: live.adjustedHoldings
                                .map((h) => AllocationItem(
                                    label: h.label, value: h.value))
                                .toList(),
                            title: l10n.investments,
                            onItemTap: (item) {
                              final holding = data.assetHoldings
                                  .firstWhere((h) => h.label == item.label);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AssetAnalysisDetailScreen(
                                      assetId: holding.assetId),
                                ),
                              );
                            },
                          );
                        },
                      ),
                  ],
                ),
              ),
              buildLiquidGlassAppBar(context,
                  title: Text(data.account.name),
                  actions: const [LiveToggleButton()]),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInfoCards(
    AccountDetailsData data,
    AppLocalizations l10n, {
    required double liveBalance,
    required double liveNetChange,
    required bool isLive,
  }) {
    final isDark = ThemeProvider.isDark();
    const double gap = 8;

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - gap) / 2;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            _buildGlassCard(
              width: cardWidth,
              icon: Icons.account_balance_wallet,
              iconColor: Colors.blue,
              label: l10n.currentBalance,
              value: formatCurrency(liveBalance),
              valueColor: isLive ? AppColors.green : null,
              isDark: isDark,
            ),
            _buildGlassCard(
              width: cardWidth,
              icon: Icons.flag,
              iconColor: Colors.orange,
              label: l10n.initialBalance,
              value: formatCurrency(data.account.initialBalance),
              isDark: isDark,
            ),
            _buildGlassCard(
              width: cardWidth,
              icon: liveNetChange >= 0
                  ? Icons.trending_up
                  : Icons.trending_down,
              iconColor:
                  liveNetChange >= 0 ? AppColors.green : AppColors.red,
              label: l10n.netChange,
              value: formatCurrency(liveNetChange),
              valueColor:
                  liveNetChange >= 0 ? AppColors.green : AppColors.red,
              isDark: isDark,
            ),
            _buildGlassCard(
              width: cardWidth,
              icon: _getAccountTypeIcon(data.account.type),
              iconColor: Colors.purple,
              label: l10n.accountType,
              value: getAccountTypeName(l10n, data.account.type),
              isDark: isDark,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCards(AccountDetailsData data, AppLocalizations l10n) {
    final isDark = ThemeProvider.isDark();
    const double gap = 8;

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - gap) / 2;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            _buildGlassCard(
              width: cardWidth,
              icon: Icons.receipt_long,
              iconColor: Colors.blue,
              label: l10n.bookings,
              value: data.bookingCount.toString(),
              isDark: isDark,
            ),
            _buildGlassCard(
              width: cardWidth,
              icon: Icons.swap_horiz,
              iconColor: Colors.orange,
              label: l10n.transfers,
              value: data.transferCount.toString(),
              isDark: isDark,
            ),
            if (data.tradeCount > 0)
              _buildGlassCard(
                width: cardWidth,
                icon: Icons.candlestick_chart,
                iconColor: Colors.purple,
                label: l10n.trades,
                value: data.tradeCount.toString(),
                isDark: isDark,
              ),
            _buildGlassCard(
              width: cardWidth,
              icon: Icons.arrow_downward,
              iconColor: AppColors.green,
              label: l10n.totalInflows,
              value: formatCurrency(data.totalInflows),
              valueColor: AppColors.green,
              isDark: isDark,
            ),
            _buildGlassCard(
              width: cardWidth,
              icon: Icons.arrow_upward,
              iconColor: AppColors.red,
              label: l10n.totalOutflows,
              value: formatCurrency(data.totalOutflows),
              valueColor: AppColors.red,
              isDark: isDark,
            ),
            _buildGlassCard(
              width: cardWidth,
              icon: Icons.width_full_outlined,
              iconColor: Colors.indigoAccent,
              label: l10n.totalVolume,
              value: formatCurrency(data.totalVolume),
              isDark: isDark,
            ),
            _buildGlassCard(
              width: cardWidth,
              icon: Icons.calendar_month,
              iconColor: Colors.teal,
              label: l10n.eventsPerMonth,
              value: formatDecimal(data.eventFrequency),
              isDark: isDark,
            ),
          ],
        );
      },
    );
  }

  Widget _buildGlassCard({
    required double width,
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required bool isDark,
    Color? valueColor,
  }) {
    return SizedBox(
      width: width,
      child: FrostedGlassCard(
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ),
            ],
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

  IconData _getAccountTypeIcon(AccountTypes type) {
    switch (type) {
      case AccountTypes.cash:
        return Icons.payments;
      case AccountTypes.bankAccount:
        return Icons.account_balance;
      case AccountTypes.portfolio:
        return Icons.show_chart;
      case AccountTypes.cryptoWallet:
        return Icons.currency_bitcoin;
    }
  }
}

class _LiveSnapshot {
  final bool isLive;
  final double balance;
  final double netChange;
  final List<AccountAssetHolding> adjustedHoldings;
  final double liveTotalDelta;

  const _LiveSnapshot({
    required this.isLive,
    required this.balance,
    required this.netChange,
    required this.adjustedHoldings,
    required this.liveTotalDelta,
  });
}

class _LoadResult {
  final AccountDetailsData data;
  final List<FlSpot> marketValueHistory;

  const _LoadResult({
    required this.data,
    required this.marketValueHistory,
  });
}
