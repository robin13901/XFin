import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../database/app_database.dart';
import '../database/tables.dart';
import '../utils/format.dart';
import '../utils/global_constants.dart';

class AllocationItem {
  final String label;
  final double value;
  final AssetTypes? type;
  final Asset? asset;

  const AllocationItem({
    required this.label,
    required this.value,
    this.type,
    this.asset,
  });
}

class AllocationBreakdownSection extends StatelessWidget {
  final List<AllocationItem> items;
  final String title;
  final ValueChanged<AllocationItem>? onItemTap;

  const AllocationBreakdownSection({
    super.key,
    required this.items,
    required this.title,
    this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    final total = items.fold<double>(0, (sum, e) => sum + e.value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AllocationPieChart(items: items),
        const SizedBox(height: 32),
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        ...List.generate(items.length, (index) {
          final item = items[index];
          final ratio = total == 0 ? 0.0 : item.value / total;
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              radius: 8,
              backgroundColor: chartColors[index % chartColors.length],
            ),
            title: Text(
              item.label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              formatCurrency(item.value),
              style: const TextStyle(color: Colors.grey),
            ),
            trailing: Text(
              formatPercent(ratio),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            onTap: onItemTap == null ? null : () => onItemTap!(item),
          );
        }),
      ],
    );
  }
}

class AllocationPieChart extends StatelessWidget {
  final List<AllocationItem> items;

  const AllocationPieChart({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final total = items.fold<double>(0, (sum, e) => sum + e.value);
    return SizedBox(
      height: 240,
      child: PieChart(
        PieChartData(
          sectionsSpace: 3,
          centerSpaceRadius: 46,
          startDegreeOffset: -90,
          sections: List.generate(items.length, (index) {
            final item = items[index];
            final ratio = total == 0 ? 0.0 : item.value / total;
            return PieChartSectionData(
              value: item.value,
              color: chartColors[index % chartColors.length],
              radius: 88,
              title: ratio >= 0.08 ? '${(ratio * 100).toStringAsFixed(0)}%' : '',
              titleStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
            );
          }),
        ),
      ),
    );
  }
}
