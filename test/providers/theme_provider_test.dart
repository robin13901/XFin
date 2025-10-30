import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xfin/providers/theme_provider.dart';

void main() {
  group('ThemeProvider', () {
    late ThemeProvider themeProvider;
    late SharedPreferences sharedPreferences;

    setUp(() async {
      // Mock SharedPreferences for testing
      SharedPreferences.setMockInitialValues({});
      sharedPreferences = await SharedPreferences.getInstance();
      themeProvider = ThemeProvider();
    });

    test('initial theme mode is system', () {
      expect(themeProvider.themeMode, ThemeMode.system);
    });

    group('loadTheme', () {
      test('loads theme from shared preferences - light', () async {
        await sharedPreferences.setString('theme_mode', 'light');
        await themeProvider.loadTheme();
        expect(themeProvider.themeMode, ThemeMode.light);
      });

      test('loads theme from shared preferences - dark', () async {
        await sharedPreferences.setString('theme_mode', 'dark');
        await themeProvider.loadTheme();
        expect(themeProvider.themeMode, ThemeMode.dark);
      });

      test('loads theme from shared preferences - system', () async {
        await sharedPreferences.setString('theme_mode', 'system');
        await themeProvider.loadTheme();
        expect(themeProvider.themeMode, ThemeMode.system);
      });

      test('defaults to system theme for invalid value in shared preferences', () async {
        await sharedPreferences.setString('theme_mode', 'invalid');
        await themeProvider.loadTheme();
        expect(themeProvider.themeMode, ThemeMode.system);
      });

      test('defaults to system theme when no value in shared preferences', () async {
        await themeProvider.loadTheme();
        expect(themeProvider.themeMode, ThemeMode.system);
      });
    });

    group('setThemeMode', () {
      test('sets theme mode and saves to shared preferences', () async {
        bool hasNotifiedListeners = false;
        themeProvider.addListener(() {
          hasNotifiedListeners = true;
        });

        await themeProvider.setThemeMode(ThemeMode.dark);

        expect(themeProvider.themeMode, ThemeMode.dark);
        expect(sharedPreferences.getString('theme_mode'), 'dark');
        expect(hasNotifiedListeners, isTrue);
      });

      test('does not notify listeners if theme mode is the same', () async {
        bool hasNotifiedListeners = false;
        themeProvider.addListener(() {
          hasNotifiedListeners = true;
        });

        // Set initial theme
        await themeProvider.setThemeMode(ThemeMode.light);
        hasNotifiedListeners = false; // Reset after initial set

        // Set the same theme again
        await themeProvider.setThemeMode(ThemeMode.light);

        expect(hasNotifiedListeners, isFalse);
      });
    });
  });
}
