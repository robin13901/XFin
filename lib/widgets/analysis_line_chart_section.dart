import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../app_theme.dart';
import '../providers/theme_provider.dart';
import '../utils/format.dart';
import '../utils/indicator_calculator.dart';

typedef ValueFormatter = String Function(double value);

class AnalysisLineChartSection extends StatelessWidget {
  final List<FlSpot> allData;
  final double startValue;
  final String selectedRange;
  final ValueChanged<String> onRangeSelected;
  final bool showSma;
  final bool showEma;
  final bool showBb;
  final ValueChanged<bool> onShowSmaChanged;
  final ValueChanged<bool> onShowEmaChanged;
  final ValueChanged<bool> onShowBbChanged;
  final LineBarSpot? touchedSpot;
  final ValueChanged<LineBarSpot?> onTouchedSpotChanged;
  final VoidCallback onPointerDown;
  final VoidCallback onPointerUpOrCancel;
  final ValueFormatter valueFormatter;
  final String Function(String range) rangeTextBuilder;

  const AnalysisLineChartSection({
    super.key,
    required this.allData,
    required this.startValue,
    required this.selectedRange,
    required this.onRangeSelected,
    required this.showSma,
    required this.showEma,
    required this.showBb,
    required this.onShowSmaChanged,
    required this.onShowEmaChanged,
    required this.onShowBbChanged,
    required this.touchedSpot,
    required this.onTouchedSpotChanged,
    required this.onPointerDown,
    required this.onPointerUpOrCancel,
    required this.valueFormatter,
    required this.rangeTextBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeProvider.isDark();
    final dataSets = <String, List<FlSpot>>{
      '1W': allData.length > 7 ? allData.sublist(allData.length - 7) : allData,
      '1M': allData.length > 30 ? allData.sublist(allData.length - 30) : allData,
      '1J': allData.length > 365 ? allData.sublist(allData.length - 365) : allData,
      'MAX': allData,
    };
    final currentData = dataSets[selectedRange] ?? allData;

    double totalToShow;
    double profit;
    double profitPercent;
    String dateText;

    if (touchedSpot == null) {
      totalToShow = currentData.isNotEmpty ? currentData.last.y : 0;
      if (currentData.length < allData.length) {
        profit = currentData.last.y - currentData.first.y;
        profitPercent = currentData.first.y != 0 ? (profit / currentData.first.y) : 0;
      } else if (currentData.length == allData.length) {
        profit = currentData.last.y - startValue;
        profitPercent = startValue != 0 ? (profit / startValue) : 0;
      } else {
        profit = 0;
        profitPercent = 0;
      }
      dateText = rangeTextBuilder(selectedRange);
    } else {
      totalToShow = touchedSpot!.y;
      final spotIndex = currentData.indexWhere((spot) => spot.x == touchedSpot!.x);

      if (spotIndex > 0) {
        final previousSpot = currentData[spotIndex - 1];
        profit = touchedSpot!.y - previousSpot.y;
        profitPercent = previousSpot.y != 0 ? (profit / previousSpot.y) : 0;
      } else if (currentData.length == allData.length) {
        profit = currentData.first.y - startValue;
        profitPercent = startValue != 0 ? (profit / startValue) : 0;
      } else {
        profit = 0;
        profitPercent = 0;
      }

      dateText = DateFormat('dd.MM.yyyy').format(
        DateTime.fromMillisecondsSinceEpoch(touchedSpot!.x.toInt()),
      );
    }

    final isProfit = profit >= 0;
    final profitColor = isProfit ? AppColors.green : AppColors.red;

    final lineBarsData = <LineChartBarData>[
      LineChartBarData(
        spots: currentData,
        barWidth: 3,
        color: isDark ? Colors.white : Colors.black,
        dotData: const FlDotData(show: false),
      ),
    ];

    final firstDateInRange = currentData.isNotEmpty ? currentData.first.x : 0;

    if (showSma) {
      final smaData = IndicatorCalculator.calculateSma(allData, 30);
      lineBarsData.add(LineChartBarData(
        spots: smaData.where((spot) => spot.x >= firstDateInRange).toList(),
        isCurved: true,
        barWidth: 2,
        color: Colors.orange,
        dotData: const FlDotData(show: false),
      ));
    }

    if (showEma) {
      final emaData = IndicatorCalculator.calculateEma(allData, 30);
      lineBarsData.add(LineChartBarData(
        spots: emaData.where((spot) => spot.x >= firstDateInRange).toList(),
        isCurved: true,
        barWidth: 2,
        color: Colors.purple,
        dotData: const FlDotData(show: false),
      ));
    }

    if (showBb) {
      final bbData = IndicatorCalculator.calculateBb(allData, 20);
      lineBarsData.addAll(
        bbData.map(
          (data) => data.copyWith(
            spots: data.spots.where((spot) => spot.x >= firstDateInRange).toList(),
          ),
        ),
      );
    }

    double overallMinY = currentData.map((e) => e.y).reduce(min);
    double overallMaxY = currentData.map((e) => e.y).reduce(max);

    for (final barData in lineBarsData) {
      if (barData.spots.isNotEmpty) {
        overallMinY = min(overallMinY, barData.spots.map((e) => e.y).reduce(min));
        overallMaxY = max(overallMaxY, barData.spots.map((e) => e.y).reduce(max));
      }
    }

    final padding = (overallMaxY - overallMinY) * 0.05;
    final minY = overallMinY - padding;
    final maxY = overallMaxY + padding;

    return Column(
      children: [
        Text(
          valueFormatter(totalToShow),
          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  isProfit ? Icons.arrow_upward : Icons.arrow_downward,
                  color: profitColor,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  '${valueFormatter(profit)} (${formatPercent(profitPercent)})',
                  style: TextStyle(color: profitColor, fontSize: 16),
                ),
              ],
            ),
            Text(dateText, style: const TextStyle(fontSize: 16)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: ['1W', '1M', '1J', 'MAX'].map((range) {
            return TextButton(
              onPressed: () => onRangeSelected(range),
              style: TextButton.styleFrom(
                backgroundColor: selectedRange == range
                    ? Theme.of(context).colorScheme.secondary
                    : Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: Text(
                range,
                style: TextStyle(
                  color: selectedRange == range
                      ? isDark
                          ? Colors.black
                          : Colors.white
                      : Theme.of(context).textTheme.bodyLarge?.color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        Listener(
          onPointerDown: (_) => onPointerDown(),
          onPointerUp: (_) => onPointerUpOrCancel(),
          onPointerCancel: (_) => onPointerUpOrCancel(),
          child: SizedBox(
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
                        if ((value - meta.min).abs() < 0.001 ||
                            (value - meta.max).abs() < 0.001) {
                          return const SizedBox.shrink();
                        }
                        String text;
                        if (value >= 1000000) {
                          text = '${(value / 1000000).toStringAsFixed(0)}m';
                        } else if (value >= 1000) {
                          text = '${(value / 1000).toStringAsFixed(2)}k';
                        } else {
                          text = value.toStringAsFixed(0);
                        }
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          space: 10,
                          child: Text(text, style: const TextStyle(fontSize: 8)),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (selectedRange == '1W') {
                          if ((value - meta.min).abs() < 0.001) {
                            return const SizedBox.shrink();
                          }
                        } else {
                          if ((value - meta.min).abs() < 0.001 ||
                              (value - meta.max).abs() < 0.001) {
                            return const SizedBox.shrink();
                          }
                        }
                        final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                        String text;
                        switch (selectedRange) {
                          case '1W':
                            text = DateFormat.E('de_DE').format(date);
                            break;
                          case '1M':
                            text = DateFormat.d('de_DE').format(date);
                            break;
                          case '1J':
                            text = DateFormat.MMM('de_DE').format(date);
                            break;
                          case 'MAX':
                            text = DateFormat.yMMM('de_DE').format(date);
                            break;
                          default:
                            text = '';
                        }
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: Text(text, style: const TextStyle(fontSize: 12)),
                        );
                      },
                      interval: _getBottomTitleInterval(currentData),
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: false,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) =>
                      const FlLine(color: Colors.grey, strokeWidth: 0.5),
                  getDrawingVerticalLine: (value) =>
                      const FlLine(color: Colors.grey, strokeWidth: 0.5),
                ),
                borderData: FlBorderData(
                  show: false,
                  border: Border.all(color: Colors.grey, width: 1),
                ),
                lineTouchData: LineTouchData(
                  touchCallback: (event, touchResponse) {
                    if (event is FlPanEndEvent || event is FlLongPressEnd || event is FlTapUpEvent) {
                      onTouchedSpotChanged(null);
                    } else if (touchResponse != null &&
                        touchResponse.lineBarSpots != null &&
                        touchResponse.lineBarSpots!.isNotEmpty) {
                      onTouchedSpotChanged(touchResponse.lineBarSpots![0]);
                    }
                  },
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedBarSpots) => touchedBarSpots
                        .map((barSpot) => LineTooltipItem(
                              valueFormatter(barSpot.y),
                              const TextStyle(color: Colors.white),
                            ))
                        .toList(),
                  ),
                  handleBuiltInTouches: true,
                ),
                clipData: const FlClipData.all(),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Row(
              children: [
                Checkbox(
                  value: showSma,
                  activeColor: Colors.orange,
                  onChanged: (value) => onShowSmaChanged(value!),
                ),
                Text(
                  '30-SMA',
                  style: TextStyle(
                    color: showSma
                        ? Colors.orange
                        : isDark
                            ? Colors.white
                            : Colors.black,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Checkbox(
                  value: showEma,
                  activeColor: Colors.purple,
                  onChanged: (value) => onShowEmaChanged(value!),
                ),
                Text(
                  '30-EMA',
                  style: TextStyle(
                    color: showEma
                        ? Colors.purple
                        : isDark
                            ? Colors.white
                            : Colors.black,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Checkbox(
                  value: showBb,
                  activeColor: Colors.blue,
                  onChanged: (value) => onShowBbChanged(value!),
                ),
                Text(
                  '20-BB',
                  style: TextStyle(
                    color: showBb
                        ? Colors.blue
                        : isDark
                            ? Colors.white
                            : Colors.black,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  double _getBottomTitleInterval(List<FlSpot> spots) {
    if (spots.length <= 1) return 1;

    final start = DateTime.fromMillisecondsSinceEpoch(spots.first.x.toInt());
    final end = DateTime.fromMillisecondsSinceEpoch(spots.last.x.toInt());
    final totalDays = max(1, end.difference(start).inDays);

    switch (selectedRange) {
      case '1W':
        return const Duration(days: 1).inMilliseconds.toDouble();
      case '1M':
        return const Duration(days: 7).inMilliseconds.toDouble();
      case '1J':
        return const Duration(days: 30).inMilliseconds.toDouble();
      case 'MAX':
        const monthDays = 30;
        const targetTicks = 6;
        final stepDays = max(monthDays, (totalDays / targetTicks).round());
        return Duration(days: stepDays).inMilliseconds.toDouble();
      default:
        return const Duration(days: 1).inMilliseconds.toDouble();
    }
  }
}
