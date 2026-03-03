import 'package:drift/drift.dart';
import '../models/filter/filter_rule.dart';
import 'app_database.dart';
import 'tables.dart';

// Helper functions for building filter expressions
Expression<bool>? buildNumericExpression(
    GeneratedColumn<double> col, FilterRule rule) {
  switch (rule.operator) {
    case FilterOperator.greaterThan:
      return col.isBiggerThanValue(rule.value as double);
    case FilterOperator.lessThan:
      return col.isSmallerThanValue(rule.value as double);
    case FilterOperator.greaterOrEqual:
      return col.isBiggerOrEqualValue(rule.value as double);
    case FilterOperator.lessOrEqual:
      return col.isSmallerOrEqualValue(rule.value as double);
    case FilterOperator.equals:
      return col.equals(rule.value as double);
    case FilterOperator.between:
      final range = rule.value as List;
      return col.isBetweenValues(
          (range[0] as num).toDouble(), (range[1] as num).toDouble());
    default:
      return null;
  }
}

Expression<bool>? buildTextExpression(
    GeneratedColumn<String> col, FilterRule rule) {
  final value = rule.value as String;
  switch (rule.operator) {
    case FilterOperator.contains:
      return col.lower().like('%${value.toLowerCase()}%');
    case FilterOperator.startsWith:
      return col.lower().like('${value.toLowerCase()}%');
    case FilterOperator.textEquals:
      return col.lower().equals(value.toLowerCase());
    default:
      return null;
  }
}

Expression<bool>? buildIntDropdownExpression(
    GeneratedColumn<int> col, FilterRule rule) {
  if (rule.operator == FilterOperator.inList) {
    final ids = (rule.value as List).cast<int>();
    if (ids.isEmpty) return null;
    if (ids.length == 1) return col.equals(ids.first);
    return col.isIn(ids);
  }
  return null;
}

Expression<bool>? buildDateExpression(
    GeneratedColumn<int> col, FilterRule rule) {
  switch (rule.operator) {
    case FilterOperator.before:
      return col.isSmallerThanValue(rule.value as int);
    case FilterOperator.after:
      return col.isBiggerThanValue(rule.value as int);
    case FilterOperator.dateBetween:
      final range = rule.value as List;
      return col.isBetweenValues(range[0] as int, range[1] as int);
    default:
      return null;
  }
}

// datetime is stored as YYYYMMDDHHMMSS, but filter uses YYYYMMDD
Expression<bool>? buildDatetimeExpression(
    GeneratedColumn<int> col, FilterRule rule) {
  switch (rule.operator) {
    case FilterOperator.before:
      return col.isSmallerThanValue((rule.value as int) * 1000000);
    case FilterOperator.after:
      return col.isBiggerOrEqualValue((rule.value as int) * 1000000 + 235959);
    case FilterOperator.dateBetween:
      final range = rule.value as List;
      return col.isBetweenValues(
          (range[0] as int) * 1000000, (range[1] as int) * 1000000 + 235959);
    default:
      return null;
  }
}

/// Builds Drift expressions from filter rules for Bookings table
class BookingFilterBuilder {
  final $BookingsTable bookings;

  BookingFilterBuilder(this.bookings);

  Expression<bool>? buildExpression(List<FilterRule> rules) {
    if (rules.isEmpty) return null;

    Expression<bool>? combined;
    for (final rule in rules) {
      final expr = _buildSingleExpression(rule);
      if (expr != null) {
        combined = combined == null ? expr : combined & expr;
      }
    }
    return combined;
  }

  Expression<bool>? _buildSingleExpression(FilterRule rule) {
    switch (rule.fieldId) {
      case 'value':
        return buildNumericExpression(bookings.value, rule);
      case 'shares':
        return buildNumericExpression(bookings.shares, rule);
      case 'category':
        return buildTextExpression(bookings.category, rule);
      case 'notes':
        return buildTextExpression(bookings.notes, rule);
      case 'assetId':
        return buildIntDropdownExpression(bookings.assetId, rule);
      case 'accountId':
        return buildIntDropdownExpression(bookings.accountId, rule);
      case 'date':
        return buildDateExpression(bookings.date, rule);
      default:
        return null;
    }
  }
}

/// Builds Drift expressions from filter rules for Transfers table
class TransferFilterBuilder {
  final $TransfersTable transfers;

  TransferFilterBuilder(this.transfers);

  Expression<bool>? buildExpression(List<FilterRule> rules) {
    if (rules.isEmpty) return null;

    Expression<bool>? combined;
    for (final rule in rules) {
      final expr = _buildSingleExpression(rule);
      if (expr != null) {
        combined = combined == null ? expr : combined & expr;
      }
    }
    return combined;
  }

  Expression<bool>? _buildSingleExpression(FilterRule rule) {
    switch (rule.fieldId) {
      case 'value':
        return buildNumericExpression(transfers.value, rule);
      case 'shares':
        return buildNumericExpression(transfers.shares, rule);
      case 'notes':
        return buildTextExpression(transfers.notes, rule);
      case 'assetId':
        return buildIntDropdownExpression(transfers.assetId, rule);
      case 'sendingAccountId':
        return buildIntDropdownExpression(transfers.sendingAccountId, rule);
      case 'receivingAccountId':
        return buildIntDropdownExpression(transfers.receivingAccountId, rule);
      case 'date':
        return buildDateExpression(transfers.date, rule);
      default:
        return null;
    }
  }
}

