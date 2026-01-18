import 'package:flutter/material.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'package:provider/provider.dart';

import '../database/app_database.dart';
import '../database/tables.dart';
import '../l10n/app_localizations.dart';
import '../providers/base_currency_provider.dart';
import '../utils/validators.dart';

class Reusables {
  final AppLocalizations l10n;
  late final Validator validator;
  late final BaseCurrencyProvider currencyProvider;

  Reusables(BuildContext context) : l10n = AppLocalizations.of(context)! {
    validator = Validator(l10n);
    currencyProvider =
        Provider.of<BaseCurrencyProvider>(context, listen: false);
  }

  static Widget buildLiquidGlassFAB(BuildContext context, Future<void> Function() onTap) {
    return Positioned(
      right: 23,
      bottom: 100,
      child: SafeArea(
        child: LiquidGlassLayer(
          settings: const LiquidGlassSettings(
            thickness: 20,
            blur: 1,
            glassColor: Color(0x33595959),
          ),
          child: LiquidGlass(
            shape: const LiquidRoundedSuperellipse(
              borderRadius: 28,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(28),
                onTap: onTap,
                child: const SizedBox(
                  height: 72,
                  width: 72,
                  child: Center(
                    child: Icon(
                      Icons.add,
                      size: 32,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------- Existing helpers (kept + unchanged) ----------
  Widget buildAssetsDropdown(int? assetId, List<Asset> assets,
      ValueChanged<int?> onChanged, String? Function(int?)? validator) {
    return Expanded(
      child: Builder(builder: (context) {
        return DropdownButtonFormField<int>(
          key: const Key('assets_dropdown'),
          initialValue: assetId,
          decoration: InputDecoration(
            labelText: l10n.asset,
            border: const OutlineInputBorder(),
            errorMaxLines: 2,
          ),
          items: assets.map((asset) {
            return DropdownMenuItem(value: asset.id, child: Text(asset.name));
          }).toList(),
          selectedItemBuilder: (context) {
            return assets.map((asset) {
              return Text(
                asset.tickerSymbol,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              );
            }).toList();
          },
          onChanged: onChanged,
          validator: validator,
        );
      }),
    );
  }

  Widget buildSharesInputRow(TextEditingController sharesController,
      TextEditingController costBasisController, Asset? selectedAsset,
      {bool hideCostBasis = false, signedShares = true}) {
    final String? sharesSuffix =
        selectedAsset?.currencySymbol ?? selectedAsset?.tickerSymbol;

    return Row(
      children: [
        Expanded(
          child: TextFormField(
              key: const Key('shares_field'),
              controller: sharesController,
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
                  : validator.validateDecimalNotZero(value)
          ),
        ),
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
              validator: (value) => validator.validateDecimalGreaterZero(value),
            ),
          ),
        ],
      ],
    );
  }

  // ---------- New helpers ----------

  /// Generic enum-like dropdown builder. `display` converts the value to a label.
  Widget buildEnumDropdown<T>({
    required T? initialValue,
    required List<T> values,
    required String label,
    required ValueChanged<T?> onChanged,
    required String Function(T) display,
    String? Function(T?)? validator,
  }) {
    return DropdownButtonFormField<T>(
      initialValue: initialValue,
      decoration:
          InputDecoration(labelText: label, border: const OutlineInputBorder()),
      items: values
          .map((v) => DropdownMenuItem(value: v, child: Text(display(v))))
          .toList(),
      onChanged: onChanged,
      validator: validator,
    );
  }

  // /// Stream-backed accounts dropdown returning account id (used in BookingForm).
  // Widget buildAccountsDropdownFromStream({
  //   required Stream<List<Account>> stream,
  //   required int? initialValue,
  //   required ValueChanged<int?> onChanged,
  //   String? Function(int?)? validator,
  // }) {
  //   return StreamBuilder<List<Account>>(
  //     stream: stream,
  //     builder: (context, snapshot) {
  //       final accounts = snapshot.data ?? [];
  //       return DropdownButtonFormField<int>(
  //         key: const Key('account_dropdown'),
  //         initialValue: initialValue,
  //         decoration: InputDecoration(
  //             labelText: l10n.account, border: const OutlineInputBorder()),
  //         items: accounts
  //             .map((a) => DropdownMenuItem(value: a.id, child: Text(a.name)))
  //             .toList(),
  //         onChanged: onChanged,
  //         validator: validator,
  //       );
  //     },
  //   );
  // }
  //
  // /// List-backed account dropdown returning Account object (used in TradeForm).
  // Widget buildAccountDropdownFromList({
  //   required List<Account> accounts,
  //   required Account? initialValue,
  //   required String label,
  //   required ValueChanged<Account?> onChanged,
  //   String? Function(Account?)? validator,
  // }) {
  //   return DropdownButtonFormField<Account>(
  //     value: initialValue,
  //     decoration:
  //         InputDecoration(labelText: label, border: const OutlineInputBorder()),
  //     items: accounts
  //         .map((a) => DropdownMenuItem(value: a, child: Text(a.name)))
  //         .toList(),
  //     onChanged: onChanged,
  //     validator: validator,
  //   );
  // }
  //
  // /// A date-only field that shows a date picker when tapped.
  // Widget buildDateField({
  //   required TextEditingController controller,
  //   required DateTime selectedDate,
  //   required Future<void> Function() onPick, // call showDatePicker from caller
  //   String label = '',
  //   String? Function(String?)? validator,
  // }) {
  //   return TextFormField(
  //     key: const Key('date_field'),
  //     readOnly: true,
  //     controller: controller,
  //     decoration: InputDecoration(
  //       labelText: label,
  //       border: const OutlineInputBorder(),
  //       suffixIcon: IconButton(
  //         icon: const Icon(Icons.calendar_today),
  //         onPressed: onPick,
  //       ),
  //     ),
  //     validator: validator,
  //   );
  // }
  //
  // /// A date+time field that shows date then time pickers; caller handles controller text & state.
  // Widget buildDateTimeField({
  //   required TextEditingController controller,
  //   required DateTime? selectedDateTime,
  //   required Future<void> Function()
  //       onPick, // caller uses showDatePicker/showTimePicker
  //   String label = '',
  //   String? Function(String?)? validator,
  // }) {
  //   return TextFormField(
  //     controller: controller,
  //     decoration: InputDecoration(
  //       labelText: label,
  //       border: const OutlineInputBorder(),
  //       suffixIcon: const Icon(Icons.calendar_today),
  //     ),
  //     readOnly: true,
  //     onTap: onPick,
  //     validator: validator,
  //   );
  // }
  //
  // /// Builds a small action row with Cancel and a primary button on the right.
  // /// If onCancel is null, the Cancel button is not shown.
  // Widget buildFormActionRow({
  //   VoidCallback? onCancel,
  //   String cancelLabel = 'Cancel',
  //   required VoidCallback onPrimary,
  //   required String primaryLabel,
  // }) {
  //   return Row(
  //     mainAxisAlignment: MainAxisAlignment.end,
  //     children: [
  //       if (onCancel != null)
  //         TextButton(onPressed: onCancel, child: Text(cancelLabel)),
  //       if (onCancel != null) const SizedBox(width: 8),
  //       ElevatedButton(onPressed: onPrimary, child: Text(primaryLabel)),
  //     ],
  //   );
  // }
  //
  // /// Builds the pending-assets list UI used in AccountForm.
  // Widget buildPendingAssetsList({
  //   required List<AssetOnAccount> pending,
  //   required Map<int, Asset> assetMap,
  //   required Function(int index) onDelete,
  //   required BaseCurrencyProvider currencyProvider,
  // }) {
  //   if (pending.isEmpty) {
  //     return Padding(
  //       padding: const EdgeInsets.symmetric(vertical: 8.0),
  //       child: Text(
  //         l10n.noAssetsAddedYet,
  //         style:
  //             const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
  //       ),
  //     );
  //   }
  //
  //   return ListView.builder(
  //     shrinkWrap: true,
  //     physics: const NeverScrollableScrollPhysics(),
  //     itemCount: pending.length,
  //     itemBuilder: (context, index) {
  //       final item = pending[index];
  //       final asset = assetMap[item.assetId];
  //       final oneLine =
  //           '${item.sharesOwned} ${asset?.tickerSymbol} @ ${item.netCostBasis} ${currencyProvider.symbol} ≈ ${currencyProvider.format.format(item.value)}';
  //
  //       return ListTile(
  //         contentPadding: EdgeInsets.zero,
  //         title: Text(
  //           oneLine,
  //           style: const TextStyle(
  //               fontStyle: FontStyle.italic, color: Colors.grey),
  //           maxLines: 1,
  //           overflow: TextOverflow.ellipsis,
  //         ),
  //         trailing: IconButton(
  //           icon: const Icon(Icons.delete, color: Colors.grey),
  //           onPressed: () => onDelete(index),
  //         ),
  //       );
  //     },
  //   );
  // }
  //
  // /// Builds a row with ticker symbol (mandatory) and optional currency symbol (shown only for currency/crypto)
  // Widget buildTickerAndCurrencyRow(TextEditingController tickerController,
  //     TextEditingController currencyController, AssetTypes type) {
  //   return Row(
  //     children: [
  //       Expanded(
  //         child: TextFormField(
  //           key: const Key('ticker_symbol_field'),
  //           controller: tickerController,
  //           textCapitalization: TextCapitalization.characters,
  //           decoration: InputDecoration(
  //             labelText: l10n.tickerSymbol,
  //             border: const OutlineInputBorder(),
  //           ),
  //           validator: (_) => validator.validateIsUnique(
  //               tickerController.text, []), // caller can override if needed
  //         ),
  //       ),
  //       if (type == AssetTypes.currency || type == AssetTypes.crypto) ...[
  //         const SizedBox(width: 16),
  //         Expanded(
  //           child: TextFormField(
  //             key: const Key('currency_symbol_field'),
  //             controller: currencyController,
  //             textCapitalization: TextCapitalization.characters,
  //             decoration: InputDecoration(
  //               labelText: l10n.currencySymbol,
  //               border: const OutlineInputBorder(),
  //             ),
  //             validator: (_) =>
  //                 validator.validateCurrencySymbol(currencyController.text),
  //           ),
  //         ),
  //       ],
  //     ],
  //   );
  // }
}
