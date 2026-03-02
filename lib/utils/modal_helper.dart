import 'package:flutter/material.dart';

/// Helper function to show a modal bottom sheet with a form widget.
///
/// This provides a consistent way to display forms across the app.
///
/// Returns a Future that completes with the result when the sheet is dismissed.
Future<T?> showFormModal<T>(
  BuildContext context,
  Widget formWidget,
) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    builder: (_) => formWidget,
  );
}
