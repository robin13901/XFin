import 'dart:async';
import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_theme.dart';
import '../database/app_database.dart';
import '../providers/database_provider.dart';
import '../providers/live_price_provider.dart';
import '../providers/privacy_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/format.dart';
import '../widgets/analysis_line_chart_section.dart';
import '../widgets/aurora_background.dart';
import '../widgets/category_widgets.dart';
import '../widgets/common_widgets.dart';
import '../widgets/inflow_outflow_toggle.dart';
import '../widgets/liquid_glass_widgets.dart';
import '../widgets/live_toggle_button.dart';
import '../widgets/summary_row.dart';
import 'category_detail_screen.dart';

// A data class to hold all asynchronous results needed by AnalysisScreen
class AnalysisData {
  final List<FlSpot> balanceHistory;
  final List<FlSpot> marketValueHistory;
  final double sumOfInitialBalances;
  final double currentMonthInflows;
  final double currentMonthOutflows;
  final double currentMonthProfit;
  final double averageMonthlyInflows;
  final double averageMonthlyOutflows;
  final double averageMonthlyProfit;
  final Map<String, double> currentMonthCategoryInflows;
  final Map<String, double> currentMonthCategoryOutflows;
  final Map<int, double> assetShares;
  final Map<int, double> assetValues;
  final Map<int, double> latestPricePerAsset;

