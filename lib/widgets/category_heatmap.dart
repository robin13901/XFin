import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../database/models/analysis_models.dart';
import '../providers/theme_provider.dart';
import 'category_histogram.dart' show CategoryHistogramMode;

/// GitHub-style heatmap calendar showing daily activity for a category.
///
/// - Each column is a week, each row a day of week (Mon at top → Sun at bottom).
/// - Three months are visible at a time; the heatmap is independently
///   scrollable from the histogram. Newest week is anchored on the right.
/// - Black/white only: light theme uses darker tones for higher activity,
///   dark theme uses lighter tones for higher activity.
/// - Intensity reflects either booking count or summed absolute value
///   depending on [mode].
class CategoryHeatmap extends StatefulWidget {
  final Map<int, CategoryDayBucket> dailyBuckets;
  final DateTime? earliestDate;
  final DateTime endDate;
  final CategoryHistogramMode mode;
  final int visibleMonths;
  final double cellGap;

  const CategoryHeatmap({
    super.key,
    required this.dailyBuckets,
    required this.earliestDate,
    required this.endDate,
    required this.mode,
    this.visibleMonths = 3,
    this.cellGap = 3,
  });

  @override
  State<CategoryHeatmap> createState() => _CategoryHeatmapState();
}

class _CategoryHeatmapState extends State<CategoryHeatmap> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  void didUpdateWidget(covariant CategoryHeatmap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dailyBuckets.length != widget.dailyBuckets.length ||
        oldWidget.earliestDate != widget.earliestDate ||
        oldWidget.mode != widget.mode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  double _intensityValue(CategoryDayBucket b) =>
      widget.mode == CategoryHistogramMode.count ? b.count.toDouble() : b.sum.abs();

  @override
  Widget build(BuildContext context) {
    final earliest = widget.earliestDate;
    final isDark = ThemeProvider.isDark();
    final fg = isDark ? Colors.white : Colors.black;
    final locale = Localizations.localeOf(context).toLanguageTag();

    if (earliest == null || widget.dailyBuckets.isEmpty) {
      return SizedBox(
        height: 140,
        child: Center(
          child: Text(
            '—',
            style: TextStyle(color: fg.withAlpha(120)),
          ),
        ),
      );
    }

    // Anchor start to the Monday of the earliest week.
    final startMonday = _mondayOf(earliest);
    final endSunday = _sundayOf(widget.endDate);
    final totalDays = endSunday.difference(startMonday).inDays + 1;
    final totalWeeks = (totalDays / 7).ceil();

    final maxValue = _maxIntensityValue();

    return LayoutBuilder(
      builder: (context, constraints) {
        // Estimate ~13 weeks per 3 months (3 × 30.44 / 7 ≈ 13.04).
        final visibleWeeks = (widget.visibleMonths * 30.44 / 7).round();
        final viewportWidth = constraints.maxWidth;
        final cellSize = (viewportWidth - widget.cellGap * (visibleWeeks - 1)) /
            visibleWeeks;
        // Layout: 22px top label strip, 7 cell rows, gaps between rows.
        const labelHeight = 20.0;
        final gridHeight = cellSize * 7 + widget.cellGap * 6;
        final totalHeight = labelHeight + gridHeight;

        final contentWidth =
            cellSize * totalWeeks + widget.cellGap * (totalWeeks - 1);

        return SizedBox(
          height: totalHeight,
          child: SingleChildScrollView(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: SizedBox(
              width: contentWidth.clamp(viewportWidth, double.infinity),
              height: totalHeight,
              child: Stack(
                children: [
                  // Month labels strip
                  for (final label in _buildMonthLabels(
                      startMonday, totalWeeks, cellSize, locale))
                    Positioned(
                      left: label.left,
                      top: 0,
                      width: label.width,
                      height: labelHeight,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 2),
                        child: Text(
                          label.text,
                          style: TextStyle(
                            color: fg.withAlpha(150),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.clip,
                          maxLines: 1,
                          softWrap: false,
                        ),
                      ),
                    ),
                  // Grid cells
                  for (var w = 0; w < totalWeeks; w++)
                    for (var d = 0; d < 7; d++)
                      _buildCell(
                        weekIndex: w,
                        dayIndex: d,
                        startMonday: startMonday,
                        endSunday: endSunday,
                        cellSize: cellSize,
                        labelHeight: labelHeight,
                        maxValue: maxValue,
                        fg: fg,
                        isDark: isDark,
                      ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  double _maxIntensityValue() {
    if (widget.dailyBuckets.isEmpty) return 0.0;
    return widget.dailyBuckets.values
        .map(_intensityValue)
        .reduce((a, b) => a > b ? a : b);
  }

  Widget _buildCell({
    required int weekIndex,
    required int dayIndex,
    required DateTime startMonday,
    required DateTime endSunday,
    required double cellSize,
    required double labelHeight,
    required double maxValue,
    required Color fg,
    required bool isDark,
  }) {
    final cellDate = startMonday.add(Duration(days: weekIndex * 7 + dayIndex));
    final isInRange =
        !cellDate.isBefore(startMonday) && !cellDate.isAfter(endSunday);
    final isFuture = cellDate.isAfter(widget.endDate);

    final left = weekIndex * (cellSize + widget.cellGap);
    final top = labelHeight + dayIndex * (cellSize + widget.cellGap);

    Color color;
    if (!isInRange || isFuture) {
      // Don't render anything in cells that are out of range or in the future.
      return const SizedBox.shrink();
    } else {
      final dateInt =
          cellDate.year * 10000 + cellDate.month * 100 + cellDate.day;
      final bucket = widget.dailyBuckets[dateInt];
      final value = bucket == null ? 0.0 : _intensityValue(bucket);
      color = _intensityColor(value, maxValue, fg: fg, isDark: isDark);
    }

    return Positioned(
      left: left,
      top: top,
      width: cellSize,
      height: cellSize,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  /// Maps [value] to a black/white tone based on [maxValue].
  ///
  /// In light theme: low → light gray, high → black.
  /// In dark theme:  low → dark gray,  high → white.
  Color _intensityColor(
    double value,
    double maxValue, {
    required Color fg,
    required bool isDark,
  }) {
    if (value <= 0 || maxValue <= 0) {
      // Empty day — barely visible "scaffold" cell.
      return fg.withAlpha(isDark ? 18 : 22);
    }
    final ratio = (value / maxValue).clamp(0.0, 1.0);
    // Map ratio [0..1] onto alpha [60..255]; min visibility 60 so even a
    // single small booking is clearly distinguishable from empty days.
    final alpha = 60 + (ratio * 195).round();
    return fg.withAlpha(alpha);
  }

  List<_MonthLabelRect> _buildMonthLabels(
    DateTime startMonday,
    int totalWeeks,
    double cellSize,
    String locale,
  ) {
    final labels = <_MonthLabelRect>[];
    int? lastMonthRendered;
    for (var w = 0; w < totalWeeks; w++) {
      final firstDayOfWeek = startMonday.add(Duration(days: w * 7));
      // Use the date that falls on the 4th day of the week to determine the
      // "owning" month — biases columns toward the month they mostly cover.
      final pivot = firstDayOfWeek.add(const Duration(days: 3));
      if (lastMonthRendered != pivot.month) {
        lastMonthRendered = pivot.month;
        labels.add(_MonthLabelRect(
          left: w * (cellSize + widget.cellGap),
          width: cellSize * 5,
          text: DateFormat('MMM', locale).format(pivot),
        ));
      }
    }
    return labels;
  }
}

class _MonthLabelRect {
  final double left;
  final double width;
  final String text;
  const _MonthLabelRect({
    required this.left,
    required this.width,
    required this.text,
  });
}

DateTime _mondayOf(DateTime d) {
  final day = DateTime(d.year, d.month, d.day);
  final weekday = day.weekday; // 1 = Monday
  return day.subtract(Duration(days: weekday - 1));
}

DateTime _sundayOf(DateTime d) {
  final day = DateTime(d.year, d.month, d.day);
  final weekday = day.weekday;
  return day.add(Duration(days: 7 - weekday));
}
