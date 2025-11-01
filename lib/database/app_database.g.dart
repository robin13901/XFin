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
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _initialBalanceMeta =
      const VerificationMeta('initialBalance');
  @override
  late final GeneratedColumn<double> initialBalance = GeneratedColumn<double>(
      'initial_balance', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
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
    } else if (isInserting) {
      context.missing(_balanceMeta);
    }
    if (data.containsKey('initial_balance')) {
      context.handle(
          _initialBalanceMeta,
          initialBalance.isAcceptableOrUnknown(
              data['initial_balance']!, _initialBalanceMeta));
    } else if (isInserting) {
      context.missing(_initialBalanceMeta);
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
    required double balance,
    required double initialBalance,
    required AccountTypes type,
    this.isArchived = const Value.absent(),
  })  : name = Value(name),
        balance = Value(balance),
        initialBalance = Value(initialBalance),
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
  @override
  List<GeneratedColumn> get $columns => [id, name, type, tickerSymbol];
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
  const Asset(
      {required this.id,
      required this.name,
      required this.type,
      required this.tickerSymbol});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    {
      map['type'] = Variable<String>($AssetsTable.$convertertype.toSql(type));
    }
    map['ticker_symbol'] = Variable<String>(tickerSymbol);
    return map;
  }

  AssetsCompanion toCompanion(bool nullToAbsent) {
    return AssetsCompanion(
      id: Value(id),
      name: Value(name),
      type: Value(type),
      tickerSymbol: Value(tickerSymbol),
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
    };
  }

  Asset copyWith(
          {int? id, String? name, AssetTypes? type, String? tickerSymbol}) =>
      Asset(
        id: id ?? this.id,
        name: name ?? this.name,
        type: type ?? this.type,
        tickerSymbol: tickerSymbol ?? this.tickerSymbol,
      );
  Asset copyWithCompanion(AssetsCompanion data) {
    return Asset(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      type: data.type.present ? data.type.value : this.type,
      tickerSymbol: data.tickerSymbol.present
          ? data.tickerSymbol.value
          : this.tickerSymbol,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Asset(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('tickerSymbol: $tickerSymbol')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, type, tickerSymbol);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Asset &&
          other.id == this.id &&
          other.name == this.name &&
          other.type == this.type &&
          other.tickerSymbol == this.tickerSymbol);
}

class AssetsCompanion extends UpdateCompanion<Asset> {
  final Value<int> id;
  final Value<String> name;
  final Value<AssetTypes> type;
  final Value<String> tickerSymbol;
  const AssetsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.tickerSymbol = const Value.absent(),
  });
  AssetsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required AssetTypes type,
    required String tickerSymbol,
  })  : name = Value(name),
        type = Value(type),
        tickerSymbol = Value(tickerSymbol);
  static Insertable<Asset> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? type,
    Expression<String>? tickerSymbol,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (tickerSymbol != null) 'ticker_symbol': tickerSymbol,
    });
  }

  AssetsCompanion copyWith(
      {Value<int>? id,
      Value<String>? name,
      Value<AssetTypes>? type,
      Value<String>? tickerSymbol}) {
    return AssetsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      tickerSymbol: tickerSymbol ?? this.tickerSymbol,
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
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AssetsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('tickerSymbol: $tickerSymbol')
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
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
      'amount', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
      'reason', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _accountIdMeta =
      const VerificationMeta('accountId');
  @override
  late final GeneratedColumn<int> accountId = GeneratedColumn<int>(
      'account_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES accounts (id)'));
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
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_generated" IN (0, 1))'));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        date,
        amount,
        reason,
        accountId,
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
    if (data.containsKey('amount')) {
      context.handle(_amountMeta,
          amount.isAcceptableOrUnknown(data['amount']!, _amountMeta));
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('reason')) {
      context.handle(_reasonMeta,
          reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta));
    } else if (isInserting) {
      context.missing(_reasonMeta);
    }
    if (data.containsKey('account_id')) {
      context.handle(_accountIdMeta,
          accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta));
    } else if (isInserting) {
      context.missing(_accountIdMeta);
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
    } else if (isInserting) {
      context.missing(_isGeneratedMeta);
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
      amount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}amount'])!,
      reason: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}reason'])!,
      accountId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}account_id'])!,
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
  final double amount;
  final String reason;
  final int accountId;
  final String? notes;
  final bool excludeFromAverage;
  final bool isGenerated;
  const Booking(
      {required this.id,
      required this.date,
      required this.amount,
      required this.reason,
      required this.accountId,
      this.notes,
      required this.excludeFromAverage,
      required this.isGenerated});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['date'] = Variable<int>(date);
    map['amount'] = Variable<double>(amount);
    map['reason'] = Variable<String>(reason);
    map['account_id'] = Variable<int>(accountId);
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
      amount: Value(amount),
      reason: Value(reason),
      accountId: Value(accountId),
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
      amount: serializer.fromJson<double>(json['amount']),
      reason: serializer.fromJson<String>(json['reason']),
      accountId: serializer.fromJson<int>(json['accountId']),
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
      'amount': serializer.toJson<double>(amount),
      'reason': serializer.toJson<String>(reason),
      'accountId': serializer.toJson<int>(accountId),
      'notes': serializer.toJson<String?>(notes),
      'excludeFromAverage': serializer.toJson<bool>(excludeFromAverage),
      'isGenerated': serializer.toJson<bool>(isGenerated),
    };
  }

  Booking copyWith(
          {int? id,
          int? date,
          double? amount,
          String? reason,
          int? accountId,
          Value<String?> notes = const Value.absent(),
          bool? excludeFromAverage,
          bool? isGenerated}) =>
      Booking(
        id: id ?? this.id,
        date: date ?? this.date,
        amount: amount ?? this.amount,
        reason: reason ?? this.reason,
        accountId: accountId ?? this.accountId,
        notes: notes.present ? notes.value : this.notes,
        excludeFromAverage: excludeFromAverage ?? this.excludeFromAverage,
        isGenerated: isGenerated ?? this.isGenerated,
      );
  Booking copyWithCompanion(BookingsCompanion data) {
    return Booking(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
      amount: data.amount.present ? data.amount.value : this.amount,
      reason: data.reason.present ? data.reason.value : this.reason,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
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
          ..write('amount: $amount, ')
          ..write('reason: $reason, ')
          ..write('accountId: $accountId, ')
          ..write('notes: $notes, ')
          ..write('excludeFromAverage: $excludeFromAverage, ')
          ..write('isGenerated: $isGenerated')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, date, amount, reason, accountId, notes,
      excludeFromAverage, isGenerated);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Booking &&
          other.id == this.id &&
          other.date == this.date &&
          other.amount == this.amount &&
          other.reason == this.reason &&
          other.accountId == this.accountId &&
          other.notes == this.notes &&
          other.excludeFromAverage == this.excludeFromAverage &&
          other.isGenerated == this.isGenerated);
}

class BookingsCompanion extends UpdateCompanion<Booking> {
  final Value<int> id;
  final Value<int> date;
  final Value<double> amount;
  final Value<String> reason;
  final Value<int> accountId;
  final Value<String?> notes;
  final Value<bool> excludeFromAverage;
  final Value<bool> isGenerated;
  const BookingsCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.amount = const Value.absent(),
    this.reason = const Value.absent(),
    this.accountId = const Value.absent(),
    this.notes = const Value.absent(),
    this.excludeFromAverage = const Value.absent(),
    this.isGenerated = const Value.absent(),
  });
  BookingsCompanion.insert({
    this.id = const Value.absent(),
    required int date,
    required double amount,
    required String reason,
    required int accountId,
    this.notes = const Value.absent(),
    this.excludeFromAverage = const Value.absent(),
    required bool isGenerated,
  })  : date = Value(date),
        amount = Value(amount),
        reason = Value(reason),
        accountId = Value(accountId),
        isGenerated = Value(isGenerated);
  static Insertable<Booking> custom({
    Expression<int>? id,
    Expression<int>? date,
    Expression<double>? amount,
    Expression<String>? reason,
    Expression<int>? accountId,
    Expression<String>? notes,
    Expression<bool>? excludeFromAverage,
    Expression<bool>? isGenerated,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (amount != null) 'amount': amount,
      if (reason != null) 'reason': reason,
      if (accountId != null) 'account_id': accountId,
      if (notes != null) 'notes': notes,
      if (excludeFromAverage != null)
        'exclude_from_average': excludeFromAverage,
      if (isGenerated != null) 'is_generated': isGenerated,
    });
  }

  BookingsCompanion copyWith(
      {Value<int>? id,
      Value<int>? date,
      Value<double>? amount,
      Value<String>? reason,
      Value<int>? accountId,
      Value<String?>? notes,
      Value<bool>? excludeFromAverage,
      Value<bool>? isGenerated}) {
    return BookingsCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      amount: amount ?? this.amount,
      reason: reason ?? this.reason,
      accountId: accountId ?? this.accountId,
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
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<int>(accountId.value);
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
          ..write('amount: $amount, ')
          ..write('reason: $reason, ')
          ..write('accountId: $accountId, ')
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
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
      'amount', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
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
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_generated" IN (0, 1))'));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        date,
        amount,
        sendingAccountId,
        receivingAccountId,
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
    if (data.containsKey('amount')) {
      context.handle(_amountMeta,
          amount.isAcceptableOrUnknown(data['amount']!, _amountMeta));
    } else if (isInserting) {
      context.missing(_amountMeta);
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
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('is_generated')) {
      context.handle(
          _isGeneratedMeta,
          isGenerated.isAcceptableOrUnknown(
              data['is_generated']!, _isGeneratedMeta));
    } else if (isInserting) {
      context.missing(_isGeneratedMeta);
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
      amount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}amount'])!,
      sendingAccountId: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}sending_account_id'])!,
      receivingAccountId: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}receiving_account_id'])!,
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
  final double amount;
  final int sendingAccountId;
  final int receivingAccountId;
  final String? notes;
  final bool isGenerated;
  const Transfer(
      {required this.id,
      required this.date,
      required this.amount,
      required this.sendingAccountId,
      required this.receivingAccountId,
      this.notes,
      required this.isGenerated});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['date'] = Variable<int>(date);
    map['amount'] = Variable<double>(amount);
    map['sending_account_id'] = Variable<int>(sendingAccountId);
    map['receiving_account_id'] = Variable<int>(receivingAccountId);
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
      amount: Value(amount),
      sendingAccountId: Value(sendingAccountId),
      receivingAccountId: Value(receivingAccountId),
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
      amount: serializer.fromJson<double>(json['amount']),
      sendingAccountId: serializer.fromJson<int>(json['sendingAccountId']),
      receivingAccountId: serializer.fromJson<int>(json['receivingAccountId']),
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
      'amount': serializer.toJson<double>(amount),
      'sendingAccountId': serializer.toJson<int>(sendingAccountId),
      'receivingAccountId': serializer.toJson<int>(receivingAccountId),
      'notes': serializer.toJson<String?>(notes),
      'isGenerated': serializer.toJson<bool>(isGenerated),
    };
  }

  Transfer copyWith(
          {int? id,
          int? date,
          double? amount,
          int? sendingAccountId,
          int? receivingAccountId,
          Value<String?> notes = const Value.absent(),
          bool? isGenerated}) =>
      Transfer(
        id: id ?? this.id,
        date: date ?? this.date,
        amount: amount ?? this.amount,
        sendingAccountId: sendingAccountId ?? this.sendingAccountId,
        receivingAccountId: receivingAccountId ?? this.receivingAccountId,
        notes: notes.present ? notes.value : this.notes,
        isGenerated: isGenerated ?? this.isGenerated,
      );
  Transfer copyWithCompanion(TransfersCompanion data) {
    return Transfer(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
      amount: data.amount.present ? data.amount.value : this.amount,
      sendingAccountId: data.sendingAccountId.present
          ? data.sendingAccountId.value
          : this.sendingAccountId,
      receivingAccountId: data.receivingAccountId.present
          ? data.receivingAccountId.value
          : this.receivingAccountId,
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
          ..write('amount: $amount, ')
          ..write('sendingAccountId: $sendingAccountId, ')
          ..write('receivingAccountId: $receivingAccountId, ')
          ..write('notes: $notes, ')
          ..write('isGenerated: $isGenerated')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, date, amount, sendingAccountId,
      receivingAccountId, notes, isGenerated);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Transfer &&
          other.id == this.id &&
          other.date == this.date &&
          other.amount == this.amount &&
          other.sendingAccountId == this.sendingAccountId &&
          other.receivingAccountId == this.receivingAccountId &&
          other.notes == this.notes &&
          other.isGenerated == this.isGenerated);
}

