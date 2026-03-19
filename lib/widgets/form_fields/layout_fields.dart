import 'package:flutter/material.dart';
import 'package:xfin/l10n/app_localizations.dart';

import '../../utils/validators.dart';

/// Mixin providing layout and miscellaneous form fields.
///
/// Includes [footerButtons] for cancel/save buttons and
/// [checkboxField] for boolean toggles.
mixin LayoutFieldsMixin {
  AppLocalizations get l10n;
  Validator get validator;
  BuildContext get formContext;

  Widget footerButtons(BuildContext context, void Function()? onPressed, {int? stepId}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: onPressed,
          child: Text(l10n.save),
        ),
      ],
    );
  }

  /// Checkbox field with consistent styling.
  ///
  /// Creates a CheckboxListTile with zero padding and leading control affinity.
  /// Used for boolean flags like "Exclude from Average" or "Is Generated" in BookingForm.
  ///
  /// Example:
  /// ```dart
  /// _formFields.checkboxField(
  ///   label: 'Exclude from Average',
  ///   value: _excludeFromAverage,
  ///   onChanged: (val) => setState(() => _excludeFromAverage = val ?? false),
  /// )
  /// ```
  Widget checkboxField({
    required String label,
    required bool value,
    required ValueChanged<bool?> onChanged,
    Key? key,
  }) {
    return CheckboxListTile(
      key: key,
      title: Text(label),
      value: value,
      onChanged: onChanged,
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
    );
  }
}

/// Isolates the [MediaQuery.viewInsetsOf] dependency so only this widget
/// — not the entire form tree — rebuilds on each keyboard-animation frame.
///
/// Wrap the outermost widget of every bottom-sheet form with this instead
/// of `Padding(padding: MediaQuery.of(context).viewInsets, …)`.
class BottomInsetPadding extends StatelessWidget {
  final Widget child;
  const BottomInsetPadding({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: child,
    );
  }
}
