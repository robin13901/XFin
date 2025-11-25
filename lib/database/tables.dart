import 'package:drift/drift.dart';

// Enums
enum AssetTypes { stock, crypto, etf, bond, currency, commodity }
enum AccountTypes { cash, portfolio }
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
  RealColumn get balance => real()();
  RealColumn get initialBalance => real()();
  TextColumn get type => text().map(const AccountTypesConverter())();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
}

@DataClassName('Asset')
class Assets extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().unique()();
  TextColumn get type => text().map(const AssetTypesConverter())();
  TextColumn get tickerSymbol => text().unique()();
  RealColumn get value => real().withDefault(const Constant(0.0))();
  RealColumn get sharesOwned => real().withDefault(const Constant(0.0))();
  RealColumn get netCostBasis => real().withDefault(const Constant(0.0))();
  RealColumn get brokerCostBasis => real().withDefault(const Constant(0.0))();
  RealColumn get buyFeeTotal => real().withDefault(const Constant(0.0))();
}

@TableIndex(name: 'bookings_account_id_date', columns: {#accountId, #date})
@TableIndex(name: 'bookings_category_date_amount', columns: {#category, #date, #amount})
@TableIndex(
  name: 'bookings_complex_query',
  columns: {#date, #accountId, #amount, #excludeFromAverage, #isGenerated},
)
@DataClassName('Booking')
class Bookings extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get date => integer()();
  RealColumn get amount => real()();
  TextColumn get category => text()();
  IntColumn get accountId => integer().references(Accounts, #id)();
  TextColumn get notes => text().nullable()();
  BoolColumn get excludeFromAverage => boolean().withDefault(const Constant(false))();
  BoolColumn get isGenerated => boolean().withDefault(const Constant(false))();
}

@TableIndex(name: 'transfers_sending_account_id_date', columns: {#sendingAccountId, #date})
@TableIndex(name: 'transfers_receiving_account_id_date', columns: {#receivingAccountId, #date})
@TableIndex(
  name: 'transfers_complex_query',
  columns: {#date, #receivingAccountId, #amount, #isGenerated},
)
@DataClassName('Transfer')
class Transfers extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get date => integer()();
  RealColumn get amount => real()();
  @ReferenceName('SendingTransfers')
  IntColumn get sendingAccountId => integer().references(Accounts, #id)();
  @ReferenceName('ReceivingTransfers')
  IntColumn get receivingAccountId => integer().references(Accounts, #id)();
  TextColumn get notes => text().nullable()();
  BoolColumn get isGenerated => boolean()();
}

@TableIndex(name: 'trades_asset_id_datetime', columns: {#assetId, #datetime})
@TableIndex(name: 'trades_clearing_account_id_datetime', columns: {#clearingAccountId, #datetime})
@TableIndex(name: 'trades_portfolio_account_id_datetime', columns: {#portfolioAccountId, #datetime})
@DataClassName('Trade')
class Trades extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get datetime => integer()();
  IntColumn get assetId => integer().references(Assets, #id)();
  TextColumn get type => text().map(const TradeTypesConverter())();
  RealColumn get clearingAccountValueDelta => real()();
  RealColumn get portfolioAccountValueDelta => real()();
  RealColumn get shares => real()();
  RealColumn get pricePerShare => real()();
  RealColumn get profitAndLossAbs => real()();
  RealColumn get profitAndLossRel => real()();
  RealColumn get tradingFee => real()();
  RealColumn get tax => real()();
  @ReferenceName('ClearingTrades')
  IntColumn get clearingAccountId => integer().references(Accounts, #id)();
  @ReferenceName('PortfolioTrades')
  IntColumn get portfolioAccountId => integer().references(Accounts, #id)();
}

@TableIndex(name: 'periodic_bookings_account_id', columns: {#accountId})
@TableIndex(name: 'periodic_bookings_next_execution_date', columns: {#nextExecutionDate})
@DataClassName('PeriodicBooking')
class PeriodicBookings extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get nextExecutionDate => integer()();
  RealColumn get amount => real()();
  IntColumn get accountId => integer().references(Accounts, #id)();
  TextColumn get category => text()();
  TextColumn get notes => text().nullable()();
  TextColumn get cycle => text().map(const CyclesConverter())();
}

@TableIndex(name: 'periodic_transfers_sending_account_id', columns: {#sendingAccountId})
@TableIndex(name: 'periodic_transfers_receiving_account_id', columns: {#receivingAccountId})
@TableIndex(name: 'periodic_transfers_next_execution_date', columns: {#nextExecutionDate})
@DataClassName('PeriodicTransfer')
class PeriodicTransfers extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get nextExecutionDate => integer()();
  RealColumn get amount => real()();
  @ReferenceName('SendingPeriodicTransfers')
  IntColumn get sendingAccountId => integer().references(Accounts, #id)();
  @ReferenceName('ReceivingPeriodicTransfers')
  IntColumn get receivingAccountId => integer().references(Accounts, #id)();
  TextColumn get notes => text().nullable()();
  TextColumn get cycle => text().map(const CyclesConverter())();
}

@DataClassName('AssetOnAccount')
class AssetsOnAccounts extends Table {
  IntColumn get accountId => integer().references(Accounts, #id)();
  IntColumn get assetId => integer().references(Assets, #id)();
  RealColumn get value => real()();
  RealColumn get sharesOwned => real()();
  RealColumn get netCostBasis => real()();
  RealColumn get brokerCostBasis => real()();
  RealColumn get buyFeeTotal => real()();

  @override
  Set<Column> get primaryKey => {accountId, assetId};
}

@TableIndex(name: 'goals_account_id', columns: {#accountId})
@TableIndex(name: 'goals_target_date', columns: {#targetDate})
@DataClassName('Goal')
class Goals extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get accountId => integer().nullable().references(Accounts, #id)();
  IntColumn get createdOn => integer()();
  IntColumn get targetDate => integer()();
  RealColumn get targetAmount => real()();
}