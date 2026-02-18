import 'package:flutter/material.dart';
import 'package:xfin/l10n/app_localizations.dart';
import 'package:xfin/utils/format.dart';

import '../database/app_database.dart';
import '../database/tables.dart';
import '../providers/base_currency_provider.dart';
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
          initialDate: date,
          firstDate: DateTime(2000),
          lastDate: DateTime(2101));
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
      onChanged: onChanged,
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
}
