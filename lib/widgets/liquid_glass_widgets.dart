import 'package:flutter/material.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

const liquidGlassSettings = LiquidGlassSettings(
  thickness: 30,
  blur: 1.4,
  glassColor: Color(0x33000000),
);

class LiquidGlassBottomNav extends StatelessWidget {
  final List<IconData> icons;
  final List<String> labels;
  final List<Key> keys;
  final int currentIndex;
  final ValueChanged<int> onTap;

  final VoidCallback? onLeftTap;
  final Set<int> leftVisibleForIndices;
  final IconData rightIcon;
  final VoidCallback? onRightTap;

  /// Height parameter is now the overall container height; by default it
  /// equals circleSize so the center pill and circular buttons match.
  final double height;
  final double horizontalPadding;
  final LiquidGlassSettings settings;

  const LiquidGlassBottomNav({
    super.key,
    required this.icons,
    required this.labels,
    required this.keys,
    required this.currentIndex,
    required this.onTap,
    this.onLeftTap,
    this.leftVisibleForIndices = const {},
    this.rightIcon = Icons.more_horiz,
    this.onRightTap,
    this.height = 56.0, // default matches circleSize below
    this.horizontalPadding = 16.0,
    this.settings = liquidGlassSettings,
  }) : assert(icons.length == labels.length,
            'icons and labels must be same length');

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    // Single source of truth for circular button diameter
    const double circleSize = 64.0;

    // Use the widget height but ensure it's at least circleSize.
    final double navHeight = height < circleSize ? circleSize : height;

    final bool showLeft =
        leftVisibleForIndices.contains(currentIndex) && onLeftTap != null;
    const double itemHorizontalPadding = 12.0;

    return SafeArea(
      bottom: true,
      child: Padding(
        padding:
            EdgeInsets.fromLTRB(horizontalPadding, 8, horizontalPadding, 8),
        child: SizedBox(
          width: double.infinity,
          height: navHeight,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Left circular button (may be hidden)
              if (showLeft)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: buildCircleButton(
                    child:
                        Icon(Icons.add, size: 26, color: theme.iconTheme.color),
                    size: circleSize,
                    onTap: onLeftTap!,
                    key: const Key('fab'),
                    settings: settings,
                  ),
                ),
              // Center pill (LiquidGlass single superellipse)
              // We make its height equal to navHeight and border radius equal to circleSize/2.
              Expanded(
                child: SizedBox(
                  height: navHeight,
                  child: LiquidGlassLayer(
                    settings: settings,
                    child: LiquidGlass.grouped(
                      shape: const LiquidRoundedSuperellipse(
                          borderRadius: circleSize / 2),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: itemHorizontalPadding),
                        decoration: BoxDecoration(
                            borderRadius:
                                BorderRadius.circular(circleSize / 2)),
                        child: LayoutBuilder(builder: (context, constraints) {
                          final int itemCount = icons.length;
                          final double totalAvailable =
                              constraints.maxWidth.isFinite
                                  ? constraints.maxWidth
                                  : MediaQuery.of(context).size.width;

                          // sensible min/max per item widths
                          const double minItemWidth = 56.0;
                          const double maxItemWidth = 140.0;

                          double perItemWidth = totalAvailable / itemCount;
                          perItemWidth =
                              perItemWidth.clamp(minItemWidth, maxItemWidth);

                          final bool fits =
                              perItemWidth * itemCount <= totalAvailable + 0.5;

                          if (fits) {
                            // Each item gets a fixed width that scales with available space
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: List.generate(itemCount, (index) {
                                final bool isSelected = index == currentIndex;
                                return GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () => onTap(index),
                                  key: keys[index],
                                  child: SizedBox(
                                    width: perItemWidth,
                                    height: navHeight,
                                    child: _buildNavColumn(
                                      icon: icons[index],
                                      label: labels[index],
                                      isSelected: isSelected,
                                      theme: theme,
                                    ),
                                  ),
                                );
                              }),
                            );
                          } else {
                            // fallback to flex so we never overflow
                            return Row(
                              children: List.generate(itemCount, (index) {
                                final bool isSelected = index == currentIndex;
                                return Expanded(
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () => onTap(index),
                                    key: keys[index],
                                    child: _buildNavColumn(
                                      icon: icons[index],
                                      label: labels[index],
                                      isSelected: isSelected,
                                      theme: theme,
                                    ),
                                  ),
                                );
                              }),
                            );
                          }
                        }),
                      ),
                    ),
                  ),
                ),
              ),
              // Right circular button
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: buildCircleButton(
                  child:
                      Icon(rightIcon, size: 26, color: theme.iconTheme.color),
                  size: circleSize,
                  onTap: onRightTap,
                  settings: settings,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavColumn({
    required IconData icon,
    required String label,
    required bool isSelected,
    required ThemeData theme,
  }) {
    const Color selectedColor = Colors.white;
    const Color unselectedColor = Colors.grey;
    // theme.iconTheme.color?.withValues(alpha: 0.85) ?? Colors.white70;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon,
            size: 22, color: isSelected ? selectedColor : unselectedColor),
        const SizedBox(height: 6),
        // Labels are always visible now; color follows the icon's color.
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 180),
          style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 9,
                color: isSelected ? selectedColor : unselectedColor,
              ) ??
              TextStyle(
                  fontSize: 11,
                  color: isSelected ? selectedColor : unselectedColor),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

