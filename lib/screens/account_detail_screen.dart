import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xfin/l10n/app_localizations.dart';

import '../app_theme.dart';
import '../database/daos/accounts_dao.dart';
import '../database/tables.dart';
import '../providers/database_provider.dart';
import '../utils/format.dart';
import '../widgets/analysis_line_chart_section.dart';
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
                      showSma200: false,
                      showEma: _showEma,
                      showBb: _showBb,
                      showSma200Toggle: false,
                      onShowSmaChanged: (value) =>
                          setState(() => _showSma = value),
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
                    StatTile(
                      label: l10n.currentBalance,
                      value: formatCurrency(data.account.balance),
                    ),
                    StatTile(
                      label: l10n.initialBalance,
                      value: formatCurrency(data.account.initialBalance),
                    ),
                    StatTile(
                      label: l10n.netChange,
                      value: formatCurrency(data.netChange),
                      valueStyle: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: data.netChange >= 0 ? AppColors.green : AppColors.red,
                      ),
                    ),
                    StatTile(
                      label: l10n.accountType,
                      value: getAccountTypeName(l10n, data.account.type),
                    ),
                    const SizedBox(height: 12),
                    SectionTitle(
                      title: l10n.transactionStatistics,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    StatTile(
                      label: l10n.bookings,
                      value: data.bookingCount.toString(),
                    ),
                    StatTile(
                      label: l10n.transfers,
                      value: data.transferCount.toString(),
                    ),
                    if (data.account.type == AccountTypes.portfolio ||
                        data.account.type == AccountTypes.cryptoWallet)
                      StatTile(
                        label: l10n.trades,
                        value: data.tradeCount.toString(),
                      ),
                    StatTile(
                      label: l10n.totalInflows,
                      value: formatCurrency(data.totalInflows),
                    ),
                    StatTile(
                      label: l10n.totalOutflows,
                      value: formatCurrency(data.totalOutflows),
                    ),
                    StatTile(
                      label: l10n.eventsPerMonth,
                      value: data.eventFrequency.toStringAsFixed(1),
                    ),
                    const SizedBox(height: 12),
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
}
