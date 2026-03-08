# Milestone 1.2.0: UX Polish — Archive

**Status**: Complete
**Date**: 2026-03-08
**Commit range**: d5a7dc3 (single commit, combined with 1.1.0 phase 1 work)
**Phases**: 1
**Tests**: 650 (18 new)

## Overview
Fix UX issues with filter/search interactions across all 5 list screens. Single phase with 4 focused fixes.

## Accomplishments
1. **Hide bottom nav when filter panel is open** — Created `NavBarController` InheritedWidget and `NavBarVisibilityMixin` to control bottom nav bar visibility from child screens. Applied to bookings, accounts, assets, trades, transfers.
2. **Hide bottom nav when keyboard visible during search** — Implemented `_KeyboardObserver` using `WidgetsBindingObserver.didChangeMetrics()` to detect keyboard state from raw platform view insets (bypasses Scaffold's viewInsets consumption).
3. **Fix filter input focus loss and backwards typing** — Converted `TextFilterInput` and `NumericFilterInput` from `StatelessWidget` to `StatefulWidget` to persist `TextEditingController` across rebuilds. Added `TextCapitalization.words` to text filter inputs.
4. **Search bar word capitalization** — Added `TextCapitalization.words` to `LiquidGlassSearchBar`.

## Key Technical Decisions
- Used `InheritedWidget` (`NavBarController`) for MainScreen children vs local `ValueNotifier` for pushed screens (assets, trades, transfers)
- Used `WidgetsBindingObserver` for keyboard detection instead of `MediaQuery.viewInsets` because nested `Scaffold` widgets consume viewInsets before child screens can read them
- `updateKeyboardVisibility()` kept as no-op for backwards compatibility

## Files Created
- `lib/widgets/nav_bar_controller.dart`
- `lib/mixins/nav_bar_visibility_mixin.dart`
- `test/widgets/nav_bar_controller_test.dart`
- `test/mixins/nav_bar_visibility_mixin_test.dart`
- `test/widgets/filter/filter_value_inputs_test.dart`

## Files Modified
- `lib/main.dart` — NavBarController wrapping
- `lib/screens/bookings_screen.dart` — mixin + visibility control
- `lib/screens/accounts_screen.dart` — mixin + visibility control
- `lib/screens/assets_screen.dart` — mixin + ValueListenableBuilder
- `lib/screens/trades_screen.dart` — mixin + ValueListenableBuilder
- `lib/screens/transfers_screen.dart` — mixin + ValueListenableBuilder
- `lib/widgets/filter/filter_value_inputs.dart` — StatefulWidget conversion
- `lib/widgets/filter/liquid_glass_search_bar.dart` — TextCapitalization.words
- `test/widgets/filter/liquid_glass_search_bar_test.dart` — new test

## Phase 1: Filter & Search UX Fixes
**Goal**: Fix bottom nav visibility, filter input focus loss, and text capitalization.
**Effort**: Medium | **Risk**: Low
**Result**: All 4 fixes implemented. 650 tests pass, zero analyze issues.
