import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../database/models/analysis_models.dart';
import '../providers/database_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/format.dart';
import '../widgets/aurora_background.dart';
import '../widgets/category_heatmap.dart';
import '../widgets/category_histogram.dart';
import '../widgets/common_widgets.dart';
import '../widgets/liquid_glass_widgets.dart';

/// Detail screen for a single booking category.
///
/// Reachable from any screen with a category list/pie chart by tapping a
/// category. Shows current-month value, a horizontally scrollable month
/// histogram, two stat cards, and a 3-month heatmap. A global toggle
/// switches all displays between booking count and summed amount.
class CategoryDetailScreen extends StatefulWidget {
  final String category;

  const CategoryDetailScreen({super.key, required this.category});

  @override
  State<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen> {
  late Future<CategoryStats> _future;
  CategoryHistogramMode _mode = CategoryHistogramMode.sum;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<CategoryStats> _load() {
    final db = context.read<DatabaseProvider>().db;
    return db.analysisDao.getCategoryStats(widget.category);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          context.watch<ThemeProvider>().isAurora ? Colors.transparent : null,
      body: FutureBuilder<CategoryStats>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(child: Text('Fehler beim Laden'));
          }
          final stats = snapshot.data!;
          return Stack(
            children: [
              buildAuroraLayer(context),
              SingleChildScrollView(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top +
                      kToolbarHeight +
                      12,
                  left: 12,
                  right: 12,
                  bottom: 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildModeToggle(),
                    const SizedBox(height: 16),
                    _buildHeader(stats),
                    const SizedBox(height: 20),
                    SectionTitle(
                      title: 'Verlauf',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    FrostedGlassCard(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 8),
                      children: [
                        CategoryHistogram(
                          buckets: stats.monthlyBuckets,
                          mode: _mode,
                          sumFormatter: formatCurrency,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SectionTitle(
                      title: 'Statistik',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    _buildStatCards(stats),
                    const SizedBox(height: 20),
                    SectionTitle(
                      title: 'Aktivität',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    FrostedGlassCard(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 12),
                      children: [
                        CategoryHeatmap(
                          dailyBuckets: stats.dailyBuckets,
                          earliestDate: stats.earliestBookingDate,
                          endDate: DateTime.now(),
                          mode: _mode,
                        ),
                      ],
                    ),
                    const SizedBox(height: 64),
                  ],
                ),
              ),
              buildLiquidGlassAppBar(
                context,
                title: Text(widget.category),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildModeToggle() {
    final isDark = ThemeProvider.isDark();
    final borderColor = isDark ? Colors.white : Colors.black;
    final unselectedFill = isDark ? const Color(0xFF151515) : Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: unselectedFill,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: 1.1),
      ),
      child: Row(
        children: [
          _buildSegment(
            label: 'Anzahl',
            isSelected: _mode == CategoryHistogramMode.count,
            onTap: () => setState(() => _mode = CategoryHistogramMode.count),
            isDark: isDark,
          ),
          _buildSegment(
            label: 'Summe',
            isSelected: _mode == CategoryHistogramMode.sum,
            onTap: () => setState(() => _mode = CategoryHistogramMode.sum),
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildSegment({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    final selectedColor =
        isDark ? Colors.white.withAlpha(15) : Colors.black.withAlpha(15);
    final textColor = isSelected
        ? (isDark ? Colors.white : Colors.black)
        : Theme.of(context).textTheme.bodyLarge?.color;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? selectedColor : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(CategoryStats stats) {
    final isDark = ThemeProvider.isDark();
    final fg = isDark ? Colors.white : Colors.black;

    final now = DateTime.now();
    final currentBucket = _findBucket(stats, now.year, now.month);
    final previousMonth = DateTime(now.year, now.month - 1, 1);
    final previousBucket =
        _findBucket(stats, previousMonth.year, previousMonth.month);

    final currentValue = currentBucket == null
        ? 0.0
        : (_mode == CategoryHistogramMode.count
            ? currentBucket.count.toDouble()
            : currentBucket.sum);
    final previousValue = previousBucket == null
        ? 0.0
        : (_mode == CategoryHistogramMode.count
            ? previousBucket.count.toDouble()
            : previousBucket.sum);

    final formattedCurrent = _mode == CategoryHistogramMode.count
        ? currentValue.toInt().toString()
        : formatCurrency(currentValue);

    final hasMomReference = previousValue.abs() > 0.0001;
    final momPct = hasMomReference
        ? ((currentValue - previousValue) / previousValue.abs()) * 100
        : null;
    final momIsUp = (momPct ?? 0) >= 0;

    return FrostedGlassCard(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
      children: [
        Text(
          'Aktueller Monat',
          style: TextStyle(
            fontSize: 12,
            color: fg.withAlpha(160),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          formattedCurrent,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: fg,
          ),
        ),
        const SizedBox(height: 6),
        if (momPct != null)
          Row(
            children: [
              Icon(
                momIsUp ? Icons.arrow_upward : Icons.arrow_downward,
                size: 14,
                color: fg.withAlpha(180),
              ),
              const SizedBox(width: 4),
              Text(
                '${momIsUp ? '+' : ''}${momPct.toStringAsFixed(1)}% vs. Vormonat',
                style: TextStyle(
                  fontSize: 12,
                  color: fg.withAlpha(180),
                ),
              ),
            ],
          )
        else
          Text(
            'Kein Vormonat-Vergleich',
            style: TextStyle(fontSize: 12, color: fg.withAlpha(140)),
          ),
      ],
    );
  }

  CategoryMonthBucket? _findBucket(CategoryStats stats, int year, int month) {
    for (final b in stats.monthlyBuckets) {
      if (b.year == year && b.month == month) return b;
    }
    return null;
  }

  Widget _buildStatCards(CategoryStats stats) {
    final isDark = ThemeProvider.isDark();
    final fg = isDark ? Colors.white : Colors.black;
    const double gap = 8;

    final monthCount = stats.monthlyBuckets.length;
    final isCount = _mode == CategoryHistogramMode.count;

    final avgPerMonth = monthCount == 0
        ? 0.0
        : (isCount
            ? stats.totalCount / monthCount
            : stats.totalSum / monthCount);
    final total = isCount ? stats.totalCount.toDouble() : stats.totalSum;

    final avgFormatted = isCount
        ? formatDecimal(avgPerMonth, decimals: 1)
        : formatCurrency(avgPerMonth);
    final totalFormatted =
        isCount ? stats.totalCount.toString() : formatCurrency(total);

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - gap) / 2;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            _StatCard(
              width: cardWidth,
              icon: Icons.calendar_view_month,
              label: 'Ø pro Monat',
              value: avgFormatted,
              fg: fg,
              isDark: isDark,
            ),
            _StatCard(
              width: cardWidth,
              icon: Icons.summarize,
              label: 'Gesamt',
              value: totalFormatted,
              fg: fg,
              isDark: isDark,
            ),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final double width;
  final IconData icon;
  final String label;
  final String value;
  final Color fg;
  final bool isDark;

  const _StatCard({
    required this.width,
    required this.icon,
    required this.label,
    required this.value,
    required this.fg,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: FrostedGlassCard(
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: fg.withAlpha(190)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: fg.withAlpha(160),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
