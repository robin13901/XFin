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
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _balanceMeta = const VerificationMeta(
    'balance',
  );
  @override
  late final GeneratedColumn<double> balance = GeneratedColumn<double>(
    'balance',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, balance];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'accounts';
  @override
  VerificationContext validateIntegrity(
    Insertable<Account> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('balance')) {
      context.handle(
        _balanceMeta,
        balance.isAcceptableOrUnknown(data['balance']!, _balanceMeta),
      );
    } else if (isInserting) {
      context.missing(_balanceMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Account map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Account(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      balance: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}balance'],
      )!,
    );
  }

  @override
  $AccountsTable createAlias(String alias) {
    return $AccountsTable(attachedDatabase, alias);
  }
}

class Account extends DataClass implements Insertable<Account> {
  final int id;
  final String name;
  final double balance;
  const Account({required this.id, required this.name, required this.balance});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['balance'] = Variable<double>(balance);
    return map;
  }

  AccountsCompanion toCompanion(bool nullToAbsent) {
    return AccountsCompanion(
      id: Value(id),
      name: Value(name),
      balance: Value(balance),
    );
  }

  factory Account.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Account(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      balance: serializer.fromJson<double>(json['balance']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'balance': serializer.toJson<double>(balance),
    };
  }

  Account copyWith({int? id, String? name, double? balance}) => Account(
    id: id ?? this.id,
    name: name ?? this.name,
    balance: balance ?? this.balance,
  );
  Account copyWithCompanion(AccountsCompanion data) {
    return Account(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      balance: data.balance.present ? data.balance.value : this.balance,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Account(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('balance: $balance')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, balance);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Account &&
          other.id == this.id &&
          other.name == this.name &&
          other.balance == this.balance);
}

