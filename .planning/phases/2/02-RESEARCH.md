# Phase 2: Extract Search/Filter Mixin - Research

**Researched:** 2026-03-08
**Domain:** Flutter mixin extraction, search/filter state management deduplication
**Confidence:** HIGH

## Summary

All 5 target screens (accounts, assets, bookings, trades, transfers) contain nearly identical search/filter state management code. The duplication is mechanical -- the same state variables, the same debounce logic, the same toggle/clear behavior, the same filter rules callback. The differences between screens are minimal and well-isolated: bookings uses split `_showSearch()`/`_hideSearch()` methods instead of `_toggleSearch()`, and bookings calls `_loadInitial()` on search/filter changes (because it uses pagination). The remaining 4 screens use a straightforward `_toggleSearch()` and StreamBuilder pattern.

The project already has 4 established mixins in `lib/mixins/` following a consistent pattern: `mixin Name<T extends StatefulWidget> on State<T>`. The test pattern is also well-established: create a test widget class that uses the mixin, expose mixin methods via public wrappers, and test via `tester.state<>()`.

**Primary recommendation:** Create `SearchFilterMixin<T extends StatefulWidget> on State<T>` that owns all search/filter state and lifecycle. Provide a callback hook `onSearchFilterChanged()` that screens override when they need to trigger additional actions (e.g., bookings pagination reload). The mixin should NOT own UI widget building -- it only manages state and behavior.

<phase_requirements>

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| R3.1 | Create a `SearchFilterMixin` extracting the common search/filter pattern | Exact duplicated code identified across all 5 screens -- see Duplicated Code Analysis section for state vars, methods, lifecycle |
| R3.2 | Refactor all 5 screens to use the extracted mixin | Integration points mapped per screen -- see Screen-Specific Differences section |
| R3.3 | Add tests for the extracted mixin | Test pattern established by existing mixin tests -- see Testing Pattern section |

</phase_requirements>

## Duplicated Code Analysis

### Identical State Variables (all 5 screens)

Found in every screen at the class-level:

```dart
// Search state
bool _showSearchBar = false;
final TextEditingController _searchController = TextEditingController();
String _searchQuery = '';
Timer? _searchDebounce;
final FocusNode _searchFocusNode = FocusNode();

// Filter state
List<FilterRule> _filterRules = [];
bool _showFilterPanel = false;

int get _activeFilterCount => _filterRules.length;
```

**Source locations:**
| Screen | Search state lines | Filter state lines |
|--------|-------------------|-------------------|
| `accounts_screen.dart` | 37-41 | 44-47 |
| `assets_screen.dart` | 40-44 | 47-50 |
| `bookings_screen.dart` | 49-53 | 56-59 |
| `trades_screen.dart` | 45-49 | 52-55 |
| `transfers_screen.dart` | 39-43 | 46-49 |

### Identical initState Logic

All 5 screens add the same focus listener in `initState()`:

```dart
_searchFocusNode.addListener(_onSearchFocusChanged);
```

### Identical dispose Logic

All 5 screens perform the same cleanup in `dispose()`:

```dart
_searchController.dispose();
_searchDebounce?.cancel();
_searchFocusNode.removeListener(_onSearchFocusChanged);
_searchFocusNode.dispose();
```

### Identical Methods (4 of 5 screens)

The following methods are identical in accounts, assets, trades, and transfers:

**`_onSearchFocusChanged()`** -- delegates to `NavBarVisibilityMixin.setSearchFocused()`:
```dart
void _onSearchFocusChanged() {
  setSearchFocused(_searchFocusNode.hasFocus);
}
```

**`_onSearchChanged(String value)`** -- 300ms debounce then setState:
```dart
void _onSearchChanged(String value) {
  _searchDebounce?.cancel();
  _searchDebounce = Timer(const Duration(milliseconds: 300), () {
    if (_searchQuery != value) {
      setState(() => _searchQuery = value);
    }
  });
}
```

**`_toggleSearch()`** -- toggles search bar visibility, manages focus, clears query:
```dart
void _toggleSearch() {
  setState(() {
    _showSearchBar = !_showSearchBar;
    if (!_showSearchBar) {
      _searchFocusNode.unfocus();
      _searchController.clear();
      if (_searchQuery.isNotEmpty) {
        _searchQuery = '';
      }
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _searchFocusNode.requestFocus();
      });
    }
  });
}
```

