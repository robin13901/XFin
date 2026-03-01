import 'package:flutter/material.dart';

/// A reusable section title widget with consistent styling
class SectionTitle extends StatelessWidget {
  final String title;
  final TextStyle? style;

  const SectionTitle({
    super.key,
    required this.title,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: style ??
          Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
    );
  }
}

/// A reusable stat tile widget for displaying label-value pairs
class StatTile extends StatelessWidget {
  final String label;
  final String value;
  final TextStyle? labelStyle;
  final TextStyle? valueStyle;

  const StatTile({
    super.key,
    required this.label,
    required this.value,
    this.labelStyle,
    this.valueStyle,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      visualDensity: const VisualDensity(vertical: -3),
      contentPadding: EdgeInsets.zero,
      title: Text(
        label,
        style: labelStyle ?? const TextStyle(fontSize: 16),
      ),
      trailing: Text(
        value,
        style: valueStyle ??
            const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
      ),
    );
  }
}
