import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'package:provider/provider.dart';

import '../app_theme.dart';
import '../database/app_database.dart';
import '../database/daos/analysis_dao.dart';
import '../database/tables.dart';
import '../l10n/app_localizations.dart';
import '../providers/database_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/format.dart';
import '../utils/global_constants.dart';
import '../widgets/inflow_outflow_toggle.dart';
import '../widgets/liquid_glass_widgets.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  static const int _initialPage = 2000;
  static const int _prefetchRadius = 2;

  late final DateTime _baseMonth;
  late final PageController _pageController;
  int _currentPageIndex = _initialPage;

  bool _showInflows = true;
  bool _showAllCategories = false;

  final Map<int, Future<_CalendarScreenData>> _monthFutureCache = {};
  late Future<_CalendarScreenData> _selectedMonthFuture;

  DateTime get _selectedMonth => _monthAtPage(_currentPageIndex);

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _baseMonth = DateTime(now.year, now.month);
    _pageController = PageController(initialPage: _initialPage);
    _selectedMonthFuture = _ensureMonthData(_selectedMonth);
    _prefetchNeighborsAfterDisplay(_selectedMonth);
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

  int _monthCacheKey(DateTime month) => month.year * 100 + month.month;

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
    final key = _monthCacheKey(month);
    return _monthFutureCache.putIfAbsent(key, () => _loadMonthData(month));
  }

  void _prefetchAround(DateTime month, {int radius = _prefetchRadius}) {
    for (var i = -radius; i <= radius; i++) {
      _ensureMonthData(addMonths(month, i));
    }
  }

  Future<void> _prefetchNeighborsAfterDisplay(DateTime month) async {
    await _ensureMonthData(month);
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _prefetchAround(month);
    });
  }

  void _onMonthChanged(int pageIndex) {
    final month = _monthAtPage(pageIndex);
    setState(() {
      _currentPageIndex = pageIndex;
      _showAllCategories = false;
      _selectedMonthFuture = _ensureMonthData(month);
    });
    _prefetchNeighborsAfterDisplay(month);
  }

  Future<void> _openDayDetails(DateTime day) async {
    final db = context.read<DatabaseProvider>().db;
    final results = await Future.wait([
      db.analysisDao.getCalendarDayDetails(day),
      db.assetsDao.getAllAssets(),
    ]);
    if (!mounted) return;

    final details = results[0] as CalendarDayDetails;
    final assets = results[1] as List<Asset>;
    final assetTickerById = <int, String>{
      for (final asset in assets) asset.id: asset.tickerSymbol,
    };

    final pages = _buildDetailPages(context, details, assetTickerById);
    if (pages.isEmpty) {
      return;
    }

    final l10n = AppLocalizations.of(context)!;

    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: l10n.calendarDayDetails,
      barrierColor: Colors.black54,
      transitionDuration: Duration.zero,
      pageBuilder: (context, _, __) {
        return Center(
          child: Material(
            type: MaterialType.transparency,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.92,
              constraints: const BoxConstraints(maxWidth: 560, maxHeight: 460),
              child: _DayDetailsPager(details: details, pages: pages),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, _, child) => child,
    );
  }

  List<_DayDetailsPage> _buildDetailPages(
    BuildContext context,
    CalendarDayDetails details,
    Map<int, String> assetTickerById,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final pages = <_DayDetailsPage>[];

    pages.add(
      _DayDetailsPage(
        title: l10n.calendarAnalyticalStats,
        child: Column(
          children: [
            _statLine(l10n.calendarNet, details.net,
                details.net >= 0 ? AppColors.green : AppColors.red),
            _statLine(l10n.calendarInflows, details.inflow, AppColors.green),
            _statLine(l10n.calendarOutflows, details.outflow, AppColors.red),
            _statLine(
              l10n.calendarTradeDeltas,
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
          title: l10n.bookings,
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
          title: l10n.transfers,
          child: _compactList(
            details.transfers.map((t) {
              return _SimpleDetailRow(
                leading: '${l10n.transfer} #${t.id}',
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
          title: l10n.trades,
          child: _compactList(
            details.trades.map((t) {
              final net = t.sourceAccountValueDelta + t.targetAccountValueDelta;
              final side =
                  t.type == TradeTypes.buy ? l10n.calendarTradeBuy : l10n.calendarTradeSell;
              final ticker = assetTickerById[t.assetId] ?? l10n.asset;
              final description =
                  '$side ${t.shares.toStringAsFixed(4)} $ticker @ ${formatCurrency(t.costBasis)}';
              return _SimpleDetailRow(
                leading: description,
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
                        maxLines: 2,
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
    final l10n = AppLocalizations.of(context)!;
    final selectedMonth = _selectedMonth;
    final selectedMonthKey = _monthCacheKey(selectedMonth);

    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + kToolbarHeight + 12,
              left: 12,
              right: 12,
              bottom: 24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMonthHeader(selectedMonth),
                const SizedBox(height: 12),
                _buildCalendarPager(),
                const SizedBox(height: 20),
                FutureBuilder<_CalendarScreenData>(
                  key: ValueKey(selectedMonthKey),
                  future: _selectedMonthFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError || !snapshot.hasData) {
                      return Center(child: Text(snapshot.error.toString()));
                    }

                    final data = snapshot.data!;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.calendarMonthlyOverview,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        _summaryRow(
                          l10n.calendarInflows,
                          data.monthlySnapshot.inflows,
                          AppColors.green,
                        ),
                        _summaryRow(
                          l10n.calendarOutflows,
                          data.monthlySnapshot.outflows,
                          AppColors.red,
                        ),
                        _summaryRow(
                          l10n.calendarProfit,
                          data.monthlySnapshot.profit,
                          data.monthlySnapshot.profit >= 0
                              ? AppColors.green
                              : AppColors.red,
                        ),
                        const SizedBox(height: 12),
                        _buildInflowOutflowSwitch(l10n),
                        const SizedBox(height: 32),
                        _buildCategoryPieChart(data.monthlySnapshot),
                        const SizedBox(height: 32),
                        _buildCategoryList(data.monthlySnapshot, l10n),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          buildLiquidGlassAppBar(context, title: Text(l10n.calendar)),
        ],
      ),
    );
  }

  Widget _buildMonthHeader(DateTime selectedMonth) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final label = DateFormat('MMMM yyyy', locale).format(selectedMonth);
    return Center(
      child: Text(
        label[0].toUpperCase() + label.substring(1),
        style: Theme.of(context).textTheme.titleLarge,
      ),
    );
  }

  Widget _buildCalendarPager() {
    return SizedBox(
      height: _calendarHeightForMonth(_selectedMonth),
      child: PageView.builder(
        controller: _pageController,
        physics: const BouncingScrollPhysics(),//const BouncingScrollPhysics(parent: PageScrollPhysics()),
        allowImplicitScrolling: true,
        onPageChanged: _onMonthChanged,
        itemBuilder: (context, index) {
          final month = _monthAtPage(index);
          final monthKey = _monthCacheKey(month);
          return FutureBuilder<_CalendarScreenData>(
            key: ValueKey(monthKey),
            future: _ensureMonthData(month),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              return _MonthGrid(
                month: month,
                dayNetFlow: snapshot.data!.dayNetFlow,
                onDayTap: _openDayDetails,
              );
            },
          );
        },
      ),
    );
  }

  double _calendarHeightForMonth(DateTime month) {
    final rows = _gridRowCount(month);
    const weekdayHeader = 32.0;
    const rowHeight = 78.0;
    const dividerHeight = 1.0;
    const gridPadding = 28.0;
    return weekdayHeader + dividerHeight + rows * rowHeight + gridPadding;
  }

  int _gridRowCount(DateTime month) {
    final firstDayOfMonth = DateTime(month.year, month.month, 1);
    final lastDayOfMonth = DateTime(month.year, month.month + 1, 0);
    final firstWeekdayOffset = (firstDayOfMonth.weekday + 6) % 7;
    final trailingDays = (7 - lastDayOfMonth.weekday) % 7;
    final totalDays = firstWeekdayOffset + lastDayOfMonth.day + trailingDays;
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

  Widget _buildInflowOutflowSwitch(AppLocalizations l10n) {
    return InflowOutflowToggle(
      showInflows: _showInflows,
      inflowLabel: l10n.calendarInflows,
      outflowLabel: l10n.calendarOutflows,
      onChanged: (showInflows) {
        setState(() {
          _showInflows = showInflows;
          _showAllCategories = false;
        });
      },
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

  Widget _buildCategoryList(MonthlyAnalysisSnapshot snapshot, AppLocalizations l10n) {
    final categories =
        _showInflows ? snapshot.categoryInflows : snapshot.categoryOutflows;
    if (categories.isEmpty) {
      return Center(
        child: Text(l10n.calendarNoCategoryData),
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
          child: Text(l10n.calendarShowAll),
        ),
      );
    } else if (!data.hasOther && _showAllCategories) {
      widgets.add(
        TextButton(
          onPressed: () => setState(() => _showAllCategories = false),
          child: Text(l10n.calendarShowLess),
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
    final l10n = AppLocalizations.of(context)!;
    final firstDayOfMonth = DateTime(month.year, month.month, 1);
    final lastDayOfMonth = DateTime(month.year, month.month + 1, 0);
    final firstWeekdayOffset = (firstDayOfMonth.weekday + 6) % 7;
    final trailingDays = (7 - lastDayOfMonth.weekday) % 7;

    final gridStart = firstDayOfMonth.subtract(Duration(days: firstWeekdayOffset));
    final totalCells = firstWeekdayOffset + lastDayOfMonth.day + trailingDays;

    final weekdayLabels = [
      l10n.calendarWeekdayMon,
      l10n.calendarWeekdayTue,
      l10n.calendarWeekdayWed,
      l10n.calendarWeekdayThu,
      l10n.calendarWeekdayFri,
      l10n.calendarWeekdaySat,
      l10n.calendarWeekdaySun,
    ];

    return Column(
      children: [
        Row(
          children: List.generate(7, (i) {
            final isSunday = i == 6;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  weekdayLabels[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isSunday
                        ? AppColors.red.withValues(alpha: 0.9)
                        : Theme.of(context).hintColor,
                  ),
                ),
              ),
            );
          }),
        ),
        Divider(
          height: 1,
          color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
        ),
        GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          itemCount: totalCells,
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisExtent: 78,
          ),
          itemBuilder: (context, index) {
            final date = gridStart.add(Duration(days: index));
            final isCurrentMonth = date.month == month.month;
            final isSunday = date.weekday == DateTime.sunday;
            final isToday = _isSameDate(date, DateTime.now());
            final dateInt = date.year * 10000 + date.month * 100 + date.day;
            final net = dayNetFlow[dateInt];
            final netColor = net == null
                ? Theme.of(context).hintColor
                : (net >= 0 ? AppColors.green : AppColors.red);

            return InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => onDayTap(date),
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    right: BorderSide(
                      color: Theme.of(context)
                          .dividerColor
                          .withValues(alpha: 0.18),
                    ),
                    bottom: BorderSide(
                      color: Theme.of(context)
                          .dividerColor
                          .withValues(alpha: 0.18),
                    ),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isToday
                            ? Theme.of(context).colorScheme.primary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Text(
                        '${date.day}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: !isCurrentMonth
                              ? Theme.of(context).hintColor.withValues(alpha: 0.5)
                              : isToday
                                  ? Colors.white
                                  : isSunday
                                      ? AppColors.red.withValues(alpha: 0.9)
                                      : Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.color,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (net != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: netColor.withValues(
                            alpha: isCurrentMonth ? 0.24 : 0.12,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          formatCurrency(net),
                          style: TextStyle(
                            fontSize: 9,
                            color: isCurrentMonth
                                ? netColor
                                : netColor.withValues(alpha: 0.5),
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
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

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
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
    final l10n = AppLocalizations.of(context)!;
    final dayLabel = DateFormat.yMd(Localizations.localeOf(context).toLanguageTag())
        .format(widget.details.day);

    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: LiquidGlassLayer(
          settings: liquidGlassSettings,
          child: LiquidGlass.grouped(
            shape: const LiquidRoundedSuperellipse(borderRadius: 28),
            child: Padding(
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
                      physics: const BouncingScrollPhysics(parent: PageScrollPhysics()),
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
                  const SizedBox(height: 4),
                  Text(
                    l10n.calendarDayDetailsSwipeHint,
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(color: Theme.of(context).hintColor),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
