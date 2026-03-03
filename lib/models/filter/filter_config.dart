import 'filter_rule.dart';

/// Option for dropdown filter fields
class DropdownOption {
  final int id;
  final String displayName;

  const DropdownOption({required this.id, required this.displayName});
}

/// Callback type for loading dropdown options
typedef DropdownOptionsLoader = Future<List<DropdownOption>> Function(
    String fieldId);

/// Configuration for entity-specific filter fields
class FilterConfig {
  final String title;
  final List<FilterField> fields;
  final DropdownOptionsLoader? loadDropdownOptions;

  const FilterConfig({
    required this.title,
    required this.fields,
    this.loadDropdownOptions,
  });

  /// Get field by id
  FilterField? getField(String id) {
    for (final field in fields) {
      if (field.id == id) return field;
    }
    return null;
  }

  /// Get all fields of a specific type
  List<FilterField> getFieldsByType(FilterFieldType type) {
    return fields.where((f) => f.type == type).toList();
  }
}
