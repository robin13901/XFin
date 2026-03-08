# Roadmap — Milestone 1.2.0: UX Polish

## Overview
Fix UX issues with filter/search interactions across all list screens. 1 phase with 4 focused fixes.

---

## Phase 1: Filter & Search UX Fixes
**Goal**: Fix bottom nav visibility, filter input focus loss, and text capitalization.
**Effort**: Medium
**Risk**: Low (behavioral fixes, no structural changes)

### Tasks
1. **Hide bottom nav when filter panel is visible**
   - Screens: bookings, accounts, assets, trades, transfers
   - Mechanism: Pass `_navBarVisible` ValueNotifier from MainScreen to child screens via InheritedWidget
   - Set to false when `_showFilterPanel = true`, restore when filter closes

2. **Hide bottom nav when keyboard visible during search**
   - Same 5 screens
   - Listen to `MediaQuery.viewInsets.bottom > 0` when search has focus
   - Hide nav when keyboard is showing, restore when keyboard dismissed

3. **Fix filter input fields (focus loss + backwards typing + capitalization)**
   - Convert `TextFilterInput` and `NumericFilterInput` from StatelessWidget to StatefulWidget
   - Persist TextEditingController across rebuilds (root cause of focus loss)
   - Add `TextCapitalization.words` to text filter inputs

4. **Add TextCapitalization.words to search bar**
   - Update `LiquidGlassSearchBar` TextField

5. Write tests for all changes
6. Run `flutter test` + `flutter analyze`

### Success Criteria
- Bottom nav hidden when filter panel open (all 5 screens)
- Bottom nav hidden when keyboard visible during search (all 5 screens)
- Filter text inputs maintain focus while typing
- Filter text inputs use word capitalization
- Search bar uses word capitalization
- No design changes beyond explicitly requested behavior
- All tests pass, zero analyze issues
