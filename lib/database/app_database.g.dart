// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $AccountsTable extends Accounts with TableInfo<$AccountsTable, Account> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AccountsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _balanceMeta =
      const VerificationMeta('balance');
  @override
  late final GeneratedColumn<double> balance = GeneratedColumn<double>(
      'balance', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _initialBalanceMeta =
      const VerificationMeta('initialBalance');
  @override
  late final GeneratedColumn<double> initialBalance = GeneratedColumn<double>(
      'initial_balance', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  late final GeneratedColumnWithTypeConverter<AccountTypes, String> type =
      GeneratedColumn<String>('type', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<AccountTypes>($AccountsTable.$convertertype);
  static const VerificationMeta _isArchivedMeta =
      const VerificationMeta('isArchived');
  @override
  late final GeneratedColumn<bool> isArchived = GeneratedColumn<bool>(
      'is_archived', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_archived" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns =>
      [id, name, balance, initialBalance, type, isArchived];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'accounts';
  @override
  VerificationContext validateIntegrity(Insertable<Account> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('balance')) {
      context.handle(_balanceMeta,
          balance.isAcceptableOrUnknown(data['balance']!, _balanceMeta));
    }
    if (data.containsKey('initial_balance')) {
      context.handle(
          _initialBalanceMeta,
          initialBalance.isAcceptableOrUnknown(
              data['initial_balance']!, _initialBalanceMeta));
    }
    if (data.containsKey('is_archived')) {
      context.handle(
          _isArchivedMeta,
          isArchived.isAcceptableOrUnknown(
              data['is_archived']!, _isArchivedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Account map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Account(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      balance: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}balance'])!,
      initialBalance: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}initial_balance'])!,
      type: $AccountsTable.$convertertype.fromSql(attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!),
      isArchived: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_archived'])!,
    );
  }

  @override
  $AccountsTable createAlias(String alias) {
    return $AccountsTable(attachedDatabase, alias);
  }

  static TypeConverter<AccountTypes, String> $convertertype =
      const AccountTypesConverter();
}

class Account extends DataClass implements Insertable<Account> {
  final int id;
  final String name;
  final double balance;
  final double initialBalance;
  final AccountTypes type;
  final bool isArchived;
  const Account(
      {required this.id,
      required this.name,
      required this.balance,
      required this.initialBalance,
      required this.type,
      required this.isArchived});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['balance'] = Variable<double>(balance);
    map['initial_balance'] = Variable<double>(initialBalance);
    {
      map['type'] = Variable<String>($AccountsTable.$convertertype.toSql(type));
    }
    map['is_archived'] = Variable<bool>(isArchived);
    return map;
  }

  AccountsCompanion toCompanion(bool nullToAbsent) {
    return AccountsCompanion(
      id: Value(id),
      name: Value(name),
      balance: Value(balance),
      initialBalance: Value(initialBalance),
      type: Value(type),
      isArchived: Value(isArchived),
    );
  }

  factory Account.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Account(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      balance: serializer.fromJson<double>(json['balance']),
      initialBalance: serializer.fromJson<double>(json['initialBalance']),
      type: serializer.fromJson<AccountTypes>(json['type']),
      isArchived: serializer.fromJson<bool>(json['isArchived']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'balance': serializer.toJson<double>(balance),
      'initialBalance': serializer.toJson<double>(initialBalance),
      'type': serializer.toJson<AccountTypes>(type),
      'isArchived': serializer.toJson<bool>(isArchived),
    };
  }

  Account copyWith(
          {int? id,
          String? name,
          double? balance,
          double? initialBalance,
          AccountTypes? type,
          bool? isArchived}) =>
      Account(
        id: id ?? this.id,
        name: name ?? this.name,
        balance: balance ?? this.balance,
        initialBalance: initialBalance ?? this.initialBalance,
        type: type ?? this.type,
        isArchived: isArchived ?? this.isArchived,
      );
  Account copyWithCompanion(AccountsCompanion data) {
    return Account(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      balance: data.balance.present ? data.balance.value : this.balance,
      initialBalance: data.initialBalance.present
          ? data.initialBalance.value
          : this.initialBalance,
      type: data.type.present ? data.type.value : this.type,
      isArchived:
          data.isArchived.present ? data.isArchived.value : this.isArchived,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Account(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('balance: $balance, ')
          ..write('initialBalance: $initialBalance, ')
          ..write('type: $type, ')
          ..write('isArchived: $isArchived')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, balance, initialBalance, type, isArchived);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Account &&
          other.id == this.id &&
          other.name == this.name &&
          other.balance == this.balance &&
          other.initialBalance == this.initialBalance &&
          other.type == this.type &&
          other.isArchived == this.isArchived);
}

class AccountsCompanion extends UpdateCompanion<Account> {
  final Value<int> id;
  final Value<String> name;
  final Value<double> balance;
  final Value<double> initialBalance;
  final Value<AccountTypes> type;
  final Value<bool> isArchived;
  const AccountsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.balance = const Value.absent(),
    this.initialBalance = const Value.absent(),
    this.type = const Value.absent(),
    this.isArchived = const Value.absent(),
  });
  AccountsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.balance = const Value.absent(),
    this.initialBalance = const Value.absent(),
    required AccountTypes type,
    this.isArchived = const Value.absent(),
  })  : name = Value(name),
        type = Value(type);
  static Insertable<Account> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<double>? balance,
    Expression<double>? initialBalance,
    Expression<String>? type,
    Expression<bool>? isArchived,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (balance != null) 'balance': balance,
      if (initialBalance != null) 'initial_balance': initialBalance,
      if (type != null) 'type': type,
      if (isArchived != null) 'is_archived': isArchived,
    });
  }

  AccountsCompanion copyWith(
      {Value<int>? id,
      Value<String>? name,
      Value<double>? balance,
      Value<double>? initialBalance,
      Value<AccountTypes>? type,
      Value<bool>? isArchived}) {
    return AccountsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      balance: balance ?? this.balance,
      initialBalance: initialBalance ?? this.initialBalance,
      type: type ?? this.type,
      isArchived: isArchived ?? this.isArchived,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (balance.present) {
      map['balance'] = Variable<double>(balance.value);
    }
    if (initialBalance.present) {
      map['initial_balance'] = Variable<double>(initialBalance.value);
    }
    if (type.present) {
      map['type'] =
          Variable<String>($AccountsTable.$convertertype.toSql(type.value));
    }
    if (isArchived.present) {
      map['is_archived'] = Variable<bool>(isArchived.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AccountsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('balance: $balance, ')
          ..write('initialBalance: $initialBalance, ')
          ..write('type: $type, ')
          ..write('isArchived: $isArchived')
          ..write(')'))
        .toString();
  }
}

class $AssetsTable extends Assets with TableInfo<$AssetsTable, Asset> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AssetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  @override
  late final GeneratedColumnWithTypeConverter<AssetTypes, String> type =
      GeneratedColumn<String>('type', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<AssetTypes>($AssetsTable.$convertertype);
  static const VerificationMeta _tickerSymbolMeta =
      const VerificationMeta('tickerSymbol');
  @override
  late final GeneratedColumn<String> tickerSymbol = GeneratedColumn<String>(
      'ticker_symbol', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _currencySymbolMeta =
      const VerificationMeta('currencySymbol');
  @override
  late final GeneratedColumn<String> currencySymbol = GeneratedColumn<String>(
      'currency_symbol', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(null));
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<double> value = GeneratedColumn<double>(
      'value', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _sharesMeta = const VerificationMeta('shares');
  @override
  late final GeneratedColumn<double> shares = GeneratedColumn<double>(
      'shares', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _netCostBasisMeta =
      const VerificationMeta('netCostBasis');
  @override
  late final GeneratedColumn<double> netCostBasis = GeneratedColumn<double>(
      'net_cost_basis', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _brokerCostBasisMeta =
      const VerificationMeta('brokerCostBasis');
  @override
  late final GeneratedColumn<double> brokerCostBasis = GeneratedColumn<double>(
      'broker_cost_basis', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _buyFeeTotalMeta =
      const VerificationMeta('buyFeeTotal');
  @override
  late final GeneratedColumn<double> buyFeeTotal = GeneratedColumn<double>(
      'buy_fee_total', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _isArchivedMeta =
      const VerificationMeta('isArchived');
  @override
  late final GeneratedColumn<bool> isArchived = GeneratedColumn<bool>(
      'is_archived', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_archived" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        type,
        tickerSymbol,
        currencySymbol,
        value,
        shares,
        netCostBasis,
        brokerCostBasis,
        buyFeeTotal,
        isArchived
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'assets';
  @override
  VerificationContext validateIntegrity(Insertable<Asset> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('ticker_symbol')) {
      context.handle(
          _tickerSymbolMeta,
          tickerSymbol.isAcceptableOrUnknown(
              data['ticker_symbol']!, _tickerSymbolMeta));
    } else if (isInserting) {
      context.missing(_tickerSymbolMeta);
    }
    if (data.containsKey('currency_symbol')) {
      context.handle(
          _currencySymbolMeta,
          currencySymbol.isAcceptableOrUnknown(
              data['currency_symbol']!, _currencySymbolMeta));
    }
    if (data.containsKey('value')) {
      context.handle(
          _valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    }
    if (data.containsKey('shares')) {
      context.handle(_sharesMeta,
          shares.isAcceptableOrUnknown(data['shares']!, _sharesMeta));
    }
    if (data.containsKey('net_cost_basis')) {
      context.handle(
          _netCostBasisMeta,
          netCostBasis.isAcceptableOrUnknown(
              data['net_cost_basis']!, _netCostBasisMeta));
    }
    if (data.containsKey('broker_cost_basis')) {
      context.handle(
          _brokerCostBasisMeta,
          brokerCostBasis.isAcceptableOrUnknown(
              data['broker_cost_basis']!, _brokerCostBasisMeta));
    }
    if (data.containsKey('buy_fee_total')) {
      context.handle(
          _buyFeeTotalMeta,
          buyFeeTotal.isAcceptableOrUnknown(
              data['buy_fee_total']!, _buyFeeTotalMeta));
    }
    if (data.containsKey('is_archived')) {
      context.handle(
          _isArchivedMeta,
          isArchived.isAcceptableOrUnknown(
              data['is_archived']!, _isArchivedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Asset map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Asset(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      type: $AssetsTable.$convertertype.fromSql(attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!),
      tickerSymbol: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}ticker_symbol'])!,
      currencySymbol: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}currency_symbol']),
      value: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}value'])!,
      shares: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}shares'])!,
      netCostBasis: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}net_cost_basis'])!,
      brokerCostBasis: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}broker_cost_basis'])!,
      buyFeeTotal: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}buy_fee_total'])!,
      isArchived: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_archived'])!,
    );
  }

  @override
  $AssetsTable createAlias(String alias) {
    return $AssetsTable(attachedDatabase, alias);
  }

  static TypeConverter<AssetTypes, String> $convertertype =
      const AssetTypesConverter();
}

class Asset extends DataClass implements Insertable<Asset> {
  final int id;
  final String name;
  final AssetTypes type;
  final String tickerSymbol;
  final String? currencySymbol;
  final double value;
  final double shares;
  final double netCostBasis;
  final double brokerCostBasis;
  final double buyFeeTotal;
  final bool isArchived;
  const Asset(
      {required this.id,
      required this.name,
      required this.type,
      required this.tickerSymbol,
      this.currencySymbol,
      required this.value,
      required this.shares,
      required this.netCostBasis,
      required this.brokerCostBasis,
      required this.buyFeeTotal,
      required this.isArchived});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    {
      map['type'] = Variable<String>($AssetsTable.$convertertype.toSql(type));
    }
    map['ticker_symbol'] = Variable<String>(tickerSymbol);
    if (!nullToAbsent || currencySymbol != null) {
      map['currency_symbol'] = Variable<String>(currencySymbol);
    }
    map['value'] = Variable<double>(value);
    map['shares'] = Variable<double>(shares);
    map['net_cost_basis'] = Variable<double>(netCostBasis);
    map['broker_cost_basis'] = Variable<double>(brokerCostBasis);
    map['buy_fee_total'] = Variable<double>(buyFeeTotal);
    map['is_archived'] = Variable<bool>(isArchived);
    return map;
  }

  AssetsCompanion toCompanion(bool nullToAbsent) {
    return AssetsCompanion(
      id: Value(id),
      name: Value(name),
      type: Value(type),
      tickerSymbol: Value(tickerSymbol),
      currencySymbol: currencySymbol == null && nullToAbsent
          ? const Value.absent()
          : Value(currencySymbol),
      value: Value(value),
      shares: Value(shares),
      netCostBasis: Value(netCostBasis),
      brokerCostBasis: Value(brokerCostBasis),
      buyFeeTotal: Value(buyFeeTotal),
      isArchived: Value(isArchived),
    );
  }

  factory Asset.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Asset(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      type: serializer.fromJson<AssetTypes>(json['type']),
      tickerSymbol: serializer.fromJson<String>(json['tickerSymbol']),
      currencySymbol: serializer.fromJson<String?>(json['currencySymbol']),
      value: serializer.fromJson<double>(json['value']),
      shares: serializer.fromJson<double>(json['shares']),
      netCostBasis: serializer.fromJson<double>(json['netCostBasis']),
      brokerCostBasis: serializer.fromJson<double>(json['brokerCostBasis']),
      buyFeeTotal: serializer.fromJson<double>(json['buyFeeTotal']),
      isArchived: serializer.fromJson<bool>(json['isArchived']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'type': serializer.toJson<AssetTypes>(type),
      'tickerSymbol': serializer.toJson<String>(tickerSymbol),
      'currencySymbol': serializer.toJson<String?>(currencySymbol),
      'value': serializer.toJson<double>(value),
      'shares': serializer.toJson<double>(shares),
      'netCostBasis': serializer.toJson<double>(netCostBasis),
      'brokerCostBasis': serializer.toJson<double>(brokerCostBasis),
      'buyFeeTotal': serializer.toJson<double>(buyFeeTotal),
      'isArchived': serializer.toJson<bool>(isArchived),
    };
  }

  Asset copyWith(
          {int? id,
          String? name,
          AssetTypes? type,
          String? tickerSymbol,
          Value<String?> currencySymbol = const Value.absent(),
          double? value,
          double? shares,
          double? netCostBasis,
          double? brokerCostBasis,
          double? buyFeeTotal,
          bool? isArchived}) =>
      Asset(
        id: id ?? this.id,
        name: name ?? this.name,
        type: type ?? this.type,
        tickerSymbol: tickerSymbol ?? this.tickerSymbol,
        currencySymbol:
            currencySymbol.present ? currencySymbol.value : this.currencySymbol,
        value: value ?? this.value,
        shares: shares ?? this.shares,
        netCostBasis: netCostBasis ?? this.netCostBasis,
        brokerCostBasis: brokerCostBasis ?? this.brokerCostBasis,
        buyFeeTotal: buyFeeTotal ?? this.buyFeeTotal,
        isArchived: isArchived ?? this.isArchived,
      );
  Asset copyWithCompanion(AssetsCompanion data) {
    return Asset(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      type: data.type.present ? data.type.value : this.type,
      tickerSymbol: data.tickerSymbol.present
          ? data.tickerSymbol.value
          : this.tickerSymbol,
      currencySymbol: data.currencySymbol.present
          ? data.currencySymbol.value
          : this.currencySymbol,
      value: data.value.present ? data.value.value : this.value,
      shares: data.shares.present ? data.shares.value : this.shares,
      netCostBasis: data.netCostBasis.present
          ? data.netCostBasis.value
          : this.netCostBasis,
      brokerCostBasis: data.brokerCostBasis.present
          ? data.brokerCostBasis.value
          : this.brokerCostBasis,
      buyFeeTotal:
          data.buyFeeTotal.present ? data.buyFeeTotal.value : this.buyFeeTotal,
      isArchived:
          data.isArchived.present ? data.isArchived.value : this.isArchived,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Asset(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('tickerSymbol: $tickerSymbol, ')
          ..write('currencySymbol: $currencySymbol, ')
          ..write('value: $value, ')
          ..write('shares: $shares, ')
          ..write('netCostBasis: $netCostBasis, ')
          ..write('brokerCostBasis: $brokerCostBasis, ')
          ..write('buyFeeTotal: $buyFeeTotal, ')
          ..write('isArchived: $isArchived')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, type, tickerSymbol, currencySymbol,
      value, shares, netCostBasis, brokerCostBasis, buyFeeTotal, isArchived);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Asset &&
          other.id == this.id &&
          other.name == this.name &&
          other.type == this.type &&
          other.tickerSymbol == this.tickerSymbol &&
          other.currencySymbol == this.currencySymbol &&
          other.value == this.value &&
          other.shares == this.shares &&
          other.netCostBasis == this.netCostBasis &&
          other.brokerCostBasis == this.brokerCostBasis &&
          other.buyFeeTotal == this.buyFeeTotal &&
          other.isArchived == this.isArchived);
}

class AssetsCompanion extends UpdateCompanion<Asset> {
  final Value<int> id;
  final Value<String> name;
  final Value<AssetTypes> type;
  final Value<String> tickerSymbol;
  final Value<String?> currencySymbol;
  final Value<double> value;
  final Value<double> shares;
  final Value<double> netCostBasis;
  final Value<double> brokerCostBasis;
  final Value<double> buyFeeTotal;
  final Value<bool> isArchived;
  const AssetsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.tickerSymbol = const Value.absent(),
    this.currencySymbol = const Value.absent(),
    this.value = const Value.absent(),
    this.shares = const Value.absent(),
    this.netCostBasis = const Value.absent(),
    this.brokerCostBasis = const Value.absent(),
    this.buyFeeTotal = const Value.absent(),
    this.isArchived = const Value.absent(),
  });
  AssetsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required AssetTypes type,
    required String tickerSymbol,
    this.currencySymbol = const Value.absent(),
    this.value = const Value.absent(),
    this.shares = const Value.absent(),
    this.netCostBasis = const Value.absent(),
    this.brokerCostBasis = const Value.absent(),
    this.buyFeeTotal = const Value.absent(),
    this.isArchived = const Value.absent(),
  })  : name = Value(name),
        type = Value(type),
        tickerSymbol = Value(tickerSymbol);
  static Insertable<Asset> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? type,
    Expression<String>? tickerSymbol,
    Expression<String>? currencySymbol,
    Expression<double>? value,
    Expression<double>? shares,
    Expression<double>? netCostBasis,
    Expression<double>? brokerCostBasis,
    Expression<double>? buyFeeTotal,
    Expression<bool>? isArchived,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (tickerSymbol != null) 'ticker_symbol': tickerSymbol,
      if (currencySymbol != null) 'currency_symbol': currencySymbol,
      if (value != null) 'value': value,
      if (shares != null) 'shares': shares,
      if (netCostBasis != null) 'net_cost_basis': netCostBasis,
      if (brokerCostBasis != null) 'broker_cost_basis': brokerCostBasis,
      if (buyFeeTotal != null) 'buy_fee_total': buyFeeTotal,
      if (isArchived != null) 'is_archived': isArchived,
    });
  }

  AssetsCompanion copyWith(
      {Value<int>? id,
      Value<String>? name,
      Value<AssetTypes>? type,
      Value<String>? tickerSymbol,
      Value<String?>? currencySymbol,
      Value<double>? value,
      Value<double>? shares,
      Value<double>? netCostBasis,
      Value<double>? brokerCostBasis,
      Value<double>? buyFeeTotal,
      Value<bool>? isArchived}) {
    return AssetsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      tickerSymbol: tickerSymbol ?? this.tickerSymbol,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      value: value ?? this.value,
      shares: shares ?? this.shares,
      netCostBasis: netCostBasis ?? this.netCostBasis,
      brokerCostBasis: brokerCostBasis ?? this.brokerCostBasis,
      buyFeeTotal: buyFeeTotal ?? this.buyFeeTotal,
      isArchived: isArchived ?? this.isArchived,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (type.present) {
      map['type'] =
          Variable<String>($AssetsTable.$convertertype.toSql(type.value));
    }
    if (tickerSymbol.present) {
      map['ticker_symbol'] = Variable<String>(tickerSymbol.value);
    }
    if (currencySymbol.present) {
      map['currency_symbol'] = Variable<String>(currencySymbol.value);
    }
    if (value.present) {
      map['value'] = Variable<double>(value.value);
    }
    if (shares.present) {
      map['shares'] = Variable<double>(shares.value);
    }
    if (netCostBasis.present) {
      map['net_cost_basis'] = Variable<double>(netCostBasis.value);
    }
    if (brokerCostBasis.present) {
      map['broker_cost_basis'] = Variable<double>(brokerCostBasis.value);
    }
    if (buyFeeTotal.present) {
      map['buy_fee_total'] = Variable<double>(buyFeeTotal.value);
    }
    if (isArchived.present) {
      map['is_archived'] = Variable<bool>(isArchived.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AssetsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('tickerSymbol: $tickerSymbol, ')
          ..write('currencySymbol: $currencySymbol, ')
          ..write('value: $value, ')
          ..write('shares: $shares, ')
          ..write('netCostBasis: $netCostBasis, ')
          ..write('brokerCostBasis: $brokerCostBasis, ')
          ..write('buyFeeTotal: $buyFeeTotal, ')
          ..write('isArchived: $isArchived')
          ..write(')'))
        .toString();
  }
}