**`_onFilterRulesChanged(List<FilterRule> rules)`** -- setState with new rules:
```dart
void _onFilterRulesChanged(List<FilterRule> rules) {
  setState(() => _filterRules = rules);
}
```

### Identical UI Integration Points

All 5 screens use the same pattern in `build()`:
1. `final searchBarSpace = _showSearchBar ? 60.0 : 0.0;` for padding calculation
2. `LiquidGlassSearchBar` widget with `controller`, `focusNode`, `hintText`, `onChanged`
3. `FilterPanel` with `config`, `currentRules`, `onRulesChanged`, `onClose`
4. Search/filter toggle buttons in app bar actions

### Identical Filter Panel Close Logic

All 5 screens close the filter panel identically:
```dart
onClose: () {
  setState(() => _showFilterPanel = false);
  setFilterPanelOpen(false);
}
```

## Screen-Specific Differences

### BookingsScreen (the outlier)

Bookings uses pagination and therefore has **additional side effects** when search/filter change:

1. **`_onSearchChanged`** calls `_loadInitial()` after updating `_searchQuery`
2. **`_onFilterRulesChanged`** calls `_loadInitial()` after updating `_filterRules`
3. Uses **split methods** (`_showSearch()` + `_hideSearch()`) instead of `_toggleSearch()`
4. `_hideSearch()` also calls `_loadInitial()` when clearing a non-empty query

These are the ONLY behavioral differences. The state variables and their types are identical.

**Solution:** The mixin provides an overridable callback `onSearchFilterChanged()` that defaults to no-op. BookingsScreen overrides it to call its pagination reload. The mixin calls this callback at the end of `_onSearchChanged`, `_onFilterRulesChanged`, and `_toggleSearch` (when clearing).

### AssetsScreen

Assets has a tab system (`_selectedTab`) where search/filter only applies to the "Assets" tab (index 1). The search bar and filter actions are conditionally shown. This is purely a UI concern -- the mixin state management is identical. The screen just chooses when to show the UI elements based on its tab state.

### TradesScreen and TransfersScreen

Both use `SingleTickerProviderStateMixin` for sheet animations. This is orthogonal to search/filter and does not conflict with the new mixin. Dart supports multiple mixins on a single class.

### AccountsScreen

Simplest case. Uses StreamBuilder directly. No pagination. No tabs. Clean extraction target.

## Architecture Patterns

### Recommended Mixin Design

```dart
mixin SearchFilterMixin<T extends StatefulWidget> on State<T> {
  // ---- State (public for build() access) ----
  bool showSearchBar = false;
  final TextEditingController searchController = TextEditingController();
  String searchQuery = '';
  Timer? _searchDebounce;
  final FocusNode searchFocusNode = FocusNode();

  List<FilterRule> filterRules = [];
  bool showFilterPanel = false;

  int get activeFilterCount => filterRules.length;
  double get searchBarSpace => showSearchBar ? 60.0 : 0.0;

  // ---- Lifecycle ----
  void initSearchFilter();    // call from initState()
  void disposeSearchFilter(); // call from dispose()

  // ---- Behavior ----
  void onSearchChanged(String value);
  void toggleSearch();
  void onFilterRulesChanged(List<FilterRule> rules);
  void closeFilterPanel();

  // ---- Hook for screens needing side effects ----
  void onSearchFilterChanged() {}  // override in bookings
}
```

### Why NOT auto-lifecycle (initState/dispose override in mixin)

The existing mixins in this project (`NavBarVisibilityMixin`, `PaginationMixin`) DO override `initState`/`dispose` with `super` calls. However, `SearchFilterMixin` should follow the same pattern for consistency. The mixin CAN safely override `initState()` and `dispose()` calling `super` since Dart linearizes the mixin chain correctly.

**Decision: Override initState/dispose in the mixin** (consistent with NavBarVisibilityMixin and PaginationMixin patterns in this project).

### Mixin Interaction with NavBarVisibilityMixin

`SearchFilterMixin` calls `setSearchFocused()` and `setFilterPanelOpen()` from `NavBarVisibilityMixin`. This creates a dependency:

**Option A:** Require both mixins via `on State<T>, NavBarVisibilityMixin<T>` -- too restrictive and breaks if any screen doesn't use NavBarVisibilityMixin.

**Option B (recommended):** Make the nav bar calls conditional. Check if `this` implements `NavBarVisibilityMixin` at runtime, or simply require the caller screen to also mix in `NavBarVisibilityMixin` as all 5 screens already do. The simplest approach: `SearchFilterMixin` defines abstract or overridable methods for nav bar integration that `NavBarVisibilityMixin` satisfies.

