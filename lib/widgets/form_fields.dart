import 'package:flutter/material.dart';
import 'package:xfin/l10n/app_localizations.dart';
import 'package:xfin/utils/format.dart';

import '../database/app_database.dart';
import '../database/tables.dart';
import '../providers/base_currency_provider.dart';
import '../utils/date_picker_locale.dart';
import '../utils/global_constants.dart';
import '../utils/validators.dart';

class FormFields {
  final AppLocalizations _l10n;
  final Validator _validator;
  final BuildContext _context;

  FormFields(this._l10n, this._validator, this._context);

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
        context: _context,
        locale: resolveDatePickerLocale(Localizations.localeOf(_context)),
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
              labelText: dateLabel ?? _l10n.date,
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: const Icon(Icons.calendar_today),
                onPressed: pickDate,
              ),
            ),
            validator: (_) {
              if (customDateValidator != null) return customDateValidator(date);
              return _validator.validateDateNotInFuture(date);
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

  Widget sharesField(TextEditingController controller, Asset? selectedAsset,
      {bool signedShares = true}) {
    final String? sharesSuffix =
        selectedAsset?.currencySymbol ?? selectedAsset?.tickerSymbol;
    return TextFormField(
        key: const Key('shares_field'),
        controller: controller,
        decoration: InputDecoration(
          labelText: selectedAsset?.id == 1 ? _l10n.amount : _l10n.shares,
          border: const OutlineInputBorder(),
          suffixText: sharesSuffix,
          errorMaxLines: 2,
        ),
        keyboardType: TextInputType.numberWithOptions(
            signed: signedShares, decimal: true),
        validator: (value) => selectedAsset?.type == AssetTypes.fiat
            ? _validator.validateMaxTwoDecimalsNotZero(value)
            : _validator.validateDecimalNotZero(value));
  }

  Widget sharesAndCostBasisRow(TextEditingController sharesController,
      TextEditingController costBasisController, Asset? selectedAsset,
      {bool hideCostBasis = false, signedShares = true}) {
    return Row(
      children: [
        Expanded(
            child: sharesField(sharesController, selectedAsset,
                signedShares: signedShares)),
        if (selectedAsset?.id != 1 && !hideCostBasis) ...[
          const SizedBox(width: 16),
          Expanded(
            child: TextFormField(
              key: const Key('cost_basis_field'),
              controller: costBasisController,
              decoration: InputDecoration(
                labelText: _l10n.pricePerShare,
                border: const OutlineInputBorder(),
                suffixText: BaseCurrencyProvider.symbol,
                errorMaxLines: 2,
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: (value) =>
                  _validator.validateDecimalGreaterZero(value),
            ),
          ),
        ],
      ],
    );
  }

  Widget notesField(TextEditingController controller) {
    return TextFormField(
      controller: controller,
      textCapitalization: TextCapitalization.words,
      decoration: InputDecoration(
        labelText: _l10n.notes,
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget categoryField(
      TextEditingController controller, List<String> categories) {
    final helper = CategoryAutocompleteHelper(categories, maxResults: 6);

    return Autocomplete<String>(
      key: const Key('category_field'),
      optionsBuilder: (v) => helper.suggestions(v.text),
      onSelected: (s) => controller.text = s,
      fieldViewBuilder: (_, tCtrl, node, onSubmit) {
        if (tCtrl.text != controller.text) {
          tCtrl.value = tCtrl.value.copyWith(
            text: controller.text,
            selection: TextSelection.collapsed(
              offset: controller.text.length,
            ),
          );
        }

        return TextFormField(
          controller: tCtrl,
          focusNode: node,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: _l10n.category,
            border: const OutlineInputBorder(),
          ),
          validator: _validator.validateNotInitial,
          onChanged: (v) => controller.text = v,
          onFieldSubmitted: (v) {
            onSubmit();
            controller.text = v;
          },
        );
      },
    );
  }

  Widget accountDropdown({
    required List<Account> accounts,
    required int? value,
    required void Function(int?)? onChanged,
    Key? key,
    bool enabled = true,
    String? label,
    String? Function(Account?)? customValidator,
  }) {
    return DropdownButtonFormField<int>(
      key: key,
      initialValue: value,
      decoration: InputDecoration(
        labelText: label ?? _l10n.account,
        enabled: enabled,
        border: const OutlineInputBorder(),
      ),
      items: accounts
          .map((a) => DropdownMenuItem(value: a.id, child: Text(a.name)))
          .toList(),
      onChanged: enabled ? onChanged : null,
      validator: (_) {
        if (customValidator != null && value != null) {
          Account account = accounts.firstWhere((a) => a.id == value);
          return customValidator(account);
        }
        return _validator.validateAccountSelected(_);
      },
    );
  }

  Widget assetsDropdown({
    required List<Asset> assets,
    required int? value,
    required void Function(int?)? onChanged,
    Key? key,
    bool enabled = true,
    String? label,
  }) {
    return DropdownButtonFormField<int>(
      key: const Key('assets_dropdown'),
      isExpanded: true,
      initialValue: value,
      decoration: InputDecoration(
        labelText: label ?? _l10n.asset,
        enabled: enabled,
        border: const OutlineInputBorder(),
      ),
      items: assets
          .map((a) => DropdownMenuItem(value: a.id, child: Text(a.name)))
          .toList(),
      onChanged: enabled ? onChanged : null,
      validator: _validator.validateAssetSelected,
    );
  }

  Widget cyclesDropdown({
    required List<Cycles> cycles,
    required int? value,
    required void Function(int?)? onChanged,
  }) {
    String cycleText(Cycles c) {
      switch (c) {
        case Cycles.daily:
          return _l10n.daily;
        case Cycles.weekly:
          return _l10n.weekly;
        case Cycles.monthly:
          return _l10n.monthly;
        case Cycles.quarterly:
          return _l10n.quarterly;
        case Cycles.yearly:
          return _l10n.yearly;
      }
    }

    return DropdownButtonFormField<int>(
      key: const Key('cycles_dropdown'),
      isExpanded: true,
      initialValue: value,
      decoration: InputDecoration(
        labelText: _l10n.cycle,
        border: const OutlineInputBorder(),
      ),
      items: cycles
          .map((v) => DropdownMenuItem(value: cycles.indexOf(v), child: Text(cycleText(v))))
          .toList(),
      onChanged: onChanged,
      validator: _validator.validateCycleSelected,
    );
  }

  Widget footerButtons(BuildContext context, void Function()? onPressed, {int? stepId}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(_l10n.cancel),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: onPressed,
          child: Text(_l10n.save),
        ),
      ],
    );
  }

  /// Generic text input field for simple text inputs.
  ///
  /// Used for: asset name, account name, ticker symbol, currency symbol, notes.
  ///
  /// Example:
  /// ```dart
  /// _formFields.basicTextField(
  ///   controller: _nameController,
  ///   label: 'Name',
  ///   validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
  /// )
  /// ```
  Widget basicTextField({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
    TextCapitalization textCapitalization = TextCapitalization.none,
    Key? key,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? suffixText,
  }) {
    return TextFormField(
      key: key,
      controller: controller,
      textCapitalization: textCapitalization,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        suffixText: suffixText,
      ),
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
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
        context: _context,
        locale: resolveDatePickerLocale(Localizations.localeOf(_context)),
        initialDate: datetime,
        firstDate: DateTime(2000),
        lastDate: DateTime.now(),
      );
      if (pickedDate != null) {
        if (!_context.mounted) return;
        final pickedTime = await showTimePicker(
          context: _context,
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
        labelText: label ?? _l10n.datetime,
        border: const OutlineInputBorder(),
        suffixIcon: const Icon(Icons.calendar_today),
      ),
      readOnly: true,
      onTap: pickDateTime,
      validator: (_) {
        if (validator != null) return validator(datetime);
        return _validator.validateDateNotInFuture(datetime);
      },
    );
  }

  /// Two numeric input fields side by side.
  ///
  /// Used for pairs like shares+fee, cost+tax in TradeForm.
  ///
  /// Example:
  /// ```dart
  /// _formFields.numericInputRow(
  ///   controller1: _sharesController,
  ///   label1: 'Shares',
  ///   validator1: (v) => _validator.validateDecimal(v),
  ///   suffixText1: 'AAPL',
  ///   controller2: _feeController,
  ///   label2: 'Fee',
  ///   validator2: (v) => _validator.validateDecimalGreaterEqualZero(v),
  ///   suffixText2: '€',
  /// )
  /// ```
  Widget numericInputRow({
    required TextEditingController controller1,
    required String label1,
    required String? Function(String?) validator1,
    required TextEditingController controller2,
    required String label2,
    required String? Function(String?) validator2,
    String? suffixText1,
    String? suffixText2,
    bool signed1 = false,
    bool signed2 = false,
    Key? key1,
    Key? key2,
  }) {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            key: key1,
            controller: controller1,
            decoration: InputDecoration(
              labelText: label1,
              border: const OutlineInputBorder(),
              suffixText: suffixText1,
            ),
            keyboardType: TextInputType.numberWithOptions(
              decimal: true,
              signed: signed1,
            ),
            validator: validator1,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: TextFormField(
            key: key2,
            controller: controller2,
            decoration: InputDecoration(
              labelText: label2,
              border: const OutlineInputBorder(),
              suffixText: suffixText2,
            ),
            keyboardType: TextInputType.numberWithOptions(
              decimal: true,
              signed: signed2,
            ),
            validator: validator2,
          ),
        ),
      ],
    );
  }

  /// Dropdown for selecting account type (Cash, Bank Account, Portfolio, Crypto Wallet).
  ///
  /// Used in AccountForm for choosing the type of account being created.
  ///
  /// Example:
  /// ```dart
  /// _formFields.accountTypeDropdown(
  ///   value: _selectedType,
  ///   onChanged: (type) => setState(() => _selectedType = type),
  /// )
  /// ```
  Widget accountTypeDropdown({
    required AccountTypes value,
    required ValueChanged<AccountTypes?> onChanged,
    bool enabled = true,
    Key? key,
  }) {
    String typeText(AccountTypes type) {
      switch (type) {
        case AccountTypes.cash:
          return _l10n.cash;
        case AccountTypes.bankAccount:
          return _l10n.bankAccount;
        case AccountTypes.portfolio:
          return _l10n.portfolio;
        case AccountTypes.cryptoWallet:
          return _l10n.cryptoWallet;
      }
    }

    return DropdownButtonFormField<AccountTypes>(
      key: key ?? const Key('account_type_dropdown'),
      initialValue: value,
      decoration: InputDecoration(
        labelText: _l10n.type,
        enabled: enabled,
        border: const OutlineInputBorder(),
      ),
      items: AccountTypes.values
          .map((type) => DropdownMenuItem(
                value: type,
                child: Text(typeText(type)),
              ))
          .toList(),
      onChanged: enabled ? onChanged : null,
    );
  }

  /// Dropdown for selecting asset type (Stock, Fiat Currency, Cryptocurrency).
  ///
  /// Used in AssetForm for choosing the type of asset being created.
  ///
  /// Example:
  /// ```dart
  /// _formFields.assetTypeDropdown(
  ///   value: _selectedAssetType,
  ///   onChanged: (type) => setState(() => _selectedAssetType = type),
  /// )
  /// ```
  Widget assetTypeDropdown({
    required AssetTypes value,
    required ValueChanged<AssetTypes?> onChanged,
    Key? key,
  }) {
    return DropdownButtonFormField<AssetTypes>(
      key: key ?? const Key('asset_type_dropdown'),
      initialValue: value,
      decoration: InputDecoration(
        labelText: _l10n.type,
        border: const OutlineInputBorder(),
      ),
      items: AssetTypes.values
          .map((type) => DropdownMenuItem(
                value: type,
                child: Text(getAssetTypeName(_l10n, type)),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }

  /// Dropdown for selecting trade type (Buy or Sell).
  ///
  /// Used in TradeForm for choosing whether the trade is a buy or sell operation.
  ///
  /// Example:
  /// ```dart
  /// _formFields.tradeTypeDropdown(
  ///   value: _tradeType,
  ///   onChanged: (type) => setState(() => _tradeType = type),
  ///   enabled: !_isEditing,
  /// )
  /// ```
  Widget tradeTypeDropdown({
    required TradeTypes? value,
    required ValueChanged<TradeTypes?> onChanged,
    bool enabled = true,
    Key? key,
  }) {
    return DropdownButtonFormField<TradeTypes>(
      key: key ?? const Key('trade_type_dropdown'),
      initialValue: value,
      decoration: InputDecoration(
        labelText: _l10n.type,
        enabled: enabled,
        border: const OutlineInputBorder(),
      ),
      items: TradeTypes.values
          .map((type) => DropdownMenuItem(
                value: type,
                child: Text(type.name),
              ))
          .toList(),
      onChanged: enabled ? onChanged : null,
      validator: (value) => value == null ? _l10n.pleaseSelectAType : null,
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
