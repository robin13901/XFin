import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';

import '../app_theme.dart';
import '../database/app_database.dart';
import '../providers/database_provider.dart';
import '../utils/format.dart';
import '../widgets/analysis_line_chart_section.dart';
import '../widgets/category_widgets.dart';
import '../widgets/common_widgets.dart';
import '../widgets/inflow_outflow_toggle.dart';
import '../widgets/summary_row.dart';

// A data class to hold all asynchronous results needed by AnalysisScreen
class AnalysisData {
  final List<FlSpot> balanceHistory;
  final double sumOfInitialBalances;
  final double currentMonthInflows;
  final double currentMonthOutflows;
  final double currentMonthProfit;
  final double averageMonthlyInflows;
  final double averageMonthlyOutflows;
  final double averageMonthlyProfit;
  final Map<String, double> currentMonthCategoryInflows;
  final Map<String, double> currentMonthCategoryOutflows;

  AnalysisData({
    required this.balanceHistory,
    required this.sumOfInitialBalances,
    required this.currentMonthInflows,
    required this.currentMonthOutflows,
    required this.currentMonthProfit,
    required this.averageMonthlyInflows,
    required this.averageMonthlyOutflows,
    required this.averageMonthlyProfit,
    required this.currentMonthCategoryInflows,
    required this.currentMonthCategoryOutflows,
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
  bool _showEma = false;
  bool _showBb = false;
  bool _showInflows = true;
  bool _showAllCategories = false;
  int _chartPointerCount = 0;

  final ScrollController _controller = ScrollController();

  LineBarSpot? _touchedSpot;
  late Future<AnalysisData> _analysisDataFuture;

  @override
  void initState() {
    super.initState();
    final dbProvider = context.read<DatabaseProvider>();
    db = dbProvider.db;
    dbProvider.addListener(_onDbChanged);
    _fetchAnalysisData();
  }

  void _onDbChanged() {
    final newDb = context.read<DatabaseProvider>().db;
    if (identical(newDb, db)) return;
    setState(() {
      db = newDb;
      _fetchAnalysisData();
    });
  }

  @override
  void dispose() {
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

    // Always assign the future inside setState so FutureBuilder reacts.
    setState(() {
      _analysisDataFuture = Future.wait([
        balanceHistoryFuture,
        sumOfInitialBalancesFuture,
        currentMonthInflowsFuture,
        currentMonthOutflowsFuture,
        currentMonthProfitFuture,
        averageMonthlyInflowsFuture,
        averageMonthlyOutflowsFuture,
        averageMonthlyProfitFuture,
        currentMonthCategoryInflowsFuture,
        currentMonthCategoryOutflowsFuture,
      ]).then((results) {
        return AnalysisData(
          balanceHistory: results[0] as List<FlSpot>,
          sumOfInitialBalances: results[1] as double,
          currentMonthInflows: results[2] as double,
          currentMonthOutflows: results[3] as double,
          currentMonthProfit: results[4] as double,
          averageMonthlyInflows: results[5] as double,
          averageMonthlyOutflows: results[6] as double,
          averageMonthlyProfit: results[7] as double,
          currentMonthCategoryInflows: results[8] as Map<String, double>,
          currentMonthCategoryOutflows: results[9] as Map<String, double>,
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
    return Scaffold(
      body: FutureBuilder<AnalysisData>(
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
              padding: const EdgeInsets.fromLTRB(8, 56, 8, 16),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: AnalysisLineChartSection(
                      allData: allData,
                      startValue: analysisData.sumOfInitialBalances,
                      selectedRange: _selectedRange,
                      onRangeSelected: _onRangeSelected,
                      showSma: _showSma,
                      showEma: _showEma,
                      showBb: _showBb,
                      onShowSmaChanged: (value) =>
                          setState(() => _showSma = value),
                      onShowEmaChanged: (value) =>
                          setState(() => _showEma = value),
                      onShowBbChanged: (value) => setState(() => _showBb = value),
                      touchedSpot: _touchedSpot,
                      onTouchedSpotChanged: (spot) =>
                          setState(() => _touchedSpot = spot),
                      onPointerDown: () => setState(() => _chartPointerCount += 1),
                      onPointerUpOrCancel: () {
                        setState(() {
                          _chartPointerCount = max(0, _chartPointerCount - 1);
                        });
                      },
                      valueFormatter: formatCurrency,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: _buildMonthlySummary(analysisData),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      children: [
                        _buildInflowOutflowSwitch(),
                        const SizedBox(height: 32),
                        _buildCategoryPieChart(analysisData),
                        const SizedBox(height: 32),
                        _buildCategoryList(analysisData),
                      ],
                    ),
                  ),
                  const SizedBox(height: 64),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMonthlySummary(AnalysisData analysisData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(title: 'Monatliche Übersicht'),
        const SizedBox(height: 8),
        SummaryRow(
          label: 'Einnahmen Aktueller Monat:',
          value: formatCurrency(analysisData.currentMonthInflows),
          valueColor: AppColors.green,
        ),
        SummaryRow(
          label: 'Ausgaben Aktueller Monat:',
          value: formatCurrency(analysisData.currentMonthOutflows),
          valueColor: AppColors.red,
        ),
        SummaryRow(
          label: 'Gewinn Aktueller Monat:',
          value: formatCurrency(analysisData.currentMonthProfit),
          valueColor: analysisData.currentMonthProfit >= 0
              ? AppColors.green
              : AppColors.red,
        ),
        const SizedBox(height: 8),
        const Divider(color: Colors.grey),
        const SizedBox(height: 8),
        SummaryRow(
          label: 'Ø Monatliche Einnahmen:',
          value: formatCurrency(analysisData.averageMonthlyInflows),
          valueColor: AppColors.green,
        ),
        SummaryRow(
          label: 'Ø Monatliche Ausgaben:',
          value: formatCurrency(analysisData.averageMonthlyOutflows),
          valueColor: AppColors.red,
        ),
        SummaryRow(
          label: 'Ø Monatlicher Gewinn:',
          value: formatCurrency(analysisData.averageMonthlyProfit),
          valueColor: analysisData.averageMonthlyProfit >= 0
              ? AppColors.green
              : AppColors.red,
        ),
      ],
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
          WidgetsBinding.instance.addPostFrameCallback((_) {
            scrollToBottom();
          });
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

    return CategoryPieChart(data: displayData);
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
}