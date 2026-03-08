# Phase 2 Plan: Extract Search/Filter Mixin

## Goal
Eliminate duplicated search/filter state management code across 5 screens by extracting it into a reusable `SearchFilterMixin`. This reduces ~350 lines of copy-pasted code to a single ~90-line mixin, and establishes a consistent pattern for any future screens that need search/filter.

## Requirements Covered
- R3.1: Create a `SearchFilterMixin` extracting the common search/filter pattern
- R3.2: Refactor all 5 screens to use the extracted mixin
- R3.3: Add tests for the extracted mixin

## Pre-conditions
- Phase 1 complete (clean baseline)
- All 650+ tests currently pass
- Zero flutter analyze issues

---

## Task 1: Create SearchFilterMixin + Tests (Wave 1 - Foundation)

### 1a: Create `lib/mixins/search_filter_mixin.dart`
**File**: `lib/mixins/search_filter_mixin.dart`
**Action**: Create the mixin following the established project pattern (`PaginationMixin`, `NavBarVisibilityMixin`). The mixin must:

**State fields (public, no underscore -- same convention as PaginationMixin):**
- `bool showSearchBar = false`
- `final TextEditingController searchController = TextEditingController()`
- `String searchQuery = ''`
- `final FocusNode searchFocusNode = FocusNode()`
- `List<FilterRule> filterRules = []`
- `bool showFilterPanel = false`

**Private implementation detail:**
- `Timer? _searchDebounce` (internal, never accessed from screen build methods)

**Computed properties:**
- `int get activeFilterCount => filterRules.length`
- `double get searchBarSpace => showSearchBar ? 60.0 : 0.0`

**Lifecycle (override initState/dispose with super calls, matching NavBarVisibilityMixin pattern):**
- `initState()`: call `super.initState()`, add `searchFocusNode.addListener(_onSearchFocusChanged)`
- `dispose()`: call `searchController.dispose()`, cancel `_searchDebounce`, remove listener from `searchFocusNode`, dispose `searchFocusNode`, call `super.dispose()`

**Behavior methods:**
- `void _onSearchFocusChanged()`: Uses Dart 3 pattern matching (`if (this case NavBarVisibilityMixin m)`) to conditionally call `m.setSearchFocused(searchFocusNode.hasFocus)`. Add `// ignore: invalid_runtime_check_of_non_local_type` before the pattern match.
- `void onSearchChanged(String value)`: Cancel existing debounce, create new 300ms Timer. In callback: guard with `if (!mounted) return`, then if `searchQuery != value`, call `setState(() => searchQuery = value)` followed by `onSearchFilterChanged()`.
- `void toggleSearch()`: Toggle `showSearchBar` in `setState`. If closing: unfocus, clear controller, clear `searchQuery` if non-empty and call `onSearchFilterChanged()`. If opening: use `addPostFrameCallback` to request focus.
- `void onFilterRulesChanged(List<FilterRule> rules)`: `setState(() => filterRules = rules)` then `onSearchFilterChanged()`.
- `void closeFilterPanel()`: `setState(() => showFilterPanel = false)`, then conditionally call `NavBarVisibilityMixin.setFilterPanelOpen(false)` via pattern match.
- `void openFilterPanel()`: `setState(() => showFilterPanel = true)`, then conditionally call `NavBarVisibilityMixin.setFilterPanelOpen(true)` via pattern match.
- `void onSearchFilterChanged() {}`: Empty default. BookingsScreen overrides this to trigger `_loadInitial()`.

**Imports:**
- `dart:async` (Timer)
- `package:flutter/material.dart`
- `../models/filter/filter_rule.dart`
- `nav_bar_visibility_mixin.dart`

**Verification**:
```
flutter analyze lib/mixins/search_filter_mixin.dart
```

### 1b: Create `test/mixins/search_filter_mixin_test.dart`
**File**: `test/mixins/search_filter_mixin_test.dart`
**Action**: Create comprehensive tests following the established pattern in `test/mixins/pagination_mixin_test.dart`:

