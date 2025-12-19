import 'package:flutter/material.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'package:xfin/l10n/app_localizations.dart';
import 'package:xfin/screens/settings_screen.dart';
import 'package:xfin/screens/assets_screen.dart';
import 'package:xfin/screens/trades_screen.dart';
import 'package:xfin/screens/transfers_screen.dart';

import 'liquid_glass_widgets.dart';

Future<void> showMorePane({
  required BuildContext context,
  required GlobalKey navBarKey,
  required ValueNotifier<bool> navBarVisible,
}) async {
  final overlay = Overlay.of(context);

  final l10n = AppLocalizations.of(context)!;
  final screenSize = MediaQuery.of(context).size;

  // compute default right/bottom fallback
  double right = 24;
  double bottom = 24;

  // Build pane items (icon over text)
  final paneItems = <_PaneItem>[
    _PaneItem(
      label: l10n.settings,
      icon: Icons.settings,
      onTap: () => Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
    ),
    _PaneItem(
      label: l10n.assets,
      icon: Icons.monetization_on,
      onTap: () => Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const AssetsScreen())),
    ),
    _PaneItem(
      label: l10n.trades,
      icon: Icons.swap_horiz,
      onTap: () => Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const TradesScreen())),
    ),
    _PaneItem(
      label: l10n.transfers,
      icon: Icons.receipt_long,
      onTap: () => Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const TransfersScreen())),
    ),
  ];

  // Pane width (clamped)
  final double paneWidth = (screenSize.width * 0.44).clamp(220.0, 360.0);

  // Insert overlay entry containing a Stateful animated pane
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (ctx) {
      return _AnimatedMorePane(
        entryRemover: () {
          if (entry.mounted) entry.remove();
        },
        right: right,
        bottom: bottom,
        paneWidth: paneWidth,
        settings: liquidGlassSettings,
        items: paneItems,
        onCloseRestoreNav: () => navBarVisible.value = true,
        onOpenHideNav: () => navBarVisible.value = false,
      );
    },
  );

  navBarVisible.value = false;
  overlay.insert(entry);

  return;
}

/// Internal model for a pane item
class _PaneItem {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  _PaneItem({required this.label, required this.icon, required this.onTap});
}

/// A widget that animates in/out on creation/dispose and removes overlay entry
/// when dismissed. It also runs the item callback when an item is tapped.
class _AnimatedMorePane extends StatefulWidget {
  final VoidCallback entryRemover;
  final double right;
  final double bottom;
  final double paneWidth;
  final LiquidGlassSettings settings;
  final List<_PaneItem> items;
  final VoidCallback onCloseRestoreNav;
  final VoidCallback onOpenHideNav;

  const _AnimatedMorePane({
    required this.entryRemover,
    required this.right,
    required this.bottom,
    required this.paneWidth,
    required this.settings,
    required this.items,
    required this.onCloseRestoreNav,
    required this.onOpenHideNav,
  });

  @override
  State<_AnimatedMorePane> createState() => _AnimatedMorePaneState();
}

class _AnimatedMorePaneState extends State<_AnimatedMorePane>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctr;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctr = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100));
    _scale = CurvedAnimation(parent: _ctr, curve: Curves.easeOutBack);
    _opacity = CurvedAnimation(parent: _ctr, curve: Curves.easeIn);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onOpenHideNav();
      _ctr.forward();
    });
  }

  @override
  void dispose() {
    _ctr.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    await _ctr.reverse();
    widget.onCloseRestoreNav();
    widget.entryRemover();
  }

  Future<void> _onItemTap(VoidCallback cb) async {
    await _ctr.reverse();
    widget.onCloseRestoreNav();
    widget.entryRemover();
    Future.microtask(cb);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => _dismiss(),
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            Positioned(
              right: widget.right,
              bottom: widget.bottom,
              child: SafeArea(
                child: AnimatedBuilder(
                  animation: _ctr,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _opacity.value,
                      child: Transform.scale(
                        scale: _scale.value.clamp(0.01, 1.0),
                        alignment: Alignment.bottomRight,
                        child: child,
                      ),
                    );
                  },
                  child: SizedBox(
                    width: widget.paneWidth,
                    child: LiquidGlassLayer(
                      settings: widget.settings,
                      child: LiquidGlass.grouped(
                        shape:
                            const LiquidRoundedSuperellipse(borderRadius: 28),
                        child: _PaneContent(
                          items: widget.items,
                          onItemTap: (cb) => _onItemTap(cb),
                          theme: theme,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaneContent extends StatelessWidget {
  final List<_PaneItem> items;
  final void Function(VoidCallback) onItemTap;
  final ThemeData theme;

  const _PaneContent({
    required this.items,
    required this.onItemTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GridView.count(
          shrinkWrap: true,
          crossAxisCount: 2,
          physics: const NeverScrollableScrollPhysics(),
          children: items.map((it) {
            return InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => onItemTap(it.onTap),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(it.icon, size: 24, color: theme.iconTheme.color),
                  const SizedBox(height: 4),
                  Text(
                    it.label,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