class AccountsCompanion extends UpdateCompanion<Account> {
  final Value<int> id;
  final Value<String> name;
  final Value<double> balance;
  const AccountsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.balance = const Value.absent(),
  });
  AccountsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required double balance,
  }) : name = Value(name),
       balance = Value(balance);
  static Insertable<Account> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<double>? balance,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (balance != null) 'balance': balance,
    });
  }

  AccountsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<double>? balance,
  }) {
    return AccountsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      balance: balance ?? this.balance,
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
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AccountsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('balance: $balance')
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
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<int> date = GeneratedColumn<int>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
    'reason',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sendingAccountIdMeta = const VerificationMeta(
    'sendingAccountId',
  );
  @override
  late final GeneratedColumn<int> sendingAccountId = GeneratedColumn<int>(
    'sending_account_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _receivingAccountIdMeta =
      const VerificationMeta('receivingAccountId');
  @override
  late final GeneratedColumn<int> receivingAccountId = GeneratedColumn<int>(
    'receiving_account_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _excludeFromAverageMeta =
      const VerificationMeta('excludeFromAverage');
  @override
  late final GeneratedColumn<bool> excludeFromAverage = GeneratedColumn<bool>(
    'exclude_from_average',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("exclude_from_average" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdByStandingOrderMeta =
      const VerificationMeta('createdByStandingOrder');
  @override
  late final GeneratedColumn<bool> createdByStandingOrder =
      GeneratedColumn<bool>(
        'created_by_standing_order',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("created_by_standing_order" IN (0, 1))',
        ),
        defaultValue: const Constant(false),
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    date,
    amount,
    reason,
    sendingAccountId,
    receivingAccountId,
    notes,
    excludeFromAverage,
    createdByStandingOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'bookings';
  @override
  VerificationContext validateIntegrity(
    Insertable<Booking> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('reason')) {
      context.handle(
        _reasonMeta,
        reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta),
      );
    } else if (isInserting) {
      context.missing(_reasonMeta);
    }
    if (data.containsKey('sending_account_id')) {
      context.handle(
        _sendingAccountIdMeta,
        sendingAccountId.isAcceptableOrUnknown(
          data['sending_account_id']!,
          _sendingAccountIdMeta,
        ),
      );
    }
    if (data.containsKey('receiving_account_id')) {
      context.handle(
        _receivingAccountIdMeta,
        receivingAccountId.isAcceptableOrUnknown(
          data['receiving_account_id']!,
          _receivingAccountIdMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('exclude_from_average')) {
      context.handle(
        _excludeFromAverageMeta,
        excludeFromAverage.isAcceptableOrUnknown(
          data['exclude_from_average']!,
          _excludeFromAverageMeta,
        ),
      );
    }
    if (data.containsKey('created_by_standing_order')) {
      context.handle(
        _createdByStandingOrderMeta,
        createdByStandingOrder.isAcceptableOrUnknown(
          data['created_by_standing_order']!,
          _createdByStandingOrderMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Booking map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Booking(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}date'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}amount'],
      )!,
      reason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reason'],
      )!,
      sendingAccountId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sending_account_id'],
      ),
      receivingAccountId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}receiving_account_id'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      excludeFromAverage: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}exclude_from_average'],
      )!,
      createdByStandingOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}created_by_standing_order'],
      )!,
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
  final int? sendingAccountId;
  final int? receivingAccountId;
  final String? notes;
  final bool excludeFromAverage;
  final bool createdByStandingOrder;
  const Booking({
    required this.id,
    required this.date,
    required this.amount,
    required this.reason,
    this.sendingAccountId,
    this.receivingAccountId,
    this.notes,
    required this.excludeFromAverage,
    required this.createdByStandingOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['date'] = Variable<int>(date);
    map['amount'] = Variable<double>(amount);
    map['reason'] = Variable<String>(reason);
    if (!nullToAbsent || sendingAccountId != null) {
      map['sending_account_id'] = Variable<int>(sendingAccountId);
    }
    if (!nullToAbsent || receivingAccountId != null) {
      map['receiving_account_id'] = Variable<int>(receivingAccountId);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['exclude_from_average'] = Variable<bool>(excludeFromAverage);
    map['created_by_standing_order'] = Variable<bool>(createdByStandingOrder);
    return map;
  }

  BookingsCompanion toCompanion(bool nullToAbsent) {
    return BookingsCompanion(
      id: Value(id),
      date: Value(date),
      amount: Value(amount),
      reason: Value(reason),
      sendingAccountId: sendingAccountId == null && nullToAbsent
          ? const Value.absent()
          : Value(sendingAccountId),
      receivingAccountId: receivingAccountId == null && nullToAbsent
          ? const Value.absent()
          : Value(receivingAccountId),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      excludeFromAverage: Value(excludeFromAverage),
      createdByStandingOrder: Value(createdByStandingOrder),
    );
  }

  factory Booking.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Booking(
      id: serializer.fromJson<int>(json['id']),
      date: serializer.fromJson<int>(json['date']),
      amount: serializer.fromJson<double>(json['amount']),
      reason: serializer.fromJson<String>(json['reason']),
      sendingAccountId: serializer.fromJson<int?>(json['sendingAccountId']),
      receivingAccountId: serializer.fromJson<int?>(json['receivingAccountId']),
      notes: serializer.fromJson<String?>(json['notes']),
      excludeFromAverage: serializer.fromJson<bool>(json['excludeFromAverage']),
      createdByStandingOrder: serializer.fromJson<bool>(
        json['createdByStandingOrder'],
      ),
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
      'sendingAccountId': serializer.toJson<int?>(sendingAccountId),
      'receivingAccountId': serializer.toJson<int?>(receivingAccountId),
      'notes': serializer.toJson<String?>(notes),
      'excludeFromAverage': serializer.toJson<bool>(excludeFromAverage),
      'createdByStandingOrder': serializer.toJson<bool>(createdByStandingOrder),
    };
  }

  Booking copyWith({
    int? id,
    int? date,
    double? amount,
    String? reason,
    Value<int?> sendingAccountId = const Value.absent(),
    Value<int?> receivingAccountId = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    bool? excludeFromAverage,
    bool? createdByStandingOrder,
  }) => Booking(
    id: id ?? this.id,
    date: date ?? this.date,
    amount: amount ?? this.amount,
    reason: reason ?? this.reason,
    sendingAccountId: sendingAccountId.present
        ? sendingAccountId.value
        : this.sendingAccountId,
    receivingAccountId: receivingAccountId.present
        ? receivingAccountId.value
        : this.receivingAccountId,
    notes: notes.present ? notes.value : this.notes,
    excludeFromAverage: excludeFromAverage ?? this.excludeFromAverage,
    createdByStandingOrder:
        createdByStandingOrder ?? this.createdByStandingOrder,
  );
  Booking copyWithCompanion(BookingsCompanion data) {
    return Booking(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
      amount: data.amount.present ? data.amount.value : this.amount,
      reason: data.reason.present ? data.reason.value : this.reason,
      sendingAccountId: data.sendingAccountId.present
          ? data.sendingAccountId.value
          : this.sendingAccountId,
      receivingAccountId: data.receivingAccountId.present
          ? data.receivingAccountId.value
          : this.receivingAccountId,
      notes: data.notes.present ? data.notes.value : this.notes,
      excludeFromAverage: data.excludeFromAverage.present
          ? data.excludeFromAverage.value
          : this.excludeFromAverage,
      createdByStandingOrder: data.createdByStandingOrder.present
          ? data.createdByStandingOrder.value
          : this.createdByStandingOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Booking(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('amount: $amount, ')
          ..write('reason: $reason, ')
          ..write('sendingAccountId: $sendingAccountId, ')
          ..write('receivingAccountId: $receivingAccountId, ')
          ..write('notes: $notes, ')
          ..write('excludeFromAverage: $excludeFromAverage, ')
          ..write('createdByStandingOrder: $createdByStandingOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    date,
    amount,
    reason,
    sendingAccountId,
    receivingAccountId,
    notes,
    excludeFromAverage,
    createdByStandingOrder,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Booking &&
          other.id == this.id &&
          other.date == this.date &&
          other.amount == this.amount &&
          other.reason == this.reason &&
          other.sendingAccountId == this.sendingAccountId &&
          other.receivingAccountId == this.receivingAccountId &&
          other.notes == this.notes &&
          other.excludeFromAverage == this.excludeFromAverage &&
          other.createdByStandingOrder == this.createdByStandingOrder);
}

class BookingsCompanion extends UpdateCompanion<Booking> {
  final Value<int> id;
  final Value<int> date;
  final Value<double> amount;
  final Value<String> reason;
  final Value<int?> sendingAccountId;
  final Value<int?> receivingAccountId;
  final Value<String?> notes;
  final Value<bool> excludeFromAverage;
  final Value<bool> createdByStandingOrder;
  const BookingsCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.amount = const Value.absent(),
    this.reason = const Value.absent(),
    this.sendingAccountId = const Value.absent(),
    this.receivingAccountId = const Value.absent(),
    this.notes = const Value.absent(),
    this.excludeFromAverage = const Value.absent(),
    this.createdByStandingOrder = const Value.absent(),
  });
  BookingsCompanion.insert({
    this.id = const Value.absent(),
    required int date,
    required double amount,
    required String reason,
    this.sendingAccountId = const Value.absent(),
    this.receivingAccountId = const Value.absent(),
    this.notes = const Value.absent(),
    this.excludeFromAverage = const Value.absent(),
    this.createdByStandingOrder = const Value.absent(),
  }) : date = Value(date),
       amount = Value(amount),
       reason = Value(reason);
  static Insertable<Booking> custom({
    Expression<int>? id,
    Expression<int>? date,
    Expression<double>? amount,
    Expression<String>? reason,
    Expression<int>? sendingAccountId,
    Expression<int>? receivingAccountId,
    Expression<String>? notes,
    Expression<bool>? excludeFromAverage,
    Expression<bool>? createdByStandingOrder,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (amount != null) 'amount': amount,
      if (reason != null) 'reason': reason,
      if (sendingAccountId != null) 'sending_account_id': sendingAccountId,
      if (receivingAccountId != null)
        'receiving_account_id': receivingAccountId,
      if (notes != null) 'notes': notes,
      if (excludeFromAverage != null)
        'exclude_from_average': excludeFromAverage,
      if (createdByStandingOrder != null)
        'created_by_standing_order': createdByStandingOrder,
    });
  }

  BookingsCompanion copyWith({
    Value<int>? id,
    Value<int>? date,
    Value<double>? amount,
    Value<String>? reason,
    Value<int?>? sendingAccountId,
    Value<int?>? receivingAccountId,
    Value<String?>? notes,
    Value<bool>? excludeFromAverage,
    Value<bool>? createdByStandingOrder,
  }) {
    return BookingsCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      amount: amount ?? this.amount,
      reason: reason ?? this.reason,
      sendingAccountId: sendingAccountId ?? this.sendingAccountId,
      receivingAccountId: receivingAccountId ?? this.receivingAccountId,
      notes: notes ?? this.notes,
      excludeFromAverage: excludeFromAverage ?? this.excludeFromAverage,
      createdByStandingOrder:
          createdByStandingOrder ?? this.createdByStandingOrder,
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
    if (sendingAccountId.present) {
      map['sending_account_id'] = Variable<int>(sendingAccountId.value);
    }
    if (receivingAccountId.present) {
      map['receiving_account_id'] = Variable<int>(receivingAccountId.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (excludeFromAverage.present) {
      map['exclude_from_average'] = Variable<bool>(excludeFromAverage.value);
    }
    if (createdByStandingOrder.present) {
      map['created_by_standing_order'] = Variable<bool>(
        createdByStandingOrder.value,
      );
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
          ..write('sendingAccountId: $sendingAccountId, ')
          ..write('receivingAccountId: $receivingAccountId, ')
          ..write('notes: $notes, ')
          ..write('excludeFromAverage: $excludeFromAverage, ')
          ..write('createdByStandingOrder: $createdByStandingOrder')
          ..write(')'))
        .toString();
  }
}

class $StandingOrdersTable extends StandingOrders
    with TableInfo<$StandingOrdersTable, StandingOrder> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StandingOrdersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
    'reason',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sendingAccountIdMeta = const VerificationMeta(
    'sendingAccountId',
  );
  @override
  late final GeneratedColumn<int> sendingAccountId = GeneratedColumn<int>(
    'sending_account_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _receivingAccountIdMeta =
      const VerificationMeta('receivingAccountId');
  @override
  late final GeneratedColumn<int> receivingAccountId = GeneratedColumn<int>(
    'receiving_account_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nextExecutionDateMeta = const VerificationMeta(
    'nextExecutionDate',
  );
  @override
  late final GeneratedColumn<int> nextExecutionDate = GeneratedColumn<int>(
    'next_execution_date',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cycleFactorMeta = const VerificationMeta(
    'cycleFactor',
  );
  @override
  late final GeneratedColumn<double> cycleFactor = GeneratedColumn<double>(
    'cycle_factor',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    amount,
    reason,
    sendingAccountId,
    receivingAccountId,
    nextExecutionDate,
    cycleFactor,
    notes,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'standing_orders';
  @override
  VerificationContext validateIntegrity(
    Insertable<StandingOrder> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('reason')) {
      context.handle(
        _reasonMeta,
        reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta),
      );
    } else if (isInserting) {
      context.missing(_reasonMeta);
    }
    if (data.containsKey('sending_account_id')) {
      context.handle(
        _sendingAccountIdMeta,
        sendingAccountId.isAcceptableOrUnknown(
          data['sending_account_id']!,
          _sendingAccountIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sendingAccountIdMeta);
    }
    if (data.containsKey('receiving_account_id')) {
      context.handle(
        _receivingAccountIdMeta,
        receivingAccountId.isAcceptableOrUnknown(
          data['receiving_account_id']!,
          _receivingAccountIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_receivingAccountIdMeta);
    }
    if (data.containsKey('next_execution_date')) {
      context.handle(
        _nextExecutionDateMeta,
        nextExecutionDate.isAcceptableOrUnknown(
          data['next_execution_date']!,
          _nextExecutionDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_nextExecutionDateMeta);
    }
    if (data.containsKey('cycle_factor')) {
      context.handle(
        _cycleFactorMeta,
        cycleFactor.isAcceptableOrUnknown(
          data['cycle_factor']!,
          _cycleFactorMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_cycleFactorMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StandingOrder map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StandingOrder(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}amount'],
      )!,
      reason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reason'],
      )!,
      sendingAccountId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sending_account_id'],
      )!,
      receivingAccountId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}receiving_account_id'],
      )!,
      nextExecutionDate: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}next_execution_date'],
      )!,
      cycleFactor: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}cycle_factor'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
    );
  }

  @override
  $StandingOrdersTable createAlias(String alias) {
    return $StandingOrdersTable(attachedDatabase, alias);
  }
}

