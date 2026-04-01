import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xfin/l10n/app_localizations.dart';

import '../app_theme.dart';
import '../database/daos/accounts_dao.dart';
import '../database/tables.dart';
import '../providers/database_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/format.dart';
import '../widgets/analysis_line_chart_section.dart';
import '../widgets/aurora_background.dart';
import '../widgets/charts.dart';
import '../widgets/common_widgets.dart';
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
                      onPointerUpOrCancel: () => setState(
                          () => _chartPointerCount = max(0, _chartPointerCount - 1)),
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
                    // Design A: Card Grid for Account Information
                    DashboardCardGrid(
                      items: [
                        DashboardCardItem(
                          label: l10n.currentBalance,
                          value: formatCurrency(data.account.balance),
                          icon: Icons.account_balance_wallet,
                          iconColor: Colors.blue,
                        ),
                        DashboardCardItem(
                          label: l10n.initialBalance,
                          value: formatCurrency(data.account.initialBalance),
                          icon: Icons.flag,
                          iconColor: Colors.orange,
                        ),
                        DashboardCardItem(
                          label: l10n.netChange,
                          value: formatCurrency(data.netChange),
                          icon: data.netChange >= 0 ? Icons.trending_up : Icons.trending_down,
                          iconColor: data.netChange >= 0 ? AppColors.green : AppColors.red,
                          valueColor: data.netChange >= 0 ? AppColors.green : AppColors.red,
                        ),
                        DashboardCardItem(
                          label: l10n.accountType,
                          value: getAccountTypeName(l10n, data.account.type),
                          icon: _getAccountTypeIcon(data.account.type),
                          iconColor: Colors.purple,
                        ),
                      ],
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
                    // Design B: Stats List for Transaction Statistics
                    DashboardStatsList(
                      items: [
                        DashboardStatItem(
                          label: l10n.bookings,
                          value: data.bookingCount.toString(),
                          icon: Icons.receipt_long,
                          accentColor: Colors.blue,
                        ),
                        DashboardStatItem(
                          label: l10n.transfers,
                          value: data.transferCount.toString(),
                          icon: Icons.swap_horiz,
                          accentColor: Colors.orange,
                        ),
                        if (data.tradeCount > 0)
                          DashboardStatItem(
                            label: l10n.trades,
                            value: data.tradeCount.toString(),
                            icon: Icons.candlestick_chart,
                            accentColor: Colors.purple,
                          ),
                        DashboardStatItem(
                          label: l10n.totalInflows,
                          value: formatCurrency(data.totalInflows),
                          icon: Icons.arrow_downward,
                          accentColor: AppColors.green,
                          valueColor: AppColors.green,
                        ),
                        DashboardStatItem(
                          label: l10n.totalOutflows,
                          value: formatCurrency(data.totalOutflows),
                          icon: Icons.arrow_upward,
                          accentColor: AppColors.red,
                          valueColor: AppColors.red,
                        ),
                        DashboardStatItem(
                          label: l10n.totalVolume,
                          value: formatCurrency(data.totalVolume),
                          icon: Icons.width_full_outlined,
                          accentColor: Colors.indigoAccent,
                        ),
                        DashboardStatItem(
                          label: l10n.eventsPerMonth,
                          value: data.eventFrequency.toStringAsFixed(1),
                          icon: Icons.calendar_month,
                          accentColor: Colors.teal,
                        ),
                      ],
                    ),
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
                      AllocationBreakdownSection(
                        items: data.assetHoldings
                            .map((h) => AllocationItem(label: h.label, value: h.value))
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
              buildLiquidGlassAppBar(context, title: Text(data.account.name)),
            ],
          );
        },
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
