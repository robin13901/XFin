import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xfin/utils/date_picker_locale.dart';

void main() {
  group('resolveDatePickerLocale', () {
    test('maps english to en_GB to keep monday as first day', () {
      expect(resolveDatePickerLocale(const Locale('en')), const Locale('en', 'GB'));
    });

    test('keeps german locale unchanged', () {
      expect(resolveDatePickerLocale(const Locale('de')), const Locale('de'));
    });
  });
}
