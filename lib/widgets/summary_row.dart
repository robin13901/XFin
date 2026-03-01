import 'package:flutter/material.dart';

/// A reusable widget that displays a label-value row with colored value text.
/// Commonly used for displaying financial summaries.
class SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final TextStyle? labelStyle;
  final TextStyle? valueStyle;

  const SummaryRow({
    super.key,
    required this.label,
    required this.value,
    required this.valueColor,
    this.labelStyle,
    this.valueStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: labelStyle ??
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            value,
            style: valueStyle ??
                TextStyle(
                  color: valueColor,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}
