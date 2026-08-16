import 'package:flutter/material.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

import '../providers/theme_provider.dart';
import 'liquid_glass_widgets.dart';

// Gradient: green edge → neutral center → red edge
// The neutral center adapts to dark/light theme
LinearGradient _buildToggleGradient(bool isDark) {
  final neutral = isDark ? const Color(0xFF111111) : const Color(0xFFEEEEEE);
  return LinearGradient(
    colors: [
      const Color(0xFF0A5C30), // deep green
      neutral,
      const Color(0xFF5C0A0A), // deep red
    ],
    stops: const [0.0, 0.5, 1.0],
  );
}

/// Gradient palette for inflow categories – widely spaced greens
List<Color> inflowCategoryColors(int count) => _wideGradient(
      const [
        Color(0xFF0A5C30),
        Color(0xFF1A8A4A),
        Color(0xFF2EBD68),
        Color(0xFF5FD98A),
        Color(0xFF96EDB5),
      ],
      count,
    );

/// Gradient palette for outflow categories – widely spaced reds
List<Color> outflowCategoryColors(int count) => _wideGradient(
      const [
        Color(0xFF5C0A0A),
        Color(0xFF8A1A1A),
        Color(0xFFBD2E2E),
        Color(0xFFD96060),
        Color(0xFFEDA0A0),
      ],
      count,
    );

List<Color> _wideGradient(List<Color> palette, int count) {
  if (count <= 0) return [];
  if (count == 1) return [palette.first];
  return List.generate(count, (i) {
    final t = i / (count - 1) * (palette.length - 1);
    final lo = t.floor().clamp(0, palette.length - 2);
    final hi = (lo + 1).clamp(0, palette.length - 1);
    return Color.lerp(palette[lo], palette[hi], t - lo)!;
  });
}

class InflowOutflowToggle extends StatelessWidget {
  final bool showInflows;
  final String inflowLabel;
  final String outflowLabel;
  final ValueChanged<bool> onChanged;

  const InflowOutflowToggle({
    super.key,
    required this.showInflows,
    required this.inflowLabel,
    required this.outflowLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: _buildToggleGradient(isDark),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Sliding liquid glass pill
          AnimatedAlign(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            alignment:
                showInflows ? Alignment.centerLeft : Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              child: LiquidGlassLayer(
                settings: liquidGlassSettings,
                child: const LiquidGlass.grouped(
                  shape: LiquidRoundedSuperellipse(borderRadius: 14),
                  child: SizedBox.expand(),
                ),
              ),
            ),
          ),
          // Labels
          Row(
            children: [
              _buildLabel(context,
                  label: inflowLabel,
                  isSelected: showInflows,
                  onTap: () => onChanged(true)),
              _buildLabel(context,
                  label: outflowLabel,
                  isSelected: !showInflows,
                  onTap: () => onChanged(false)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = ThemeProvider.isDark();
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 180),
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected
                  ? (isDark ? Colors.white : Colors.black)
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.5)
                      : Colors.black.withValues(alpha: 0.45)),
              letterSpacing: isSelected ? 0.3 : 0,
            ),
            child: Text(label),
          ),
        ),
      ),
    );
  }
}