  AnalysisData({
    required this.balanceHistory,
    required this.marketValueHistory,
    required this.sumOfInitialBalances,
    required this.currentMonthInflows,
    required this.currentMonthOutflows,
    required this.currentMonthProfit,
    required this.averageMonthlyInflows,
    required this.averageMonthlyOutflows,
    required this.averageMonthlyProfit,
    required this.currentMonthCategoryInflows,
    required this.currentMonthCategoryOutflows,
    required this.assetShares,
    required this.assetValues,
    required this.latestPricePerAsset,
  });
}

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  late AppDatabase db;
  String _selectedRange = '1W';
  bool _showSma = false;
  bool _showSma200 = false;
  bool _showEma = false;
  bool _showBb = false;
  bool _showInflows = true;
  bool _showAllCategories = false;
  int _chartPointerCount = 0;

  final ScrollController _controller = ScrollController();

  LineBarSpot? _touchedSpot;
  late Future<AnalysisData> _analysisDataFuture;
  StreamSubscription<dynamic>? _tableWatcher;
  LivePriceProvider? _liveProvider;
  DatabaseProvider? _dbProvider;

  @override
  void initState() {
    super.initState();
    _dbProvider = context.read<DatabaseProvider>();
    db = _dbProvider!.db;
    _dbProvider!.addListener(_onDbChanged);
    _liveProvider = context.read<LivePriceProvider>();
    _liveProvider!.addListener(_onLiveChanged);
    _fetchAnalysisData();
    _startTableWatch();
  }

  void _startTableWatch() {
    _tableWatcher?.cancel();
    _tableWatcher = db.tableUpdates().listen((_) {
      if (mounted && !(_liveProvider?.isSyncing ?? false)) {
        _fetchAnalysisData();
      }
    });
  }

  bool _lastLiveState = false;
  bool _lastSyncingState = false;

  void _onLiveChanged() {
    final isLive = _liveProvider?.isLive ?? false;
    final isSyncing = _liveProvider?.isSyncing ?? false;

    if (isLive != _lastLiveState) {
      _lastLiveState = isLive;
      if (mounted && !isSyncing) _fetchAnalysisData();
    }

    if (_lastSyncingState && !isSyncing) {
      if (mounted) _fetchAnalysisData();
    }
    _lastSyncingState = isSyncing;
  }

  void _onDbChanged() {
    final newDb = _dbProvider!.db;
    if (identical(newDb, db)) return;
    setState(() {
      db = newDb;
      _fetchAnalysisData();
      _startTableWatch();
    });
  }

  @override
  void dispose() {
    _tableWatcher?.cancel();
    _dbProvider?.removeListener(_onDbChanged);
    _liveProvider?.removeListener(_onLiveChanged);
    try {
      context.read<DatabaseProvider>().removeListener(_onDbChanged);
    } catch (_) {}
    _controller.dispose();
    super.dispose();
  }

  void _fetchAnalysisData() {
    final now = DateTime.now();

    final Future<List<FlSpot>> balanceHistoryFuture =
        db.analysisDao.getBalanceHistory();
    final Future<List<FlSpot>> marketValueHistoryFuture =
        db.analysisDao.getMarketValueHistory();
    final Future<double> sumOfInitialBalancesFuture =
        db.accountsDao.getSumOfInitialBalances();
    final Future<double> currentMonthInflowsFuture =
        db.analysisDao.getTotalInflowsForMonth(now);
    final Future<double> currentMonthOutflowsFuture =
        db.analysisDao.getTotalOutflowsForMonth(now);
    final Future<double> currentMonthProfitFuture =
        db.analysisDao.getProfitAndLossForMonth(now);
    final Future<double> averageMonthlyInflowsFuture =
        db.analysisDao.getMonthlyInflows();
    final Future<double> averageMonthlyOutflowsFuture =
        db.analysisDao.getMonthlyOutflows();
    final Future<double> averageMonthlyProfitFuture =
        db.analysisDao.getMonthlyProfitAndLoss();
    final Future<Map<String, double>> currentMonthCategoryInflowsFuture =
        db.analysisDao.getMonthlyCategoryInflows();
    final Future<Map<String, double>> currentMonthCategoryOutflowsFuture =
        db.analysisDao.getMonthlyCategoryOutflows();
    final Future<Map<int, double>> assetSharesFuture =
        db.assetsDao.getAllAssets().then((assets) {
      final map = <int, double>{};
      for (final a in assets) {
        if (a.shares > 0) map[a.id] = a.shares;
      }
      return map;
    });
    final Future<Map<int, double>> assetValuesFuture =
        db.assetsDao.getAllAssets().then((assets) {
      final map = <int, double>{};
      for (final a in assets) {
        map[a.id] = a.value;
      }
      return map;
    });
    final Future<Map<int, double>> latestPricePerAssetFuture =
        db.assetPricesDao.getLatestPricePerAsset();

    // Always assign the future inside setState so FutureBuilder reacts.
    setState(() {
      _analysisDataFuture = Future.wait([
        balanceHistoryFuture,
        marketValueHistoryFuture,
        sumOfInitialBalancesFuture,
        currentMonthInflowsFuture,
        currentMonthOutflowsFuture,
        currentMonthProfitFuture,
        averageMonthlyInflowsFuture,
        averageMonthlyOutflowsFuture,
        averageMonthlyProfitFuture,
        currentMonthCategoryInflowsFuture,
        currentMonthCategoryOutflowsFuture,
        assetSharesFuture,
        assetValuesFuture,
        latestPricePerAssetFuture,
      ]).then((results) {
        return AnalysisData(
          balanceHistory: results[0] as List<FlSpot>,
          marketValueHistory: results[1] as List<FlSpot>,
          sumOfInitialBalances: results[2] as double,
          currentMonthInflows: results[3] as double,
          currentMonthOutflows: results[4] as double,
          currentMonthProfit: results[5] as double,
          averageMonthlyInflows: results[6] as double,
          averageMonthlyOutflows: results[7] as double,
          averageMonthlyProfit: results[8] as double,
          currentMonthCategoryInflows: results[9] as Map<String, double>,
          currentMonthCategoryOutflows: results[10] as Map<String, double>,
          assetShares: results[11] as Map<int, double>,
          assetValues: results[12] as Map<int, double>,
          latestPricePerAsset: results[13] as Map<int, double>,
        );
      });
    });
  }

  void _onRangeSelected(String range) {
    setState(() {
      _selectedRange = range;
      _touchedSpot = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final showAurora = context.watch<ThemeProvider>().isAurora;

    return Scaffold(
      backgroundColor: showAurora ? Colors.transparent : null,
      body: Stack(
        children: [
          buildAuroraLayer(context),
          FutureBuilder<AnalysisData>(
            future: _analysisDataFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              } else if (!snapshot.hasData ||
                  snapshot.data!.balanceHistory.isEmpty) {
                return const Center(child: Text('No data available.'));
              }

              final analysisData = snapshot.data!;
              final allData = analysisData.balanceHistory;
              return SingleChildScrollView(
            controller: _controller,
            physics: _chartPointerCount > 0
                ? const NeverScrollableScrollPhysics()
                : null,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                showAurora ? 10 : 8,
                MediaQuery.of(context).padding.top + kToolbarHeight + 12,
                showAurora ? 10 : 8,
                16,
              ),
              child: Column(
                children: [
                  // ── Chart ──
                  _wrapCard(
                    showAurora: showAurora,
                    padding: const EdgeInsets.all(16.0),
                    children: [
                      Consumer<LivePriceProvider>(
                        builder: (context, liveProvider, _) {
                          final isLive = liveProvider.isLive &&
                              liveProvider.livePrices.isNotEmpty;
                          double? liveTotal;
                          if (isLive &&
                              analysisData.marketValueHistory.isNotEmpty) {
                            final baseValue =
                                analysisData.marketValueHistory.last.y;
                            final shares = analysisData.assetShares;
                            final latestPrices =
                                analysisData.latestPricePerAsset;

                            double liveDelta = 0;
                            for (final entry
                                in liveProvider.livePrices.entries) {
                              final s = shares[entry.key] ?? 0;
                              if (s <= 0) continue;
                              final stored =
                                  latestPrices[entry.key] ?? 0;
                              liveDelta += s * (entry.value - stored);
                            }
                            liveTotal = baseValue + liveDelta;
                          }

                          // Green market-value line with today's live data point
                          List<FlSpot>? greenLine;
                          if (isLive &&
                              analysisData.marketValueHistory.isNotEmpty) {
                            greenLine = [...analysisData.marketValueHistory];
                            if (liveTotal != null) {
                              final now = DateTime.now();
                              final todayMs = DateTime(
                                      now.year, now.month, now.day)
                                  .millisecondsSinceEpoch
                                  .toDouble();
                              if (greenLine.last.x == todayMs) {
                                greenLine.last = FlSpot(todayMs, liveTotal);
                              } else {
                                greenLine.add(FlSpot(todayMs, liveTotal));
                              }
                            }
                          }

                          return AnalysisLineChartSection(
                        allData: allData,
                        startValue: analysisData.sumOfInitialBalances,
                        liveOverrideValue: liveTotal,
                        marketValueData: greenLine,
                        isLive: isLive,
                        selectedRange: _selectedRange,
                        onRangeSelected: _onRangeSelected,
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
                        onPointerUpOrCancel: () {
                          setState(() {
                            _chartPointerCount =
                                max(0, _chartPointerCount - 1);
                          });
                        },
                        valueFormatter: formatCurrency,
                        hidden: context.watch<PrivacyProvider>().hidden,
                      );
                        },
                      ),
                    ],
                  ),

                  SizedBox(height: showAurora ? 14 : 8),

                  // ── Monthly Summary ──
                  _wrapCard(
                    showAurora: showAurora,
                    padding: const EdgeInsets.all(16.0),
                    children: [
                      _buildMonthlySummary(analysisData),
                    ],
                  ),

                  SizedBox(height: showAurora ? 14 : 8),

                  // ── Categories ──
                  _wrapCard(
                    showAurora: showAurora,
                    padding: const EdgeInsets.all(16.0),
                    children: [
                      _buildInflowOutflowSwitch(),
                      const SizedBox(height: 32),
                      _buildCategoryPieChart(analysisData),
                      const SizedBox(height: 32),
                      _buildCategoryList(analysisData),
                    ],
                  ),

                  const SizedBox(height: 64),
                ],
              ),
            ),
          );
        },
      ),
          buildLiquidGlassAppBar(
            context,
            title: const Text('Analyse'),
            showBackButton: false,
            actions: [
              if (context.watch<PrivacyProvider>().enabled)
                _buildPrivacyToggle(context),
              const LiveToggleButton(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlySummary(AnalysisData analysisData) {
    final hidden = context.watch<PrivacyProvider>().hidden;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(title: 'Monatliche Übersicht'),
        const SizedBox(height: 8),
        SummaryRow(
          label: 'Einnahmen Aktueller Monat:',
          value: formatCurrency(analysisData.currentMonthInflows),
          valueColor: AppColors.green,
          hidden: hidden,
        ),
        SummaryRow(
          label: 'Ausgaben Aktueller Monat:',
          value: formatCurrency(analysisData.currentMonthOutflows),
          valueColor: AppColors.red,
          hidden: hidden,
        ),
        SummaryRow(
          label: 'Gewinn Aktueller Monat:',
          value: formatCurrency(analysisData.currentMonthProfit),
          valueColor: analysisData.currentMonthProfit >= 0
              ? AppColors.green
              : AppColors.red,
          hidden: hidden,
        ),
        const SizedBox(height: 8),
        const Divider(color: Colors.grey),
        const SizedBox(height: 8),
        SummaryRow(
          label: 'Ø Monatliche Einnahmen:',
          value: formatCurrency(analysisData.averageMonthlyInflows),
          valueColor: AppColors.green,
          hidden: hidden,
        ),
        SummaryRow(
          label: 'Ø Monatliche Ausgaben:',
          value: formatCurrency(analysisData.averageMonthlyOutflows),
          valueColor: AppColors.red,
          hidden: hidden,
        ),
        SummaryRow(
          label: 'Ø Monatlicher Gewinn:',
          value: formatCurrency(analysisData.averageMonthlyProfit),
          valueColor: analysisData.averageMonthlyProfit >= 0
              ? AppColors.green
              : AppColors.red,
          hidden: hidden,
        ),
      ],
    );
  }

  Widget _buildPrivacyToggle(BuildContext context) {
    final privacy = context.watch<PrivacyProvider>();
    return IconButton(
      icon: Icon(privacy.hidden ? Icons.visibility_off : Icons.visibility),
      tooltip: privacy.hidden ? 'Werte anzeigen' : 'Werte ausblenden',
      onPressed: () => privacy.toggleHidden(),
    );
  }

  void scrollToBottom() {
    _controller.animateTo(
      _controller.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  Widget _buildInflowOutflowSwitch() {
    return InflowOutflowToggle(
      showInflows: _showInflows,
      inflowLabel: 'Einnahmen',
      outflowLabel: 'Ausgaben',
      onChanged: (showInflows) {
        setState(() {
          _showInflows = showInflows;
          _showAllCategories = false;
        });
      },
    );
  }

  Widget _buildCategoryPieChart(AnalysisData analysisData) {
    final categories = _showInflows
        ? analysisData.currentMonthCategoryInflows
        : analysisData.currentMonthCategoryOutflows;

    final displayData = calculateCategoryData(
      categories: categories,
      showAllCategories: _showAllCategories,
    );

    return CategoryPieChart(
      data: displayData,
      onCategoryTap: _openCategoryDetail,
      showInflows: _showInflows,
    );
  }

  Widget _buildCategoryList(AnalysisData analysisData) {
    final categories = _showInflows
        ? analysisData.currentMonthCategoryInflows
        : analysisData.currentMonthCategoryOutflows;

    final displayData = calculateCategoryData(
      categories: categories,
      showAllCategories: _showAllCategories,
    );

    return CategoryList(
      data: displayData,
      noCategoriesMessage: 'Keine Daten für diese Kategorie verfügbar.',
      showAllLabel: 'Alle anzeigen',
      showLessLabel: 'Weniger anzeigen',
      onCategoryTap: _openCategoryDetail,
      showInflows: _showInflows,
      hidden: context.watch<PrivacyProvider>().hidden,
      onShowAllChanged: (showAll) {
        setState(() {
          _showAllCategories = showAll;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            scrollToBottom();
          });
        });
      },
    );
  }

  void _openCategoryDetail(String category) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) =>
            CategoryDetailScreen(category: category),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  /// Wraps [children] in a lightweight glass-style card when aurora is active,
  /// otherwise returns a plain [Padding] with a [Column].
  ///
  /// Uses a simple [DecoratedBox] instead of [LiquidGlassLayer] because the
  /// analysis screen contains heavy repaint content (line chart, pie chart)
  /// that would cause severe jank with real-time shader blur layers.
  Widget _wrapCard({
    required bool showAurora,
    required List<Widget> children,
    EdgeInsetsGeometry padding = EdgeInsets.zero,
  }) {
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
    if (!showAurora) {
      return Padding(padding: padding, child: content);
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0x33000000),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Padding(padding: padding, child: content),
    );
  }
}