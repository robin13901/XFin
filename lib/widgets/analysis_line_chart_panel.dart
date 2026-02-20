import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../app_theme.dart';
import '../utils/format.dart';
import '../utils/indicator_calculator.dart';

class AnalysisLineChartPanel extends StatelessWidget {
  final List<FlSpot> allData;
  final double baselineValue;
  final String selectedRange;
  final ValueChanged<String> onRangeSelected;
  final LineBarSpot? touchedSpot;
  final ValueChanged<LineBarSpot?> onTouchedSpotChanged;
  final bool showSma;
  final bool showEma;
  final bool showBb;
  final ValueChanged<bool> onShowSmaChanged;
  final ValueChanged<bool> onShowEmaChanged;
  final ValueChanged<bool> onShowBbChanged;
  final ValueChanged<int>? onChartPointerDelta;
  final String Function(double) valueFormatter;
  final Color? mainLineColor;

  const AnalysisLineChartPanel({
    super.key,
    required this.allData,
    required this.baselineValue,
    required this.selectedRange,
    required this.onRangeSelected,
    required this.touchedSpot,
    required this.onTouchedSpotChanged,
    required this.showSma,
    required this.showEma,
    required this.showBb,
    required this.onShowSmaChanged,
    required this.onShowEmaChanged,
    required this.onShowBbChanged,
    required this.valueFormatter,
    this.onChartPointerDelta,
    this.mainLineColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dataSets = {
      '1W': allData.length > 7 ? allData.sublist(allData.length - 7) : allData,
      '1M': allData.length > 30 ? allData.sublist(allData.length - 30) : allData,
      '1J': allData.length > 365 ? allData.sublist(allData.length - 365) : allData,
      'MAX': allData,
    };
    final currentData = dataSets[selectedRange] ?? allData;

    double balanceToShow;
    double profit;
    double profitPercent;
    String dateText;

    if (touchedSpot == null) {
      balanceToShow = currentData.isNotEmpty ? currentData.last.y : 0;
      if (currentData.length < allData.length) {
        profit = currentData.last.y - currentData.first.y;
        profitPercent = currentData.first.y != 0 ? profit / currentData.first.y : 0;
      } else {
        profit = currentData.last.y - baselineValue;
        profitPercent = baselineValue != 0 ? profit / baselineValue : 0;
      }
      switch (selectedRange) {
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
      balanceToShow = touchedSpot!.y;
      final spotIndex = currentData.indexWhere((spot) => spot.x == touchedSpot!.x);
      if (spotIndex > 0) {
        final previousSpot = currentData[spotIndex - 1];
        profit = touchedSpot!.y - previousSpot.y;
        profitPercent = previousSpot.y != 0 ? profit / previousSpot.y : 0;
      } else {
        profit = currentData.first.y - baselineValue;
        profitPercent = baselineValue != 0 ? profit / baselineValue : 0;
      }
      dateText = DateFormat('dd.MM.yyyy').format(DateTime.fromMillisecondsSinceEpoch(touchedSpot!.x.toInt()));
    }

    final isProfit = profit >= 0;
    final profitColor = isProfit ? AppColors.green : AppColors.red;

    final lineBarsData = <LineChartBarData>[
      LineChartBarData(
        spots: currentData,
        barWidth: 3,
        color: mainLineColor ?? (isDark ? Colors.white : Colors.black),
        dotData: const FlDotData(show: false),
      ),
    ];

    final firstDateInRange = currentData.isNotEmpty ? currentData.first.x : 0;
    if (showSma) {
      lineBarsData.add(LineChartBarData(
        spots: IndicatorCalculator.calculateSma(allData, 30).where((spot) => spot.x >= firstDateInRange).toList(),
        isCurved: true,
        barWidth: 2,
        color: Colors.orange,
        dotData: const FlDotData(show: false),
      ));
    }
    if (showEma) {
      lineBarsData.add(LineChartBarData(
        spots: IndicatorCalculator.calculateEma(allData, 30).where((spot) => spot.x >= firstDateInRange).toList(),
        isCurved: true,
        barWidth: 2,
        color: Colors.purple,
        dotData: const FlDotData(show: false),
      ));
    }
    if (showBb) {
      lineBarsData.addAll(IndicatorCalculator.calculateBb(allData, 20)
          .map((data) => data.copyWith(spots: data.spots.where((spot) => spot.x >= firstDateInRange).toList())));
    }

    double overallMinY = currentData.map((e) => e.y).reduce(min);
    double overallMaxY = currentData.map((e) => e.y).reduce(max);
    for (final barData in lineBarsData) {
      if (barData.spots.isEmpty) continue;
      overallMinY = min(overallMinY, barData.spots.map((e) => e.y).reduce(min));
      overallMaxY = max(overallMaxY, barData.spots.map((e) => e.y).reduce(max));
    }
    final padding = (overallMaxY - overallMinY) * 0.05;

    return Column(
      children: [
        Text(valueFormatter(balanceToShow), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(isProfit ? Icons.arrow_upward : Icons.arrow_downward, color: profitColor, size: 16),
                const SizedBox(width: 4),
                Text('${valueFormatter(profit)} (${formatPercent(profitPercent)})', style: TextStyle(color: profitColor, fontSize: 16)),
              ],
            ),
            Text(dateText, style: const TextStyle(fontSize: 16)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: ['1W', '1M', '1J', 'MAX'].map((range) {
            final selected = selectedRange == range;
            return TextButton(
              onPressed: () => onRangeSelected(range),
              style: TextButton.styleFrom(
                backgroundColor: selected ? Theme.of(context).colorScheme.secondary : Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: Text(
                range,
                style: TextStyle(
                  color: selected ? (isDark ? Colors.black : Colors.white) : Theme.of(context).textTheme.bodyLarge?.color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        Listener(
          onPointerDown: (_) => onChartPointerDelta?.call(1),
          onPointerUp: (_) => onChartPointerDelta?.call(-1),
          onPointerCancel: (_) => onChartPointerDelta?.call(-1),
          child: SizedBox(
            height: 400,
            child: LineChart(
              LineChartData(
                minY: overallMinY - padding,
                maxY: overallMaxY + padding,
                lineBarsData: lineBarsData,
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 38,
                      getTitlesWidget: (value, meta) {
                        if ((value - meta.min).abs() < 0.001 || (value - meta.max).abs() < 0.001) {
                          return const SizedBox.shrink();
                        }
                        final text = value >= 1000000
                            ? '${(value / 1000000).toStringAsFixed(0)}m'
                            : value >= 1000
                                ? '${(value / 1000).toStringAsFixed(2)}k'
                                : value.toStringAsFixed(0);
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
                          if ((value - meta.min).abs() < 0.001) return const SizedBox.shrink();
                        } else {
                          if ((value - meta.min).abs() < 0.001 || (value - meta.max).abs() < 0.001) {
                            return const SizedBox.shrink();
                          }
                        }
                        final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                        final text = switch (selectedRange) {
                          '1W' => DateFormat.E('de_DE').format(date),
                          '1M' => DateFormat.d('de_DE').format(date),
                          '1J' => DateFormat.MMM('de_DE').format(date),
                          'MAX' => DateFormat.yMMM('de_DE').format(date),
                          _ => '',
                        };
                        return SideTitleWidget(axisSide: meta.axisSide, child: Text(text, style: const TextStyle(fontSize: 12)));
                      },
                      interval: _bottomTitleInterval(currentData, selectedRange),
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: false,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => const FlLine(color: Colors.grey, strokeWidth: 0.5),
                  getDrawingVerticalLine: (value) => const FlLine(color: Colors.grey, strokeWidth: 0.5),
                ),
                borderData: FlBorderData(show: false, border: Border.all(color: Colors.grey, width: 1)),
                lineTouchData: LineTouchData(
                  touchCallback: (event, touchResponse) {
                    if (event is FlPanEndEvent || event is FlLongPressEnd || event is FlTapUpEvent) {
                      onTouchedSpotChanged(null);
                    } else if (touchResponse != null && touchResponse.lineBarSpots != null && touchResponse.lineBarSpots!.isNotEmpty) {
                      onTouchedSpotChanged(touchResponse.lineBarSpots![0]);
                    }
                  },
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (spots) => spots
                        .map((barSpot) => LineTooltipItem(valueFormatter(barSpot.y), const TextStyle(color: Colors.white)))
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
            Row(children: [
              Checkbox(value: showSma, activeColor: Colors.orange, onChanged: (value) => onShowSmaChanged(value ?? false)),
              Text('30-SMA', style: TextStyle(color: showSma ? Colors.orange : (isDark ? Colors.white : Colors.black))),
            ]),
            Row(children: [
              Checkbox(value: showEma, activeColor: Colors.purple, onChanged: (value) => onShowEmaChanged(value ?? false)),
              Text('30-EMA', style: TextStyle(color: showEma ? Colors.purple : (isDark ? Colors.white : Colors.black))),
            ]),
            Row(children: [
              Checkbox(value: showBb, activeColor: Colors.blue, onChanged: (value) => onShowBbChanged(value ?? false)),
              Text('20-BB', style: TextStyle(color: showBb ? Colors.blue : (isDark ? Colors.white : Colors.black))),
            ]),
          ],
        ),
      ],
    );
  }

  double _bottomTitleInterval(List<FlSpot> data, String range) {
    if (data.isEmpty) return 1;
    final first = DateTime.fromMillisecondsSinceEpoch(data.first.x.toInt());
    final last = DateTime.fromMillisecondsSinceEpoch(data.last.x.toInt());
    final difference = last.difference(first);
    return switch (range) {
      '1W' => const Duration(days: 1).inMilliseconds.toDouble(),
      '1M' => const Duration(days: 5).inMilliseconds.toDouble(),
      '1J' => const Duration(days: 30).inMilliseconds.toDouble(),
      'MAX' => Duration(days: (difference.inDays / 4).round().clamp(1, 365)).inMilliseconds.toDouble(),
      _ => const Duration(days: 1).inMilliseconds.toDouble(),
    };
  }
}
