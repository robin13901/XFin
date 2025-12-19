import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables.dart';

part 'goals_dao.g.dart';

@DriftAccessor(tables: [Goals, Accounts])
class GoalsDao extends DatabaseAccessor<AppDatabase> with _$GoalsDaoMixin {
  GoalsDao(super.db);


}
