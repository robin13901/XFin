import 'package:drift/drift.dart';

// Enums
enum AssetTypes { stock, crypto, etf, fund, fiat, derivative }

enum AccountTypes { cash, bankAccount, portfolio, cryptoWallet }

enum TradeTypes { buy, sell }

enum Cycles { daily, weekly, monthly, quarterly, yearly }

// Type Converters
class AssetTypesConverter extends TypeConverter<AssetTypes, String> {
  const AssetTypesConverter();

  @override
  AssetTypes fromSql(String fromDb) {
    return AssetTypes.values.byName(fromDb);
  }

  @override
  String toSql(AssetTypes value) {
    return value.name;
  }
}

class AccountTypesConverter extends TypeConverter<AccountTypes, String> {
  const AccountTypesConverter();

  @override
  AccountTypes fromSql(String fromDb) {
    return AccountTypes.values.byName(fromDb);
  }

  @override
  String toSql(AccountTypes value) {
    return value.name;
  }
}

class TradeTypesConverter extends TypeConverter<TradeTypes, String> {
  const TradeTypesConverter();

  @override
  TradeTypes fromSql(String fromDb) {
    return TradeTypes.values.byName(fromDb);
  }

  @override
  String toSql(TradeTypes value) {
    return value.name;
  }
}

class CyclesConverter extends TypeConverter<Cycles, String> {
  const CyclesConverter();

  @override
  Cycles fromSql(String fromDb) {
    return Cycles.values.byName(fromDb);
  }

  @override
  String toSql(Cycles value) {
    return value.name;
  }
}

// Tables
@DataClassName('Account')
class Accounts extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get name => text().unique()();

  RealColumn get balance => real().withDefault(const Constant(0))();

  RealColumn get initialBalance => real().withDefault(const Constant(0))();

  TextColumn get type => text().map(const AccountTypesConverter())();

  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
}

@DataClassName('Asset')
class Assets extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get name => text().unique()();

  TextColumn get type => text().map(const AssetTypesConverter())();

  TextColumn get tickerSymbol => text().unique()();

  TextColumn get currencySymbol => text().nullable().withDefault(const Constant(null))();

  RealColumn get value => real().withDefault(const Constant(0))();

  RealColumn get shares => real().withDefault(const Constant(0))();

  RealColumn get netCostBasis => real().withDefault(const Constant(1))();

  RealColumn get brokerCostBasis => real().withDefault(const Constant(1))();

  RealColumn get buyFeeTotal => real().withDefault(const Constant(0))();

  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
}

