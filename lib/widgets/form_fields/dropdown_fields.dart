import 'package:flutter/material.dart';
import 'package:xfin/l10n/app_localizations.dart';
import 'package:xfin/utils/format.dart';

import '../../database/app_database.dart';
import '../../database/tables.dart';
import '../../utils/validators.dart';

/// Mixin providing dropdown form fields.
///
/// Includes account, asset, cycle, account type, asset type, and trade type
/// dropdowns.
mixin DropdownFieldsMixin {
  AppLocalizations get l10n;
  Validator get validator;
  BuildContext get formContext;

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
        labelText: label ?? l10n.account,
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
        return validator.validateAccountSelected(_);
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
        labelText: label ?? l10n.asset,
        enabled: enabled,
        border: const OutlineInputBorder(),
      ),
      items: assets
          .map((a) => DropdownMenuItem(value: a.id, child: Text(a.name)))
          .toList(),
      onChanged: enabled ? onChanged : null,
      validator: validator.validateAssetSelected,
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
          return l10n.daily;
        case Cycles.weekly:
          return l10n.weekly;
        case Cycles.monthly:
          return l10n.monthly;
        case Cycles.quarterly:
          return l10n.quarterly;
        case Cycles.yearly:
          return l10n.yearly;
      }
    }

    return DropdownButtonFormField<int>(
      key: const Key('cycles_dropdown'),
      isExpanded: true,
      initialValue: value,
      decoration: InputDecoration(
        labelText: l10n.cycle,
        border: const OutlineInputBorder(),
      ),
      items: cycles
          .map((v) => DropdownMenuItem(value: cycles.indexOf(v), child: Text(cycleText(v))))
          .toList(),
      onChanged: onChanged,
      validator: validator.validateCycleSelected,
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
          return l10n.cash;
        case AccountTypes.bankAccount:
          return l10n.bankAccount;
        case AccountTypes.portfolio:
          return l10n.portfolio;
        case AccountTypes.cryptoWallet:
          return l10n.cryptoWallet;
      }
    }

    return DropdownButtonFormField<AccountTypes>(
      key: key ?? const Key('account_type_dropdown'),
      initialValue: value,
      decoration: InputDecoration(
        labelText: l10n.type,
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
        labelText: l10n.type,
        border: const OutlineInputBorder(),
      ),
      items: AssetTypes.values
          .map((type) => DropdownMenuItem(
                value: type,
                child: Text(getAssetTypeName(l10n, type)),
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
        labelText: l10n.type,
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
      validator: (value) => value == null ? l10n.pleaseSelectAType : null,
    );
  }
}
