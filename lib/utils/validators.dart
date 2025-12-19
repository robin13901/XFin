import 'package:xfin/database/tables.dart';

import '../l10n/app_localizations.dart';

class Validator {
  AppLocalizations l10n;

  Validator(this.l10n);

  String? validateNotInitial(String? value) {
    if (value == null || value.trim().isEmpty) return l10n.requiredField;
    return null;
  }

  String? validateDecimal(String? value) {
    if (validateNotInitial(value) case String error) return error;
    if (double.tryParse(value!) == null) return l10n.invalidInput;
    return null;
  }

  String? validateDecimalGreaterZero(String? value) {
    if (validateDecimal(value) case String error) return error;
    if (double.parse(value!) <= 0) return l10n.valueMustBeGreaterZero;
    return null;
  }

  String? validateDecimalNotZero(String? value) {
    if (validateDecimal(value) case String error) return error;
    if (double.parse(value!) == 0) return l10n.valueMustNotBeZero;
    return null;
  }

  String? validateDecimalGreaterEqualZero(String? value) {
    if (validateDecimal(value) case String error) return error;
    if (double.parse(value!) < 0) return l10n.valueMustBeGreaterEqualZero;
    return null;
  }

  String? validateMaxTwoDecimals(String? value) {
    if (validateDecimal(value) case String error) return error;
    if (value!.contains('.') && value.split('.')[1].length > 2) {
      return l10n.tooManyDecimalPlaces;
    }
    return null;
  }

  String? validateMaxTwoDecimalsNotZero(String? value) {
    if (validateMaxTwoDecimals(value) case String error) return error;
    if (double.parse(value!) == 0) return l10n.valueCannotBeZero;
    return null;
  }

  String? validateMaxTwoDecimalsGreaterZero(String? value) {
    if (validateDecimalGreaterZero(value) case String error) return error;
    if (value!.contains('.') && value.split('.')[1].length > 2) {
      return l10n.tooManyDecimalPlaces;
    }
    return null;
  }

  String? validateMaxTwoDecimalsGreaterEqualZero(String? value) {
    if (validateDecimalGreaterEqualZero(value) case String error) return error;
    if (value!.contains('.') && value.split('.')[1].length > 2) {
      return l10n.tooManyDecimalPlaces;
    }
    return null;
  }

  String? validateSufficientSharesToSell(
      String? value, double ownedShares, TradeTypes? tradeType) {
    if (validateDecimalGreaterZero(value) case String error) return error;

    if (tradeType == TradeTypes.sell) {
      final sharesToBeSold = double.parse(value!);
      if (ownedShares < sharesToBeSold) return l10n.insufficientShares;
    }

    return null;
  }

  String? validateIsUnique(
      String? value, List<String> existingValues) {
    if (validateNotInitial(value) case String error) return error;
    if (existingValues.contains(value!.trim())) {
      return l10n.valueAlreadyExists;
    }
    return null;
  }

  String? validateAccountSelected(int? accountId) {
    return accountId == null ? l10n.pleaseSelectAnAccount : null;
  }

  String? validateDate(DateTime? value) {
    if (value == null) return l10n.requiredField;
    if (value.isAfter(DateTime.now())) return l10n.dateCannotBeInTheFuture;
    return null;
  }

}
