import 'package:flutter/material.dart';

import '../app_theme.dart';

/// A reusable section title widget with consistent styling
class SectionTitle extends StatelessWidget {
  final String title;
  final TextStyle? style;

  const SectionTitle({
    super.key,
    required this.title,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: style ??
          Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
    );
  }
}

/// A reusable stat tile widget for displaying label-value pairs
class StatTile extends StatelessWidget {
  final String label;
  final String value;
  final TextStyle? labelStyle;
  final TextStyle? valueStyle;

  const StatTile({
    super.key,
    required this.label,
    required this.value,
    this.labelStyle,
    this.valueStyle,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      visualDensity: const VisualDensity(vertical: -3),
      contentPadding: EdgeInsets.zero,
      title: Text(
        label,
        style: labelStyle ?? const TextStyle(fontSize: 16),
      ),
      trailing: Text(
        value,
        style: valueStyle ??
            const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
      ),
    );
  }
}

/// Design A: Dashboard card grid with icons and large values
/// Modern card-based layout with 2 columns
class DashboardCardGrid extends StatelessWidget {
  final List<DashboardCardItem> items;

  const DashboardCardGrid({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: items.map((item) {
        return SizedBox(
          width: (MediaQuery.of(context).size.width - 48) / 2,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (item.icon != null)
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (item.iconColor ?? Theme.of(context).colorScheme.primary)
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          item.icon,
                          size: 18,
                          color: item.iconColor ?? Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    const Spacer(),
                    if (item.trend != null)
                      Icon(
                        item.trend! >= 0 ? Icons.trending_up : Icons.trending_down,
                        size: 16,
                        color: item.trend! >= 0 ? AppColors.green : AppColors.red,
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  item.value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: item.valueColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class DashboardCardItem {
  final String label;
  final String value;
  final IconData? icon;
  final Color? iconColor;
  final Color? valueColor;
  final double? trend;

  const DashboardCardItem({
    required this.label,
    required this.value,
    this.icon,
    this.iconColor,
    this.valueColor,
    this.trend,
  });
}

/// Design B: Compact horizontal stat tiles with accent bars
/// Sleek inline design with colored left accent
class DashboardStatsList extends StatelessWidget {
  final List<DashboardStatItem> items;

  const DashboardStatsList({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant;

    return Column(
      children: items.map((item) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: item.accentColor ?? Theme.of(context).colorScheme.primary,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        if (item.icon != null) ...[
                          Icon(
                            item.icon,
                            size: 20,
                            color: item.accentColor ?? (isDark ? Colors.white70 : Colors.black54),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          child: Text(
                            item.label,
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                        ),
                        Text(
                          item.value,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: item.valueColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class DashboardStatItem {
  final String label;
  final String value;
  final IconData? icon;
  final Color? accentColor;
  final Color? valueColor;

  const DashboardStatItem({
    required this.label,
    required this.value,
    this.icon,
    this.accentColor,
    this.valueColor,
  });
}
