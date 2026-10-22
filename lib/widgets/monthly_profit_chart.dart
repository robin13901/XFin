import 'dart:math';
import 'dart:ui';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../app_theme.dart';
import '../providers/theme_provider.dart';
import '../utils/format.dart';

/// A compact line chart that visualizes the development of the monthly profit.
///
/// Mirrors the visual styling of [AnalysisLineChartSection] (same line and
/// tooltip look) but is tailored to this popup: a toggle switches between the
/// per-month profit (monthly points, last ~2 years) and the cumulative average
/// (daily points over the active timeframe). The horizontal axis is left
/// unlabeled on purpose to avoid overlapping date labels.
class MonthlyProfitChart extends StatefulWidget {
  final List<FlSpot> perMonthProfit;
  final List<FlSpot> movingAverage;
  final bool hidden;

  const MonthlyProfitChart({
    super.key,
    required this.perMonthProfit,
    required this.movingAverage,
    this.hidden = false,
  });

  @override
  State<MonthlyProfitChart> createState() => _MonthlyProfitChartState();
}

class _MonthlyProfitChartState extends State<MonthlyProfitChart> {
  /// Whether the cumulative daily average is shown (true) or the per-month
  /// profit (false).
  bool _showAverage = true;
  LineBarSpot? _touchedSpot;

  List<FlSpot> get _currentData =>
      _showAverage ? widget.movingAverage : widget.perMonthProfit;

  /// Formats an x value (ms since epoch) for the header: a full day for the
  /// cumulative (daily) view, a month for the per-month view.
  String _formatDate(double xMillis) {
    final date = DateTime.fromMillisecondsSinceEpoch(xMillis.toInt());
    return _showAverage
        ? DateFormat('dd.MM.yyyy').format(date)
        : DateFormat.yMMM('de_DE').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeProvider.isDark();
    final currentData = _currentData;

    if (currentData.isEmpty) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            height: 120,
            child: Center(child: Text('Keine Daten verfügbar.')),
          ),
          const SizedBox(height: 16),
          _buildToggle(),
        ],
      );
    }

    final double valueToShow;
    final String dateText;
    if (_touchedSpot == null) {
      valueToShow = currentData.last.y;
      dateText = _formatDate(currentData.last.x);
    } else {
      valueToShow = _touchedSpot!.y;
      dateText = _formatDate(_touchedSpot!.x);
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
                // Horizontal axis intentionally unlabeled to avoid overlapping
                // date labels.
                bottomTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
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
        _buildToggle(),
      ],
    );
  }

  Widget _buildToggle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ChoiceChip(
          label: const Text('100-SMA'),
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
    );
  }

  Widget _maybeBlur({required Widget child}) {
    if (!widget.hidden) return child;
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: child,
    );
  }
}
