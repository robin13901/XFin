import 'package:flutter/material.dart';

/// Keeps the date picker calendar grid Monday-first for all supported languages.
Locale resolveDatePickerLocale(Locale appLocale) {
  if (appLocale.languageCode == 'en') {
    return const Locale('en', 'GB');
  }
  return appLocale;
}

