import 'package:flutter/material.dart';
import 'package:xfin/l10n/app_localizations.dart';
import 'package:xfin/utils/format.dart';

import '../../database/app_database.dart';
import '../../utils/date_picker_locale.dart';
import '../../utils/validators.dart';

/// Mixin providing date-related form fields.
///
/// Includes [dateAndAssetRow] for combined date + asset selection,
/// and [dateTimeField] for date-time picking.
mixin DateFieldsMixin {
  AppLocalizations get l10n;
  Validator get validator;
  BuildContext get formContext;

  /// Abstract declaration so [dateAndAssetRow] can call the concrete
  /// implementation provided by [DropdownFieldsMixin].
  Widget assetsDropdown({
    required List<Asset> assets,
    required int? value,
    required void Function(int?)? onChanged,
    Key? key,
    bool enabled = true,
    String? label,
  });

  Widget dateAndAssetRow({
    required TextEditingController dateController,
    required DateTime date,
    required ValueChanged<DateTime> onDateChanged,
    required List<Asset> assets,
    required int? assetId,
    void Function(int?)? onAssetChanged,
    String? Function(DateTime?)? customDateValidator,
    String? dateLabel,
    bool assetsEditable = true,
  }) {
    Future<void> pickDate() async {
      final picked = await showDatePicker(
        context: formContext,
        locale: resolveDatePickerLocale(Localizations.localeOf(formContext)),
        initialDate: date,
        firstDate: DateTime(2000),
        lastDate: DateTime(2101),
      );
      if (picked == null || picked == date) return;
      dateController.text = dateFormat.format(picked);
      onDateChanged(picked);
    }

    return Row(
      children: [
        Expanded(
          child: TextFormField(
            readOnly: true,
            key: const Key('date_field'),
            controller: dateController,
            decoration: InputDecoration(
              labelText: dateLabel ?? l10n.date,
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: const Icon(Icons.calendar_today),
                onPressed: pickDate,
              ),
            ),
            validator: (_) {
              if (customDateValidator != null) return customDateValidator(date);
              return validator.validateDateNotInFuture(date);
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: assetsDropdown(
              assets: assets, value: assetId, onChanged: onAssetChanged, enabled: assetsEditable),
        ),
      ],
    );
  }

  /// Date and time picker field.
  ///
  /// Opens a date picker followed by a time picker when tapped.
  /// Used in TradeForm for recording precise transaction times.
  ///
  /// Example:
  /// ```dart
  /// _formFields.dateTimeField(
  ///   controller: _dateTimeController,
  ///   datetime: _selectedDateTime,
  ///   onChanged: (dt) => setState(() => _selectedDateTime = dt),
  /// )
  /// ```
  Widget dateTimeField({
    required TextEditingController controller,
    required DateTime datetime,
    required ValueChanged<DateTime> onChanged,
    String? Function(DateTime?)? validator,
    String? label,
    Key? key,
  }) {
    Future<void> pickDateTime() async {
      final pickedDate = await showDatePicker(
        context: formContext,
        locale: resolveDatePickerLocale(Localizations.localeOf(formContext)),
        initialDate: datetime,
        firstDate: DateTime(2000),
        lastDate: DateTime.now(),
      );
      if (pickedDate != null) {
        if (!formContext.mounted) return;
        final pickedTime = await showTimePicker(
          context: formContext,
          initialTime: TimeOfDay.fromDateTime(datetime),
        );
        if (pickedTime != null) {
          final picked = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
          if (picked != datetime) {
            controller.text = dateTimeFormat.format(picked);
            onChanged(picked);
          }
        }
      }
    }

    return TextFormField(
      key: key,
      controller: controller,
      decoration: InputDecoration(
        labelText: label ?? l10n.datetime,
        border: const OutlineInputBorder(),
        suffixIcon: const Icon(Icons.calendar_today),
      ),
      readOnly: true,
      onTap: pickDateTime,
      validator: (_) {
        if (validator != null) return validator(datetime);
        return this.validator.validateDateNotInFuture(datetime);
      },
    );
  }
}
