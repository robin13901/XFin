import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../database/app_database.dart';
import '../database/daos/trades_dao.dart';
import '../l10n/app_localizations.dart';
import '../providers/database_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/format.dart';
import 'liquid_glass_widgets.dart';

enum ReportMetric { pnl, tradeCount }

class AnnualReportTab extends StatefulWidget {
  const AnnualReportTab({super.key});

  @override
  State<AnnualReportTab> createState() => _AnnualReportTabState();
}

class _AnnualReportTabState extends State<AnnualReportTab> {
  late int _selectedYear;
  ReportMetric _selectedMetric = ReportMetric.pnl;
  Future<AnnualReportData>? _reportFuture;
  late AppDatabase _db;

  bool _showCounts = false;

  @override
  void initState() {
    super.initState();
    _selectedYear = DateTime.now().year;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _db = context.read<DatabaseProvider>().db;
    _reportFuture ??= _db.tradesDao.getAnnualReportData(_selectedYear);
  }

  void _changeYear(int delta) {
    setState(() {
      _selectedYear += delta;
      _reportFuture = _db.tradesDao.getAnnualReportData(_selectedYear);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final statusBarHeight = MediaQuery.of(context).padding.top;

    return FutureBuilder<AnnualReportData>(
      future: _reportFuture,
      builder: (context, snapshot) {
        final data = snapshot.data ?? AnnualReportData.empty;

        return SingleChildScrollView(
          padding: EdgeInsets.only(
            top: statusBarHeight + kToolbarHeight + 12,
            bottom: 96,
            left: 12,
            right: 12,
          ),
          child: Column(
            children: [
              _buildYearSelector(),
              const SizedBox(height: 16),
              _buildBarChart(data, l10n),
              const SizedBox(height: 12),
              _buildMetricSelector(l10n),
              const SizedBox(height: 20),
              _buildSummaryCards(data, l10n),
            ],
          ),
        );
      },
    );
  }

  Widget _buildYearSelector() {
    final isDark = ThemeProvider.isDark();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          key: const Key('year_back'),
          icon: const Icon(Icons.chevron_left),
          onPressed: () => _changeYear(-1),
        ),
        Text(
          '$_selectedYear',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        IconButton(
          key: const Key('year_forward'),
          icon: const Icon(Icons.chevron_right),
          onPressed: _selectedYear < DateTime.now().year
              ? () => _changeYear(1)
              : null,
        ),
      ],
    );
  }

  String _formatYAxisValue(double value) {
    if (_selectedMetric == ReportMetric.tradeCount) {
      return value.toInt().toString();
    }
    final abs = value.abs();
    if (abs >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (abs >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}k';
    }
    return value.toStringAsFixed(0);
  }

  Widget _buildBarChart(AnnualReportData data, AppLocalizations l10n) {
    final isDark = ThemeProvider.isDark();
    const months = ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];
    final axisColor = isDark ? Colors.white24 : Colors.black26;
    final labelColor = isDark ? Colors.white70 : Colors.black54;

    final List<double> values = _selectedMetric == ReportMetric.pnl
        ? data.monthlyPnL
        : List.generate(12, (i) =>
            (data.monthlyBuyCount[i] + data.monthlySellCount[i]).toDouble());

    final maxVal = values.fold<double>(0, (m, v) => v.abs() > m ? v.abs() : m);
    final ceilMax = maxVal == 0 ? 10.0 : maxVal * 1.15;
    final hasNegative = values.any((v) => v < 0);

