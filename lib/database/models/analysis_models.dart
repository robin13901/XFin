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

/// A single month's realized profit together with the average monthly profit
/// as of that month.
///
/// Used by the monthly-profit line chart popup on the analysis screen.
/// [profit] is computed with the same methodology as the "Gewinn Aktueller
/// Monat" row (`AnalysisDao.getProfitAndLossForMonth`). [runningAverage] uses
/// the same methodology as the headline "Ø Monatlicher Gewinn"
/// (`AnalysisDao.getMonthlyProfitAndLoss`) with the timeframe truncated to the
/// end of this month, so the series' last point matches that headline exactly.
class MonthlyProfitPoint {
  /// First day of the represented month.
  final DateTime monthDate;

  /// Realized profit/loss for this month (bookings + trade result).
  final double profit;

  /// Average monthly profit computed as if the timeframe ended with this month
  /// (headline methodology).
  final double runningAverage;

  const MonthlyProfitPoint({
    required this.monthDate,
    required this.profit,
    required this.runningAverage,
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
