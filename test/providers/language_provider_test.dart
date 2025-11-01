import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xfin/providers/language_provider.dart';

void main() {
  group('LanguageProvider', () {
    late LanguageProvider languageProvider;
    late SharedPreferences sharedPreferences;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      sharedPreferences = await SharedPreferences.getInstance();
      languageProvider = LanguageProvider();
      // Wait for initial loadLocale to complete
      await languageProvider.loadLocale();
    });

    test('initializes with English locale by default', () {
      expect(languageProvider.appLocale, const Locale('en'));
    });

    test('setLocale updates the locale and notifies listeners', () async {
      const newLocale = Locale('de');
      bool listenerCalled = false;

      languageProvider.addListener(() {
        listenerCalled = true;
      });

      await languageProvider.setLocale(newLocale);

      expect(languageProvider.appLocale, newLocale);
      expect(listenerCalled, isTrue);
    });

    test('setLocale saves the language code to SharedPreferences', () async {
      const newLocale = Locale('de');
      await languageProvider.setLocale(newLocale);

      final savedLanguageCode = sharedPreferences.getString('language_code');
      expect(savedLanguageCode, 'de');
    });

    test('setLocale does not notify listeners if locale is the same', () async {
      bool listenerCalled = false;

      languageProvider.addListener(() {
        listenerCalled = true;
      });

      // Set the same locale
      await languageProvider.setLocale(const Locale('en'));

      expect(listenerCalled, isFalse);
    });

    test('loadLocale loads locale from SharedPreferences', () async {
      // Set a value in SharedPreferences and then create a new provider
      SharedPreferences.setMockInitialValues({'language_code': 'de'});
      final newLanguageProvider = LanguageProvider();
      await newLanguageProvider.loadLocale();

      expect(newLanguageProvider.appLocale, const Locale('de'));
    });

    test('loadLocale defaults to English if no value is in SharedPreferences', () async {
      // Ensure SharedPreferences is empty
      SharedPreferences.setMockInitialValues({});
      final newLanguageProvider = LanguageProvider();
      await newLanguageProvider.loadLocale();

      expect(newLanguageProvider.appLocale, const Locale('en'));
    });
  });
}