class $BookingsTable extends Bookings with TableInfo<$BookingsTable, Booking> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BookingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<int> date = GeneratedColumn<int>(
      'date', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _assetIdMeta =
      const VerificationMeta('assetId');
  @override
  late final GeneratedColumn<int> assetId = GeneratedColumn<int>(
      'asset_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES assets (id)'),
      defaultValue: const Constant(1));
  static const VerificationMeta _accountIdMeta =
      const VerificationMeta('accountId');
  @override
  late final GeneratedColumn<int> accountId = GeneratedColumn<int>(
      'account_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES accounts (id)'));
  static const VerificationMeta _categoryMeta =
      const VerificationMeta('category');
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
      'category', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sharesMeta = const VerificationMeta('shares');
  @override
  late final GeneratedColumn<double> shares = GeneratedColumn<double>(
      'shares', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _costBasisMeta =
      const VerificationMeta('costBasis');
  @override
  late final GeneratedColumn<double> costBasis = GeneratedColumn<double>(
      'cost_basis', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<double> value = GeneratedColumn<double>(
      'value', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _excludeFromAverageMeta =
      const VerificationMeta('excludeFromAverage');
  @override
  late final GeneratedColumn<bool> excludeFromAverage = GeneratedColumn<bool>(
      'exclude_from_average', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("exclude_from_average" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _isGeneratedMeta =
      const VerificationMeta('isGenerated');
  @override
  late final GeneratedColumn<bool> isGenerated = GeneratedColumn<bool>(
      'is_generated', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_generated" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        date,
        assetId,
        accountId,
        category,
        shares,
        costBasis,
        value,
        notes,
        excludeFromAverage,
        isGenerated
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'bookings';
  @override
  VerificationContext validateIntegrity(Insertable<Booking> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('date')) {
      context.handle(
          _dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('asset_id')) {
      context.handle(_assetIdMeta,
          assetId.isAcceptableOrUnknown(data['asset_id']!, _assetIdMeta));
    }
    if (data.containsKey('account_id')) {
      context.handle(_accountIdMeta,
          accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta));
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('category')) {
      context.handle(_categoryMeta,
          category.isAcceptableOrUnknown(data['category']!, _categoryMeta));
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('shares')) {
      context.handle(_sharesMeta,
          shares.isAcceptableOrUnknown(data['shares']!, _sharesMeta));
    } else if (isInserting) {
      context.missing(_sharesMeta);
    }
    if (data.containsKey('cost_basis')) {
      context.handle(_costBasisMeta,
          costBasis.isAcceptableOrUnknown(data['cost_basis']!, _costBasisMeta));
    }
    if (data.containsKey('value')) {
      context.handle(
          _valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('exclude_from_average')) {
      context.handle(
          _excludeFromAverageMeta,
          excludeFromAverage.isAcceptableOrUnknown(
              data['exclude_from_average']!, _excludeFromAverageMeta));
    }
    if (data.containsKey('is_generated')) {
      context.handle(
          _isGeneratedMeta,
          isGenerated.isAcceptableOrUnknown(
              data['is_generated']!, _isGeneratedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Booking map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Booking(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      date: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}date'])!,
      assetId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}asset_id'])!,
      accountId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}account_id'])!,
      category: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category'])!,
      shares: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}shares'])!,
      costBasis: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}cost_basis'])!,
      value: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}value'])!,
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
      excludeFromAverage: attachedDatabase.typeMapping.read(
          DriftSqlType.bool, data['${effectivePrefix}exclude_from_average'])!,
      isGenerated: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_generated'])!,
    );
  }

  @override
  $BookingsTable createAlias(String alias) {
    return $BookingsTable(attachedDatabase, alias);
  }
}

class Booking extends DataClass implements Insertable<Booking> {
  final int id;
  final int date;
  final int assetId;
  final int accountId;
  final String category;
  final double shares;
  final double costBasis;
  final double value;
  final String? notes;
  final bool excludeFromAverage;
  final bool isGenerated;
  const Booking(
      {required this.id,
      required this.date,
      required this.assetId,
      required this.accountId,
      required this.category,
      required this.shares,
      required this.costBasis,
      required this.value,
      this.notes,
      required this.excludeFromAverage,
      required this.isGenerated});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['date'] = Variable<int>(date);
    map['asset_id'] = Variable<int>(assetId);
    map['account_id'] = Variable<int>(accountId);
    map['category'] = Variable<String>(category);
    map['shares'] = Variable<double>(shares);
    map['cost_basis'] = Variable<double>(costBasis);
    map['value'] = Variable<double>(value);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['exclude_from_average'] = Variable<bool>(excludeFromAverage);
    map['is_generated'] = Variable<bool>(isGenerated);
    return map;
  }

  BookingsCompanion toCompanion(bool nullToAbsent) {
    return BookingsCompanion(
      id: Value(id),
      date: Value(date),
      assetId: Value(assetId),
      accountId: Value(accountId),
      category: Value(category),
      shares: Value(shares),
      costBasis: Value(costBasis),
      value: Value(value),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      excludeFromAverage: Value(excludeFromAverage),
      isGenerated: Value(isGenerated),
    );
  }

  factory Booking.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Booking(
      id: serializer.fromJson<int>(json['id']),
      date: serializer.fromJson<int>(json['date']),
      assetId: serializer.fromJson<int>(json['assetId']),
      accountId: serializer.fromJson<int>(json['accountId']),
      category: serializer.fromJson<String>(json['category']),
      shares: serializer.fromJson<double>(json['shares']),
      costBasis: serializer.fromJson<double>(json['costBasis']),
      value: serializer.fromJson<double>(json['value']),
      notes: serializer.fromJson<String?>(json['notes']),
      excludeFromAverage: serializer.fromJson<bool>(json['excludeFromAverage']),
      isGenerated: serializer.fromJson<bool>(json['isGenerated']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'date': serializer.toJson<int>(date),
      'assetId': serializer.toJson<int>(assetId),
      'accountId': serializer.toJson<int>(accountId),
      'category': serializer.toJson<String>(category),
      'shares': serializer.toJson<double>(shares),
      'costBasis': serializer.toJson<double>(costBasis),
      'value': serializer.toJson<double>(value),
      'notes': serializer.toJson<String?>(notes),
      'excludeFromAverage': serializer.toJson<bool>(excludeFromAverage),
      'isGenerated': serializer.toJson<bool>(isGenerated),
    };
  }

  Booking copyWith(
          {int? id,
          int? date,
          int? assetId,
          int? accountId,
          String? category,
          double? shares,
          double? costBasis,
          double? value,
          Value<String?> notes = const Value.absent(),
          bool? excludeFromAverage,
          bool? isGenerated}) =>
      Booking(
        id: id ?? this.id,
        date: date ?? this.date,
        assetId: assetId ?? this.assetId,
        accountId: accountId ?? this.accountId,
        category: category ?? this.category,
        shares: shares ?? this.shares,
        costBasis: costBasis ?? this.costBasis,
        value: value ?? this.value,
        notes: notes.present ? notes.value : this.notes,
        excludeFromAverage: excludeFromAverage ?? this.excludeFromAverage,
        isGenerated: isGenerated ?? this.isGenerated,
      );
  Booking copyWithCompanion(BookingsCompanion data) {
    return Booking(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
      assetId: data.assetId.present ? data.assetId.value : this.assetId,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      category: data.category.present ? data.category.value : this.category,
      shares: data.shares.present ? data.shares.value : this.shares,
      costBasis: data.costBasis.present ? data.costBasis.value : this.costBasis,
      value: data.value.present ? data.value.value : this.value,
      notes: data.notes.present ? data.notes.value : this.notes,
      excludeFromAverage: data.excludeFromAverage.present
          ? data.excludeFromAverage.value
          : this.excludeFromAverage,
      isGenerated:
          data.isGenerated.present ? data.isGenerated.value : this.isGenerated,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Booking(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('assetId: $assetId, ')
          ..write('accountId: $accountId, ')
          ..write('category: $category, ')
          ..write('shares: $shares, ')
          ..write('costBasis: $costBasis, ')
          ..write('value: $value, ')
          ..write('notes: $notes, ')
          ..write('excludeFromAverage: $excludeFromAverage, ')
          ..write('isGenerated: $isGenerated')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, date, assetId, accountId, category,
      shares, costBasis, value, notes, excludeFromAverage, isGenerated);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Booking &&
          other.id == this.id &&
          other.date == this.date &&
          other.assetId == this.assetId &&
          other.accountId == this.accountId &&
          other.category == this.category &&
          other.shares == this.shares &&
          other.costBasis == this.costBasis &&
          other.value == this.value &&
          other.notes == this.notes &&
          other.excludeFromAverage == this.excludeFromAverage &&
          other.isGenerated == this.isGenerated);
}

class BookingsCompanion extends UpdateCompanion<Booking> {
  final Value<int> id;
  final Value<int> date;
  final Value<int> assetId;
  final Value<int> accountId;
  final Value<String> category;
  final Value<double> shares;
  final Value<double> costBasis;
  final Value<double> value;
  final Value<String?> notes;
  final Value<bool> excludeFromAverage;
  final Value<bool> isGenerated;
  const BookingsCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.assetId = const Value.absent(),
    this.accountId = const Value.absent(),
    this.category = const Value.absent(),
    this.shares = const Value.absent(),
    this.costBasis = const Value.absent(),
    this.value = const Value.absent(),
    this.notes = const Value.absent(),
    this.excludeFromAverage = const Value.absent(),
    this.isGenerated = const Value.absent(),
  });
  BookingsCompanion.insert({
    this.id = const Value.absent(),
    required int date,
    this.assetId = const Value.absent(),
    required int accountId,
    required String category,
    required double shares,
    this.costBasis = const Value.absent(),
    required double value,
    this.notes = const Value.absent(),
    this.excludeFromAverage = const Value.absent(),
    this.isGenerated = const Value.absent(),
  })  : date = Value(date),
        accountId = Value(accountId),
        category = Value(category),
        shares = Value(shares),
        value = Value(value);
  static Insertable<Booking> custom({
    Expression<int>? id,
    Expression<int>? date,
    Expression<int>? assetId,
    Expression<int>? accountId,
    Expression<String>? category,
    Expression<double>? shares,
    Expression<double>? costBasis,
    Expression<double>? value,
    Expression<String>? notes,
    Expression<bool>? excludeFromAverage,
    Expression<bool>? isGenerated,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (assetId != null) 'asset_id': assetId,
      if (accountId != null) 'account_id': accountId,
      if (category != null) 'category': category,
      if (shares != null) 'shares': shares,
      if (costBasis != null) 'cost_basis': costBasis,
      if (value != null) 'value': value,
      if (notes != null) 'notes': notes,
      if (excludeFromAverage != null)
        'exclude_from_average': excludeFromAverage,
      if (isGenerated != null) 'is_generated': isGenerated,
    });
  }

  BookingsCompanion copyWith(
      {Value<int>? id,
      Value<int>? date,
      Value<int>? assetId,
      Value<int>? accountId,
      Value<String>? category,
      Value<double>? shares,
      Value<double>? costBasis,
      Value<double>? value,
      Value<String?>? notes,
      Value<bool>? excludeFromAverage,
      Value<bool>? isGenerated}) {
    return BookingsCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      assetId: assetId ?? this.assetId,
      accountId: accountId ?? this.accountId,
      category: category ?? this.category,
      shares: shares ?? this.shares,
      costBasis: costBasis ?? this.costBasis,
      value: value ?? this.value,
      notes: notes ?? this.notes,
      excludeFromAverage: excludeFromAverage ?? this.excludeFromAverage,
      isGenerated: isGenerated ?? this.isGenerated,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (date.present) {
      map['date'] = Variable<int>(date.value);
    }
    if (assetId.present) {
      map['asset_id'] = Variable<int>(assetId.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<int>(accountId.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (shares.present) {
      map['shares'] = Variable<double>(shares.value);
    }
    if (costBasis.present) {
      map['cost_basis'] = Variable<double>(costBasis.value);
    }
    if (value.present) {
      map['value'] = Variable<double>(value.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (excludeFromAverage.present) {
      map['exclude_from_average'] = Variable<bool>(excludeFromAverage.value);
    }
    if (isGenerated.present) {
      map['is_generated'] = Variable<bool>(isGenerated.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BookingsCompanion(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('assetId: $assetId, ')
          ..write('accountId: $accountId, ')
          ..write('category: $category, ')
          ..write('shares: $shares, ')
          ..write('costBasis: $costBasis, ')
          ..write('value: $value, ')
          ..write('notes: $notes, ')
          ..write('excludeFromAverage: $excludeFromAverage, ')
          ..write('isGenerated: $isGenerated')
          ..write(')'))
        .toString();
  }
}

class $TransfersTable extends Transfers
    with TableInfo<$TransfersTable, Transfer> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransfersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<int> date = GeneratedColumn<int>(
      'date', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _sendingAccountIdMeta =
      const VerificationMeta('sendingAccountId');
  @override
  late final GeneratedColumn<int> sendingAccountId = GeneratedColumn<int>(
      'sending_account_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES accounts (id)'));
  static const VerificationMeta _receivingAccountIdMeta =
      const VerificationMeta('receivingAccountId');
  @override
  late final GeneratedColumn<int> receivingAccountId = GeneratedColumn<int>(
      'receiving_account_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES accounts (id)'));
  static const VerificationMeta _assetIdMeta =
      const VerificationMeta('assetId');
  @override
  late final GeneratedColumn<int> assetId = GeneratedColumn<int>(
      'asset_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES assets (id)'),
      defaultValue: const Constant(1));
  static const VerificationMeta _sharesMeta = const VerificationMeta('shares');
  @override
  late final GeneratedColumn<double> shares = GeneratedColumn<double>(
      'shares', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _costBasisMeta =
      const VerificationMeta('costBasis');
  @override
  late final GeneratedColumn<double> costBasis = GeneratedColumn<double>(
      'cost_basis', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<double> value = GeneratedColumn<double>(
      'value', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isGeneratedMeta =
      const VerificationMeta('isGenerated');
  @override
  late final GeneratedColumn<bool> isGenerated = GeneratedColumn<bool>(
      'is_generated', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_generated" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        date,
        sendingAccountId,
        receivingAccountId,
        assetId,
        shares,
        costBasis,
        value,
        notes,
        isGenerated
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transfers';
  @override
  VerificationContext validateIntegrity(Insertable<Transfer> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('date')) {
      context.handle(
          _dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('sending_account_id')) {
      context.handle(
          _sendingAccountIdMeta,
          sendingAccountId.isAcceptableOrUnknown(
              data['sending_account_id']!, _sendingAccountIdMeta));
    } else if (isInserting) {
      context.missing(_sendingAccountIdMeta);
    }
    if (data.containsKey('receiving_account_id')) {
      context.handle(
          _receivingAccountIdMeta,
          receivingAccountId.isAcceptableOrUnknown(
              data['receiving_account_id']!, _receivingAccountIdMeta));
    } else if (isInserting) {
      context.missing(_receivingAccountIdMeta);
    }
    if (data.containsKey('asset_id')) {
      context.handle(_assetIdMeta,
          assetId.isAcceptableOrUnknown(data['asset_id']!, _assetIdMeta));
    }
    if (data.containsKey('shares')) {
      context.handle(_sharesMeta,
          shares.isAcceptableOrUnknown(data['shares']!, _sharesMeta));
    } else if (isInserting) {
      context.missing(_sharesMeta);
    }
    if (data.containsKey('cost_basis')) {
      context.handle(_costBasisMeta,
          costBasis.isAcceptableOrUnknown(data['cost_basis']!, _costBasisMeta));
    }
    if (data.containsKey('value')) {
      context.handle(
          _valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('is_generated')) {
      context.handle(
          _isGeneratedMeta,
          isGenerated.isAcceptableOrUnknown(
              data['is_generated']!, _isGeneratedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Transfer map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Transfer(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      date: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}date'])!,
      sendingAccountId: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}sending_account_id'])!,
      receivingAccountId: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}receiving_account_id'])!,
      assetId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}asset_id'])!,
      shares: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}shares'])!,
      costBasis: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}cost_basis'])!,
      value: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}value'])!,
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
      isGenerated: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_generated'])!,
    );
  }

  @override
  $TransfersTable createAlias(String alias) {
    return $TransfersTable(attachedDatabase, alias);
  }
}

class Transfer extends DataClass implements Insertable<Transfer> {
  final int id;
  final int date;
  final int sendingAccountId;
  final int receivingAccountId;
  final int assetId;
  final double shares;
  final double costBasis;
  final double value;
  final String? notes;
  final bool isGenerated;
  const Transfer(
      {required this.id,
      required this.date,
      required this.sendingAccountId,
      required this.receivingAccountId,
      required this.assetId,
      required this.shares,
      required this.costBasis,
      required this.value,
      this.notes,
      required this.isGenerated});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['date'] = Variable<int>(date);
    map['sending_account_id'] = Variable<int>(sendingAccountId);
    map['receiving_account_id'] = Variable<int>(receivingAccountId);
    map['asset_id'] = Variable<int>(assetId);
    map['shares'] = Variable<double>(shares);
    map['cost_basis'] = Variable<double>(costBasis);
    map['value'] = Variable<double>(value);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['is_generated'] = Variable<bool>(isGenerated);
    return map;
  }

  TransfersCompanion toCompanion(bool nullToAbsent) {
    return TransfersCompanion(
      id: Value(id),
      date: Value(date),
      sendingAccountId: Value(sendingAccountId),
      receivingAccountId: Value(receivingAccountId),
      assetId: Value(assetId),
      shares: Value(shares),
      costBasis: Value(costBasis),
      value: Value(value),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      isGenerated: Value(isGenerated),
    );
  }

  factory Transfer.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Transfer(
      id: serializer.fromJson<int>(json['id']),
      date: serializer.fromJson<int>(json['date']),
      sendingAccountId: serializer.fromJson<int>(json['sendingAccountId']),
      receivingAccountId: serializer.fromJson<int>(json['receivingAccountId']),
      assetId: serializer.fromJson<int>(json['assetId']),
      shares: serializer.fromJson<double>(json['shares']),
      costBasis: serializer.fromJson<double>(json['costBasis']),
      value: serializer.fromJson<double>(json['value']),
      notes: serializer.fromJson<String?>(json['notes']),
      isGenerated: serializer.fromJson<bool>(json['isGenerated']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'date': serializer.toJson<int>(date),
      'sendingAccountId': serializer.toJson<int>(sendingAccountId),
      'receivingAccountId': serializer.toJson<int>(receivingAccountId),
      'assetId': serializer.toJson<int>(assetId),
      'shares': serializer.toJson<double>(shares),
      'costBasis': serializer.toJson<double>(costBasis),
      'value': serializer.toJson<double>(value),
      'notes': serializer.toJson<String?>(notes),
      'isGenerated': serializer.toJson<bool>(isGenerated),
    };
  }

  Transfer copyWith(
          {int? id,
          int? date,
          int? sendingAccountId,
          int? receivingAccountId,
          int? assetId,
          double? shares,
          double? costBasis,
          double? value,
          Value<String?> notes = const Value.absent(),
          bool? isGenerated}) =>
      Transfer(
        id: id ?? this.id,
        date: date ?? this.date,
        sendingAccountId: sendingAccountId ?? this.sendingAccountId,
        receivingAccountId: receivingAccountId ?? this.receivingAccountId,
        assetId: assetId ?? this.assetId,
        shares: shares ?? this.shares,
        costBasis: costBasis ?? this.costBasis,
        value: value ?? this.value,
        notes: notes.present ? notes.value : this.notes,
        isGenerated: isGenerated ?? this.isGenerated,
      );
  Transfer copyWithCompanion(TransfersCompanion data) {
    return Transfer(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
      sendingAccountId: data.sendingAccountId.present
          ? data.sendingAccountId.value
          : this.sendingAccountId,
      receivingAccountId: data.receivingAccountId.present
          ? data.receivingAccountId.value
          : this.receivingAccountId,
      assetId: data.assetId.present ? data.assetId.value : this.assetId,
      shares: data.shares.present ? data.shares.value : this.shares,
      costBasis: data.costBasis.present ? data.costBasis.value : this.costBasis,
      value: data.value.present ? data.value.value : this.value,
      notes: data.notes.present ? data.notes.value : this.notes,
      isGenerated:
          data.isGenerated.present ? data.isGenerated.value : this.isGenerated,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Transfer(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('sendingAccountId: $sendingAccountId, ')
          ..write('receivingAccountId: $receivingAccountId, ')
          ..write('assetId: $assetId, ')
          ..write('shares: $shares, ')
          ..write('costBasis: $costBasis, ')
          ..write('value: $value, ')
          ..write('notes: $notes, ')
          ..write('isGenerated: $isGenerated')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      date,
      sendingAccountId,
      receivingAccountId,
      assetId,
      shares,
      costBasis,
      value,
      notes,
      isGenerated);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Transfer &&
          other.id == this.id &&
          other.date == this.date &&
          other.sendingAccountId == this.sendingAccountId &&
          other.receivingAccountId == this.receivingAccountId &&
          other.assetId == this.assetId &&
          other.shares == this.shares &&
          other.costBasis == this.costBasis &&
          other.value == this.value &&
          other.notes == this.notes &&
          other.isGenerated == this.isGenerated);
}

class TransfersCompanion extends UpdateCompanion<Transfer> {
  final Value<int> id;
  final Value<int> date;
  final Value<int> sendingAccountId;
  final Value<int> receivingAccountId;
  final Value<int> assetId;
  final Value<double> shares;
  final Value<double> costBasis;
  final Value<double> value;
  final Value<String?> notes;
  final Value<bool> isGenerated;
  const TransfersCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.sendingAccountId = const Value.absent(),
    this.receivingAccountId = const Value.absent(),
    this.assetId = const Value.absent(),
    this.shares = const Value.absent(),
    this.costBasis = const Value.absent(),
    this.value = const Value.absent(),
    this.notes = const Value.absent(),
    this.isGenerated = const Value.absent(),
  });
  TransfersCompanion.insert({
    this.id = const Value.absent(),
    required int date,
    required int sendingAccountId,
    required int receivingAccountId,
    this.assetId = const Value.absent(),
    required double shares,
    this.costBasis = const Value.absent(),
    required double value,
    this.notes = const Value.absent(),
    this.isGenerated = const Value.absent(),
  })  : date = Value(date),
        sendingAccountId = Value(sendingAccountId),
        receivingAccountId = Value(receivingAccountId),
        shares = Value(shares),
        value = Value(value);
  static Insertable<Transfer> custom({
    Expression<int>? id,
    Expression<int>? date,
    Expression<int>? sendingAccountId,
    Expression<int>? receivingAccountId,
    Expression<int>? assetId,
    Expression<double>? shares,
    Expression<double>? costBasis,
    Expression<double>? value,
    Expression<String>? notes,
    Expression<bool>? isGenerated,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (sendingAccountId != null) 'sending_account_id': sendingAccountId,
      if (receivingAccountId != null)
        'receiving_account_id': receivingAccountId,
      if (assetId != null) 'asset_id': assetId,
      if (shares != null) 'shares': shares,
      if (costBasis != null) 'cost_basis': costBasis,
      if (value != null) 'value': value,
      if (notes != null) 'notes': notes,
      if (isGenerated != null) 'is_generated': isGenerated,
    });
  }

  TransfersCompanion copyWith(
      {Value<int>? id,
      Value<int>? date,
      Value<int>? sendingAccountId,
      Value<int>? receivingAccountId,
      Value<int>? assetId,
      Value<double>? shares,
      Value<double>? costBasis,
      Value<double>? value,
      Value<String?>? notes,
      Value<bool>? isGenerated}) {
    return TransfersCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      sendingAccountId: sendingAccountId ?? this.sendingAccountId,
      receivingAccountId: receivingAccountId ?? this.receivingAccountId,
      assetId: assetId ?? this.assetId,
      shares: shares ?? this.shares,
      costBasis: costBasis ?? this.costBasis,
      value: value ?? this.value,
      notes: notes ?? this.notes,
      isGenerated: isGenerated ?? this.isGenerated,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (date.present) {
      map['date'] = Variable<int>(date.value);
    }
    if (sendingAccountId.present) {
      map['sending_account_id'] = Variable<int>(sendingAccountId.value);
    }
    if (receivingAccountId.present) {
      map['receiving_account_id'] = Variable<int>(receivingAccountId.value);
    }
    if (assetId.present) {
      map['asset_id'] = Variable<int>(assetId.value);
    }
    if (shares.present) {
      map['shares'] = Variable<double>(shares.value);
    }
    if (costBasis.present) {
      map['cost_basis'] = Variable<double>(costBasis.value);
    }
    if (value.present) {
      map['value'] = Variable<double>(value.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (isGenerated.present) {
      map['is_generated'] = Variable<bool>(isGenerated.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransfersCompanion(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('sendingAccountId: $sendingAccountId, ')
          ..write('receivingAccountId: $receivingAccountId, ')
          ..write('assetId: $assetId, ')
          ..write('shares: $shares, ')
          ..write('costBasis: $costBasis, ')
          ..write('value: $value, ')
          ..write('notes: $notes, ')
          ..write('isGenerated: $isGenerated')
          ..write(')'))
        .toString();
  }
}

class $TradesTable extends Trades with TableInfo<$TradesTable, Trade> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TradesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _datetimeMeta =
      const VerificationMeta('datetime');
  @override
  late final GeneratedColumn<int> datetime = GeneratedColumn<int>(
      'datetime', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  late final GeneratedColumnWithTypeConverter<TradeTypes, String> type =
      GeneratedColumn<String>('type', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<TradeTypes>($TradesTable.$convertertype);
  static const VerificationMeta _sourceAccountIdMeta =
      const VerificationMeta('sourceAccountId');
  @override
  late final GeneratedColumn<int> sourceAccountId = GeneratedColumn<int>(
      'source_account_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES accounts (id)'));
  static const VerificationMeta _targetAccountIdMeta =
      const VerificationMeta('targetAccountId');
  @override
  late final GeneratedColumn<int> targetAccountId = GeneratedColumn<int>(
      'target_account_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES accounts (id)'));
  static const VerificationMeta _assetIdMeta =
      const VerificationMeta('assetId');
  @override
  late final GeneratedColumn<int> assetId = GeneratedColumn<int>(
      'asset_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES assets (id)'));
  static const VerificationMeta _sharesMeta = const VerificationMeta('shares');
  @override
  late final GeneratedColumn<double> shares = GeneratedColumn<double>(
      'shares', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _costBasisMeta =
      const VerificationMeta('costBasis');
  @override
  late final GeneratedColumn<double> costBasis = GeneratedColumn<double>(
      'cost_basis', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _feeMeta = const VerificationMeta('fee');
  @override
  late final GeneratedColumn<double> fee = GeneratedColumn<double>(
      'fee', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _taxMeta = const VerificationMeta('tax');
  @override
  late final GeneratedColumn<double> tax = GeneratedColumn<double>(
      'tax', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _sourceAccountValueDeltaMeta =
      const VerificationMeta('sourceAccountValueDelta');
  @override
  late final GeneratedColumn<double> sourceAccountValueDelta =
      GeneratedColumn<double>('source_account_value_delta', aliasedName, false,
          type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _targetAccountValueDeltaMeta =
      const VerificationMeta('targetAccountValueDelta');
  @override
  late final GeneratedColumn<double> targetAccountValueDelta =
      GeneratedColumn<double>('target_account_value_delta', aliasedName, false,
          type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _profitAndLossMeta =
      const VerificationMeta('profitAndLoss');
  @override
  late final GeneratedColumn<double> profitAndLoss = GeneratedColumn<double>(
      'profit_and_loss', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _returnOnInvestMeta =
      const VerificationMeta('returnOnInvest');
  @override
  late final GeneratedColumn<double> returnOnInvest = GeneratedColumn<double>(
      'return_on_invest', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        datetime,
        type,
        sourceAccountId,
        targetAccountId,
        assetId,
        shares,
        costBasis,
        fee,
        tax,
        sourceAccountValueDelta,
        targetAccountValueDelta,
        profitAndLoss,
        returnOnInvest
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'trades';
  @override
  VerificationContext validateIntegrity(Insertable<Trade> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('datetime')) {
      context.handle(_datetimeMeta,
          datetime.isAcceptableOrUnknown(data['datetime']!, _datetimeMeta));
    } else if (isInserting) {
      context.missing(_datetimeMeta);
    }
    if (data.containsKey('source_account_id')) {
      context.handle(
          _sourceAccountIdMeta,
          sourceAccountId.isAcceptableOrUnknown(
              data['source_account_id']!, _sourceAccountIdMeta));
    } else if (isInserting) {
      context.missing(_sourceAccountIdMeta);
    }
    if (data.containsKey('target_account_id')) {
      context.handle(
          _targetAccountIdMeta,
          targetAccountId.isAcceptableOrUnknown(
              data['target_account_id']!, _targetAccountIdMeta));
    } else if (isInserting) {
      context.missing(_targetAccountIdMeta);
    }
    if (data.containsKey('asset_id')) {
      context.handle(_assetIdMeta,
          assetId.isAcceptableOrUnknown(data['asset_id']!, _assetIdMeta));
    } else if (isInserting) {
      context.missing(_assetIdMeta);
    }
    if (data.containsKey('shares')) {
      context.handle(_sharesMeta,
          shares.isAcceptableOrUnknown(data['shares']!, _sharesMeta));
    } else if (isInserting) {
      context.missing(_sharesMeta);
    }
    if (data.containsKey('cost_basis')) {
      context.handle(_costBasisMeta,
          costBasis.isAcceptableOrUnknown(data['cost_basis']!, _costBasisMeta));
    } else if (isInserting) {
      context.missing(_costBasisMeta);
    }
    if (data.containsKey('fee')) {
      context.handle(
          _feeMeta, fee.isAcceptableOrUnknown(data['fee']!, _feeMeta));
    }
    if (data.containsKey('tax')) {
      context.handle(
          _taxMeta, tax.isAcceptableOrUnknown(data['tax']!, _taxMeta));
    }
    if (data.containsKey('source_account_value_delta')) {
      context.handle(
          _sourceAccountValueDeltaMeta,
          sourceAccountValueDelta.isAcceptableOrUnknown(
              data['source_account_value_delta']!,
              _sourceAccountValueDeltaMeta));
    } else if (isInserting) {
      context.missing(_sourceAccountValueDeltaMeta);
    }
    if (data.containsKey('target_account_value_delta')) {
      context.handle(
          _targetAccountValueDeltaMeta,
          targetAccountValueDelta.isAcceptableOrUnknown(
              data['target_account_value_delta']!,
              _targetAccountValueDeltaMeta));
    } else if (isInserting) {
      context.missing(_targetAccountValueDeltaMeta);
    }
    if (data.containsKey('profit_and_loss')) {
      context.handle(
          _profitAndLossMeta,
          profitAndLoss.isAcceptableOrUnknown(
              data['profit_and_loss']!, _profitAndLossMeta));
    }
    if (data.containsKey('return_on_invest')) {
      context.handle(
          _returnOnInvestMeta,
          returnOnInvest.isAcceptableOrUnknown(
              data['return_on_invest']!, _returnOnInvestMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Trade map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Trade(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      datetime: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}datetime'])!,
      type: $TradesTable.$convertertype.fromSql(attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!),
      sourceAccountId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}source_account_id'])!,
      targetAccountId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}target_account_id'])!,
      assetId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}asset_id'])!,
      shares: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}shares'])!,
      costBasis: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}cost_basis'])!,
      fee: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}fee'])!,
      tax: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}tax'])!,
      sourceAccountValueDelta: attachedDatabase.typeMapping.read(
          DriftSqlType.double,
          data['${effectivePrefix}source_account_value_delta'])!,
      targetAccountValueDelta: attachedDatabase.typeMapping.read(
          DriftSqlType.double,
          data['${effectivePrefix}target_account_value_delta'])!,
      profitAndLoss: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}profit_and_loss'])!,
      returnOnInvest: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}return_on_invest'])!,
    );
  }

  @override
  $TradesTable createAlias(String alias) {
    return $TradesTable(attachedDatabase, alias);
  }

  static TypeConverter<TradeTypes, String> $convertertype =
      const TradeTypesConverter();
}

class Trade extends DataClass implements Insertable<Trade> {
  final int id;
  final int datetime;
  final TradeTypes type;
  final int sourceAccountId;
  final int targetAccountId;
  final int assetId;
  final double shares;
  final double costBasis;
  final double fee;
  final double tax;
  final double sourceAccountValueDelta;
  final double targetAccountValueDelta;
  final double profitAndLoss;
  final double returnOnInvest;
  const Trade(
      {required this.id,
      required this.datetime,
      required this.type,
      required this.sourceAccountId,
      required this.targetAccountId,
      required this.assetId,
      required this.shares,
      required this.costBasis,
      required this.fee,
      required this.tax,
      required this.sourceAccountValueDelta,
      required this.targetAccountValueDelta,
      required this.profitAndLoss,
      required this.returnOnInvest});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['datetime'] = Variable<int>(datetime);
    {
      map['type'] = Variable<String>($TradesTable.$convertertype.toSql(type));
    }
    map['source_account_id'] = Variable<int>(sourceAccountId);
    map['target_account_id'] = Variable<int>(targetAccountId);
    map['asset_id'] = Variable<int>(assetId);
    map['shares'] = Variable<double>(shares);
    map['cost_basis'] = Variable<double>(costBasis);
    map['fee'] = Variable<double>(fee);
    map['tax'] = Variable<double>(tax);
    map['source_account_value_delta'] =
        Variable<double>(sourceAccountValueDelta);
    map['target_account_value_delta'] =
        Variable<double>(targetAccountValueDelta);
    map['profit_and_loss'] = Variable<double>(profitAndLoss);
    map['return_on_invest'] = Variable<double>(returnOnInvest);
    return map;
  }

  TradesCompanion toCompanion(bool nullToAbsent) {
    return TradesCompanion(
      id: Value(id),
      datetime: Value(datetime),
      type: Value(type),
      sourceAccountId: Value(sourceAccountId),
      targetAccountId: Value(targetAccountId),
      assetId: Value(assetId),
      shares: Value(shares),
      costBasis: Value(costBasis),
      fee: Value(fee),
      tax: Value(tax),
      sourceAccountValueDelta: Value(sourceAccountValueDelta),
      targetAccountValueDelta: Value(targetAccountValueDelta),
      profitAndLoss: Value(profitAndLoss),
      returnOnInvest: Value(returnOnInvest),
    );
  }

  factory Trade.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Trade(
      id: serializer.fromJson<int>(json['id']),
      datetime: serializer.fromJson<int>(json['datetime']),
      type: serializer.fromJson<TradeTypes>(json['type']),
      sourceAccountId: serializer.fromJson<int>(json['sourceAccountId']),
      targetAccountId: serializer.fromJson<int>(json['targetAccountId']),
      assetId: serializer.fromJson<int>(json['assetId']),
      shares: serializer.fromJson<double>(json['shares']),
      costBasis: serializer.fromJson<double>(json['costBasis']),
      fee: serializer.fromJson<double>(json['fee']),
      tax: serializer.fromJson<double>(json['tax']),
      sourceAccountValueDelta:
          serializer.fromJson<double>(json['sourceAccountValueDelta']),
      targetAccountValueDelta:
          serializer.fromJson<double>(json['targetAccountValueDelta']),
      profitAndLoss: serializer.fromJson<double>(json['profitAndLoss']),
      returnOnInvest: serializer.fromJson<double>(json['returnOnInvest']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'datetime': serializer.toJson<int>(datetime),
      'type': serializer.toJson<TradeTypes>(type),
      'sourceAccountId': serializer.toJson<int>(sourceAccountId),
      'targetAccountId': serializer.toJson<int>(targetAccountId),
      'assetId': serializer.toJson<int>(assetId),
      'shares': serializer.toJson<double>(shares),
      'costBasis': serializer.toJson<double>(costBasis),
      'fee': serializer.toJson<double>(fee),
      'tax': serializer.toJson<double>(tax),
      'sourceAccountValueDelta':
          serializer.toJson<double>(sourceAccountValueDelta),
      'targetAccountValueDelta':
          serializer.toJson<double>(targetAccountValueDelta),
      'profitAndLoss': serializer.toJson<double>(profitAndLoss),
      'returnOnInvest': serializer.toJson<double>(returnOnInvest),
    };
  }

  Trade copyWith(
          {int? id,
          int? datetime,
          TradeTypes? type,
          int? sourceAccountId,
          int? targetAccountId,
          int? assetId,
          double? shares,
          double? costBasis,
          double? fee,
          double? tax,
          double? sourceAccountValueDelta,
          double? targetAccountValueDelta,
          double? profitAndLoss,
          double? returnOnInvest}) =>
      Trade(
        id: id ?? this.id,
        datetime: datetime ?? this.datetime,
        type: type ?? this.type,
        sourceAccountId: sourceAccountId ?? this.sourceAccountId,
        targetAccountId: targetAccountId ?? this.targetAccountId,
        assetId: assetId ?? this.assetId,
        shares: shares ?? this.shares,
        costBasis: costBasis ?? this.costBasis,
        fee: fee ?? this.fee,
        tax: tax ?? this.tax,
        sourceAccountValueDelta:
            sourceAccountValueDelta ?? this.sourceAccountValueDelta,
        targetAccountValueDelta:
            targetAccountValueDelta ?? this.targetAccountValueDelta,
        profitAndLoss: profitAndLoss ?? this.profitAndLoss,
        returnOnInvest: returnOnInvest ?? this.returnOnInvest,
      );
  Trade copyWithCompanion(TradesCompanion data) {
    return Trade(
      id: data.id.present ? data.id.value : this.id,
      datetime: data.datetime.present ? data.datetime.value : this.datetime,
      type: data.type.present ? data.type.value : this.type,
      sourceAccountId: data.sourceAccountId.present
          ? data.sourceAccountId.value
          : this.sourceAccountId,
      targetAccountId: data.targetAccountId.present
          ? data.targetAccountId.value
          : this.targetAccountId,
      assetId: data.assetId.present ? data.assetId.value : this.assetId,
      shares: data.shares.present ? data.shares.value : this.shares,
      costBasis: data.costBasis.present ? data.costBasis.value : this.costBasis,
      fee: data.fee.present ? data.fee.value : this.fee,
      tax: data.tax.present ? data.tax.value : this.tax,
      sourceAccountValueDelta: data.sourceAccountValueDelta.present
          ? data.sourceAccountValueDelta.value
          : this.sourceAccountValueDelta,
      targetAccountValueDelta: data.targetAccountValueDelta.present
          ? data.targetAccountValueDelta.value
          : this.targetAccountValueDelta,
      profitAndLoss: data.profitAndLoss.present
          ? data.profitAndLoss.value
          : this.profitAndLoss,
      returnOnInvest: data.returnOnInvest.present
          ? data.returnOnInvest.value
          : this.returnOnInvest,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Trade(')
          ..write('id: $id, ')
          ..write('datetime: $datetime, ')
          ..write('type: $type, ')
          ..write('sourceAccountId: $sourceAccountId, ')
          ..write('targetAccountId: $targetAccountId, ')
          ..write('assetId: $assetId, ')
          ..write('shares: $shares, ')
          ..write('costBasis: $costBasis, ')
          ..write('fee: $fee, ')
          ..write('tax: $tax, ')
          ..write('sourceAccountValueDelta: $sourceAccountValueDelta, ')
          ..write('targetAccountValueDelta: $targetAccountValueDelta, ')
          ..write('profitAndLoss: $profitAndLoss, ')
          ..write('returnOnInvest: $returnOnInvest')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      datetime,
      type,
      sourceAccountId,
      targetAccountId,
      assetId,
      shares,
      costBasis,
      fee,
      tax,
      sourceAccountValueDelta,
      targetAccountValueDelta,
      profitAndLoss,
      returnOnInvest);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Trade &&
          other.id == this.id &&
          other.datetime == this.datetime &&
          other.type == this.type &&
          other.sourceAccountId == this.sourceAccountId &&
          other.targetAccountId == this.targetAccountId &&
          other.assetId == this.assetId &&
          other.shares == this.shares &&
          other.costBasis == this.costBasis &&
          other.fee == this.fee &&
          other.tax == this.tax &&
          other.sourceAccountValueDelta == this.sourceAccountValueDelta &&
          other.targetAccountValueDelta == this.targetAccountValueDelta &&
          other.profitAndLoss == this.profitAndLoss &&
          other.returnOnInvest == this.returnOnInvest);
}

class TradesCompanion extends UpdateCompanion<Trade> {
  final Value<int> id;
  final Value<int> datetime;
  final Value<TradeTypes> type;
  final Value<int> sourceAccountId;
  final Value<int> targetAccountId;
  final Value<int> assetId;
  final Value<double> shares;
  final Value<double> costBasis;
  final Value<double> fee;
  final Value<double> tax;
  final Value<double> sourceAccountValueDelta;
  final Value<double> targetAccountValueDelta;
  final Value<double> profitAndLoss;
  final Value<double> returnOnInvest;
  const TradesCompanion({
    this.id = const Value.absent(),
    this.datetime = const Value.absent(),
    this.type = const Value.absent(),
    this.sourceAccountId = const Value.absent(),
    this.targetAccountId = const Value.absent(),
    this.assetId = const Value.absent(),
    this.shares = const Value.absent(),
    this.costBasis = const Value.absent(),
    this.fee = const Value.absent(),
    this.tax = const Value.absent(),
    this.sourceAccountValueDelta = const Value.absent(),
    this.targetAccountValueDelta = const Value.absent(),
    this.profitAndLoss = const Value.absent(),
    this.returnOnInvest = const Value.absent(),
  });
  TradesCompanion.insert({
    this.id = const Value.absent(),
    required int datetime,
    required TradeTypes type,
    required int sourceAccountId,
    required int targetAccountId,
    required int assetId,
    required double shares,
    required double costBasis,
    this.fee = const Value.absent(),
    this.tax = const Value.absent(),
    required double sourceAccountValueDelta,
    required double targetAccountValueDelta,
    this.profitAndLoss = const Value.absent(),
    this.returnOnInvest = const Value.absent(),
  })  : datetime = Value(datetime),
        type = Value(type),
        sourceAccountId = Value(sourceAccountId),
        targetAccountId = Value(targetAccountId),
        assetId = Value(assetId),
        shares = Value(shares),
        costBasis = Value(costBasis),
        sourceAccountValueDelta = Value(sourceAccountValueDelta),
        targetAccountValueDelta = Value(targetAccountValueDelta);
  static Insertable<Trade> custom({
    Expression<int>? id,
    Expression<int>? datetime,
    Expression<String>? type,
    Expression<int>? sourceAccountId,
    Expression<int>? targetAccountId,
    Expression<int>? assetId,
    Expression<double>? shares,
    Expression<double>? costBasis,
    Expression<double>? fee,
    Expression<double>? tax,
    Expression<double>? sourceAccountValueDelta,
    Expression<double>? targetAccountValueDelta,
    Expression<double>? profitAndLoss,
    Expression<double>? returnOnInvest,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (datetime != null) 'datetime': datetime,
      if (type != null) 'type': type,
      if (sourceAccountId != null) 'source_account_id': sourceAccountId,
      if (targetAccountId != null) 'target_account_id': targetAccountId,
      if (assetId != null) 'asset_id': assetId,
      if (shares != null) 'shares': shares,
      if (costBasis != null) 'cost_basis': costBasis,
      if (fee != null) 'fee': fee,
      if (tax != null) 'tax': tax,
      if (sourceAccountValueDelta != null)
        'source_account_value_delta': sourceAccountValueDelta,
      if (targetAccountValueDelta != null)
        'target_account_value_delta': targetAccountValueDelta,
      if (profitAndLoss != null) 'profit_and_loss': profitAndLoss,
      if (returnOnInvest != null) 'return_on_invest': returnOnInvest,
    });
  }

  TradesCompanion copyWith(
      {Value<int>? id,
      Value<int>? datetime,
      Value<TradeTypes>? type,
      Value<int>? sourceAccountId,
      Value<int>? targetAccountId,
      Value<int>? assetId,
      Value<double>? shares,
      Value<double>? costBasis,
      Value<double>? fee,
      Value<double>? tax,
      Value<double>? sourceAccountValueDelta,
      Value<double>? targetAccountValueDelta,
      Value<double>? profitAndLoss,
      Value<double>? returnOnInvest}) {
    return TradesCompanion(
      id: id ?? this.id,
      datetime: datetime ?? this.datetime,
      type: type ?? this.type,
      sourceAccountId: sourceAccountId ?? this.sourceAccountId,
      targetAccountId: targetAccountId ?? this.targetAccountId,
      assetId: assetId ?? this.assetId,
      shares: shares ?? this.shares,
      costBasis: costBasis ?? this.costBasis,
      fee: fee ?? this.fee,
      tax: tax ?? this.tax,
      sourceAccountValueDelta:
          sourceAccountValueDelta ?? this.sourceAccountValueDelta,
      targetAccountValueDelta:
          targetAccountValueDelta ?? this.targetAccountValueDelta,
      profitAndLoss: profitAndLoss ?? this.profitAndLoss,
      returnOnInvest: returnOnInvest ?? this.returnOnInvest,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (datetime.present) {
      map['datetime'] = Variable<int>(datetime.value);
    }
    if (type.present) {
      map['type'] =
          Variable<String>($TradesTable.$convertertype.toSql(type.value));
    }
    if (sourceAccountId.present) {
      map['source_account_id'] = Variable<int>(sourceAccountId.value);
    }
    if (targetAccountId.present) {
      map['target_account_id'] = Variable<int>(targetAccountId.value);
    }
    if (assetId.present) {
      map['asset_id'] = Variable<int>(assetId.value);
    }
    if (shares.present) {
      map['shares'] = Variable<double>(shares.value);
    }
    if (costBasis.present) {
      map['cost_basis'] = Variable<double>(costBasis.value);
    }
    if (fee.present) {
      map['fee'] = Variable<double>(fee.value);
    }
    if (tax.present) {
      map['tax'] = Variable<double>(tax.value);
    }
    if (sourceAccountValueDelta.present) {
      map['source_account_value_delta'] =
          Variable<double>(sourceAccountValueDelta.value);
    }
    if (targetAccountValueDelta.present) {
      map['target_account_value_delta'] =
          Variable<double>(targetAccountValueDelta.value);
    }
    if (profitAndLoss.present) {
      map['profit_and_loss'] = Variable<double>(profitAndLoss.value);
    }
    if (returnOnInvest.present) {
      map['return_on_invest'] = Variable<double>(returnOnInvest.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TradesCompanion(')
          ..write('id: $id, ')
          ..write('datetime: $datetime, ')
          ..write('type: $type, ')
          ..write('sourceAccountId: $sourceAccountId, ')
          ..write('targetAccountId: $targetAccountId, ')
          ..write('assetId: $assetId, ')
          ..write('shares: $shares, ')
          ..write('costBasis: $costBasis, ')
          ..write('fee: $fee, ')
          ..write('tax: $tax, ')
          ..write('sourceAccountValueDelta: $sourceAccountValueDelta, ')
          ..write('targetAccountValueDelta: $targetAccountValueDelta, ')
          ..write('profitAndLoss: $profitAndLoss, ')
          ..write('returnOnInvest: $returnOnInvest')
          ..write(')'))
        .toString();
  }
}

class $PeriodicBookingsTable extends PeriodicBookings
    with TableInfo<$PeriodicBookingsTable, PeriodicBooking> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PeriodicBookingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nextExecutionDateMeta =
      const VerificationMeta('nextExecutionDate');
  @override
  late final GeneratedColumn<int> nextExecutionDate = GeneratedColumn<int>(
      'next_execution_date', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _assetIdMeta =
      const VerificationMeta('assetId');
  @override
  late final GeneratedColumn<int> assetId = GeneratedColumn<int>(
      'asset_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES assets (id)'),
      defaultValue: const Constant(1));
  static const VerificationMeta _accountIdMeta =
      const VerificationMeta('accountId');
  @override
  late final GeneratedColumn<int> accountId = GeneratedColumn<int>(
      'account_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES accounts (id)'));
  static const VerificationMeta _sharesMeta = const VerificationMeta('shares');
  @override
  late final GeneratedColumn<double> shares = GeneratedColumn<double>(
      'shares', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _costBasisMeta =
      const VerificationMeta('costBasis');
  @override
  late final GeneratedColumn<double> costBasis = GeneratedColumn<double>(
      'cost_basis', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<double> value = GeneratedColumn<double>(
      'value', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _categoryMeta =
      const VerificationMeta('category');
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
      'category', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  late final GeneratedColumnWithTypeConverter<Cycles, String> cycle =
      GeneratedColumn<String>('cycle', aliasedName, false,
              type: DriftSqlType.string,
              requiredDuringInsert: false,
              defaultValue: Constant(Cycles.monthly.name))
          .withConverter<Cycles>($PeriodicBookingsTable.$convertercycle);
  static const VerificationMeta _monthlyAverageFactorMeta =
      const VerificationMeta('monthlyAverageFactor');
  @override
  late final GeneratedColumn<double> monthlyAverageFactor =
      GeneratedColumn<double>('monthly_average_factor', aliasedName, false,
          type: DriftSqlType.double,
          requiredDuringInsert: false,
          defaultValue: const Constant(1));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        nextExecutionDate,
        assetId,
        accountId,
        shares,
        costBasis,
        value,
        category,
        notes,
        cycle,
        monthlyAverageFactor
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'periodic_bookings';
  @override
  VerificationContext validateIntegrity(Insertable<PeriodicBooking> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('next_execution_date')) {
      context.handle(
          _nextExecutionDateMeta,
          nextExecutionDate.isAcceptableOrUnknown(
              data['next_execution_date']!, _nextExecutionDateMeta));
    } else if (isInserting) {
      context.missing(_nextExecutionDateMeta);
    }
    if (data.containsKey('asset_id')) {
      context.handle(_assetIdMeta,
          assetId.isAcceptableOrUnknown(data['asset_id']!, _assetIdMeta));
    }
    if (data.containsKey('account_id')) {
      context.handle(_accountIdMeta,
          accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta));
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('shares')) {
      context.handle(_sharesMeta,
          shares.isAcceptableOrUnknown(data['shares']!, _sharesMeta));
    } else if (isInserting) {
      context.missing(_sharesMeta);
    }
    if (data.containsKey('cost_basis')) {
      context.handle(_costBasisMeta,
          costBasis.isAcceptableOrUnknown(data['cost_basis']!, _costBasisMeta));
    }
    if (data.containsKey('value')) {
      context.handle(
          _valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('category')) {
      context.handle(_categoryMeta,
          category.isAcceptableOrUnknown(data['category']!, _categoryMeta));
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('monthly_average_factor')) {
      context.handle(
          _monthlyAverageFactorMeta,
          monthlyAverageFactor.isAcceptableOrUnknown(
              data['monthly_average_factor']!, _monthlyAverageFactorMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PeriodicBooking map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PeriodicBooking(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      nextExecutionDate: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}next_execution_date'])!,
      assetId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}asset_id'])!,
      accountId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}account_id'])!,
      shares: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}shares'])!,
      costBasis: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}cost_basis'])!,
      value: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}value'])!,
      category: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category'])!,
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
      cycle: $PeriodicBookingsTable.$convertercycle.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}cycle'])!),
      monthlyAverageFactor: attachedDatabase.typeMapping.read(
          DriftSqlType.double,
          data['${effectivePrefix}monthly_average_factor'])!,
    );
  }

  @override
  $PeriodicBookingsTable createAlias(String alias) {
    return $PeriodicBookingsTable(attachedDatabase, alias);
  }

  static TypeConverter<Cycles, String> $convertercycle =
      const CyclesConverter();
}

class PeriodicBooking extends DataClass implements Insertable<PeriodicBooking> {
  final int id;
  final int nextExecutionDate;
  final int assetId;
  final int accountId;
  final double shares;
  final double costBasis;
  final double value;
  final String category;
  final String? notes;
  final Cycles cycle;
  final double monthlyAverageFactor;
  const PeriodicBooking(
      {required this.id,
      required this.nextExecutionDate,
      required this.assetId,
      required this.accountId,
      required this.shares,
      required this.costBasis,
      required this.value,
      required this.category,
      this.notes,
      required this.cycle,
      required this.monthlyAverageFactor});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['next_execution_date'] = Variable<int>(nextExecutionDate);
    map['asset_id'] = Variable<int>(assetId);
    map['account_id'] = Variable<int>(accountId);
    map['shares'] = Variable<double>(shares);
    map['cost_basis'] = Variable<double>(costBasis);
    map['value'] = Variable<double>(value);
    map['category'] = Variable<String>(category);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    {
      map['cycle'] =
          Variable<String>($PeriodicBookingsTable.$convertercycle.toSql(cycle));
    }
    map['monthly_average_factor'] = Variable<double>(monthlyAverageFactor);
    return map;
  }

  PeriodicBookingsCompanion toCompanion(bool nullToAbsent) {
    return PeriodicBookingsCompanion(
      id: Value(id),
      nextExecutionDate: Value(nextExecutionDate),
      assetId: Value(assetId),
      accountId: Value(accountId),
      shares: Value(shares),
      costBasis: Value(costBasis),
      value: Value(value),
      category: Value(category),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      cycle: Value(cycle),
      monthlyAverageFactor: Value(monthlyAverageFactor),
    );
  }

  factory PeriodicBooking.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PeriodicBooking(
      id: serializer.fromJson<int>(json['id']),
      nextExecutionDate: serializer.fromJson<int>(json['nextExecutionDate']),
      assetId: serializer.fromJson<int>(json['assetId']),
      accountId: serializer.fromJson<int>(json['accountId']),
      shares: serializer.fromJson<double>(json['shares']),
      costBasis: serializer.fromJson<double>(json['costBasis']),
      value: serializer.fromJson<double>(json['value']),
      category: serializer.fromJson<String>(json['category']),
      notes: serializer.fromJson<String?>(json['notes']),
      cycle: serializer.fromJson<Cycles>(json['cycle']),
      monthlyAverageFactor:
          serializer.fromJson<double>(json['monthlyAverageFactor']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'nextExecutionDate': serializer.toJson<int>(nextExecutionDate),
      'assetId': serializer.toJson<int>(assetId),
      'accountId': serializer.toJson<int>(accountId),
      'shares': serializer.toJson<double>(shares),
      'costBasis': serializer.toJson<double>(costBasis),
      'value': serializer.toJson<double>(value),
      'category': serializer.toJson<String>(category),
      'notes': serializer.toJson<String?>(notes),
      'cycle': serializer.toJson<Cycles>(cycle),
      'monthlyAverageFactor': serializer.toJson<double>(monthlyAverageFactor),
    };
  }

  PeriodicBooking copyWith(
          {int? id,
          int? nextExecutionDate,
          int? assetId,
          int? accountId,
          double? shares,
          double? costBasis,
          double? value,
          String? category,
          Value<String?> notes = const Value.absent(),
          Cycles? cycle,
          double? monthlyAverageFactor}) =>
      PeriodicBooking(
        id: id ?? this.id,
        nextExecutionDate: nextExecutionDate ?? this.nextExecutionDate,
        assetId: assetId ?? this.assetId,
        accountId: accountId ?? this.accountId,
        shares: shares ?? this.shares,
        costBasis: costBasis ?? this.costBasis,
        value: value ?? this.value,
        category: category ?? this.category,
        notes: notes.present ? notes.value : this.notes,
        cycle: cycle ?? this.cycle,
        monthlyAverageFactor: monthlyAverageFactor ?? this.monthlyAverageFactor,
      );
  PeriodicBooking copyWithCompanion(PeriodicBookingsCompanion data) {
    return PeriodicBooking(
      id: data.id.present ? data.id.value : this.id,
      nextExecutionDate: data.nextExecutionDate.present
          ? data.nextExecutionDate.value
          : this.nextExecutionDate,
      assetId: data.assetId.present ? data.assetId.value : this.assetId,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      shares: data.shares.present ? data.shares.value : this.shares,
      costBasis: data.costBasis.present ? data.costBasis.value : this.costBasis,
      value: data.value.present ? data.value.value : this.value,
      category: data.category.present ? data.category.value : this.category,
      notes: data.notes.present ? data.notes.value : this.notes,
      cycle: data.cycle.present ? data.cycle.value : this.cycle,
      monthlyAverageFactor: data.monthlyAverageFactor.present
          ? data.monthlyAverageFactor.value
          : this.monthlyAverageFactor,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PeriodicBooking(')
          ..write('id: $id, ')
          ..write('nextExecutionDate: $nextExecutionDate, ')
          ..write('assetId: $assetId, ')
          ..write('accountId: $accountId, ')
          ..write('shares: $shares, ')
          ..write('costBasis: $costBasis, ')
          ..write('value: $value, ')
          ..write('category: $category, ')
          ..write('notes: $notes, ')
          ..write('cycle: $cycle, ')
          ..write('monthlyAverageFactor: $monthlyAverageFactor')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, nextExecutionDate, assetId, accountId,
      shares, costBasis, value, category, notes, cycle, monthlyAverageFactor);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PeriodicBooking &&
          other.id == this.id &&
          other.nextExecutionDate == this.nextExecutionDate &&
          other.assetId == this.assetId &&
          other.accountId == this.accountId &&
          other.shares == this.shares &&
          other.costBasis == this.costBasis &&
          other.value == this.value &&
          other.category == this.category &&
          other.notes == this.notes &&
          other.cycle == this.cycle &&
          other.monthlyAverageFactor == this.monthlyAverageFactor);
}

class PeriodicBookingsCompanion extends UpdateCompanion<PeriodicBooking> {
  final Value<int> id;
  final Value<int> nextExecutionDate;
  final Value<int> assetId;
  final Value<int> accountId;
  final Value<double> shares;
  final Value<double> costBasis;
  final Value<double> value;
  final Value<String> category;
  final Value<String?> notes;
  final Value<Cycles> cycle;
  final Value<double> monthlyAverageFactor;
  const PeriodicBookingsCompanion({
    this.id = const Value.absent(),
    this.nextExecutionDate = const Value.absent(),
    this.assetId = const Value.absent(),
    this.accountId = const Value.absent(),
    this.shares = const Value.absent(),
    this.costBasis = const Value.absent(),
    this.value = const Value.absent(),
    this.category = const Value.absent(),
    this.notes = const Value.absent(),
    this.cycle = const Value.absent(),
    this.monthlyAverageFactor = const Value.absent(),
  });
  PeriodicBookingsCompanion.insert({
    this.id = const Value.absent(),
    required int nextExecutionDate,
    this.assetId = const Value.absent(),
    required int accountId,
    required double shares,
    this.costBasis = const Value.absent(),
    required double value,
    required String category,
    this.notes = const Value.absent(),
    this.cycle = const Value.absent(),
    this.monthlyAverageFactor = const Value.absent(),
  })  : nextExecutionDate = Value(nextExecutionDate),
        accountId = Value(accountId),
        shares = Value(shares),
        value = Value(value),
        category = Value(category);
  static Insertable<PeriodicBooking> custom({
    Expression<int>? id,
    Expression<int>? nextExecutionDate,
    Expression<int>? assetId,
    Expression<int>? accountId,
    Expression<double>? shares,
    Expression<double>? costBasis,
    Expression<double>? value,
    Expression<String>? category,
    Expression<String>? notes,
    Expression<String>? cycle,
    Expression<double>? monthlyAverageFactor,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (nextExecutionDate != null) 'next_execution_date': nextExecutionDate,
      if (assetId != null) 'asset_id': assetId,
      if (accountId != null) 'account_id': accountId,
      if (shares != null) 'shares': shares,
      if (costBasis != null) 'cost_basis': costBasis,
      if (value != null) 'value': value,
      if (category != null) 'category': category,
      if (notes != null) 'notes': notes,
      if (cycle != null) 'cycle': cycle,
      if (monthlyAverageFactor != null)
        'monthly_average_factor': monthlyAverageFactor,
    });
  }

  PeriodicBookingsCompanion copyWith(
      {Value<int>? id,
      Value<int>? nextExecutionDate,
      Value<int>? assetId,
      Value<int>? accountId,
      Value<double>? shares,
      Value<double>? costBasis,
      Value<double>? value,
      Value<String>? category,
      Value<String?>? notes,
      Value<Cycles>? cycle,
      Value<double>? monthlyAverageFactor}) {
    return PeriodicBookingsCompanion(
      id: id ?? this.id,
      nextExecutionDate: nextExecutionDate ?? this.nextExecutionDate,
      assetId: assetId ?? this.assetId,
      accountId: accountId ?? this.accountId,
      shares: shares ?? this.shares,
      costBasis: costBasis ?? this.costBasis,
      value: value ?? this.value,
      category: category ?? this.category,
      notes: notes ?? this.notes,
      cycle: cycle ?? this.cycle,
      monthlyAverageFactor: monthlyAverageFactor ?? this.monthlyAverageFactor,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (nextExecutionDate.present) {
      map['next_execution_date'] = Variable<int>(nextExecutionDate.value);
    }
    if (assetId.present) {
      map['asset_id'] = Variable<int>(assetId.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<int>(accountId.value);
    }
    if (shares.present) {
      map['shares'] = Variable<double>(shares.value);
    }
    if (costBasis.present) {
      map['cost_basis'] = Variable<double>(costBasis.value);
    }
    if (value.present) {
      map['value'] = Variable<double>(value.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (cycle.present) {
      map['cycle'] = Variable<String>(
          $PeriodicBookingsTable.$convertercycle.toSql(cycle.value));
    }
    if (monthlyAverageFactor.present) {
      map['monthly_average_factor'] =
          Variable<double>(monthlyAverageFactor.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PeriodicBookingsCompanion(')
          ..write('id: $id, ')
          ..write('nextExecutionDate: $nextExecutionDate, ')
          ..write('assetId: $assetId, ')
          ..write('accountId: $accountId, ')
          ..write('shares: $shares, ')
          ..write('costBasis: $costBasis, ')
          ..write('value: $value, ')
          ..write('category: $category, ')
          ..write('notes: $notes, ')
          ..write('cycle: $cycle, ')
          ..write('monthlyAverageFactor: $monthlyAverageFactor')
          ..write(')'))
        .toString();
  }
}

class $PeriodicTransfersTable extends PeriodicTransfers
    with TableInfo<$PeriodicTransfersTable, PeriodicTransfer> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PeriodicTransfersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nextExecutionDateMeta =
      const VerificationMeta('nextExecutionDate');
  @override
  late final GeneratedColumn<int> nextExecutionDate = GeneratedColumn<int>(
      'next_execution_date', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _assetIdMeta =
      const VerificationMeta('assetId');
  @override
  late final GeneratedColumn<int> assetId = GeneratedColumn<int>(
      'asset_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES assets (id)'),
      defaultValue: const Constant(1));
  static const VerificationMeta _sendingAccountIdMeta =
      const VerificationMeta('sendingAccountId');
  @override
  late final GeneratedColumn<int> sendingAccountId = GeneratedColumn<int>(
      'sending_account_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES accounts (id)'));
  static const VerificationMeta _receivingAccountIdMeta =
      const VerificationMeta('receivingAccountId');
  @override
  late final GeneratedColumn<int> receivingAccountId = GeneratedColumn<int>(
      'receiving_account_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES accounts (id)'));
  static const VerificationMeta _sharesMeta = const VerificationMeta('shares');
  @override
  late final GeneratedColumn<double> shares = GeneratedColumn<double>(
      'shares', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _costBasisMeta =
      const VerificationMeta('costBasis');
  @override
  late final GeneratedColumn<double> costBasis = GeneratedColumn<double>(
      'cost_basis', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<double> value = GeneratedColumn<double>(
      'value', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  late final GeneratedColumnWithTypeConverter<Cycles, String> cycle =
      GeneratedColumn<String>('cycle', aliasedName, false,
              type: DriftSqlType.string,
              requiredDuringInsert: false,
              defaultValue: Constant(Cycles.monthly.name))
          .withConverter<Cycles>($PeriodicTransfersTable.$convertercycle);
  static const VerificationMeta _monthlyAverageFactorMeta =
      const VerificationMeta('monthlyAverageFactor');
  @override
  late final GeneratedColumn<double> monthlyAverageFactor =
      GeneratedColumn<double>('monthly_average_factor', aliasedName, false,
          type: DriftSqlType.double,
          requiredDuringInsert: false,
          defaultValue: const Constant(1));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        nextExecutionDate,
        assetId,
        sendingAccountId,
        receivingAccountId,
        shares,
        costBasis,
        value,
        notes,
        cycle,
        monthlyAverageFactor
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'periodic_transfers';
  @override
  VerificationContext validateIntegrity(Insertable<PeriodicTransfer> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('next_execution_date')) {
      context.handle(
          _nextExecutionDateMeta,
          nextExecutionDate.isAcceptableOrUnknown(
              data['next_execution_date']!, _nextExecutionDateMeta));
    } else if (isInserting) {
      context.missing(_nextExecutionDateMeta);
    }
    if (data.containsKey('asset_id')) {
      context.handle(_assetIdMeta,
          assetId.isAcceptableOrUnknown(data['asset_id']!, _assetIdMeta));
    }
    if (data.containsKey('sending_account_id')) {
      context.handle(
          _sendingAccountIdMeta,
          sendingAccountId.isAcceptableOrUnknown(
              data['sending_account_id']!, _sendingAccountIdMeta));
    } else if (isInserting) {
      context.missing(_sendingAccountIdMeta);
    }
    if (data.containsKey('receiving_account_id')) {
      context.handle(
          _receivingAccountIdMeta,
          receivingAccountId.isAcceptableOrUnknown(
              data['receiving_account_id']!, _receivingAccountIdMeta));
    } else if (isInserting) {
      context.missing(_receivingAccountIdMeta);
    }
    if (data.containsKey('shares')) {
      context.handle(_sharesMeta,
          shares.isAcceptableOrUnknown(data['shares']!, _sharesMeta));
    } else if (isInserting) {
      context.missing(_sharesMeta);
    }
    if (data.containsKey('cost_basis')) {
      context.handle(_costBasisMeta,
          costBasis.isAcceptableOrUnknown(data['cost_basis']!, _costBasisMeta));
    }
    if (data.containsKey('value')) {
      context.handle(
          _valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('monthly_average_factor')) {
      context.handle(
          _monthlyAverageFactorMeta,
          monthlyAverageFactor.isAcceptableOrUnknown(
              data['monthly_average_factor']!, _monthlyAverageFactorMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PeriodicTransfer map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PeriodicTransfer(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      nextExecutionDate: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}next_execution_date'])!,
      assetId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}asset_id'])!,
      sendingAccountId: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}sending_account_id'])!,
      receivingAccountId: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}receiving_account_id'])!,
      shares: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}shares'])!,
      costBasis: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}cost_basis'])!,
      value: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}value'])!,
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
      cycle: $PeriodicTransfersTable.$convertercycle.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}cycle'])!),
      monthlyAverageFactor: attachedDatabase.typeMapping.read(
          DriftSqlType.double,
          data['${effectivePrefix}monthly_average_factor'])!,
    );
  }

  @override
  $PeriodicTransfersTable createAlias(String alias) {
    return $PeriodicTransfersTable(attachedDatabase, alias);
  }

  static TypeConverter<Cycles, String> $convertercycle =
      const CyclesConverter();
}

class PeriodicTransfer extends DataClass
    implements Insertable<PeriodicTransfer> {
  final int id;
  final int nextExecutionDate;
  final int assetId;
  final int sendingAccountId;
  final int receivingAccountId;
  final double shares;
  final double costBasis;
  final double value;
  final String? notes;
  final Cycles cycle;
  final double monthlyAverageFactor;
  const PeriodicTransfer(
      {required this.id,
      required this.nextExecutionDate,
      required this.assetId,
      required this.sendingAccountId,
      required this.receivingAccountId,
      required this.shares,
      required this.costBasis,
      required this.value,
      this.notes,
      required this.cycle,
      required this.monthlyAverageFactor});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['next_execution_date'] = Variable<int>(nextExecutionDate);
    map['asset_id'] = Variable<int>(assetId);
    map['sending_account_id'] = Variable<int>(sendingAccountId);
    map['receiving_account_id'] = Variable<int>(receivingAccountId);
    map['shares'] = Variable<double>(shares);
    map['cost_basis'] = Variable<double>(costBasis);
    map['value'] = Variable<double>(value);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    {
      map['cycle'] = Variable<String>(
          $PeriodicTransfersTable.$convertercycle.toSql(cycle));
    }
    map['monthly_average_factor'] = Variable<double>(monthlyAverageFactor);
    return map;
  }

  PeriodicTransfersCompanion toCompanion(bool nullToAbsent) {
    return PeriodicTransfersCompanion(
      id: Value(id),
      nextExecutionDate: Value(nextExecutionDate),
      assetId: Value(assetId),
      sendingAccountId: Value(sendingAccountId),
      receivingAccountId: Value(receivingAccountId),
      shares: Value(shares),
      costBasis: Value(costBasis),
      value: Value(value),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      cycle: Value(cycle),
      monthlyAverageFactor: Value(monthlyAverageFactor),
    );
  }

  factory PeriodicTransfer.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PeriodicTransfer(
      id: serializer.fromJson<int>(json['id']),
      nextExecutionDate: serializer.fromJson<int>(json['nextExecutionDate']),
      assetId: serializer.fromJson<int>(json['assetId']),
      sendingAccountId: serializer.fromJson<int>(json['sendingAccountId']),
      receivingAccountId: serializer.fromJson<int>(json['receivingAccountId']),
      shares: serializer.fromJson<double>(json['shares']),
      costBasis: serializer.fromJson<double>(json['costBasis']),
      value: serializer.fromJson<double>(json['value']),
      notes: serializer.fromJson<String?>(json['notes']),
      cycle: serializer.fromJson<Cycles>(json['cycle']),
      monthlyAverageFactor:
          serializer.fromJson<double>(json['monthlyAverageFactor']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'nextExecutionDate': serializer.toJson<int>(nextExecutionDate),
      'assetId': serializer.toJson<int>(assetId),
      'sendingAccountId': serializer.toJson<int>(sendingAccountId),
      'receivingAccountId': serializer.toJson<int>(receivingAccountId),
      'shares': serializer.toJson<double>(shares),
      'costBasis': serializer.toJson<double>(costBasis),
      'value': serializer.toJson<double>(value),
      'notes': serializer.toJson<String?>(notes),
      'cycle': serializer.toJson<Cycles>(cycle),
      'monthlyAverageFactor': serializer.toJson<double>(monthlyAverageFactor),
    };
  }

  PeriodicTransfer copyWith(
          {int? id,
          int? nextExecutionDate,
          int? assetId,
          int? sendingAccountId,
          int? receivingAccountId,
          double? shares,
          double? costBasis,
          double? value,
          Value<String?> notes = const Value.absent(),
          Cycles? cycle,
          double? monthlyAverageFactor}) =>
      PeriodicTransfer(
        id: id ?? this.id,
        nextExecutionDate: nextExecutionDate ?? this.nextExecutionDate,
        assetId: assetId ?? this.assetId,
        sendingAccountId: sendingAccountId ?? this.sendingAccountId,
        receivingAccountId: receivingAccountId ?? this.receivingAccountId,
        shares: shares ?? this.shares,
        costBasis: costBasis ?? this.costBasis,
        value: value ?? this.value,
        notes: notes.present ? notes.value : this.notes,
        cycle: cycle ?? this.cycle,
        monthlyAverageFactor: monthlyAverageFactor ?? this.monthlyAverageFactor,
      );
  PeriodicTransfer copyWithCompanion(PeriodicTransfersCompanion data) {
    return PeriodicTransfer(
      id: data.id.present ? data.id.value : this.id,
      nextExecutionDate: data.nextExecutionDate.present
          ? data.nextExecutionDate.value
          : this.nextExecutionDate,
      assetId: data.assetId.present ? data.assetId.value : this.assetId,
      sendingAccountId: data.sendingAccountId.present
          ? data.sendingAccountId.value
          : this.sendingAccountId,
      receivingAccountId: data.receivingAccountId.present
          ? data.receivingAccountId.value
          : this.receivingAccountId,
      shares: data.shares.present ? data.shares.value : this.shares,
      costBasis: data.costBasis.present ? data.costBasis.value : this.costBasis,
      value: data.value.present ? data.value.value : this.value,
      notes: data.notes.present ? data.notes.value : this.notes,
      cycle: data.cycle.present ? data.cycle.value : this.cycle,
      monthlyAverageFactor: data.monthlyAverageFactor.present
          ? data.monthlyAverageFactor.value
          : this.monthlyAverageFactor,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PeriodicTransfer(')
          ..write('id: $id, ')
          ..write('nextExecutionDate: $nextExecutionDate, ')
          ..write('assetId: $assetId, ')
          ..write('sendingAccountId: $sendingAccountId, ')
          ..write('receivingAccountId: $receivingAccountId, ')
          ..write('shares: $shares, ')
          ..write('costBasis: $costBasis, ')
          ..write('value: $value, ')
          ..write('notes: $notes, ')
          ..write('cycle: $cycle, ')
          ..write('monthlyAverageFactor: $monthlyAverageFactor')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      nextExecutionDate,
      assetId,
      sendingAccountId,
      receivingAccountId,
      shares,
      costBasis,
      value,
      notes,
      cycle,
      monthlyAverageFactor);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PeriodicTransfer &&
          other.id == this.id &&
          other.nextExecutionDate == this.nextExecutionDate &&
          other.assetId == this.assetId &&
          other.sendingAccountId == this.sendingAccountId &&
          other.receivingAccountId == this.receivingAccountId &&
          other.shares == this.shares &&
          other.costBasis == this.costBasis &&
          other.value == this.value &&
          other.notes == this.notes &&
          other.cycle == this.cycle &&
          other.monthlyAverageFactor == this.monthlyAverageFactor);
}

class PeriodicTransfersCompanion extends UpdateCompanion<PeriodicTransfer> {
  final Value<int> id;
  final Value<int> nextExecutionDate;
  final Value<int> assetId;
  final Value<int> sendingAccountId;
  final Value<int> receivingAccountId;
  final Value<double> shares;
  final Value<double> costBasis;
  final Value<double> value;
  final Value<String?> notes;
  final Value<Cycles> cycle;
  final Value<double> monthlyAverageFactor;
  const PeriodicTransfersCompanion({
    this.id = const Value.absent(),
    this.nextExecutionDate = const Value.absent(),
    this.assetId = const Value.absent(),
    this.sendingAccountId = const Value.absent(),
    this.receivingAccountId = const Value.absent(),
    this.shares = const Value.absent(),
    this.costBasis = const Value.absent(),
    this.value = const Value.absent(),
    this.notes = const Value.absent(),
    this.cycle = const Value.absent(),
    this.monthlyAverageFactor = const Value.absent(),
  });
  PeriodicTransfersCompanion.insert({
    this.id = const Value.absent(),
    required int nextExecutionDate,
    this.assetId = const Value.absent(),
    required int sendingAccountId,
    required int receivingAccountId,
    required double shares,
    this.costBasis = const Value.absent(),
    required double value,
    this.notes = const Value.absent(),
    this.cycle = const Value.absent(),
    this.monthlyAverageFactor = const Value.absent(),
  })  : nextExecutionDate = Value(nextExecutionDate),
        sendingAccountId = Value(sendingAccountId),
        receivingAccountId = Value(receivingAccountId),
        shares = Value(shares),
        value = Value(value);
  static Insertable<PeriodicTransfer> custom({
    Expression<int>? id,
    Expression<int>? nextExecutionDate,
    Expression<int>? assetId,
    Expression<int>? sendingAccountId,
    Expression<int>? receivingAccountId,
    Expression<double>? shares,
    Expression<double>? costBasis,
    Expression<double>? value,
    Expression<String>? notes,
    Expression<String>? cycle,
    Expression<double>? monthlyAverageFactor,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (nextExecutionDate != null) 'next_execution_date': nextExecutionDate,
      if (assetId != null) 'asset_id': assetId,
      if (sendingAccountId != null) 'sending_account_id': sendingAccountId,
      if (receivingAccountId != null)
        'receiving_account_id': receivingAccountId,
      if (shares != null) 'shares': shares,
      if (costBasis != null) 'cost_basis': costBasis,
      if (value != null) 'value': value,
      if (notes != null) 'notes': notes,
      if (cycle != null) 'cycle': cycle,
      if (monthlyAverageFactor != null)
        'monthly_average_factor': monthlyAverageFactor,
    });
  }

  PeriodicTransfersCompanion copyWith(
      {Value<int>? id,
      Value<int>? nextExecutionDate,
      Value<int>? assetId,
      Value<int>? sendingAccountId,
      Value<int>? receivingAccountId,
      Value<double>? shares,
      Value<double>? costBasis,
      Value<double>? value,
      Value<String?>? notes,
      Value<Cycles>? cycle,
      Value<double>? monthlyAverageFactor}) {
    return PeriodicTransfersCompanion(
      id: id ?? this.id,
      nextExecutionDate: nextExecutionDate ?? this.nextExecutionDate,
      assetId: assetId ?? this.assetId,
      sendingAccountId: sendingAccountId ?? this.sendingAccountId,
      receivingAccountId: receivingAccountId ?? this.receivingAccountId,
      shares: shares ?? this.shares,
      costBasis: costBasis ?? this.costBasis,
      value: value ?? this.value,
      notes: notes ?? this.notes,
      cycle: cycle ?? this.cycle,
      monthlyAverageFactor: monthlyAverageFactor ?? this.monthlyAverageFactor,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (nextExecutionDate.present) {
      map['next_execution_date'] = Variable<int>(nextExecutionDate.value);
    }
    if (assetId.present) {
      map['asset_id'] = Variable<int>(assetId.value);
    }
    if (sendingAccountId.present) {
      map['sending_account_id'] = Variable<int>(sendingAccountId.value);
    }
    if (receivingAccountId.present) {
      map['receiving_account_id'] = Variable<int>(receivingAccountId.value);
    }
    if (shares.present) {
      map['shares'] = Variable<double>(shares.value);
    }
    if (costBasis.present) {
      map['cost_basis'] = Variable<double>(costBasis.value);
    }
    if (value.present) {
      map['value'] = Variable<double>(value.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (cycle.present) {
      map['cycle'] = Variable<String>(
          $PeriodicTransfersTable.$convertercycle.toSql(cycle.value));
    }
    if (monthlyAverageFactor.present) {
      map['monthly_average_factor'] =
          Variable<double>(monthlyAverageFactor.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PeriodicTransfersCompanion(')
          ..write('id: $id, ')
          ..write('nextExecutionDate: $nextExecutionDate, ')
          ..write('assetId: $assetId, ')
          ..write('sendingAccountId: $sendingAccountId, ')
          ..write('receivingAccountId: $receivingAccountId, ')
          ..write('shares: $shares, ')
          ..write('costBasis: $costBasis, ')
          ..write('value: $value, ')
          ..write('notes: $notes, ')
          ..write('cycle: $cycle, ')
          ..write('monthlyAverageFactor: $monthlyAverageFactor')
          ..write(')'))
        .toString();
  }
}

class $AssetsOnAccountsTable extends AssetsOnAccounts
    with TableInfo<$AssetsOnAccountsTable, AssetOnAccount> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AssetsOnAccountsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _accountIdMeta =
      const VerificationMeta('accountId');
  @override
  late final GeneratedColumn<int> accountId = GeneratedColumn<int>(
      'account_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES accounts (id)'));
  static const VerificationMeta _assetIdMeta =
      const VerificationMeta('assetId');
  @override
  late final GeneratedColumn<int> assetId = GeneratedColumn<int>(
      'asset_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES assets (id)'));
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<double> value = GeneratedColumn<double>(
      'value', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _sharesMeta = const VerificationMeta('shares');
  @override
  late final GeneratedColumn<double> shares = GeneratedColumn<double>(
      'shares', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _netCostBasisMeta =
      const VerificationMeta('netCostBasis');
  @override
  late final GeneratedColumn<double> netCostBasis = GeneratedColumn<double>(
      'net_cost_basis', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _brokerCostBasisMeta =
      const VerificationMeta('brokerCostBasis');
  @override
  late final GeneratedColumn<double> brokerCostBasis = GeneratedColumn<double>(
      'broker_cost_basis', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _buyFeeTotalMeta =
      const VerificationMeta('buyFeeTotal');
  @override
  late final GeneratedColumn<double> buyFeeTotal = GeneratedColumn<double>(
      'buy_fee_total', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  List<GeneratedColumn> get $columns => [
        accountId,
        assetId,
        value,
        shares,
        netCostBasis,
        brokerCostBasis,
        buyFeeTotal
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'assets_on_accounts';
  @override
  VerificationContext validateIntegrity(Insertable<AssetOnAccount> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('account_id')) {
      context.handle(_accountIdMeta,
          accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta));
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('asset_id')) {
      context.handle(_assetIdMeta,
          assetId.isAcceptableOrUnknown(data['asset_id']!, _assetIdMeta));
    } else if (isInserting) {
      context.missing(_assetIdMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
          _valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    }
    if (data.containsKey('shares')) {
      context.handle(_sharesMeta,
          shares.isAcceptableOrUnknown(data['shares']!, _sharesMeta));
    }
    if (data.containsKey('net_cost_basis')) {
      context.handle(
          _netCostBasisMeta,
          netCostBasis.isAcceptableOrUnknown(
              data['net_cost_basis']!, _netCostBasisMeta));
    }
    if (data.containsKey('broker_cost_basis')) {
      context.handle(
          _brokerCostBasisMeta,
          brokerCostBasis.isAcceptableOrUnknown(
              data['broker_cost_basis']!, _brokerCostBasisMeta));
    }
    if (data.containsKey('buy_fee_total')) {
      context.handle(
          _buyFeeTotalMeta,
          buyFeeTotal.isAcceptableOrUnknown(
              data['buy_fee_total']!, _buyFeeTotalMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {accountId, assetId};
  @override
  AssetOnAccount map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AssetOnAccount(
      accountId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}account_id'])!,
      assetId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}asset_id'])!,
      value: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}value'])!,
      shares: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}shares'])!,
      netCostBasis: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}net_cost_basis'])!,
      brokerCostBasis: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}broker_cost_basis'])!,
      buyFeeTotal: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}buy_fee_total'])!,
    );
  }

  @override
  $AssetsOnAccountsTable createAlias(String alias) {
    return $AssetsOnAccountsTable(attachedDatabase, alias);
  }
}

class AssetOnAccount extends DataClass implements Insertable<AssetOnAccount> {
  final int accountId;
  final int assetId;
  final double value;
  final double shares;
  final double netCostBasis;
  final double brokerCostBasis;
  final double buyFeeTotal;
  const AssetOnAccount(
      {required this.accountId,
      required this.assetId,
      required this.value,
      required this.shares,
      required this.netCostBasis,
      required this.brokerCostBasis,
      required this.buyFeeTotal});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['account_id'] = Variable<int>(accountId);
    map['asset_id'] = Variable<int>(assetId);
    map['value'] = Variable<double>(value);
    map['shares'] = Variable<double>(shares);
    map['net_cost_basis'] = Variable<double>(netCostBasis);
    map['broker_cost_basis'] = Variable<double>(brokerCostBasis);
    map['buy_fee_total'] = Variable<double>(buyFeeTotal);
    return map;
  }

  AssetsOnAccountsCompanion toCompanion(bool nullToAbsent) {
    return AssetsOnAccountsCompanion(
      accountId: Value(accountId),
      assetId: Value(assetId),
      value: Value(value),
      shares: Value(shares),
      netCostBasis: Value(netCostBasis),
      brokerCostBasis: Value(brokerCostBasis),
      buyFeeTotal: Value(buyFeeTotal),
    );
  }

  factory AssetOnAccount.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AssetOnAccount(
      accountId: serializer.fromJson<int>(json['accountId']),
      assetId: serializer.fromJson<int>(json['assetId']),
      value: serializer.fromJson<double>(json['value']),
      shares: serializer.fromJson<double>(json['shares']),
      netCostBasis: serializer.fromJson<double>(json['netCostBasis']),
      brokerCostBasis: serializer.fromJson<double>(json['brokerCostBasis']),
      buyFeeTotal: serializer.fromJson<double>(json['buyFeeTotal']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'accountId': serializer.toJson<int>(accountId),
      'assetId': serializer.toJson<int>(assetId),
      'value': serializer.toJson<double>(value),
      'shares': serializer.toJson<double>(shares),
      'netCostBasis': serializer.toJson<double>(netCostBasis),
      'brokerCostBasis': serializer.toJson<double>(brokerCostBasis),
      'buyFeeTotal': serializer.toJson<double>(buyFeeTotal),
    };
  }

  AssetOnAccount copyWith(
          {int? accountId,
          int? assetId,
          double? value,
          double? shares,
          double? netCostBasis,
          double? brokerCostBasis,
          double? buyFeeTotal}) =>
      AssetOnAccount(
        accountId: accountId ?? this.accountId,
        assetId: assetId ?? this.assetId,
        value: value ?? this.value,
        shares: shares ?? this.shares,
        netCostBasis: netCostBasis ?? this.netCostBasis,
        brokerCostBasis: brokerCostBasis ?? this.brokerCostBasis,
        buyFeeTotal: buyFeeTotal ?? this.buyFeeTotal,
      );
  AssetOnAccount copyWithCompanion(AssetsOnAccountsCompanion data) {
    return AssetOnAccount(
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      assetId: data.assetId.present ? data.assetId.value : this.assetId,
      value: data.value.present ? data.value.value : this.value,
      shares: data.shares.present ? data.shares.value : this.shares,
      netCostBasis: data.netCostBasis.present
          ? data.netCostBasis.value
          : this.netCostBasis,
      brokerCostBasis: data.brokerCostBasis.present
          ? data.brokerCostBasis.value
          : this.brokerCostBasis,
      buyFeeTotal:
          data.buyFeeTotal.present ? data.buyFeeTotal.value : this.buyFeeTotal,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AssetOnAccount(')
          ..write('accountId: $accountId, ')
          ..write('assetId: $assetId, ')
          ..write('value: $value, ')
          ..write('shares: $shares, ')
          ..write('netCostBasis: $netCostBasis, ')
          ..write('brokerCostBasis: $brokerCostBasis, ')
          ..write('buyFeeTotal: $buyFeeTotal')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(accountId, assetId, value, shares,
      netCostBasis, brokerCostBasis, buyFeeTotal);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AssetOnAccount &&
          other.accountId == this.accountId &&
          other.assetId == this.assetId &&
          other.value == this.value &&
          other.shares == this.shares &&
          other.netCostBasis == this.netCostBasis &&
          other.brokerCostBasis == this.brokerCostBasis &&
          other.buyFeeTotal == this.buyFeeTotal);
}

class AssetsOnAccountsCompanion extends UpdateCompanion<AssetOnAccount> {
  final Value<int> accountId;
  final Value<int> assetId;
  final Value<double> value;
  final Value<double> shares;
  final Value<double> netCostBasis;
  final Value<double> brokerCostBasis;
  final Value<double> buyFeeTotal;
  final Value<int> rowid;
  const AssetsOnAccountsCompanion({
    this.accountId = const Value.absent(),
    this.assetId = const Value.absent(),
    this.value = const Value.absent(),
    this.shares = const Value.absent(),
    this.netCostBasis = const Value.absent(),
    this.brokerCostBasis = const Value.absent(),
    this.buyFeeTotal = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AssetsOnAccountsCompanion.insert({
    required int accountId,
    required int assetId,
    this.value = const Value.absent(),
    this.shares = const Value.absent(),
    this.netCostBasis = const Value.absent(),
    this.brokerCostBasis = const Value.absent(),
    this.buyFeeTotal = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : accountId = Value(accountId),
        assetId = Value(assetId);
  static Insertable<AssetOnAccount> custom({
    Expression<int>? accountId,
    Expression<int>? assetId,
    Expression<double>? value,
    Expression<double>? shares,
    Expression<double>? netCostBasis,
    Expression<double>? brokerCostBasis,
    Expression<double>? buyFeeTotal,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (accountId != null) 'account_id': accountId,
      if (assetId != null) 'asset_id': assetId,
      if (value != null) 'value': value,
      if (shares != null) 'shares': shares,
      if (netCostBasis != null) 'net_cost_basis': netCostBasis,
      if (brokerCostBasis != null) 'broker_cost_basis': brokerCostBasis,
      if (buyFeeTotal != null) 'buy_fee_total': buyFeeTotal,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AssetsOnAccountsCompanion copyWith(
      {Value<int>? accountId,
      Value<int>? assetId,
      Value<double>? value,
      Value<double>? shares,
      Value<double>? netCostBasis,
      Value<double>? brokerCostBasis,
      Value<double>? buyFeeTotal,
      Value<int>? rowid}) {
    return AssetsOnAccountsCompanion(
      accountId: accountId ?? this.accountId,
      assetId: assetId ?? this.assetId,
      value: value ?? this.value,
      shares: shares ?? this.shares,
      netCostBasis: netCostBasis ?? this.netCostBasis,
      brokerCostBasis: brokerCostBasis ?? this.brokerCostBasis,
      buyFeeTotal: buyFeeTotal ?? this.buyFeeTotal,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (accountId.present) {
      map['account_id'] = Variable<int>(accountId.value);
    }
    if (assetId.present) {
      map['asset_id'] = Variable<int>(assetId.value);
    }
    if (value.present) {
      map['value'] = Variable<double>(value.value);
    }
    if (shares.present) {
      map['shares'] = Variable<double>(shares.value);
    }
    if (netCostBasis.present) {
      map['net_cost_basis'] = Variable<double>(netCostBasis.value);
    }
    if (brokerCostBasis.present) {
      map['broker_cost_basis'] = Variable<double>(brokerCostBasis.value);
    }
    if (buyFeeTotal.present) {
      map['buy_fee_total'] = Variable<double>(buyFeeTotal.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AssetsOnAccountsCompanion(')
          ..write('accountId: $accountId, ')
          ..write('assetId: $assetId, ')
          ..write('value: $value, ')
          ..write('shares: $shares, ')
          ..write('netCostBasis: $netCostBasis, ')
          ..write('brokerCostBasis: $brokerCostBasis, ')
          ..write('buyFeeTotal: $buyFeeTotal, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GoalsTable extends Goals with TableInfo<$GoalsTable, Goal> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GoalsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _assetIdMeta =
      const VerificationMeta('assetId');
  @override
  late final GeneratedColumn<int> assetId = GeneratedColumn<int>(
      'asset_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES assets (id)'),
      defaultValue: const Constant(1));
  static const VerificationMeta _accountIdMeta =
      const VerificationMeta('accountId');
  @override
  late final GeneratedColumn<int> accountId = GeneratedColumn<int>(
      'account_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES accounts (id)'));
  static const VerificationMeta _createdOnMeta =
      const VerificationMeta('createdOn');
  @override
  late final GeneratedColumn<int> createdOn = GeneratedColumn<int>(
      'created_on', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _targetDateMeta =
      const VerificationMeta('targetDate');
  @override
  late final GeneratedColumn<int> targetDate = GeneratedColumn<int>(
      'target_date', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _targetSharesMeta =
      const VerificationMeta('targetShares');
  @override
  late final GeneratedColumn<double> targetShares = GeneratedColumn<double>(
      'target_shares', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _targetValueMeta =
      const VerificationMeta('targetValue');
  @override
  late final GeneratedColumn<double> targetValue = GeneratedColumn<double>(
      'target_value', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        assetId,
        accountId,
        createdOn,
        targetDate,
        targetShares,
        targetValue
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'goals';
  @override
  VerificationContext validateIntegrity(Insertable<Goal> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('asset_id')) {
      context.handle(_assetIdMeta,
          assetId.isAcceptableOrUnknown(data['asset_id']!, _assetIdMeta));
    }
    if (data.containsKey('account_id')) {
      context.handle(_accountIdMeta,
          accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta));
    }
    if (data.containsKey('created_on')) {
      context.handle(_createdOnMeta,
          createdOn.isAcceptableOrUnknown(data['created_on']!, _createdOnMeta));
    } else if (isInserting) {
      context.missing(_createdOnMeta);
    }
    if (data.containsKey('target_date')) {
      context.handle(
          _targetDateMeta,
          targetDate.isAcceptableOrUnknown(
              data['target_date']!, _targetDateMeta));
    } else if (isInserting) {
      context.missing(_targetDateMeta);
    }
    if (data.containsKey('target_shares')) {
      context.handle(
          _targetSharesMeta,
          targetShares.isAcceptableOrUnknown(
              data['target_shares']!, _targetSharesMeta));
    } else if (isInserting) {
      context.missing(_targetSharesMeta);
    }
    if (data.containsKey('target_value')) {
      context.handle(
          _targetValueMeta,
          targetValue.isAcceptableOrUnknown(
              data['target_value']!, _targetValueMeta));
    } else if (isInserting) {
      context.missing(_targetValueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Goal map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Goal(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      assetId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}asset_id']),
      accountId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}account_id']),
      createdOn: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_on'])!,
      targetDate: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}target_date'])!,
      targetShares: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}target_shares'])!,
      targetValue: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}target_value'])!,
    );
  }

  @override
  $GoalsTable createAlias(String alias) {
    return $GoalsTable(attachedDatabase, alias);
  }
}

class Goal extends DataClass implements Insertable<Goal> {
  final int id;
  final int? assetId;
  final int? accountId;
  final int createdOn;
  final int targetDate;
  final double targetShares;
  final double targetValue;
  const Goal(
      {required this.id,
      this.assetId,
      this.accountId,
      required this.createdOn,
      required this.targetDate,
      required this.targetShares,
      required this.targetValue});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || assetId != null) {
      map['asset_id'] = Variable<int>(assetId);
    }
    if (!nullToAbsent || accountId != null) {
      map['account_id'] = Variable<int>(accountId);
    }
    map['created_on'] = Variable<int>(createdOn);
    map['target_date'] = Variable<int>(targetDate);
    map['target_shares'] = Variable<double>(targetShares);
    map['target_value'] = Variable<double>(targetValue);
    return map;
  }

  GoalsCompanion toCompanion(bool nullToAbsent) {
    return GoalsCompanion(
      id: Value(id),
      assetId: assetId == null && nullToAbsent
          ? const Value.absent()
          : Value(assetId),
      accountId: accountId == null && nullToAbsent
          ? const Value.absent()
          : Value(accountId),
      createdOn: Value(createdOn),
      targetDate: Value(targetDate),
      targetShares: Value(targetShares),
      targetValue: Value(targetValue),
    );
  }

  factory Goal.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Goal(
      id: serializer.fromJson<int>(json['id']),
      assetId: serializer.fromJson<int?>(json['assetId']),
      accountId: serializer.fromJson<int?>(json['accountId']),
      createdOn: serializer.fromJson<int>(json['createdOn']),
      targetDate: serializer.fromJson<int>(json['targetDate']),
      targetShares: serializer.fromJson<double>(json['targetShares']),
      targetValue: serializer.fromJson<double>(json['targetValue']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'assetId': serializer.toJson<int?>(assetId),
      'accountId': serializer.toJson<int?>(accountId),
      'createdOn': serializer.toJson<int>(createdOn),
      'targetDate': serializer.toJson<int>(targetDate),
      'targetShares': serializer.toJson<double>(targetShares),
      'targetValue': serializer.toJson<double>(targetValue),
    };
  }

  Goal copyWith(
          {int? id,
          Value<int?> assetId = const Value.absent(),
          Value<int?> accountId = const Value.absent(),
          int? createdOn,
          int? targetDate,
          double? targetShares,
          double? targetValue}) =>
      Goal(
        id: id ?? this.id,
        assetId: assetId.present ? assetId.value : this.assetId,
        accountId: accountId.present ? accountId.value : this.accountId,
        createdOn: createdOn ?? this.createdOn,
        targetDate: targetDate ?? this.targetDate,
        targetShares: targetShares ?? this.targetShares,
        targetValue: targetValue ?? this.targetValue,
      );
  Goal copyWithCompanion(GoalsCompanion data) {
    return Goal(
      id: data.id.present ? data.id.value : this.id,
      assetId: data.assetId.present ? data.assetId.value : this.assetId,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      createdOn: data.createdOn.present ? data.createdOn.value : this.createdOn,
      targetDate:
          data.targetDate.present ? data.targetDate.value : this.targetDate,
      targetShares: data.targetShares.present
          ? data.targetShares.value
          : this.targetShares,
      targetValue:
          data.targetValue.present ? data.targetValue.value : this.targetValue,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Goal(')
          ..write('id: $id, ')
          ..write('assetId: $assetId, ')
          ..write('accountId: $accountId, ')
          ..write('createdOn: $createdOn, ')
          ..write('targetDate: $targetDate, ')
          ..write('targetShares: $targetShares, ')
          ..write('targetValue: $targetValue')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, assetId, accountId, createdOn, targetDate, targetShares, targetValue);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Goal &&
          other.id == this.id &&
          other.assetId == this.assetId &&
          other.accountId == this.accountId &&
          other.createdOn == this.createdOn &&
          other.targetDate == this.targetDate &&
          other.targetShares == this.targetShares &&
          other.targetValue == this.targetValue);
}

class GoalsCompanion extends UpdateCompanion<Goal> {
  final Value<int> id;
  final Value<int?> assetId;
  final Value<int?> accountId;
  final Value<int> createdOn;
  final Value<int> targetDate;
  final Value<double> targetShares;
  final Value<double> targetValue;
  const GoalsCompanion({
    this.id = const Value.absent(),
    this.assetId = const Value.absent(),
    this.accountId = const Value.absent(),
    this.createdOn = const Value.absent(),
    this.targetDate = const Value.absent(),
    this.targetShares = const Value.absent(),
    this.targetValue = const Value.absent(),
  });
  GoalsCompanion.insert({
    this.id = const Value.absent(),
    this.assetId = const Value.absent(),
    this.accountId = const Value.absent(),
    required int createdOn,
    required int targetDate,
    required double targetShares,
    required double targetValue,
  })  : createdOn = Value(createdOn),
        targetDate = Value(targetDate),
        targetShares = Value(targetShares),
        targetValue = Value(targetValue);
  static Insertable<Goal> custom({
    Expression<int>? id,
    Expression<int>? assetId,
    Expression<int>? accountId,
    Expression<int>? createdOn,
    Expression<int>? targetDate,
    Expression<double>? targetShares,
    Expression<double>? targetValue,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (assetId != null) 'asset_id': assetId,
      if (accountId != null) 'account_id': accountId,
      if (createdOn != null) 'created_on': createdOn,
      if (targetDate != null) 'target_date': targetDate,
      if (targetShares != null) 'target_shares': targetShares,
      if (targetValue != null) 'target_value': targetValue,
    });
  }

  GoalsCompanion copyWith(
      {Value<int>? id,
      Value<int?>? assetId,
      Value<int?>? accountId,
      Value<int>? createdOn,
      Value<int>? targetDate,
      Value<double>? targetShares,
      Value<double>? targetValue}) {
    return GoalsCompanion(
      id: id ?? this.id,
      assetId: assetId ?? this.assetId,
      accountId: accountId ?? this.accountId,
      createdOn: createdOn ?? this.createdOn,
      targetDate: targetDate ?? this.targetDate,
      targetShares: targetShares ?? this.targetShares,
      targetValue: targetValue ?? this.targetValue,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (assetId.present) {
      map['asset_id'] = Variable<int>(assetId.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<int>(accountId.value);
    }
    if (createdOn.present) {
      map['created_on'] = Variable<int>(createdOn.value);
    }
    if (targetDate.present) {
      map['target_date'] = Variable<int>(targetDate.value);
    }
    if (targetShares.present) {
      map['target_shares'] = Variable<double>(targetShares.value);
    }
    if (targetValue.present) {
      map['target_value'] = Variable<double>(targetValue.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GoalsCompanion(')
          ..write('id: $id, ')
          ..write('assetId: $assetId, ')
          ..write('accountId: $accountId, ')
          ..write('createdOn: $createdOn, ')
          ..write('targetDate: $targetDate, ')
          ..write('targetShares: $targetShares, ')
          ..write('targetValue: $targetValue')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $AccountsTable accounts = $AccountsTable(this);
  late final $AssetsTable assets = $AssetsTable(this);
  late final $BookingsTable bookings = $BookingsTable(this);
  late final $TransfersTable transfers = $TransfersTable(this);
  late final $TradesTable trades = $TradesTable(this);
  late final $PeriodicBookingsTable periodicBookings =
      $PeriodicBookingsTable(this);
  late final $PeriodicTransfersTable periodicTransfers =
      $PeriodicTransfersTable(this);
  late final $AssetsOnAccountsTable assetsOnAccounts =
      $AssetsOnAccountsTable(this);
  late final $GoalsTable goals = $GoalsTable(this);
  late final Index bookingsAccountIdDate = Index('bookings_account_id_date',
      'CREATE INDEX bookings_account_id_date ON bookings (account_id, date)');
  late final Index transfersSendingAccountIdDate = Index(
      'transfers_sending_account_id_date',
      'CREATE INDEX transfers_sending_account_id_date ON transfers (sending_account_id, date)');
  late final Index transfersReceivingAccountIdDate = Index(
      'transfers_receiving_account_id_date',
      'CREATE INDEX transfers_receiving_account_id_date ON transfers (receiving_account_id, date)');
  late final Index tradesAssetIdDatetime = Index('trades_asset_id_datetime',
      'CREATE INDEX trades_asset_id_datetime ON trades (asset_id, datetime)');
  late final Index tradesSourceAccountIdDatetime = Index(
      'trades_source_account_id_datetime',
      'CREATE INDEX trades_source_account_id_datetime ON trades (source_account_id, datetime)');
  late final Index tradesTargetAccountIdDatetime = Index(
      'trades_target_account_id_datetime',
      'CREATE INDEX trades_target_account_id_datetime ON trades (target_account_id, datetime)');
  late final Index periodicBookingsNextExecutionDate = Index(
      'periodic_bookings_next_execution_date',
      'CREATE INDEX periodic_bookings_next_execution_date ON periodic_bookings (next_execution_date)');
  late final Index periodicTransfersNextExecutionDate = Index(
      'periodic_transfers_next_execution_date',
      'CREATE INDEX periodic_transfers_next_execution_date ON periodic_transfers (next_execution_date)');
  late final Index goalsTargetDate = Index('goals_target_date',
      'CREATE INDEX goals_target_date ON goals (target_date)');
  late final AccountsDao accountsDao = AccountsDao(this as AppDatabase);
  late final AnalysisDao analysisDao = AnalysisDao(this as AppDatabase);
  late final AssetsDao assetsDao = AssetsDao(this as AppDatabase);
  late final AssetsOnAccountsDao assetsOnAccountsDao =
      AssetsOnAccountsDao(this as AppDatabase);
  late final BookingsDao bookingsDao = BookingsDao(this as AppDatabase);
  late final GoalsDao goalsDao = GoalsDao(this as AppDatabase);
  late final PeriodicBookingsDao periodicBookingsDao =
      PeriodicBookingsDao(this as AppDatabase);
  late final PeriodicTransfersDao periodicTransfersDao =
      PeriodicTransfersDao(this as AppDatabase);
  late final TradesDao tradesDao = TradesDao(this as AppDatabase);
  late final TransfersDao transfersDao = TransfersDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        accounts,
        assets,
        bookings,
        transfers,
        trades,
        periodicBookings,
        periodicTransfers,
        assetsOnAccounts,
        goals,
        bookingsAccountIdDate,
        transfersSendingAccountIdDate,
        transfersReceivingAccountIdDate,
        tradesAssetIdDatetime,
        tradesSourceAccountIdDatetime,
        tradesTargetAccountIdDatetime,
        periodicBookingsNextExecutionDate,
        periodicTransfersNextExecutionDate,
        goalsTargetDate
      ];
}

typedef $$AccountsTableCreateCompanionBuilder = AccountsCompanion Function({
  Value<int> id,
  required String name,
  Value<double> balance,
  Value<double> initialBalance,
  required AccountTypes type,
  Value<bool> isArchived,
});
typedef $$AccountsTableUpdateCompanionBuilder = AccountsCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<double> balance,
  Value<double> initialBalance,
  Value<AccountTypes> type,
  Value<bool> isArchived,
});

final class $$AccountsTableReferences
    extends BaseReferences<_$AppDatabase, $AccountsTable, Account> {
  $$AccountsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$BookingsTable, List<Booking>> _bookingsRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.bookings,
          aliasName:
              $_aliasNameGenerator(db.accounts.id, db.bookings.accountId));

  $$BookingsTableProcessedTableManager get bookingsRefs {
    final manager = $$BookingsTableTableManager($_db, $_db.bookings)
        .filter((f) => f.accountId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_bookingsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$TransfersTable, List<Transfer>>
      _SendingTransfersTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.transfers,
              aliasName: $_aliasNameGenerator(
                  db.accounts.id, db.transfers.sendingAccountId));

  $$TransfersTableProcessedTableManager get SendingTransfers {
    final manager = $$TransfersTableTableManager($_db, $_db.transfers).filter(
        (f) => f.sendingAccountId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_SendingTransfersTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$TransfersTable, List<Transfer>>
      _ReceivingTransfersTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.transfers,
              aliasName: $_aliasNameGenerator(
                  db.accounts.id, db.transfers.receivingAccountId));

  $$TransfersTableProcessedTableManager get ReceivingTransfers {
    final manager = $$TransfersTableTableManager($_db, $_db.transfers).filter(
        (f) => f.receivingAccountId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_ReceivingTransfersTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$TradesTable, List<Trade>> _SourceTradesTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.trades,
          aliasName:
              $_aliasNameGenerator(db.accounts.id, db.trades.sourceAccountId));

  $$TradesTableProcessedTableManager get SourceTrades {
    final manager = $$TradesTableTableManager($_db, $_db.trades).filter(
        (f) => f.sourceAccountId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_SourceTradesTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$TradesTable, List<Trade>> _TargetTradesTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.trades,
          aliasName:
              $_aliasNameGenerator(db.accounts.id, db.trades.targetAccountId));

  $$TradesTableProcessedTableManager get TargetTrades {
    final manager = $$TradesTableTableManager($_db, $_db.trades).filter(
        (f) => f.targetAccountId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_TargetTradesTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$PeriodicBookingsTable, List<PeriodicBooking>>
      _periodicBookingsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.periodicBookings,
              aliasName: $_aliasNameGenerator(
                  db.accounts.id, db.periodicBookings.accountId));

  $$PeriodicBookingsTableProcessedTableManager get periodicBookingsRefs {
    final manager =
        $$PeriodicBookingsTableTableManager($_db, $_db.periodicBookings)
            .filter((f) => f.accountId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_periodicBookingsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$PeriodicTransfersTable, List<PeriodicTransfer>>
      _SendingPeriodicTransfersTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.periodicTransfers,
              aliasName: $_aliasNameGenerator(
                  db.accounts.id, db.periodicTransfers.sendingAccountId));

  $$PeriodicTransfersTableProcessedTableManager get SendingPeriodicTransfers {
    final manager = $$PeriodicTransfersTableTableManager(
            $_db, $_db.periodicTransfers)
        .filter(
            (f) => f.sendingAccountId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_SendingPeriodicTransfersTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$PeriodicTransfersTable, List<PeriodicTransfer>>
      _ReceivingPeriodicTransfersTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.periodicTransfers,
              aliasName: $_aliasNameGenerator(
                  db.accounts.id, db.periodicTransfers.receivingAccountId));

  $$PeriodicTransfersTableProcessedTableManager get ReceivingPeriodicTransfers {
    final manager = $$PeriodicTransfersTableTableManager(
            $_db, $_db.periodicTransfers)
        .filter(
            (f) => f.receivingAccountId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_ReceivingPeriodicTransfersTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$AssetsOnAccountsTable, List<AssetOnAccount>>
      _assetsOnAccountsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.assetsOnAccounts,
              aliasName: $_aliasNameGenerator(
                  db.accounts.id, db.assetsOnAccounts.accountId));

  $$AssetsOnAccountsTableProcessedTableManager get assetsOnAccountsRefs {
    final manager =
        $$AssetsOnAccountsTableTableManager($_db, $_db.assetsOnAccounts)
            .filter((f) => f.accountId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_assetsOnAccountsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$GoalsTable, List<Goal>> _goalsRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.goals,
          aliasName: $_aliasNameGenerator(db.accounts.id, db.goals.accountId));

  $$GoalsTableProcessedTableManager get goalsRefs {
    final manager = $$GoalsTableTableManager($_db, $_db.goals)
        .filter((f) => f.accountId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_goalsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$AccountsTableFilterComposer
    extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get balance => $composableBuilder(
      column: $table.balance, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get initialBalance => $composableBuilder(
      column: $table.initialBalance,
      builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<AccountTypes, AccountTypes, String> get type =>
      $composableBuilder(
          column: $table.type,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<bool> get isArchived => $composableBuilder(
      column: $table.isArchived, builder: (column) => ColumnFilters(column));

  Expression<bool> bookingsRefs(
      Expression<bool> Function($$BookingsTableFilterComposer f) f) {
    final $$BookingsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.bookings,
        getReferencedColumn: (t) => t.accountId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BookingsTableFilterComposer(
              $db: $db,
              $table: $db.bookings,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> SendingTransfers(
      Expression<bool> Function($$TransfersTableFilterComposer f) f) {
    final $$TransfersTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.transfers,
        getReferencedColumn: (t) => t.sendingAccountId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TransfersTableFilterComposer(
              $db: $db,
              $table: $db.transfers,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> ReceivingTransfers(
      Expression<bool> Function($$TransfersTableFilterComposer f) f) {
    final $$TransfersTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.transfers,
        getReferencedColumn: (t) => t.receivingAccountId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TransfersTableFilterComposer(
              $db: $db,
              $table: $db.transfers,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> SourceTrades(
      Expression<bool> Function($$TradesTableFilterComposer f) f) {
    final $$TradesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.trades,
        getReferencedColumn: (t) => t.sourceAccountId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TradesTableFilterComposer(
              $db: $db,
              $table: $db.trades,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> TargetTrades(
      Expression<bool> Function($$TradesTableFilterComposer f) f) {
    final $$TradesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.trades,
        getReferencedColumn: (t) => t.targetAccountId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TradesTableFilterComposer(
              $db: $db,
              $table: $db.trades,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> periodicBookingsRefs(
      Expression<bool> Function($$PeriodicBookingsTableFilterComposer f) f) {
    final $$PeriodicBookingsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.periodicBookings,
        getReferencedColumn: (t) => t.accountId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PeriodicBookingsTableFilterComposer(
              $db: $db,
              $table: $db.periodicBookings,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> SendingPeriodicTransfers(
      Expression<bool> Function($$PeriodicTransfersTableFilterComposer f) f) {
    final $$PeriodicTransfersTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.periodicTransfers,
        getReferencedColumn: (t) => t.sendingAccountId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PeriodicTransfersTableFilterComposer(
              $db: $db,
              $table: $db.periodicTransfers,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> ReceivingPeriodicTransfers(
      Expression<bool> Function($$PeriodicTransfersTableFilterComposer f) f) {
    final $$PeriodicTransfersTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.periodicTransfers,
        getReferencedColumn: (t) => t.receivingAccountId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PeriodicTransfersTableFilterComposer(
              $db: $db,
              $table: $db.periodicTransfers,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> assetsOnAccountsRefs(
      Expression<bool> Function($$AssetsOnAccountsTableFilterComposer f) f) {
    final $$AssetsOnAccountsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.assetsOnAccounts,
        getReferencedColumn: (t) => t.accountId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AssetsOnAccountsTableFilterComposer(
              $db: $db,
              $table: $db.assetsOnAccounts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> goalsRefs(
      Expression<bool> Function($$GoalsTableFilterComposer f) f) {
    final $$GoalsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.goals,
        getReferencedColumn: (t) => t.accountId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$GoalsTableFilterComposer(
              $db: $db,
              $table: $db.goals,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$AccountsTableOrderingComposer
    extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get balance => $composableBuilder(
      column: $table.balance, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get initialBalance => $composableBuilder(
      column: $table.initialBalance,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isArchived => $composableBuilder(
      column: $table.isArchived, builder: (column) => ColumnOrderings(column));
}

class $$AccountsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<double> get balance =>
      $composableBuilder(column: $table.balance, builder: (column) => column);

  GeneratedColumn<double> get initialBalance => $composableBuilder(
      column: $table.initialBalance, builder: (column) => column);

  GeneratedColumnWithTypeConverter<AccountTypes, String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<bool> get isArchived => $composableBuilder(
      column: $table.isArchived, builder: (column) => column);

  Expression<T> bookingsRefs<T extends Object>(
      Expression<T> Function($$BookingsTableAnnotationComposer a) f) {
    final $$BookingsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.bookings,
        getReferencedColumn: (t) => t.accountId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BookingsTableAnnotationComposer(
              $db: $db,
              $table: $db.bookings,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> SendingTransfers<T extends Object>(
      Expression<T> Function($$TransfersTableAnnotationComposer a) f) {
    final $$TransfersTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.transfers,
        getReferencedColumn: (t) => t.sendingAccountId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TransfersTableAnnotationComposer(
              $db: $db,
              $table: $db.transfers,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> ReceivingTransfers<T extends Object>(
      Expression<T> Function($$TransfersTableAnnotationComposer a) f) {
    final $$TransfersTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.transfers,
        getReferencedColumn: (t) => t.receivingAccountId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TransfersTableAnnotationComposer(
              $db: $db,
              $table: $db.transfers,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> SourceTrades<T extends Object>(
      Expression<T> Function($$TradesTableAnnotationComposer a) f) {
    final $$TradesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.trades,
        getReferencedColumn: (t) => t.sourceAccountId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TradesTableAnnotationComposer(
              $db: $db,
              $table: $db.trades,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> TargetTrades<T extends Object>(
      Expression<T> Function($$TradesTableAnnotationComposer a) f) {
    final $$TradesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.trades,
        getReferencedColumn: (t) => t.targetAccountId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TradesTableAnnotationComposer(
              $db: $db,
              $table: $db.trades,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> periodicBookingsRefs<T extends Object>(
      Expression<T> Function($$PeriodicBookingsTableAnnotationComposer a) f) {
    final $$PeriodicBookingsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.periodicBookings,
        getReferencedColumn: (t) => t.accountId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PeriodicBookingsTableAnnotationComposer(
              $db: $db,
              $table: $db.periodicBookings,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> SendingPeriodicTransfers<T extends Object>(
      Expression<T> Function($$PeriodicTransfersTableAnnotationComposer a) f) {
    final $$PeriodicTransfersTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.periodicTransfers,
            getReferencedColumn: (t) => t.sendingAccountId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$PeriodicTransfersTableAnnotationComposer(
                  $db: $db,
                  $table: $db.periodicTransfers,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }

  Expression<T> ReceivingPeriodicTransfers<T extends Object>(
      Expression<T> Function($$PeriodicTransfersTableAnnotationComposer a) f) {
    final $$PeriodicTransfersTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.periodicTransfers,
            getReferencedColumn: (t) => t.receivingAccountId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$PeriodicTransfersTableAnnotationComposer(
                  $db: $db,
                  $table: $db.periodicTransfers,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }

  Expression<T> assetsOnAccountsRefs<T extends Object>(
      Expression<T> Function($$AssetsOnAccountsTableAnnotationComposer a) f) {
    final $$AssetsOnAccountsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.assetsOnAccounts,
        getReferencedColumn: (t) => t.accountId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AssetsOnAccountsTableAnnotationComposer(
              $db: $db,
              $table: $db.assetsOnAccounts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> goalsRefs<T extends Object>(
      Expression<T> Function($$GoalsTableAnnotationComposer a) f) {
    final $$GoalsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.goals,
        getReferencedColumn: (t) => t.accountId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$GoalsTableAnnotationComposer(
              $db: $db,
              $table: $db.goals,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$AccountsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AccountsTable,
    Account,
    $$AccountsTableFilterComposer,
    $$AccountsTableOrderingComposer,
    $$AccountsTableAnnotationComposer,
    $$AccountsTableCreateCompanionBuilder,
    $$AccountsTableUpdateCompanionBuilder,
    (Account, $$AccountsTableReferences),
    Account,
    PrefetchHooks Function(
        {bool bookingsRefs,
        bool SendingTransfers,
        bool ReceivingTransfers,
        bool SourceTrades,
        bool TargetTrades,
        bool periodicBookingsRefs,
        bool SendingPeriodicTransfers,
        bool ReceivingPeriodicTransfers,
        bool assetsOnAccountsRefs,
        bool goalsRefs})> {
  $$AccountsTableTableManager(_$AppDatabase db, $AccountsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AccountsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AccountsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AccountsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<double> balance = const Value.absent(),
            Value<double> initialBalance = const Value.absent(),
            Value<AccountTypes> type = const Value.absent(),
            Value<bool> isArchived = const Value.absent(),
          }) =>
              AccountsCompanion(
            id: id,
            name: name,
            balance: balance,
            initialBalance: initialBalance,
            type: type,
            isArchived: isArchived,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            Value<double> balance = const Value.absent(),
            Value<double> initialBalance = const Value.absent(),
            required AccountTypes type,
            Value<bool> isArchived = const Value.absent(),
          }) =>
              AccountsCompanion.insert(
            id: id,
            name: name,
            balance: balance,
            initialBalance: initialBalance,
            type: type,
            isArchived: isArchived,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$AccountsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: (
              {bookingsRefs = false,
              SendingTransfers = false,
              ReceivingTransfers = false,
              SourceTrades = false,
              TargetTrades = false,
              periodicBookingsRefs = false,
              SendingPeriodicTransfers = false,
              ReceivingPeriodicTransfers = false,
              assetsOnAccountsRefs = false,
              goalsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (bookingsRefs) db.bookings,
                if (SendingTransfers) db.transfers,
                if (ReceivingTransfers) db.transfers,
                if (SourceTrades) db.trades,
                if (TargetTrades) db.trades,
                if (periodicBookingsRefs) db.periodicBookings,
                if (SendingPeriodicTransfers) db.periodicTransfers,
                if (ReceivingPeriodicTransfers) db.periodicTransfers,
                if (assetsOnAccountsRefs) db.assetsOnAccounts,
                if (goalsRefs) db.goals
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (bookingsRefs)
                    await $_getPrefetchedData<Account, $AccountsTable, Booking>(
                        currentTable: table,
                        referencedTable:
                            $$AccountsTableReferences._bookingsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$AccountsTableReferences(db, table, p0)
                                .bookingsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.accountId == item.id),
                        typedResults: items),
                  if (SendingTransfers)
                    await $_getPrefetchedData<Account, $AccountsTable,
                            Transfer>(
                        currentTable: table,
                        referencedTable:
                            $$AccountsTableReferences._SendingTransfersTable(
                                db),
                        managerFromTypedResult: (p0) =>
                            $$AccountsTableReferences(db, table, p0)
                                .SendingTransfers,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.sendingAccountId == item.id),
                        typedResults: items),
                  if (ReceivingTransfers)
                    await $_getPrefetchedData<Account, $AccountsTable,
                            Transfer>(
                        currentTable: table,
                        referencedTable:
                            $$AccountsTableReferences._ReceivingTransfersTable(
                                db),
                        managerFromTypedResult: (p0) =>
                            $$AccountsTableReferences(db, table, p0)
                                .ReceivingTransfers,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.receivingAccountId == item.id),
                        typedResults: items),
                  if (SourceTrades)
                    await $_getPrefetchedData<Account, $AccountsTable, Trade>(
                        currentTable: table,
                        referencedTable:
                            $$AccountsTableReferences._SourceTradesTable(db),
                        managerFromTypedResult: (p0) =>
                            $$AccountsTableReferences(db, table, p0)
                                .SourceTrades,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.sourceAccountId == item.id),
                        typedResults: items),
                  if (TargetTrades)
                    await $_getPrefetchedData<Account, $AccountsTable, Trade>(
                        currentTable: table,
                        referencedTable:
                            $$AccountsTableReferences._TargetTradesTable(db),
                        managerFromTypedResult: (p0) =>
                            $$AccountsTableReferences(db, table, p0)
                                .TargetTrades,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.targetAccountId == item.id),
                        typedResults: items),
                  if (periodicBookingsRefs)
                    await $_getPrefetchedData<Account, $AccountsTable,
                            PeriodicBooking>(
                        currentTable: table,
                        referencedTable: $$AccountsTableReferences
                            ._periodicBookingsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$AccountsTableReferences(db, table, p0)
                                .periodicBookingsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.accountId == item.id),
                        typedResults: items),
                  if (SendingPeriodicTransfers)
                    await $_getPrefetchedData<Account, $AccountsTable,
                            PeriodicTransfer>(
                        currentTable: table,
                        referencedTable: $$AccountsTableReferences
                            ._SendingPeriodicTransfersTable(db),
                        managerFromTypedResult: (p0) =>
                            $$AccountsTableReferences(db, table, p0)
                                .SendingPeriodicTransfers,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.sendingAccountId == item.id),
                        typedResults: items),
                  if (ReceivingPeriodicTransfers)
                    await $_getPrefetchedData<Account, $AccountsTable,
                            PeriodicTransfer>(
                        currentTable: table,
                        referencedTable: $$AccountsTableReferences
                            ._ReceivingPeriodicTransfersTable(db),
                        managerFromTypedResult: (p0) =>
                            $$AccountsTableReferences(db, table, p0)
                                .ReceivingPeriodicTransfers,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.receivingAccountId == item.id),
                        typedResults: items),
                  if (assetsOnAccountsRefs)
                    await $_getPrefetchedData<Account, $AccountsTable,
                            AssetOnAccount>(
                        currentTable: table,
                        referencedTable: $$AccountsTableReferences
                            ._assetsOnAccountsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$AccountsTableReferences(db, table, p0)
                                .assetsOnAccountsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.accountId == item.id),
                        typedResults: items),
                  if (goalsRefs)
                    await $_getPrefetchedData<Account, $AccountsTable, Goal>(
                        currentTable: table,
                        referencedTable:
                            $$AccountsTableReferences._goalsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$AccountsTableReferences(db, table, p0).goalsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.accountId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$AccountsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $AccountsTable,
    Account,
    $$AccountsTableFilterComposer,
    $$AccountsTableOrderingComposer,
    $$AccountsTableAnnotationComposer,
    $$AccountsTableCreateCompanionBuilder,
    $$AccountsTableUpdateCompanionBuilder,
    (Account, $$AccountsTableReferences),
    Account,
    PrefetchHooks Function(
        {bool bookingsRefs,
        bool SendingTransfers,
        bool ReceivingTransfers,
        bool SourceTrades,
        bool TargetTrades,
        bool periodicBookingsRefs,
        bool SendingPeriodicTransfers,
        bool ReceivingPeriodicTransfers,
        bool assetsOnAccountsRefs,
        bool goalsRefs})>;
typedef $$AssetsTableCreateCompanionBuilder = AssetsCompanion Function({
  Value<int> id,
  required String name,
  required AssetTypes type,
  required String tickerSymbol,
  Value<String?> currencySymbol,
  Value<double> value,
  Value<double> shares,
  Value<double> netCostBasis,
  Value<double> brokerCostBasis,
  Value<double> buyFeeTotal,
  Value<bool> isArchived,
});
typedef $$AssetsTableUpdateCompanionBuilder = AssetsCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<AssetTypes> type,
  Value<String> tickerSymbol,
  Value<String?> currencySymbol,
  Value<double> value,
  Value<double> shares,
  Value<double> netCostBasis,
  Value<double> brokerCostBasis,
  Value<double> buyFeeTotal,
  Value<bool> isArchived,
});

final class $$AssetsTableReferences
    extends BaseReferences<_$AppDatabase, $AssetsTable, Asset> {
  $$AssetsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$BookingsTable, List<Booking>> _bookingsRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.bookings,
          aliasName: $_aliasNameGenerator(db.assets.id, db.bookings.assetId));

  $$BookingsTableProcessedTableManager get bookingsRefs {
    final manager = $$BookingsTableTableManager($_db, $_db.bookings)
        .filter((f) => f.assetId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_bookingsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$TransfersTable, List<Transfer>>
      _transfersRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
          db.transfers,
          aliasName: $_aliasNameGenerator(db.assets.id, db.transfers.assetId));

  $$TransfersTableProcessedTableManager get transfersRefs {
    final manager = $$TransfersTableTableManager($_db, $_db.transfers)
        .filter((f) => f.assetId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_transfersRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$TradesTable, List<Trade>> _tradesRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.trades,
          aliasName: $_aliasNameGenerator(db.assets.id, db.trades.assetId));

  $$TradesTableProcessedTableManager get tradesRefs {
    final manager = $$TradesTableTableManager($_db, $_db.trades)
        .filter((f) => f.assetId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_tradesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$PeriodicBookingsTable, List<PeriodicBooking>>
      _periodicBookingsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.periodicBookings,
              aliasName: $_aliasNameGenerator(
                  db.assets.id, db.periodicBookings.assetId));

  $$PeriodicBookingsTableProcessedTableManager get periodicBookingsRefs {
    final manager =
        $$PeriodicBookingsTableTableManager($_db, $_db.periodicBookings)
            .filter((f) => f.assetId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_periodicBookingsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$PeriodicTransfersTable, List<PeriodicTransfer>>
      _periodicTransfersRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.periodicTransfers,
              aliasName: $_aliasNameGenerator(
                  db.assets.id, db.periodicTransfers.assetId));

  $$PeriodicTransfersTableProcessedTableManager get periodicTransfersRefs {
    final manager =
        $$PeriodicTransfersTableTableManager($_db, $_db.periodicTransfers)
            .filter((f) => f.assetId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_periodicTransfersRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$AssetsOnAccountsTable, List<AssetOnAccount>>
      _assetsOnAccountsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.assetsOnAccounts,
              aliasName: $_aliasNameGenerator(
                  db.assets.id, db.assetsOnAccounts.assetId));

  $$AssetsOnAccountsTableProcessedTableManager get assetsOnAccountsRefs {
    final manager =
        $$AssetsOnAccountsTableTableManager($_db, $_db.assetsOnAccounts)
            .filter((f) => f.assetId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_assetsOnAccountsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$GoalsTable, List<Goal>> _goalsRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.goals,
          aliasName: $_aliasNameGenerator(db.assets.id, db.goals.assetId));

  $$GoalsTableProcessedTableManager get goalsRefs {
    final manager = $$GoalsTableTableManager($_db, $_db.goals)
        .filter((f) => f.assetId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_goalsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$AssetsTableFilterComposer
    extends Composer<_$AppDatabase, $AssetsTable> {
  $$AssetsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<AssetTypes, AssetTypes, String> get type =>
      $composableBuilder(
          column: $table.type,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<String> get tickerSymbol => $composableBuilder(
      column: $table.tickerSymbol, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get currencySymbol => $composableBuilder(
      column: $table.currencySymbol,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get shares => $composableBuilder(
      column: $table.shares, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get netCostBasis => $composableBuilder(
      column: $table.netCostBasis, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get brokerCostBasis => $composableBuilder(
      column: $table.brokerCostBasis,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get buyFeeTotal => $composableBuilder(
      column: $table.buyFeeTotal, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isArchived => $composableBuilder(
      column: $table.isArchived, builder: (column) => ColumnFilters(column));

  Expression<bool> bookingsRefs(
      Expression<bool> Function($$BookingsTableFilterComposer f) f) {
    final $$BookingsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.bookings,
        getReferencedColumn: (t) => t.assetId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BookingsTableFilterComposer(
              $db: $db,
              $table: $db.bookings,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> transfersRefs(
      Expression<bool> Function($$TransfersTableFilterComposer f) f) {
    final $$TransfersTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.transfers,
        getReferencedColumn: (t) => t.assetId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TransfersTableFilterComposer(
              $db: $db,
              $table: $db.transfers,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> tradesRefs(
      Expression<bool> Function($$TradesTableFilterComposer f) f) {
    final $$TradesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.trades,
        getReferencedColumn: (t) => t.assetId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TradesTableFilterComposer(
              $db: $db,
              $table: $db.trades,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> periodicBookingsRefs(
      Expression<bool> Function($$PeriodicBookingsTableFilterComposer f) f) {
    final $$PeriodicBookingsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.periodicBookings,
        getReferencedColumn: (t) => t.assetId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PeriodicBookingsTableFilterComposer(
              $db: $db,
              $table: $db.periodicBookings,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> periodicTransfersRefs(
      Expression<bool> Function($$PeriodicTransfersTableFilterComposer f) f) {
    final $$PeriodicTransfersTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.periodicTransfers,
        getReferencedColumn: (t) => t.assetId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PeriodicTransfersTableFilterComposer(
              $db: $db,
              $table: $db.periodicTransfers,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> assetsOnAccountsRefs(
      Expression<bool> Function($$AssetsOnAccountsTableFilterComposer f) f) {
    final $$AssetsOnAccountsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.assetsOnAccounts,
        getReferencedColumn: (t) => t.assetId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AssetsOnAccountsTableFilterComposer(
              $db: $db,
              $table: $db.assetsOnAccounts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> goalsRefs(
      Expression<bool> Function($$GoalsTableFilterComposer f) f) {
    final $$GoalsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.goals,
        getReferencedColumn: (t) => t.assetId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$GoalsTableFilterComposer(
              $db: $db,
              $table: $db.goals,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$AssetsTableOrderingComposer
    extends Composer<_$AppDatabase, $AssetsTable> {
  $$AssetsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tickerSymbol => $composableBuilder(
      column: $table.tickerSymbol,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get currencySymbol => $composableBuilder(
      column: $table.currencySymbol,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get shares => $composableBuilder(
      column: $table.shares, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get netCostBasis => $composableBuilder(
      column: $table.netCostBasis,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get brokerCostBasis => $composableBuilder(
      column: $table.brokerCostBasis,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get buyFeeTotal => $composableBuilder(
      column: $table.buyFeeTotal, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isArchived => $composableBuilder(
      column: $table.isArchived, builder: (column) => ColumnOrderings(column));
}

class $$AssetsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AssetsTable> {
  $$AssetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumnWithTypeConverter<AssetTypes, String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get tickerSymbol => $composableBuilder(
      column: $table.tickerSymbol, builder: (column) => column);

  GeneratedColumn<String> get currencySymbol => $composableBuilder(
      column: $table.currencySymbol, builder: (column) => column);

  GeneratedColumn<double> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<double> get shares =>
      $composableBuilder(column: $table.shares, builder: (column) => column);

  GeneratedColumn<double> get netCostBasis => $composableBuilder(
      column: $table.netCostBasis, builder: (column) => column);

  GeneratedColumn<double> get brokerCostBasis => $composableBuilder(
      column: $table.brokerCostBasis, builder: (column) => column);

  GeneratedColumn<double> get buyFeeTotal => $composableBuilder(
      column: $table.buyFeeTotal, builder: (column) => column);

  GeneratedColumn<bool> get isArchived => $composableBuilder(
      column: $table.isArchived, builder: (column) => column);

  Expression<T> bookingsRefs<T extends Object>(
      Expression<T> Function($$BookingsTableAnnotationComposer a) f) {
    final $$BookingsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.bookings,
        getReferencedColumn: (t) => t.assetId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BookingsTableAnnotationComposer(
              $db: $db,
              $table: $db.bookings,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> transfersRefs<T extends Object>(
      Expression<T> Function($$TransfersTableAnnotationComposer a) f) {
    final $$TransfersTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.transfers,
        getReferencedColumn: (t) => t.assetId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TransfersTableAnnotationComposer(
              $db: $db,
              $table: $db.transfers,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> tradesRefs<T extends Object>(
      Expression<T> Function($$TradesTableAnnotationComposer a) f) {
    final $$TradesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.trades,
        getReferencedColumn: (t) => t.assetId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TradesTableAnnotationComposer(
              $db: $db,
              $table: $db.trades,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> periodicBookingsRefs<T extends Object>(
      Expression<T> Function($$PeriodicBookingsTableAnnotationComposer a) f) {
    final $$PeriodicBookingsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.periodicBookings,
        getReferencedColumn: (t) => t.assetId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PeriodicBookingsTableAnnotationComposer(
              $db: $db,
              $table: $db.periodicBookings,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> periodicTransfersRefs<T extends Object>(
      Expression<T> Function($$PeriodicTransfersTableAnnotationComposer a) f) {
    final $$PeriodicTransfersTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.periodicTransfers,
            getReferencedColumn: (t) => t.assetId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$PeriodicTransfersTableAnnotationComposer(
                  $db: $db,
                  $table: $db.periodicTransfers,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }

  Expression<T> assetsOnAccountsRefs<T extends Object>(
      Expression<T> Function($$AssetsOnAccountsTableAnnotationComposer a) f) {
    final $$AssetsOnAccountsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.assetsOnAccounts,
        getReferencedColumn: (t) => t.assetId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AssetsOnAccountsTableAnnotationComposer(
              $db: $db,
              $table: $db.assetsOnAccounts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> goalsRefs<T extends Object>(
      Expression<T> Function($$GoalsTableAnnotationComposer a) f) {
    final $$GoalsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.goals,
        getReferencedColumn: (t) => t.assetId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$GoalsTableAnnotationComposer(
              $db: $db,
              $table: $db.goals,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$AssetsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AssetsTable,
    Asset,
    $$AssetsTableFilterComposer,
    $$AssetsTableOrderingComposer,
    $$AssetsTableAnnotationComposer,
    $$AssetsTableCreateCompanionBuilder,
    $$AssetsTableUpdateCompanionBuilder,
    (Asset, $$AssetsTableReferences),
    Asset,
    PrefetchHooks Function(
        {bool bookingsRefs,
        bool transfersRefs,
        bool tradesRefs,
        bool periodicBookingsRefs,
        bool periodicTransfersRefs,
        bool assetsOnAccountsRefs,
        bool goalsRefs})> {
  $$AssetsTableTableManager(_$AppDatabase db, $AssetsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AssetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AssetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AssetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<AssetTypes> type = const Value.absent(),
            Value<String> tickerSymbol = const Value.absent(),
            Value<String?> currencySymbol = const Value.absent(),
            Value<double> value = const Value.absent(),
            Value<double> shares = const Value.absent(),
            Value<double> netCostBasis = const Value.absent(),
            Value<double> brokerCostBasis = const Value.absent(),
            Value<double> buyFeeTotal = const Value.absent(),
            Value<bool> isArchived = const Value.absent(),
          }) =>
              AssetsCompanion(
            id: id,
            name: name,
            type: type,
            tickerSymbol: tickerSymbol,
            currencySymbol: currencySymbol,
            value: value,
            shares: shares,
            netCostBasis: netCostBasis,
            brokerCostBasis: brokerCostBasis,
            buyFeeTotal: buyFeeTotal,
            isArchived: isArchived,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            required AssetTypes type,
            required String tickerSymbol,
            Value<String?> currencySymbol = const Value.absent(),
            Value<double> value = const Value.absent(),
            Value<double> shares = const Value.absent(),
            Value<double> netCostBasis = const Value.absent(),
            Value<double> brokerCostBasis = const Value.absent(),
            Value<double> buyFeeTotal = const Value.absent(),
            Value<bool> isArchived = const Value.absent(),
          }) =>
              AssetsCompanion.insert(
            id: id,
            name: name,
            type: type,
            tickerSymbol: tickerSymbol,
            currencySymbol: currencySymbol,
            value: value,
            shares: shares,
            netCostBasis: netCostBasis,
            brokerCostBasis: brokerCostBasis,
            buyFeeTotal: buyFeeTotal,
            isArchived: isArchived,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$AssetsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: (
              {bookingsRefs = false,
              transfersRefs = false,
              tradesRefs = false,
              periodicBookingsRefs = false,
              periodicTransfersRefs = false,
              assetsOnAccountsRefs = false,
              goalsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (bookingsRefs) db.bookings,
                if (transfersRefs) db.transfers,
                if (tradesRefs) db.trades,
                if (periodicBookingsRefs) db.periodicBookings,
                if (periodicTransfersRefs) db.periodicTransfers,
                if (assetsOnAccountsRefs) db.assetsOnAccounts,
                if (goalsRefs) db.goals
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (bookingsRefs)
                    await $_getPrefetchedData<Asset, $AssetsTable, Booking>(
                        currentTable: table,
                        referencedTable:
                            $$AssetsTableReferences._bookingsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$AssetsTableReferences(db, table, p0).bookingsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.assetId == item.id),
                        typedResults: items),
                  if (transfersRefs)
                    await $_getPrefetchedData<Asset, $AssetsTable, Transfer>(
                        currentTable: table,
                        referencedTable:
                            $$AssetsTableReferences._transfersRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$AssetsTableReferences(db, table, p0)
                                .transfersRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.assetId == item.id),
                        typedResults: items),
                  if (tradesRefs)
                    await $_getPrefetchedData<Asset, $AssetsTable, Trade>(
                        currentTable: table,
                        referencedTable:
                            $$AssetsTableReferences._tradesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$AssetsTableReferences(db, table, p0).tradesRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.assetId == item.id),
                        typedResults: items),
                  if (periodicBookingsRefs)
                    await $_getPrefetchedData<Asset, $AssetsTable,
                            PeriodicBooking>(
                        currentTable: table,
                        referencedTable: $$AssetsTableReferences
                            ._periodicBookingsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$AssetsTableReferences(db, table, p0)
                                .periodicBookingsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.assetId == item.id),
                        typedResults: items),
                  if (periodicTransfersRefs)
                    await $_getPrefetchedData<Asset, $AssetsTable,
                            PeriodicTransfer>(
                        currentTable: table,
                        referencedTable: $$AssetsTableReferences
                            ._periodicTransfersRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$AssetsTableReferences(db, table, p0)
                                .periodicTransfersRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.assetId == item.id),
                        typedResults: items),
                  if (assetsOnAccountsRefs)
                    await $_getPrefetchedData<Asset, $AssetsTable,
                            AssetOnAccount>(
                        currentTable: table,
                        referencedTable: $$AssetsTableReferences
                            ._assetsOnAccountsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$AssetsTableReferences(db, table, p0)
                                .assetsOnAccountsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.assetId == item.id),
                        typedResults: items),
                  if (goalsRefs)
                    await $_getPrefetchedData<Asset, $AssetsTable, Goal>(
                        currentTable: table,
                        referencedTable:
                            $$AssetsTableReferences._goalsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$AssetsTableReferences(db, table, p0).goalsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.assetId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$AssetsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $AssetsTable,
    Asset,
    $$AssetsTableFilterComposer,
    $$AssetsTableOrderingComposer,
    $$AssetsTableAnnotationComposer,
    $$AssetsTableCreateCompanionBuilder,
    $$AssetsTableUpdateCompanionBuilder,
    (Asset, $$AssetsTableReferences),
    Asset,
    PrefetchHooks Function(
        {bool bookingsRefs,
        bool transfersRefs,
        bool tradesRefs,
        bool periodicBookingsRefs,
        bool periodicTransfersRefs,
        bool assetsOnAccountsRefs,
        bool goalsRefs})>;
typedef $$BookingsTableCreateCompanionBuilder = BookingsCompanion Function({
  Value<int> id,
  required int date,
  Value<int> assetId,
  required int accountId,
  required String category,
  required double shares,
  Value<double> costBasis,
  required double value,
  Value<String?> notes,
  Value<bool> excludeFromAverage,
  Value<bool> isGenerated,
});
typedef $$BookingsTableUpdateCompanionBuilder = BookingsCompanion Function({
  Value<int> id,
  Value<int> date,
  Value<int> assetId,
  Value<int> accountId,
  Value<String> category,
  Value<double> shares,
  Value<double> costBasis,
  Value<double> value,
  Value<String?> notes,
  Value<bool> excludeFromAverage,
  Value<bool> isGenerated,
});

final class $$BookingsTableReferences
    extends BaseReferences<_$AppDatabase, $BookingsTable, Booking> {
  $$BookingsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $AssetsTable _assetIdTable(_$AppDatabase db) => db.assets
      .createAlias($_aliasNameGenerator(db.bookings.assetId, db.assets.id));

  $$AssetsTableProcessedTableManager get assetId {
    final $_column = $_itemColumn<int>('asset_id')!;

    final manager = $$AssetsTableTableManager($_db, $_db.assets)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_assetIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $AccountsTable _accountIdTable(_$AppDatabase db) => db.accounts
      .createAlias($_aliasNameGenerator(db.bookings.accountId, db.accounts.id));

  $$AccountsTableProcessedTableManager get accountId {
    final $_column = $_itemColumn<int>('account_id')!;

    final manager = $$AccountsTableTableManager($_db, $_db.accounts)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_accountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$BookingsTableFilterComposer
    extends Composer<_$AppDatabase, $BookingsTable> {
  $$BookingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get shares => $composableBuilder(
      column: $table.shares, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get costBasis => $composableBuilder(
      column: $table.costBasis, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get excludeFromAverage => $composableBuilder(
      column: $table.excludeFromAverage,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isGenerated => $composableBuilder(
      column: $table.isGenerated, builder: (column) => ColumnFilters(column));

  $$AssetsTableFilterComposer get assetId {
    final $$AssetsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.assetId,
        referencedTable: $db.assets,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AssetsTableFilterComposer(
              $db: $db,
              $table: $db.assets,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$AccountsTableFilterComposer get accountId {
    final $$AccountsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.accountId,
        referencedTable: $db.accounts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AccountsTableFilterComposer(
              $db: $db,
              $table: $db.accounts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$BookingsTableOrderingComposer
    extends Composer<_$AppDatabase, $BookingsTable> {
  $$BookingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get shares => $composableBuilder(
      column: $table.shares, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get costBasis => $composableBuilder(
      column: $table.costBasis, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get excludeFromAverage => $composableBuilder(
      column: $table.excludeFromAverage,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isGenerated => $composableBuilder(
      column: $table.isGenerated, builder: (column) => ColumnOrderings(column));

  $$AssetsTableOrderingComposer get assetId {
    final $$AssetsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.assetId,
        referencedTable: $db.assets,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AssetsTableOrderingComposer(
              $db: $db,
              $table: $db.assets,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$AccountsTableOrderingComposer get accountId {
    final $$AccountsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.accountId,
        referencedTable: $db.accounts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AccountsTableOrderingComposer(
              $db: $db,
              $table: $db.accounts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$BookingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BookingsTable> {
  $$BookingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<double> get shares =>
      $composableBuilder(column: $table.shares, builder: (column) => column);

  GeneratedColumn<double> get costBasis =>
      $composableBuilder(column: $table.costBasis, builder: (column) => column);

  GeneratedColumn<double> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<bool> get excludeFromAverage => $composableBuilder(
      column: $table.excludeFromAverage, builder: (column) => column);

  GeneratedColumn<bool> get isGenerated => $composableBuilder(
      column: $table.isGenerated, builder: (column) => column);

  $$AssetsTableAnnotationComposer get assetId {
    final $$AssetsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.assetId,
        referencedTable: $db.assets,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AssetsTableAnnotationComposer(
              $db: $db,
              $table: $db.assets,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$AccountsTableAnnotationComposer get accountId {
    final $$AccountsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.accountId,
        referencedTable: $db.accounts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AccountsTableAnnotationComposer(
              $db: $db,
              $table: $db.accounts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$BookingsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $BookingsTable,
    Booking,
    $$BookingsTableFilterComposer,
    $$BookingsTableOrderingComposer,
    $$BookingsTableAnnotationComposer,
    $$BookingsTableCreateCompanionBuilder,
    $$BookingsTableUpdateCompanionBuilder,
    (Booking, $$BookingsTableReferences),
    Booking,
    PrefetchHooks Function({bool assetId, bool accountId})> {
  $$BookingsTableTableManager(_$AppDatabase db, $BookingsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BookingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BookingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BookingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> date = const Value.absent(),
            Value<int> assetId = const Value.absent(),
            Value<int> accountId = const Value.absent(),
            Value<String> category = const Value.absent(),
            Value<double> shares = const Value.absent(),
            Value<double> costBasis = const Value.absent(),
            Value<double> value = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<bool> excludeFromAverage = const Value.absent(),
            Value<bool> isGenerated = const Value.absent(),
          }) =>
              BookingsCompanion(
            id: id,
            date: date,
            assetId: assetId,
            accountId: accountId,
            category: category,
            shares: shares,
            costBasis: costBasis,
            value: value,
            notes: notes,
            excludeFromAverage: excludeFromAverage,
            isGenerated: isGenerated,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int date,
            Value<int> assetId = const Value.absent(),
            required int accountId,
            required String category,
            required double shares,
            Value<double> costBasis = const Value.absent(),
            required double value,
            Value<String?> notes = const Value.absent(),
            Value<bool> excludeFromAverage = const Value.absent(),
            Value<bool> isGenerated = const Value.absent(),
          }) =>
              BookingsCompanion.insert(
            id: id,
            date: date,
            assetId: assetId,
            accountId: accountId,
            category: category,
            shares: shares,
            costBasis: costBasis,
            value: value,
            notes: notes,
            excludeFromAverage: excludeFromAverage,
            isGenerated: isGenerated,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$BookingsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({assetId = false, accountId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (assetId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.assetId,
                    referencedTable:
                        $$BookingsTableReferences._assetIdTable(db),
                    referencedColumn:
                        $$BookingsTableReferences._assetIdTable(db).id,
                  ) as T;
                }
                if (accountId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.accountId,
                    referencedTable:
                        $$BookingsTableReferences._accountIdTable(db),
                    referencedColumn:
                        $$BookingsTableReferences._accountIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$BookingsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $BookingsTable,
    Booking,
    $$BookingsTableFilterComposer,
    $$BookingsTableOrderingComposer,
    $$BookingsTableAnnotationComposer,
    $$BookingsTableCreateCompanionBuilder,
    $$BookingsTableUpdateCompanionBuilder,
    (Booking, $$BookingsTableReferences),
    Booking,
    PrefetchHooks Function({bool assetId, bool accountId})>;
typedef $$TransfersTableCreateCompanionBuilder = TransfersCompanion Function({
  Value<int> id,
  required int date,
  required int sendingAccountId,
  required int receivingAccountId,
  Value<int> assetId,
  required double shares,
  Value<double> costBasis,
  required double value,
  Value<String?> notes,
  Value<bool> isGenerated,
});
typedef $$TransfersTableUpdateCompanionBuilder = TransfersCompanion Function({
  Value<int> id,
  Value<int> date,
  Value<int> sendingAccountId,
  Value<int> receivingAccountId,
  Value<int> assetId,
  Value<double> shares,
  Value<double> costBasis,
  Value<double> value,
  Value<String?> notes,
  Value<bool> isGenerated,
});

final class $$TransfersTableReferences
    extends BaseReferences<_$AppDatabase, $TransfersTable, Transfer> {
  $$TransfersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $AccountsTable _sendingAccountIdTable(_$AppDatabase db) =>
      db.accounts.createAlias(
          $_aliasNameGenerator(db.transfers.sendingAccountId, db.accounts.id));

  $$AccountsTableProcessedTableManager get sendingAccountId {
    final $_column = $_itemColumn<int>('sending_account_id')!;

    final manager = $$AccountsTableTableManager($_db, $_db.accounts)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sendingAccountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $AccountsTable _receivingAccountIdTable(_$AppDatabase db) =>
      db.accounts.createAlias($_aliasNameGenerator(
          db.transfers.receivingAccountId, db.accounts.id));

  $$AccountsTableProcessedTableManager get receivingAccountId {
    final $_column = $_itemColumn<int>('receiving_account_id')!;

    final manager = $$AccountsTableTableManager($_db, $_db.accounts)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_receivingAccountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $AssetsTable _assetIdTable(_$AppDatabase db) => db.assets
      .createAlias($_aliasNameGenerator(db.transfers.assetId, db.assets.id));

  $$AssetsTableProcessedTableManager get assetId {
    final $_column = $_itemColumn<int>('asset_id')!;

    final manager = $$AssetsTableTableManager($_db, $_db.assets)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_assetIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$TransfersTableFilterComposer
    extends Composer<_$AppDatabase, $TransfersTable> {
  $$TransfersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get shares => $composableBuilder(
      column: $table.shares, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get costBasis => $composableBuilder(
      column: $table.costBasis, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isGenerated => $composableBuilder(
      column: $table.isGenerated, builder: (column) => ColumnFilters(column));

  $$AccountsTableFilterComposer get sendingAccountId {
    final $$AccountsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.sendingAccountId,
        referencedTable: $db.accounts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AccountsTableFilterComposer(
              $db: $db,
              $table: $db.accounts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$AccountsTableFilterComposer get receivingAccountId {
    final $$AccountsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.receivingAccountId,
        referencedTable: $db.accounts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AccountsTableFilterComposer(
              $db: $db,
              $table: $db.accounts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$AssetsTableFilterComposer get assetId {
    final $$AssetsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.assetId,
        referencedTable: $db.assets,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AssetsTableFilterComposer(
              $db: $db,
              $table: $db.assets,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$TransfersTableOrderingComposer
    extends Composer<_$AppDatabase, $TransfersTable> {
  $$TransfersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get shares => $composableBuilder(
      column: $table.shares, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get costBasis => $composableBuilder(
      column: $table.costBasis, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isGenerated => $composableBuilder(
      column: $table.isGenerated, builder: (column) => ColumnOrderings(column));

  $$AccountsTableOrderingComposer get sendingAccountId {
    final $$AccountsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.sendingAccountId,
        referencedTable: $db.accounts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AccountsTableOrderingComposer(
              $db: $db,
              $table: $db.accounts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$AccountsTableOrderingComposer get receivingAccountId {
    final $$AccountsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.receivingAccountId,
        referencedTable: $db.accounts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AccountsTableOrderingComposer(
              $db: $db,
              $table: $db.accounts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$AssetsTableOrderingComposer get assetId {
    final $$AssetsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.assetId,
        referencedTable: $db.assets,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AssetsTableOrderingComposer(
              $db: $db,
              $table: $db.assets,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$TransfersTableAnnotationComposer
    extends Composer<_$AppDatabase, $TransfersTable> {
  $$TransfersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<double> get shares =>
      $composableBuilder(column: $table.shares, builder: (column) => column);

  GeneratedColumn<double> get costBasis =>
      $composableBuilder(column: $table.costBasis, builder: (column) => column);

  GeneratedColumn<double> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<bool> get isGenerated => $composableBuilder(
      column: $table.isGenerated, builder: (column) => column);

  $$AccountsTableAnnotationComposer get sendingAccountId {
    final $$AccountsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.sendingAccountId,
        referencedTable: $db.accounts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AccountsTableAnnotationComposer(
              $db: $db,
              $table: $db.accounts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$AccountsTableAnnotationComposer get receivingAccountId {
    final $$AccountsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.receivingAccountId,
        referencedTable: $db.accounts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AccountsTableAnnotationComposer(
              $db: $db,
              $table: $db.accounts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$AssetsTableAnnotationComposer get assetId {
    final $$AssetsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.assetId,
        referencedTable: $db.assets,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AssetsTableAnnotationComposer(
              $db: $db,
              $table: $db.assets,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$TransfersTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TransfersTable,
    Transfer,
    $$TransfersTableFilterComposer,
    $$TransfersTableOrderingComposer,
    $$TransfersTableAnnotationComposer,
    $$TransfersTableCreateCompanionBuilder,
    $$TransfersTableUpdateCompanionBuilder,
    (Transfer, $$TransfersTableReferences),
    Transfer,
    PrefetchHooks Function(
        {bool sendingAccountId, bool receivingAccountId, bool assetId})> {
  $$TransfersTableTableManager(_$AppDatabase db, $TransfersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TransfersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TransfersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TransfersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> date = const Value.absent(),
            Value<int> sendingAccountId = const Value.absent(),
            Value<int> receivingAccountId = const Value.absent(),
            Value<int> assetId = const Value.absent(),
            Value<double> shares = const Value.absent(),
            Value<double> costBasis = const Value.absent(),
            Value<double> value = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<bool> isGenerated = const Value.absent(),
          }) =>
              TransfersCompanion(
            id: id,
            date: date,
            sendingAccountId: sendingAccountId,
            receivingAccountId: receivingAccountId,
            assetId: assetId,
            shares: shares,
            costBasis: costBasis,
            value: value,
            notes: notes,
            isGenerated: isGenerated,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int date,
            required int sendingAccountId,
            required int receivingAccountId,
            Value<int> assetId = const Value.absent(),
            required double shares,
            Value<double> costBasis = const Value.absent(),
            required double value,
            Value<String?> notes = const Value.absent(),
            Value<bool> isGenerated = const Value.absent(),
          }) =>
              TransfersCompanion.insert(
            id: id,
            date: date,
            sendingAccountId: sendingAccountId,
            receivingAccountId: receivingAccountId,
            assetId: assetId,
            shares: shares,
            costBasis: costBasis,
            value: value,
            notes: notes,
            isGenerated: isGenerated,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$TransfersTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {sendingAccountId = false,
              receivingAccountId = false,
              assetId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (sendingAccountId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.sendingAccountId,
                    referencedTable:
                        $$TransfersTableReferences._sendingAccountIdTable(db),
                    referencedColumn: $$TransfersTableReferences
                        ._sendingAccountIdTable(db)
                        .id,
                  ) as T;
                }
                if (receivingAccountId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.receivingAccountId,
                    referencedTable:
                        $$TransfersTableReferences._receivingAccountIdTable(db),
                    referencedColumn: $$TransfersTableReferences
                        ._receivingAccountIdTable(db)
                        .id,
                  ) as T;
                }
                if (assetId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.assetId,
                    referencedTable:
                        $$TransfersTableReferences._assetIdTable(db),
                    referencedColumn:
                        $$TransfersTableReferences._assetIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$TransfersTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $TransfersTable,
    Transfer,
    $$TransfersTableFilterComposer,
    $$TransfersTableOrderingComposer,
    $$TransfersTableAnnotationComposer,
    $$TransfersTableCreateCompanionBuilder,
    $$TransfersTableUpdateCompanionBuilder,
    (Transfer, $$TransfersTableReferences),
    Transfer,
    PrefetchHooks Function(
        {bool sendingAccountId, bool receivingAccountId, bool assetId})>;
typedef $$TradesTableCreateCompanionBuilder = TradesCompanion Function({
  Value<int> id,
  required int datetime,
  required TradeTypes type,
  required int sourceAccountId,
  required int targetAccountId,
  required int assetId,
  required double shares,
  required double costBasis,
  Value<double> fee,
  Value<double> tax,
  required double sourceAccountValueDelta,
  required double targetAccountValueDelta,
  Value<double> profitAndLoss,
  Value<double> returnOnInvest,
});
typedef $$TradesTableUpdateCompanionBuilder = TradesCompanion Function({
  Value<int> id,
  Value<int> datetime,
  Value<TradeTypes> type,
  Value<int> sourceAccountId,
  Value<int> targetAccountId,
  Value<int> assetId,
  Value<double> shares,
  Value<double> costBasis,
  Value<double> fee,
  Value<double> tax,
  Value<double> sourceAccountValueDelta,
  Value<double> targetAccountValueDelta,
  Value<double> profitAndLoss,
  Value<double> returnOnInvest,
});

final class $$TradesTableReferences
    extends BaseReferences<_$AppDatabase, $TradesTable, Trade> {
  $$TradesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $AccountsTable _sourceAccountIdTable(_$AppDatabase db) =>
      db.accounts.createAlias(
          $_aliasNameGenerator(db.trades.sourceAccountId, db.accounts.id));

  $$AccountsTableProcessedTableManager get sourceAccountId {
    final $_column = $_itemColumn<int>('source_account_id')!;

    final manager = $$AccountsTableTableManager($_db, $_db.accounts)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sourceAccountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $AccountsTable _targetAccountIdTable(_$AppDatabase db) =>
      db.accounts.createAlias(
          $_aliasNameGenerator(db.trades.targetAccountId, db.accounts.id));

  $$AccountsTableProcessedTableManager get targetAccountId {
    final $_column = $_itemColumn<int>('target_account_id')!;

    final manager = $$AccountsTableTableManager($_db, $_db.accounts)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_targetAccountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $AssetsTable _assetIdTable(_$AppDatabase db) => db.assets
      .createAlias($_aliasNameGenerator(db.trades.assetId, db.assets.id));

  $$AssetsTableProcessedTableManager get assetId {
    final $_column = $_itemColumn<int>('asset_id')!;

    final manager = $$AssetsTableTableManager($_db, $_db.assets)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_assetIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$TradesTableFilterComposer
    extends Composer<_$AppDatabase, $TradesTable> {
  $$TradesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get datetime => $composableBuilder(
      column: $table.datetime, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<TradeTypes, TradeTypes, String> get type =>
      $composableBuilder(
          column: $table.type,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<double> get shares => $composableBuilder(
      column: $table.shares, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get costBasis => $composableBuilder(
      column: $table.costBasis, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get fee => $composableBuilder(
      column: $table.fee, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get tax => $composableBuilder(
      column: $table.tax, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get sourceAccountValueDelta => $composableBuilder(
      column: $table.sourceAccountValueDelta,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get targetAccountValueDelta => $composableBuilder(
      column: $table.targetAccountValueDelta,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get profitAndLoss => $composableBuilder(
      column: $table.profitAndLoss, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get returnOnInvest => $composableBuilder(
      column: $table.returnOnInvest,
      builder: (column) => ColumnFilters(column));

  $$AccountsTableFilterComposer get sourceAccountId {
    final $$AccountsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.sourceAccountId,
        referencedTable: $db.accounts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AccountsTableFilterComposer(
              $db: $db,
              $table: $db.accounts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$AccountsTableFilterComposer get targetAccountId {
    final $$AccountsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.targetAccountId,
        referencedTable: $db.accounts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AccountsTableFilterComposer(
              $db: $db,
              $table: $db.accounts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$AssetsTableFilterComposer get assetId {
    final $$AssetsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.assetId,
        referencedTable: $db.assets,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AssetsTableFilterComposer(
              $db: $db,
              $table: $db.assets,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$TradesTableOrderingComposer
    extends Composer<_$AppDatabase, $TradesTable> {
  $$TradesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get datetime => $composableBuilder(
      column: $table.datetime, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get shares => $composableBuilder(
      column: $table.shares, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get costBasis => $composableBuilder(
      column: $table.costBasis, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get fee => $composableBuilder(
      column: $table.fee, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get tax => $composableBuilder(
      column: $table.tax, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get sourceAccountValueDelta => $composableBuilder(
      column: $table.sourceAccountValueDelta,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get targetAccountValueDelta => $composableBuilder(
      column: $table.targetAccountValueDelta,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get profitAndLoss => $composableBuilder(
      column: $table.profitAndLoss,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get returnOnInvest => $composableBuilder(
      column: $table.returnOnInvest,
      builder: (column) => ColumnOrderings(column));

  $$AccountsTableOrderingComposer get sourceAccountId {
    final $$AccountsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.sourceAccountId,
        referencedTable: $db.accounts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AccountsTableOrderingComposer(
              $db: $db,
              $table: $db.accounts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$AccountsTableOrderingComposer get targetAccountId {
    final $$AccountsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.targetAccountId,
        referencedTable: $db.accounts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AccountsTableOrderingComposer(
              $db: $db,
              $table: $db.accounts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$AssetsTableOrderingComposer get assetId {
    final $$AssetsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.assetId,
        referencedTable: $db.assets,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AssetsTableOrderingComposer(
              $db: $db,
              $table: $db.assets,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$TradesTableAnnotationComposer
    extends Composer<_$AppDatabase, $TradesTable> {
  $$TradesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get datetime =>
      $composableBuilder(column: $table.datetime, builder: (column) => column);

  GeneratedColumnWithTypeConverter<TradeTypes, String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<double> get shares =>
      $composableBuilder(column: $table.shares, builder: (column) => column);

  GeneratedColumn<double> get costBasis =>
      $composableBuilder(column: $table.costBasis, builder: (column) => column);

  GeneratedColumn<double> get fee =>
      $composableBuilder(column: $table.fee, builder: (column) => column);

  GeneratedColumn<double> get tax =>
      $composableBuilder(column: $table.tax, builder: (column) => column);

  GeneratedColumn<double> get sourceAccountValueDelta => $composableBuilder(
      column: $table.sourceAccountValueDelta, builder: (column) => column);

  GeneratedColumn<double> get targetAccountValueDelta => $composableBuilder(
      column: $table.targetAccountValueDelta, builder: (column) => column);

  GeneratedColumn<double> get profitAndLoss => $composableBuilder(
      column: $table.profitAndLoss, builder: (column) => column);

  GeneratedColumn<double> get returnOnInvest => $composableBuilder(
      column: $table.returnOnInvest, builder: (column) => column);

  $$AccountsTableAnnotationComposer get sourceAccountId {
    final $$AccountsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.sourceAccountId,
        referencedTable: $db.accounts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AccountsTableAnnotationComposer(
              $db: $db,
              $table: $db.accounts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$AccountsTableAnnotationComposer get targetAccountId {
    final $$AccountsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.targetAccountId,
        referencedTable: $db.accounts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AccountsTableAnnotationComposer(
              $db: $db,
              $table: $db.accounts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$AssetsTableAnnotationComposer get assetId {
    final $$AssetsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.assetId,
        referencedTable: $db.assets,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AssetsTableAnnotationComposer(
              $db: $db,
              $table: $db.assets,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$TradesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TradesTable,
    Trade,
    $$TradesTableFilterComposer,
    $$TradesTableOrderingComposer,
    $$TradesTableAnnotationComposer,
    $$TradesTableCreateCompanionBuilder,
    $$TradesTableUpdateCompanionBuilder,
    (Trade, $$TradesTableReferences),
    Trade,
    PrefetchHooks Function(
        {bool sourceAccountId, bool targetAccountId, bool assetId})> {
  $$TradesTableTableManager(_$AppDatabase db, $TradesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TradesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TradesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TradesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> datetime = const Value.absent(),
            Value<TradeTypes> type = const Value.absent(),
            Value<int> sourceAccountId = const Value.absent(),
            Value<int> targetAccountId = const Value.absent(),
            Value<int> assetId = const Value.absent(),
            Value<double> shares = const Value.absent(),
            Value<double> costBasis = const Value.absent(),
            Value<double> fee = const Value.absent(),
            Value<double> tax = const Value.absent(),
            Value<double> sourceAccountValueDelta = const Value.absent(),
            Value<double> targetAccountValueDelta = const Value.absent(),
            Value<double> profitAndLoss = const Value.absent(),
            Value<double> returnOnInvest = const Value.absent(),
          }) =>
              TradesCompanion(
            id: id,
            datetime: datetime,
            type: type,
            sourceAccountId: sourceAccountId,
            targetAccountId: targetAccountId,
            assetId: assetId,
            shares: shares,
            costBasis: costBasis,
            fee: fee,
            tax: tax,
            sourceAccountValueDelta: sourceAccountValueDelta,
            targetAccountValueDelta: targetAccountValueDelta,
            profitAndLoss: profitAndLoss,
            returnOnInvest: returnOnInvest,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int datetime,
            required TradeTypes type,
            required int sourceAccountId,
            required int targetAccountId,
            required int assetId,
            required double shares,
            required double costBasis,
            Value<double> fee = const Value.absent(),
            Value<double> tax = const Value.absent(),
            required double sourceAccountValueDelta,
            required double targetAccountValueDelta,
            Value<double> profitAndLoss = const Value.absent(),
            Value<double> returnOnInvest = const Value.absent(),
          }) =>
              TradesCompanion.insert(
            id: id,
            datetime: datetime,
            type: type,
            sourceAccountId: sourceAccountId,
            targetAccountId: targetAccountId,
            assetId: assetId,
            shares: shares,
            costBasis: costBasis,
            fee: fee,
            tax: tax,
            sourceAccountValueDelta: sourceAccountValueDelta,
            targetAccountValueDelta: targetAccountValueDelta,
            profitAndLoss: profitAndLoss,
            returnOnInvest: returnOnInvest,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$TradesTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: (
              {sourceAccountId = false,
              targetAccountId = false,
              assetId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (sourceAccountId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.sourceAccountId,
                    referencedTable:
                        $$TradesTableReferences._sourceAccountIdTable(db),
                    referencedColumn:
                        $$TradesTableReferences._sourceAccountIdTable(db).id,
                  ) as T;
                }
                if (targetAccountId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.targetAccountId,
                    referencedTable:
                        $$TradesTableReferences._targetAccountIdTable(db),
                    referencedColumn:
                        $$TradesTableReferences._targetAccountIdTable(db).id,
                  ) as T;
                }
                if (assetId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.assetId,
                    referencedTable: $$TradesTableReferences._assetIdTable(db),
                    referencedColumn:
                        $$TradesTableReferences._assetIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$TradesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $TradesTable,
    Trade,
    $$TradesTableFilterComposer,
    $$TradesTableOrderingComposer,
    $$TradesTableAnnotationComposer,
    $$TradesTableCreateCompanionBuilder,
    $$TradesTableUpdateCompanionBuilder,
    (Trade, $$TradesTableReferences),
    Trade,
    PrefetchHooks Function(
        {bool sourceAccountId, bool targetAccountId, bool assetId})>;
typedef $$PeriodicBookingsTableCreateCompanionBuilder
    = PeriodicBookingsCompanion Function({
  Value<int> id,
  required int nextExecutionDate,
  Value<int> assetId,
  required int accountId,
  required double shares,
  Value<double> costBasis,
  required double value,
  required String category,
  Value<String?> notes,
  Value<Cycles> cycle,
  Value<double> monthlyAverageFactor,
});
typedef $$PeriodicBookingsTableUpdateCompanionBuilder
    = PeriodicBookingsCompanion Function({
  Value<int> id,
  Value<int> nextExecutionDate,
  Value<int> assetId,
  Value<int> accountId,
  Value<double> shares,
  Value<double> costBasis,
  Value<double> value,
  Value<String> category,
  Value<String?> notes,
  Value<Cycles> cycle,
  Value<double> monthlyAverageFactor,
});

final class $$PeriodicBookingsTableReferences extends BaseReferences<
    _$AppDatabase, $PeriodicBookingsTable, PeriodicBooking> {
  $$PeriodicBookingsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $AssetsTable _assetIdTable(_$AppDatabase db) => db.assets.createAlias(
      $_aliasNameGenerator(db.periodicBookings.assetId, db.assets.id));

  $$AssetsTableProcessedTableManager get assetId {
    final $_column = $_itemColumn<int>('asset_id')!;

    final manager = $$AssetsTableTableManager($_db, $_db.assets)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_assetIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $AccountsTable _accountIdTable(_$AppDatabase db) =>
      db.accounts.createAlias(
          $_aliasNameGenerator(db.periodicBookings.accountId, db.accounts.id));

  $$AccountsTableProcessedTableManager get accountId {
    final $_column = $_itemColumn<int>('account_id')!;

    final manager = $$AccountsTableTableManager($_db, $_db.accounts)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_accountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$PeriodicBookingsTableFilterComposer
    extends Composer<_$AppDatabase, $PeriodicBookingsTable> {
  $$PeriodicBookingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get nextExecutionDate => $composableBuilder(
      column: $table.nextExecutionDate,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get shares => $composableBuilder(
      column: $table.shares, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get costBasis => $composableBuilder(
      column: $table.costBasis, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<Cycles, Cycles, String> get cycle =>
      $composableBuilder(
          column: $table.cycle,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<double> get monthlyAverageFactor => $composableBuilder(
      column: $table.monthlyAverageFactor,
      builder: (column) => ColumnFilters(column));

  $$AssetsTableFilterComposer get assetId {
    final $$AssetsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.assetId,
        referencedTable: $db.assets,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AssetsTableFilterComposer(
              $db: $db,
              $table: $db.assets,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$AccountsTableFilterComposer get accountId {
    final $$AccountsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.accountId,
        referencedTable: $db.accounts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AccountsTableFilterComposer(
              $db: $db,
              $table: $db.accounts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$PeriodicBookingsTableOrderingComposer
    extends Composer<_$AppDatabase, $PeriodicBookingsTable> {
  $$PeriodicBookingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get nextExecutionDate => $composableBuilder(
      column: $table.nextExecutionDate,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get shares => $composableBuilder(
      column: $table.shares, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get costBasis => $composableBuilder(
      column: $table.costBasis, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get cycle => $composableBuilder(
      column: $table.cycle, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get monthlyAverageFactor => $composableBuilder(
      column: $table.monthlyAverageFactor,
      builder: (column) => ColumnOrderings(column));

  $$AssetsTableOrderingComposer get assetId {
    final $$AssetsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.assetId,
        referencedTable: $db.assets,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AssetsTableOrderingComposer(
              $db: $db,
              $table: $db.assets,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$AccountsTableOrderingComposer get accountId {
    final $$AccountsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.accountId,
        referencedTable: $db.accounts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AccountsTableOrderingComposer(
              $db: $db,
              $table: $db.accounts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$PeriodicBookingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PeriodicBookingsTable> {
  $$PeriodicBookingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get nextExecutionDate => $composableBuilder(
      column: $table.nextExecutionDate, builder: (column) => column);

  GeneratedColumn<double> get shares =>
      $composableBuilder(column: $table.shares, builder: (column) => column);

  GeneratedColumn<double> get costBasis =>
      $composableBuilder(column: $table.costBasis, builder: (column) => column);

  GeneratedColumn<double> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Cycles, String> get cycle =>
      $composableBuilder(column: $table.cycle, builder: (column) => column);

  GeneratedColumn<double> get monthlyAverageFactor => $composableBuilder(
      column: $table.monthlyAverageFactor, builder: (column) => column);

  $$AssetsTableAnnotationComposer get assetId {
    final $$AssetsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.assetId,
        referencedTable: $db.assets,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AssetsTableAnnotationComposer(
              $db: $db,
              $table: $db.assets,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$AccountsTableAnnotationComposer get accountId {
    final $$AccountsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.accountId,
        referencedTable: $db.accounts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AccountsTableAnnotationComposer(
              $db: $db,
              $table: $db.accounts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$PeriodicBookingsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PeriodicBookingsTable,
    PeriodicBooking,
    $$PeriodicBookingsTableFilterComposer,
    $$PeriodicBookingsTableOrderingComposer,
    $$PeriodicBookingsTableAnnotationComposer,
    $$PeriodicBookingsTableCreateCompanionBuilder,
    $$PeriodicBookingsTableUpdateCompanionBuilder,
    (PeriodicBooking, $$PeriodicBookingsTableReferences),
    PeriodicBooking,
    PrefetchHooks Function({bool assetId, bool accountId})> {
  $$PeriodicBookingsTableTableManager(
      _$AppDatabase db, $PeriodicBookingsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PeriodicBookingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PeriodicBookingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PeriodicBookingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> nextExecutionDate = const Value.absent(),
            Value<int> assetId = const Value.absent(),
            Value<int> accountId = const Value.absent(),
            Value<double> shares = const Value.absent(),
            Value<double> costBasis = const Value.absent(),
            Value<double> value = const Value.absent(),
            Value<String> category = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<Cycles> cycle = const Value.absent(),
            Value<double> monthlyAverageFactor = const Value.absent(),
          }) =>
              PeriodicBookingsCompanion(
            id: id,
            nextExecutionDate: nextExecutionDate,
            assetId: assetId,
            accountId: accountId,
            shares: shares,
            costBasis: costBasis,
            value: value,
            category: category,
            notes: notes,
            cycle: cycle,
            monthlyAverageFactor: monthlyAverageFactor,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int nextExecutionDate,
            Value<int> assetId = const Value.absent(),
            required int accountId,
            required double shares,
            Value<double> costBasis = const Value.absent(),
            required double value,
            required String category,
            Value<String?> notes = const Value.absent(),
            Value<Cycles> cycle = const Value.absent(),
            Value<double> monthlyAverageFactor = const Value.absent(),
          }) =>
              PeriodicBookingsCompanion.insert(
            id: id,
            nextExecutionDate: nextExecutionDate,
            assetId: assetId,
            accountId: accountId,
            shares: shares,
            costBasis: costBasis,
            value: value,
            category: category,
            notes: notes,
            cycle: cycle,
            monthlyAverageFactor: monthlyAverageFactor,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$PeriodicBookingsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({assetId = false, accountId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (assetId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.assetId,
                    referencedTable:
                        $$PeriodicBookingsTableReferences._assetIdTable(db),
                    referencedColumn:
                        $$PeriodicBookingsTableReferences._assetIdTable(db).id,
                  ) as T;
                }
                if (accountId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.accountId,
                    referencedTable:
                        $$PeriodicBookingsTableReferences._accountIdTable(db),
                    referencedColumn: $$PeriodicBookingsTableReferences
                        ._accountIdTable(db)
                        .id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$PeriodicBookingsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PeriodicBookingsTable,
    PeriodicBooking,
    $$PeriodicBookingsTableFilterComposer,
    $$PeriodicBookingsTableOrderingComposer,
    $$PeriodicBookingsTableAnnotationComposer,
    $$PeriodicBookingsTableCreateCompanionBuilder,
    $$PeriodicBookingsTableUpdateCompanionBuilder,
    (PeriodicBooking, $$PeriodicBookingsTableReferences),
    PeriodicBooking,
    PrefetchHooks Function({bool assetId, bool accountId})>;
typedef $$PeriodicTransfersTableCreateCompanionBuilder
    = PeriodicTransfersCompanion Function({
  Value<int> id,
  required int nextExecutionDate,
  Value<int> assetId,
  required int sendingAccountId,
  required int receivingAccountId,
  required double shares,
  Value<double> costBasis,
  required double value,
  Value<String?> notes,
  Value<Cycles> cycle,
  Value<double> monthlyAverageFactor,
});
typedef $$PeriodicTransfersTableUpdateCompanionBuilder
    = PeriodicTransfersCompanion Function({
  Value<int> id,
  Value<int> nextExecutionDate,
  Value<int> assetId,
  Value<int> sendingAccountId,
  Value<int> receivingAccountId,
  Value<double> shares,
  Value<double> costBasis,
  Value<double> value,
  Value<String?> notes,
  Value<Cycles> cycle,
  Value<double> monthlyAverageFactor,
});

final class $$PeriodicTransfersTableReferences extends BaseReferences<
    _$AppDatabase, $PeriodicTransfersTable, PeriodicTransfer> {
  $$PeriodicTransfersTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $AssetsTable _assetIdTable(_$AppDatabase db) => db.assets.createAlias(
      $_aliasNameGenerator(db.periodicTransfers.assetId, db.assets.id));

  $$AssetsTableProcessedTableManager get assetId {
    final $_column = $_itemColumn<int>('asset_id')!;

    final manager = $$AssetsTableTableManager($_db, $_db.assets)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_assetIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $AccountsTable _sendingAccountIdTable(_$AppDatabase db) =>
      db.accounts.createAlias($_aliasNameGenerator(
          db.periodicTransfers.sendingAccountId, db.accounts.id));

  $$AccountsTableProcessedTableManager get sendingAccountId {
    final $_column = $_itemColumn<int>('sending_account_id')!;

    final manager = $$AccountsTableTableManager($_db, $_db.accounts)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sendingAccountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $AccountsTable _receivingAccountIdTable(_$AppDatabase db) =>
      db.accounts.createAlias($_aliasNameGenerator(
          db.periodicTransfers.receivingAccountId, db.accounts.id));

  $$AccountsTableProcessedTableManager get receivingAccountId {
    final $_column = $_itemColumn<int>('receiving_account_id')!;

    final manager = $$AccountsTableTableManager($_db, $_db.accounts)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_receivingAccountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$PeriodicTransfersTableFilterComposer
    extends Composer<_$AppDatabase, $PeriodicTransfersTable> {
  $$PeriodicTransfersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get nextExecutionDate => $composableBuilder(
      column: $table.nextExecutionDate,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get shares => $composableBuilder(
      column: $table.shares, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get costBasis => $composableBuilder(
      column: $table.costBasis, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<Cycles, Cycles, String> get cycle =>
      $composableBuilder(
          column: $table.cycle,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<double> get monthlyAverageFactor => $composableBuilder(
      column: $table.monthlyAverageFactor,
      builder: (column) => ColumnFilters(column));

  $$AssetsTableFilterComposer get assetId {
    final $$AssetsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.assetId,
        referencedTable: $db.assets,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AssetsTableFilterComposer(
              $db: $db,
              $table: $db.assets,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$AccountsTableFilterComposer get sendingAccountId {
    final $$AccountsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.sendingAccountId,
        referencedTable: $db.accounts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AccountsTableFilterComposer(
              $db: $db,
              $table: $db.accounts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$AccountsTableFilterComposer get receivingAccountId {
    final $$AccountsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.receivingAccountId,
        referencedTable: $db.accounts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AccountsTableFilterComposer(
              $db: $db,
              $table: $db.accounts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$PeriodicTransfersTableOrderingComposer
    extends Composer<_$AppDatabase, $PeriodicTransfersTable> {
  $$PeriodicTransfersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get nextExecutionDate => $composableBuilder(
      column: $table.nextExecutionDate,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get shares => $composableBuilder(
      column: $table.shares, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get costBasis => $composableBuilder(
      column: $table.costBasis, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get cycle => $composableBuilder(
      column: $table.cycle, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get monthlyAverageFactor => $composableBuilder(
      column: $table.monthlyAverageFactor,
      builder: (column) => ColumnOrderings(column));

  $$AssetsTableOrderingComposer get assetId {
    final $$AssetsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.assetId,
        referencedTable: $db.assets,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AssetsTableOrderingComposer(
              $db: $db,
              $table: $db.assets,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$AccountsTableOrderingComposer get sendingAccountId {
    final $$AccountsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.sendingAccountId,
        referencedTable: $db.accounts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AccountsTableOrderingComposer(
              $db: $db,
              $table: $db.accounts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$AccountsTableOrderingComposer get receivingAccountId {
    final $$AccountsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.receivingAccountId,
        referencedTable: $db.accounts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AccountsTableOrderingComposer(
              $db: $db,
              $table: $db.accounts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$PeriodicTransfersTableAnnotationComposer
    extends Composer<_$AppDatabase, $PeriodicTransfersTable> {
  $$PeriodicTransfersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get nextExecutionDate => $composableBuilder(
      column: $table.nextExecutionDate, builder: (column) => column);

  GeneratedColumn<double> get shares =>
      $composableBuilder(column: $table.shares, builder: (column) => column);

  GeneratedColumn<double> get costBasis =>
      $composableBuilder(column: $table.costBasis, builder: (column) => column);

  GeneratedColumn<double> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Cycles, String> get cycle =>
      $composableBuilder(column: $table.cycle, builder: (column) => column);

  GeneratedColumn<double> get monthlyAverageFactor => $composableBuilder(
      column: $table.monthlyAverageFactor, builder: (column) => column);

  $$AssetsTableAnnotationComposer get assetId {
    final $$AssetsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.assetId,
        referencedTable: $db.assets,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AssetsTableAnnotationComposer(
              $db: $db,
              $table: $db.assets,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$AccountsTableAnnotationComposer get sendingAccountId {
    final $$AccountsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.sendingAccountId,
        referencedTable: $db.accounts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AccountsTableAnnotationComposer(
              $db: $db,
              $table: $db.accounts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$AccountsTableAnnotationComposer get receivingAccountId {
    final $$AccountsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.receivingAccountId,
        referencedTable: $db.accounts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AccountsTableAnnotationComposer(
              $db: $db,
              $table: $db.accounts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$PeriodicTransfersTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PeriodicTransfersTable,
    PeriodicTransfer,
    $$PeriodicTransfersTableFilterComposer,
    $$PeriodicTransfersTableOrderingComposer,
    $$PeriodicTransfersTableAnnotationComposer,
    $$PeriodicTransfersTableCreateCompanionBuilder,
    $$PeriodicTransfersTableUpdateCompanionBuilder,
    (PeriodicTransfer, $$PeriodicTransfersTableReferences),
    PeriodicTransfer,
    PrefetchHooks Function(
        {bool assetId, bool sendingAccountId, bool receivingAccountId})> {
  $$PeriodicTransfersTableTableManager(
      _$AppDatabase db, $PeriodicTransfersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PeriodicTransfersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PeriodicTransfersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PeriodicTransfersTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> nextExecutionDate = const Value.absent(),
            Value<int> assetId = const Value.absent(),
            Value<int> sendingAccountId = const Value.absent(),
            Value<int> receivingAccountId = const Value.absent(),
            Value<double> shares = const Value.absent(),
            Value<double> costBasis = const Value.absent(),
            Value<double> value = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<Cycles> cycle = const Value.absent(),
            Value<double> monthlyAverageFactor = const Value.absent(),
          }) =>
              PeriodicTransfersCompanion(
            id: id,
            nextExecutionDate: nextExecutionDate,
            assetId: assetId,
            sendingAccountId: sendingAccountId,
            receivingAccountId: receivingAccountId,
            shares: shares,
            costBasis: costBasis,
            value: value,
            notes: notes,
            cycle: cycle,
            monthlyAverageFactor: monthlyAverageFactor,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int nextExecutionDate,
            Value<int> assetId = const Value.absent(),
            required int sendingAccountId,
            required int receivingAccountId,
            required double shares,
            Value<double> costBasis = const Value.absent(),
            required double value,
            Value<String?> notes = const Value.absent(),
            Value<Cycles> cycle = const Value.absent(),
            Value<double> monthlyAverageFactor = const Value.absent(),
          }) =>
              PeriodicTransfersCompanion.insert(
            id: id,
            nextExecutionDate: nextExecutionDate,
            assetId: assetId,
            sendingAccountId: sendingAccountId,
            receivingAccountId: receivingAccountId,
            shares: shares,
            costBasis: costBasis,
            value: value,
            notes: notes,
            cycle: cycle,
            monthlyAverageFactor: monthlyAverageFactor,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$PeriodicTransfersTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {assetId = false,
              sendingAccountId = false,
              receivingAccountId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (assetId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.assetId,
                    referencedTable:
                        $$PeriodicTransfersTableReferences._assetIdTable(db),
                    referencedColumn:
                        $$PeriodicTransfersTableReferences._assetIdTable(db).id,
                  ) as T;
                }
                if (sendingAccountId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.sendingAccountId,
                    referencedTable: $$PeriodicTransfersTableReferences
                        ._sendingAccountIdTable(db),
                    referencedColumn: $$PeriodicTransfersTableReferences
                        ._sendingAccountIdTable(db)
                        .id,
                  ) as T;
                }
                if (receivingAccountId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.receivingAccountId,
                    referencedTable: $$PeriodicTransfersTableReferences
                        ._receivingAccountIdTable(db),
                    referencedColumn: $$PeriodicTransfersTableReferences
                        ._receivingAccountIdTable(db)
                        .id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$PeriodicTransfersTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PeriodicTransfersTable,
    PeriodicTransfer,
    $$PeriodicTransfersTableFilterComposer,
    $$PeriodicTransfersTableOrderingComposer,
    $$PeriodicTransfersTableAnnotationComposer,
    $$PeriodicTransfersTableCreateCompanionBuilder,
    $$PeriodicTransfersTableUpdateCompanionBuilder,
    (PeriodicTransfer, $$PeriodicTransfersTableReferences),
    PeriodicTransfer,
    PrefetchHooks Function(
        {bool assetId, bool sendingAccountId, bool receivingAccountId})>;
typedef $$AssetsOnAccountsTableCreateCompanionBuilder
    = AssetsOnAccountsCompanion Function({
  required int accountId,
  required int assetId,
  Value<double> value,
  Value<double> shares,
  Value<double> netCostBasis,
  Value<double> brokerCostBasis,
  Value<double> buyFeeTotal,
  Value<int> rowid,
});
typedef $$AssetsOnAccountsTableUpdateCompanionBuilder
    = AssetsOnAccountsCompanion Function({
  Value<int> accountId,
  Value<int> assetId,
  Value<double> value,
  Value<double> shares,
  Value<double> netCostBasis,
  Value<double> brokerCostBasis,
  Value<double> buyFeeTotal,
  Value<int> rowid,
});

final class $$AssetsOnAccountsTableReferences extends BaseReferences<
    _$AppDatabase, $AssetsOnAccountsTable, AssetOnAccount> {
  $$AssetsOnAccountsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $AccountsTable _accountIdTable(_$AppDatabase db) =>
      db.accounts.createAlias(
          $_aliasNameGenerator(db.assetsOnAccounts.accountId, db.accounts.id));

  $$AccountsTableProcessedTableManager get accountId {
    final $_column = $_itemColumn<int>('account_id')!;

    final manager = $$AccountsTableTableManager($_db, $_db.accounts)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_accountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $AssetsTable _assetIdTable(_$AppDatabase db) => db.assets.createAlias(
      $_aliasNameGenerator(db.assetsOnAccounts.assetId, db.assets.id));

  $$AssetsTableProcessedTableManager get assetId {
    final $_column = $_itemColumn<int>('asset_id')!;

    final manager = $$AssetsTableTableManager($_db, $_db.assets)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_assetIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$AssetsOnAccountsTableFilterComposer
    extends Composer<_$AppDatabase, $AssetsOnAccountsTable> {
  $$AssetsOnAccountsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<double> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get shares => $composableBuilder(
      column: $table.shares, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get netCostBasis => $composableBuilder(
      column: $table.netCostBasis, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get brokerCostBasis => $composableBuilder(
      column: $table.brokerCostBasis,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get buyFeeTotal => $composableBuilder(
      column: $table.buyFeeTotal, builder: (column) => ColumnFilters(column));

  $$AccountsTableFilterComposer get accountId {
    final $$AccountsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.accountId,
        referencedTable: $db.accounts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AccountsTableFilterComposer(
              $db: $db,
              $table: $db.accounts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$AssetsTableFilterComposer get assetId {
    final $$AssetsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.assetId,
        referencedTable: $db.assets,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AssetsTableFilterComposer(
              $db: $db,
              $table: $db.assets,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$AssetsOnAccountsTableOrderingComposer
    extends Composer<_$AppDatabase, $AssetsOnAccountsTable> {
  $$AssetsOnAccountsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<double> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get shares => $composableBuilder(
      column: $table.shares, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get netCostBasis => $composableBuilder(
      column: $table.netCostBasis,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get brokerCostBasis => $composableBuilder(
      column: $table.brokerCostBasis,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get buyFeeTotal => $composableBuilder(
      column: $table.buyFeeTotal, builder: (column) => ColumnOrderings(column));

  $$AccountsTableOrderingComposer get accountId {
    final $$AccountsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.accountId,
        referencedTable: $db.accounts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AccountsTableOrderingComposer(
              $db: $db,
              $table: $db.accounts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$AssetsTableOrderingComposer get assetId {
    final $$AssetsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.assetId,
        referencedTable: $db.assets,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AssetsTableOrderingComposer(
              $db: $db,
              $table: $db.assets,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$AssetsOnAccountsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AssetsOnAccountsTable> {
  $$AssetsOnAccountsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<double> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<double> get shares =>
      $composableBuilder(column: $table.shares, builder: (column) => column);

  GeneratedColumn<double> get netCostBasis => $composableBuilder(
      column: $table.netCostBasis, builder: (column) => column);

  GeneratedColumn<double> get brokerCostBasis => $composableBuilder(
      column: $table.brokerCostBasis, builder: (column) => column);

  GeneratedColumn<double> get buyFeeTotal => $composableBuilder(
      column: $table.buyFeeTotal, builder: (column) => column);

  $$AccountsTableAnnotationComposer get accountId {
    final $$AccountsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.accountId,
        referencedTable: $db.accounts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AccountsTableAnnotationComposer(
              $db: $db,
              $table: $db.accounts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$AssetsTableAnnotationComposer get assetId {
    final $$AssetsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.assetId,
        referencedTable: $db.assets,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AssetsTableAnnotationComposer(
              $db: $db,
              $table: $db.assets,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$AssetsOnAccountsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AssetsOnAccountsTable,
    AssetOnAccount,
    $$AssetsOnAccountsTableFilterComposer,
    $$AssetsOnAccountsTableOrderingComposer,
    $$AssetsOnAccountsTableAnnotationComposer,
    $$AssetsOnAccountsTableCreateCompanionBuilder,
    $$AssetsOnAccountsTableUpdateCompanionBuilder,
    (AssetOnAccount, $$AssetsOnAccountsTableReferences),
    AssetOnAccount,
    PrefetchHooks Function({bool accountId, bool assetId})> {
  $$AssetsOnAccountsTableTableManager(
      _$AppDatabase db, $AssetsOnAccountsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AssetsOnAccountsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AssetsOnAccountsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AssetsOnAccountsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> accountId = const Value.absent(),
            Value<int> assetId = const Value.absent(),
            Value<double> value = const Value.absent(),
            Value<double> shares = const Value.absent(),
            Value<double> netCostBasis = const Value.absent(),
            Value<double> brokerCostBasis = const Value.absent(),
            Value<double> buyFeeTotal = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AssetsOnAccountsCompanion(
            accountId: accountId,
            assetId: assetId,
            value: value,
            shares: shares,
            netCostBasis: netCostBasis,
            brokerCostBasis: brokerCostBasis,
            buyFeeTotal: buyFeeTotal,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required int accountId,
            required int assetId,
            Value<double> value = const Value.absent(),
            Value<double> shares = const Value.absent(),
            Value<double> netCostBasis = const Value.absent(),
            Value<double> brokerCostBasis = const Value.absent(),
            Value<double> buyFeeTotal = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AssetsOnAccountsCompanion.insert(
            accountId: accountId,
            assetId: assetId,
            value: value,
            shares: shares,
            netCostBasis: netCostBasis,
            brokerCostBasis: brokerCostBasis,
            buyFeeTotal: buyFeeTotal,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$AssetsOnAccountsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({accountId = false, assetId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (accountId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.accountId,
                    referencedTable:
                        $$AssetsOnAccountsTableReferences._accountIdTable(db),
                    referencedColumn: $$AssetsOnAccountsTableReferences
                        ._accountIdTable(db)
                        .id,
                  ) as T;
                }
                if (assetId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.assetId,
                    referencedTable:
                        $$AssetsOnAccountsTableReferences._assetIdTable(db),
                    referencedColumn:
                        $$AssetsOnAccountsTableReferences._assetIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$AssetsOnAccountsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $AssetsOnAccountsTable,
    AssetOnAccount,
    $$AssetsOnAccountsTableFilterComposer,
    $$AssetsOnAccountsTableOrderingComposer,
    $$AssetsOnAccountsTableAnnotationComposer,
    $$AssetsOnAccountsTableCreateCompanionBuilder,
    $$AssetsOnAccountsTableUpdateCompanionBuilder,
    (AssetOnAccount, $$AssetsOnAccountsTableReferences),
    AssetOnAccount,
    PrefetchHooks Function({bool accountId, bool assetId})>;
typedef $$GoalsTableCreateCompanionBuilder = GoalsCompanion Function({
  Value<int> id,
  Value<int?> assetId,
  Value<int?> accountId,
  required int createdOn,
  required int targetDate,
  required double targetShares,
  required double targetValue,
});
typedef $$GoalsTableUpdateCompanionBuilder = GoalsCompanion Function({
  Value<int> id,
  Value<int?> assetId,
  Value<int?> accountId,
  Value<int> createdOn,
  Value<int> targetDate,
  Value<double> targetShares,
  Value<double> targetValue,
});

final class $$GoalsTableReferences
    extends BaseReferences<_$AppDatabase, $GoalsTable, Goal> {
  $$GoalsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $AssetsTable _assetIdTable(_$AppDatabase db) => db.assets
      .createAlias($_aliasNameGenerator(db.goals.assetId, db.assets.id));

  $$AssetsTableProcessedTableManager? get assetId {
    final $_column = $_itemColumn<int>('asset_id');
    if ($_column == null) return null;
    final manager = $$AssetsTableTableManager($_db, $_db.assets)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_assetIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $AccountsTable _accountIdTable(_$AppDatabase db) => db.accounts
      .createAlias($_aliasNameGenerator(db.goals.accountId, db.accounts.id));

  $$AccountsTableProcessedTableManager? get accountId {
    final $_column = $_itemColumn<int>('account_id');
    if ($_column == null) return null;
    final manager = $$AccountsTableTableManager($_db, $_db.accounts)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_accountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$GoalsTableFilterComposer extends Composer<_$AppDatabase, $GoalsTable> {
  $$GoalsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdOn => $composableBuilder(
      column: $table.createdOn, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get targetDate => $composableBuilder(
      column: $table.targetDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get targetShares => $composableBuilder(
      column: $table.targetShares, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get targetValue => $composableBuilder(
      column: $table.targetValue, builder: (column) => ColumnFilters(column));

  $$AssetsTableFilterComposer get assetId {
    final $$AssetsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.assetId,
        referencedTable: $db.assets,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AssetsTableFilterComposer(
              $db: $db,
              $table: $db.assets,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$AccountsTableFilterComposer get accountId {
    final $$AccountsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.accountId,
        referencedTable: $db.accounts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AccountsTableFilterComposer(
              $db: $db,
              $table: $db.accounts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$GoalsTableOrderingComposer
    extends Composer<_$AppDatabase, $GoalsTable> {
  $$GoalsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdOn => $composableBuilder(
      column: $table.createdOn, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get targetDate => $composableBuilder(
      column: $table.targetDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get targetShares => $composableBuilder(
      column: $table.targetShares,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get targetValue => $composableBuilder(
      column: $table.targetValue, builder: (column) => ColumnOrderings(column));

  $$AssetsTableOrderingComposer get assetId {
    final $$AssetsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.assetId,
        referencedTable: $db.assets,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AssetsTableOrderingComposer(
              $db: $db,
              $table: $db.assets,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$AccountsTableOrderingComposer get accountId {
    final $$AccountsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.accountId,
        referencedTable: $db.accounts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AccountsTableOrderingComposer(
              $db: $db,
              $table: $db.accounts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$GoalsTableAnnotationComposer
    extends Composer<_$AppDatabase, $GoalsTable> {
  $$GoalsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get createdOn =>
      $composableBuilder(column: $table.createdOn, builder: (column) => column);

  GeneratedColumn<int> get targetDate => $composableBuilder(
      column: $table.targetDate, builder: (column) => column);

  GeneratedColumn<double> get targetShares => $composableBuilder(
      column: $table.targetShares, builder: (column) => column);

  GeneratedColumn<double> get targetValue => $composableBuilder(
      column: $table.targetValue, builder: (column) => column);

  $$AssetsTableAnnotationComposer get assetId {
    final $$AssetsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.assetId,
        referencedTable: $db.assets,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AssetsTableAnnotationComposer(
              $db: $db,
              $table: $db.assets,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$AccountsTableAnnotationComposer get accountId {
    final $$AccountsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.accountId,
        referencedTable: $db.accounts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AccountsTableAnnotationComposer(
              $db: $db,
              $table: $db.accounts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$GoalsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $GoalsTable,
    Goal,
    $$GoalsTableFilterComposer,
    $$GoalsTableOrderingComposer,
    $$GoalsTableAnnotationComposer,
    $$GoalsTableCreateCompanionBuilder,
    $$GoalsTableUpdateCompanionBuilder,
    (Goal, $$GoalsTableReferences),
    Goal,
    PrefetchHooks Function({bool assetId, bool accountId})> {
  $$GoalsTableTableManager(_$AppDatabase db, $GoalsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GoalsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GoalsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GoalsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int?> assetId = const Value.absent(),
            Value<int?> accountId = const Value.absent(),
            Value<int> createdOn = const Value.absent(),
            Value<int> targetDate = const Value.absent(),
            Value<double> targetShares = const Value.absent(),
            Value<double> targetValue = const Value.absent(),
          }) =>
              GoalsCompanion(
            id: id,
            assetId: assetId,
            accountId: accountId,
            createdOn: createdOn,
            targetDate: targetDate,
            targetShares: targetShares,
            targetValue: targetValue,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int?> assetId = const Value.absent(),
            Value<int?> accountId = const Value.absent(),
            required int createdOn,
            required int targetDate,
            required double targetShares,
            required double targetValue,
          }) =>
              GoalsCompanion.insert(
            id: id,
            assetId: assetId,
            accountId: accountId,
            createdOn: createdOn,
            targetDate: targetDate,
            targetShares: targetShares,
            targetValue: targetValue,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$GoalsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({assetId = false, accountId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (assetId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.assetId,
                    referencedTable: $$GoalsTableReferences._assetIdTable(db),
                    referencedColumn:
                        $$GoalsTableReferences._assetIdTable(db).id,
                  ) as T;
                }
                if (accountId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.accountId,
                    referencedTable: $$GoalsTableReferences._accountIdTable(db),
                    referencedColumn:
                        $$GoalsTableReferences._accountIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$GoalsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $GoalsTable,
    Goal,
    $$GoalsTableFilterComposer,
    $$GoalsTableOrderingComposer,
    $$GoalsTableAnnotationComposer,
    $$GoalsTableCreateCompanionBuilder,
    $$GoalsTableUpdateCompanionBuilder,
    (Goal, $$GoalsTableReferences),
    Goal,
    PrefetchHooks Function({bool assetId, bool accountId})>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$AccountsTableTableManager get accounts =>
      $$AccountsTableTableManager(_db, _db.accounts);
  $$AssetsTableTableManager get assets =>
      $$AssetsTableTableManager(_db, _db.assets);
  $$BookingsTableTableManager get bookings =>
      $$BookingsTableTableManager(_db, _db.bookings);
  $$TransfersTableTableManager get transfers =>
      $$TransfersTableTableManager(_db, _db.transfers);
  $$TradesTableTableManager get trades =>
      $$TradesTableTableManager(_db, _db.trades);
  $$PeriodicBookingsTableTableManager get periodicBookings =>
      $$PeriodicBookingsTableTableManager(_db, _db.periodicBookings);
  $$PeriodicTransfersTableTableManager get periodicTransfers =>
      $$PeriodicTransfersTableTableManager(_db, _db.periodicTransfers);
  $$AssetsOnAccountsTableTableManager get assetsOnAccounts =>
      $$AssetsOnAccountsTableTableManager(_db, _db.assetsOnAccounts);
  $$GoalsTableTableManager get goals =>
      $$GoalsTableTableManager(_db, _db.goals);
}
