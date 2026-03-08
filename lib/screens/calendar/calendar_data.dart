import 'package:xfin/database/models/analysis_models.dart';

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
