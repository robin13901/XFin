import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/filter/filter_config.dart';
import '../../models/filter/filter_rule.dart';
import '../../providers/theme_provider.dart';
import '../../utils/format.dart';

/// Input widget for numeric filter values
class NumericFilterInput extends StatefulWidget {
  final double? value;
  final ValueChanged<double?> onChanged;
  final String? label;

  const NumericFilterInput({
    super.key,
    this.value,
    required this.onChanged,
    this.label,
  });

  @override
  State<NumericFilterInput> createState() => _NumericFilterInputState();
}

class _NumericFilterInputState extends State<NumericFilterInput> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value?.toString() ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
      decoration: InputDecoration(
        labelText: widget.label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      onChanged: (text) {
        final parsed = double.tryParse(text);
        widget.onChanged(parsed);
      },
    );
  }
}

/// Input widget for numeric range (between operator)
class NumericRangeInput extends StatelessWidget {
  final double? minValue;
  final double? maxValue;
  final ValueChanged<List<double>?> onChanged;
  final AppLocalizations l10n;

  const NumericRangeInput({
    super.key,
    this.minValue,
    this.maxValue,
    required this.onChanged,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    double? currentMin = minValue;
    double? currentMax = maxValue;

    return Row(
      children: [
        Expanded(
          child: NumericFilterInput(
            value: minValue,
            label: l10n.from,
            onChanged: (val) {
              currentMin = val;
              if (currentMin != null && currentMax != null) {
                onChanged([currentMin!, currentMax!]);
              }
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: NumericFilterInput(
            value: maxValue,
            label: l10n.to,
            onChanged: (val) {
              currentMax = val;
              if (currentMin != null && currentMax != null) {
                onChanged([currentMin!, currentMax!]);
              }
            },
          ),
        ),
      ],
    );
  }
}

/// Input widget for text filter values
class TextFilterInput extends StatefulWidget {
  final String? value;
  final ValueChanged<String> onChanged;
  final String? label;

  const TextFilterInput({
    super.key,
    this.value,
    required this.onChanged,
    this.label,
  });

  @override
  State<TextFilterInput> createState() => _TextFilterInputState();
}

class _TextFilterInputState extends State<TextFilterInput> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      textCapitalization: TextCapitalization.words,
      decoration: InputDecoration(
        labelText: widget.label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      onChanged: widget.onChanged,
    );
  }
}

/// Input widget for dropdown filter values (single or multi-select)
class DropdownFilterInput extends StatefulWidget {
  final List<int> selectedIds;
  final Future<List<DropdownOption>> Function() loadOptions;
  final ValueChanged<List<int>> onChanged;

  const DropdownFilterInput({
    super.key,
    required this.selectedIds,
    required this.loadOptions,
    required this.onChanged,
  });

  @override
  State<DropdownFilterInput> createState() => _DropdownFilterInputState();
}

class _DropdownFilterInputState extends State<DropdownFilterInput> {
  List<DropdownOption>? _options;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  Future<void> _loadOptions() async {
    final options = await widget.loadOptions();
    if (mounted) {
      setState(() {
        _options = options;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final options = _options ?? [];
    final isDark = ThemeProvider.isDark();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final isSelected = widget.selectedIds.contains(option.id);
        return FilterChip(
          label: Text(option.displayName),
          selected: isSelected,
          onSelected: (selected) {
            final newIds = List<int>.from(widget.selectedIds);
            if (selected) {
              newIds.add(option.id);
            } else {
              newIds.remove(option.id);
            }
            widget.onChanged(newIds);
          },
          selectedColor: isDark ? Colors.white24 : Colors.black12,
          checkmarkColor: isDark ? Colors.white : Colors.black,
        );
      }).toList(),
    );
  }
}

/// Input widget for date filter values
class DateFilterInput extends StatelessWidget {
  final int? dateInt; // YYYYMMDD format
  final ValueChanged<int?> onChanged;
  final String? label;

  const DateFilterInput({
    super.key,
    this.dateInt,
    required this.onChanged,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final date = dateInt != null ? intToDateTime(dateInt!) : null;
    final displayText = date != null ? dateFormat.format(date) : '';

    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (picked != null) {
          final intValue = picked.year * 10000 + picked.month * 100 + picked.day;
          onChanged(intValue);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          suffixIcon: const Icon(Icons.calendar_today, size: 18),
        ),
        child: Text(
          displayText.isEmpty ? '—' : displayText,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}

/// Input widget for date range (between operator)
class DateRangeInput extends StatelessWidget {
  final int? startDate;
  final int? endDate;
  final ValueChanged<List<int>?> onChanged;
  final AppLocalizations l10n;

  const DateRangeInput({
    super.key,
    this.startDate,
    this.endDate,
    required this.onChanged,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    int? currentStart = startDate;
    int? currentEnd = endDate;

    return Row(
      children: [
        Expanded(
          child: DateFilterInput(
            dateInt: startDate,
            label: l10n.from,
            onChanged: (val) {
              currentStart = val;
              if (currentStart != null && currentEnd != null) {
                onChanged([currentStart!, currentEnd!]);
              }
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: DateFilterInput(
            dateInt: endDate,
            label: l10n.to,
            onChanged: (val) {
              currentEnd = val;
              if (currentStart != null && currentEnd != null) {
                onChanged([currentStart!, currentEnd!]);
              }
            },
          ),
        ),
      ],
    );
  }
}

/// Helper to get user-friendly operator display names
String getOperatorDisplayName(FilterOperator op, AppLocalizations l10n) {
  switch (op) {
    case FilterOperator.greaterThan:
      return l10n.greaterThan;
    case FilterOperator.lessThan:
      return l10n.lessThan;
    case FilterOperator.greaterOrEqual:
      return l10n.greaterOrEqual;
    case FilterOperator.lessOrEqual:
      return l10n.lessOrEqual;
    case FilterOperator.equals:
      return l10n.equalTo;
    case FilterOperator.between:
      return l10n.between;
    case FilterOperator.contains:
      return l10n.contains;
    case FilterOperator.startsWith:
      return l10n.startsWith;
    case FilterOperator.textEquals:
      return l10n.equalTo;
    case FilterOperator.inList:
      return l10n.select;
    case FilterOperator.before:
      return l10n.before;
    case FilterOperator.after:
      return l10n.after;
    case FilterOperator.dateBetween:
      return l10n.between;
  }
}
