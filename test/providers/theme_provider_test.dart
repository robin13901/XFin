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
      themeProvider = ThemeProvider.instance;
      // Reset singleton to known state
      await themeProvider.setThemeMode(ThemeMode.system);
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

      test('defaults to system theme when no value in shared preferences', () async {
        await themeProvider.loadTheme();
        expect(themeProvider.themeMode, ThemeMode.system);
      });

      test('loads aurora flag from shared preferences', () async {
        await sharedPreferences.setString('theme_mode', 'dark');
        await sharedPreferences.setBool('is_aurora', true);
        await themeProvider.loadTheme();
        expect(themeProvider.themeMode, ThemeMode.dark);
        expect(themeProvider.isAurora, isTrue);
      });

      test('aurora defaults to false when not stored', () async {
        await sharedPreferences.setString('theme_mode', 'dark');
        await themeProvider.loadTheme();
        expect(themeProvider.isAurora, isFalse);
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

      test('sets aurora flag and persists it', () async {
        await themeProvider.setThemeMode(ThemeMode.dark, aurora: true);

        expect(themeProvider.themeMode, ThemeMode.dark);
        expect(themeProvider.isAurora, isTrue);
        expect(sharedPreferences.getString('theme_mode'), 'dark');
        expect(sharedPreferences.getBool('is_aurora'), isTrue);
      });

      test('clears aurora when switching to non-aurora theme', () async {
        await themeProvider.setThemeMode(ThemeMode.dark, aurora: true);
        expect(themeProvider.isAurora, isTrue);

        await themeProvider.setThemeMode(ThemeMode.dark);
        expect(themeProvider.isAurora, isFalse);
        expect(sharedPreferences.getBool('is_aurora'), isFalse);
      });

      test('notifies when only aurora flag changes', () async {
        await themeProvider.setThemeMode(ThemeMode.dark);

        bool hasNotifiedListeners = false;
        themeProvider.addListener(() {
          hasNotifiedListeners = true;
        });

        await themeProvider.setThemeMode(ThemeMode.dark, aurora: true);
        expect(hasNotifiedListeners, isTrue);
      });
    });
  });
}