**Simplest solution:** Since ALL 5 screens already use `NavBarVisibilityMixin`, declare the mixin as:
```dart
mixin SearchFilterMixin<T extends StatefulWidget> on State<T> {
```
And call `setSearchFocused`/`setFilterPanelOpen` only if `this is NavBarVisibilityMixin`. This keeps the mixin loosely coupled.

### Project Structure

```
lib/mixins/
  search_filter_mixin.dart    # NEW
  database_provider_mixin.dart # existing
  form_base_mixin.dart         # existing
  nav_bar_visibility_mixin.dart # existing
  pagination_mixin.dart        # existing

test/mixins/
  search_filter_mixin_test.dart    # NEW
  database_provider_mixin_test.dart # existing
  form_base_mixin_test.dart         # existing
  nav_bar_visibility_mixin_test.dart # existing
  pagination_mixin_test.dart        # existing
```

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Search debounce | Custom Timer management | Keep Timer in mixin (it IS the standard pattern) | Timer + 300ms is the correct Flutter pattern; no library needed |
| Focus management | Custom focus tracking | Keep FocusNode in mixin | FocusNode is Flutter's built-in solution |
| Filter state | Complex state management (BLoC, Riverpod) | Simple setState in mixin | Matches existing project pattern (Provider + setState), no need to introduce new state management |

## Common Pitfalls

### Pitfall 1: Mixin Order Matters in Dart
**What goes wrong:** If `SearchFilterMixin` overrides `initState`/`dispose` and is mixed in before or after other mixins that also override these, the super chain could skip calls.
**Why it happens:** Dart mixin linearization means the LAST mixin in the `with` clause is called first.
**How to avoid:** Ensure `SearchFilterMixin` always calls `super.initState()` and `super.dispose()`. Document the expected mixin order. Test with the exact mixin combinations used in each screen.
**Warning signs:** Missing dispose calls (Timer not cancelled, FocusNode not disposed), search not initializing.

### Pitfall 2: setState After Dispose
**What goes wrong:** The debounce Timer fires after the widget is disposed, calling `setState` on a disposed State.
**Why it happens:** Timer is async; user navigates away before debounce completes.
**How to avoid:** Cancel `_searchDebounce` in `dispose()`. Also guard the Timer callback with `if (mounted)` before calling `setState`.
**Warning signs:** "setState() called after dispose()" error in console.

### Pitfall 3: Breaking BookingsScreen Pagination
**What goes wrong:** After extraction, bookings no longer reloads data when search/filter changes.
**Why it happens:** The `_loadInitial()` call in `_onSearchChanged` and `_onFilterRulesChanged` is bookings-specific.
**How to avoid:** The `onSearchFilterChanged()` hook must be called AFTER state is updated but BEFORE the end of the method. BookingsScreen overrides this to call its `_loadInitial()`.
**Warning signs:** Search works visually but list doesn't update. Filters apply but stale data remains.

### Pitfall 4: Public vs Private State Fields
**What goes wrong:** Mixin fields need to be accessed in `build()` of the screen, but `_private` fields from a mixin are accessible within the mixin but need to be used in the class that mixes it in.
**Why it happens:** Dart's privacy model: `_foo` is library-private. If the mixin is in a different file, `_foo` is not accessible from the screen file.
**How to avoid:** Use **public field names** (no underscore) for state that the screen's `build()` method needs to read: `showSearchBar`, `searchQuery`, `filterRules`, `searchController`, `searchFocusNode`, etc. Use `_private` only for internal implementation details like `_searchDebounce`.
**Warning signs:** Compilation errors when refactoring screens to use mixin fields.

### Pitfall 5: NavBarVisibilityMixin Coupling
**What goes wrong:** Runtime error or missing nav bar hide behavior because `SearchFilterMixin` tries to call `setSearchFocused` which doesn't exist.
**Why it happens:** `SearchFilterMixin` needs to notify NavBarVisibilityMixin about focus/filter panel state.
**How to avoid:** Use a runtime check: `if (this is NavBarVisibilityMixin)` or define the callbacks within SearchFilterMixin as overridable no-ops.
**Warning signs:** Nav bar doesn't hide when search is focused, or runtime NoSuchMethodError.

## Code Examples

### Mixin Implementation Pattern (verified from existing project mixins)

