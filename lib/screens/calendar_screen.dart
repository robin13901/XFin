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
import '../utils/format.dart';
import '../utils/global_constants.dart';
import '../widgets/category_widgets.dart';
import '../widgets/common_widgets.dart';
import '../widgets/inflow_outflow_toggle.dart';
import '../widgets/liquid_glass_widgets.dart';
import '../widgets/summary_row.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}


class _SnappyPageScrollPhysics extends PageScrollPhysics {
  const _SnappyPageScrollPhysics({super.parent});

  @override
  _SnappyPageScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return _SnappyPageScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  double get minFlingDistance => 1.0;

  @override
  double get minFlingVelocity => 15.0;

  @override
  double get maxFlingVelocity => 20000.0;

  @override
  double carriedMomentum(double existingVelocity) =>
      existingVelocity.sign * existingVelocity.abs().clamp(0.0, 10000.0) * 12;

  @override
  SpringDescription get spring => SpringDescription.withDampingRatio(
        mass: 0.3,
        stiffness: 300.0,
        ratio: 0.8,
      );
}

class _CalendarScreenState extends State<CalendarScreen> {
  static const int _initialPage = 2000;
  static const int _prefetchRadius = 3;

  late final DateTime _baseMonth;
  late final PageController _pageController;
  late final ScrollController _scrollController;
  int _currentPageIndex = _initialPage;

  bool _showInflows = true;
  bool _showAllCategories = false;

  final Map<int, Future<_CalendarScreenData>> _monthFutureCache = {};
  final Map<int, _CalendarScreenData> _monthDataCache = {};
  late Future<_CalendarScreenData> _selectedMonthFuture;

  DateTime get _selectedMonth => _monthAtPage(_currentPageIndex);

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _baseMonth = DateTime(now.year, now.month);
    _pageController = PageController(initialPage: _initialPage);
    _scrollController = ScrollController();
    _selectedMonthFuture = _ensureMonthData(_selectedMonth);
    _prefetchNeighborsAfterDisplay(_selectedMonth);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _scrollController.dispose();
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

    final data = _CalendarScreenData(
      month: month,
      dayNetFlow: results[0] as Map<int, double>,
      monthlySnapshot: results[1] as MonthlyAnalysisSnapshot,
    );

    // Cache the resolved data for instant access
    _monthDataCache[_monthCacheKey(month)] = data;

