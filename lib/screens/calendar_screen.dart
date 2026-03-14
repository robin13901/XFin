import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_theme.dart';
import '../database/app_database.dart';
import '../database/models/analysis_models.dart';
import '../database/tables.dart';
import '../l10n/app_localizations.dart';
import '../providers/database_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/format.dart';
import '../utils/global_constants.dart';
import '../widgets/aurora_background.dart';
import '../widgets/liquid_glass_widgets.dart';
import 'calendar/calendar_data.dart';
import 'calendar/day_details.dart';
import 'calendar/month_grid.dart';
import 'calendar/month_summary.dart';

/// Slightly more sensitive [PageScrollPhysics]: boosts weak fling velocities
/// so that light swipes reliably snap to the next month instead of bouncing
/// back. All other behaviour (spring, snap, overscroll) stays stock.
class _CalendarPagePhysics extends PageScrollPhysics {
  const _CalendarPagePhysics({super.parent});

  @override
  _CalendarPagePhysics applyTo(ScrollPhysics? ancestor) {
    return _CalendarPagePhysics(parent: buildParent(ancestor));
  }

  @override
  Simulation? createBallisticSimulation(
      ScrollMetrics position, double velocity) {
    // Default PageScrollPhysics only adjusts the target page by ±0.5 when
    // |velocity| > tolerance (~7 px/s).  A slow, short swipe can end below
    // that threshold and snap back.  Boosting weak-but-intentional velocities
    // ensures the ±0.5 kicks in and the page commits to moving forward.
    const double minBoost = 300.0;
    if (velocity.abs() > 1.0 && velocity.abs() < minBoost) {
      velocity = velocity.sign * minBoost;
    }
    return super.createBallisticSimulation(position, velocity);
  }
}

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  static const int _initialPage = 2000;
  static const int _prefetchRadius = 3;

  late final DateTime _baseMonth;
  late final PageController _pageController;
  late final ScrollController _scrollController;

  /// Drives header + summary rebuilds without touching the PageView or scroll wrapper.
  final ValueNotifier<int> _pageNotifier = ValueNotifier<int>(_initialPage);

  bool _showInflows = true;
  bool _showAllCategories = false;

  final Map<int, Future<CalendarScreenData>> _monthFutureCache = {};
  final Map<int, CalendarScreenData> _monthDataCache = {};

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _baseMonth = DateTime(now.year, now.month);
    _pageController = PageController(initialPage: _initialPage);
    _scrollController = ScrollController();
    final initialMonth = _monthAtPage(_initialPage);
    _ensureMonthData(initialMonth);
    _prefetchNeighborsAfterDisplay(initialMonth);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _scrollController.dispose();
    _pageNotifier.dispose();
    super.dispose();
  }

  DateTime _monthAtPage(int index) {
    final delta = index - _initialPage;
    return addMonths(_baseMonth, delta);
  }

  int _monthCacheKey(DateTime month) => month.year * 100 + month.month;

  Future<CalendarScreenData> _loadMonthData(DateTime month) async {
    final db = context.read<DatabaseProvider>().db;
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 0);

    final results = await Future.wait([
      db.analysisDao.getDailyNetFlowInRange(start: start, end: end),
      db.analysisDao.getMonthlyAnalysisSnapshot(month, filterStart: 0, filterEnd: 99999999),
    ]);

    final data = CalendarScreenData(
      month: month,
      dayNetFlow: results[0] as Map<int, double>,
      monthlySnapshot: results[1] as MonthlyAnalysisSnapshot,
    );

    // Cache the resolved data for instant access
    _monthDataCache[_monthCacheKey(month)] = data;

    return data;
  }

  Future<CalendarScreenData> _ensureMonthData(DateTime month) {
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
    _showAllCategories = false;
    _pageNotifier.value = pageIndex;
    final month = _monthAtPage(pageIndex);
    _ensureMonthData(month);
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
              child: DayDetailsPager(details: details, pages: pages),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, _, child) => child,
    );
  }

  List<DayDetailsPage> _buildDetailPages(
    BuildContext context,
    CalendarDayDetails details,
    Map<int, String> assetTickerById,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final pages = <DayDetailsPage>[];

    pages.add(
      DayDetailsPage(
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
        DayDetailsPage(
          title: l10n.bookings,
          child: _compactList(
            details.bookings.map((b) {
              return SimpleDetailRow(
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
        DayDetailsPage(
          title: l10n.transfers,
          child: _compactList(
            details.transfers.map((t) {
              return SimpleDetailRow(
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
        DayDetailsPage(
          title: l10n.trades,
          child: _compactList(
            details.trades.map((t) {
              final net = t.sourceAccountValueDelta + t.targetAccountValueDelta;
              final side =
                  t.type == TradeTypes.buy ? l10n.calendarTradeBuy : l10n.calendarTradeSell;
              final ticker = assetTickerById[t.assetId] ?? l10n.asset;
              final description =
                  '$side ${t.shares.toStringAsFixed(4)} $ticker @ ${formatCurrency(t.costBasis)}';
              return SimpleDetailRow(
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

  Widget _compactList(List<SimpleDetailRow> rows) {
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

    return Scaffold(
      backgroundColor:
          ThemeProvider.instance.isAurora ? Colors.transparent : null,
      body: Stack(
        children: [
          buildAuroraLayer(context),
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
                _buildAnimatedMonthHeader(),
                const SizedBox(height: 12),
                _buildCalendarPager(),
                const SizedBox(height: 20),
                _buildMonthSummary(),
              ],
            ),
          ),
          buildLiquidGlassAppBar(context, title: Text(l10n.calendar)),
        ],
      ),
    );
  }

  /// Month label with a smooth crossfade when the page changes.
  Widget _buildAnimatedMonthHeader() {
    return ValueListenableBuilder<int>(
      valueListenable: _pageNotifier,
      builder: (context, pageIndex, _) {
        final month = _monthAtPage(pageIndex);
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.25),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: MonthHeader(
            key: ValueKey(_monthCacheKey(month)),
            month: month,
          ),
        );
      },
    );
  }

  /// Summary section scoped to [_pageNotifier] so the PageView never rebuilds.
  Widget _buildMonthSummary() {
    return ValueListenableBuilder<int>(
      valueListenable: _pageNotifier,
      builder: (context, pageIndex, _) {
        final month = _monthAtPage(pageIndex);
        final monthKey = _monthCacheKey(month);
        final future = _ensureMonthData(month);

        return FutureBuilder<CalendarScreenData>(
          future: future,
          builder: (context, snapshot) {
            final data = snapshot.data ?? _monthDataCache[monthKey];
            if (data == null) {
              return const SizedBox(height: 200);
            }

            return MonthSummarySection(
              key: ValueKey(monthKey),
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
        );
      },
    );
  }

  Widget _buildCalendarPager() {
    return SizedBox(
      height: _calendarPagerViewportHeight(),
      child: PageView.builder(
        controller: _pageController,
        physics: const _CalendarPagePhysics(),
        allowImplicitScrolling: true,
        onPageChanged: _onMonthChanged,
        itemBuilder: (context, index) {
          final month = _monthAtPage(index);
          final monthKey = _monthCacheKey(month);

          // Fast path: data already resolved — render instantly
          final cachedData = _monthDataCache[monthKey];
          if (cachedData != null) {
            return MonthGrid(
              key: ValueKey(monthKey),
              month: month,
              dayNetFlow: cachedData.dayNetFlow,
              onDayTap: _openDayDetails,
            );
          }

          // Slow path: render grid structure immediately (day numbers visible),
          // then fill in flow data once the future resolves
          return FutureBuilder<CalendarScreenData>(
            key: ValueKey(monthKey),
            future: _ensureMonthData(month),
            builder: (context, snapshot) {
              return MonthGrid(
                month: month,
                dayNetFlow: snapshot.data?.dayNetFlow ?? const {},
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
