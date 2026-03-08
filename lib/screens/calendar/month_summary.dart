import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:xfin/app_theme.dart';
import 'package:xfin/l10n/app_localizations.dart';
import 'package:xfin/utils/format.dart';
import 'package:xfin/utils/global_constants.dart';
import 'package:xfin/widgets/category_widgets.dart';
import 'package:xfin/widgets/common_widgets.dart';
import 'package:xfin/widgets/inflow_outflow_toggle.dart';
import 'package:xfin/widgets/summary_row.dart';

import 'calendar_data.dart';

class MonthHeader extends StatelessWidget {
  final DateTime month;

  const MonthHeader({super.key, required this.month});

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final label = DateFormat('MMMM yyyy', locale).format(month);
    return Center(
      child: Text(
        label[0].toUpperCase() + label.substring(1),
        style: Theme.of(context).textTheme.titleLarge,
      ),
    );
  }
}

class MonthSummarySection extends StatelessWidget {
  final CalendarScreenData data;
  final bool showInflows;
  final bool showAllCategories;
  final ValueChanged<bool> onInflowOutflowChanged;
  final ValueChanged<bool> onShowAllChanged;

  const MonthSummarySection({
    super.key,
    required this.data,
    required this.showInflows,
    required this.showAllCategories,
    required this.onInflowOutflowChanged,
    required this.onShowAllChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(title: l10n.calendarMonthlyOverview),
        const SizedBox(height: 8),
        SummaryRow(
          label: l10n.calendarInflows,
          value: formatCurrency(data.monthlySnapshot.inflows),
          valueColor: AppColors.green,
        ),
        SummaryRow(
          label: l10n.calendarOutflows,
          value: formatCurrency(data.monthlySnapshot.outflows),
          valueColor: AppColors.red,
        ),
        SummaryRow(
          label: l10n.calendarProfit,
          value: formatCurrency(data.monthlySnapshot.profit),
          valueColor: data.monthlySnapshot.profit >= 0 ? AppColors.green : AppColors.red,
        ),
        const SizedBox(height: 12),
        InflowOutflowToggle(
          showInflows: showInflows,
          inflowLabel: l10n.calendarInflows,
          outflowLabel: l10n.calendarOutflows,
          onChanged: onInflowOutflowChanged,
        ),
        const SizedBox(height: 32),
        CategoryPieChart(
          data: calculateCategoryData(
            categories: showInflows
                ? data.monthlySnapshot.categoryInflows
                : data.monthlySnapshot.categoryOutflows,
            showAllCategories: showAllCategories,
          ),
        ),
        const SizedBox(height: 32),
        CategoryListWrapper(
          data: data,
          showInflows: showInflows,
          showAllCategories: showAllCategories,
          onShowAllChanged: onShowAllChanged,
        ),
      ],
    );
  }
}

/// Wrapper to handle category list display logic
class CategoryListWrapper extends StatelessWidget {
  final CalendarScreenData data;
  final bool showInflows;
  final bool showAllCategories;
  final ValueChanged<bool> onShowAllChanged;

  const CategoryListWrapper({
    super.key,
    required this.data,
    required this.showInflows,
    required this.showAllCategories,
    required this.onShowAllChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final categories =
        showInflows ? data.monthlySnapshot.categoryInflows : data.monthlySnapshot.categoryOutflows;

    if (categories.isEmpty) {
      return Center(child: Text(l10n.calendarNoCategoryData));
    }

    final displayData = calculateCategoryData(
      categories: categories,
      showAllCategories: showAllCategories,
    );

    return Column(
      children: [
        ...List.generate(displayData.entries.length, (i) {
          final entry = displayData.entries[i];
          final percentage = displayData.totalAmount == 0
              ? 0
              : (entry.value.abs() / displayData.totalAmount) * 100;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: chartColors[i % chartColors.length],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(entry.key)),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Text(formatCurrency(entry.value)),
                    const SizedBox(width: 8),
                    Text(
                      '${percentage.toStringAsFixed(1)}%',
                      style: TextStyle(color: Theme.of(context).hintColor),
                    ),
                  ],
                )
              ],
            ),
          );
        }),
        if (displayData.hasOther && !showAllCategories)
          TextButton(
            onPressed: () => onShowAllChanged(true),
            child: Text(l10n.calendarShowAll),
          )
        else if (!displayData.hasOther && showAllCategories)
          TextButton(
            onPressed: () => onShowAllChanged(false),
            child: Text(l10n.calendarShowLess),
          ),
      ],
    );
  }
}
