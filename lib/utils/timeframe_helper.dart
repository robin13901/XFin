// Pure utility functions for timeframe calculations.
//
// Extracted from AnalysisDao to enable standalone testing
// and reuse without database dependencies.

/// Returns (startOfMonth, endOfMonth) as yyyyMMdd integers for the given [date].
(int, int) getMonthStartEnd(DateTime date) {
  final startOfMonth = date.year * 10000 + date.month * 100 + 1;
  final lastDayOfMonth = DateTime(date.year, date.month + 1, 0);
  final endOfMonth = lastDayOfMonth.year * 10000 +
      lastDayOfMonth.month * 100 +
      lastDayOfMonth.day;
  return (startOfMonth, endOfMonth);
}

/// Computes the intersection between a calendar month and a filter range.
///
/// Returns (effectiveStart, effectiveEnd) as yyyyMMdd integers,
/// or `null` when the month lies entirely outside the filter window.
(int, int)? getMonthTimeframeIntersection(
  DateTime date, {
  required int filterStart,
  required int filterEnd,
}) {
  final (monthStart, monthEnd) = getMonthStartEnd(date);

  final effectiveStart = monthStart > filterStart ? monthStart : filterStart;
  final effectiveEnd = monthEnd < filterEnd ? monthEnd : filterEnd;

  if (effectiveStart > effectiveEnd) return null;
  return (effectiveStart, effectiveEnd);
}

/// Converts a yyyyMMdd date integer to the start-of-day datetime integer
/// used by trade queries (yyyyMMddHHmmss with HHmmss = 000000).
int monthStartDateTimeInt(int startDate) => startDate * 1000000;

/// Converts a yyyyMMdd date integer to the end-of-day datetime integer
/// used by trade queries (yyyyMMddHHmmss with HHmmss = 235959).
int monthEndDateTimeInt(int endDate) => endDate * 1000000 + 235959;