**Test harness:** Create a `_TestSearchFilterWidget` StatefulWidget with a `_TestSearchFilterWidgetState` that mixes in `SearchFilterMixin`. The widget accepts optional callbacks: `VoidCallback? onSearchFilterChanged` to verify the hook is called. The state class overrides `onSearchFilterChanged` to call the widget's callback. The `build()` method returns a simple `SizedBox`.

**Test cases (aim for 100% statement coverage on the mixin):**

1. **Default state initialization**: Verify `showSearchBar == false`, `searchQuery == ''`, `filterRules == []`, `showFilterPanel == false`, `activeFilterCount == 0`, `searchBarSpace == 0.0`.

2. **toggleSearch() shows search bar**: Call `toggleSearch()`, pump, verify `showSearchBar == true`, `searchBarSpace == 60.0`.

3. **toggleSearch() hides and clears**: Set search bar open with query, call `toggleSearch()`, pump, verify `showSearchBar == false`, `searchQuery == ''`, `searchController.text` unchanged (controller is separate from query -- controller is UI, query is debounced state).

4. **toggleSearch() calls onSearchFilterChanged when clearing non-empty query**: Set up with `searchQuery = 'test'` and `showSearchBar = true`, toggle off, verify callback was called.

5. **toggleSearch() does NOT call onSearchFilterChanged when query was already empty**: Toggle on then off with empty query, verify callback was NOT called.

6. **onSearchChanged() debounces at 300ms**: Call `onSearchChanged('test')`, pump 100ms, verify `searchQuery` still empty. Pump remaining 200ms, verify `searchQuery == 'test'`.

7. **onSearchChanged() cancels previous debounce**: Call `onSearchChanged('a')`, pump 100ms, call `onSearchChanged('b')`, pump 300ms, verify `searchQuery == 'b'` (not 'a').

8. **onSearchChanged() calls onSearchFilterChanged after debounce**: Verify callback fires after 300ms.

9. **onSearchChanged() skips if value unchanged**: Set `searchQuery = 'same'`, call `onSearchChanged('same')`, pump 300ms, verify callback NOT called.

10. **onFilterRulesChanged() updates state**: Create a `FilterRule`, call `onFilterRulesChanged([rule])`, verify `filterRules.length == 1`, `activeFilterCount == 1`.

11. **onFilterRulesChanged() calls onSearchFilterChanged**: Verify callback fires.

12. **closeFilterPanel()**: Set `showFilterPanel = true`, call `closeFilterPanel()`, verify `showFilterPanel == false`.

13. **openFilterPanel()**: Call `openFilterPanel()`, verify `showFilterPanel == true`.

14. **dispose cleans up resources**: Verify no errors after disposing (Timer cancelled, FocusNode disposed, etc.). Test by pumping a new widget after the first is removed.

15. **mounted guard in debounce**: Start a search debounce, dispose the widget before 300ms, pump -- verify no "setState after dispose" error.

**Verification**:
```
flutter test test/mixins/search_filter_mixin_test.dart
```

### 1c: Run targeted verification
**Command**:
```
flutter test test/mixins/search_filter_mixin_test.dart
flutter analyze
```
**Expected**: All new mixin tests pass, zero analyzer issues.

---

## Task 2: Refactor AccountsScreen (Wave 2 - Validate Pattern)

AccountsScreen is the simplest screen (no tabs, no pagination, no animation controllers). Refactoring it first validates the mixin integration pattern before applying to more complex screens.

### 2a: Refactor `lib/screens/accounts_screen.dart`
**File**: `lib/screens/accounts_screen.dart`
**Action**:

**Add import:**
- `import '../mixins/search_filter_mixin.dart';`

**Remove import (no longer needed directly):**
- `import 'dart:async';` (only if Timer was the sole reason for the import -- check first)

**Change class declaration (line 34-35):**
- FROM: `with NavBarVisibilityMixin<AccountsScreen>`
- TO: `with NavBarVisibilityMixin<AccountsScreen>, SearchFilterMixin<AccountsScreen>`

