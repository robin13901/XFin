import 'package:flutter/material.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

import '../liquid_glass_widgets.dart';
import '../../providers/theme_provider.dart';

/// Liquid Glass styled search bar
class LiquidGlassSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;
  final FocusNode? focusNode;

  const LiquidGlassSearchBar({
    super.key,
    required this.controller,
    required this.hintText,
    required this.onChanged,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = ThemeProvider.isDark();
    final iconColor = isDark ? Colors.white70 : Colors.black54;
    final textColor = isDark ? Colors.white : Colors.black;

    return SizedBox(
      height: 48,
      child: LiquidGlassLayer(
        settings: liquidGlassSettings,
        child: LiquidGlass.grouped(
          shape: const LiquidRoundedSuperellipse(borderRadius: 24),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.search, color: iconColor, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    onChanged: onChanged,
                    textCapitalization: TextCapitalization.words,
                    style: theme.textTheme.bodyMedium?.copyWith(color: textColor),
                    decoration: InputDecoration(
                      hintText: hintText,
                      hintStyle: theme.textTheme.bodyMedium?.copyWith(
                        color: iconColor,
                      ),
                      border: InputBorder.none,
                      fillColor: Colors.transparent,
                      filled: true,
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                    ),
                  ),
                ),
                if (controller.text.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      controller.clear();
                      onChanged('');
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(Icons.clear, color: iconColor, size: 20),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