class StandingOrder extends DataClass implements Insertable<StandingOrder> {
  final int id;
  final double amount;
  final String reason;
  final int sendingAccountId;
  final int receivingAccountId;
  final int nextExecutionDate;
  final double cycleFactor;
  final String? notes;
  const StandingOrder({
    required this.id,
    required this.amount,
    required this.reason,
    required this.sendingAccountId,
    required this.receivingAccountId,
    required this.nextExecutionDate,
    required this.cycleFactor,
    this.notes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['amount'] = Variable<double>(amount);
    map['reason'] = Variable<String>(reason);
    map['sending_account_id'] = Variable<int>(sendingAccountId);
    map['receiving_account_id'] = Variable<int>(receivingAccountId);
    map['next_execution_date'] = Variable<int>(nextExecutionDate);
    map['cycle_factor'] = Variable<double>(cycleFactor);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    return map;
  }

  StandingOrdersCompanion toCompanion(bool nullToAbsent) {
    return StandingOrdersCompanion(
      id: Value(id),
      amount: Value(amount),
      reason: Value(reason),
      sendingAccountId: Value(sendingAccountId),
      receivingAccountId: Value(receivingAccountId),
      nextExecutionDate: Value(nextExecutionDate),
      cycleFactor: Value(cycleFactor),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
    );
  }

  factory StandingOrder.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StandingOrder(
      id: serializer.fromJson<int>(json['id']),
      amount: serializer.fromJson<double>(json['amount']),
      reason: serializer.fromJson<String>(json['reason']),
      sendingAccountId: serializer.fromJson<int>(json['sendingAccountId']),
      receivingAccountId: serializer.fromJson<int>(json['receivingAccountId']),
      nextExecutionDate: serializer.fromJson<int>(json['nextExecutionDate']),
      cycleFactor: serializer.fromJson<double>(json['cycleFactor']),
      notes: serializer.fromJson<String?>(json['notes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'amount': serializer.toJson<double>(amount),
      'reason': serializer.toJson<String>(reason),
      'sendingAccountId': serializer.toJson<int>(sendingAccountId),
      'receivingAccountId': serializer.toJson<int>(receivingAccountId),
      'nextExecutionDate': serializer.toJson<int>(nextExecutionDate),
      'cycleFactor': serializer.toJson<double>(cycleFactor),
      'notes': serializer.toJson<String?>(notes),
    };
  }

  StandingOrder copyWith({
    int? id,
    double? amount,
    String? reason,
    int? sendingAccountId,
    int? receivingAccountId,
    int? nextExecutionDate,
    double? cycleFactor,
    Value<String?> notes = const Value.absent(),
  }) => StandingOrder(
    id: id ?? this.id,
    amount: amount ?? this.amount,
    reason: reason ?? this.reason,
    sendingAccountId: sendingAccountId ?? this.sendingAccountId,
    receivingAccountId: receivingAccountId ?? this.receivingAccountId,
    nextExecutionDate: nextExecutionDate ?? this.nextExecutionDate,
    cycleFactor: cycleFactor ?? this.cycleFactor,
    notes: notes.present ? notes.value : this.notes,
  );
  StandingOrder copyWithCompanion(StandingOrdersCompanion data) {
    return StandingOrder(
      id: data.id.present ? data.id.value : this.id,
      amount: data.amount.present ? data.amount.value : this.amount,
      reason: data.reason.present ? data.reason.value : this.reason,
      sendingAccountId: data.sendingAccountId.present
          ? data.sendingAccountId.value
          : this.sendingAccountId,
      receivingAccountId: data.receivingAccountId.present
          ? data.receivingAccountId.value
          : this.receivingAccountId,
      nextExecutionDate: data.nextExecutionDate.present
          ? data.nextExecutionDate.value
          : this.nextExecutionDate,
      cycleFactor: data.cycleFactor.present
          ? data.cycleFactor.value
          : this.cycleFactor,
      notes: data.notes.present ? data.notes.value : this.notes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StandingOrder(')
          ..write('id: $id, ')
          ..write('amount: $amount, ')
          ..write('reason: $reason, ')
          ..write('sendingAccountId: $sendingAccountId, ')
          ..write('receivingAccountId: $receivingAccountId, ')
          ..write('nextExecutionDate: $nextExecutionDate, ')
          ..write('cycleFactor: $cycleFactor, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    amount,
    reason,
    sendingAccountId,
    receivingAccountId,
    nextExecutionDate,
    cycleFactor,
    notes,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StandingOrder &&
          other.id == this.id &&
          other.amount == this.amount &&
          other.reason == this.reason &&
          other.sendingAccountId == this.sendingAccountId &&
          other.receivingAccountId == this.receivingAccountId &&
          other.nextExecutionDate == this.nextExecutionDate &&
          other.cycleFactor == this.cycleFactor &&
          other.notes == this.notes);
}

class StandingOrdersCompanion extends UpdateCompanion<StandingOrder> {
  final Value<int> id;
  final Value<double> amount;
  final Value<String> reason;
  final Value<int> sendingAccountId;
  final Value<int> receivingAccountId;
  final Value<int> nextExecutionDate;
  final Value<double> cycleFactor;
  final Value<String?> notes;
  const StandingOrdersCompanion({
    this.id = const Value.absent(),
    this.amount = const Value.absent(),
    this.reason = const Value.absent(),
    this.sendingAccountId = const Value.absent(),
    this.receivingAccountId = const Value.absent(),
    this.nextExecutionDate = const Value.absent(),
    this.cycleFactor = const Value.absent(),
    this.notes = const Value.absent(),
  });
  StandingOrdersCompanion.insert({
    this.id = const Value.absent(),
    required double amount,
    required String reason,
    required int sendingAccountId,
    required int receivingAccountId,
    required int nextExecutionDate,
    required double cycleFactor,
    this.notes = const Value.absent(),
  }) : amount = Value(amount),
       reason = Value(reason),
       sendingAccountId = Value(sendingAccountId),
       receivingAccountId = Value(receivingAccountId),
       nextExecutionDate = Value(nextExecutionDate),
       cycleFactor = Value(cycleFactor);
  static Insertable<StandingOrder> custom({
    Expression<int>? id,
    Expression<double>? amount,
    Expression<String>? reason,
    Expression<int>? sendingAccountId,
    Expression<int>? receivingAccountId,
    Expression<int>? nextExecutionDate,
    Expression<double>? cycleFactor,
    Expression<String>? notes,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (amount != null) 'amount': amount,
      if (reason != null) 'reason': reason,
      if (sendingAccountId != null) 'sending_account_id': sendingAccountId,
      if (receivingAccountId != null)
        'receiving_account_id': receivingAccountId,
      if (nextExecutionDate != null) 'next_execution_date': nextExecutionDate,
      if (cycleFactor != null) 'cycle_factor': cycleFactor,
      if (notes != null) 'notes': notes,
    });
  }

  StandingOrdersCompanion copyWith({
    Value<int>? id,
    Value<double>? amount,
    Value<String>? reason,
    Value<int>? sendingAccountId,
    Value<int>? receivingAccountId,
    Value<int>? nextExecutionDate,
    Value<double>? cycleFactor,
    Value<String?>? notes,
  }) {
    return StandingOrdersCompanion(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      reason: reason ?? this.reason,
      sendingAccountId: sendingAccountId ?? this.sendingAccountId,
      receivingAccountId: receivingAccountId ?? this.receivingAccountId,
      nextExecutionDate: nextExecutionDate ?? this.nextExecutionDate,
      cycleFactor: cycleFactor ?? this.cycleFactor,
      notes: notes ?? this.notes,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (sendingAccountId.present) {
      map['sending_account_id'] = Variable<int>(sendingAccountId.value);
    }
    if (receivingAccountId.present) {
      map['receiving_account_id'] = Variable<int>(receivingAccountId.value);
    }
    if (nextExecutionDate.present) {
      map['next_execution_date'] = Variable<int>(nextExecutionDate.value);
    }
    if (cycleFactor.present) {
      map['cycle_factor'] = Variable<double>(cycleFactor.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StandingOrdersCompanion(')
          ..write('id: $id, ')
          ..write('amount: $amount, ')
          ..write('reason: $reason, ')
          ..write('sendingAccountId: $sendingAccountId, ')
          ..write('receivingAccountId: $receivingAccountId, ')
          ..write('nextExecutionDate: $nextExecutionDate, ')
          ..write('cycleFactor: $cycleFactor, ')
          ..write('notes: $notes')
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
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _createdOnMeta = const VerificationMeta(
    'createdOn',
  );
  @override
  late final GeneratedColumn<int> createdOn = GeneratedColumn<int>(
    'created_on',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetDateMeta = const VerificationMeta(
    'targetDate',
  );
  @override
  late final GeneratedColumn<int> targetDate = GeneratedColumn<int>(
    'target_date',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetAmountMeta = const VerificationMeta(
    'targetAmount',
  );
  @override
  late final GeneratedColumn<double> targetAmount = GeneratedColumn<double>(
    'target_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdOn,
    targetDate,
    targetAmount,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'goals';
  @override
  VerificationContext validateIntegrity(
    Insertable<Goal> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('created_on')) {
      context.handle(
        _createdOnMeta,
        createdOn.isAcceptableOrUnknown(data['created_on']!, _createdOnMeta),
      );
    } else if (isInserting) {
      context.missing(_createdOnMeta);
    }
    if (data.containsKey('target_date')) {
      context.handle(
        _targetDateMeta,
        targetDate.isAcceptableOrUnknown(data['target_date']!, _targetDateMeta),
      );
    } else if (isInserting) {
      context.missing(_targetDateMeta);
    }
    if (data.containsKey('target_amount')) {
      context.handle(
        _targetAmountMeta,
        targetAmount.isAcceptableOrUnknown(
          data['target_amount']!,
          _targetAmountMeta,
        ),
      );
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
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      createdOn: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_on'],
      )!,
      targetDate: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}target_date'],
      )!,
      targetAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}target_amount'],
      )!,
    );
  }

  @override
  $GoalsTable createAlias(String alias) {
    return $GoalsTable(attachedDatabase, alias);
  }
}

class Goal extends DataClass implements Insertable<Goal> {
  final int id;
  final int createdOn;
  final int targetDate;
  final double targetAmount;
  const Goal({
    required this.id,
    required this.createdOn,
    required this.targetDate,
    required this.targetAmount,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['created_on'] = Variable<int>(createdOn);
    map['target_date'] = Variable<int>(targetDate);
    map['target_amount'] = Variable<double>(targetAmount);
    return map;
  }

  GoalsCompanion toCompanion(bool nullToAbsent) {
    return GoalsCompanion(
      id: Value(id),
      createdOn: Value(createdOn),
      targetDate: Value(targetDate),
      targetAmount: Value(targetAmount),
    );
  }

  factory Goal.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Goal(
      id: serializer.fromJson<int>(json['id']),
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
      'createdOn': serializer.toJson<int>(createdOn),
      'targetDate': serializer.toJson<int>(targetDate),
      'targetAmount': serializer.toJson<double>(targetAmount),
    };
  }

  Goal copyWith({
    int? id,
    int? createdOn,
    int? targetDate,
    double? targetAmount,
  }) => Goal(
    id: id ?? this.id,
    createdOn: createdOn ?? this.createdOn,
    targetDate: targetDate ?? this.targetDate,
    targetAmount: targetAmount ?? this.targetAmount,
  );
  Goal copyWithCompanion(GoalsCompanion data) {
    return Goal(
      id: data.id.present ? data.id.value : this.id,
      createdOn: data.createdOn.present ? data.createdOn.value : this.createdOn,
      targetDate: data.targetDate.present
          ? data.targetDate.value
          : this.targetDate,
      targetAmount: data.targetAmount.present
          ? data.targetAmount.value
          : this.targetAmount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Goal(')
          ..write('id: $id, ')
          ..write('createdOn: $createdOn, ')
          ..write('targetDate: $targetDate, ')
          ..write('targetAmount: $targetAmount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, createdOn, targetDate, targetAmount);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Goal &&
          other.id == this.id &&
          other.createdOn == this.createdOn &&
          other.targetDate == this.targetDate &&
          other.targetAmount == this.targetAmount);
}

class GoalsCompanion extends UpdateCompanion<Goal> {
  final Value<int> id;
  final Value<int> createdOn;
  final Value<int> targetDate;
  final Value<double> targetAmount;
  const GoalsCompanion({
    this.id = const Value.absent(),
    this.createdOn = const Value.absent(),
    this.targetDate = const Value.absent(),
    this.targetAmount = const Value.absent(),
  });
  GoalsCompanion.insert({
    this.id = const Value.absent(),
    required int createdOn,
    required int targetDate,
    required double targetAmount,
  }) : createdOn = Value(createdOn),
       targetDate = Value(targetDate),
       targetAmount = Value(targetAmount);
  static Insertable<Goal> custom({
    Expression<int>? id,
    Expression<int>? createdOn,
    Expression<int>? targetDate,
    Expression<double>? targetAmount,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdOn != null) 'created_on': createdOn,
      if (targetDate != null) 'target_date': targetDate,
      if (targetAmount != null) 'target_amount': targetAmount,
    });
  }

  GoalsCompanion copyWith({
    Value<int>? id,
    Value<int>? createdOn,
    Value<int>? targetDate,
    Value<double>? targetAmount,
  }) {
    return GoalsCompanion(
      id: id ?? this.id,
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
  late final $BookingsTable bookings = $BookingsTable(this);
  late final $StandingOrdersTable standingOrders = $StandingOrdersTable(this);
  late final $GoalsTable goals = $GoalsTable(this);
  late final Index indexBookingsDateSendingAmountExcludeStanding = Index(
    'index_bookings_date_sending_amount_exclude_standing',
    'CREATE INDEX index_bookings_date_sending_amount_exclude_standing ON bookings (date, sending_account_id, amount, exclude_from_average, created_by_standing_order)',
  );
  late final Index indexBookingsDateReceivingAmountExcludeStanding = Index(
    'index_bookings_date_receiving_amount_exclude_standing',
    'CREATE INDEX index_bookings_date_receiving_amount_exclude_standing ON bookings (date, receiving_account_id, amount, exclude_from_average, created_by_standing_order)',
  );
  late final Index indexBookingsReasonDateAmount = Index(
    'index_bookings_reason_date_amount',
    'CREATE INDEX index_bookings_reason_date_amount ON bookings (reason, date, amount)',
  );
  late final Index indexBookingsDateSending = Index(
    'index_bookings_date_sending',
    'CREATE INDEX index_bookings_date_sending ON bookings (date, sending_account_id)',
  );
  late final Index indexBookingsDateReceiving = Index(
    'index_bookings_date_receiving',
    'CREATE INDEX index_bookings_date_receiving ON bookings (date, receiving_account_id)',
  );
  late final Index indexGoalsTargetDate = Index(
    'index_goals_targetDate',
    'CREATE INDEX index_goals_targetDate ON goals (target_date)',
  );
  late final BookingsDao bookingsDao = BookingsDao(this as AppDatabase);
  late final AccountsDao accountsDao = AccountsDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    accounts,
    bookings,
    standingOrders,
    goals,
    indexBookingsDateSendingAmountExcludeStanding,
    indexBookingsDateReceivingAmountExcludeStanding,
    indexBookingsReasonDateAmount,
    indexBookingsDateSending,
    indexBookingsDateReceiving,
    indexGoalsTargetDate,
  ];
}

typedef $$AccountsTableCreateCompanionBuilder =
    AccountsCompanion Function({
      Value<int> id,
      required String name,
      required double balance,
    });
typedef $$AccountsTableUpdateCompanionBuilder =
    AccountsCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<double> balance,
    });

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
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get balance => $composableBuilder(
    column: $table.balance,
    builder: (column) => ColumnFilters(column),
  );
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
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get balance => $composableBuilder(
    column: $table.balance,
    builder: (column) => ColumnOrderings(column),
  );
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
}

class $$AccountsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AccountsTable,
          Account,
          $$AccountsTableFilterComposer,
          $$AccountsTableOrderingComposer,
          $$AccountsTableAnnotationComposer,
          $$AccountsTableCreateCompanionBuilder,
          $$AccountsTableUpdateCompanionBuilder,
          (Account, BaseReferences<_$AppDatabase, $AccountsTable, Account>),
          Account,
          PrefetchHooks Function()
        > {
  $$AccountsTableTableManager(_$AppDatabase db, $AccountsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AccountsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AccountsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AccountsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<double> balance = const Value.absent(),
              }) => AccountsCompanion(id: id, name: name, balance: balance),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required double balance,
              }) => AccountsCompanion.insert(
                id: id,
                name: name,
                balance: balance,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AccountsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AccountsTable,
      Account,
      $$AccountsTableFilterComposer,
      $$AccountsTableOrderingComposer,
      $$AccountsTableAnnotationComposer,
      $$AccountsTableCreateCompanionBuilder,
      $$AccountsTableUpdateCompanionBuilder,
      (Account, BaseReferences<_$AppDatabase, $AccountsTable, Account>),
      Account,
      PrefetchHooks Function()
    >;
typedef $$BookingsTableCreateCompanionBuilder =
    BookingsCompanion Function({
      Value<int> id,
      required int date,
      required double amount,
      required String reason,
      Value<int?> sendingAccountId,
      Value<int?> receivingAccountId,
      Value<String?> notes,
      Value<bool> excludeFromAverage,
      Value<bool> createdByStandingOrder,
    });
typedef $$BookingsTableUpdateCompanionBuilder =
    BookingsCompanion Function({
      Value<int> id,
      Value<int> date,
      Value<double> amount,
      Value<String> reason,
      Value<int?> sendingAccountId,
      Value<int?> receivingAccountId,
      Value<String?> notes,
      Value<bool> excludeFromAverage,
      Value<bool> createdByStandingOrder,
    });

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
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sendingAccountId => $composableBuilder(
    column: $table.sendingAccountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get receivingAccountId => $composableBuilder(
    column: $table.receivingAccountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get excludeFromAverage => $composableBuilder(
    column: $table.excludeFromAverage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get createdByStandingOrder => $composableBuilder(
    column: $table.createdByStandingOrder,
    builder: (column) => ColumnFilters(column),
  );
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
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sendingAccountId => $composableBuilder(
    column: $table.sendingAccountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get receivingAccountId => $composableBuilder(
    column: $table.receivingAccountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get excludeFromAverage => $composableBuilder(
    column: $table.excludeFromAverage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get createdByStandingOrder => $composableBuilder(
    column: $table.createdByStandingOrder,
    builder: (column) => ColumnOrderings(column),
  );
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

  GeneratedColumn<int> get sendingAccountId => $composableBuilder(
    column: $table.sendingAccountId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get receivingAccountId => $composableBuilder(
    column: $table.receivingAccountId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<bool> get excludeFromAverage => $composableBuilder(
    column: $table.excludeFromAverage,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get createdByStandingOrder => $composableBuilder(
    column: $table.createdByStandingOrder,
    builder: (column) => column,
  );
}

class $$BookingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BookingsTable,
          Booking,
          $$BookingsTableFilterComposer,
          $$BookingsTableOrderingComposer,
          $$BookingsTableAnnotationComposer,
          $$BookingsTableCreateCompanionBuilder,
          $$BookingsTableUpdateCompanionBuilder,
          (Booking, BaseReferences<_$AppDatabase, $BookingsTable, Booking>),
          Booking,
          PrefetchHooks Function()
        > {
  $$BookingsTableTableManager(_$AppDatabase db, $BookingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BookingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BookingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BookingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> date = const Value.absent(),
                Value<double> amount = const Value.absent(),
                Value<String> reason = const Value.absent(),
                Value<int?> sendingAccountId = const Value.absent(),
                Value<int?> receivingAccountId = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<bool> excludeFromAverage = const Value.absent(),
                Value<bool> createdByStandingOrder = const Value.absent(),
              }) => BookingsCompanion(
                id: id,
                date: date,
                amount: amount,
                reason: reason,
                sendingAccountId: sendingAccountId,
                receivingAccountId: receivingAccountId,
                notes: notes,
                excludeFromAverage: excludeFromAverage,
                createdByStandingOrder: createdByStandingOrder,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int date,
                required double amount,
                required String reason,
                Value<int?> sendingAccountId = const Value.absent(),
                Value<int?> receivingAccountId = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<bool> excludeFromAverage = const Value.absent(),
                Value<bool> createdByStandingOrder = const Value.absent(),
              }) => BookingsCompanion.insert(
                id: id,
                date: date,
                amount: amount,
                reason: reason,
                sendingAccountId: sendingAccountId,
                receivingAccountId: receivingAccountId,
                notes: notes,
                excludeFromAverage: excludeFromAverage,
                createdByStandingOrder: createdByStandingOrder,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BookingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BookingsTable,
      Booking,
      $$BookingsTableFilterComposer,
      $$BookingsTableOrderingComposer,
      $$BookingsTableAnnotationComposer,
      $$BookingsTableCreateCompanionBuilder,
      $$BookingsTableUpdateCompanionBuilder,
      (Booking, BaseReferences<_$AppDatabase, $BookingsTable, Booking>),
      Booking,
      PrefetchHooks Function()
    >;
typedef $$StandingOrdersTableCreateCompanionBuilder =
    StandingOrdersCompanion Function({
      Value<int> id,
      required double amount,
      required String reason,
      required int sendingAccountId,
      required int receivingAccountId,
      required int nextExecutionDate,
      required double cycleFactor,
      Value<String?> notes,
    });
typedef $$StandingOrdersTableUpdateCompanionBuilder =
    StandingOrdersCompanion Function({
      Value<int> id,
      Value<double> amount,
      Value<String> reason,
      Value<int> sendingAccountId,
      Value<int> receivingAccountId,
      Value<int> nextExecutionDate,
      Value<double> cycleFactor,
      Value<String?> notes,
    });

class $$StandingOrdersTableFilterComposer
    extends Composer<_$AppDatabase, $StandingOrdersTable> {
  $$StandingOrdersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sendingAccountId => $composableBuilder(
    column: $table.sendingAccountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get receivingAccountId => $composableBuilder(
    column: $table.receivingAccountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get nextExecutionDate => $composableBuilder(
    column: $table.nextExecutionDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get cycleFactor => $composableBuilder(
    column: $table.cycleFactor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );
}

class $$StandingOrdersTableOrderingComposer
    extends Composer<_$AppDatabase, $StandingOrdersTable> {
  $$StandingOrdersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sendingAccountId => $composableBuilder(
    column: $table.sendingAccountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get receivingAccountId => $composableBuilder(
    column: $table.receivingAccountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get nextExecutionDate => $composableBuilder(
    column: $table.nextExecutionDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get cycleFactor => $composableBuilder(
    column: $table.cycleFactor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StandingOrdersTableAnnotationComposer
    extends Composer<_$AppDatabase, $StandingOrdersTable> {
  $$StandingOrdersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);

  GeneratedColumn<int> get sendingAccountId => $composableBuilder(
    column: $table.sendingAccountId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get receivingAccountId => $composableBuilder(
    column: $table.receivingAccountId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get nextExecutionDate => $composableBuilder(
    column: $table.nextExecutionDate,
    builder: (column) => column,
  );

  GeneratedColumn<double> get cycleFactor => $composableBuilder(
    column: $table.cycleFactor,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);
}

class $$StandingOrdersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StandingOrdersTable,
          StandingOrder,
          $$StandingOrdersTableFilterComposer,
          $$StandingOrdersTableOrderingComposer,
          $$StandingOrdersTableAnnotationComposer,
          $$StandingOrdersTableCreateCompanionBuilder,
          $$StandingOrdersTableUpdateCompanionBuilder,
          (
            StandingOrder,
            BaseReferences<_$AppDatabase, $StandingOrdersTable, StandingOrder>,
          ),
          StandingOrder,
          PrefetchHooks Function()
        > {
  $$StandingOrdersTableTableManager(
    _$AppDatabase db,
    $StandingOrdersTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StandingOrdersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StandingOrdersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StandingOrdersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<double> amount = const Value.absent(),
                Value<String> reason = const Value.absent(),
                Value<int> sendingAccountId = const Value.absent(),
                Value<int> receivingAccountId = const Value.absent(),
                Value<int> nextExecutionDate = const Value.absent(),
                Value<double> cycleFactor = const Value.absent(),
                Value<String?> notes = const Value.absent(),
              }) => StandingOrdersCompanion(
                id: id,
                amount: amount,
                reason: reason,
                sendingAccountId: sendingAccountId,
                receivingAccountId: receivingAccountId,
                nextExecutionDate: nextExecutionDate,
                cycleFactor: cycleFactor,
                notes: notes,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required double amount,
                required String reason,
                required int sendingAccountId,
                required int receivingAccountId,
                required int nextExecutionDate,
                required double cycleFactor,
                Value<String?> notes = const Value.absent(),
              }) => StandingOrdersCompanion.insert(
                id: id,
                amount: amount,
                reason: reason,
                sendingAccountId: sendingAccountId,
                receivingAccountId: receivingAccountId,
                nextExecutionDate: nextExecutionDate,
                cycleFactor: cycleFactor,
                notes: notes,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$StandingOrdersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StandingOrdersTable,
      StandingOrder,
      $$StandingOrdersTableFilterComposer,
      $$StandingOrdersTableOrderingComposer,
      $$StandingOrdersTableAnnotationComposer,
      $$StandingOrdersTableCreateCompanionBuilder,
      $$StandingOrdersTableUpdateCompanionBuilder,
      (
        StandingOrder,
        BaseReferences<_$AppDatabase, $StandingOrdersTable, StandingOrder>,
      ),
      StandingOrder,
      PrefetchHooks Function()
    >;
typedef $$GoalsTableCreateCompanionBuilder =
    GoalsCompanion Function({
      Value<int> id,
      required int createdOn,
      required int targetDate,
      required double targetAmount,
    });
typedef $$GoalsTableUpdateCompanionBuilder =
    GoalsCompanion Function({
      Value<int> id,
      Value<int> createdOn,
      Value<int> targetDate,
      Value<double> targetAmount,
    });

class $$GoalsTableFilterComposer extends Composer<_$AppDatabase, $GoalsTable> {
  $$GoalsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdOn => $composableBuilder(
    column: $table.createdOn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get targetDate => $composableBuilder(
    column: $table.targetDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get targetAmount => $composableBuilder(
    column: $table.targetAmount,
    builder: (column) => ColumnFilters(column),
  );
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
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdOn => $composableBuilder(
    column: $table.createdOn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get targetDate => $composableBuilder(
    column: $table.targetDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get targetAmount => $composableBuilder(
    column: $table.targetAmount,
    builder: (column) => ColumnOrderings(column),
  );
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
    column: $table.targetDate,
    builder: (column) => column,
  );

  GeneratedColumn<double> get targetAmount => $composableBuilder(
    column: $table.targetAmount,
    builder: (column) => column,
  );
}

class $$GoalsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GoalsTable,
          Goal,
          $$GoalsTableFilterComposer,
          $$GoalsTableOrderingComposer,
          $$GoalsTableAnnotationComposer,
          $$GoalsTableCreateCompanionBuilder,
          $$GoalsTableUpdateCompanionBuilder,
          (Goal, BaseReferences<_$AppDatabase, $GoalsTable, Goal>),
          Goal,
          PrefetchHooks Function()
        > {
  $$GoalsTableTableManager(_$AppDatabase db, $GoalsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GoalsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GoalsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GoalsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> createdOn = const Value.absent(),
                Value<int> targetDate = const Value.absent(),
                Value<double> targetAmount = const Value.absent(),
              }) => GoalsCompanion(
                id: id,
                createdOn: createdOn,
                targetDate: targetDate,
                targetAmount: targetAmount,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int createdOn,
                required int targetDate,
                required double targetAmount,
              }) => GoalsCompanion.insert(
                id: id,
                createdOn: createdOn,
                targetDate: targetDate,
                targetAmount: targetAmount,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$GoalsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GoalsTable,
      Goal,
      $$GoalsTableFilterComposer,
      $$GoalsTableOrderingComposer,
      $$GoalsTableAnnotationComposer,
      $$GoalsTableCreateCompanionBuilder,
      $$GoalsTableUpdateCompanionBuilder,
      (Goal, BaseReferences<_$AppDatabase, $GoalsTable, Goal>),
      Goal,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$AccountsTableTableManager get accounts =>
      $$AccountsTableTableManager(_db, _db.accounts);
  $$BookingsTableTableManager get bookings =>
      $$BookingsTableTableManager(_db, _db.bookings);
  $$StandingOrdersTableTableManager get standingOrders =>
      $$StandingOrdersTableTableManager(_db, _db.standingOrders);
  $$GoalsTableTableManager get goals =>
      $$GoalsTableTableManager(_db, _db.goals);
}
