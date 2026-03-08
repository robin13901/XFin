import 'package:xfin/database/daos/analysis_dao.dart';

class CalendarScreenData {
  final DateTime month;
  final Map<int, double> dayNetFlow;
  final MonthlyAnalysisSnapshot monthlySnapshot;

  const CalendarScreenData({
    required this.month,
    required this.dayNetFlow,
    required this.monthlySnapshot,
  });
}
