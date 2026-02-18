import 'dart:ui';

import 'package:test/test.dart';

import 'package:xfin/l10n/app_localizations.dart';
import 'package:xfin/database/tables.dart';
import 'package:xfin/utils/validators.dart';

void main() {
  late Validator validator;
  late AppLocalizations l10n;

  setUp(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
    validator = Validator(l10n);
  });

  group('validateNotInitial', () {
    test('returns error when value is null', () {
      expect(validator.validateNotInitial(null), l10n.requiredField);
    });

    test('returns error when value is empty string or whitespace', () {
      expect(validator.validateNotInitial(''), l10n.requiredField);
      expect(validator.validateNotInitial(' '), l10n.requiredField);
    });

    test('returns null when value is non-empty', () {
      expect(validator.validateNotInitial('0'), isNull);
      expect(validator.validateNotInitial('some text'), isNull);
    });
  });

  group('validateDecimal', () {
    test('propagates not-initial error (null)', () {
      expect(validator.validateDecimal(null), l10n.requiredField);
    });

    test('propagates not-initial error (empty or whitespace)', () {
      expect(validator.validateDecimal(''), l10n.requiredField);
      expect(validator.validateDecimal(' '), l10n.requiredField);
    });

    test('returns invalidInput for non-numeric string', () {
      expect(validator.validateDecimal('abc'), l10n.invalidInput);
      expect(validator.validateDecimal('12a'), l10n.invalidInput);
      expect(validator.validateDecimal('1,23'),
          l10n.invalidInput); // comma not accepted by double.parse
    });

    test('accepts valid decimals and integers', () {
      expect(validator.validateDecimal('0'), isNull);
      expect(validator.validateDecimal('123'), isNull);
      expect(validator.validateDecimal('123.45'), isNull);
      expect(validator.validateDecimal('-12.3'), isNull);
      expect(validator.validateDecimal('1e3'),
          isNull); // scientific notation ok for double.tryParse
    });
  });

  group('validateDecimalGreaterZero', () {
    test('propagates decimal errors (null)', () {
      expect(validator.validateDecimalGreaterZero(null), l10n.requiredField);
    });

    test('propagates decimal errors (non-numeric)', () {
      expect(validator.validateDecimalGreaterZero('foo'), l10n.invalidInput);
    });

    test('returns error when value is zero or less', () {
      expect(validator.validateDecimalGreaterZero('0'),
          l10n.valueMustBeGreaterZero);
      expect(validator.validateDecimalGreaterZero('-0.0001'),
          l10n.valueMustBeGreaterZero);
      expect(validator.validateDecimalGreaterZero('-5'),
          l10n.valueMustBeGreaterZero);
    });

    test('accepts positive numbers', () {
      expect(validator.validateDecimalGreaterZero('0.0000001'), isNull);
      expect(validator.validateDecimalGreaterZero('1'), isNull);
      expect(validator.validateDecimalGreaterZero('100.5'), isNull);
    });
  });

  group('validateDecimalGreaterEqualZero', () {
    test('propagates decimal errors', () {
      expect(
          validator.validateDecimalGreaterEqualZero(null), l10n.requiredField);
      expect(
          validator.validateDecimalGreaterEqualZero('nope'), l10n.invalidInput);
    });

    test('returns error for negative values', () {
      expect(validator.validateDecimalGreaterEqualZero('-0.0001'),
          l10n.valueMustBeGreaterEqualZero);
      expect(validator.validateDecimalGreaterEqualZero('-10'),
          l10n.valueMustBeGreaterEqualZero);
    });

    test('accepts zero and positive values', () {
      expect(validator.validateDecimalGreaterEqualZero('0'), isNull);
      expect(validator.validateDecimalGreaterEqualZero('10'), isNull);
      expect(validator.validateDecimalGreaterEqualZero('3.14'), isNull);
    });
  });

  group('validateDecimalNotZero', () {
    test('propagates not-initial error (null/empty/whitespace)', () {
      expect(validator.validateDecimalNotZero(null), l10n.requiredField);
      expect(validator.validateDecimalNotZero(''), l10n.requiredField);
      expect(validator.validateDecimalNotZero(' '), l10n.requiredField);
    });

    test('returns invalidInput for non-numeric strings', () {
      expect(validator.validateDecimalNotZero('abc'), l10n.invalidInput);
      expect(validator.validateDecimalNotZero('12a'), l10n.invalidInput);
      expect(validator.validateDecimalNotZero('1,23'),
          l10n.invalidInput); // comma not accepted by double.parse
    });

    test('returns error for zero (including -0 variants)', () {
      expect(validator.validateDecimalNotZero('0'), l10n.valueMustNotBeZero);
      expect(validator.validateDecimalNotZero('0.0'), l10n.valueMustNotBeZero);
      expect(validator.validateDecimalNotZero('-0'), l10n.valueMustNotBeZero);
      expect(
          validator.validateDecimalNotZero('-0.00'), l10n.valueMustNotBeZero);
    });

    test('accepts non-zero numbers (positive, negative, scientific)', () {
      expect(validator.validateDecimalNotZero('0.0001'), isNull);
      expect(validator.validateDecimalNotZero('1'), isNull);
      expect(validator.validateDecimalNotZero('-1.2'), isNull);
      expect(validator.validateDecimalNotZero('1e3'),
          isNull); // scientific notation
    });
  });

  group('validateMaxTwoDecimals', () {
    test('propagates decimal errors', () {
      expect(validator.validateMaxTwoDecimals(null), l10n.requiredField);
      expect(validator.validateMaxTwoDecimals('bad'), l10n.invalidInput);
    });

    test('accepts integers and decimals with up to 2 decimal places', () {
      expect(validator.validateMaxTwoDecimals('1'), isNull);
      expect(validator.validateMaxTwoDecimals('1.0'), isNull);
      expect(validator.validateMaxTwoDecimals('1.00'), isNull);
      expect(validator.validateMaxTwoDecimals('123.45'), isNull);
      expect(validator.validateMaxTwoDecimals('0.5'), isNull);
    });

    test('rejects numbers with more than 2 decimal places', () {
      expect(
          validator.validateMaxTwoDecimals('1.234'), l10n.tooManyDecimalPlaces);
      expect(
          validator.validateMaxTwoDecimals('0.001'), l10n.tooManyDecimalPlaces);
      expect(validator.validateMaxTwoDecimals('10.9999'),
          l10n.tooManyDecimalPlaces);
    });

    test('handles values without any decimal point (no crash)', () {
      expect(validator.validateMaxTwoDecimals('1000'), isNull);
    });
  });

  group('validateMaxTwoDecimalsNotZero', () {
    test('propagates decimal errors', () {
      expect(validator.validateMaxTwoDecimalsNotZero(null), l10n.requiredField);
      expect(validator.validateMaxTwoDecimalsNotZero('bad'), l10n.invalidInput);
    });

    test('rejects numbers with more than 2 decimals even if <> 0', () {
      expect(validator.validateMaxTwoDecimalsNotZero('1.234'),
          l10n.tooManyDecimalPlaces);
      expect(validator.validateMaxTwoDecimalsNotZero('-2.999'),
          l10n.tooManyDecimalPlaces);
    });

    test('rejects numbers equal to 0', () {
      expect(
          validator.validateMaxTwoDecimalsNotZero('0'), l10n.valueCannotBeZero);
      expect(validator.validateMaxTwoDecimalsNotZero('-0.00'),
          l10n.valueCannotBeZero);
    });

    test('accepts non-zero numbers with up to 2 decimals', () {
      expect(validator.validateMaxTwoDecimalsNotZero('0.01'), isNull);
      expect(validator.validateMaxTwoDecimalsNotZero('-1.2'), isNull);
      expect(validator.validateMaxTwoDecimalsNotZero('5'), isNull);
    });
  });

  group('validateMaxTwoDecimalsGreaterZero', () {
    test('propagates greater-zero errors', () {
      expect(validator.validateMaxTwoDecimalsGreaterZero(null),
          l10n.requiredField);
      expect(validator.validateMaxTwoDecimalsGreaterZero('bad'),
          l10n.invalidInput);
      expect(validator.validateMaxTwoDecimalsGreaterZero('0'),
          l10n.valueMustBeGreaterZero); // zero not allowed
    });

    test('rejects numbers with more than 2 decimals even if > 0', () {
      expect(validator.validateMaxTwoDecimalsGreaterZero('1.234'),
          l10n.tooManyDecimalPlaces);
      expect(validator.validateMaxTwoDecimalsGreaterZero('2.999'),
          l10n.tooManyDecimalPlaces);
    });

    test('accepts positive numbers with up to 2 decimals', () {
      expect(validator.validateMaxTwoDecimalsGreaterZero('0.01'), isNull);
      expect(validator.validateMaxTwoDecimalsGreaterZero('1.2'), isNull);
      expect(validator.validateMaxTwoDecimalsGreaterZero('5'), isNull);
    });
  });

  group('validateMaxTwoDecimalsGreaterEqualZero', () {
    test('propagates greater-equal-zero errors', () {
      expect(validator.validateMaxTwoDecimalsGreaterEqualZero(null),
          l10n.requiredField);
      expect(validator.validateMaxTwoDecimalsGreaterEqualZero('bad'),
          l10n.invalidInput);
      expect(validator.validateMaxTwoDecimalsGreaterEqualZero('-1'),
          l10n.valueMustBeGreaterEqualZero);
    });

    test('rejects numbers with more than 2 decimals even if >= 0', () {
      expect(validator.validateMaxTwoDecimalsGreaterEqualZero('0.001'),
          l10n.tooManyDecimalPlaces);
      expect(validator.validateMaxTwoDecimalsGreaterEqualZero('10.123'),
          l10n.tooManyDecimalPlaces);
    });

    test('accepts zero and positive numbers with up to 2 decimals', () {
      expect(validator.validateMaxTwoDecimalsGreaterEqualZero('0'), isNull);
      expect(validator.validateMaxTwoDecimalsGreaterEqualZero('0.0'), isNull);
      expect(validator.validateMaxTwoDecimalsGreaterEqualZero('2.34'), isNull);
    });
  });

  group('validateSufficientSharesToSell', () {
    test('propagates decimal greater-zero errors', () {
      // null and non-numeric should be caught by validateDecimalGreaterZero
      expect(
          validator.validateSufficientSharesToSell(null, 10.0, TradeTypes.sell),
          l10n.requiredField);
      expect(
          validator.validateSufficientSharesToSell(
              'foo', 10.0, TradeTypes.sell),
          l10n.invalidInput);
      expect(
          validator.validateSufficientSharesToSell('0', 10.0, TradeTypes.sell),
          l10n.valueMustBeGreaterZero);
    });

    test('returns insufficientShares when selling more than owned', () {
      // tradeType == sell
      expect(
          validator.validateSufficientSharesToSell('5', 4.99, TradeTypes.sell),
          l10n.insufficientShares);
      expect(
          validator.validateSufficientSharesToSell(
              '100', 10.0, TradeTypes.sell),
          l10n.insufficientShares);
    });

    test('allows selling equal to owned shares', () {
      expect(
          validator.validateSufficientSharesToSell('5', 5.0, TradeTypes.sell),
          isNull);
    });

    test('allows selling less than owned shares', () {
      expect(
          validator.validateSufficientSharesToSell('5', 10.0, TradeTypes.sell),
          isNull);
    });

    test('does not check owned shares when tradeType is buy or null', () {
      // Even if ownedShares are less than the value to be "sold", if tradeType != sell we return null
      expect(
          validator.validateSufficientSharesToSell('100', 1.0, TradeTypes.buy),
          isNull);
      expect(
          validator.validateSufficientSharesToSell('100', 1.0, null), isNull);
    });
  });

  group('validateIsUnique', () {
    test('propagates not-initial error (null)', () {
      expect(
          validator.validateIsUnique(
            null,
            ['Cash'],
          ),
          l10n.requiredField);
    });

    test('propagates not-initial error (empty or whitespace)', () {
      expect(
          validator.validateIsUnique(
            '',
            ['Cash'],
          ),
          l10n.requiredField);
      expect(
          validator.validateIsUnique(
            ' ',
            ['Cash'],
          ),
          l10n.requiredField);
    });

    test('returns error when name already exists', () {
      expect(
          validator.validateIsUnique(
            'Cash',
            ['Cash', 'Savings'],
          ),
          l10n.valueAlreadyExists);
    });

    test('trims whitespace before comparing', () {
      expect(
          validator.validateIsUnique(
            '  Cash  ',
            ['Cash'],
          ),
          l10n.valueAlreadyExists);
    });

    test('returns null for a unique name', () {
      expect(
          validator.validateIsUnique(
            'Investments',
            ['Cash', 'Savings'],
          ),
          isNull);

      expect(
          validator.validateIsUnique(
            'Cash',
            [],
          ),
          isNull);
    });
  });

  group('validateAccountSelected', () {
    test('account is selected', () {
      expect(validator.validateAccountSelected(1), null);
    });

    test('account is not selected', () {
      expect(
          validator.validateAccountSelected(null), l10n.pleaseSelectAnAccount);
    });
  });

  group('validateAssetSelected', () {
    test('asset is selected', () {
      expect(validator.validateAssetSelected(1), null);
    });

    test('account is not selected', () {
      expect(validator.validateAssetSelected(null), l10n.pleaseSelectAnAsset);
    });
  });

  group('validateCycleSelected', () {
    test('cycle is selected', () {
      expect(validator.validateCycleSelected(1), null);
    });

    test('cycle is not selected', () {
      expect(validator.validateCycleSelected(null), l10n.pleaseSelectACycle);
    });
  });

  group('validateDateNotInFuture', () {
    test('date is null', () {
      expect(validator.validateDateNotInFuture(null), l10n.requiredField);
    });

    test('date is in the past', () {
      expect(validator.validateDateNotInFuture(DateTime(2021)), null);
    });

    test('date is now', () {
      expect(validator.validateDateNotInFuture(DateTime.now()), null);
    });

    test('date is in the future', () {
      expect(validator.validateDateNotInFuture(DateTime(2099)),
          l10n.dateCannotBeInTheFuture);
    });
  });

  group('validateDateInFuture', () {
    test('date is null', () {
      expect(validator.validateDateInFuture(null), l10n.requiredField);
    });

    test('date is in the past', () {
      expect(validator.validateDateInFuture(DateTime(2021)),
          l10n.dateMustBeInTheFuture);
    });

    test('date is now', () {
      expect(validator.validateDateInFuture(DateTime.now()),
          l10n.dateMustBeInTheFuture);
    });

    test('date is in the future', () {
      expect(validator.validateDateInFuture(DateTime(2099)), null);
    });
  });
}
