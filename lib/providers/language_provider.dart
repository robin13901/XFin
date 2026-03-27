import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider with ChangeNotifier {
  Locale _appLocale = const Locale('en');

  Locale get appLocale => _appLocale;

  LanguageProvider() {
    loadLocale();
  }

  /// Creates a provider without triggering automatic [loadLocale].
  /// Used by [main] where loading is handled explicitly with a shared
  /// [SharedPreferences] instance.
  LanguageProvider.eager();

  Future<void> setLocale(Locale locale) async {
    if (_appLocale == locale) return;

    _appLocale = locale;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', locale.languageCode);
    notifyListeners();
  }

  Future<void> loadLocale([SharedPreferences? prefsOverride]) async {
    final prefs = prefsOverride ?? await SharedPreferences.getInstance();
    String languageCode = prefs.getString('language_code') ?? 'en';
    _appLocale = Locale(languageCode);
    notifyListeners();
  }
}
