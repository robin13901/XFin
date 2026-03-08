import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

import 'package:xfin/database/daos/analysis_dao.dart';
import 'package:xfin/utils/snappy_scroll_physics.dart';
import 'package:xfin/widgets/liquid_glass_widgets.dart';

class DayDetailsPage {
  final String title;
  final Widget child;

  const DayDetailsPage({required this.title, required this.child});
}

class SimpleDetailRow {
  final String leading;
  final String trailing;
  final Color? trailingColor;

  const SimpleDetailRow({
    required this.leading,
    required this.trailing,
    required this.trailingColor,
  });
}

class DayDetailsPager extends StatefulWidget {
  final CalendarDayDetails details;
  final List<DayDetailsPage> pages;

  const DayDetailsPager({super.key, required this.details, required this.pages});

  @override
  State<DayDetailsPager> createState() => DayDetailsPagerState();
}

class DayDetailsPagerState extends State<DayDetailsPager> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final dayLabel = DateFormat('EEEE, dd.MM.yyyy', locale).format(widget.details.day);

    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: LiquidGlassLayer(
          settings: liquidGlassSettings,
          child: LiquidGlass.grouped(
            shape: const LiquidRoundedSuperellipse(borderRadius: 28),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          dayLabel,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800, fontSize: 19),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.pages[_index].title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).hintColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: PageView.builder(
                      physics: const BouncingScrollPhysics(parent: SnappyPageScrollPhysics()),
                      itemCount: widget.pages.length,
                      onPageChanged: (i) => setState(() => _index = i),
                      itemBuilder: (context, i) {
                        return SingleChildScrollView(
                          child: widget.pages[i].child,
                        );
                      },
                    ),
                  ),
                  if (widget.pages.length > 1)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        widget.pages.length,
                        (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: i == _index ? 14 : 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            color: i == _index
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).dividerColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
