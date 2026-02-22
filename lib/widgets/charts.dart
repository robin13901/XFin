import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';

import '../database/app_database.dart';
import '../database/tables.dart';
import '../utils/global_constants.dart';

class AllocationItem {
  final String label;
  final double value;
  final AssetTypes? type;
  final Asset? asset;

  const AllocationItem(
      {required this.label, required this.value, this.type, this.asset});
}

Widget buildAllocationChart(List<AllocationItem> items) {
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
            title:
            ratio >= 0.08 ? '${(ratio * 100).toStringAsFixed(0)}%' : '',
            titleStyle:
            const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
          );
        }),
      ),
    ),
  );
}