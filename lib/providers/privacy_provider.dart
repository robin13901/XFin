import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrivacyProvider with ChangeNotifier {
  static final PrivacyProvider instance = PrivacyProvider._internal();

  PrivacyProvider._internal();

  static const String _enabledKey = 'privacy_mode_enabled';

  bool _enabled = false;
  bool _hidden = true;

  /// Whether the privacy-mode feature is turned on in settings.
  bool get enabled => _enabled;

  /// Whether values are currently hidden (only relevant when [enabled] is true).
  bool get hidden => _enabled && _hidden;

  Future<void> load([SharedPreferences? prefsOverride]) async {
    final prefs = prefsOverride ?? await SharedPreferences.getInstance();
    _enabled = prefs.getBool(_enabledKey) ?? false;
    _hidden = _enabled; // start hidden whenever the feature is on
    notifyListeners();
  }

  Future<void> setEnabled(bool value) async {
    if (_enabled == value) return;
    _enabled = value;
    _hidden = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, value);
    notifyListeners();
  }

  void toggleHidden() {
    if (!_enabled) return;
    _hidden = !_hidden;
    notifyListeners();
  }

  void reveal() {
    if (!_enabled || !_hidden) return;
    _hidden = false;
    notifyListeners();
  }

  void hide() {
    if (!_enabled || _hidden) return;
    _hidden = true;
    notifyListeners();
  }
}