@DataClassName('AssetOnAccount')
class AssetsOnAccounts extends Table {
  IntColumn get accountId => integer().references(Accounts, #id)();

  IntColumn get assetId => integer().references(Assets, #id)();

  RealColumn get value => real().withDefault(const Constant(0))();

  RealColumn get shares => real().withDefault(const Constant(0))();

  RealColumn get netCostBasis => real().withDefault(const Constant(1))();

  RealColumn get brokerCostBasis => real().withDefault(const Constant(1))();

  RealColumn get buyFeeTotal => real().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {accountId, assetId};
}

@TableIndex(name: 'bookings_account_id_date', columns: {#accountId, #date})
@DataClassName('Booking')
class Bookings extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get date => integer()();

  IntColumn get assetId => integer().references(Assets, #id).withDefault(const Constant(1))();

  IntColumn get accountId => integer().references(Accounts, #id)();

  TextColumn get category => text()();

  RealColumn get shares => real()();

  RealColumn get costBasis => real().withDefault(const Constant(1))();

  RealColumn get value => real()();

  TextColumn get notes => text().nullable()();

  BoolColumn get excludeFromAverage =>
      boolean().withDefault(const Constant(false))();

  BoolColumn get isGenerated => boolean().withDefault(const Constant(false))();
}

@TableIndex(
    name: 'transfers_sending_account_id_date',
    columns: {#sendingAccountId, #date})
@TableIndex(
    name: 'transfers_receiving_account_id_date',
    columns: {#receivingAccountId, #date})
@DataClassName('Transfer')
class Transfers extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get date => integer()();

  @ReferenceName('SendingTransfers')
  IntColumn get sendingAccountId => integer().references(Accounts, #id)();

  @ReferenceName('ReceivingTransfers')
  IntColumn get receivingAccountId => integer().references(Accounts, #id)();

  IntColumn get assetId => integer().references(Assets, #id).withDefault(const Constant(1))();

  RealColumn get shares => real()();

  RealColumn get costBasis => real().withDefault(const Constant(1))();

  RealColumn get value => real()();

  TextColumn get notes => text().nullable()();

  BoolColumn get isGenerated => boolean().withDefault(const Constant(false))();
}

@TableIndex(name: 'trades_asset_id_datetime', columns: {#assetId, #datetime})
@TableIndex(
    name: 'trades_source_account_id_datetime',
    columns: {#sourceAccountId, #datetime})
@TableIndex(
    name: 'trades_target_account_id_datetime',
    columns: {#targetAccountId, #datetime})
@DataClassName('Trade')
class Trades extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get datetime => integer()();

  TextColumn get type => text().map(const TradeTypesConverter())();

  @ReferenceName('SourceTrades')
  IntColumn get sourceAccountId => integer().references(Accounts, #id)();

  @ReferenceName('TargetTrades')
  IntColumn get targetAccountId => integer().references(Accounts, #id)();

  IntColumn get assetId => integer().references(Assets, #id)();

  RealColumn get shares => real()();

  RealColumn get costBasis => real()();

  RealColumn get fee => real().withDefault(const Constant(0))();

  RealColumn get tax => real().withDefault(const Constant(0))();

  RealColumn get sourceAccountValueDelta => real()();

  RealColumn get targetAccountValueDelta => real()();

  RealColumn get profitAndLoss => real().withDefault(const Constant(0))();

  RealColumn get returnOnInvest => real().withDefault(const Constant(0))();
}

@TableIndex(
    name: 'periodic_bookings_next_execution_date',
    columns: {#nextExecutionDate})
@DataClassName('PeriodicBooking')
class PeriodicBookings extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get nextExecutionDate => integer()();

  IntColumn get assetId => integer().references(Assets, #id).withDefault(const Constant(1))();

  IntColumn get accountId => integer().references(Accounts, #id)();

  RealColumn get shares => real()();

  RealColumn get costBasis => real().withDefault(const Constant(1))();

  RealColumn get value => real()();

  TextColumn get category => text()();

  TextColumn get notes => text().nullable()();

  TextColumn get cycle => text()
      .map(const CyclesConverter())
      .withDefault(Constant(Cycles.monthly.name))();

  RealColumn get monthlyAverageFactor =>
      real().withDefault(const Constant(1))();
}

@TableIndex(
    name: 'periodic_transfers_next_execution_date',
    columns: {#nextExecutionDate})
@DataClassName('PeriodicTransfer')
class PeriodicTransfers extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get nextExecutionDate => integer()();

  IntColumn get assetId => integer().references(Assets, #id).withDefault(const Constant(1))();

  @ReferenceName('SendingPeriodicTransfers')
  IntColumn get sendingAccountId => integer().references(Accounts, #id)();

  @ReferenceName('ReceivingPeriodicTransfers')
  IntColumn get receivingAccountId => integer().references(Accounts, #id)();

  RealColumn get shares => real()();

  RealColumn get costBasis => real().withDefault(const Constant(1))();

  RealColumn get value => real()();

  TextColumn get notes => text().nullable()();

  TextColumn get cycle => text()
      .map(const CyclesConverter())
      .withDefault(Constant(Cycles.monthly.name))();

  RealColumn get monthlyAverageFactor =>
      real().withDefault(const Constant(1))();
}

@TableIndex(name: 'goals_target_date', columns: {#targetDate})
@DataClassName('Goal')
class Goals extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get assetId => integer().nullable().references(Assets, #id).withDefault(const Constant(1))();

  IntColumn get accountId => integer().nullable().references(Accounts, #id)();

  IntColumn get createdOn => integer()();

  IntColumn get targetDate => integer()();

  RealColumn get targetShares => real()();

  RealColumn get targetValue => real()();
}
