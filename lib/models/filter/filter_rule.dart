/// Filter operators for different field types
enum FilterOperator {
  // Numeric operators
  greaterThan,
  lessThan,
  greaterOrEqual,
  lessOrEqual,
  equals,
  between,

  // Text operators
  contains,
  startsWith,
  textEquals,

  // Selection operators
  inList,

  // Date operators
  before,
  after,
  dateBetween,
}

/// Field types that determine available operators
enum FilterFieldType {
  numeric,
  text,
  dropdown,
  date,
}

/// Definition of a filterable field
class FilterField {
  final String id;
  final String displayName;
  final FilterFieldType type;

  const FilterField({
    required this.id,
    required this.displayName,
    required this.type,
  });

  /// Returns available operators for this field type
  List<FilterOperator> get availableOperators {
    switch (type) {
      case FilterFieldType.numeric:
        return [
          FilterOperator.greaterThan,
          FilterOperator.lessThan,
          FilterOperator.greaterOrEqual,
          FilterOperator.lessOrEqual,
          FilterOperator.equals,
          FilterOperator.between,
        ];
      case FilterFieldType.text:
        return [
          FilterOperator.contains,
          FilterOperator.startsWith,
          FilterOperator.textEquals,
        ];
      case FilterFieldType.dropdown:
        return [FilterOperator.inList];
      case FilterFieldType.date:
        return [
          FilterOperator.before,
          FilterOperator.after,
          FilterOperator.dateBetween,
        ];
    }
  }
}

/// A single filter rule
class FilterRule {
  final String fieldId;
  final FilterOperator operator;
  final dynamic value; // Single value, List for 'between'/'inList', int for date

  const FilterRule({
    required this.fieldId,
    required this.operator,
    required this.value,
  });

  /// Whether this operator requires a range (two values)
  bool get isRangeOperator =>
      operator == FilterOperator.between ||
      operator == FilterOperator.dateBetween;

  FilterRule copyWith({
    String? fieldId,
    FilterOperator? operator,
    dynamic value,
  }) {
    return FilterRule(
      fieldId: fieldId ?? this.fieldId,
      operator: operator ?? this.operator,
      value: value ?? this.value,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FilterRule &&
          runtimeType == other.runtimeType &&
          fieldId == other.fieldId &&
          operator == other.operator &&
          _valueEquals(value, other.value);

  bool _valueEquals(dynamic a, dynamic b) {
    if (a is List && b is List) {
      if (a.length != b.length) return false;
      for (int i = 0; i < a.length; i++) {
        if (a[i] != b[i]) return false;
      }
      return true;
    }
    return a == b;
  }

  @override
  int get hashCode => Object.hash(fieldId, operator, value.hashCode);
}
