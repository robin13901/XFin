import 'package:flutter/material.dart';

// Dark green for inflows, dark red for outflows
const _kGreenDark = Color(0xFF0D4A2A);
const _kGreenMid = Color(0xFF1A7A44);
const _kRedMid = Color(0xFF7A1A1A);
const _kRedDark = Color(0xFF4A0D0D);

/// Gradient palette for inflow categories (10 steps, dark→light green)
List<Color> inflowCategoryColors(int count) =>
    _gradientStops(_kGreenDark, _kGreenMid, count);

/// Gradient palette for outflow categories (10 steps, dark→light red)
List<Color> outflowCategoryColors(int count) =>
    _gradientStops(_kRedDark, _kRedMid, count);

List<Color> _gradientStops(Color from, Color to, int count) {
  if (count <= 0) return [];
  if (count == 1) return [from];
  return List.generate(count, (i) {
    final t = i / (count - 1);
    return Color.lerp(from, to, t)!;
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
    return Container(
      height: 46,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          colors: [_kGreenDark, _kGreenMid, _kRedMid, _kRedDark],
          stops: [0.0, 0.38, 0.62, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Sliding glass pill
          AnimatedAlign(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            alignment:
                showInflows ? Alignment.centerLeft : Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              child: Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(11),
                  color: Colors.white.withValues(alpha: 0.18),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.35),
                    width: 0.8,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Labels row
          Row(
            children: [
              _buildLabel(context, label: inflowLabel, isSelected: showInflows,
                  onTap: () => onChanged(true)),
              _buildLabel(context, label: outflowLabel, isSelected: !showInflows,
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
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.6),
              letterSpacing: isSelected ? 0.3 : 0,
            ),
            child: Text(label),
          ),
        ),
      ),
    );
  }
}
