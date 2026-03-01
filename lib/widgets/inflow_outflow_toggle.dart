import 'package:flutter/material.dart';

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
            context,
            isSelected: showInflows,
            label: inflowLabel,
            onTap: () => onChanged(true),
          ),
          _buildSegment(
            context,
            isSelected: !showInflows,
            label: outflowLabel,
            onTap: () => onChanged(false),
          ),
        ],
      ),
    );
  }

  Widget _buildSegment(
    BuildContext context, {
    required bool isSelected,
    required String label,
    required VoidCallback onTap,
  }) {
    const selectedColor = Colors.indigoAccent;
    final textColor = isSelected
        ? Colors.white
        : Theme.of(context).textTheme.bodyLarge?.color;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
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
}
