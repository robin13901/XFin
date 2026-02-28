import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_theme.dart';
import '../database/daos/analysis_dao.dart';
import '../providers/database_provider.dart';
import '../utils/format.dart';
import '../utils/global_constants.dart';
import '../widgets/liquid_glass_widgets.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  static const int _initialPage = 1200;
  final PageController _pageController = PageController(initialPage: _initialPage);
  bool _showInflows = true;
  bool _showAllCategories = false;

  late DateTime _selectedMonth;
  late Future<_CalendarScreenData> _monthDataFuture;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month);
    _monthDataFuture = _loadMonthData(_selectedMonth);
  }

  Future<_CalendarScreenData> _loadMonthData(DateTime month) async {
    final db = context.read<DatabaseProvider>().db;
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 0);

    final results = await Future.wait([
      db.analysisDao.getDailyNetFlowInRange(start: start, end: end),
      db.analysisDao.getMonthlyAnalysisSnapshot(month),
    ]);

    return _CalendarScreenData(
      dayNetFlow: results[0] as Map<int, double>,
      monthlySnapshot: results[1] as MonthlyAnalysisSnapshot,
    );
  }

  void _setMonth(DateTime month) {
    setState(() {
      _selectedMonth = DateTime(month.year, month.month);
      _showAllCategories = false;
      _monthDataFuture = _loadMonthData(_selectedMonth);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FutureBuilder<_CalendarScreenData>(
            future: _monthDataFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError || !snapshot.hasData) {
                return Center(child: Text(snapshot.error.toString()));
              }

              final data = snapshot.data!;
              return SingleChildScrollView(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + kToolbarHeight + 12,
                  left: 12,
                  right: 12,
                  bottom: 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMonthHeader(),
                    const SizedBox(height: 8),
                    _buildCalendarPager(data.dayNetFlow),
                    const SizedBox(height: 20),
                    Text('Monatliche Übersicht', style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 8),
                    _summaryRow('Einnahmen', data.monthlySnapshot.inflows, AppColors.green),
                    _summaryRow('Ausgaben', data.monthlySnapshot.outflows, AppColors.red),
                    _summaryRow(
                      'Gewinn',
                      data.monthlySnapshot.profit,
                      data.monthlySnapshot.profit >= 0 ? AppColors.green : AppColors.red,
                    ),
                    const SizedBox(height: 12),
                    _buildInflowOutflowSwitch(),
                    const SizedBox(height: 12),
                    _buildCategoryPieChart(data.monthlySnapshot),
                    const SizedBox(height: 12),
                    _buildCategoryList(data.monthlySnapshot),
                  ],
                ),
              );
            },
          ),
          buildLiquidGlassAppBar(context, title: const Text('Calendar')),
        ],
      ),
    );
  }

  Widget _buildMonthHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: () => _pageController.previousPage(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
          ),
          icon: const Icon(Icons.chevron_left),
        ),
        Text(
          '${monthName(_selectedMonth.month)} ${_selectedMonth.year}',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        IconButton(
          onPressed: () => _pageController.nextPage(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
          ),
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }

  Widget _buildCalendarPager(Map<int, double> dayNetFlow) {
    return SizedBox(
      height: 420,
      child: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) {
          final diff = index - _initialPage;
          _setMonth(DateTime(DateTime.now().year, DateTime.now().month + diff));
        },
        itemBuilder: (context, index) {
          final diff = index - _initialPage;
          final month = DateTime(DateTime.now().year, DateTime.now().month + diff);
          final monthMap = month.year == _selectedMonth.year && month.month == _selectedMonth.month
              ? dayNetFlow
              : const <int, double>{};
          return _MonthGrid(month: month, dayNetFlow: monthMap);
        },
      ),
    );
  }

  Widget _summaryRow(String label, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label), Text(formatCurrency(value), style: TextStyle(color: color, fontWeight: FontWeight.bold))],
      ),
    );
  }

  Widget _buildInflowOutflowSwitch() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() {
                _showInflows = true;
                _showAllCategories = false;
              }),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _showInflows ? AppColors.green.withValues(alpha: 0.2) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    'Einnahmen',
                    style: TextStyle(
                      color: _showInflows ? AppColors.green : Theme.of(context).textTheme.bodyLarge?.color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() {
                _showInflows = false;
                _showAllCategories = false;
              }),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: !_showInflows ? AppColors.red.withValues(alpha: 0.2) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    'Ausgaben',
                    style: TextStyle(
                      color: !_showInflows ? AppColors.red : Theme.of(context).textTheme.bodyLarge?.color,
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

  _CategoryDisplayData _categoryData(MonthlyAnalysisSnapshot snapshot) {
    final categories = _showInflows ? snapshot.categoryInflows : snapshot.categoryOutflows;
    final totalAmount = categories.values.fold(0.0, (sum, item) => sum + item.abs());
    final sortedCategories = categories.entries.toList()..sort((a, b) => b.value.abs().compareTo(a.value.abs()));

    final visible = <MapEntry<String, double>>[];
    bool hasOther = false;
    double other = 0;

    for (final entry in sortedCategories) {
      final percentage = totalAmount == 0 ? 0 : (entry.value.abs() / totalAmount) * 100;
      if (!_showAllCategories && percentage < 1.0) {
        hasOther = true;
        other += entry.value;
      } else {
        visible.add(entry);
      }
    }

    if (hasOther && other != 0) {
      visible.add(MapEntry('...', other));
    }

    return _CategoryDisplayData(entries: visible, totalAmount: totalAmount, hasOther: hasOther);
  }

  Widget _buildCategoryPieChart(MonthlyAnalysisSnapshot snapshot) {
    final data = _categoryData(snapshot);
    if (data.entries.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 220,
      child: PieChart(
        PieChartData(
          sectionsSpace: 3,
          centerSpaceRadius: 40,
          startDegreeOffset: -90,
          sections: List.generate(data.entries.length, (index) {
            final entry = data.entries[index];
            final ratio = data.totalAmount == 0 ? 0.0 : entry.value.abs() / data.totalAmount;
            return PieChartSectionData(
              value: entry.value.abs(),
              color: chartColors[index % chartColors.length],
              radius: 84,
              title: ratio >= 0.08 ? '${(ratio * 100).toStringAsFixed(0)}%' : '',
              titleStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildCategoryList(MonthlyAnalysisSnapshot snapshot) {
    final categories = _showInflows ? snapshot.categoryInflows : snapshot.categoryOutflows;
    if (categories.isEmpty) {
      return const Center(child: Text('Keine Daten für diese Kategorie verfügbar.'));
    }

    final data = _categoryData(snapshot);
    final widgets = <Widget>[];

    for (var i = 0; i < data.entries.length; i++) {
      final entry = data.entries[i];
      final percentage = data.totalAmount == 0 ? 0 : (entry.value.abs() / data.totalAmount) * 100;
      widgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(color: chartColors[i % chartColors.length], shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(entry.key)),
                  ],
                ),
              ),
              Row(
                children: [
                  Text(formatCurrency(entry.value)),
                  const SizedBox(width: 8),
                  Text('${percentage.toStringAsFixed(1)}%', style: TextStyle(color: Theme.of(context).hintColor)),
                ],
              )
            ],
          ),
        ),
      );
    }

    if (data.hasOther && !_showAllCategories) {
      widgets.add(TextButton(onPressed: () => setState(() => _showAllCategories = true), child: const Text('Alle anzeigen')));
    } else if (!data.hasOther && _showAllCategories) {
      widgets.add(TextButton(onPressed: () => setState(() => _showAllCategories = false), child: const Text('Weniger anzeigen')));
    }

    return Column(children: widgets);
  }
}

