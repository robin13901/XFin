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
  late Future<AccountDetailsData> _future;
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

  Future<AccountDetailsData> _load() async {
    final db = context.read<DatabaseProvider>().db;
    return db.accountsDao.getAccountDetails(widget.accountId);
  }

  @override
  Widget build(BuildContext context) {
    AppLocalizations l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor:
          context.watch<ThemeProvider>().isAurora ? Colors.transparent : null,
      body: FutureBuilder<AccountDetailsData>(
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

              double liveBalance = data.account.balance;
              double liveNetChange = data.netChange;
              List<AccountAssetHolding> effectiveHoldings = data.assetHoldings;

              if (isLive) {
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

                liveBalance = data.account.balance + totalDelta;
                liveNetChange = liveBalance - data.account.initialBalance;
                effectiveHoldings = adjustedHoldings;
              }

              List<FlSpot> effectiveHistory = data.balanceHistory;
              if (isLive && liveBalance != data.account.balance) {
                effectiveHistory = [...data.balanceHistory];
                final now = DateTime.now();
                final todayMs = DateTime(now.year, now.month, now.day)
                    .millisecondsSinceEpoch
                    .toDouble();
                if (effectiveHistory.isNotEmpty &&
                    effectiveHistory.last.x == todayMs) {
                  effectiveHistory[effectiveHistory.length - 1] =
                      FlSpot(todayMs, liveBalance);
                } else {
                  effectiveHistory.add(FlSpot(todayMs, liveBalance));
                }
              }

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
                        AnalysisLineChartSection(
                          allData: effectiveHistory,
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
                          liveOverrideValue: isLive ? liveBalance : null,
                          isLive: isLive,
                          valueFormatter: formatCurrency,
                          valueLabel: l10n.total,
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
                            liveBalance: liveBalance,
                            liveNetChange: liveNetChange,
                            isLive: isLive),
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
                        if (effectiveHoldings.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(l10n.noAssetHoldings),
                          )
                        else
                          AllocationBreakdownSection(
                            items: effectiveHoldings
                                .map((h) =>
                                    AllocationItem(label: h.label, value: h.value))
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
