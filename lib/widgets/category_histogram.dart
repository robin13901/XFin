import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../database/models/analysis_models.dart';
import '../providers/theme_provider.dart';

/// What the histogram bars encode: number of bookings or summed value.
enum CategoryHistogramMode { count, sum }

/// Horizontal scrollable bar chart for a single category.
///
/// - Shows up to [visibleBars] bars at a time (default 12).
/// - Newest month is anchored on the right; older months scroll in from the left.
/// - Tap on a bar shows a tooltip; tapping outside dismisses it.
/// - A horizontal average line is overlaid across the visible viewport.
/// - Black/white only — derives shades from the active theme.
class CategoryHistogram extends StatefulWidget {
  final List<CategoryMonthBucket> buckets;
  final CategoryHistogramMode mode;
  final String Function(double value) sumFormatter;
  final double height;
  final int visibleBars;

  const CategoryHistogram({
    super.key,
    required this.buckets,
    required this.mode,
    required this.sumFormatter,
    this.height = 220,
    this.visibleBars = 12,
  });

  @override
  State<CategoryHistogram> createState() => _CategoryHistogramState();
}

class _CategoryHistogramState extends State<CategoryHistogram> {
  final ScrollController _scrollController = ScrollController();
  int? _selectedIndex;
  // Reset to null when widget is rebuilt with a different mode/category, since
  // the bar heights change and a stale tooltip would point at the wrong value.
  CategoryHistogramMode? _lastMode;
  int? _lastBucketCount;

  @override
  void initState() {
    super.initState();
    // After first frame, jump to the right-most position (newest month).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  void didUpdateWidget(covariant CategoryHistogram oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mode != widget.mode ||
        oldWidget.buckets.length != widget.buckets.length) {
      _selectedIndex = null;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  double _valueOf(CategoryMonthBucket b) =>
      widget.mode == CategoryHistogramMode.count ? b.count.toDouble() : b.sum.abs();

  String _formatValue(CategoryMonthBucket b) {
    if (widget.mode == CategoryHistogramMode.count) return b.count.toString();
    return widget.sumFormatter(b.sum);
  }

  @override
  Widget build(BuildContext context) {
    if (_lastMode != widget.mode ||
        _lastBucketCount != widget.buckets.length) {
      _lastMode = widget.mode;
      _lastBucketCount = widget.buckets.length;
      _selectedIndex = null;
      // Re-anchor scroll to newest after data changes.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController
              .jumpTo(_scrollController.position.maxScrollExtent);
        }
      });
    }

    if (widget.buckets.isEmpty) {
      return SizedBox(
        height: widget.height,
        child: const Center(child: Text('—')),
      );
    }

    final isDark = ThemeProvider.isDark();
    final fg = isDark ? Colors.white : Colors.black;
    final locale = Localizations.localeOf(context).toLanguageTag();

    final values = widget.buckets.map(_valueOf).toList();
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final nonZero = values.where((v) => v > 0).toList();
    final avgValue = nonZero.isEmpty
        ? 0.0
        : nonZero.reduce((a, b) => a + b) / nonZero.length;

    return SizedBox(
      height: widget.height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final viewport = constraints.maxWidth;
          final barCellWidth = viewport / widget.visibleBars;
          final contentWidth =
              (barCellWidth * widget.buckets.length).clamp(viewport, double.infinity);

          // Reserve 28px at bottom for month labels, 8px at top for breathing room.
          const labelStripHeight = 28.0;
          const topPadding = 8.0;
          final chartArea = widget.height - labelStripHeight - topPadding;
          final avgY = maxValue == 0
              ? chartArea
              : topPadding + (1 - avgValue / maxValue) * chartArea;

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (_selectedIndex != null) {
                setState(() => _selectedIndex = null);
              }
            },
            child: Stack(
              children: [
                Positioned.fill(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: SizedBox(
                      width: contentWidth,
                      height: widget.height,
                      child: Stack(
                        children: [
                          for (var i = 0; i < widget.buckets.length; i++)
                            _buildBar(
                              index: i,
                              bucket: widget.buckets[i],
                              left: i * barCellWidth,
                              cellWidth: barCellWidth,
                              chartTop: topPadding,
                              chartHeight: chartArea,
                              maxValue: maxValue,
                              fg: fg,
                              isDark: isDark,
                            ),
                          for (var i = 0; i < widget.buckets.length; i++)
                            Positioned(
                              left: i * barCellWidth,
                              width: barCellWidth,
                              bottom: 0,
                              height: labelStripHeight,
                              child: _MonthLabel(
                                bucket: widget.buckets[i],
                                color: fg.withAlpha(140),
                                locale: locale,
                              ),
                            ),
                          if (_selectedIndex != null)
                            _buildTooltip(
                              index: _selectedIndex!,
                              bucket: widget.buckets[_selectedIndex!],
                              barCellWidth: barCellWidth,
                              fg: fg,
                              isDark: isDark,
                              locale: locale,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (avgValue > 0)
                  Positioned(
                    left: 0,
                    right: 0,
                    top: avgY,
                    child: IgnorePointer(
                      child: _AverageLine(color: fg.withAlpha(110)),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBar({
    required int index,
    required CategoryMonthBucket bucket,
    required double left,
    required double cellWidth,
    required double chartTop,
    required double chartHeight,
    required double maxValue,
    required Color fg,
    required bool isDark,
  }) {
    final value = _valueOf(bucket);
    final ratio = maxValue == 0 ? 0.0 : (value / maxValue).clamp(0.0, 1.0);
    final barHeight = ratio * chartHeight;
    const horizontalPadding = 4.0;
    final isSelected = _selectedIndex == index;

    return Positioned(
      key: ValueKey('bar-$index'),
      left: left,
      top: chartTop,
      width: cellWidth,
      height: chartHeight,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          setState(() {
            _selectedIndex = isSelected ? null : index;
          });
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOut,
              width: cellWidth - horizontalPadding * 2,
              height: barHeight,
              decoration: BoxDecoration(
                color: isSelected
                    ? fg
                    : (isDark
                        ? fg.withAlpha(180)
                        : fg.withAlpha(210)),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(3),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTooltip({
    required int index,
    required CategoryMonthBucket bucket,
    required double barCellWidth,
    required Color fg,
    required bool isDark,
    required String locale,
  }) {
    final monthName =
        DateFormat('MMM yyyy', locale).format(bucket.monthStart);
    final value = _formatValue(bucket);
    return Positioned(
      left: index * barCellWidth - 40 + barCellWidth / 2,
      top: 0,
      child: IgnorePointer(
        child: Container(
          constraints: const BoxConstraints(minWidth: 80),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: isDark ? Colors.white : Colors.black,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                monthName,
                style: TextStyle(
                  color: isDark ? Colors.black : Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  color: isDark ? Colors.black : Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MonthLabel extends StatelessWidget {
  final CategoryMonthBucket bucket;
  final Color color;
  final String locale;

  const _MonthLabel({
    required this.bucket,
    required this.color,
    required this.locale,
  });

  @override
  Widget build(BuildContext context) {
    final isJan = bucket.month == 1;
    final monthShort = DateFormat('MMM', locale).format(bucket.monthStart);
    final label = isJan ? "$monthShort '${bucket.year % 100}" : monthShort;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          label,
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.clip,
          style: TextStyle(
            fontSize: 10,
            color: color,
            fontWeight: isJan ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _AverageLine extends StatelessWidget {
  final Color color;

  const _AverageLine({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: color,
            width: 1,
            style: BorderStyle.solid,
          ),
        ),
      ),
    );
  }
}
