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
  static const int _initialPage = 2000;

  late final DateTime _baseMonth;
  late final PageController _pageController;
  int _currentPageIndex = _initialPage;

  bool _showInflows = true;
  bool _showAllCategories = false;

  final Map<String, Future<_CalendarScreenData>> _monthFutureCache = {};

  DateTime get _selectedMonth => _monthAtPage(_currentPageIndex);

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _baseMonth = DateTime(now.year, now.month);
    _pageController = PageController(initialPage: _initialPage);
    _ensureMonthData(_selectedMonth);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  DateTime _monthAtPage(int index) {
    final delta = index - _initialPage;
    return addMonths(_baseMonth, delta);
  }

  String _monthKey(DateTime month) => '${month.year}-${month.month}';

  Future<_CalendarScreenData> _loadMonthData(DateTime month) async {
    final db = context.read<DatabaseProvider>().db;
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 0);

    final results = await Future.wait([
      db.analysisDao.getDailyNetFlowInRange(start: start, end: end),
      db.analysisDao.getMonthlyAnalysisSnapshot(month),
    ]);

    return _CalendarScreenData(
      month: month,
      dayNetFlow: results[0] as Map<int, double>,
      monthlySnapshot: results[1] as MonthlyAnalysisSnapshot,
    );
  }

  Future<_CalendarScreenData> _ensureMonthData(DateTime month) {
    final key = _monthKey(month);
    return _monthFutureCache.putIfAbsent(key, () => _loadMonthData(month));
  }

  void _onMonthChanged(int pageIndex) {
    setState(() {
      _currentPageIndex = pageIndex;
      _showAllCategories = false;
    });
    _ensureMonthData(_selectedMonth);
  }

  Future<void> _openDayDetails(DateTime day) async {
    final db = context.read<DatabaseProvider>().db;
    final details = await db.analysisDao.getCalendarDayDetails(day);
    if (!mounted) return;

    final pages = _buildDetailPages(context, details);
    if (pages.isEmpty) {
      return;
    }

    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'calendar-day-details',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (context, _, __) {
        return Center(
          child: Material(
            type: MaterialType.transparency,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.92,
              constraints: const BoxConstraints(maxWidth: 560, maxHeight: 460),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: _DayDetailsPager(details: details, pages: pages),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, _, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: ScaleTransition(
            scale:
                Tween<double>(begin: 0.96, end: 1.0).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOut,
            )),
            child: child,
          ),
        );
      },
    );
  }

  List<_DayDetailsPage> _buildDetailPages(
      BuildContext context, CalendarDayDetails details) {
    final pages = <_DayDetailsPage>[];

    pages.add(
      _DayDetailsPage(
        title: 'Analytical stats',
        child: Column(
          children: [
            _statLine('Netto', details.net,
                details.net >= 0 ? AppColors.green : AppColors.red),
            _statLine('Einnahmen', details.inflow, AppColors.green),
            _statLine('Ausgaben', details.outflow, AppColors.red),
            _statLine(
              'Trade-Deltas',
              details.tradeNet,
              details.tradeNet >= 0 ? AppColors.green : AppColors.red,
            ),
          ],
        ),
      ),
    );

    if (details.bookings.isNotEmpty) {
      pages.add(
        _DayDetailsPage(
          title: 'Bookings',
          child: _compactList(
            details.bookings.map((b) {
              return _SimpleDetailRow(
                leading: b.category,
                trailing: formatCurrency(b.value),
                trailingColor: b.value >= 0 ? AppColors.green : AppColors.red,
              );
            }).toList(),
          ),
        ),
      );
    }

    if (details.transfers.isNotEmpty) {
      pages.add(
        _DayDetailsPage(
          title: 'Transfers',
          child: _compactList(
            details.transfers.map((t) {
              return _SimpleDetailRow(
                leading: 'Transfer #${t.id}',
                trailing: formatCurrency(t.value),
                trailingColor: Theme.of(context).textTheme.bodyLarge?.color,
              );
            }).toList(),
          ),
        ),
      );
    }

    if (details.trades.isNotEmpty) {
      pages.add(
        _DayDetailsPage(
          title: 'Trades',
          child: _compactList(
            details.trades.map((t) {
              final net = t.sourceAccountValueDelta + t.targetAccountValueDelta;
              return _SimpleDetailRow(
                leading: '${t.type.name.toUpperCase()} #${t.id}',
                trailing: formatCurrency(net),
                trailingColor: net >= 0 ? AppColors.green : AppColors.red,
              );
            }).toList(),
          ),
        ),
      );
    }

    return pages;
  }

  Widget _compactList(List<_SimpleDetailRow> rows) {
    return Column(
      children: rows
          .map((row) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        row.leading,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      row.trailing,
                      style: TextStyle(
                        color: row.trailingColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }

  Widget _statLine(String label, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            formatCurrency(value),
            style: TextStyle(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedMonth = _selectedMonth;

    return Scaffold(
      body: Stack(
        children: [
          FutureBuilder<_CalendarScreenData>(
            future: _ensureMonthData(selectedMonth),
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
                    _buildMonthHeader(data.month),
                    const SizedBox(height: 12),
                    _buildCalendarPager(data),
                    const SizedBox(height: 20),
                    Text('Monatliche Übersicht',
                        style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 8),
                    _summaryRow(
                        'Einnahmen', data.monthlySnapshot.inflows, AppColors.green),
                    _summaryRow(
                        'Ausgaben', data.monthlySnapshot.outflows, AppColors.red),
                    _summaryRow(
                      'Gewinn',
                      data.monthlySnapshot.profit,
                      data.monthlySnapshot.profit >= 0
                          ? AppColors.green
                          : AppColors.red,
                    ),
                    const SizedBox(height: 12),
                    _buildInflowOutflowSwitch(),
                    const SizedBox(height: 16),
                    _buildCategoryPieChart(data.monthlySnapshot),
                    const SizedBox(height: 16),
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

  Widget _buildMonthHeader(DateTime selectedMonth) {
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
          '${monthName(selectedMonth.month)} ${selectedMonth.year}',
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

  Widget _buildCalendarPager(_CalendarScreenData currentData) {
    return SizedBox(
      height: _calendarHeightForMonth(currentData.month),
      child: PageView.builder(
        controller: _pageController,
        onPageChanged: _onMonthChanged,
        itemBuilder: (context, index) {
          final month = _monthAtPage(index);
          final monthMap = (month.year == currentData.month.year &&
                  month.month == currentData.month.month)
              ? currentData.dayNetFlow
              : const <int, double>{};
          return _MonthGrid(
            month: month,
            dayNetFlow: monthMap,
            onDayTap: _openDayDetails,
          );
        },
      ),
    );
  }

  double _calendarHeightForMonth(DateTime month) {
    final rows = _gridRowCount(month);
    const weekdayHeader = 36.0;
    const rowHeight = 86.0;
    return weekdayHeader + rows * rowHeight + 10;
  }

  int _gridRowCount(DateTime month) {
    final firstDayOfMonth = DateTime(month.year, month.month, 1);
    final lastDayOfMonth = DateTime(month.year, month.month + 1, 0);
    final firstWeekdayOffset = (firstDayOfMonth.weekday + 6) % 7;
    final trailingDays = (7 - lastDayOfMonth.weekday) % 7;
    final totalDays =
        firstWeekdayOffset + lastDayOfMonth.day + trailingDays;
    return (totalDays / 7).ceil();
  }

  Widget _summaryRow(String label, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            formatCurrency(value),
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ],
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
              onTap: () => setState(() {
                _showInflows = false;
                _showAllCategories = false;
              }),
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

  _CategoryDisplayData _categoryData(MonthlyAnalysisSnapshot snapshot) {
    final categories =
        _showInflows ? snapshot.categoryInflows : snapshot.categoryOutflows;
    final totalAmount =
        categories.values.fold(0.0, (sum, item) => sum + item.abs());
    final sortedCategories = categories.entries.toList()
      ..sort((a, b) => b.value.abs().compareTo(a.value.abs()));

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

    return _CategoryDisplayData(
      entries: visible,
      totalAmount: totalAmount,
      hasOther: hasOther,
    );
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
            final ratio =
                data.totalAmount == 0 ? 0.0 : entry.value.abs() / data.totalAmount;
            return PieChartSectionData(
              value: entry.value.abs(),
              color: chartColors[index % chartColors.length],
              radius: 84,
              title: ratio >= 0.08 ? '${(ratio * 100).toStringAsFixed(0)}%' : '',
              titleStyle:
                  const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildCategoryList(MonthlyAnalysisSnapshot snapshot) {
    final categories =
        _showInflows ? snapshot.categoryInflows : snapshot.categoryOutflows;
    if (categories.isEmpty) {
      return const Center(
        child: Text('Keine Daten für diese Kategorie verfügbar.'),
      );
    }

    final data = _categoryData(snapshot);
    final widgets = <Widget>[];

    for (var i = 0; i < data.entries.length; i++) {
      final entry = data.entries[i];
      final percentage =
          data.totalAmount == 0 ? 0 : (entry.value.abs() / data.totalAmount) * 100;
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
                      decoration: BoxDecoration(
                        color: chartColors[i % chartColors.length],
                        shape: BoxShape.circle,
                      ),
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
                  Text(
                    '${percentage.toStringAsFixed(1)}%',
                    style: TextStyle(color: Theme.of(context).hintColor),
                  ),
                ],
              )
            ],
          ),
        ),
      );
    }

    if (data.hasOther && !_showAllCategories) {
      widgets.add(
        TextButton(
          onPressed: () => setState(() => _showAllCategories = true),
          child: const Text('Alle anzeigen'),
        ),
      );
    } else if (!data.hasOther && _showAllCategories) {
      widgets.add(
        TextButton(
          onPressed: () => setState(() => _showAllCategories = false),
          child: const Text('Weniger anzeigen'),
        ),
      );
    }

    return Column(children: widgets);
  }
}

class _CalendarScreenData {
  final DateTime month;
  final Map<int, double> dayNetFlow;
  final MonthlyAnalysisSnapshot monthlySnapshot;

  const _CalendarScreenData({
    required this.month,
    required this.dayNetFlow,
    required this.monthlySnapshot,
  });
}

class _CategoryDisplayData {
  final List<MapEntry<String, double>> entries;
  final double totalAmount;
  final bool hasOther;

  const _CategoryDisplayData({
    required this.entries,
    required this.totalAmount,
    required this.hasOther,
  });
}

class _MonthGrid extends StatelessWidget {
  final DateTime month;
  final Map<int, double> dayNetFlow;
  final ValueChanged<DateTime> onDayTap;

  const _MonthGrid({
    required this.month,
    required this.dayNetFlow,
    required this.onDayTap,
  });

  @override
  Widget build(BuildContext context) {
    final firstDayOfMonth = DateTime(month.year, month.month, 1);
    final lastDayOfMonth = DateTime(month.year, month.month + 1, 0);
    final firstWeekdayOffset = (firstDayOfMonth.weekday + 6) % 7;
    final trailingDays = (7 - lastDayOfMonth.weekday) % 7;

    final gridStart = firstDayOfMonth.subtract(Duration(days: firstWeekdayOffset));
    final totalCells = firstWeekdayOffset + lastDayOfMonth.day + trailingDays;

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
                    color: isSunday
                        ? AppColors.red
                        : Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ),
            );
          }),
        ),
        const Divider(height: 1),
        GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          itemCount: totalCells,
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisExtent: 86,
          ),
          itemBuilder: (context, index) {
            final date = gridStart.add(Duration(days: index));
            final isCurrentMonth = date.month == month.month;
            final dateInt = date.year * 10000 + date.month * 100 + date.day;
            final net = dayNetFlow[dateInt];
            final color = net == null
                ? Theme.of(context).hintColor
                : (net >= 0 ? AppColors.green : AppColors.red);

            return InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => onDayTap(date),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context)
                        .dividerColor
                        .withValues(alpha: 0.25),
                  ),
                ),
                padding: const EdgeInsets.all(6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${date.day}',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: isCurrentMonth
                            ? Theme.of(context).textTheme.bodyLarge?.color
                            : Theme.of(context).hintColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (net != null)
                      Text(
                        formatCurrency(net),
                        style: TextStyle(
                          fontSize: 10,
                          color: isCurrentMonth
                              ? color
                              : color.withValues(alpha: 0.45),
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _DayDetailsPage {
  final String title;
  final Widget child;

  const _DayDetailsPage({required this.title, required this.child});
}

class _SimpleDetailRow {
  final String leading;
  final String trailing;
  final Color? trailingColor;

  const _SimpleDetailRow({
    required this.leading,
    required this.trailing,
    required this.trailingColor,
  });
}

class _DayDetailsPager extends StatefulWidget {
  final CalendarDayDetails details;
  final List<_DayDetailsPage> pages;

  const _DayDetailsPager({required this.details, required this.pages});

  @override
  State<_DayDetailsPager> createState() => _DayDetailsPagerState();
}

class _DayDetailsPagerState extends State<_DayDetailsPager> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final dayLabel =
        '${widget.details.day.day.toString().padLeft(2, '0')}.${widget.details.day.month.toString().padLeft(2, '0')}.${widget.details.day.year}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  dayLabel,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            widget.pages[_index].title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).hintColor,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: PageView.builder(
              itemCount: widget.pages.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (context, i) {
                return SingleChildScrollView(
                  child: widget.pages[i].child,
                );
              },
            ),
          ),
          if (widget.pages.length > 1)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.pages.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: i == _index ? 14 : 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: i == _index
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).dividerColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
        ],
      ),
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
