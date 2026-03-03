import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/filter/filter_config.dart';
import '../../models/filter/filter_rule.dart';
import '../../providers/theme_provider.dart';
import 'filter_value_inputs.dart';

/// Editor widget for creating/editing a single filter rule
class FilterRuleEditor extends StatefulWidget {
  final FilterConfig config;
  final FilterRule? existingRule;
  final ValueChanged<FilterRule> onSave;
  final VoidCallback onCancel;

  const FilterRuleEditor({
    super.key,
    required this.config,
    this.existingRule,
    required this.onSave,
    required this.onCancel,
  });

  @override
  State<FilterRuleEditor> createState() => _FilterRuleEditorState();
}

class _FilterRuleEditorState extends State<FilterRuleEditor> {
  FilterField? _selectedField;
  FilterOperator? _selectedOperator;
  dynamic _value;

  @override
  void initState() {
    super.initState();
    if (widget.existingRule != null) {
      _selectedField = widget.config.getField(widget.existingRule!.fieldId);
      _selectedOperator = widget.existingRule!.operator;
      _value = widget.existingRule!.value;
    }
  }

  bool get _canSave =>
      _selectedField != null && _selectedOperator != null && _value != null;

  void _save() {
    if (_canSave) {
      widget.onSave(FilterRule(
        fieldId: _selectedField!.id,
        operator: _selectedOperator!,
        value: _value,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = ThemeProvider.isDark();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Step 1: Select field
        Text(l10n.selectField, style: theme.textTheme.labelMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.config.fields.map((field) {
            final isSelected = _selectedField?.id == field.id;
            return ChoiceChip(
              label: Text(field.displayName),
              selected: isSelected,
              onSelected: (_) {
                setState(() {
                  _selectedField = field;
                  _value = null;
                  // Auto-select operator if only one available
                  if (field.availableOperators.length == 1) {
                    _selectedOperator = field.availableOperators.first;
                  } else {
                    _selectedOperator = null;
                  }
                });
              },
              selectedColor: isDark ? Colors.white24 : Colors.black12,
              checkmarkColor: isDark ? Colors.white : Colors.black,
            );
          }).toList(),
        ),

        // Step 2: Select operator (if field selected and multiple operators available)
        if (_selectedField != null &&
            _selectedField!.availableOperators.length > 1) ...[
          const SizedBox(height: 16),
          Text(l10n.selectOperator, style: theme.textTheme.labelMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selectedField!.availableOperators.map((op) {
              final isSelected = _selectedOperator == op;
              return ChoiceChip(
                label: Text(getOperatorDisplayName(op, l10n)),
                selected: isSelected,
                onSelected: (_) {
                  setState(() {
                    _selectedOperator = op;
                    _value = null;
                  });
                },
                selectedColor: isDark ? Colors.white24 : Colors.black12,
                checkmarkColor: isDark ? Colors.white : Colors.black,
              );
            }).toList(),
          ),
        ],

        // Step 3: Enter value (if operator selected)
        if (_selectedOperator != null) ...[
          const SizedBox(height: 16),
          Text(l10n.enterValue, style: theme.textTheme.labelMedium),
          const SizedBox(height: 8),
          _buildValueInput(l10n),
        ],

        // Action buttons
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: widget.onCancel,
              child: Text(l10n.cancel),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: _canSave ? _save : null,
              style: FilledButton.styleFrom(
                backgroundColor:
                    isDark ? const Color(0xFFFFFFFF) : const Color(0xFF000000),
                foregroundColor: isDark ? Colors.black : Colors.white,
                disabledBackgroundColor: isDark
                    ? Colors.white.withValues(alpha: 0.38)
                    : Colors.black.withValues(alpha: 0.38),
                disabledForegroundColor: isDark
                    ? Colors.black.withValues(alpha: 0.54)
                    : Colors.white.withValues(alpha: 0.54),
              ),
              child: Text(l10n.save),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildValueInput(AppLocalizations l10n) {
    if (_selectedField == null || _selectedOperator == null) {
      return const SizedBox.shrink();
    }

    switch (_selectedField!.type) {
      case FilterFieldType.numeric:
        if (_selectedOperator == FilterOperator.between) {
          final range = _value is List ? _value as List : null;
          return NumericRangeInput(
            minValue: range != null && range.isNotEmpty
                ? (range[0] as num).toDouble()
                : null,
            maxValue: range != null && range.length > 1
                ? (range[1] as num).toDouble()
                : null,
            l10n: l10n,
            onChanged: (val) => setState(() => _value = val),
          );
        }
        return NumericFilterInput(
          value: _value is double ? _value : null,
          onChanged: (val) => setState(() => _value = val),
        );

      case FilterFieldType.text:
        return TextFilterInput(
          value: _value is String ? _value : null,
          onChanged: (val) => setState(() => _value = val),
        );

      case FilterFieldType.dropdown:
        return DropdownFilterInput(
          selectedIds: _value is List ? (_value as List).cast<int>() : [],
          loadOptions: () =>
              widget.config.loadDropdownOptions?.call(_selectedField!.id) ??
              Future.value([]),
          onChanged: (ids) => setState(() => _value = ids),
        );

      case FilterFieldType.date:
        if (_selectedOperator == FilterOperator.dateBetween) {
          final range = _value is List ? _value as List : null;
          return DateRangeInput(
            startDate: range != null && range.isNotEmpty ? range[0] as int : null,
            endDate: range != null && range.length > 1 ? range[1] as int : null,
            l10n: l10n,
            onChanged: (val) => setState(() => _value = val),
          );
        }
        return DateFilterInput(
          dateInt: _value is int ? _value : null,
          onChanged: (val) => setState(() => _value = val),
        );
    }
  }
}
