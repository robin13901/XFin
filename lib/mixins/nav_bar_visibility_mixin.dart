import 'package:flutter/material.dart';

import '../widgets/nav_bar_controller.dart';

/// Mixin for screens that need to hide the bottom nav bar when
/// the filter panel is open or the keyboard is visible during search.
///
/// Uses a [_KeyboardObserver] to reliably detect keyboard visibility
/// changes, which works even inside nested [Scaffold] widgets that consume
/// [MediaQuery.viewInsets].
mixin NavBarVisibilityMixin<T extends StatefulWidget> on State<T> {
  /// Override to provide local ValueNotifier for screens with their own nav bar.
  /// Returns null by default (will use NavBarController from context).
  ValueNotifier<bool>? get localNavBarVisible => null;

  ValueNotifier<bool>? _cachedNotifier;
  bool _filterPanelOpen = false;
  bool _searchFocused = false;
  bool _keyboardVisible = false;
  _KeyboardObserver? _keyboardObserver;

  ValueNotifier<bool>? get _notifier =>
      localNavBarVisible ?? _cachedNotifier;

  @override
  void initState() {
    super.initState();
    _keyboardObserver = _KeyboardObserver(_onKeyboardChanged);
    WidgetsBinding.instance.addObserver(_keyboardObserver!);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Cache the inherited notifier so we can use it safely in dispose
    _cachedNotifier = NavBarController.of(context);
  }

  @override
  void dispose() {
    if (_keyboardObserver != null) {
      WidgetsBinding.instance.removeObserver(_keyboardObserver!);
      _keyboardObserver = null;
    }
    super.dispose();
  }

  void _onKeyboardChanged(bool visible) {
    if (visible != _keyboardVisible) {
      _keyboardVisible = visible;
      if (mounted) _updateNavBarVisibility();
    }
  }

  void _updateNavBarVisibility() {
    final notifier = _notifier;
    if (notifier == null) return;

    // Hide if filter panel is open OR (search focused AND keyboard visible)
    final shouldHide = _filterPanelOpen || (_searchFocused && _keyboardVisible);
    notifier.value = !shouldHide;
  }

  /// Call when filter panel visibility changes.
  void setFilterPanelOpen(bool open) {
    _filterPanelOpen = open;
    _updateNavBarVisibility();
  }

  /// Call when search focus changes.
  void setSearchFocused(bool focused) {
    _searchFocused = focused;
    _updateNavBarVisibility();
  }

  /// No longer needed - keyboard detection is handled via [WidgetsBindingObserver].
  /// Kept so existing call sites don't break; does nothing.
  void updateKeyboardVisibility(BuildContext context) {}

  /// Call when screen is being disposed to restore nav bar visibility.
  void restoreNavBarVisibility() {
    _notifier?.value = true;
  }
}

/// Lightweight observer that only cares about [didChangeMetrics].
class _KeyboardObserver with WidgetsBindingObserver {
  final void Function(bool visible) onChanged;

  _KeyboardObserver(this.onChanged);

  @override
  void didChangeMetrics() {
    final view = WidgetsBinding.instance.platformDispatcher.implicitView;
    final bottomInset = view?.viewInsets.bottom ?? 0.0;
    onChanged(bottomInset > 0);
  }
}