```dart
// Source: Following pattern of lib/mixins/pagination_mixin.dart and nav_bar_visibility_mixin.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../models/filter/filter_rule.dart';

mixin SearchFilterMixin<T extends StatefulWidget> on State<T> {
  // Public state (accessed by screen build methods)
  bool showSearchBar = false;
  final TextEditingController searchController = TextEditingController();
  String searchQuery = '';
  final FocusNode searchFocusNode = FocusNode();

  List<FilterRule> filterRules = [];
  bool showFilterPanel = false;

  // Private implementation
  Timer? _searchDebounce;

  // Computed properties
  int get activeFilterCount => filterRules.length;
  double get searchBarSpace => showSearchBar ? 60.0 : 0.0;

  /// Override in screens that need side effects on search/filter change
  /// (e.g., BookingsScreen calls _loadInitial())
  void onSearchFilterChanged() {}

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
    // Dynamic dispatch to NavBarVisibilityMixin if present
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
}
```

### Refactored Screen Pattern (accounts_screen.dart example)

```dart
class _AccountsScreenState extends State<AccountsScreen>
    with NavBarVisibilityMixin<AccountsScreen>,
         SearchFilterMixin<AccountsScreen> {

  // No more search/filter state declarations
  // No more _onSearchChanged, _toggleSearch, _onFilterRulesChanged, etc.
  // No more search/filter dispose logic

  @override
  void dispose() {
    restoreNavBarVisibility();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ... use showSearchBar, searchQuery, filterRules, etc. directly
    // ... use searchBarSpace instead of computing it
    // ... pass onSearchChanged, toggleSearch, onFilterRulesChanged
  }
}
```

### Refactored BookingsScreen (the pagination case)

```dart
class _BookingsScreenState extends State<BookingsScreen>
    with DatabaseProviderMixin<BookingsScreen>,
         NavBarVisibilityMixin<BookingsScreen>,
         SearchFilterMixin<BookingsScreen> {

  // Pagination state...

  @override
  void onSearchFilterChanged() {
    // This is the hook -- reload pagination when search/filter changes
    _loadInitial();
  }

  // No more search/filter state or methods
}
```

### Test Pattern (following existing mixin test conventions)

```dart
// Source: Following pattern of test/mixins/pagination_mixin_test.dart
class _TestSearchFilterWidget extends StatefulWidget {
  final VoidCallback? onSearchFilterChanged;
  const _TestSearchFilterWidget({super.key, this.onSearchFilterChanged});

  @override
  State<_TestSearchFilterWidget> createState() => _TestSearchFilterWidgetState();
}

class _TestSearchFilterWidgetState extends State<_TestSearchFilterWidget>
    with SearchFilterMixin<_TestSearchFilterWidget> {

  @override
  void onSearchFilterChanged() {
    widget.onSearchFilterChanged?.call();
  }

  @override
  Widget build(BuildContext context) => const SizedBox();
}

void main() {
  testWidgets('initializes with default state', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: _TestSearchFilterWidget())),
    );
    final state = tester.state<_TestSearchFilterWidgetState>(
      find.byType(_TestSearchFilterWidget),
    );
    expect(state.showSearchBar, isFalse);
    expect(state.searchQuery, isEmpty);
    expect(state.filterRules, isEmpty);
    expect(state.showFilterPanel, isFalse);
    expect(state.activeFilterCount, 0);
    expect(state.searchBarSpace, 0.0);
  });
  // ... more tests
}
```

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | flutter_test (SDK bundled) |
| Config file | `pubspec.yaml` (flutter_test dev dependency) |
| Quick run command | `flutter test test/mixins/search_filter_mixin_test.dart` |
| Full suite command | `flutter test` |

