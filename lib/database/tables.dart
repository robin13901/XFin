import 'package:drift/drift.dart';

class Accounts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  RealColumn get balance => real()();
}

@TableIndex(
  name: 'index_bookings_date_sending_amount_exclude_standing',
  columns: {
    #date,
    #sendingAccountId,
    #amount,
    #excludeFromAverage,
    #createdByStandingOrder,
  },
)
@TableIndex(
  name: 'index_bookings_date_receiving_amount_exclude_standing',
  columns: {
    #date,
    #receivingAccountId,
    #amount,
    #excludeFromAverage,
    #createdByStandingOrder,
  },
)
@TableIndex(
  name: 'index_bookings_reason_date_amount',
  columns: {#reason, #date, #amount},
)
@TableIndex(
  name: 'index_bookings_date_sending',
  columns: {#date, #sendingAccountId},
)
@TableIndex(
  name: 'index_bookings_date_receiving',
  columns: {#date, #receivingAccountId},
)
class Bookings extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get date => integer()();
  RealColumn get amount => real()();
  TextColumn get reason => text()();
  IntColumn get sendingAccountId => integer()();
  IntColumn get receivingAccountId => integer()();
  TextColumn get notes => text().nullable()();
  BoolColumn get excludeFromAverage =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get createdByStandingOrder =>
      boolean().withDefault(const Constant(false))();
}

class StandingOrders extends Table {
  IntColumn get id => integer().autoIncrement()();
  RealColumn get amount => real()();
  TextColumn get reason => text()();
  IntColumn get sendingAccountId => integer()();
  IntColumn get receivingAccountId => integer()();
  IntColumn get nextExecutionDate => integer()();
  RealColumn get cycleFactor => real()();
  TextColumn get notes => text().nullable()();
}

@TableIndex(name: 'index_goals_targetDate', columns: {#targetDate})
class Goals extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get createdOn => integer()();
  IntColumn get targetDate => integer()();
  RealColumn get targetAmount => real()();
}
