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
