import 'package:drift/drift.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xfin/utils/format.dart';
import 'package:xfin/utils/global_constants.dart';
import '../app_database.dart';
import '../tables.dart';

part 'analysis_dao.g.dart';

@DriftAccessor(tables: [
  Accounts,
  Bookings,
  Transfers,
  Trades,
  PeriodicBookings,
  PeriodicTransfers,
  Goals,
  AssetsOnAccounts
])
class AnalysisDao extends DatabaseAccessor<AppDatabase>
    with _$AnalysisDaoMixin {
  AnalysisDao(super.db);

  (int, int) _getMonthStartEnd(DateTime date) {
    final startOfMonth = date.year * 10000 + date.month * 100 + 1;
    final lastDayOfMonth = DateTime(date.year, date.month + 1, 0);
    final endOfMonth = lastDayOfMonth.year * 10000 +
        lastDayOfMonth.month * 100 +
        lastDayOfMonth.day;
    return (startOfMonth, endOfMonth);
  }

  Future<int> _getDaysInTimeFrame() async {
    final prefs = await SharedPreferences.getInstance();
    final int startOfTimeFrameInt = prefs.getInt(PrefKeys.filterStartDate) ?? 0;
    final int endOfTimeFrameInt = prefs.getInt(PrefKeys.filterEndDate) ?? 99999999;

    DateTime? effectiveEndDate;
    if (endOfTimeFrameInt == 99999999) {
      final now = DateTime.now();
      effectiveEndDate = DateTime(now.year, now.month, now.day);
    } else {
      effectiveEndDate = intToDateTime(endOfTimeFrameInt);
    }

    DateTime? effectiveStartDate;
    if (startOfTimeFrameInt == 0) {
      List<int> allMinDates = [];
      final minBookingDate = await (selectOnly(bookings)
            ..addColumns([bookings.date.min()]))
          .map((row) => row.read(bookings.date.min()))
          .getSingle();
      if (minBookingDate != null) allMinDates.add(minBookingDate);
      final minTransferDate = await (selectOnly(transfers)
            ..addColumns([transfers.date.min()]))
          .map((row) => row.read(transfers.date.min()))
          .getSingle();
      if (minTransferDate != null) allMinDates.add(minTransferDate);
      final minTradeDate = await (selectOnly(trades)
            ..addColumns([trades.datetime.min()]))
          .map((row) => row.read(trades.datetime.min()))
          .getSingle();
      if (minTradeDate != null) allMinDates.add(minTradeDate);

      if (allMinDates.isEmpty) {
        effectiveStartDate = effectiveEndDate;
      } else {
        allMinDates.sort();
        effectiveStartDate = intToDateTime(allMinDates.first);
      }
    } else {
      effectiveStartDate = intToDateTime(startOfTimeFrameInt);
    }

    return effectiveEndDate!.difference(effectiveStartDate!).inDays + 1;
  }

  Future<double> _getMonthsInTimeFrame() async {
    int daysInTimeFrame = await _getDaysInTimeFrame();
    return daysInTimeFrame / 30.436875;
  }

  // Reusable queries
  Future<double> getPositivePnLForMonth(
      int startOfMonth, int endOfMonth) async {
    return (selectOnly(trades)
          ..addColumns([trades.profitAndLoss.sum()])
          ..where(
            trades.profitAndLoss.isBiggerThanValue(0) &
                trades.datetime.isBetweenValues(
                    startOfMonth * 1000000, endOfMonth * 1000000),
          ))
        .map((row) => row.read(trades.profitAndLoss.sum()) ?? 0.0)
        .getSingle();
  }

  Future<double> getNegativePnLForMonth(
      int startOfMonth, int endOfMonth) async {
    return (selectOnly(trades)
          ..addColumns([trades.profitAndLoss.sum()])
          ..where(trades.profitAndLoss.isSmallerThanValue(0) &
              trades.datetime.isBetweenValues(
                  startOfMonth * 1000000, endOfMonth * 1000000)))
        .map((row) => row.read(trades.profitAndLoss.sum()) ?? 0.0)
        .getSingle();
  }

  Future<double> getFeesForMonth(int startOfMonth, int endOfMonth) async {
    return (selectOnly(trades)
          ..addColumns([trades.fee.sum()])
          ..where(trades.datetime
              .isBetweenValues(startOfMonth * 1000000, endOfMonth * 1000000)))
        .map((row) => row.read(trades.fee.sum()) ?? 0.0)
        .getSingle();
  }

  Future<double> getTaxForMonth(int startOfMonth, int endOfMonth) async {
    return (selectOnly(trades)
          ..addColumns([trades.tax.sum()])
          ..where(trades.datetime
              .isBetweenValues(startOfMonth * 1000000, endOfMonth * 1000000)))
        .map((row) => row.read(trades.tax.sum()) ?? 0.0)
        .getSingle();
  }

  Future<double> getTotalPositivePnL() async {
    return (selectOnly(trades)
          ..addColumns([trades.profitAndLoss.sum()])
          ..where(trades.profitAndLoss.isBiggerThanValue(0) &
              trades.datetime.isBetweenValues(
                  filterStartDate * 1000000, filterEndDate * 1000000)))
        .map((row) => row.read(trades.profitAndLoss.sum()) ?? 0.0)
        .getSingle();
  }

  Future<double> getTotalNegativePnL() async {
    return (selectOnly(trades)
          ..addColumns([trades.profitAndLoss.sum()])
          ..where(trades.profitAndLoss.isSmallerThanValue(0) &
              trades.datetime.isBetweenValues(
                  filterStartDate * 1000000, filterEndDate * 1000000)))
        .map((row) => row.read(trades.profitAndLoss.sum()) ?? 0.0)
        .getSingle();
  }

  Future<double> getTotalFees() async {
    return (selectOnly(trades)
          ..addColumns([trades.fee.sum()])
          ..where(trades.datetime.isBetweenValues(
              filterStartDate * 1000000, filterEndDate * 1000000)))
        .map((row) => row.read(trades.fee.sum()) ?? 0.0)
        .getSingle();
  }

  Future<double> getTotalTax() async {
    return (selectOnly(trades)
          ..addColumns([trades.tax.sum()])
          ..where(trades.datetime.isBetweenValues(
              filterStartDate * 1000000, filterEndDate * 1000000)))
        .map((row) => row.read(trades.tax.sum()) ?? 0.0)
        .getSingle();
  }

  // Totals for month
  Future<double> getTotalInflowsForMonth(DateTime date) async {
    final (start, end) = _getMonthStartEnd(date);

    final bookingsFuture = (selectOnly(bookings)
          ..addColumns([bookings.value.sum()])
          ..where(bookings.value.isBiggerThanValue(0) &
              bookings.date.isBetweenValues(start, end)))
        .map((row) => row.read(bookings.value.sum()) ?? 0.0)
        .getSingle();

    final positivePnLFuture = getPositivePnLForMonth(start, end);

    final bookingsTotal = await bookingsFuture;
    final positivePnLTotal = await positivePnLFuture;

    return bookingsTotal + positivePnLTotal;
  }

  Future<double> getTotalOutflowsForMonth(DateTime date) async {
    final (start, end) = _getMonthStartEnd(date);

    final bookingsFuture = (selectOnly(bookings)
          ..addColumns([bookings.value.sum()])
          ..where(bookings.value.isSmallerThanValue(0) &
              bookings.date.isBetweenValues(start, end)))
        .map((row) => row.read(bookings.value.sum()) ?? 0.0)
        .getSingle();

    final negativePnLFuture = getNegativePnLForMonth(start, end);
    final tradingFeesFuture = getFeesForMonth(start, end);
    final taxFuture = getTaxForMonth(start, end);

    final bookingsTotal = await bookingsFuture;
    final negativePnLTotal = await negativePnLFuture;
    final tradingFeesTotal = await tradingFeesFuture;
    final taxTotal = await taxFuture;

    return bookingsTotal + negativePnLTotal - tradingFeesTotal - taxTotal;
  }

  Future<double> getProfitAndLossForMonth(DateTime date) async {
    final (start, end) = _getMonthStartEnd(date);

    final bookingsFuture = (selectOnly(bookings)
          ..addColumns([bookings.value.sum()])
          ..where(bookings.date.isBetweenValues(start, end)))
        .map((row) => row.read(bookings.value.sum()) ?? 0.0)
        .getSingle();

    final tradeResultExpression =
        trades.profitAndLoss.sum() - trades.fee.sum() - trades.tax.sum();

    final tradeFuture = (selectOnly(trades)
          ..addColumns([tradeResultExpression])
          ..where(
              trades.datetime.isBetweenValues(start * 1000000, end * 1000000)))
        .map((row) => row.read(tradeResultExpression) ?? 0.0)
        .getSingle();

    final bookingsTotal = await bookingsFuture;
    final tradeTotal = await tradeFuture;

    return bookingsTotal + tradeTotal;
  }

  Future<Map<String, double>> getCategoryInflowsForMonth(DateTime date) async {
    final (start, end) = _getMonthStartEnd(date);

    final bookingsFuture = (selectOnly(bookings)
          ..addColumns([bookings.category, bookings.value.sum()])
          ..where(
            bookings.value.isBiggerThanValue(0) &
                bookings.date.isBetweenValues(start, end),
          )
          ..groupBy([bookings.category]))
        .map((row) => {
              'category': row.read(bookings.category),
              'amount': row.read(bookings.value.sum()) ?? 0.0,
            })
        .get();

    final positivePnLFuture = getPositivePnLForMonth(start, end);

    final bookingsRows = await bookingsFuture;
    final positivePnLTotal = await positivePnLFuture;

    final resultMap = <String, double>{
      for (final row in bookingsRows)
        row['category'] as String: row['amount'] as double,
      if (positivePnLTotal != 0) 'Profit aus Trades': positivePnLTotal,
    };

    final sortedMap = Map.fromEntries(
      resultMap.entries.toList()..sort((a, b) => b.value.compareTo(a.value)),
    );

    return sortedMap;
  }

  Future<Map<String, double>> getCategoryOutflowsForMonth(DateTime date) async {
    final (start, end) = _getMonthStartEnd(date);

    final bookingsFuture = (selectOnly(bookings)
          ..addColumns([bookings.category, bookings.value.sum()])
          ..where(
            bookings.value.isSmallerThanValue(0) &
                bookings.date.isBetweenValues(start, end),
          )
          ..groupBy([bookings.category]))
        .map((row) => {
              'category': row.read(bookings.category),
              'amount': row.read(bookings.value.sum()) ?? 0.0,
            })
        .get();

    final negativePnLFuture = getNegativePnLForMonth(start, end);
    final tradingFeesFuture = getFeesForMonth(start, end);
    final taxFuture = getTaxForMonth(start, end);

    final bookingsRows = await bookingsFuture;
    final negativePnLTotal = await negativePnLFuture;
    final tradingFeesTotal = await tradingFeesFuture;
    final taxTotal = await taxFuture;

    final resultMap = <String, double>{
      for (final row in bookingsRows)
        row['category'] as String: row['amount'] as double,
      if (negativePnLTotal != 0) 'Verlust aus Trades': -negativePnLTotal,
      if (tradingFeesTotal != 0) 'Trading Gebühren': -tradingFeesTotal,
      if (taxTotal != 0) 'Steuern': -taxTotal,
    };

    final sortedMap = Map.fromEntries(
      resultMap.entries.toList()..sort((a, b) => a.value.compareTo(b.value)),
    );

    return sortedMap;
  }

  // Monthly
  Future<double> getMonthlyInflows() async {
    final bookingsFuture = (selectOnly(bookings)
          ..addColumns([bookings.value.sum()])
          ..where(bookings.value.isBiggerThanValue(0) &
              bookings.isGenerated.equals(false) &
              bookings.excludeFromAverage.equals(false) &
              bookings.date.isBetweenValues(filterStartDate, filterEndDate)))
        .map((row) => row.read(bookings.value.sum()) ?? 0.0)
        .getSingle();

    final periodicBookingsFuture = (select(periodicBookings)
          ..where((pb) => pb.shares.isBiggerThanValue(0)))
        .get()
        .then((rows) => rows.fold<double>(
            0.0, (acc, row) => acc + (row.value * row.monthlyAverageFactor)));

    final positivePnLFuture = getTotalPositivePnL();

    final monthsInTimeFrameFuture = _getMonthsInTimeFrame();

    final bookingsTotal = await bookingsFuture;
    final periodicBookingsTotal = await periodicBookingsFuture;
    final positivePnLTotal = await positivePnLFuture;
    final monthsInTimeFrame = await monthsInTimeFrameFuture;

    return (bookingsTotal + positivePnLTotal) / monthsInTimeFrame +
        periodicBookingsTotal;
  }

  Future<double> getMonthlyOutflows() async {
    final bookingsFuture = (selectOnly(bookings)
          ..addColumns([bookings.value.sum()])
          ..where(bookings.value.isSmallerThanValue(0) &
              bookings.isGenerated.equals(false) &
              bookings.excludeFromAverage.equals(false) &
              bookings.date.isBetweenValues(filterStartDate, filterEndDate)))
        .map((row) => row.read(bookings.value.sum()) ?? 0.0)
        .getSingle();

    final periodicBookingsFuture = (select(periodicBookings)
          ..where((pb) => pb.shares.isSmallerThanValue(0)))
        .get()
        .then((rows) => rows.fold<double>(
            0.0, (acc, row) => acc + (row.value * row.monthlyAverageFactor)));

    final negativePnLFuture = getTotalNegativePnL();
    final tradingFeesFuture = getTotalFees();
    final taxFuture = getTotalTax();
    final monthsInTimeFrameFuture = _getMonthsInTimeFrame();

    final bookingsTotal = await bookingsFuture;
    final periodicBookingsTotal = await periodicBookingsFuture;
    final negativePnLTotal = await negativePnLFuture;
    final tradingFeesTotal = await tradingFeesFuture;
    final taxTotal = await taxFuture;
    final monthsInTimeFrame = await monthsInTimeFrameFuture;

    return (bookingsTotal + negativePnLTotal - tradingFeesTotal - taxTotal) /
            monthsInTimeFrame +
        periodicBookingsTotal;
  }

  Future<double> getMonthlyProfitAndLoss() async {
    final bookingsFuture = (selectOnly(bookings)
          ..addColumns([bookings.value.sum()])
          ..where(bookings.isGenerated.equals(false) &
              bookings.excludeFromAverage.equals(false) &
              bookings.date.isBetweenValues(filterStartDate, filterEndDate)))
        .map((row) => row.read(bookings.value.sum()) ?? 0.0)
        .getSingle();

    final periodicBookingsFuture = (select(periodicBookings)).get().then(
        (rows) => rows.fold<double>(
            0.0, (acc, row) => acc + (row.value * row.monthlyAverageFactor)));

    final tradeResultExpression =
        trades.profitAndLoss.sum() - trades.fee.sum() - trades.tax.sum();

    final tradesFuture = (selectOnly(trades)
          ..addColumns([tradeResultExpression]))
        .map((row) => row.read(tradeResultExpression) ?? 0.0)
        .getSingle();

    final monthsInTimeFrameFuture = _getMonthsInTimeFrame();

    final bookingsTotal = await bookingsFuture;
    final periodicBookingsTotal = await periodicBookingsFuture;
    final tradesTotal = await tradesFuture;
    final monthsInTimeFrame = await monthsInTimeFrameFuture;

    return (bookingsTotal + tradesTotal) / monthsInTimeFrame +
        periodicBookingsTotal;
  }

  Future<Map<String, double>> getMonthlyCategoryInflows() async {
    final bookingsFuture = (selectOnly(bookings)
          ..addColumns([bookings.category, bookings.value.sum()])
          ..where(bookings.value.isBiggerThanValue(0) &
              bookings.isGenerated.equals(false) &
              bookings.excludeFromAverage.equals(false) &
              bookings.date.isBetweenValues(filterStartDate, filterEndDate))
          ..groupBy([bookings.category]))
        .map((row) => {
              'category': row.read(bookings.category),
              'amount': row.read(bookings.value.sum()) ?? 0.0,
            })
        .get();

    final periodicBookingsFuture = (selectOnly(periodicBookings)
          ..addColumns([
            periodicBookings.category,
            periodicBookings.value * periodicBookings.monthlyAverageFactor,
          ])
          ..where(periodicBookings.value.isBiggerThanValue(0)))
        .map((row) => {
              'category': row.read(bookings.category),
              'amount': row.read(periodicBookings.value *
                      periodicBookings.monthlyAverageFactor) ??
                  0.0,
            })
        .get();

    final positivePnLFuture = getTotalPositivePnL();
    final monthsInTimeFrameFuture = _getMonthsInTimeFrame();

    final bookingsRows = await bookingsFuture;
    final periodicBookingsRows = await periodicBookingsFuture;
    final positivePnLTotal = await positivePnLFuture;
    final monthsInTimeFrame = await monthsInTimeFrameFuture;

    final resultMap = <String, double>{
      for (final row in bookingsRows)
        row['category'] as String:
            (row['amount'] as double) / monthsInTimeFrame,
      for (final row in periodicBookingsRows)
        row['category'] as String: row['amount'] as double,
      if (positivePnLTotal != 0)
        'Profit aus Trades': positivePnLTotal / monthsInTimeFrame,
    };

    final sortedMap = Map.fromEntries(
      resultMap.entries.toList()..sort((a, b) => b.value.compareTo(a.value)),
    );

    return sortedMap;
  }

  Future<Map<String, double>> getMonthlyCategoryOutflows() async {
    final bookingsFuture = (selectOnly(bookings)
          ..addColumns([bookings.category, bookings.value.sum()])
          ..where(bookings.value.isSmallerThanValue(0) &
              bookings.isGenerated.equals(false) &
              bookings.excludeFromAverage.equals(false) &
              bookings.date.isBetweenValues(filterStartDate, filterEndDate))
          ..groupBy([bookings.category]))
        .map((row) => {
              'category': row.read(bookings.category),
              'amount': row.read(bookings.value.sum()) ?? 0.0,
            })
        .get();

    final periodicBookingsFuture = (selectOnly(periodicBookings)
          ..addColumns([
            periodicBookings.category,
            periodicBookings.value * periodicBookings.monthlyAverageFactor,
          ])
          ..where(periodicBookings.value.isSmallerThanValue(0)))
        .map((row) => {
              'category': row.read(bookings.category),
              'amount': row.read(periodicBookings.value *
                      periodicBookings.monthlyAverageFactor) ??
                  0.0,
            })
        .get();

    final negativePnLFuture = getTotalNegativePnL();
    final tradingFeesFuture = getTotalFees();
    final taxFuture = getTotalTax();
    final monthsInTimeFrameFuture = _getMonthsInTimeFrame();

    final bookingsRows = await bookingsFuture;
    final periodicBookingsRows = await periodicBookingsFuture;
    final negativePnLTotal = await negativePnLFuture;
    final tradingFeesTotal = await tradingFeesFuture;
    final taxTotal = await taxFuture;
    final monthsInTimeFrame = await monthsInTimeFrameFuture;

    final resultMap = <String, double>{
      for (final row in bookingsRows)
        row['category'] as String:
            (row['amount'] as double) / monthsInTimeFrame,
      for (final row in periodicBookingsRows)
        row['category'] as String: row['amount'] as double,
      if (negativePnLTotal != 0)
        'Verlust aus Trades': negativePnLTotal / monthsInTimeFrame,
      if (tradingFeesTotal != 0)
        'Trading Gebühren': -tradingFeesTotal / monthsInTimeFrame,
      if (taxTotal != 0) 'Steuern': -taxTotal / monthsInTimeFrame,
    };

    final sortedMap = Map.fromEntries(
      resultMap.entries.toList()..sort((a, b) => a.value.compareTo(b.value)),
    );

    return sortedMap;
  }

  // Singles
  Future<List<FlSpot>> getBalanceHistory() async {
    final futureResults = await Future.wait([
      db.accountsDao.getSumOfInitialBalances(),
      db.bookingsDao.getAllBookings(),
      db.tradesDao.getAllTrades()
    ]);
    final totalInitialBalance = futureResults[0] as double;
    final allBookings = futureResults[1] as List<Booking>;
    final allTrades = futureResults[2] as List<Trade>;

    final Map<DateTime, double> dailyDeltas = {};

    for (final booking in allBookings) {
      final date = intToDateTime(booking.date)!;
      dailyDeltas[date] = (dailyDeltas[date] ?? 0) + booking.value;
    }

    for (final trade in allTrades) {
      final date = intToDateTime(trade.datetime ~/ 1000000)!;
      dailyDeltas[date] = (dailyDeltas[date] ?? 0) +
          trade.sourceAccountValueDelta +
          trade.targetAccountValueDelta;
    }

    if (dailyDeltas.isEmpty) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      return [
        FlSpot(today.millisecondsSinceEpoch.toDouble(), totalInitialBalance)
      ];
    }

    final sortedDates = dailyDeltas.keys.toList()..sort();
    final firstDate = sortedDates.first;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    List<FlSpot> spots = [];
    double runningBalance = totalInitialBalance;

    for (var date = firstDate;
        date.isBefore(tomorrow);
        date = date.add(const Duration(days: 1))) {
      final dateOnly = DateTime(date.year, date.month, date.day);
      runningBalance += dailyDeltas[dateOnly] ?? 0;
      spots.add(
          FlSpot(dateOnly.millisecondsSinceEpoch.toDouble(), runningBalance));
    }

    return spots;
  }
}