    return SizedBox(
      height: 260,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: ceilMax,
          minY: hasNegative ? -ceilMax : 0,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final val = values[group.x];
                final text = _selectedMetric == ReportMetric.pnl
                    ? formatCurrency(val)
                    : val.toInt().toString();
                return BarTooltipItem(
                  text,
                  TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx > 11) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      months[idx],
                      style: TextStyle(fontSize: 11, color: labelColor),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 46,
                getTitlesWidget: (value, meta) {
                  if ((value - meta.min).abs() < 0.001 ||
                      (value - meta.max).abs() < 0.001) {
                    return const SizedBox.shrink();
                  }
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    space: 6,
                    child: Text(
                      _formatYAxisValue(value),
                      style: TextStyle(fontSize: 10, color: labelColor),
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
          borderData: FlBorderData(
            show: true,
            border: Border(
              bottom: BorderSide(color: axisColor, width: 1),
              left: BorderSide.none,
              top: BorderSide.none,
              right: BorderSide.none,
            ),
          ),
          extraLinesData: hasNegative
              ? ExtraLinesData(horizontalLines: [
                  HorizontalLine(
                    y: 0,
                    color: labelColor,
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                ])
              : const ExtraLinesData(),
          gridData: const FlGridData(show: false),
          barGroups: List.generate(12, (i) {
            final val = values[i];
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: val,
                  color: val >= 0 ? Colors.green : Colors.red,
                  width: 16,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                    bottom: Radius.circular(4),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildMetricSelector(AppLocalizations l10n) {
    return SegmentedButton<ReportMetric>(
      segments: [
        ButtonSegment(
          value: ReportMetric.pnl,
          label: Text(l10n.profitAndLossAbbrev),
          icon: const Icon(Icons.trending_up, size: 18),
        ),
        ButtonSegment(
          value: ReportMetric.tradeCount,
          label: Text(l10n.tradeCount),
          icon: const Icon(Icons.tag, size: 18),
        ),
      ],
      selected: {_selectedMetric},
      onSelectionChanged: (selection) {
        setState(() => _selectedMetric = selection.first);
      },
    );
  }

  void _toggleCountGroup() {
    setState(() => _showCounts = !_showCounts);
  }

  Widget _buildSummaryCards(AnnualReportData data, AppLocalizations l10n) {
    const double gap = 8;

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - gap) / 2;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            _buildCard(
              key: 'pnl',
              label: l10n.totalProfitAndLoss,
              primaryValue: formatCurrency(data.totalPnL),
              primaryColor: data.totalPnL >= 0 ? Colors.green : Colors.red,
              toggleable: false,
              width: cardWidth,
            ),
            _buildCard(
              key: 'fees',
              label: l10n.totalFees,
              primaryValue: formatCurrency(data.totalFees),
              toggleable: false,
              width: cardWidth,
            ),
            _buildCard(
              key: 'buys',
              label: l10n.totalBuys,
              primaryValue: formatCurrency(data.totalBuyValue),
              secondaryValue: '${data.totalBuyCount}',
              width: cardWidth,
            ),
            _buildCard(
              key: 'sells',
              label: l10n.totalSells,
              primaryValue: formatCurrency(data.totalSellValue),
              secondaryValue: '${data.totalSellCount}',
              width: cardWidth,
            ),
            _buildCard(
              key: 'volume',
              label: l10n.totalTradesVolume,
              primaryValue: formatCurrency(data.totalBuyValue + data.totalSellValue),
              secondaryValue: '${data.totalBuyCount + data.totalSellCount}',
              width: cardWidth,
            ),
          ],
        );
      },
    );
  }

  Widget _buildCard({
    required String key,
    required String label,
    required String primaryValue,
    required double width,
    String? secondaryValue,
    Color? primaryColor,
    bool toggleable = true,
  }) {
    final isDark = ThemeProvider.isDark();
    final displayValue = (toggleable && _showCounts) ? secondaryValue! : primaryValue;

    return SizedBox(
      width: width,
      child: buildLiquidGlassCard(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(height: 6),
          GestureDetector(
            key: Key('card_tap_$key'),
            onTap: toggleable ? _toggleCountGroup : null,
            child: Text(
              displayValue,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: primaryColor ?? (isDark ? Colors.white : Colors.black),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