    return data;
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
      barrierColor: Colors.transparent,
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
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      row.trailing,
                      style: TextStyle(
                        color: row.trailingColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
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
          Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
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

    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            controller: _scrollController,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + kToolbarHeight + 12,
              left: 12,
              right: 12,
              bottom: 24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _MonthHeader(month: selectedMonth),
                const SizedBox(height: 12),
                _buildCalendarPager(),
                const SizedBox(height: 20),
                FutureBuilder<_CalendarScreenData>(
                  future: _selectedMonthFuture,
                  builder: (context, snapshot) {
                    // Show previous data while loading to avoid flicker
                    final data = snapshot.data ?? _monthDataCache[_monthCacheKey(selectedMonth)];
                    if (data == null) {
                      return const SizedBox(height: 200);
                    }

                    return _MonthSummarySection(
                      key: ValueKey(_monthCacheKey(selectedMonth)),
                      data: data,
                      showInflows: _showInflows,
                      showAllCategories: _showAllCategories,
                      onInflowOutflowChanged: (showInflows) {
                        setState(() {
                          _showInflows = showInflows;
                          _showAllCategories = false;
                        });
                      },
                      onShowAllChanged: (showAll) {
                        setState(() {
                          _showAllCategories = showAll;
                        });
                      },
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

  Widget _buildCalendarPager() {
    return SizedBox(
      height: _calendarPagerViewportHeight(),
      child: PageView.builder(
        controller: _pageController,
        physics: const BouncingScrollPhysics(parent: _SnappyPageScrollPhysics()),
        allowImplicitScrolling: true,
        onPageChanged: _onMonthChanged,
        itemBuilder: (context, index) {
          final month = _monthAtPage(index);
          final monthKey = _monthCacheKey(month);

          // Check if data is already cached synchronously
          final cachedData = _monthDataCache[monthKey];
          if (cachedData != null) {
            return _MonthGrid(
              key: ValueKey(monthKey),
              month: month,
              dayNetFlow: cachedData.dayNetFlow,
              onDayTap: _openDayDetails,
            );
          }

          // Otherwise use FutureBuilder
          return FutureBuilder<_CalendarScreenData>(
            key: ValueKey(monthKey),
            future: _ensureMonthData(month),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const SizedBox.shrink();
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

  double _calendarPagerViewportHeight() {
    // Fixed height for 6 rows (maximum possible)
    const weekdayHeader = 32.0;
    const rowHeight = 78.0;
    const dividerHeight = 1.0;
    const gridPadding = 32;
    const maxRows = 6;
    return weekdayHeader + dividerHeight + maxRows * rowHeight + gridPadding;
  }


}

class _MonthHeader extends StatelessWidget {
  final DateTime month;

  const _MonthHeader({required this.month});

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final label = DateFormat('MMMM yyyy', locale).format(month);
    return Center(
      child: Text(
        label[0].toUpperCase() + label.substring(1),
        style: Theme.of(context).textTheme.titleLarge,
      ),
    );
  }
}

class _MonthSummarySection extends StatelessWidget {
  final _CalendarScreenData data;
  final bool showInflows;
  final bool showAllCategories;
  final ValueChanged<bool> onInflowOutflowChanged;
  final ValueChanged<bool> onShowAllChanged;

  const _MonthSummarySection({
    super.key,
    required this.data,
    required this.showInflows,
    required this.showAllCategories,
    required this.onInflowOutflowChanged,
    required this.onShowAllChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(title: l10n.calendarMonthlyOverview),
        const SizedBox(height: 8),
        SummaryRow(
          label: l10n.calendarInflows,
          value: formatCurrency(data.monthlySnapshot.inflows),
          valueColor: AppColors.green,
        ),
        SummaryRow(
          label: l10n.calendarOutflows,
          value: formatCurrency(data.monthlySnapshot.outflows),
          valueColor: AppColors.red,
        ),
        SummaryRow(
          label: l10n.calendarProfit,
          value: formatCurrency(data.monthlySnapshot.profit),
          valueColor: data.monthlySnapshot.profit >= 0 ? AppColors.green : AppColors.red,
        ),
        const SizedBox(height: 12),
        InflowOutflowToggle(
          showInflows: showInflows,
          inflowLabel: l10n.calendarInflows,
          outflowLabel: l10n.calendarOutflows,
          onChanged: onInflowOutflowChanged,
        ),
        const SizedBox(height: 32),
        CategoryPieChart(
          data: calculateCategoryData(
            categories: showInflows
                ? data.monthlySnapshot.categoryInflows
                : data.monthlySnapshot.categoryOutflows,
            showAllCategories: showAllCategories,
          ),
        ),
        const SizedBox(height: 32),
        _CategoryListWrapper(
          data: data,
          showInflows: showInflows,
          showAllCategories: showAllCategories,
          onShowAllChanged: onShowAllChanged,
        ),
      ],
    );
  }
}

/// Wrapper to handle category list display logic
class _CategoryListWrapper extends StatelessWidget {
  final _CalendarScreenData data;
  final bool showInflows;
  final bool showAllCategories;
  final ValueChanged<bool> onShowAllChanged;

  const _CategoryListWrapper({
    required this.data,
    required this.showInflows,
    required this.showAllCategories,
    required this.onShowAllChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final categories =
        showInflows ? data.monthlySnapshot.categoryInflows : data.monthlySnapshot.categoryOutflows;

    if (categories.isEmpty) {
      return Center(child: Text(l10n.calendarNoCategoryData));
    }

    final displayData = calculateCategoryData(
      categories: categories,
      showAllCategories: showAllCategories,
    );

    return Column(
      children: [
        ...List.generate(displayData.entries.length, (i) {
          final entry = displayData.entries[i];
          final percentage = displayData.totalAmount == 0
              ? 0
              : (entry.value.abs() / displayData.totalAmount) * 100;
          return Padding(
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
          );
        }),
        if (displayData.hasOther && !showAllCategories)
          TextButton(
            onPressed: () => onShowAllChanged(true),
            child: Text(l10n.calendarShowAll),
          )
        else if (!displayData.hasOther && showAllCategories)
          TextButton(
            onPressed: () => onShowAllChanged(false),
            child: Text(l10n.calendarShowLess),
          ),
      ],
    );
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

class _MonthGrid extends StatelessWidget {
  final DateTime month;
  final Map<int, double> dayNetFlow;
  final ValueChanged<DateTime> onDayTap;

  const _MonthGrid({
    super.key,
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
    final rowCount = (totalCells / 7).ceil();

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
        Expanded(
          child: Column(
            children: List.generate(rowCount, (rowIndex) {
              return Expanded(
                child: Row(
                  children: List.generate(7, (colIndex) {
                    final cellIndex = rowIndex * 7 + colIndex;
                    if (cellIndex >= totalCells) {
                      return const Expanded(child: SizedBox());
                    }

                    final date = gridStart.add(Duration(days: cellIndex));
                    final isCurrentMonth = date.month == month.month;
                    final isSunday = date.weekday == DateTime.sunday;
                    final isToday = _isSameDate(date, DateTime.now());
                    final dateInt = date.year * 10000 + date.month * 100 + date.day;
                    final net = dayNetFlow[dateInt];
                    final netColor = net == null
                        ? Theme.of(context).hintColor
                        : (net >= 0 ? AppColors.green : AppColors.red);

                    return Expanded(
                      child: InkWell(
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
                                    color: isToday
                                        ? Theme.of(context).colorScheme.onPrimary
                                        : !isCurrentMonth
                                            ? Theme.of(context).hintColor.withValues(alpha: 0.5)
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
                      ),
                    );
                  }),
                ),
              );
            }),
          ),
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
    final locale = Localizations.localeOf(context).toLanguageTag();
    final dayLabel = DateFormat('EEEE, dd.MM.yyyy', locale).format(widget.details.day);

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
                              ?.copyWith(fontWeight: FontWeight.w800, fontSize: 19),
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
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).hintColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: PageView.builder(
                      physics: const BouncingScrollPhysics(parent: _SnappyPageScrollPhysics()),
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
            ),
          ),
        ),
      ),
    );
  }
}
