# Roadmap — Milestone 1.1.0: Code Quality & Architecture

## Overview
7 phases focused on internal quality improvements. No new features. Ordered by dependency and impact.

---

## Phase 1: Dead Code Cleanup & DAO Consistency
**Goal**: Clean foundation before larger refactors.
**Requirements**: R5.1, R5.2, R5.3, R5.4
**Effort**: Small
**Risk**: Low

### Tasks
1. Remove commented-out CSV import code in `trades_dao.dart` (lines 315-334)
2. Remove/resolve `// ignore: unused_element` in `bookings_screen.dart`
3. Standardize DAO public/private method naming convention
4. Audit and correct `@DriftAccessor(tables: [...])` declarations
5. Run `flutter test` + `flutter analyze` to verify no regressions

### Success Criteria
- Zero commented-out code blocks in DAOs
- Consistent `_` prefix usage for internal DAO methods
- All table declarations match actual usage
- All 512+ tests pass

---

## Phase 2: Extract Search/Filter Mixin
**Goal**: Eliminate duplicated search/filter code across 5 screens.
**Requirements**: R3.1, R3.2, R3.3
**Effort**: Medium
**Risk**: Medium (touches 5 screens)

### Tasks
1. Create `lib/mixins/search_filter_mixin.dart` extracting common pattern
2. Refactor `accounts_screen.dart` to use mixin
3. Refactor `assets_screen.dart` to use mixin
4. Refactor `bookings_screen.dart` to use mixin
5. Refactor `trades_screen.dart` to use mixin
6. Refactor `transfers_screen.dart` to use mixin
7. Add `test/mixins/search_filter_mixin_test.dart`
8. Run all existing screen tests to verify no regressions

### Success Criteria
- Zero duplicated search/filter logic across screens
- All 5 screens use shared mixin
- New mixin has comprehensive tests
- All existing screen tests pass

---

## Phase 3: Refactor Large Files
**Goal**: Split oversized files into focused, single-responsibility modules.
**Requirements**: R4.1, R4.2, R4.3
**Effort**: Medium
**Risk**: Medium (structural changes)
**Plans:** 3 plans

Plans:
- [x] 03-01-PLAN.md — Split form_fields.dart into mixin-based modules with barrel file
- [x] 03-02-PLAN.md — Extract calendar_screen.dart widgets into screens/calendar/ subdirectory
- [x] 03-03-PLAN.md — Extract timeframe helpers and data classes from analysis_dao.dart

### Tasks
1. Split `form_fields.dart` (602 lines) into focused modules:
   - `form_fields/date_fields.dart`
   - `form_fields/dropdown_fields.dart`
   - `form_fields/text_fields.dart`
   - `form_fields/form_fields.dart` (barrel file)
2. Refactor `calendar_screen.dart` (922 lines):
   - Extract `_SnappyPageScrollPhysics` to `utils/snappy_scroll_physics.dart`
   - Extract calendar data loading/caching logic
3. Extract timeframe calculation utilities from `analysis_dao.dart` to `utils/timeframe_helper.dart`
4. Update all imports across the codebase
5. Run `flutter test` + `flutter analyze`

### Success Criteria
- No non-generated source file exceeds ~400 lines
- Each extracted module has clear single responsibility
- All tests pass after restructuring

---

## Phase 4: Test Coverage — Widget Tests
**Goal**: Add tests for all untested widget files.
**Requirements**: R1.1, R1.2, R1.3, R1.4, R1.5, R1.6, R1.7, R1.8, R1.9
**Effort**: Large (9 widget files to test)
**Risk**: Low (additive, no existing code changes)

### Tasks
1. Add `test/widgets/form_fields_test.dart` (or per-module tests after Phase 3 split)
2. Add `test/widgets/filter/filter_panel_test.dart`
3. Add `test/widgets/filter/filter_rule_editor_test.dart`
4. Add `test/widgets/filter/filter_value_inputs_test.dart`
5. Add `test/widgets/charts_test.dart`
6. Add `test/widgets/dialogs_test.dart`
7. Add `test/widgets/reusables_test.dart`
8. Add `test/widgets/inflow_outflow_toggle_test.dart`
9. Add `test/widgets/analysis_line_chart_section_test.dart`
10. Run full test suite to verify

