import 'package:flutter/material.dart';

import 'package:xfin/app_theme.dart';
import 'package:xfin/l10n/app_localizations.dart';
import 'package:xfin/utils/format.dart';

class MonthGrid extends StatelessWidget {
  final DateTime month;
  final Map<int, double> dayNetFlow;
  final ValueChanged<DateTime> onDayTap;

  const MonthGrid({
    super.key,
    required this.month,
    required this.dayNetFlow,
    required this.onDayTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final firstDayOfMonth = DateTime(month.year, month.month, 1);
    final lastDayOfMonth = DateTime(month.year, month.month + 1, 0);
    final firstWeekdayOffset = (firstDayOfMonth.weekday + 6) % 7;
    final trailingDays = (7 - lastDayOfMonth.weekday) % 7;

    final gridStart = firstDayOfMonth.subtract(Duration(days: firstWeekdayOffset));
    final totalCells = firstWeekdayOffset + lastDayOfMonth.day + trailingDays;
    final rowCount = (totalCells / 7).ceil();

    final weekdayLabels = [
      l10n.calendarWeekdayMon,
      l10n.calendarWeekdayTue,
      l10n.calendarWeekdayWed,
      l10n.calendarWeekdayThu,
      l10n.calendarWeekdayFri,
      l10n.calendarWeekdaySat,
      l10n.calendarWeekdaySun,
    ];

    return Column(
      children: [
        Row(
          children: List.generate(7, (i) {
            final isSunday = i == 6;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  weekdayLabels[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isSunday
                        ? AppColors.red.withValues(alpha: 0.9)
                        : Theme.of(context).hintColor,
                  ),
                ),
              ),
            );
          }),
        ),
        Divider(
          height: 1,
          color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
        ),
        Expanded(
          child: Column(
            children: List.generate(rowCount, (rowIndex) {
              return Expanded(
                child: Row(
                  children: List.generate(7, (colIndex) {
                    final cellIndex = rowIndex * 7 + colIndex;
                    if (cellIndex >= totalCells) {
                      return const Expanded(child: SizedBox());
                    }

                    final date = gridStart.add(Duration(days: cellIndex));
                    final isCurrentMonth = date.month == month.month;
                    final isSunday = date.weekday == DateTime.sunday;
                    final isToday = _isSameDate(date, DateTime.now());
                    final dateInt = date.year * 10000 + date.month * 100 + date.day;
                    final net = dayNetFlow[dateInt];
                    final netColor = net == null
                        ? Theme.of(context).hintColor
                        : (net >= 0 ? AppColors.green : AppColors.red);

                    return Expanded(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => onDayTap(date),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border(
                              right: BorderSide(
                                color: Theme.of(context)
                                    .dividerColor
                                    .withValues(alpha: 0.18),
                              ),
                              bottom: BorderSide(
                                color: Theme.of(context)
                                    .dividerColor
                                    .withValues(alpha: 0.18),
                              ),
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 22,
                                height: 22,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: isToday
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(11),
                                ),
                                child: Text(
                                  '${date.day}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: isToday
                                        ? Theme.of(context).colorScheme.onPrimary
                                        : !isCurrentMonth
                                            ? Theme.of(context).hintColor.withValues(alpha: 0.5)
                                            : isSunday
                                                ? AppColors.red.withValues(alpha: 0.9)
                                                : Theme.of(context)
                                                    .textTheme
                                                    .bodyLarge
                                                    ?.color,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              if (net != null)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 4, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: netColor.withValues(
                                      alpha: isCurrentMonth ? 0.24 : 0.12,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    formatCurrency(net),
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: isCurrentMonth
                                          ? netColor
                                          : netColor.withValues(alpha: 0.5),
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