/// Builds Drift expressions from filter rules for Trades table
class TradeFilterBuilder {
  final $TradesTable trades;

  TradeFilterBuilder(this.trades);

  Expression<bool>? buildExpression(List<FilterRule> rules) {
    if (rules.isEmpty) return null;

    Expression<bool>? combined;
    for (final rule in rules) {
      final expr = _buildSingleExpression(rule);
      if (expr != null) {
        combined = combined == null ? expr : combined & expr;
      }
    }
    return combined;
  }

  Expression<bool>? _buildSingleExpression(FilterRule rule) {
    switch (rule.fieldId) {
      case 'type':
        return _buildTradeTypeExpression(rule);
      case 'shares':
        return buildNumericExpression(trades.shares, rule);
      case 'costBasis':
        return buildNumericExpression(trades.costBasis, rule);
      case 'fee':
        return buildNumericExpression(trades.fee, rule);
      case 'tax':
        return buildNumericExpression(trades.tax, rule);
      case 'profitAndLoss':
        return buildNumericExpression(trades.profitAndLoss, rule);
      case 'assetId':
        return buildIntDropdownExpression(trades.assetId, rule);
      case 'sourceAccountId':
        return buildIntDropdownExpression(trades.sourceAccountId, rule);
      case 'targetAccountId':
        return buildIntDropdownExpression(trades.targetAccountId, rule);
      case 'datetime':
        return buildDatetimeExpression(trades.datetime, rule);
      default:
        return null;
    }
  }

  Expression<bool>? _buildTradeTypeExpression(FilterRule rule) {
    if (rule.operator == FilterOperator.inList) {
      final indices = (rule.value as List).cast<int>();
      if (indices.isEmpty) return null;
      if (indices.length == 1) {
        return trades.type.equalsValue(TradeTypes.values[indices.first]);
      }
      // Build OR expression for multiple types
      Expression<bool>? combined;
      for (final index in indices) {
        final expr = trades.type.equalsValue(TradeTypes.values[index]);
        combined = combined == null ? expr : combined | expr;
      }
      return combined;
    }
    return null;
  }
}

/// Builds Drift expressions from filter rules for Assets table
class AssetFilterBuilder {
  final $AssetsTable assets;

  AssetFilterBuilder(this.assets);

  Expression<bool>? buildExpression(List<FilterRule> rules) {
    if (rules.isEmpty) return null;

    Expression<bool>? combined;
    for (final rule in rules) {
      final expr = _buildSingleExpression(rule);
      if (expr != null) {
        combined = combined == null ? expr : combined & expr;
      }
    }
    return combined;
  }

  Expression<bool>? _buildSingleExpression(FilterRule rule) {
    switch (rule.fieldId) {
      case 'name':
        return buildTextExpression(assets.name, rule);
      case 'tickerSymbol':
        return buildTextExpression(assets.tickerSymbol, rule);
      case 'value':
        return buildNumericExpression(assets.value, rule);
      case 'shares':
        return buildNumericExpression(assets.shares, rule);
      case 'type':
        return _buildAssetTypeExpression(rule);
      default:
        return null;
    }
  }

  Expression<bool>? _buildAssetTypeExpression(FilterRule rule) {
    if (rule.operator == FilterOperator.inList) {
      final indices = (rule.value as List).cast<int>();
      if (indices.isEmpty) return null;
      if (indices.length == 1) {
        return assets.type.equalsValue(AssetTypes.values[indices.first]);
      }
      // Build OR expression for multiple types
      Expression<bool>? combined;
      for (final index in indices) {
        final expr = assets.type.equalsValue(AssetTypes.values[index]);
        combined = combined == null ? expr : combined | expr;
      }
      return combined;
    }
    return null;
  }
}

/// Builds Drift expressions from filter rules for Accounts table
class AccountFilterBuilder {
  final $AccountsTable accounts;

  AccountFilterBuilder(this.accounts);

  Expression<bool>? buildExpression(List<FilterRule> rules) {
    if (rules.isEmpty) return null;

    Expression<bool>? combined;
    for (final rule in rules) {
      final expr = _buildSingleExpression(rule);
      if (expr != null) {
        combined = combined == null ? expr : combined & expr;
      }
    }
    return combined;
  }

  Expression<bool>? _buildSingleExpression(FilterRule rule) {
    switch (rule.fieldId) {
      case 'name':
        return buildTextExpression(accounts.name, rule);
      case 'balance':
        return buildNumericExpression(accounts.balance, rule);
      case 'type':
        return _buildAccountTypeExpression(rule);
      default:
        return null;
    }
  }

  Expression<bool>? _buildAccountTypeExpression(FilterRule rule) {
    if (rule.operator == FilterOperator.inList) {
      final indices = (rule.value as List).cast<int>();
      if (indices.isEmpty) return null;
      if (indices.length == 1) {
        return accounts.type.equalsValue(AccountTypes.values[indices.first]);
      }
      // Build OR expression for multiple types
      Expression<bool>? combined;
      for (final index in indices) {
        final expr = accounts.type.equalsValue(AccountTypes.values[index]);
        combined = combined == null ? expr : combined | expr;
      }
      return combined;
    }
    return null;
  }
}
