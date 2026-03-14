import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  static final ThemeProvider instance = ThemeProvider._internal();

  ThemeProvider._internal();

  static const String _themeKey = 'theme_mode';
  static const String _auroraKey = 'is_aurora';
  ThemeMode _themeMode = ThemeMode.system;
  bool _isAurora = false;

  ThemeMode get themeMode => _themeMode;

  /// Whether the "Dark Aurora" variant is active (dark theme + aurora bg).
  bool get isAurora => _isAurora;

  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    String themeName = prefs.getString(_themeKey) ?? 'system';
    _themeMode = ThemeMode.values.byName(themeName);
    _isAurora = prefs.getBool(_auroraKey) ?? false;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode, {bool aurora = false}) async {
    if (_themeMode == mode && _isAurora == aurora) return;
    _themeMode = mode;
    _isAurora = aurora;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, mode.name);
    await prefs.setBool(_auroraKey, aurora);
    notifyListeners();
  }

  static bool isDark() {
    return switch (instance.themeMode) {
      ThemeMode.dark => true,
      ThemeMode.light => false,
      ThemeMode.system =>
      WidgetsBinding.instance.platformDispatcher.platformBrightness ==
          Brightness.dark,
    };
  }
}
