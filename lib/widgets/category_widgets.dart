import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../utils/global_constants.dart';

/// Data class for category display information
class CategoryDisplayData {
  final List<MapEntry<String, double>> entries;
  final double totalAmount;
  final bool hasOther;

  const CategoryDisplayData({
    required this.entries,
    required this.totalAmount,
    required this.hasOther,
  });
}

/// Calculates category display data from a map of categories
CategoryDisplayData calculateCategoryData({
  required Map<String, double> categories,
  required bool showAllCategories,
}) {
  final totalAmount = categories.values.fold(0.0, (sum, item) => sum + item.abs());
  final sortedCategories = categories.entries.toList()
    ..sort((a, b) => b.value.abs().compareTo(a.value.abs()));

  final visible = <MapEntry<String, double>>[];
  bool hasOther = false;
  double other = 0;

  for (final entry in sortedCategories) {
    final percentage = totalAmount == 0 ? 0 : (entry.value.abs() / totalAmount) * 100;
    if (!showAllCategories && percentage < 1.0) {
      hasOther = true;
      other += entry.value;
    } else {
      visible.add(entry);
    }
  }

  if (hasOther && other != 0) {
    visible.add(MapEntry('...', other));
  }

  return CategoryDisplayData(
    entries: visible,
    totalAmount: totalAmount,
    hasOther: hasOther,
  );
}

/// A reusable pie chart widget for displaying category breakdowns
class CategoryPieChart extends StatelessWidget {
  final CategoryDisplayData data;
  final ValueChanged<String>? onCategoryTap;

  const CategoryPieChart({
    super.key,
    required this.data,
    this.onCategoryTap,
  });

  @override
  Widget build(BuildContext context) {
    if (data.entries.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 220,
      child: PieChart(
        PieChartData(
          sectionsSpace: 3,
          centerSpaceRadius: 40,
          startDegreeOffset: -90,
          pieTouchData: onCategoryTap == null
              ? null
              : PieTouchData(
                  touchCallback: (event, response) {
                    if (event is FlTapUpEvent &&
                        response?.touchedSection != null) {
                      final idx =
                          response!.touchedSection!.touchedSectionIndex;
                      if (idx < 0 || idx >= data.entries.length) return;
                      final key = data.entries[idx].key;
                      // Don't navigate from the synthetic "..." aggregation row.
                      if (key == '...') return;
                      onCategoryTap!(key);
                    }
                  },
                ),
          sections: List.generate(data.entries.length, (index) {
            final entry = data.entries[index];
            final ratio =
                data.totalAmount == 0 ? 0.0 : entry.value.abs() / data.totalAmount;
            return PieChartSectionData(
              value: entry.value.abs(),
              color: chartColors[index % chartColors.length],
              radius: 84,
              title: ratio >= 0.08 ? '${(ratio * 100).toStringAsFixed(0)}%' : '',
              titleStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
            );
          }),
        ),
      ),
    );
  }
}

/// A reusable widget for displaying a list of categories with amounts and percentages
class CategoryList extends StatelessWidget {
  final CategoryDisplayData data;
  final String noCategoriesMessage;
  final String showAllLabel;
  final String showLessLabel;
  final ValueChanged<bool>? onShowAllChanged;
  final ValueChanged<String>? onCategoryTap;

  const CategoryList({
    super.key,
    required this.data,
    required this.noCategoriesMessage,
    required this.showAllLabel,
    required this.showLessLabel,
    this.onShowAllChanged,
    this.onCategoryTap,
  });

  @override
  Widget build(BuildContext context) {
    if (data.entries.isEmpty) {
      return Center(child: Text(noCategoriesMessage));
    }

    final widgets = <Widget>[];

    for (var i = 0; i < data.entries.length; i++) {
      final entry = data.entries[i];
      final percentage =
          data.totalAmount == 0 ? 0.0 : (entry.value.abs() / data.totalAmount) * 100.0;
      // Don't make the synthetic "..." aggregation row tappable.
      final isAggregator = entry.key == '...';
      widgets.add(
        CategoryListItem(
          category: entry.key,
          amount: entry.value,
          percentage: percentage,
          color: chartColors[i % chartColors.length],
          onTap: (onCategoryTap == null || isAggregator)
              ? null
              : () => onCategoryTap!(entry.key),
        ),
      );
    }

    if (onShowAllChanged != null) {
      if (data.hasOther) {
        widgets.add(
          TextButton(
            onPressed: () => onShowAllChanged!(true),
            child: Text(showAllLabel),
          ),
        );
      } else {
        widgets.add(
          TextButton(
            onPressed: () => onShowAllChanged!(false),
            child: Text(showLessLabel),
          ),
        );
      }
    }

    return Column(children: widgets);
  }
}

/// A single category list item showing a color indicator, label, amount, and percentage
class CategoryListItem extends StatelessWidget {
  final String category;
  final double amount;
  final double percentage;
  final Color color;
  final VoidCallback? onTap;

  const CategoryListItem({
    super.key,
    required this.category,
    required this.amount,
    required this.percentage,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final row = Padding(
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
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(category)),
              ],
            ),
          ),
          Row(
            children: [
              Text(amount.toStringAsFixed(2)),
              const SizedBox(width: 8),
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: TextStyle(color: Theme.of(context).hintColor),
              ),
            ],
          ),
        ],
      ),
    );
    if (onTap == null) return row;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: row,
    );
  }
}
