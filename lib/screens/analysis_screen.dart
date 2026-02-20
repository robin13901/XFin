import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';

import '../app_theme.dart';
import '../database/app_database.dart';
import '../providers/database_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/format.dart';
import '../widgets/analysis_line_chart_panel.dart';

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
          final isDark = ThemeProvider.isDark();

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
                    child: Column(
                      children: [
                        AnalysisLineChartPanel(
                          allData: allData,
                          baselineValue: analysisData.sumOfInitialBalances,
                          selectedRange: _selectedRange,
                          onRangeSelected: _onRangeSelected,
                          touchedSpot: _touchedSpot,
                          onTouchedSpotChanged: (spot) =>
                              setState(() => _touchedSpot = spot),
                          showSma: _showSma,
                          showEma: _showEma,
                          showBb: _showBb,
                          onShowSmaChanged: (value) =>
                              setState(() => _showSma = value),
                          onShowEmaChanged: (value) =>
                              setState(() => _showEma = value),
                          onShowBbChanged: (value) =>
                              setState(() => _showBb = value),
                          onChartPointerDelta: (delta) =>
                              setState(() => _chartPointerCount =
                                  max(0, _chartPointerCount + delta)),
                          valueFormatter: formatCurrency,
                          mainLineColor: isDark ? Colors.white : Colors.black,
                        ),
                      ],
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
                        const SizedBox(height: 8),
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
        Text('Monatliche Übersicht',
            style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        _buildSummaryRow('Einnahmen Aktueller Monat:',
            analysisData.currentMonthInflows, AppColors.green),
        _buildSummaryRow('Ausgaben Aktueller Monat:',
            analysisData.currentMonthOutflows, AppColors.red),
        _buildSummaryRow(
            'Gewinn Aktueller Monat:',
            analysisData.currentMonthProfit,
            analysisData.currentMonthProfit >= 0
                ? AppColors.green
                : AppColors.red),
        const SizedBox(height: 8),
        const Divider(color: Colors.grey),
        const SizedBox(height: 8),
        _buildSummaryRow('Ø Monatliche Einnahmen:',
            analysisData.averageMonthlyInflows, AppColors.green),
        _buildSummaryRow('Ø Monatliche Ausgaben:',
            analysisData.averageMonthlyOutflows, AppColors.red),
        _buildSummaryRow(
            'Ø Monatlicher Gewinn:',
            analysisData.averageMonthlyProfit,
            analysisData.averageMonthlyProfit >= 0
                ? AppColors.green
                : AppColors.red),
      ],
    );
  }

  Widget _buildSummaryRow(String title, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title),
          Text(
            formatCurrency(value),
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
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
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _showInflows = true;
                  _showAllCategories = false;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    scrollToBottom();
                  });
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _showInflows
                      ? AppColors.green.withValues(alpha: 0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    'Einnahmen',
                    style: TextStyle(
                      color: _showInflows
                          ? AppColors.green
                          : Theme.of(context).textTheme.bodyLarge?.color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _showInflows = false;
                  _showAllCategories = false;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    scrollToBottom();
                  });
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: !_showInflows
                      ? AppColors.red.withValues(alpha: 0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    'Ausgaben',
                    style: TextStyle(
                      color: !_showInflows
                          ? AppColors.red
                          : Theme.of(context).textTheme.bodyLarge?.color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryList(AnalysisData analysisData) {
    final Map<String, double> categories = _showInflows
        ? analysisData.currentMonthCategoryInflows
        : analysisData.currentMonthCategoryOutflows;

    final double totalAmount =
        categories.values.fold(0.0, (sum, item) => sum + item.abs());

    // Sort categories by absolute amount in descending order
    List<MapEntry<String, double>> sortedCategories = categories.entries
        .toList()
      ..sort((a, b) => b.value.abs().compareTo(a.value.abs()));

    List<Widget> categoryWidgets = [];
    double aggregatedOtherAmount = 0.0;
    bool hasOther = false;

    for (int i = 0; i < sortedCategories.length; i++) {
      final entry = sortedCategories[i];
      final percentage = (entry.value.abs() / totalAmount) * 100;

      if (!_showAllCategories &&
          percentage < 1.0 &&
          i < sortedCategories.length) {
        aggregatedOtherAmount += entry.value;
        hasOther = true;
      } else {
        categoryWidgets
            .add(_buildCategoryRow(entry.key, entry.value, percentage));
      }
    }

    if (hasOther) {
      final otherPercentage = (aggregatedOtherAmount.abs() / totalAmount) * 100;
      categoryWidgets.add(
          _buildCategoryRow('...', aggregatedOtherAmount, otherPercentage));
    }

    if (hasOther && !_showAllCategories) {
      categoryWidgets.add(
        TextButton(
          onPressed: () {
            setState(() {
              _showAllCategories = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                scrollToBottom();
              });
            });
          },
          child: const Text('Alle anzeigen'),
        ),
      );
    } else if (!hasOther && _showAllCategories) {
      categoryWidgets.add(
        TextButton(
          onPressed: () {
            setState(() {
              _showAllCategories = false;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                scrollToBottom();
              });
            });
          },
          child: const Text('Weniger anzeigen'),
        ),
      );
    }

    if (categories.isEmpty) {
      return const Center(
          child: Text('Keine Daten für diese Kategorie verfügbar.'));
    }

    return Column(children: categoryWidgets);
  }

  Widget _buildCategoryRow(String category, double amount, double percentage) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(category),
          Row(
            children: [
              Text(formatCurrency(amount)),
              const SizedBox(width: 8),
              Text('${percentage.toStringAsFixed(1)}%',
                  style: TextStyle(color: Theme.of(context).hintColor)),
            ],
          ),
        ],
      ),
    );
  }

}