### Success Criteria
- Every widget file under `lib/widgets/` has a corresponding test
- Tests cover primary render paths and user interactions
- Aim for 100% statement coverage on new tests

---

## Phase 5: Test Coverage — Utilities & Providers
**Goal**: Close remaining test coverage gaps.
**Requirements**: R2.1, R2.2
**Effort**: Small
**Risk**: Low

### Tasks
1. Add `test/utils/modal_helper_test.dart`
2. Add `test/constants/spacing_test.dart` (if non-trivial)
3. Run full test suite

### Success Criteria
- All utility and provider files have test coverage
- Full test suite passes

---

## Phase 6: Error Handling Improvement
**Goal**: Add validation and error handling to critical DAO operations.
**Requirements**: R6.1, R6.2, R6.3
**Effort**: Medium
**Risk**: Medium (changes behavior of write operations)

### Tasks
1. Audit all DAO write methods for missing precondition validation
2. Add validation to critical operations:
   - Account existence checks before booking/transfer
   - Sufficient shares/balance checks before sell/withdrawal
   - Asset existence checks before trade
3. Add localized error messages for new validations
4. Add tests for all new error paths
5. Run `flutter test` + `flutter analyze`

### Success Criteria
- Critical write operations validate preconditions before executing
- Error messages use localized strings
- Error paths have test coverage
- All tests pass

---

## Phase 7: Test Coverage — Filter Models & Filter Widgets
**Goal**: Add comprehensive tests for all filter model classes and filter widget files.
**Requirements**: R1.2, R1.3, R1.4
**Effort**: Medium (7 model files + 2 widget files to test)
**Risk**: Low (additive, no existing code changes)
**Plans:** 3 plans

Plans:
- [x] 07-01-PLAN.md — Filter model unit tests (filter_rule expansion, filter_config)
- [x] 07-02-PLAN.md — Filter config builder tests (5 entity configs)
- [x] 07-03-PLAN.md — Filter widget tests (filter_panel, filter_rule_editor, expand existing)

### Tasks
1. Add `test/models/filter/filter_config_test.dart` (base FilterConfig)
2. Add `test/models/filter/booking_filter_config_test.dart`
3. Add `test/models/filter/transfer_filter_config_test.dart`
4. Add `test/models/filter/account_filter_config_test.dart`
5. Add `test/models/filter/trade_filter_config_test.dart`
6. Add `test/models/filter/asset_filter_config_test.dart`
7. Add `test/widgets/filter/filter_panel_test.dart`
8. Add `test/widgets/filter/filter_rule_editor_test.dart`
9. Expand existing `test/models/filter/filter_rule_test.dart` if coverage gaps found
10. Expand existing `test/widgets/filter/filter_badge_test.dart`, `filter_value_inputs_test.dart`, `liquid_glass_search_bar_test.dart` if coverage gaps found
11. Run full test suite + `flutter analyze`

### Success Criteria
- Every file under `lib/models/filter/` has a corresponding test with 100% statement coverage
- Every file under `lib/widgets/filter/` has a corresponding test with 100% statement coverage
- Existing tests for `filter_rule`, `filter_badge`, `filter_value_inputs`, and `liquid_glass_search_bar` are expanded to cover any gaps
- All tests pass, zero analyze issues

---

## Phase Dependencies
```
Phase 1 (cleanup) ──→ Phase 2 (search/filter mixin)
                  ──→ Phase 3 (refactor large files) ──→ Phase 4 (widget tests)
                                                     ──→ Phase 5 (utility tests)
Phase 1 ──→ Phase 6 (error handling)
Phase 2 ──→ Phase 7 (filter model & widget tests)
```

Phase 1 should be done first (clean baseline). Phases 2, 3, and 6 can be done in parallel after Phase 1. Phases 4 and 5 depend on Phase 3 (test the refactored structure). Phase 7 depends on Phase 2 (filter mixin may affect filter widget behavior).
