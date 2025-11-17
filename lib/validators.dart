import 'package:xfin/database/tables.dart';

import 'l10n/app_localizations.dart';

class Validator {
  AppLocalizations l10n;
  
  Validator(this.l10n);
  
  String? validateNotInitial(String? value) {
    if (value == null || value.isEmpty) return l10n.pleaseEnterAValue;
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

  String? validateDecimalGreaterEqualZero(String? value) {
    if (validateDecimal(value) case String error) return error;
    if (double.parse(value!) < 0) return l10n.valueMustBeGreaterEqualZero;
    return null;
  }

  String? validateMaxTwoDecimals(String? value) {
    if (validateDecimal(value) case String error) return error;
    if (value!.contains('.') && value.split('.')[1].length > 2) return l10n.tooManyDecimalPlaces;
    return null;
  }

  String? validateMaxTwoDecimalsGreaterZero(String? value) {
    if (validateDecimalGreaterZero(value) case String error) return error;
    if (value!.contains('.') && value.split('.')[1].length > 2) return l10n.tooManyDecimalPlaces;
    return null;
  }

  String? validateMaxTwoDecimalsGreaterEqualZero(String? value) {
    if (validateDecimalGreaterEqualZero(value) case String error) return error;
    if (value!.contains('.') && value.split('.')[1].length > 2) return l10n.tooManyDecimalPlaces;
    return null;
  }

  String? validateSufficientSharesToSell(String? value, double ownedShares, TradeTypes? tradeType) {
    if (validateDecimalGreaterZero(value) case String error) return error;

    if (tradeType == TradeTypes.sell) {
      final sharesToBeSold = double.parse(value!);
      if (ownedShares < sharesToBeSold) return l10n.insufficientShares;
    }

    return null;
  }
}