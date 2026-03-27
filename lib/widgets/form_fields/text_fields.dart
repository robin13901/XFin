import 'package:flutter/material.dart';
import 'package:xfin/l10n/app_localizations.dart';

import '../../database/app_database.dart';
import '../../database/tables.dart';
import '../../providers/base_currency_provider.dart';
import '../../utils/global_constants.dart';
import '../../utils/validators.dart';

/// Mixin providing text and numeric form fields.
///
/// Includes [sharesField], [sharesAndCostBasisRow], [notesField],
/// [categoryField], [basicTextField], and [numericInputRow].
mixin TextFieldsMixin {
  AppLocalizations get l10n;
  Validator get validator;
  BuildContext get formContext;

  Widget sharesField(TextEditingController controller, Asset? selectedAsset,
      {bool signedShares = true}) {
    final String? sharesSuffix =
        selectedAsset?.currencySymbol ?? selectedAsset?.tickerSymbol;
    return TextFormField(
        key: const Key('shares_field'),
        controller: controller,
        decoration: InputDecoration(
          labelText: selectedAsset?.id == 1 ? l10n.amount : l10n.shares,
          border: const OutlineInputBorder(),
          suffixText: sharesSuffix,
          errorMaxLines: 2,
        ),
        keyboardType: TextInputType.numberWithOptions(
            signed: signedShares, decimal: true),
        validator: (value) => selectedAsset?.type == AssetTypes.fiat
            ? validator.validateMaxTwoDecimalsNotZero(value)
            : validator.validateDecimalNotZero(value));
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
                labelText: l10n.pricePerShare,
                border: const OutlineInputBorder(),
                suffixText: BaseCurrencyProvider.symbol,
                errorMaxLines: 2,
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: (value) =>
                  validator.validateDecimalGreaterZero(value),
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
        labelText: l10n.notes,
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget categoryField(
      TextEditingController controller, List<String> categories,
      {CategoryAutocompleteHelper? cachedHelper}) {
    final helper =
        cachedHelper ?? CategoryAutocompleteHelper(categories, maxResults: 6);

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
            labelText: l10n.category,
            border: const OutlineInputBorder(),
          ),
          validator: validator.validateNotInitial,
          onChanged: (v) => controller.text = v,
          onFieldSubmitted: (v) {
            onSubmit();
            controller.text = v;
          },
        );
      },
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
  ///   suffixText2: 'EUR',
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
}