class TransfersCompanion extends UpdateCompanion<Transfer> {
  final Value<int> id;
  final Value<int> date;
  final Value<double> amount;
  final Value<int> sendingAccountId;
  final Value<int> receivingAccountId;
  final Value<String?> notes;
  final Value<bool> isGenerated;
  const TransfersCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.amount = const Value.absent(),
    this.sendingAccountId = const Value.absent(),
    this.receivingAccountId = const Value.absent(),
    this.notes = const Value.absent(),
    this.isGenerated = const Value.absent(),
  });
  TransfersCompanion.insert({
    this.id = const Value.absent(),
    required int date,
    required double amount,
    required int sendingAccountId,
    required int receivingAccountId,
    this.notes = const Value.absent(),
    required bool isGenerated,
  })  : date = Value(date),
        amount = Value(amount),
        sendingAccountId = Value(sendingAccountId),
        receivingAccountId = Value(receivingAccountId),
        isGenerated = Value(isGenerated);
  static Insertable<Transfer> custom({
    Expression<int>? id,
    Expression<int>? date,
    Expression<double>? amount,
    Expression<int>? sendingAccountId,
    Expression<int>? receivingAccountId,
    Expression<String>? notes,
    Expression<bool>? isGenerated,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (amount != null) 'amount': amount,
      if (sendingAccountId != null) 'sending_account_id': sendingAccountId,
      if (receivingAccountId != null)
        'receiving_account_id': receivingAccountId,
      if (notes != null) 'notes': notes,
      if (isGenerated != null) 'is_generated': isGenerated,
    });
  }

  TransfersCompanion copyWith(
      {Value<int>? id,
      Value<int>? date,
      Value<double>? amount,
      Value<int>? sendingAccountId,
      Value<int>? receivingAccountId,
      Value<String?>? notes,
      Value<bool>? isGenerated}) {
    return TransfersCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      amount: amount ?? this.amount,
      sendingAccountId: sendingAccountId ?? this.sendingAccountId,
      receivingAccountId: receivingAccountId ?? this.receivingAccountId,
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
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (sendingAccountId.present) {
      map['sending_account_id'] = Variable<int>(sendingAccountId.value);
    }
    if (receivingAccountId.present) {
      map['receiving_account_id'] = Variable<int>(receivingAccountId.value);
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
          ..write('amount: $amount, ')
          ..write('sendingAccountId: $sendingAccountId, ')
          ..write('receivingAccountId: $receivingAccountId, ')
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
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES assets (id)'));
  @override
  late final GeneratedColumnWithTypeConverter<TradeTypes, String> type =
      GeneratedColumn<String>('type', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<TradeTypes>($TradesTable.$convertertype);
  static const VerificationMeta _movedValueMeta =
      const VerificationMeta('movedValue');
  @override
  late final GeneratedColumn<double> movedValue = GeneratedColumn<double>(
      'moved_value', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _sharesMeta = const VerificationMeta('shares');
  @override
  late final GeneratedColumn<double> shares = GeneratedColumn<double>(
      'shares', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _pricePerShareMeta =
      const VerificationMeta('pricePerShare');
  @override
  late final GeneratedColumn<double> pricePerShare = GeneratedColumn<double>(
      'price_per_share', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _profitAndLossMeta =
      const VerificationMeta('profitAndLoss');
  @override
  late final GeneratedColumn<double> profitAndLoss = GeneratedColumn<double>(
      'profit_and_loss', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _tradingFeeMeta =
      const VerificationMeta('tradingFee');
  @override
  late final GeneratedColumn<double> tradingFee = GeneratedColumn<double>(
      'trading_fee', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _clearingAccountIdMeta =
      const VerificationMeta('clearingAccountId');
  @override
  late final GeneratedColumn<int> clearingAccountId = GeneratedColumn<int>(
      'clearing_account_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES accounts (id)'));
  static const VerificationMeta _portfolioAccountIdMeta =
      const VerificationMeta('portfolioAccountId');
  @override
  late final GeneratedColumn<int> portfolioAccountId = GeneratedColumn<int>(
      'portfolio_account_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES accounts (id)'));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        date,
        assetId,
        type,
        movedValue,
        shares,
        pricePerShare,
        profitAndLoss,
        tradingFee,
        clearingAccountId,
        portfolioAccountId
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
    if (data.containsKey('date')) {
      context.handle(
          _dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('asset_id')) {
      context.handle(_assetIdMeta,
          assetId.isAcceptableOrUnknown(data['asset_id']!, _assetIdMeta));
    } else if (isInserting) {
      context.missing(_assetIdMeta);
    }
    if (data.containsKey('moved_value')) {
      context.handle(
          _movedValueMeta,
          movedValue.isAcceptableOrUnknown(
              data['moved_value']!, _movedValueMeta));
    } else if (isInserting) {
      context.missing(_movedValueMeta);
    }
    if (data.containsKey('shares')) {
      context.handle(_sharesMeta,
          shares.isAcceptableOrUnknown(data['shares']!, _sharesMeta));
    } else if (isInserting) {
      context.missing(_sharesMeta);
    }
    if (data.containsKey('price_per_share')) {
      context.handle(
          _pricePerShareMeta,
          pricePerShare.isAcceptableOrUnknown(
              data['price_per_share']!, _pricePerShareMeta));
    } else if (isInserting) {
      context.missing(_pricePerShareMeta);
    }
    if (data.containsKey('profit_and_loss')) {
      context.handle(
          _profitAndLossMeta,
          profitAndLoss.isAcceptableOrUnknown(
              data['profit_and_loss']!, _profitAndLossMeta));
    } else if (isInserting) {
      context.missing(_profitAndLossMeta);
    }
    if (data.containsKey('trading_fee')) {
      context.handle(
          _tradingFeeMeta,
          tradingFee.isAcceptableOrUnknown(
              data['trading_fee']!, _tradingFeeMeta));
    } else if (isInserting) {
      context.missing(_tradingFeeMeta);
    }
    if (data.containsKey('clearing_account_id')) {
      context.handle(
          _clearingAccountIdMeta,
          clearingAccountId.isAcceptableOrUnknown(
              data['clearing_account_id']!, _clearingAccountIdMeta));
    } else if (isInserting) {
      context.missing(_clearingAccountIdMeta);
    }
    if (data.containsKey('portfolio_account_id')) {
      context.handle(
          _portfolioAccountIdMeta,
          portfolioAccountId.isAcceptableOrUnknown(
              data['portfolio_account_id']!, _portfolioAccountIdMeta));
    } else if (isInserting) {
      context.missing(_portfolioAccountIdMeta);
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
      date: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}date'])!,
      assetId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}asset_id'])!,
      type: $TradesTable.$convertertype.fromSql(attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!),
      movedValue: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}moved_value'])!,
      shares: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}shares'])!,
      pricePerShare: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}price_per_share'])!,
      profitAndLoss: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}profit_and_loss'])!,
      tradingFee: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}trading_fee'])!,
      clearingAccountId: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}clearing_account_id'])!,
      portfolioAccountId: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}portfolio_account_id'])!,
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
  final int date;
  final int assetId;
  final TradeTypes type;
  final double movedValue;
  final double shares;
  final double pricePerShare;
  final double profitAndLoss;
  final double tradingFee;
  final int clearingAccountId;
  final int portfolioAccountId;
  const Trade(
      {required this.id,
      required this.date,
      required this.assetId,
      required this.type,
      required this.movedValue,
      required this.shares,
      required this.pricePerShare,
      required this.profitAndLoss,
      required this.tradingFee,
      required this.clearingAccountId,
      required this.portfolioAccountId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['date'] = Variable<int>(date);
    map['asset_id'] = Variable<int>(assetId);
    {
      map['type'] = Variable<String>($TradesTable.$convertertype.toSql(type));
    }
    map['moved_value'] = Variable<double>(movedValue);
    map['shares'] = Variable<double>(shares);
    map['price_per_share'] = Variable<double>(pricePerShare);
    map['profit_and_loss'] = Variable<double>(profitAndLoss);
    map['trading_fee'] = Variable<double>(tradingFee);
    map['clearing_account_id'] = Variable<int>(clearingAccountId);
    map['portfolio_account_id'] = Variable<int>(portfolioAccountId);
    return map;
  }

  TradesCompanion toCompanion(bool nullToAbsent) {
    return TradesCompanion(
      id: Value(id),
      date: Value(date),
      assetId: Value(assetId),
      type: Value(type),
      movedValue: Value(movedValue),
      shares: Value(shares),
      pricePerShare: Value(pricePerShare),
      profitAndLoss: Value(profitAndLoss),
      tradingFee: Value(tradingFee),
      clearingAccountId: Value(clearingAccountId),
      portfolioAccountId: Value(portfolioAccountId),
    );
  }

  factory Trade.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Trade(
      id: serializer.fromJson<int>(json['id']),
      date: serializer.fromJson<int>(json['date']),
      assetId: serializer.fromJson<int>(json['assetId']),
      type: serializer.fromJson<TradeTypes>(json['type']),
      movedValue: serializer.fromJson<double>(json['movedValue']),
      shares: serializer.fromJson<double>(json['shares']),
      pricePerShare: serializer.fromJson<double>(json['pricePerShare']),
      profitAndLoss: serializer.fromJson<double>(json['profitAndLoss']),
      tradingFee: serializer.fromJson<double>(json['tradingFee']),
      clearingAccountId: serializer.fromJson<int>(json['clearingAccountId']),
      portfolioAccountId: serializer.fromJson<int>(json['portfolioAccountId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'date': serializer.toJson<int>(date),
      'assetId': serializer.toJson<int>(assetId),
      'type': serializer.toJson<TradeTypes>(type),
      'movedValue': serializer.toJson<double>(movedValue),
      'shares': serializer.toJson<double>(shares),
      'pricePerShare': serializer.toJson<double>(pricePerShare),
      'profitAndLoss': serializer.toJson<double>(profitAndLoss),
      'tradingFee': serializer.toJson<double>(tradingFee),
      'clearingAccountId': serializer.toJson<int>(clearingAccountId),
      'portfolioAccountId': serializer.toJson<int>(portfolioAccountId),
    };
  }

  Trade copyWith(
          {int? id,
          int? date,
          int? assetId,
          TradeTypes? type,
          double? movedValue,
          double? shares,
          double? pricePerShare,
          double? profitAndLoss,
          double? tradingFee,
          int? clearingAccountId,
          int? portfolioAccountId}) =>
      Trade(
        id: id ?? this.id,
        date: date ?? this.date,
        assetId: assetId ?? this.assetId,
        type: type ?? this.type,
        movedValue: movedValue ?? this.movedValue,
        shares: shares ?? this.shares,
        pricePerShare: pricePerShare ?? this.pricePerShare,
        profitAndLoss: profitAndLoss ?? this.profitAndLoss,
        tradingFee: tradingFee ?? this.tradingFee,
        clearingAccountId: clearingAccountId ?? this.clearingAccountId,
        portfolioAccountId: portfolioAccountId ?? this.portfolioAccountId,
      );
  Trade copyWithCompanion(TradesCompanion data) {
    return Trade(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
      assetId: data.assetId.present ? data.assetId.value : this.assetId,
      type: data.type.present ? data.type.value : this.type,
      movedValue:
          data.movedValue.present ? data.movedValue.value : this.movedValue,
      shares: data.shares.present ? data.shares.value : this.shares,
      pricePerShare: data.pricePerShare.present
          ? data.pricePerShare.value
          : this.pricePerShare,
      profitAndLoss: data.profitAndLoss.present
          ? data.profitAndLoss.value
          : this.profitAndLoss,
      tradingFee:
          data.tradingFee.present ? data.tradingFee.value : this.tradingFee,
      clearingAccountId: data.clearingAccountId.present
          ? data.clearingAccountId.value
          : this.clearingAccountId,
      portfolioAccountId: data.portfolioAccountId.present
          ? data.portfolioAccountId.value
          : this.portfolioAccountId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Trade(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('assetId: $assetId, ')
          ..write('type: $type, ')
          ..write('movedValue: $movedValue, ')
          ..write('shares: $shares, ')
          ..write('pricePerShare: $pricePerShare, ')
          ..write('profitAndLoss: $profitAndLoss, ')
          ..write('tradingFee: $tradingFee, ')
          ..write('clearingAccountId: $clearingAccountId, ')
          ..write('portfolioAccountId: $portfolioAccountId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      date,
      assetId,
      type,
      movedValue,
      shares,
      pricePerShare,
      profitAndLoss,
      tradingFee,
      clearingAccountId,
      portfolioAccountId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Trade &&
          other.id == this.id &&
          other.date == this.date &&
          other.assetId == this.assetId &&
          other.type == this.type &&
          other.movedValue == this.movedValue &&
          other.shares == this.shares &&
          other.pricePerShare == this.pricePerShare &&
          other.profitAndLoss == this.profitAndLoss &&
          other.tradingFee == this.tradingFee &&
          other.clearingAccountId == this.clearingAccountId &&
          other.portfolioAccountId == this.portfolioAccountId);
}

class TradesCompanion extends UpdateCompanion<Trade> {
  final Value<int> id;
  final Value<int> date;
  final Value<int> assetId;
  final Value<TradeTypes> type;
  final Value<double> movedValue;
  final Value<double> shares;
  final Value<double> pricePerShare;
  final Value<double> profitAndLoss;
  final Value<double> tradingFee;
  final Value<int> clearingAccountId;
  final Value<int> portfolioAccountId;
  const TradesCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.assetId = const Value.absent(),
    this.type = const Value.absent(),
    this.movedValue = const Value.absent(),
    this.shares = const Value.absent(),
    this.pricePerShare = const Value.absent(),
    this.profitAndLoss = const Value.absent(),
    this.tradingFee = const Value.absent(),
    this.clearingAccountId = const Value.absent(),
    this.portfolioAccountId = const Value.absent(),
  });
  TradesCompanion.insert({
    this.id = const Value.absent(),
    required int date,
    required int assetId,
    required TradeTypes type,
    required double movedValue,
    required double shares,
    required double pricePerShare,
    required double profitAndLoss,
    required double tradingFee,
    required int clearingAccountId,
    required int portfolioAccountId,
  })  : date = Value(date),
        assetId = Value(assetId),
        type = Value(type),
        movedValue = Value(movedValue),
        shares = Value(shares),
        pricePerShare = Value(pricePerShare),
        profitAndLoss = Value(profitAndLoss),
        tradingFee = Value(tradingFee),
        clearingAccountId = Value(clearingAccountId),
        portfolioAccountId = Value(portfolioAccountId);
  static Insertable<Trade> custom({
    Expression<int>? id,
    Expression<int>? date,
    Expression<int>? assetId,
    Expression<String>? type,
    Expression<double>? movedValue,
    Expression<double>? shares,
    Expression<double>? pricePerShare,
    Expression<double>? profitAndLoss,
    Expression<double>? tradingFee,
    Expression<int>? clearingAccountId,
    Expression<int>? portfolioAccountId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (assetId != null) 'asset_id': assetId,
      if (type != null) 'type': type,
      if (movedValue != null) 'moved_value': movedValue,
      if (shares != null) 'shares': shares,
      if (pricePerShare != null) 'price_per_share': pricePerShare,
      if (profitAndLoss != null) 'profit_and_loss': profitAndLoss,
      if (tradingFee != null) 'trading_fee': tradingFee,
      if (clearingAccountId != null) 'clearing_account_id': clearingAccountId,
      if (portfolioAccountId != null)
        'portfolio_account_id': portfolioAccountId,
    });
  }

  TradesCompanion copyWith(
      {Value<int>? id,
      Value<int>? date,
      Value<int>? assetId,
      Value<TradeTypes>? type,
      Value<double>? movedValue,
      Value<double>? shares,
      Value<double>? pricePerShare,
      Value<double>? profitAndLoss,
      Value<double>? tradingFee,
      Value<int>? clearingAccountId,
      Value<int>? portfolioAccountId}) {
    return TradesCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      assetId: assetId ?? this.assetId,
      type: type ?? this.type,
      movedValue: movedValue ?? this.movedValue,
      shares: shares ?? this.shares,
      pricePerShare: pricePerShare ?? this.pricePerShare,
      profitAndLoss: profitAndLoss ?? this.profitAndLoss,
      tradingFee: tradingFee ?? this.tradingFee,
      clearingAccountId: clearingAccountId ?? this.clearingAccountId,
      portfolioAccountId: portfolioAccountId ?? this.portfolioAccountId,
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
    if (type.present) {
      map['type'] =
          Variable<String>($TradesTable.$convertertype.toSql(type.value));
    }
    if (movedValue.present) {
      map['moved_value'] = Variable<double>(movedValue.value);
    }
    if (shares.present) {
      map['shares'] = Variable<double>(shares.value);
    }
    if (pricePerShare.present) {
      map['price_per_share'] = Variable<double>(pricePerShare.value);
    }
    if (profitAndLoss.present) {
      map['profit_and_loss'] = Variable<double>(profitAndLoss.value);
    }
    if (tradingFee.present) {
      map['trading_fee'] = Variable<double>(tradingFee.value);
    }
    if (clearingAccountId.present) {
      map['clearing_account_id'] = Variable<int>(clearingAccountId.value);
    }
    if (portfolioAccountId.present) {
      map['portfolio_account_id'] = Variable<int>(portfolioAccountId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TradesCompanion(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('assetId: $assetId, ')
          ..write('type: $type, ')
          ..write('movedValue: $movedValue, ')
          ..write('shares: $shares, ')
          ..write('pricePerShare: $pricePerShare, ')
          ..write('profitAndLoss: $profitAndLoss, ')
          ..write('tradingFee: $tradingFee, ')
          ..write('clearingAccountId: $clearingAccountId, ')
          ..write('portfolioAccountId: $portfolioAccountId')
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
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
      'amount', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _accountIdMeta =
      const VerificationMeta('accountId');
  @override
  late final GeneratedColumn<int> accountId = GeneratedColumn<int>(
      'account_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES accounts (id)'));
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
      'reason', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  late final GeneratedColumnWithTypeConverter<Cycles, String> cycle =
      GeneratedColumn<String>('cycle', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<Cycles>($PeriodicBookingsTable.$convertercycle);
  @override
  List<GeneratedColumn> get $columns =>
      [id, nextExecutionDate, amount, accountId, reason, notes, cycle];
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
    if (data.containsKey('amount')) {
      context.handle(_amountMeta,
          amount.isAcceptableOrUnknown(data['amount']!, _amountMeta));
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('account_id')) {
      context.handle(_accountIdMeta,
          accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta));
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('reason')) {
      context.handle(_reasonMeta,
          reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta));
    } else if (isInserting) {
      context.missing(_reasonMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
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
      amount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}amount'])!,
      accountId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}account_id'])!,
      reason: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}reason'])!,
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
      cycle: $PeriodicBookingsTable.$convertercycle.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}cycle'])!),
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
  final double amount;
  final int accountId;
  final String reason;
  final String? notes;
  final Cycles cycle;
  const PeriodicBooking(
      {required this.id,
      required this.nextExecutionDate,
      required this.amount,
      required this.accountId,
      required this.reason,
      this.notes,
      required this.cycle});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['next_execution_date'] = Variable<int>(nextExecutionDate);
    map['amount'] = Variable<double>(amount);
    map['account_id'] = Variable<int>(accountId);
    map['reason'] = Variable<String>(reason);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    {
      map['cycle'] =
          Variable<String>($PeriodicBookingsTable.$convertercycle.toSql(cycle));
    }
    return map;
  }

  PeriodicBookingsCompanion toCompanion(bool nullToAbsent) {
    return PeriodicBookingsCompanion(
      id: Value(id),
      nextExecutionDate: Value(nextExecutionDate),
      amount: Value(amount),
      accountId: Value(accountId),
      reason: Value(reason),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      cycle: Value(cycle),
    );
  }

  factory PeriodicBooking.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PeriodicBooking(
      id: serializer.fromJson<int>(json['id']),
      nextExecutionDate: serializer.fromJson<int>(json['nextExecutionDate']),
      amount: serializer.fromJson<double>(json['amount']),
      accountId: serializer.fromJson<int>(json['accountId']),
      reason: serializer.fromJson<String>(json['reason']),
      notes: serializer.fromJson<String?>(json['notes']),
      cycle: serializer.fromJson<Cycles>(json['cycle']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'nextExecutionDate': serializer.toJson<int>(nextExecutionDate),
      'amount': serializer.toJson<double>(amount),
      'accountId': serializer.toJson<int>(accountId),
      'reason': serializer.toJson<String>(reason),
      'notes': serializer.toJson<String?>(notes),
      'cycle': serializer.toJson<Cycles>(cycle),
    };
  }

  PeriodicBooking copyWith(
          {int? id,
          int? nextExecutionDate,
          double? amount,
          int? accountId,
          String? reason,
          Value<String?> notes = const Value.absent(),
          Cycles? cycle}) =>
      PeriodicBooking(
        id: id ?? this.id,
        nextExecutionDate: nextExecutionDate ?? this.nextExecutionDate,
        amount: amount ?? this.amount,
        accountId: accountId ?? this.accountId,
        reason: reason ?? this.reason,
        notes: notes.present ? notes.value : this.notes,
        cycle: cycle ?? this.cycle,
      );
  PeriodicBooking copyWithCompanion(PeriodicBookingsCompanion data) {
    return PeriodicBooking(
      id: data.id.present ? data.id.value : this.id,
      nextExecutionDate: data.nextExecutionDate.present
          ? data.nextExecutionDate.value
          : this.nextExecutionDate,
      amount: data.amount.present ? data.amount.value : this.amount,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      reason: data.reason.present ? data.reason.value : this.reason,
      notes: data.notes.present ? data.notes.value : this.notes,
      cycle: data.cycle.present ? data.cycle.value : this.cycle,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PeriodicBooking(')
          ..write('id: $id, ')
          ..write('nextExecutionDate: $nextExecutionDate, ')
          ..write('amount: $amount, ')
          ..write('accountId: $accountId, ')
          ..write('reason: $reason, ')
          ..write('notes: $notes, ')
          ..write('cycle: $cycle')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, nextExecutionDate, amount, accountId, reason, notes, cycle);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PeriodicBooking &&
          other.id == this.id &&
          other.nextExecutionDate == this.nextExecutionDate &&
          other.amount == this.amount &&
          other.accountId == this.accountId &&
          other.reason == this.reason &&
          other.notes == this.notes &&
          other.cycle == this.cycle);
}

class PeriodicBookingsCompanion extends UpdateCompanion<PeriodicBooking> {
  final Value<int> id;
  final Value<int> nextExecutionDate;
  final Value<double> amount;
  final Value<int> accountId;
  final Value<String> reason;
  final Value<String?> notes;
  final Value<Cycles> cycle;
  const PeriodicBookingsCompanion({
    this.id = const Value.absent(),
    this.nextExecutionDate = const Value.absent(),
    this.amount = const Value.absent(),
    this.accountId = const Value.absent(),
    this.reason = const Value.absent(),
    this.notes = const Value.absent(),
    this.cycle = const Value.absent(),
  });
  PeriodicBookingsCompanion.insert({
    this.id = const Value.absent(),
    required int nextExecutionDate,
    required double amount,
    required int accountId,
    required String reason,
    this.notes = const Value.absent(),
    required Cycles cycle,
  })  : nextExecutionDate = Value(nextExecutionDate),
        amount = Value(amount),
        accountId = Value(accountId),
        reason = Value(reason),
        cycle = Value(cycle);
  static Insertable<PeriodicBooking> custom({
    Expression<int>? id,
    Expression<int>? nextExecutionDate,
    Expression<double>? amount,
    Expression<int>? accountId,
    Expression<String>? reason,
    Expression<String>? notes,
    Expression<String>? cycle,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (nextExecutionDate != null) 'next_execution_date': nextExecutionDate,
      if (amount != null) 'amount': amount,
      if (accountId != null) 'account_id': accountId,
      if (reason != null) 'reason': reason,
      if (notes != null) 'notes': notes,
      if (cycle != null) 'cycle': cycle,
    });
  }

  PeriodicBookingsCompanion copyWith(
      {Value<int>? id,
      Value<int>? nextExecutionDate,
      Value<double>? amount,
      Value<int>? accountId,
      Value<String>? reason,
      Value<String?>? notes,
      Value<Cycles>? cycle}) {
    return PeriodicBookingsCompanion(
      id: id ?? this.id,
      nextExecutionDate: nextExecutionDate ?? this.nextExecutionDate,
      amount: amount ?? this.amount,
      accountId: accountId ?? this.accountId,
      reason: reason ?? this.reason,
      notes: notes ?? this.notes,
      cycle: cycle ?? this.cycle,
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
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<int>(accountId.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (cycle.present) {
      map['cycle'] = Variable<String>(
          $PeriodicBookingsTable.$convertercycle.toSql(cycle.value));
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PeriodicBookingsCompanion(')
          ..write('id: $id, ')
          ..write('nextExecutionDate: $nextExecutionDate, ')
          ..write('amount: $amount, ')
          ..write('accountId: $accountId, ')
          ..write('reason: $reason, ')
          ..write('notes: $notes, ')
          ..write('cycle: $cycle')
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
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
      'amount', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
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
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  late final GeneratedColumnWithTypeConverter<Cycles, String> cycle =
      GeneratedColumn<String>('cycle', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<Cycles>($PeriodicTransfersTable.$convertercycle);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        nextExecutionDate,
        amount,
        sendingAccountId,
        receivingAccountId,
        notes,
        cycle
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
    if (data.containsKey('amount')) {
      context.handle(_amountMeta,
          amount.isAcceptableOrUnknown(data['amount']!, _amountMeta));
    } else if (isInserting) {
      context.missing(_amountMeta);
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
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
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
      amount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}amount'])!,
      sendingAccountId: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}sending_account_id'])!,
      receivingAccountId: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}receiving_account_id'])!,
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
      cycle: $PeriodicTransfersTable.$convertercycle.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}cycle'])!),
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
  final double amount;
  final int sendingAccountId;
  final int receivingAccountId;
  final String? notes;
  final Cycles cycle;
  const PeriodicTransfer(
      {required this.id,
      required this.nextExecutionDate,
      required this.amount,
      required this.sendingAccountId,
      required this.receivingAccountId,
      this.notes,
      required this.cycle});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['next_execution_date'] = Variable<int>(nextExecutionDate);
    map['amount'] = Variable<double>(amount);
    map['sending_account_id'] = Variable<int>(sendingAccountId);
    map['receiving_account_id'] = Variable<int>(receivingAccountId);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    {
      map['cycle'] = Variable<String>(
          $PeriodicTransfersTable.$convertercycle.toSql(cycle));
    }
    return map;
  }

  PeriodicTransfersCompanion toCompanion(bool nullToAbsent) {
    return PeriodicTransfersCompanion(
      id: Value(id),
      nextExecutionDate: Value(nextExecutionDate),
      amount: Value(amount),
      sendingAccountId: Value(sendingAccountId),
      receivingAccountId: Value(receivingAccountId),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      cycle: Value(cycle),
    );
  }

  factory PeriodicTransfer.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PeriodicTransfer(
      id: serializer.fromJson<int>(json['id']),
      nextExecutionDate: serializer.fromJson<int>(json['nextExecutionDate']),
      amount: serializer.fromJson<double>(json['amount']),
      sendingAccountId: serializer.fromJson<int>(json['sendingAccountId']),
      receivingAccountId: serializer.fromJson<int>(json['receivingAccountId']),
      notes: serializer.fromJson<String?>(json['notes']),
      cycle: serializer.fromJson<Cycles>(json['cycle']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'nextExecutionDate': serializer.toJson<int>(nextExecutionDate),
      'amount': serializer.toJson<double>(amount),
      'sendingAccountId': serializer.toJson<int>(sendingAccountId),
      'receivingAccountId': serializer.toJson<int>(receivingAccountId),
      'notes': serializer.toJson<String?>(notes),
      'cycle': serializer.toJson<Cycles>(cycle),
    };
  }

  PeriodicTransfer copyWith(
          {int? id,
          int? nextExecutionDate,
          double? amount,
          int? sendingAccountId,
          int? receivingAccountId,
          Value<String?> notes = const Value.absent(),
          Cycles? cycle}) =>
      PeriodicTransfer(
        id: id ?? this.id,
        nextExecutionDate: nextExecutionDate ?? this.nextExecutionDate,
        amount: amount ?? this.amount,
        sendingAccountId: sendingAccountId ?? this.sendingAccountId,
        receivingAccountId: receivingAccountId ?? this.receivingAccountId,
        notes: notes.present ? notes.value : this.notes,
        cycle: cycle ?? this.cycle,
      );
  PeriodicTransfer copyWithCompanion(PeriodicTransfersCompanion data) {
    return PeriodicTransfer(
      id: data.id.present ? data.id.value : this.id,
      nextExecutionDate: data.nextExecutionDate.present
          ? data.nextExecutionDate.value
          : this.nextExecutionDate,
      amount: data.amount.present ? data.amount.value : this.amount,
      sendingAccountId: data.sendingAccountId.present
          ? data.sendingAccountId.value
          : this.sendingAccountId,
      receivingAccountId: data.receivingAccountId.present
          ? data.receivingAccountId.value
          : this.receivingAccountId,
      notes: data.notes.present ? data.notes.value : this.notes,
      cycle: data.cycle.present ? data.cycle.value : this.cycle,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PeriodicTransfer(')
          ..write('id: $id, ')
          ..write('nextExecutionDate: $nextExecutionDate, ')
          ..write('amount: $amount, ')
          ..write('sendingAccountId: $sendingAccountId, ')
          ..write('receivingAccountId: $receivingAccountId, ')
          ..write('notes: $notes, ')
          ..write('cycle: $cycle')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, nextExecutionDate, amount,
      sendingAccountId, receivingAccountId, notes, cycle);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PeriodicTransfer &&
          other.id == this.id &&
          other.nextExecutionDate == this.nextExecutionDate &&
          other.amount == this.amount &&
          other.sendingAccountId == this.sendingAccountId &&
          other.receivingAccountId == this.receivingAccountId &&
          other.notes == this.notes &&
          other.cycle == this.cycle);
}

class PeriodicTransfersCompanion extends UpdateCompanion<PeriodicTransfer> {
  final Value<int> id;
  final Value<int> nextExecutionDate;
  final Value<double> amount;
  final Value<int> sendingAccountId;
  final Value<int> receivingAccountId;
  final Value<String?> notes;
  final Value<Cycles> cycle;
  const PeriodicTransfersCompanion({
    this.id = const Value.absent(),
    this.nextExecutionDate = const Value.absent(),
    this.amount = const Value.absent(),
    this.sendingAccountId = const Value.absent(),
    this.receivingAccountId = const Value.absent(),
    this.notes = const Value.absent(),
    this.cycle = const Value.absent(),
  });
  PeriodicTransfersCompanion.insert({
    this.id = const Value.absent(),
    required int nextExecutionDate,
    required double amount,
    required int sendingAccountId,
    required int receivingAccountId,
    this.notes = const Value.absent(),
    required Cycles cycle,
  })  : nextExecutionDate = Value(nextExecutionDate),
        amount = Value(amount),
        sendingAccountId = Value(sendingAccountId),
        receivingAccountId = Value(receivingAccountId),
        cycle = Value(cycle);
  static Insertable<PeriodicTransfer> custom({
    Expression<int>? id,
    Expression<int>? nextExecutionDate,
    Expression<double>? amount,
    Expression<int>? sendingAccountId,
    Expression<int>? receivingAccountId,
    Expression<String>? notes,
    Expression<String>? cycle,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (nextExecutionDate != null) 'next_execution_date': nextExecutionDate,
      if (amount != null) 'amount': amount,
      if (sendingAccountId != null) 'sending_account_id': sendingAccountId,
      if (receivingAccountId != null)
        'receiving_account_id': receivingAccountId,
      if (notes != null) 'notes': notes,
      if (cycle != null) 'cycle': cycle,
    });
  }

  PeriodicTransfersCompanion copyWith(
      {Value<int>? id,
      Value<int>? nextExecutionDate,
      Value<double>? amount,
      Value<int>? sendingAccountId,
      Value<int>? receivingAccountId,
      Value<String?>? notes,
      Value<Cycles>? cycle}) {
    return PeriodicTransfersCompanion(
      id: id ?? this.id,
      nextExecutionDate: nextExecutionDate ?? this.nextExecutionDate,
      amount: amount ?? this.amount,
      sendingAccountId: sendingAccountId ?? this.sendingAccountId,
      receivingAccountId: receivingAccountId ?? this.receivingAccountId,
      notes: notes ?? this.notes,
      cycle: cycle ?? this.cycle,
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
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (sendingAccountId.present) {
      map['sending_account_id'] = Variable<int>(sendingAccountId.value);
    }
    if (receivingAccountId.present) {
      map['receiving_account_id'] = Variable<int>(receivingAccountId.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (cycle.present) {
      map['cycle'] = Variable<String>(
          $PeriodicTransfersTable.$convertercycle.toSql(cycle.value));
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PeriodicTransfersCompanion(')
          ..write('id: $id, ')
          ..write('nextExecutionDate: $nextExecutionDate, ')
          ..write('amount: $amount, ')
          ..write('sendingAccountId: $sendingAccountId, ')
          ..write('receivingAccountId: $receivingAccountId, ')
          ..write('notes: $notes, ')
          ..write('cycle: $cycle')
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
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _sharesOwnedMeta =
      const VerificationMeta('sharesOwned');
  @override
  late final GeneratedColumn<double> sharesOwned = GeneratedColumn<double>(
      'shares_owned', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _netBuyInMeta =
      const VerificationMeta('netBuyIn');
  @override
  late final GeneratedColumn<double> netBuyIn = GeneratedColumn<double>(
      'net_buy_in', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _brokerBuyInMeta =
      const VerificationMeta('brokerBuyIn');
  @override
  late final GeneratedColumn<double> brokerBuyIn = GeneratedColumn<double>(
      'broker_buy_in', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _buyFeeTotalMeta =
      const VerificationMeta('buyFeeTotal');
  @override
  late final GeneratedColumn<double> buyFeeTotal = GeneratedColumn<double>(
      'buy_fee_total', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        accountId,
        assetId,
        value,
        sharesOwned,
        netBuyIn,
        brokerBuyIn,
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
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('shares_owned')) {
      context.handle(
          _sharesOwnedMeta,
          sharesOwned.isAcceptableOrUnknown(
              data['shares_owned']!, _sharesOwnedMeta));
    } else if (isInserting) {
      context.missing(_sharesOwnedMeta);
    }
    if (data.containsKey('net_buy_in')) {
      context.handle(_netBuyInMeta,
          netBuyIn.isAcceptableOrUnknown(data['net_buy_in']!, _netBuyInMeta));
    } else if (isInserting) {
      context.missing(_netBuyInMeta);
    }
    if (data.containsKey('broker_buy_in')) {
      context.handle(
          _brokerBuyInMeta,
          brokerBuyIn.isAcceptableOrUnknown(
              data['broker_buy_in']!, _brokerBuyInMeta));
    } else if (isInserting) {
      context.missing(_brokerBuyInMeta);
    }
    if (data.containsKey('buy_fee_total')) {
      context.handle(
          _buyFeeTotalMeta,
          buyFeeTotal.isAcceptableOrUnknown(
              data['buy_fee_total']!, _buyFeeTotalMeta));
    } else if (isInserting) {
      context.missing(_buyFeeTotalMeta);
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
      sharesOwned: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}shares_owned'])!,
      netBuyIn: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}net_buy_in'])!,
      brokerBuyIn: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}broker_buy_in'])!,
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
  final double sharesOwned;
  final double netBuyIn;
  final double brokerBuyIn;
  final double buyFeeTotal;
  const AssetOnAccount(
      {required this.accountId,
      required this.assetId,
      required this.value,
      required this.sharesOwned,
      required this.netBuyIn,
      required this.brokerBuyIn,
      required this.buyFeeTotal});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['account_id'] = Variable<int>(accountId);
    map['asset_id'] = Variable<int>(assetId);
    map['value'] = Variable<double>(value);
    map['shares_owned'] = Variable<double>(sharesOwned);
    map['net_buy_in'] = Variable<double>(netBuyIn);
    map['broker_buy_in'] = Variable<double>(brokerBuyIn);
    map['buy_fee_total'] = Variable<double>(buyFeeTotal);
    return map;
  }

  AssetsOnAccountsCompanion toCompanion(bool nullToAbsent) {
    return AssetsOnAccountsCompanion(
      accountId: Value(accountId),
      assetId: Value(assetId),
      value: Value(value),
      sharesOwned: Value(sharesOwned),
      netBuyIn: Value(netBuyIn),
      brokerBuyIn: Value(brokerBuyIn),
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
      sharesOwned: serializer.fromJson<double>(json['sharesOwned']),
      netBuyIn: serializer.fromJson<double>(json['netBuyIn']),
      brokerBuyIn: serializer.fromJson<double>(json['brokerBuyIn']),
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
      'sharesOwned': serializer.toJson<double>(sharesOwned),
      'netBuyIn': serializer.toJson<double>(netBuyIn),
      'brokerBuyIn': serializer.toJson<double>(brokerBuyIn),
      'buyFeeTotal': serializer.toJson<double>(buyFeeTotal),
    };
  }

  AssetOnAccount copyWith(
          {int? accountId,
          int? assetId,
          double? value,
          double? sharesOwned,
          double? netBuyIn,
          double? brokerBuyIn,
          double? buyFeeTotal}) =>
      AssetOnAccount(
        accountId: accountId ?? this.accountId,
        assetId: assetId ?? this.assetId,
        value: value ?? this.value,
        sharesOwned: sharesOwned ?? this.sharesOwned,
        netBuyIn: netBuyIn ?? this.netBuyIn,
        brokerBuyIn: brokerBuyIn ?? this.brokerBuyIn,
        buyFeeTotal: buyFeeTotal ?? this.buyFeeTotal,
      );
  AssetOnAccount copyWithCompanion(AssetsOnAccountsCompanion data) {
    return AssetOnAccount(
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      assetId: data.assetId.present ? data.assetId.value : this.assetId,
      value: data.value.present ? data.value.value : this.value,
      sharesOwned:
          data.sharesOwned.present ? data.sharesOwned.value : this.sharesOwned,
      netBuyIn: data.netBuyIn.present ? data.netBuyIn.value : this.netBuyIn,
      brokerBuyIn:
          data.brokerBuyIn.present ? data.brokerBuyIn.value : this.brokerBuyIn,
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
          ..write('sharesOwned: $sharesOwned, ')
          ..write('netBuyIn: $netBuyIn, ')
          ..write('brokerBuyIn: $brokerBuyIn, ')
          ..write('buyFeeTotal: $buyFeeTotal')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(accountId, assetId, value, sharesOwned,
      netBuyIn, brokerBuyIn, buyFeeTotal);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AssetOnAccount &&
          other.accountId == this.accountId &&
          other.assetId == this.assetId &&
          other.value == this.value &&
          other.sharesOwned == this.sharesOwned &&
          other.netBuyIn == this.netBuyIn &&
          other.brokerBuyIn == this.brokerBuyIn &&
          other.buyFeeTotal == this.buyFeeTotal);
}

class AssetsOnAccountsCompanion extends UpdateCompanion<AssetOnAccount> {
  final Value<int> accountId;
  final Value<int> assetId;
  final Value<double> value;
  final Value<double> sharesOwned;
  final Value<double> netBuyIn;
  final Value<double> brokerBuyIn;
  final Value<double> buyFeeTotal;
  final Value<int> rowid;
  const AssetsOnAccountsCompanion({
    this.accountId = const Value.absent(),
    this.assetId = const Value.absent(),
    this.value = const Value.absent(),
    this.sharesOwned = const Value.absent(),
    this.netBuyIn = const Value.absent(),
    this.brokerBuyIn = const Value.absent(),
    this.buyFeeTotal = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AssetsOnAccountsCompanion.insert({
    required int accountId,
    required int assetId,
    required double value,
    required double sharesOwned,
    required double netBuyIn,
    required double brokerBuyIn,
    required double buyFeeTotal,
    this.rowid = const Value.absent(),
  })  : accountId = Value(accountId),
        assetId = Value(assetId),
        value = Value(value),
        sharesOwned = Value(sharesOwned),
        netBuyIn = Value(netBuyIn),
        brokerBuyIn = Value(brokerBuyIn),
        buyFeeTotal = Value(buyFeeTotal);
  static Insertable<AssetOnAccount> custom({
    Expression<int>? accountId,
    Expression<int>? assetId,
    Expression<double>? value,
    Expression<double>? sharesOwned,
    Expression<double>? netBuyIn,
    Expression<double>? brokerBuyIn,
    Expression<double>? buyFeeTotal,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (accountId != null) 'account_id': accountId,
      if (assetId != null) 'asset_id': assetId,
      if (value != null) 'value': value,
      if (sharesOwned != null) 'shares_owned': sharesOwned,
      if (netBuyIn != null) 'net_buy_in': netBuyIn,
      if (brokerBuyIn != null) 'broker_buy_in': brokerBuyIn,
      if (buyFeeTotal != null) 'buy_fee_total': buyFeeTotal,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AssetsOnAccountsCompanion copyWith(
      {Value<int>? accountId,
      Value<int>? assetId,
      Value<double>? value,
      Value<double>? sharesOwned,
      Value<double>? netBuyIn,
      Value<double>? brokerBuyIn,
      Value<double>? buyFeeTotal,
      Value<int>? rowid}) {
    return AssetsOnAccountsCompanion(
      accountId: accountId ?? this.accountId,
      assetId: assetId ?? this.assetId,
      value: value ?? this.value,
      sharesOwned: sharesOwned ?? this.sharesOwned,
      netBuyIn: netBuyIn ?? this.netBuyIn,
      brokerBuyIn: brokerBuyIn ?? this.brokerBuyIn,
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
    if (sharesOwned.present) {
      map['shares_owned'] = Variable<double>(sharesOwned.value);
    }
    if (netBuyIn.present) {
      map['net_buy_in'] = Variable<double>(netBuyIn.value);
    }
    if (brokerBuyIn.present) {
      map['broker_buy_in'] = Variable<double>(brokerBuyIn.value);
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
          ..write('sharesOwned: $sharesOwned, ')
          ..write('netBuyIn: $netBuyIn, ')
          ..write('brokerBuyIn: $brokerBuyIn, ')
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
  static const VerificationMeta _targetAmountMeta =
      const VerificationMeta('targetAmount');
  @override
  late final GeneratedColumn<double> targetAmount = GeneratedColumn<double>(
      'target_amount', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, accountId, createdOn, targetDate, targetAmount];
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
    if (data.containsKey('target_amount')) {
      context.handle(
          _targetAmountMeta,
          targetAmount.isAcceptableOrUnknown(
              data['target_amount']!, _targetAmountMeta));
    } else if (isInserting) {
      context.missing(_targetAmountMeta);
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
      accountId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}account_id']),
      createdOn: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_on'])!,
      targetDate: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}target_date'])!,
      targetAmount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}target_amount'])!,
    );
  }

  @override
  $GoalsTable createAlias(String alias) {
    return $GoalsTable(attachedDatabase, alias);
  }
}

class Goal extends DataClass implements Insertable<Goal> {
  final int id;
  final int? accountId;
  final int createdOn;
  final int targetDate;
  final double targetAmount;
  const Goal(
      {required this.id,
      this.accountId,
      required this.createdOn,
      required this.targetDate,
      required this.targetAmount});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || accountId != null) {
      map['account_id'] = Variable<int>(accountId);
    }
    map['created_on'] = Variable<int>(createdOn);
    map['target_date'] = Variable<int>(targetDate);
    map['target_amount'] = Variable<double>(targetAmount);
    return map;
  }

  GoalsCompanion toCompanion(bool nullToAbsent) {
    return GoalsCompanion(
      id: Value(id),
      accountId: accountId == null && nullToAbsent
          ? const Value.absent()
          : Value(accountId),
      createdOn: Value(createdOn),
      targetDate: Value(targetDate),
      targetAmount: Value(targetAmount),
    );
  }

  factory Goal.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Goal(
      id: serializer.fromJson<int>(json['id']),
      accountId: serializer.fromJson<int?>(json['accountId']),
      createdOn: serializer.fromJson<int>(json['createdOn']),
      targetDate: serializer.fromJson<int>(json['targetDate']),
      targetAmount: serializer.fromJson<double>(json['targetAmount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'accountId': serializer.toJson<int?>(accountId),
      'createdOn': serializer.toJson<int>(createdOn),
      'targetDate': serializer.toJson<int>(targetDate),
      'targetAmount': serializer.toJson<double>(targetAmount),
    };
  }

  Goal copyWith(
          {int? id,
          Value<int?> accountId = const Value.absent(),
          int? createdOn,
          int? targetDate,
          double? targetAmount}) =>
      Goal(
        id: id ?? this.id,
        accountId: accountId.present ? accountId.value : this.accountId,
        createdOn: createdOn ?? this.createdOn,
        targetDate: targetDate ?? this.targetDate,
        targetAmount: targetAmount ?? this.targetAmount,
      );
  Goal copyWithCompanion(GoalsCompanion data) {
    return Goal(
      id: data.id.present ? data.id.value : this.id,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      createdOn: data.createdOn.present ? data.createdOn.value : this.createdOn,
      targetDate:
          data.targetDate.present ? data.targetDate.value : this.targetDate,
      targetAmount: data.targetAmount.present
          ? data.targetAmount.value
          : this.targetAmount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Goal(')
          ..write('id: $id, ')
          ..write('accountId: $accountId, ')
          ..write('createdOn: $createdOn, ')
          ..write('targetDate: $targetDate, ')
          ..write('targetAmount: $targetAmount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, accountId, createdOn, targetDate, targetAmount);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Goal &&
          other.id == this.id &&
          other.accountId == this.accountId &&
          other.createdOn == this.createdOn &&
          other.targetDate == this.targetDate &&
          other.targetAmount == this.targetAmount);
}

class GoalsCompanion extends UpdateCompanion<Goal> {
  final Value<int> id;
  final Value<int?> accountId;
  final Value<int> createdOn;
  final Value<int> targetDate;
  final Value<double> targetAmount;
  const GoalsCompanion({
    this.id = const Value.absent(),
    this.accountId = const Value.absent(),
    this.createdOn = const Value.absent(),
    this.targetDate = const Value.absent(),
    this.targetAmount = const Value.absent(),
  });
  GoalsCompanion.insert({
    this.id = const Value.absent(),
    this.accountId = const Value.absent(),
    required int createdOn,
    required int targetDate,
    required double targetAmount,
  })  : createdOn = Value(createdOn),
        targetDate = Value(targetDate),
        targetAmount = Value(targetAmount);
  static Insertable<Goal> custom({
    Expression<int>? id,
    Expression<int>? accountId,
    Expression<int>? createdOn,
    Expression<int>? targetDate,
    Expression<double>? targetAmount,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (accountId != null) 'account_id': accountId,
      if (createdOn != null) 'created_on': createdOn,
      if (targetDate != null) 'target_date': targetDate,
      if (targetAmount != null) 'target_amount': targetAmount,
    });
  }

  GoalsCompanion copyWith(
      {Value<int>? id,
      Value<int?>? accountId,
      Value<int>? createdOn,
      Value<int>? targetDate,
      Value<double>? targetAmount}) {
    return GoalsCompanion(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      createdOn: createdOn ?? this.createdOn,
      targetDate: targetDate ?? this.targetDate,
      targetAmount: targetAmount ?? this.targetAmount,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
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
    if (targetAmount.present) {
      map['target_amount'] = Variable<double>(targetAmount.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GoalsCompanion(')
          ..write('id: $id, ')
          ..write('accountId: $accountId, ')
          ..write('createdOn: $createdOn, ')
          ..write('targetDate: $targetDate, ')
          ..write('targetAmount: $targetAmount')
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
  late final Index bookingsReasonDateAmount = Index(
      'bookings_reason_date_amount',
      'CREATE INDEX bookings_reason_date_amount ON bookings (reason, date, amount)');
  late final Index bookingsComplexQuery = Index('bookings_complex_query',
      'CREATE INDEX bookings_complex_query ON bookings (date, account_id, amount, exclude_from_average, is_generated)');
  late final Index transfersSendingAccountIdDate = Index(
      'transfers_sending_account_id_date',
      'CREATE INDEX transfers_sending_account_id_date ON transfers (sending_account_id, date)');
  late final Index transfersReceivingAccountIdDate = Index(
      'transfers_receiving_account_id_date',
      'CREATE INDEX transfers_receiving_account_id_date ON transfers (receiving_account_id, date)');
  late final Index transfersComplexQuery = Index('transfers_complex_query',
      'CREATE INDEX transfers_complex_query ON transfers (date, receiving_account_id, amount, is_generated)');
  late final Index tradesAssetIdDate = Index('trades_asset_id_date',
      'CREATE INDEX trades_asset_id_date ON trades (asset_id, date)');
  late final Index tradesClearingAccountIdDate = Index(
      'trades_clearing_account_id_date',
      'CREATE INDEX trades_clearing_account_id_date ON trades (clearing_account_id, date)');
  late final Index tradesPortfolioAccountIdDate = Index(
      'trades_portfolio_account_id_date',
      'CREATE INDEX trades_portfolio_account_id_date ON trades (portfolio_account_id, date)');
  late final Index periodicBookingsAccountId = Index(
      'periodic_bookings_account_id',
      'CREATE INDEX periodic_bookings_account_id ON periodic_bookings (account_id)');
  late final Index periodicBookingsNextExecutionDate = Index(
      'periodic_bookings_next_execution_date',
      'CREATE INDEX periodic_bookings_next_execution_date ON periodic_bookings (next_execution_date)');
  late final Index periodicTransfersSendingAccountId = Index(
      'periodic_transfers_sending_account_id',
      'CREATE INDEX periodic_transfers_sending_account_id ON periodic_transfers (sending_account_id)');
  late final Index periodicTransfersReceivingAccountId = Index(
      'periodic_transfers_receiving_account_id',
      'CREATE INDEX periodic_transfers_receiving_account_id ON periodic_transfers (receiving_account_id)');
  late final Index periodicTransfersNextExecutionDate = Index(
      'periodic_transfers_next_execution_date',
      'CREATE INDEX periodic_transfers_next_execution_date ON periodic_transfers (next_execution_date)');
  late final Index goalsAccountId = Index('goals_account_id',
      'CREATE INDEX goals_account_id ON goals (account_id)');
  late final Index goalsTargetDate = Index('goals_target_date',
      'CREATE INDEX goals_target_date ON goals (target_date)');
  late final AccountsDao accountsDao = AccountsDao(this as AppDatabase);
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
        bookingsReasonDateAmount,
        bookingsComplexQuery,
        transfersSendingAccountIdDate,
        transfersReceivingAccountIdDate,
        transfersComplexQuery,
        tradesAssetIdDate,
        tradesClearingAccountIdDate,
        tradesPortfolioAccountIdDate,
        periodicBookingsAccountId,
        periodicBookingsNextExecutionDate,
        periodicTransfersSendingAccountId,
        periodicTransfersReceivingAccountId,
        periodicTransfersNextExecutionDate,
        goalsAccountId,
        goalsTargetDate
      ];
}

typedef $$AccountsTableCreateCompanionBuilder = AccountsCompanion Function({
  Value<int> id,
  required String name,
  required double balance,
  required double initialBalance,
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

  static MultiTypedResultKey<$TradesTable, List<Trade>> _ClearingTradesTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.trades,
          aliasName: $_aliasNameGenerator(
              db.accounts.id, db.trades.clearingAccountId));

  $$TradesTableProcessedTableManager get ClearingTrades {
    final manager = $$TradesTableTableManager($_db, $_db.trades).filter(
        (f) => f.clearingAccountId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_ClearingTradesTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$TradesTable, List<Trade>> _PortfolioTradesTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.trades,
          aliasName: $_aliasNameGenerator(
              db.accounts.id, db.trades.portfolioAccountId));

  $$TradesTableProcessedTableManager get PortfolioTrades {
    final manager = $$TradesTableTableManager($_db, $_db.trades).filter(
        (f) => f.portfolioAccountId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_PortfolioTradesTable($_db));
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

  Expression<bool> ClearingTrades(
      Expression<bool> Function($$TradesTableFilterComposer f) f) {
    final $$TradesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.trades,
        getReferencedColumn: (t) => t.clearingAccountId,
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

  Expression<bool> PortfolioTrades(
      Expression<bool> Function($$TradesTableFilterComposer f) f) {
    final $$TradesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.trades,
        getReferencedColumn: (t) => t.portfolioAccountId,
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

  Expression<T> ClearingTrades<T extends Object>(
      Expression<T> Function($$TradesTableAnnotationComposer a) f) {
    final $$TradesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.trades,
        getReferencedColumn: (t) => t.clearingAccountId,
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

  Expression<T> PortfolioTrades<T extends Object>(
      Expression<T> Function($$TradesTableAnnotationComposer a) f) {
    final $$TradesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.trades,
        getReferencedColumn: (t) => t.portfolioAccountId,
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
        bool ClearingTrades,
        bool PortfolioTrades,
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
            required double balance,
            required double initialBalance,
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
              ClearingTrades = false,
              PortfolioTrades = false,
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
                if (ClearingTrades) db.trades,
                if (PortfolioTrades) db.trades,
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
                  if (ClearingTrades)
                    await $_getPrefetchedData<Account, $AccountsTable, Trade>(
                        currentTable: table,
                        referencedTable:
                            $$AccountsTableReferences._ClearingTradesTable(db),
                        managerFromTypedResult: (p0) =>
                            $$AccountsTableReferences(db, table, p0)
                                .ClearingTrades,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.clearingAccountId == item.id),
                        typedResults: items),
                  if (PortfolioTrades)
                    await $_getPrefetchedData<Account, $AccountsTable, Trade>(
                        currentTable: table,
                        referencedTable:
                            $$AccountsTableReferences._PortfolioTradesTable(db),
                        managerFromTypedResult: (p0) =>
                            $$AccountsTableReferences(db, table, p0)
                                .PortfolioTrades,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.portfolioAccountId == item.id),
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
        bool ClearingTrades,
        bool PortfolioTrades,
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
});
typedef $$AssetsTableUpdateCompanionBuilder = AssetsCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<AssetTypes> type,
  Value<String> tickerSymbol,
});

final class $$AssetsTableReferences
    extends BaseReferences<_$AppDatabase, $AssetsTable, Asset> {
  $$AssetsTableReferences(super.$_db, super.$_table, super.$_typedResult);

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
    PrefetchHooks Function({bool tradesRefs, bool assetsOnAccountsRefs})> {
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
          }) =>
              AssetsCompanion(
            id: id,
            name: name,
            type: type,
            tickerSymbol: tickerSymbol,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            required AssetTypes type,
            required String tickerSymbol,
          }) =>
              AssetsCompanion.insert(
            id: id,
            name: name,
            type: type,
            tickerSymbol: tickerSymbol,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$AssetsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: (
              {tradesRefs = false, assetsOnAccountsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (tradesRefs) db.trades,
                if (assetsOnAccountsRefs) db.assetsOnAccounts
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
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
    PrefetchHooks Function({bool tradesRefs, bool assetsOnAccountsRefs})>;
typedef $$BookingsTableCreateCompanionBuilder = BookingsCompanion Function({
  Value<int> id,
  required int date,
  required double amount,
  required String reason,
  required int accountId,
  Value<String?> notes,
  Value<bool> excludeFromAverage,
  required bool isGenerated,
});
typedef $$BookingsTableUpdateCompanionBuilder = BookingsCompanion Function({
  Value<int> id,
  Value<int> date,
  Value<double> amount,
  Value<String> reason,
  Value<int> accountId,
  Value<String?> notes,
  Value<bool> excludeFromAverage,
  Value<bool> isGenerated,
});

final class $$BookingsTableReferences
    extends BaseReferences<_$AppDatabase, $BookingsTable, Booking> {
  $$BookingsTableReferences(super.$_db, super.$_table, super.$_typedResult);

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

  ColumnFilters<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get reason => $composableBuilder(
      column: $table.reason, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get excludeFromAverage => $composableBuilder(
      column: $table.excludeFromAverage,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isGenerated => $composableBuilder(
      column: $table.isGenerated, builder: (column) => ColumnFilters(column));

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

  ColumnOrderings<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get reason => $composableBuilder(
      column: $table.reason, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get excludeFromAverage => $composableBuilder(
      column: $table.excludeFromAverage,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isGenerated => $composableBuilder(
      column: $table.isGenerated, builder: (column) => ColumnOrderings(column));

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

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<bool> get excludeFromAverage => $composableBuilder(
      column: $table.excludeFromAverage, builder: (column) => column);

  GeneratedColumn<bool> get isGenerated => $composableBuilder(
      column: $table.isGenerated, builder: (column) => column);

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
    PrefetchHooks Function({bool accountId})> {
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
            Value<double> amount = const Value.absent(),
            Value<String> reason = const Value.absent(),
            Value<int> accountId = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<bool> excludeFromAverage = const Value.absent(),
            Value<bool> isGenerated = const Value.absent(),
          }) =>
              BookingsCompanion(
            id: id,
            date: date,
            amount: amount,
            reason: reason,
            accountId: accountId,
            notes: notes,
            excludeFromAverage: excludeFromAverage,
            isGenerated: isGenerated,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int date,
            required double amount,
            required String reason,
            required int accountId,
            Value<String?> notes = const Value.absent(),
            Value<bool> excludeFromAverage = const Value.absent(),
            required bool isGenerated,
          }) =>
              BookingsCompanion.insert(
            id: id,
            date: date,
            amount: amount,
            reason: reason,
            accountId: accountId,
            notes: notes,
            excludeFromAverage: excludeFromAverage,
            isGenerated: isGenerated,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$BookingsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({accountId = false}) {
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
    PrefetchHooks Function({bool accountId})>;
typedef $$TransfersTableCreateCompanionBuilder = TransfersCompanion Function({
  Value<int> id,
  required int date,
  required double amount,
  required int sendingAccountId,
  required int receivingAccountId,
  Value<String?> notes,
  required bool isGenerated,
});
typedef $$TransfersTableUpdateCompanionBuilder = TransfersCompanion Function({
  Value<int> id,
  Value<int> date,
  Value<double> amount,
  Value<int> sendingAccountId,
  Value<int> receivingAccountId,
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

  ColumnFilters<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnFilters(column));

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

  ColumnOrderings<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnOrderings(column));

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

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

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
    PrefetchHooks Function({bool sendingAccountId, bool receivingAccountId})> {
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
            Value<double> amount = const Value.absent(),
            Value<int> sendingAccountId = const Value.absent(),
            Value<int> receivingAccountId = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<bool> isGenerated = const Value.absent(),
          }) =>
              TransfersCompanion(
            id: id,
            date: date,
            amount: amount,
            sendingAccountId: sendingAccountId,
            receivingAccountId: receivingAccountId,
            notes: notes,
            isGenerated: isGenerated,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int date,
            required double amount,
            required int sendingAccountId,
            required int receivingAccountId,
            Value<String?> notes = const Value.absent(),
            required bool isGenerated,
          }) =>
              TransfersCompanion.insert(
            id: id,
            date: date,
            amount: amount,
            sendingAccountId: sendingAccountId,
            receivingAccountId: receivingAccountId,
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
              {sendingAccountId = false, receivingAccountId = false}) {
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
    PrefetchHooks Function({bool sendingAccountId, bool receivingAccountId})>;
typedef $$TradesTableCreateCompanionBuilder = TradesCompanion Function({
  Value<int> id,
  required int date,
  required int assetId,
  required TradeTypes type,
  required double movedValue,
  required double shares,
  required double pricePerShare,
  required double profitAndLoss,
  required double tradingFee,
  required int clearingAccountId,
  required int portfolioAccountId,
});
typedef $$TradesTableUpdateCompanionBuilder = TradesCompanion Function({
  Value<int> id,
  Value<int> date,
  Value<int> assetId,
  Value<TradeTypes> type,
  Value<double> movedValue,
  Value<double> shares,
  Value<double> pricePerShare,
  Value<double> profitAndLoss,
  Value<double> tradingFee,
  Value<int> clearingAccountId,
  Value<int> portfolioAccountId,
});

final class $$TradesTableReferences
    extends BaseReferences<_$AppDatabase, $TradesTable, Trade> {
  $$TradesTableReferences(super.$_db, super.$_table, super.$_typedResult);

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

  static $AccountsTable _clearingAccountIdTable(_$AppDatabase db) =>
      db.accounts.createAlias(
          $_aliasNameGenerator(db.trades.clearingAccountId, db.accounts.id));

  $$AccountsTableProcessedTableManager get clearingAccountId {
    final $_column = $_itemColumn<int>('clearing_account_id')!;

    final manager = $$AccountsTableTableManager($_db, $_db.accounts)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_clearingAccountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $AccountsTable _portfolioAccountIdTable(_$AppDatabase db) =>
      db.accounts.createAlias(
          $_aliasNameGenerator(db.trades.portfolioAccountId, db.accounts.id));

  $$AccountsTableProcessedTableManager get portfolioAccountId {
    final $_column = $_itemColumn<int>('portfolio_account_id')!;

    final manager = $$AccountsTableTableManager($_db, $_db.accounts)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_portfolioAccountIdTable($_db));
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

  ColumnFilters<int> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<TradeTypes, TradeTypes, String> get type =>
      $composableBuilder(
          column: $table.type,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<double> get movedValue => $composableBuilder(
      column: $table.movedValue, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get shares => $composableBuilder(
      column: $table.shares, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get pricePerShare => $composableBuilder(
      column: $table.pricePerShare, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get profitAndLoss => $composableBuilder(
      column: $table.profitAndLoss, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get tradingFee => $composableBuilder(
      column: $table.tradingFee, builder: (column) => ColumnFilters(column));

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

  $$AccountsTableFilterComposer get clearingAccountId {
    final $$AccountsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.clearingAccountId,
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

  $$AccountsTableFilterComposer get portfolioAccountId {
    final $$AccountsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.portfolioAccountId,
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

  ColumnOrderings<int> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get movedValue => $composableBuilder(
      column: $table.movedValue, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get shares => $composableBuilder(
      column: $table.shares, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get pricePerShare => $composableBuilder(
      column: $table.pricePerShare,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get profitAndLoss => $composableBuilder(
      column: $table.profitAndLoss,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get tradingFee => $composableBuilder(
      column: $table.tradingFee, builder: (column) => ColumnOrderings(column));

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

  $$AccountsTableOrderingComposer get clearingAccountId {
    final $$AccountsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.clearingAccountId,
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

  $$AccountsTableOrderingComposer get portfolioAccountId {
    final $$AccountsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.portfolioAccountId,
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

  GeneratedColumn<int> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumnWithTypeConverter<TradeTypes, String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<double> get movedValue => $composableBuilder(
      column: $table.movedValue, builder: (column) => column);

  GeneratedColumn<double> get shares =>
      $composableBuilder(column: $table.shares, builder: (column) => column);

  GeneratedColumn<double> get pricePerShare => $composableBuilder(
      column: $table.pricePerShare, builder: (column) => column);

  GeneratedColumn<double> get profitAndLoss => $composableBuilder(
      column: $table.profitAndLoss, builder: (column) => column);

  GeneratedColumn<double> get tradingFee => $composableBuilder(
      column: $table.tradingFee, builder: (column) => column);

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

  $$AccountsTableAnnotationComposer get clearingAccountId {
    final $$AccountsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.clearingAccountId,
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

  $$AccountsTableAnnotationComposer get portfolioAccountId {
    final $$AccountsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.portfolioAccountId,
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
        {bool assetId, bool clearingAccountId, bool portfolioAccountId})> {
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
            Value<int> date = const Value.absent(),
            Value<int> assetId = const Value.absent(),
            Value<TradeTypes> type = const Value.absent(),
            Value<double> movedValue = const Value.absent(),
            Value<double> shares = const Value.absent(),
            Value<double> pricePerShare = const Value.absent(),
            Value<double> profitAndLoss = const Value.absent(),
            Value<double> tradingFee = const Value.absent(),
            Value<int> clearingAccountId = const Value.absent(),
            Value<int> portfolioAccountId = const Value.absent(),
          }) =>
              TradesCompanion(
            id: id,
            date: date,
            assetId: assetId,
            type: type,
            movedValue: movedValue,
            shares: shares,
            pricePerShare: pricePerShare,
            profitAndLoss: profitAndLoss,
            tradingFee: tradingFee,
            clearingAccountId: clearingAccountId,
            portfolioAccountId: portfolioAccountId,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int date,
            required int assetId,
            required TradeTypes type,
            required double movedValue,
            required double shares,
            required double pricePerShare,
            required double profitAndLoss,
            required double tradingFee,
            required int clearingAccountId,
            required int portfolioAccountId,
          }) =>
              TradesCompanion.insert(
            id: id,
            date: date,
            assetId: assetId,
            type: type,
            movedValue: movedValue,
            shares: shares,
            pricePerShare: pricePerShare,
            profitAndLoss: profitAndLoss,
            tradingFee: tradingFee,
            clearingAccountId: clearingAccountId,
            portfolioAccountId: portfolioAccountId,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$TradesTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: (
              {assetId = false,
              clearingAccountId = false,
              portfolioAccountId = false}) {
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
                    referencedTable: $$TradesTableReferences._assetIdTable(db),
                    referencedColumn:
                        $$TradesTableReferences._assetIdTable(db).id,
                  ) as T;
                }
                if (clearingAccountId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.clearingAccountId,
                    referencedTable:
                        $$TradesTableReferences._clearingAccountIdTable(db),
                    referencedColumn:
                        $$TradesTableReferences._clearingAccountIdTable(db).id,
                  ) as T;
                }
                if (portfolioAccountId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.portfolioAccountId,
                    referencedTable:
                        $$TradesTableReferences._portfolioAccountIdTable(db),
                    referencedColumn:
                        $$TradesTableReferences._portfolioAccountIdTable(db).id,
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
        {bool assetId, bool clearingAccountId, bool portfolioAccountId})>;
typedef $$PeriodicBookingsTableCreateCompanionBuilder
    = PeriodicBookingsCompanion Function({
  Value<int> id,
  required int nextExecutionDate,
  required double amount,
  required int accountId,
  required String reason,
  Value<String?> notes,
  required Cycles cycle,
});
typedef $$PeriodicBookingsTableUpdateCompanionBuilder
    = PeriodicBookingsCompanion Function({
  Value<int> id,
  Value<int> nextExecutionDate,
  Value<double> amount,
  Value<int> accountId,
  Value<String> reason,
  Value<String?> notes,
  Value<Cycles> cycle,
});

final class $$PeriodicBookingsTableReferences extends BaseReferences<
    _$AppDatabase, $PeriodicBookingsTable, PeriodicBooking> {
  $$PeriodicBookingsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

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

  ColumnFilters<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get reason => $composableBuilder(
      column: $table.reason, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<Cycles, Cycles, String> get cycle =>
      $composableBuilder(
          column: $table.cycle,
          builder: (column) => ColumnWithTypeConverterFilters(column));

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

  ColumnOrderings<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get reason => $composableBuilder(
      column: $table.reason, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get cycle => $composableBuilder(
      column: $table.cycle, builder: (column) => ColumnOrderings(column));

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

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Cycles, String> get cycle =>
      $composableBuilder(column: $table.cycle, builder: (column) => column);

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
    PrefetchHooks Function({bool accountId})> {
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
            Value<double> amount = const Value.absent(),
            Value<int> accountId = const Value.absent(),
            Value<String> reason = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<Cycles> cycle = const Value.absent(),
          }) =>
              PeriodicBookingsCompanion(
            id: id,
            nextExecutionDate: nextExecutionDate,
            amount: amount,
            accountId: accountId,
            reason: reason,
            notes: notes,
            cycle: cycle,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int nextExecutionDate,
            required double amount,
            required int accountId,
            required String reason,
            Value<String?> notes = const Value.absent(),
            required Cycles cycle,
          }) =>
              PeriodicBookingsCompanion.insert(
            id: id,
            nextExecutionDate: nextExecutionDate,
            amount: amount,
            accountId: accountId,
            reason: reason,
            notes: notes,
            cycle: cycle,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$PeriodicBookingsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({accountId = false}) {
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
    PrefetchHooks Function({bool accountId})>;
typedef $$PeriodicTransfersTableCreateCompanionBuilder
    = PeriodicTransfersCompanion Function({
  Value<int> id,
  required int nextExecutionDate,
  required double amount,
  required int sendingAccountId,
  required int receivingAccountId,
  Value<String?> notes,
  required Cycles cycle,
});
typedef $$PeriodicTransfersTableUpdateCompanionBuilder
    = PeriodicTransfersCompanion Function({
  Value<int> id,
  Value<int> nextExecutionDate,
  Value<double> amount,
  Value<int> sendingAccountId,
  Value<int> receivingAccountId,
  Value<String?> notes,
  Value<Cycles> cycle,
});

final class $$PeriodicTransfersTableReferences extends BaseReferences<
    _$AppDatabase, $PeriodicTransfersTable, PeriodicTransfer> {
  $$PeriodicTransfersTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

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

  ColumnFilters<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<Cycles, Cycles, String> get cycle =>
      $composableBuilder(
          column: $table.cycle,
          builder: (column) => ColumnWithTypeConverterFilters(column));

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

  ColumnOrderings<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get cycle => $composableBuilder(
      column: $table.cycle, builder: (column) => ColumnOrderings(column));

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

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Cycles, String> get cycle =>
      $composableBuilder(column: $table.cycle, builder: (column) => column);

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
    PrefetchHooks Function({bool sendingAccountId, bool receivingAccountId})> {
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
            Value<double> amount = const Value.absent(),
            Value<int> sendingAccountId = const Value.absent(),
            Value<int> receivingAccountId = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<Cycles> cycle = const Value.absent(),
          }) =>
              PeriodicTransfersCompanion(
            id: id,
            nextExecutionDate: nextExecutionDate,
            amount: amount,
            sendingAccountId: sendingAccountId,
            receivingAccountId: receivingAccountId,
            notes: notes,
            cycle: cycle,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int nextExecutionDate,
            required double amount,
            required int sendingAccountId,
            required int receivingAccountId,
            Value<String?> notes = const Value.absent(),
            required Cycles cycle,
          }) =>
              PeriodicTransfersCompanion.insert(
            id: id,
            nextExecutionDate: nextExecutionDate,
            amount: amount,
            sendingAccountId: sendingAccountId,
            receivingAccountId: receivingAccountId,
            notes: notes,
            cycle: cycle,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$PeriodicTransfersTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {sendingAccountId = false, receivingAccountId = false}) {
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
    PrefetchHooks Function({bool sendingAccountId, bool receivingAccountId})>;
typedef $$AssetsOnAccountsTableCreateCompanionBuilder
    = AssetsOnAccountsCompanion Function({
  required int accountId,
  required int assetId,
  required double value,
  required double sharesOwned,
  required double netBuyIn,
  required double brokerBuyIn,
  required double buyFeeTotal,
  Value<int> rowid,
});
typedef $$AssetsOnAccountsTableUpdateCompanionBuilder
    = AssetsOnAccountsCompanion Function({
  Value<int> accountId,
  Value<int> assetId,
  Value<double> value,
  Value<double> sharesOwned,
  Value<double> netBuyIn,
  Value<double> brokerBuyIn,
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

  ColumnFilters<double> get sharesOwned => $composableBuilder(
      column: $table.sharesOwned, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get netBuyIn => $composableBuilder(
      column: $table.netBuyIn, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get brokerBuyIn => $composableBuilder(
      column: $table.brokerBuyIn, builder: (column) => ColumnFilters(column));

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

  ColumnOrderings<double> get sharesOwned => $composableBuilder(
      column: $table.sharesOwned, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get netBuyIn => $composableBuilder(
      column: $table.netBuyIn, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get brokerBuyIn => $composableBuilder(
      column: $table.brokerBuyIn, builder: (column) => ColumnOrderings(column));

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

  GeneratedColumn<double> get sharesOwned => $composableBuilder(
      column: $table.sharesOwned, builder: (column) => column);

  GeneratedColumn<double> get netBuyIn =>
      $composableBuilder(column: $table.netBuyIn, builder: (column) => column);

  GeneratedColumn<double> get brokerBuyIn => $composableBuilder(
      column: $table.brokerBuyIn, builder: (column) => column);

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
            Value<double> sharesOwned = const Value.absent(),
            Value<double> netBuyIn = const Value.absent(),
            Value<double> brokerBuyIn = const Value.absent(),
            Value<double> buyFeeTotal = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AssetsOnAccountsCompanion(
            accountId: accountId,
            assetId: assetId,
            value: value,
            sharesOwned: sharesOwned,
            netBuyIn: netBuyIn,
            brokerBuyIn: brokerBuyIn,
            buyFeeTotal: buyFeeTotal,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required int accountId,
            required int assetId,
            required double value,
            required double sharesOwned,
            required double netBuyIn,
            required double brokerBuyIn,
            required double buyFeeTotal,
            Value<int> rowid = const Value.absent(),
          }) =>
              AssetsOnAccountsCompanion.insert(
            accountId: accountId,
            assetId: assetId,
            value: value,
            sharesOwned: sharesOwned,
            netBuyIn: netBuyIn,
            brokerBuyIn: brokerBuyIn,
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
  Value<int?> accountId,
  required int createdOn,
  required int targetDate,
  required double targetAmount,
});
typedef $$GoalsTableUpdateCompanionBuilder = GoalsCompanion Function({
  Value<int> id,
  Value<int?> accountId,
  Value<int> createdOn,
  Value<int> targetDate,
  Value<double> targetAmount,
});

final class $$GoalsTableReferences
    extends BaseReferences<_$AppDatabase, $GoalsTable, Goal> {
  $$GoalsTableReferences(super.$_db, super.$_table, super.$_typedResult);

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

  ColumnFilters<double> get targetAmount => $composableBuilder(
      column: $table.targetAmount, builder: (column) => ColumnFilters(column));

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

  ColumnOrderings<double> get targetAmount => $composableBuilder(
      column: $table.targetAmount,
      builder: (column) => ColumnOrderings(column));

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

  GeneratedColumn<double> get targetAmount => $composableBuilder(
      column: $table.targetAmount, builder: (column) => column);

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
    PrefetchHooks Function({bool accountId})> {
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
            Value<int?> accountId = const Value.absent(),
            Value<int> createdOn = const Value.absent(),
            Value<int> targetDate = const Value.absent(),
            Value<double> targetAmount = const Value.absent(),
          }) =>
              GoalsCompanion(
            id: id,
            accountId: accountId,
            createdOn: createdOn,
            targetDate: targetDate,
            targetAmount: targetAmount,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int?> accountId = const Value.absent(),
            required int createdOn,
            required int targetDate,
            required double targetAmount,
          }) =>
              GoalsCompanion.insert(
            id: id,
            accountId: accountId,
            createdOn: createdOn,
            targetDate: targetDate,
            targetAmount: targetAmount,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$GoalsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({accountId = false}) {
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
    PrefetchHooks Function({bool accountId})>;

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
