import 'package:flutter/material.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

import '../../l10n/app_localizations.dart';
import '../../models/filter/filter_config.dart';
import '../../models/filter/filter_rule.dart';
import '../../providers/theme_provider.dart';
import '../../utils/format.dart';
import '../liquid_glass_widgets.dart';
import 'filter_rule_editor.dart';
import 'filter_value_inputs.dart';

/// Main filter panel overlay
class FilterPanel extends StatefulWidget {
  final FilterConfig config;
  final List<FilterRule> currentRules;
  final ValueChanged<List<FilterRule>> onRulesChanged;
  final VoidCallback onClose;

  const FilterPanel({
    super.key,
    required this.config,
    required this.currentRules,
    required this.onRulesChanged,
    required this.onClose,
  });

  @override
  State<FilterPanel> createState() => _FilterPanelState();
}

class _FilterPanelState extends State<FilterPanel> {
  late bool _isEditing;
  int? _editingIndex;

  @override
  void initState() {
    super.initState();
    // Start in editing mode if no filters are set
    _isEditing = widget.currentRules.isEmpty;
  }

  void _addRule(FilterRule rule) {
    final newRules = List<FilterRule>.from(widget.currentRules)..add(rule);
    widget.onRulesChanged(newRules);
    setState(() => _isEditing = false);
  }

  void _updateRule(int index, FilterRule rule) {
    final newRules = List<FilterRule>.from(widget.currentRules);
    newRules[index] = rule;
    widget.onRulesChanged(newRules);
    setState(() {
      _isEditing = false;
      _editingIndex = null;
    });
  }

  void _deleteRule(int index) {
    final newRules = List<FilterRule>.from(widget.currentRules)..removeAt(index);
    widget.onRulesChanged(newRules);
    // Auto-close panel if last filter was deleted
    if (newRules.isEmpty) {
      widget.onClose();
    }
  }

  void _clearAll() {
    widget.onRulesChanged([]);
    widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = ThemeProvider.isDark();
    final mediaQuery = MediaQuery.of(context);
    final maxHeight = mediaQuery.size.height * 0.7;
    final maxWidth = mediaQuery.size.width * 0.92;

    return GestureDetector(
      onTap: widget.onClose,
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: Colors.black26,
        child: Center(
          child: GestureDetector(
            onTap: () {}, // Prevent closing when tapping panel
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: maxWidth > 400 ? 400 : maxWidth,
                maxHeight: maxHeight,
              ),
              child: LiquidGlassLayer(
                settings: liquidGlassSettings,
                child: LiquidGlass.grouped(
                  shape: const LiquidRoundedSuperellipse(borderRadius: 28),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header
                        Row(
                          children: [
                            Text(
                              widget.config.title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Spacer(),
                            if (widget.currentRules.isNotEmpty)
                              TextButton(
                                onPressed: _clearAll,
                                child: Text(
                                  l10n.clearAllFilters,
                                  style: TextStyle(
                                    color: isDark ? Colors.white70 : Colors.black54,
                                  ),
                                ),
                              ),
                            IconButton(
                              onPressed: widget.onClose,
                              icon: const Icon(Icons.close),
                              iconSize: 20,
                            ),
                          ],
                        ),

                        const Divider(height: 24),

                        // Content
                        Flexible(
                          child: SingleChildScrollView(
                            child: _isEditing
                                ? FilterRuleEditor(
                                    config: widget.config,
                                    existingRule: _editingIndex != null
                                        ? widget.currentRules[_editingIndex!]
                                        : null,
                                    onSave: (rule) {
                                      if (_editingIndex != null) {
                                        _updateRule(_editingIndex!, rule);
                                      } else {
                                        _addRule(rule);
                                      }
                                    },
                                    onCancel: () {
                                      // If there are no rules, close the panel
                                      if (widget.currentRules.isEmpty) {
                                        widget.onClose();
                                      } else {
                                        setState(() {
                                          _isEditing = false;
                                          _editingIndex = null;
                                        });
                                      }
                                    },
                                  )
                                : _buildRulesList(l10n, theme, isDark),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRulesList(AppLocalizations l10n, ThemeData theme, bool isDark) {
    return Column(
      children: [
        // Existing rules
        ...widget.currentRules.asMap().entries.map((entry) {
          final index = entry.key;
          final rule = entry.value;
          return _buildRuleCard(rule, index, l10n, theme, isDark);
        }),

        // Add more button
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: OutlinedButton.icon(
            onPressed: () => setState(() => _isEditing = true),
            icon: const Icon(Icons.add, size: 18),
            label: Text(l10n.addFilter),
            style: OutlinedButton.styleFrom(
              foregroundColor: isDark ? Colors.white70 : Colors.black87,
              side: BorderSide(
                color: isDark ? Colors.white24 : Colors.black26,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRuleCard(
    FilterRule rule,
    int index,
    AppLocalizations l10n,
    ThemeData theme,
    bool isDark,
  ) {
    final field = widget.config.getField(rule.fieldId);
    final fieldName = field?.displayName ?? rule.fieldId;
    final operatorName = getOperatorDisplayName(rule.operator, l10n);
    final valueDisplay = _formatValue(rule, field);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$fieldName $operatorName $valueDisplay',
              style: theme.textTheme.bodyMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            onPressed: () => _deleteRule(index),
            icon: const Icon(Icons.close, size: 18),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
          ),
        ],
      ),
    );
  }

  String _formatValue(FilterRule rule, FilterField? field) {
    final value = rule.value;

    if (field?.type == FilterFieldType.date) {
      if (value is List && value.length == 2) {
        final start = intToDateTime(value[0] as int);
        final end = intToDateTime(value[1] as int);
        if (start != null && end != null) {
          return '${dateFormat.format(start)} - ${dateFormat.format(end)}';
        }
      } else if (value is int) {
        final date = intToDateTime(value);
        return date != null ? dateFormat.format(date) : value.toString();
      }
    }

    if (value is List) {
      if (value.isEmpty) return '—';
      if (value.length <= 3) {
        return value.join(', ');
      }
      return '${value.take(3).join(', ')}...';
    }

    return value?.toString() ?? '—';
  }
}
