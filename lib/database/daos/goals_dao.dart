import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables.dart';

part 'goals_dao.g.dart';

@DriftAccessor(tables: [Goals, Accounts])
class GoalsDao extends DatabaseAccessor<AppDatabase> with _$GoalsDaoMixin {
  GoalsDao(super.db);

  void _validateDate(int dateInt) {
    final dateString = dateInt.toString();
    if (dateString.length != 8) {
      throw Exception('Date must be in yyyyMMdd format and a valid date.');
    }

    final year = int.tryParse(dateString.substring(0, 4)) ?? 0;
    final month = int.tryParse(dateString.substring(4, 6)) ?? 0;
    final day = int.tryParse(dateString.substring(6, 8)) ?? 0;

    try {
      final date = DateTime(year, month, day);
      if (date.year != year || date.month != month || date.day != day) {
        throw Exception('Date must be a valid date.');
      }
    } catch (e) {
      throw Exception('Date must be a valid date.');
    }
  }

  Future<void> validate(Goal goal) async {
    _validateDate(goal.createdOn);
    _validateDate(goal.targetDate);
    if (goal.targetAmount <= 0) {
      throw Exception('Target amount must be greater than 0.');
    }
    if (goal.targetDate <= goal.createdOn) {
      throw Exception('Target date must be after created date.');
    }
  }
}
