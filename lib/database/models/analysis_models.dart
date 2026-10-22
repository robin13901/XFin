import 'package:fl_chart/fl_chart.dart';
import 'package:xfin/database/app_database.dart';

/// Aggregated snapshot of a single calendar month's financial data.
class MonthlyAnalysisSnapshot {
  final double inflows;
  final double outflows;
  final double profit;
  final Map<String, double> categoryInflows;
  final Map<String, double> categoryOutflows;

  const MonthlyAnalysisSnapshot({
    required this.inflows,
    required this.outflows,
    required this.profit,
    required this.categoryInflows,
    required this.categoryOutflows,
  });
}

/// Data backing the monthly-profit line chart popup on the analysis screen.
///
/// The two series are shown exclusively (toggled by the user) and use
/// different x-axis granularity and range:
/// - [perMonthProfit]: one point per calendar month (x = month start in ms
///   since epoch) for roughly the last two years, independent of the active
///   timeframe filter. Each y is the month's realized profit, computed with the
///   same methodology as the "Gewinn Aktueller Monat" row
///   (`AnalysisDao.getProfitAndLossForMonth`).
/// - [movingAverage]: one point per day (x = day in ms since epoch) from the
///   start of the active timeframe up to today. Each y is a 100-day moving
///   average of the monthly profit: the sum of realized profit over the last
///   100 days (clipped to the timeframe start) divided by the number of months
///   in that window, plus the standing-order projection.
class MonthlyProfitChartData {
  final List<FlSpot> perMonthProfit;
  final List<FlSpot> movingAverage;

  const MonthlyProfitChartData({
    required this.perMonthProfit,
    required this.movingAverage,
  });
}

/// Per-month aggregation for a single category.
class CategoryMonthBucket {
  final int year;
  final int month;
  final int count;
  final double sum;

  const CategoryMonthBucket({
    required this.year,
    required this.month,
    required this.count,
    required this.sum,
  });

  /// First day of this bucket's month.
  DateTime get monthStart => DateTime(year, month, 1);

  /// Stable key in yyyyMM form for fast lookups.
  int get key => year * 100 + month;
}

/// Per-day aggregation for a single category (for heatmap rendering).
class CategoryDayBucket {
  final int dateInt; // yyyyMMdd
  final int count;
  final double sum;

  const CategoryDayBucket({
    required this.dateInt,
    required this.count,
    required this.sum,
  });
}

/// Aggregated statistics for a single category, used by [CategoryDetailScreen].
class CategoryStats {
  final String category;
  final List<CategoryMonthBucket> monthlyBuckets; // ascending by date, all months filled with zeros
  final Map<int, CategoryDayBucket> dailyBuckets; // keyed by yyyyMMdd, only days with bookings
  final int totalCount;
  final double totalSum;
  final DateTime? earliestBookingDate;

  const CategoryStats({
    required this.category,
    required this.monthlyBuckets,
    required this.dailyBuckets,
    required this.totalCount,
    required this.totalSum,
    required this.earliestBookingDate,
  });
}

/// Detailed breakdown of bookings, transfers, and trades for a single day.
class CalendarDayDetails {
  final DateTime day;
  final double inflow;
  final double outflow;
  final double tradeNet;
  final double net;
  final List<Booking> bookings;
  final List<Transfer> transfers;
  final List<Trade> trades;

  const CalendarDayDetails({
    required this.day,
    required this.inflow,
    required this.outflow,
    required this.tradeNet,
    required this.net,
    required this.bookings,
    required this.transfers,
    required this.trades,
  });
}
