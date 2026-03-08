# Requirements — Milestone 1.1.0: Code Quality & Architecture

## Milestone Goal
Improve XFin's code quality, test coverage, and architecture to create a more maintainable, testable, and consistent codebase. No new user-facing features — focus entirely on internal quality.

## Success Criteria
- All existing 512+ tests continue to pass
- Test coverage increased: 14 untested lib/ files gain test coverage
- Zero flutter analyze issues maintained
- Duplicated search/filter code extracted into reusable abstraction
- Large files (>500 lines) refactored into focused modules
- Dead code removed
- DAO APIs follow consistent patterns

---

## R1: Test Coverage for Untested Widgets
**Priority**: HIGH
**Rationale**: Core reusable widgets (form_fields.dart, filter widgets, charts, dialogs) have zero test coverage despite being used across multiple screens.

### Requirements
- R1.1: Add tests for `widgets/form_fields.dart` (602 lines, 15+ form field builders)
- R1.2: Add tests for `widgets/filter/filter_panel.dart`
- R1.3: Add tests for `widgets/filter/filter_rule_editor.dart`
- R1.4: Add tests for `widgets/filter/filter_value_inputs.dart` (324 lines)
- R1.5: Add tests for `widgets/charts.dart`
- R1.6: Add tests for `widgets/dialogs.dart`
- R1.7: Add tests for `widgets/reusables.dart` (309 lines)
- R1.8: Add tests for `widgets/inflow_outflow_toggle.dart`
- R1.9: Add tests for `widgets/analysis_line_chart_section.dart` (461 lines)

### Acceptance
- Each widget file has a corresponding `_test.dart` file
- Tests cover primary render paths, user interactions, and edge cases
- Aim for 100% statement coverage on new test files

---

## R2: Test Coverage for Untested Utilities & Providers
**Priority**: HIGH
**Rationale**: `database_provider.dart` and `modal_helper.dart` are used across the app but untested.

### Requirements
- R2.1: Add tests for `utils/modal_helper.dart`
- R2.2: Add tests for `constants/spacing.dart` (if non-trivial constants)

### Acceptance
- Each file has a corresponding test file
- Tests verify correct behavior and edge cases

---

## R3: Extract Search/Filter Pattern into Reusable Mixin
**Priority**: MEDIUM
**Rationale**: 5 screens (accounts, assets, bookings, trades, transfers) duplicate identical search/filter state management code (~30 lines each).

### Requirements
- R3.1: Create a `SearchFilterMixin` (or similar) extracting the common pattern:
  - `_showSearchBar`, `_searchController`, `_searchQuery`, `_searchDebounce`, `_searchFocusNode`
  - `_filterRules`, `_showFilterPanel`
  - `_onSearchChanged()`, `_toggleSearch()`, `_onFilterRulesChanged()`
- R3.2: Refactor all 5 screens to use the extracted mixin
- R3.3: Add tests for the extracted mixin

### Acceptance
- Zero code duplication of search/filter logic across screens
- All 5 screens use the shared abstraction
- Existing screen tests continue to pass
- Mixin has its own test file

---

## R4: Refactor Large Files
**Priority**: MEDIUM
**Rationale**: Several files exceed 500 lines, mixing multiple concerns.

### Requirements
- R4.1: Split `widgets/form_fields.dart` (602 lines) into focused modules grouped by field type (date fields, dropdown fields, text fields, etc.)
- R4.2: Refactor `screens/calendar_screen.dart` (922 lines) — extract pagination logic, data caching, and custom scroll physics into separate files
- R4.3: Review `database/daos/analysis_dao.dart` (773 lines) — extract timeframe calculation utilities into a separate helper

### Acceptance
- No non-generated file exceeds ~400 lines
- Each extracted module has clear single responsibility
- All existing tests pass after refactoring

---

## R5: DAO API Consistency & Cleanup
**Priority**: MEDIUM
**Rationale**: DAOs have inconsistent public/private method naming and over-declared table dependencies.

### Requirements
- R5.1: Standardize public/private method naming across all DAOs (consistent use of `_` prefix for internal methods)
- R5.2: Review and correct `@DriftAccessor(tables: [...])` declarations to match actual usage
- R5.3: Remove commented-out dead code in `trades_dao.dart` (~20 lines of CSV import code)
- R5.4: Remove or resolve `// ignore: unused_element` in `bookings_screen.dart`

### Acceptance
- All DAOs follow same naming convention for CRUD operations
- Table declarations match actual usage
- Zero commented-out code blocks
- Zero `ignore: unused_element` directives

---

## R6: Error Handling Improvement
**Priority**: LOW
**Rationale**: Only 2 explicit throw statements across all DAOs. Most database operations could fail silently.

### Requirements
- R6.1: Audit DAO methods for operations that should validate preconditions (e.g., account exists before booking, sufficient shares before sell)
- R6.2: Add appropriate error handling for critical write operations (insert, update, delete)
- R6.3: Ensure error messages use localized strings where user-facing

### Acceptance
- Critical write operations validate preconditions
- Errors are thrown with descriptive messages
- Tests cover error paths

---

## Out of Scope
- No new user-facing features
- No UI/UX changes
- No dependency upgrades
- No new screens or navigation changes
- No database schema changes
