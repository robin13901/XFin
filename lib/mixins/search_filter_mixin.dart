import 'dart:async';

import 'package:flutter/material.dart';

import '../models/filter/filter_rule.dart';
import 'nav_bar_visibility_mixin.dart';

/// Mixin that handles search and filter state management for list screens.
///
/// This eliminates duplicated search/filter code across multiple screens.
///
/// Usage:
/// ```dart
/// class MyScreenState extends State<MyScreen>
///     with NavBarVisibilityMixin<MyScreen>, SearchFilterMixin<MyScreen> {
///   @override
///   Widget build(BuildContext context) {
///     // Use showSearchBar, searchQuery, filterRules, etc.
///   }
/// }
/// ```
mixin SearchFilterMixin<T extends StatefulWidget> on State<T> {
  bool showSearchBar = false;
  final TextEditingController searchController = TextEditingController();
  String searchQuery = '';
  final FocusNode searchFocusNode = FocusNode();

  List<FilterRule> filterRules = [];
  bool showFilterPanel = false;

  Timer? _searchDebounce;

  int get activeFilterCount => filterRules.length;

  double get searchBarSpace => showSearchBar ? 60.0 : 0.0;

  @override
  void initState() {
    super.initState();
    searchFocusNode.addListener(_onSearchFocusChanged);
  }

  @override
  void dispose() {
    searchController.dispose();
    _searchDebounce?.cancel();
    searchFocusNode.removeListener(_onSearchFocusChanged);
    searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchFocusChanged() {
    // ignore: invalid_runtime_check_of_non_local_type
    if (this case NavBarVisibilityMixin m) {
      m.setSearchFocused(searchFocusNode.hasFocus);
    }
  }

  void onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      if (searchQuery != value) {
        setState(() => searchQuery = value);
        onSearchFilterChanged();
      }
    });
  }

  void toggleSearch() {
    setState(() {
      showSearchBar = !showSearchBar;
      if (!showSearchBar) {
        searchFocusNode.unfocus();
        searchController.clear();
        if (searchQuery.isNotEmpty) {
          searchQuery = '';
          onSearchFilterChanged();
        }
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          searchFocusNode.requestFocus();
        });
      }
    });
  }

  void onFilterRulesChanged(List<FilterRule> rules) {
    setState(() => filterRules = rules);
    onSearchFilterChanged();
  }

  void closeFilterPanel() {
    setState(() => showFilterPanel = false);
    // ignore: invalid_runtime_check_of_non_local_type
    if (this case NavBarVisibilityMixin m) {
      m.setFilterPanelOpen(false);
    }
  }

  void openFilterPanel() {
    setState(() => showFilterPanel = true);
    // ignore: invalid_runtime_check_of_non_local_type
    if (this case NavBarVisibilityMixin m) {
      m.setFilterPanelOpen(true);
    }
  }

  /// Override in screens that need to react to search/filter changes.
  /// For example, BookingsScreen overrides this to call _loadInitial().
  void onSearchFilterChanged() {}
}