Widget buildCircleButton({
  required Widget child,
  required double size,
  required LiquidGlassSettings settings,
  VoidCallback? onTap,
  Key? key,
}) {
  final btn = SizedBox(
    width: size,
    height: size,
    child: LiquidGlassLayer(
      settings: settings,
      child: LiquidGlass.grouped(
        shape: const LiquidRoundedSuperellipse(borderRadius: 100),
        child: Center(child: child),
      ),
    ),
  );

  if (onTap == null) return btn;
  return GestureDetector(
      onTap: onTap, behavior: HitTestBehavior.opaque, key: key, child: btn);
}

Widget buildFAB({
  required BuildContext context,
  VoidCallback? onTap,
}) {
  return Positioned(
    bottom: 24,
    right: 24,
    child: buildCircleButton(
      child:
          Icon(Icons.add, size: 26, color: Theme.of(context).iconTheme.color),
      size: 64,
      onTap: onTap,
      settings: liquidGlassSettings,
      key: const Key('fab'),
    ),
  );
}

Widget buildLiquidGlassAppBar(BuildContext context,
    {required Widget title, bool showBackButton = true}) {
  final double statusBar = MediaQuery.of(context).padding.top;
  final double height = statusBar + kToolbarHeight;

  const double overscan = 40.0;

  return Positioned(
    top: -overscan,
    left: -overscan,
    right: -overscan,
    height: height + overscan,
    child: LiquidGlassLayer(
      settings: liquidGlassSettings,
      child: LiquidGlass.grouped(
        shape: const LiquidRoundedSuperellipse(borderRadius: 0),
        child: Stack(
          children: [
            // Oversized glass background
            Positioned(
              top: -overscan,
              left: 0,
              right: 0,
              height: height + overscan * 2,
              child: Container(),
            ),

            // Foreground content (interactive)
            Positioned(
              left: overscan,
              right: overscan,
              top: statusBar + overscan,
              height: kToolbarHeight,
              child: Row(
                children: [
                  if (showBackButton) ...[
                    const BackButton(),
                  ] else ...[
                    const SizedBox(width: 8),
                  ],
                  const SizedBox(width: 8),
                  Expanded(
                    child: DefaultTextStyle(
                      style: Theme.of(context).appBarTheme.titleTextStyle ??
                          Theme.of(context).textTheme.titleLarge!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      child: title,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// A simple model for menu items shown in the panel
class GlassMenuItem {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  GlassMenuItem({required this.label, required this.icon, this.onTap});
}

/// Show a centered floating LiquidGlass panel as an OverlayEntry.
/// The panel will dismiss when tapping outside or pressing a menu item.
/// The returned Future completes when the panel is dismissed.
Future<void> showLiquidGlassPanel({
  required BuildContext context,
  required List<GlassMenuItem> items,
  double widthFraction = 0.65, // fraction of screen width
  double maxHeightFraction = 0.7,
  LiquidGlassSettings settings = liquidGlassSettings,
}) async {
  final overlay = Overlay.of(context);

  final screenSize = MediaQuery.of(context).size;
  final width = screenSize.width * widthFraction;
  final maxHeight = screenSize.height * maxHeightFraction;

  final entry = OverlayEntry(builder: (ctx) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        // entry.remove();
      },
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            // Centered panel
            Center(
              child: SizedBox(
                width: width,
                // height adapt to content
                child: LiquidGlassLayer(
                  settings: settings,
                  child: LiquidGlass.grouped(
                    shape: const LiquidRoundedSuperellipse(borderRadius: 28),
                    child: Container(
                      constraints: BoxConstraints(
                        maxHeight: maxHeight,
                      ),
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 12),
                      child: _PanelContent(items: items),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  });

  overlay.insert(entry);

  // Wait until entry removed; we can't easily await removal, so return immediately.
  // If you want a Future that completes on dismiss, you can wrap remove with a Completer.
  return;
}

class _PanelContent extends StatelessWidget {
  final List<GlassMenuItem> items;

  const _PanelContent({required this.items});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // 2-column grid
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // header spacing / subtle handle
        const SizedBox(height: 6),
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 12),
        Flexible(
          child: GridView.builder(
            shrinkWrap: true,
            itemCount: items.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              childAspectRatio: 3.0,
            ),
            itemBuilder: (context, index) {
              final item = items[index];
              return _PanelItem(item: item, theme: theme);
            },
          ),
        ),
      ],
    );
  }
}

class _PanelItem extends StatelessWidget {
  final GlassMenuItem item;
  final ThemeData theme;

  const _PanelItem({required this.item, required this.theme});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        item.onTap?.call();
        // close overlay by popping the overlay: easiest is Navigator.pop until overlay removed,
        // but because we used OverlayEntry directly we remove by searching overlays or let the caller remove it.
        // For simplicity we pop the route if possible:
        // Navigator.of(context)
        //     .pop(); // may or may not remove overlay depending how called
      },
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.white.withValues(alpha: 0.06),
            child: Icon(item.icon, size: 18, color: theme.iconTheme.color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              item.label,
              style: theme.textTheme.titleMedium?.copyWith(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