### Phase Requirements -> Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| R3.1 | Mixin state initialization | unit | `flutter test test/mixins/search_filter_mixin_test.dart -x` | Wave 0 |
| R3.1 | Search debounce logic | unit | `flutter test test/mixins/search_filter_mixin_test.dart -x` | Wave 0 |
| R3.1 | Toggle search show/hide | unit | `flutter test test/mixins/search_filter_mixin_test.dart -x` | Wave 0 |
| R3.1 | Filter rules change | unit | `flutter test test/mixins/search_filter_mixin_test.dart -x` | Wave 0 |
| R3.1 | Filter panel open/close | unit | `flutter test test/mixins/search_filter_mixin_test.dart -x` | Wave 0 |
| R3.1 | onSearchFilterChanged hook | unit | `flutter test test/mixins/search_filter_mixin_test.dart -x` | Wave 0 |
| R3.1 | Dispose cleanup | unit | `flutter test test/mixins/search_filter_mixin_test.dart -x` | Wave 0 |
| R3.2 | Accounts screen regression | integration | `flutter test test/screens/accounts_screen_test.dart -x` | Exists |
| R3.2 | Assets screen regression | integration | `flutter test test/screens/assets_screen_test.dart -x` | Exists |
| R3.2 | Bookings screen regression | integration | `flutter test test/screens/bookings_screen_test.dart -x` | Exists |
| R3.2 | Trades screen regression | integration | `flutter test test/screens/trades_screen_test.dart -x` | Exists |
| R3.2 | Transfers screen regression | integration | `flutter test test/screens/transfers_screen_test.dart -x` | Exists |

### Sampling Rate
- **Per task commit:** `flutter test test/mixins/search_filter_mixin_test.dart`
- **Per wave merge:** `flutter test`
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `test/mixins/search_filter_mixin_test.dart` -- covers R3.1, R3.3
- No framework install needed (flutter_test already configured)
- No shared fixtures needed (test widget is self-contained)

## Risks and Mitigations

### Risk 1: Mixin Ordering with Multiple Mixins (MEDIUM)
Some screens use 3 mixins: `DatabaseProviderMixin`, `NavBarVisibilityMixin`, and now `SearchFilterMixin`. Additionally, `TradesScreen` and `TransfersScreen` use `SingleTickerProviderStateMixin`.

**Mitigation:** Dart handles linear mixin chains correctly as long as all mixins call `super`. Verify by running all screen tests after each refactoring.

### Risk 2: BookingsScreen's Split Show/Hide (LOW)
BookingsScreen uses `_showSearch()` / `_hideSearch()` instead of `_toggleSearch()`. The mixin uses `toggleSearch()`.

**Mitigation:** `toggleSearch()` handles both show and hide in a single method (which is what 4/5 screens already do). BookingsScreen can simply use `toggleSearch()` since the logic is equivalent. The only added behavior is calling `onSearchFilterChanged()` which BookingsScreen implements to reload pagination.

### Risk 3: Breaking Existing Tests (MEDIUM)
The 5 existing screen test files don't directly test search/filter behavior -- they test display, interaction, and deletion flows. However, they still instantiate the full screen widget and may indirectly depend on internal state management.

**Mitigation:** Run ALL existing screen tests after each refactoring step. The mixin changes state field names from `_private` to `public`, but since tests don't access these directly (they use the widget testing API), this should be transparent.

## Open Questions

1. **NavBarVisibilityMixin coupling approach**
   - What we know: All 5 screens already use NavBarVisibilityMixin. A runtime check (`this is NavBarVisibilityMixin`) works.
   - What's unclear: Is there a cleaner Dart pattern than runtime type checking for this? Dart 3 pattern matching (`this case NavBarVisibilityMixin m`) is cleaner.
   - Recommendation: Use Dart 3 pattern matching. It is supported (SDK >=3.2.3) and is the idiomatic approach.

2. **Naming: fields public without underscore**
   - What we know: Mixin private fields (`_foo`) are library-private in Dart. Since the mixin lives in a different file, screens cannot access `_foo`.
   - What's unclear: Does the project have a convention about public mixin fields?
   - Recommendation: Follow existing pattern -- `PaginationMixin` uses public fields (`items`, `isLoading`, `hasMore`, `currentLimit`, `scrollController`). Do the same for `SearchFilterMixin`.

## Sources

### Primary (HIGH confidence)
- Direct source code analysis of all 5 screen files in `lib/screens/`
- Direct source code analysis of all 4 existing mixins in `lib/mixins/`
- Direct source code analysis of all 4 existing mixin tests in `test/mixins/`
- Direct source code analysis of `lib/models/filter/filter_rule.dart` and `filter_config.dart`

### Secondary (MEDIUM confidence)
- Dart language specification for mixin linearization and `super` call ordering

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - No new libraries needed; pure refactoring of existing code
- Architecture: HIGH - Pattern verified against 4 existing mixins in same project
- Pitfalls: HIGH - All identified from direct code analysis of actual duplication and differences
- Duplicated code mapping: HIGH - Line-by-line comparison of all 5 screens completed

**Research date:** 2026-03-08
**Valid until:** Indefinite (internal refactoring, no external dependencies)
