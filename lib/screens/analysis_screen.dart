import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'dart:math';

import '../app_theme.dart';
import '../database/app_database.dart';
import '../utils/indicator_calculator.dart';

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
  String _selectedRange = '1W';
  bool _showSma = false;
  bool _showEma = false;
  bool _showBb = false;
  bool _showInflows = true;
  bool _showAllCategories = false;

  final ScrollController _controller = ScrollController();

  LineBarSpot? _touchedSpot;
  late Future<AnalysisData> _analysisDataFuture;

  @override
  void initState() {
    super.initState();
    _fetchAnalysisData();
  }

  void _fetchAnalysisData() {
    AppDatabase db = Provider.of<AppDatabase>(context, listen: false);
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
  }

  void _onRangeSelected(String range) {
    setState(() {
      _selectedRange = range;
      // Untouch the spot when range changes to reset the header
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
          final sumOfInitialBalances = analysisData.sumOfInitialBalances;

          final Map<String, List<FlSpot>> dataSets = {
            '1W': allData.length > 7
                ? allData.sublist(allData.length - 7)
                : allData,
            '1M': allData.length > 30
                ? allData.sublist(allData.length - 30)
                : allData,
            '1J': allData.length > 365
                ? allData.sublist(allData.length - 365)
                : allData,
            'MAX': allData,
          };

          final currencyFormat =
              NumberFormat.currency(locale: 'de_DE', symbol: '€');
          final List<FlSpot> currentData = dataSets[_selectedRange]!;

          double balanceToShow;
          double profit;
          double profitPercent;
          String dateText;

          if (_touchedSpot == null) {
            balanceToShow = currentData.isNotEmpty ? currentData.last.y : 0;
            if (currentData.length < allData.length) {
              profit = currentData.last.y - currentData.first.y;
              profitPercent = (currentData.first.y != 0)
                  ? (profit / currentData.first.y)
                  : 0;
            } else if (currentData.length == allData.length) {
              profit = currentData.last.y - sumOfInitialBalances;
              profitPercent = (sumOfInitialBalances != 0)
                  ? (profit / sumOfInitialBalances)
                  : 0;
            } else {
              profit = 0;
              profitPercent = 0;
            }

            switch (_selectedRange) {
              case '1W':
                dateText = 'Seit 7 Tagen';
                break;
              case '1M':
                dateText = 'Seit 1 Monat';
                break;
              case '1J':
                dateText = 'Seit 1 Jahr';
                break;
              case 'MAX':
                dateText = 'Insgesamt';
                break;
              default:
                dateText = '';
            }
          } else {
            balanceToShow = _touchedSpot!.y;
            final spotIndex =
                currentData.indexWhere((spot) => spot.x == _touchedSpot!.x);

            if (spotIndex > 0) {
              final previousSpot = currentData[spotIndex - 1];
              profit = _touchedSpot!.y - previousSpot.y;
              profitPercent =
                  (previousSpot.y != 0) ? (profit / previousSpot.y) : 0;
            } else if (currentData.length == allData.length) {
              profit = currentData.first.y - sumOfInitialBalances;
              profitPercent = (sumOfInitialBalances != 0)
                  ? (profit / sumOfInitialBalances)
                  : 0;
            } else {
              profit = 0;
              profitPercent = 0;
            }
            dateText = DateFormat('dd.MM.yyyy').format(
                DateTime.fromMillisecondsSinceEpoch(_touchedSpot!.x.toInt()));
          }

          final bool isProfit = profit >= 0;
          final Color profitColor = isProfit ? AppColors.green : AppColors.red;

          List<LineChartBarData> lineBarsData = [
            LineChartBarData(
              spots: currentData,
              barWidth: 3,
              color: Colors.white,
              dotData: const FlDotData(show: false),
            ),
          ];

          final firstDateInRange =
              currentData.isNotEmpty ? currentData.first.x : 0;

          if (_showSma) {
            final smaData = IndicatorCalculator.calculateSma(allData, 30);
            lineBarsData.add(LineChartBarData(
              spots:
                  smaData.where((spot) => spot.x >= firstDateInRange).toList(),
              isCurved: true,
              barWidth: 2,
              color: Colors.orange,
              dotData: const FlDotData(show: false),
            ));
          }

          if (_showEma) {
            final emaData = IndicatorCalculator.calculateEma(allData, 30);
            lineBarsData.add(LineChartBarData(
              spots:
                  emaData.where((spot) => spot.x >= firstDateInRange).toList(),
              isCurved: true,
              barWidth: 2,
              color: Colors.purple,
              dotData: const FlDotData(show: false),
            ));
          }

          if (_showBb) {
            final bbData = IndicatorCalculator.calculateBb(allData, 20);
            lineBarsData.addAll(bbData.map((data) => data.copyWith(
                spots: data.spots
                    .where((spot) => spot.x >= firstDateInRange)
                    .toList())));
          }

          double overallMinY = currentData.map((e) => e.y).reduce(min);
          double overallMaxY = currentData.map((e) => e.y).reduce(max);

          for (final barData in lineBarsData) {
            if (barData.spots.isNotEmpty) {
              overallMinY =
                  min(overallMinY, barData.spots.map((e) => e.y).reduce(min));
              overallMaxY =
                  max(overallMaxY, barData.spots.map((e) => e.y).reduce(max));
            }
          }
          double padding = (overallMaxY - overallMinY) * 0.05;
          double minY = overallMinY - padding;
          double maxY = overallMaxY + padding;

          return SingleChildScrollView(
            controller: _controller,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 56, 8, 16),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      children: [
                        // Total balance
                        Text(
                          currencyFormat.format(balanceToShow),
                          style: const TextStyle(
                              fontSize: 32, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                    isProfit
                                        ? Icons.arrow_upward
                                        : Icons.arrow_downward,
                                    color: profitColor,
                                    size: 16),
                                const SizedBox(width: 4),
                                Text(
                                    '${currencyFormat.format(profit)} (${NumberFormat.percentPattern().format(profitPercent)})',
                                    style: TextStyle(
                                        color: profitColor, fontSize: 16)),
                              ],
                            ),
                            Text(dateText,
                                style: const TextStyle(fontSize: 16)),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Range selection
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: ['1W', '1M', '1J', 'MAX'].map((range) {
                            return TextButton(
                              onPressed: () => _onRangeSelected(range),
                              child: Text(range,
                                  style: TextStyle(
                                      color: _selectedRange == range
                                          ? Theme.of(context)
                                              .colorScheme
                                              .secondary
                                          : Theme.of(context)
                                              .textTheme
                                              .bodyLarge
                                              ?.color)),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),

                        // Chart
                        SizedBox(
                          height: 400,
                          child: LineChart(
                            LineChartData(
                              minY: minY,
                              maxY: maxY,
                              lineBarsData: lineBarsData,
                              titlesData: FlTitlesData(
                                leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 38,
                                        getTitlesWidget: (value, meta) {
                                          // Hide first and last labels
                                          if ((value - meta.min).abs() <
                                                  0.001 ||
                                              (value - meta.max).abs() <
                                                  0.001) {
                                            return const SizedBox.shrink();
                                          }
                                          String text;
                                          if (value >= 1000000) {
                                            text =
                                                '${(value / 1000000).toStringAsFixed(0)}m';
                                          } else if (value >= 1000) {
                                            text =
                                                '${(value / 1000).toStringAsFixed(2)}k';
                                          } else {
                                            text = value.toStringAsFixed(0);
                                          }
                                          return SideTitleWidget(
                                            axisSide: meta.axisSide,
                                            space: 10,
                                            child: Text(text,
                                                style: const TextStyle(
                                                    fontSize: 8)),
                                          );
                                        })),
                                bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                        showTitles: true,
                                        getTitlesWidget: (value, meta) {
                                          // Hide first and last labels
                                          if (_selectedRange == '1W') {
                                            if ((value - meta.min).abs() <
                                                0.001) {
                                              return const SizedBox.shrink();
                                            }
                                          } else {
                                            if ((value - meta.min).abs() <
                                                    0.001 ||
                                                (value - meta.max).abs() <
                                                    0.001) {
                                              return const SizedBox.shrink();
                                            }
                                          }
                                          final date = DateTime
                                              .fromMillisecondsSinceEpoch(
                                                  value.toInt());
                                          String text;
                                          switch (_selectedRange) {
                                            case '1W':
                                              text = DateFormat.E('de_DE')
                                                  .format(date);
                                              break;
                                            case '1M':
                                              text = DateFormat.d('de_DE')
                                                  .format(date);
                                              break;
                                            case '1J':
                                              text = DateFormat.MMM('de_DE')
                                                  .format(date);
                                              break;
                                            case 'MAX':
                                              text = DateFormat.yMMM('de_DE')
                                                  .format(date);
                                              break;
                                            default:
                                              text = '';
                                          }
                                          return SideTitleWidget(
                                              axisSide: meta.axisSide,
                                              child: Text(text,
                                                  style: const TextStyle(
                                                      fontSize: 12)));
                                        },
                                        interval: _getBottomTitleInterval(
                                            currentData))),
                                topTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false)),
                                rightTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false)),
                              ),
                              gridData: FlGridData(
                                show: false,
                                drawVerticalLine: false,
                                getDrawingHorizontalLine: (value) =>
                                    const FlLine(
                                        color: Colors.grey, strokeWidth: 0.5),
                                getDrawingVerticalLine: (value) => const FlLine(
                                    color: Colors.grey, strokeWidth: 0.5),
                              ),
                              borderData: FlBorderData(
                                  show: false,
                                  border:
                                      Border.all(color: Colors.grey, width: 1)),
                              lineTouchData: LineTouchData(
                                touchCallback: (FlTouchEvent event,
                                    LineTouchResponse? touchResponse) {
                                  if (event is FlPanEndEvent ||
                                      event is FlLongPressEnd ||
                                      event is FlTapUpEvent) {
                                    setState(() => _touchedSpot = null);
                                  } else if (touchResponse != null &&
                                      touchResponse.lineBarSpots != null &&
                                      touchResponse.lineBarSpots!.isNotEmpty) {
                                    setState(() => _touchedSpot =
                                        touchResponse.lineBarSpots![0]);
                                  }
                                },
                                touchTooltipData: LineTouchTooltipData(
                                  getTooltipItems: (touchedBarSpots) =>
                                      touchedBarSpots
                                          .map((barSpot) => LineTooltipItem(
                                              currencyFormat.format(barSpot.y),
                                              const TextStyle(
                                                  color: Colors.white)))
                                          .toList(),
                                ),
                                handleBuiltInTouches: true,
                              ),
                              clipData: const FlClipData.all(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Indicators
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Row(children: [
                              Checkbox(
                                  value: _showSma,
                                  onChanged: (value) =>
                                      setState(() => _showSma = value!)),
                              const Text('30-SMA')
                            ]),
                            Row(children: [
                              Checkbox(
                                  value: _showEma,
                                  onChanged: (value) =>
                                      setState(() => _showEma = value!)),
                              const Text('30-EMA')
                            ]),
                            Row(children: [
                              Checkbox(
                                  value: _showBb,
                                  onChanged: (value) =>
                                      setState(() => _showBb = value!)),
                              const Text('20-BB')
                            ]),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: _buildMonthlySummary(analysisData, currencyFormat),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      children: [
                        _buildInflowOutflowSwitch(),
                        const SizedBox(height: 8),
                        _buildCategoryList(analysisData, currencyFormat),
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

  Widget _buildMonthlySummary(
      AnalysisData analysisData, NumberFormat currencyFormat) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Monatliche Übersicht',
            style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        _buildSummaryRow('Einnahmen Aktueller Monat:',
            analysisData.currentMonthInflows, currencyFormat, AppColors.green),
        _buildSummaryRow('Ausgaben Aktueller Monat:',
            analysisData.currentMonthOutflows, currencyFormat, AppColors.red),
        _buildSummaryRow(
            'Gewinn Aktueller Monat:',
            analysisData.currentMonthProfit,
            currencyFormat,
            analysisData.currentMonthProfit >= 0 ? AppColors.green : AppColors.red),
        const SizedBox(height: 8),
        const Divider(color: Colors.grey),
        const SizedBox(height: 8),
        _buildSummaryRow('Ø Monatliche Einnahmen:',
            analysisData.averageMonthlyInflows, currencyFormat, AppColors.green),
        _buildSummaryRow('Ø Monatliche Ausgaben:',
            analysisData.averageMonthlyOutflows, currencyFormat, AppColors.red),
        _buildSummaryRow(
            'Ø Monatlicher Gewinn:',
            analysisData.averageMonthlyProfit,
            currencyFormat,
            analysisData.averageMonthlyProfit >= 0 ? AppColors.green : AppColors.red),
      ],
    );
  }

  Widget _buildSummaryRow(
      String title, double value, NumberFormat currencyFormat, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title),
          Text(
            currencyFormat.format(value),
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

  Widget _buildCategoryList(
      AnalysisData analysisData, NumberFormat currencyFormat) {
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
        categoryWidgets.add(_buildCategoryRow(
            entry.key, entry.value, percentage, currencyFormat));
      }
    }

    if (hasOther) {
      final otherPercentage = (aggregatedOtherAmount.abs() / totalAmount) * 100;
      categoryWidgets.add(_buildCategoryRow(
          '...', aggregatedOtherAmount, otherPercentage, currencyFormat));
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

  Widget _buildCategoryRow(String category, double amount, double percentage,
      NumberFormat currencyFormat) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(category),
          Row(
            children: [
              Text(currencyFormat.format(amount)),
              const SizedBox(width: 8),
              Text('${percentage.toStringAsFixed(1)}%',
                  style: TextStyle(color: Theme.of(context).hintColor)),
            ],
          ),
        ],
      ),
    );
  }

  double _getBottomTitleInterval(List<FlSpot> data) {
    if (data.isEmpty) return 1;
    final first = DateTime.fromMillisecondsSinceEpoch(data.first.x.toInt());
    final last = DateTime.fromMillisecondsSinceEpoch(data.last.x.toInt());
    final difference = last.difference(first);

    switch (_selectedRange) {
      case '1W':
        return const Duration(days: 1).inMilliseconds.toDouble();
      case '1M':
        return const Duration(days: 5).inMilliseconds.toDouble();
      case '1J':
        return const Duration(days: 30).inMilliseconds.toDouble();
      case 'MAX':
        return Duration(days: (difference.inDays / 4).round().clamp(1, 365))
            .inMilliseconds
            .toDouble(); // Show fewer labels for MAX
      default:
        return const Duration(days: 1).inMilliseconds.toDouble();
    }
  }
}
