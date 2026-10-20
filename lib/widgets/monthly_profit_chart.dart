import 'dart:math';
import 'dart:ui';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../app_theme.dart';
import '../database/models/analysis_models.dart';
import '../providers/theme_provider.dart';
import '../utils/format.dart';

/// A compact line chart that visualizes the development of the monthly profit.
///
/// Mirrors the visual styling of [AnalysisLineChartSection] (same line, axes
/// and tooltip look) but is tailored to a monthly series: it drops the
/// day-oriented range buttons and SMA/EMA/BB indicators and instead offers a
/// toggle between the running (cumulative) average and the per-month profit.
class MonthlyProfitChart extends StatefulWidget {
  final List<MonthlyProfitPoint> points;
  final bool hidden;

  const MonthlyProfitChart({
    super.key,
    required this.points,
    this.hidden = false,
  });

  @override
  State<MonthlyProfitChart> createState() => _MonthlyProfitChartState();
}

class _MonthlyProfitChartState extends State<MonthlyProfitChart> {
  /// Whether the running cumulative average is shown (true) or the raw
  /// per-month profit (false).
  bool _showAverage = true;
  LineBarSpot? _touchedSpot;

  List<FlSpot> _toSpots(bool average) {
    return widget.points
        .map((point) => FlSpot(
              point.monthDate.millisecondsSinceEpoch.toDouble(),
              average ? point.runningAverage : point.profit,
            ))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeProvider.isDark();
    final currentData = _toSpots(_showAverage);

    final double valueToShow;
    final String dateText;
    if (_touchedSpot == null) {
      valueToShow = currentData.isNotEmpty ? currentData.last.y : 0;
      dateText = currentData.isNotEmpty
          ? DateFormat.yMMM('de_DE').format(
              DateTime.fromMillisecondsSinceEpoch(currentData.last.x.toInt()),
            )
          : '';
    } else {
      valueToShow = _touchedSpot!.y;
      dateText = DateFormat.yMMM('de_DE').format(
        DateTime.fromMillisecondsSinceEpoch(_touchedSpot!.x.toInt()),
      );
    }

    final valueColor = valueToShow >= 0 ? AppColors.green : AppColors.red;

    double overallMinY = currentData.map((e) => e.y).reduce(min);
    double overallMaxY = currentData.map((e) => e.y).reduce(max);
    var padding = (overallMaxY - overallMinY) * 0.05;
    // Guard against a flat line (single point or all-equal values), which would
    // otherwise collapse minY == maxY and break the chart.
    if (padding == 0) {
      padding = overallMaxY.abs() > 0 ? overallMaxY.abs() * 0.1 : 1;
    }
    final minY = overallMinY - padding;
    final maxY = overallMaxY + padding;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Monatlicher Gewinn',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _maybeBlur(
              child: Text(
                formatCurrency(valueToShow),
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: valueColor,
                ),
              ),
            ),
            Text(dateText, style: const TextStyle(fontSize: 16)),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 320,
          child: LineChart(
            duration: const Duration(milliseconds: 150),
            LineChartData(
              minY: minY,
              maxY: maxY,
              lineBarsData: [
                LineChartBarData(
                  spots: currentData,
                  barWidth: 3,
                  color: isDark ? Colors.white : Colors.black,
                  dotData: const FlDotData(show: false),
                ),
              ],
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: !widget.hidden,
                    reservedSize: 38,
                    getTitlesWidget: (value, meta) {
                      if ((value - meta.min).abs() < 0.001 ||
                          (value - meta.max).abs() < 0.001) {
                        return const SizedBox.shrink();
                      }
                      String text;
                      if (value.abs() >= 1000000) {
                        text = '${(value / 1000000).toStringAsFixed(0)}m';
                      } else if (value.abs() >= 1000) {
                        text = '${(value / 1000).toStringAsFixed(1)}k';
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
                    interval: _bottomTitleInterval(currentData),
                    getTitlesWidget: (value, meta) {
                      if ((value - meta.min).abs() < 0.001 ||
                          (value - meta.max).abs() < 0.001) {
                        return const SizedBox.shrink();
                      }
                      final date =
                          DateTime.fromMillisecondsSinceEpoch(value.toInt());
                      return SideTitleWidget(
                        axisSide: meta.axisSide,
                        child: Text(
                          DateFormat.yMMM('de_DE').format(date),
                          style: const TextStyle(fontSize: 10),
                        ),
                      );
                    },
                  ),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              lineTouchData: LineTouchData(
                touchCallback: (event, touchResponse) {
                  if (event is FlPanEndEvent ||
                      event is FlLongPressEnd ||
                      event is FlTapUpEvent) {
                    setState(() => _touchedSpot = null);
                  } else if (touchResponse != null &&
                      touchResponse.lineBarSpots != null &&
                      touchResponse.lineBarSpots!.isNotEmpty) {
                    setState(() =>
                        _touchedSpot = touchResponse.lineBarSpots![0]);
                  }
                },
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (touchedBarSpots) => touchedBarSpots
                      .map((barSpot) => LineTooltipItem(
                            formatCurrency(barSpot.y),
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
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ChoiceChip(
              label: const Text('Ø kumuliert'),
              selected: _showAverage,
              showCheckmark: false,
              onSelected: (_) => setState(() {
                _showAverage = true;
                _touchedSpot = null;
              }),
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: const Text('Je Monat'),
              selected: !_showAverage,
              showCheckmark: false,
              onSelected: (_) => setState(() {
                _showAverage = false;
                _touchedSpot = null;
              }),
            ),
          ],
        ),
      ],
    );
  }

  Widget _maybeBlur({required Widget child}) {
    if (!widget.hidden) return child;
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: child,
    );
  }

  /// Picks a bottom-axis tick interval (in milliseconds) that yields roughly
  /// six evenly spaced month labels, matching the approach used for the main
  /// chart's "MAX" range.
  double _bottomTitleInterval(List<FlSpot> spots) {
    if (spots.length <= 1) return const Duration(days: 30).inMilliseconds.toDouble();

    final start = DateTime.fromMillisecondsSinceEpoch(spots.first.x.toInt());
    final end = DateTime.fromMillisecondsSinceEpoch(spots.last.x.toInt());
    final totalDays = max(1, end.difference(start).inDays);

    const targetTicks = 6;
    const monthDays = 30;
    final stepDays = max(monthDays, (totalDays / targetTicks).round());
    return Duration(days: stepDays).inMilliseconds.toDouble();
  }
}