**Delete state variables (lines ~37-47):**
- Remove `_showSearchBar`, `_searchController`, `_searchQuery`, `_searchDebounce`, `_searchFocusNode`
- Remove `_filterRules`, `_showFilterPanel`
- Remove `_activeFilterCount` getter

**Simplify initState() (lines ~49-53):**
- Remove `_searchFocusNode.addListener(_onSearchFocusChanged);` (mixin handles this)
- If initState body becomes empty (only `super.initState()`), keep it if it still calls `super` (mixin's initState will handle the rest via super chain)
- If initState has no other code besides `super.initState()`, remove the entire override (the mixin handles it)

**Simplify dispose() (lines ~55-63):**
- Remove `_searchController.dispose()`, `_searchDebounce?.cancel()`, `_searchFocusNode.removeListener(...)`, `_searchFocusNode.dispose()`
- KEEP `restoreNavBarVisibility()` and `super.dispose()`
- The mixin's dispose handles search/filter cleanup via the super chain

**Delete methods (lines ~65-99):**
- Delete `_onSearchFocusChanged()` (mixin owns this)
- Delete `_onSearchChanged()` (use mixin's `onSearchChanged`)
- Delete `_toggleSearch()` (use mixin's `toggleSearch`)
- Delete `_onFilterRulesChanged()` if it exists (use mixin's `onFilterRulesChanged`)

**Update build() method references:** Replace all underscore-prefixed private references with mixin public names:
- `_showSearchBar` -> `showSearchBar`
- `_searchQuery` -> `searchQuery`
- `_searchController` -> `searchController`
- `_searchFocusNode` -> `searchFocusNode`
- `_filterRules` -> `filterRules`
- `_showFilterPanel` -> `showFilterPanel`
- `_activeFilterCount` -> `activeFilterCount`
- `_onSearchChanged` -> `onSearchChanged`
- `_toggleSearch` -> `toggleSearch`
- `_onFilterRulesChanged` -> `onFilterRulesChanged`
- Any `_showSearchBar ? 60.0 : 0.0` -> `searchBarSpace`
- Any `setState(() => _showFilterPanel = false); setFilterPanelOpen(false);` -> `closeFilterPanel()`
- Any filter panel open logic -> `openFilterPanel()`

**Verification**:
```
flutter test test/screens/accounts_screen_test.dart
flutter analyze lib/screens/accounts_screen.dart
```

### 2b: Run full test suite to verify no regressions
**Command**:
```
flutter test
```
**Expected**: All tests pass. This validates the mixin pattern works correctly before applying to the remaining 4 screens.

---

## Task 3: Refactor Remaining 4 Screens (Wave 3)

Apply the same refactoring pattern validated in Task 2 to assets, bookings, trades, and transfers. Bookings requires special attention for the pagination hook.

### 3a: Refactor `lib/screens/assets_screen.dart`
**File**: `lib/screens/assets_screen.dart`
**Action**: Apply the same pattern as accounts_screen (Task 2a). Specifics:

- Add `SearchFilterMixin<AssetsScreen>` to the `with` clause (after `NavBarVisibilityMixin<AssetsScreen>`)
- Delete search/filter state vars (lines ~40-50)
- Delete `_activeFilterCount` getter
- Remove search focus listener from `initState()` (mixin handles it)
- Remove search/filter cleanup from `dispose()` (KEEP: `_navBarVisible.dispose()`, `super.dispose()`)
- Delete `_onSearchFocusChanged()`, `_onSearchChanged()`, `_toggleSearch()`, `_onFilterRulesChanged()`
- Update all build() references from private `_foo` to public `foo`
- KEEP: `_selectedTab`, `_selectedType`, `_navBarVisible`, `localNavBarVisible` override -- these are assets-specific, not search/filter
- KEEP: Conditional display logic based on `_selectedTab == 1` for showing search/filter only on Assets tab -- this is UI logic, not state management

**Verification**:
```
flutter test test/screens/assets_screen_test.dart
flutter analyze lib/screens/assets_screen.dart
```

### 3b: Refactor `lib/screens/bookings_screen.dart` (PAGINATION SPECIAL CASE)
**File**: `lib/screens/bookings_screen.dart`
**Action**: This screen is the outlier -- it needs the `onSearchFilterChanged` hook for pagination reload.

- Add `SearchFilterMixin<BookingsScreen>` to the `with` clause (after `NavBarVisibilityMixin<BookingsScreen>`)
- Delete search/filter state vars (lines ~49-59)
- Delete `_activeFilterCount` getter
- Remove search focus listener from `initState()` (mixin handles it)
- Remove search/filter cleanup from `dispose()` (KEEP: `_pageSub?.cancel()`, `_scrollController` cleanup, `restoreNavBarVisibility()`)
- Delete `_onSearchFocusChanged()`
- Delete `_onSearchChanged()` (the bookings-specific version with `_loadInitial()`)
- Delete `_showSearch()` and `_hideSearch()` (replaced by mixin's `toggleSearch()`)
- Delete `_onFilterRulesChanged()` (the bookings-specific version with `_loadInitial()`)

**ADD the pagination hook override:**
```dart
@override
void onSearchFilterChanged() {
  _loadInitial();
}
```

- Update build() references: `_showSearchBar` -> `showSearchBar`, `_searchQuery` -> `searchQuery`, etc.
- Where build() previously called `_showSearch()` and `_hideSearch()` separately, replace both with `toggleSearch()`
- In `_subscribeForLimit()`, update references: `_searchQuery` -> `searchQuery`, `_filterRules` -> `filterRules`

**CRITICAL**: Verify that `_loadInitial()` is called when:
1. Search query changes (via debounce) -- handled by `onSearchChanged()` -> `onSearchFilterChanged()` -> `_loadInitial()`
2. Filter rules change -- handled by `onFilterRulesChanged()` -> `onSearchFilterChanged()` -> `_loadInitial()`
3. Search is hidden with non-empty query -- handled by `toggleSearch()` -> `onSearchFilterChanged()` -> `_loadInitial()`

**Verification**:
```
flutter test test/screens/bookings_screen_test.dart
flutter analyze lib/screens/bookings_screen.dart
```

### 3c: Refactor `lib/screens/trades_screen.dart`
**File**: `lib/screens/trades_screen.dart`
**Action**: Apply the same pattern as accounts_screen (Task 2a). Specifics:

- Add `SearchFilterMixin<TradesScreen>` to the `with` clause (after `NavBarVisibilityMixin<TradesScreen>`)
- Mixin order: `SingleTickerProviderStateMixin, NavBarVisibilityMixin<TradesScreen>, SearchFilterMixin<TradesScreen>` -- `SingleTickerProviderStateMixin` must come first since it provides `vsync` for `AnimationController`
- Delete search/filter state vars (lines ~45-55)
- Delete `_activeFilterCount` getter
- Remove search focus listener from `initState()` (KEEP: `_sheetAnimController` setup, `db` initialization, preload futures)
- Remove search/filter cleanup from `dispose()` (KEEP: `_sheetAnimController.dispose()`, `_navBarVisible.dispose()`, `super.dispose()`)
- Delete `_onSearchFocusChanged()`, `_onSearchChanged()`, `_toggleSearch()`, `_onFilterRulesChanged()`
- Update all build() references from private `_foo` to public `foo`
- KEEP: `_sheetAnimController`, `db`, `_navBarVisible`, `localNavBarVisible`, preload futures

**Verification**:
```
flutter test test/screens/trades_screen_test.dart
flutter analyze lib/screens/trades_screen.dart
```

### 3d: Refactor `lib/screens/transfers_screen.dart`
**File**: `lib/screens/transfers_screen.dart`
**Action**: Apply the same pattern as trades_screen (same mixin combination).

- Add `SearchFilterMixin<TransfersScreen>` to the `with` clause
- Mixin order: `SingleTickerProviderStateMixin, NavBarVisibilityMixin<TransfersScreen>, SearchFilterMixin<TransfersScreen>`
- Delete search/filter state vars (lines ~39-49)
- Delete `_activeFilterCount` getter
- Remove search focus listener from `initState()` (KEEP: `db` initialization, `assetsFuture`, `_sheetAnimController` setup)
- Remove search/filter cleanup from `dispose()` (KEEP: `_sheetAnimController.dispose()`, `_navBarVisible.dispose()`, `super.dispose()`)
- Delete `_onSearchFocusChanged()`, `_onSearchChanged()`, `_toggleSearch()`, `_onFilterRulesChanged()`
- Update all build() references from private `_foo` to public `foo`
- KEEP: `_sheetAnimController`, `db`, `assetsFuture`, `_navBarVisible`, `localNavBarVisible`

**Verification**:
```
flutter test test/screens/transfers_screen_test.dart
flutter analyze lib/screens/transfers_screen.dart
```

### 3e: Run full test suite after all refactorings
**Command**:
```
flutter test
flutter analyze
```
**Expected**: All 650+ tests pass, zero analyzer issues.

---

## Task 4: Final Verification (Wave 4)

### 4a: Full test suite
**Command**:
```
flutter test
```
**Expected**: All tests pass.

### 4b: Static analysis
**Command**:
```
flutter analyze
```
**Expected**: Zero issues.

### 4c: Manual spot-check of deduplication
**Action**: Verify no screen still contains any of these patterns:
- `bool _showSearchBar`
- `String _searchQuery`
- `Timer? _searchDebounce`
- `FocusNode _searchFocusNode`
- `List<FilterRule> _filterRules`
- `bool _showFilterPanel`
- `int get _activeFilterCount`
- `void _onSearchFocusChanged()`
- `void _onSearchChanged(`
- `void _toggleSearch()`

Use grep across `lib/screens/` to confirm zero matches.

**Verification**:
```
grep -rn "_showSearchBar\|_searchQuery\|_searchDebounce\|_searchFocusNode\|_filterRules\|_showFilterPanel\|_activeFilterCount\|_onSearchFocusChanged\|_onSearchChanged\|_toggleSearch" lib/screens/
```
**Expected**: Zero matches.

---

## Execution Order

1. **Wave 1**: Task 1 (create mixin + tests) -- establishes the foundation
2. **Wave 2**: Task 2 (refactor AccountsScreen) -- validates pattern on simplest screen
3. **Wave 3**: Task 3 (refactor remaining 4 screens) -- apply validated pattern
4. **Wave 4**: Task 4 (final verification) -- ensure everything is clean

Run `flutter test` after EVERY sub-task completion (not just at wave boundaries). Stop and investigate immediately if any test fails.

## Rollback Plan

Each task produces a git commit. If any task breaks tests:
1. Revert that specific commit: `git revert HEAD`
2. Investigate the failure
3. Fix and retry

The mixin is additive in Wave 1 (no existing code changes). Screen refactors in Waves 2-3 are independent per-screen commits -- reverting one screen does not affect others.

## Success Criteria

- [ ] `lib/mixins/search_filter_mixin.dart` exists with all state, lifecycle, and behavior methods
- [ ] `test/mixins/search_filter_mixin_test.dart` exists with 15+ test cases covering all mixin behavior
- [ ] All 5 screens (`accounts`, `assets`, `bookings`, `trades`, `transfers`) use `SearchFilterMixin`
- [ ] Zero duplicated search/filter state variables across screens
- [ ] Zero duplicated search/filter methods across screens
- [ ] BookingsScreen correctly overrides `onSearchFilterChanged()` to call `_loadInitial()`
- [ ] All screen tests pass (no regressions)
- [ ] All mixin tests pass
- [ ] `flutter test` passes (full suite, 650+ tests)
- [ ] `flutter analyze` reports zero issues
- [ ] `grep` confirms zero private search/filter patterns remain in `lib/screens/`