class _CalendarScreenData {
  final Map<int, double> dayNetFlow;
  final MonthlyAnalysisSnapshot monthlySnapshot;

  const _CalendarScreenData({required this.dayNetFlow, required this.monthlySnapshot});
}

class _CategoryDisplayData {
  final List<MapEntry<String, double>> entries;
  final double totalAmount;
  final bool hasOther;

  const _CategoryDisplayData({required this.entries, required this.totalAmount, required this.hasOther});
}

class _MonthGrid extends StatelessWidget {
  final DateTime month;
  final Map<int, double> dayNetFlow;

  const _MonthGrid({required this.month, required this.dayNetFlow});

  @override
  Widget build(BuildContext context) {
    final firstDayOfMonth = DateTime(month.year, month.month, 1);
    final firstWeekdayOffset = (firstDayOfMonth.weekday + 6) % 7;
    final gridStart = firstDayOfMonth.subtract(Duration(days: firstWeekdayOffset));

    const weekdayLabels = ['MO.', 'DI.', 'MI.', 'DO.', 'FR.', 'SA.', 'SO.'];

    return Column(
      children: [
        Row(
          children: List.generate(7, (i) {
            final isSunday = i == 6;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  weekdayLabels[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isSunday ? AppColors.red : Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ),
            );
          }),
        ),
        const Divider(height: 1),
        Expanded(
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 42,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7),
            itemBuilder: (context, index) {
              final date = gridStart.add(Duration(days: index));
              final isCurrentMonth = date.month == month.month;
              final dateInt = date.year * 10000 + date.month * 100 + date.day;
              final net = dayNetFlow[dateInt];
              final color = net == null
                  ? Theme.of(context).hintColor
                  : (net >= 0 ? AppColors.green : AppColors.red);

              return Container(
                decoration: BoxDecoration(border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.25))),
                padding: const EdgeInsets.all(4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${date.day}',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: isCurrentMonth ? Theme.of(context).textTheme.bodyLarge?.color : Theme.of(context).hintColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    if (net != null)
                      Text(
                        formatCurrency(net),
                        style: TextStyle(fontSize: 12, color: isCurrentMonth ? color : color.withValues(alpha: 0.45), fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

String monthName(int month) {
  const names = [
    'Januar',
    'Februar',
    'März',
    'April',
    'Mai',
    'Juni',
    'Juli',
    'August',
    'September',
    'Oktober',
    'November',
    'Dezember',
  ];
  return names[(month - 1).clamp(0, 11)];
}
