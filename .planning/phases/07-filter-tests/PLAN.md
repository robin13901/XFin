# Phase 7 Plan — Filter Model & Widget Tests

## Overview
3 plans covering all filter model and widget test coverage. Ordered by dependency: pure models first, then config builders (need DB), then widgets (need both).

---

## Plan 07-01: Filter Model Unit Tests (filter_rule, filter_config)

**Goal**: Achieve 100% coverage on filter_rule.dart and filter_config.dart — the foundation classes.

### Tasks

#### Task 1: Expand test/models/filter/filter_rule_test.dart
Add missing coverage:

```dart
// Add to FilterRule group:
test('copyWith preserves unchanged fields', () {
  const original = FilterRule(fieldId: 'v', operator: FilterOperator.greaterThan, value: 100.0);
  final copied = original.copyWith(fieldId: 'x');
  expect(copied.fieldId, 'x');
  expect(copied.operator, FilterOperator.greaterThan);
  expect(copied.value, 100.0);
});

test('inequality for different fieldId', () { ... });
test('inequality for different operator', () { ... });
test('equality for empty list values', () { ... });
test('inequality for lists of different length', () { ... });
test('inequality when one value is List and other is scalar', () { ... }); // exercises _valueEquals branch where `a is List && b is List` is false
test('hashCode is consistent for equal rules', () { ... });
test('hashCode differs for unequal rules', () { ... });
```

**Estimated new tests**: ~9

#### Task 2: Create test/models/filter/filter_config_test.dart
Test DropdownOption, FilterConfig.getField, FilterConfig.getFieldsByType:

```dart
group('DropdownOption', () {
  test('creates correctly', () { ... });
});

group('FilterConfig', () {
  test('creates with title, fields, and optional loadDropdownOptions', () { ... });
  test('getField returns matching field by id', () { ... });
  test('getField returns null for unknown id', () { ... });
  test('getFieldsByType returns only matching fields', () { ... });
  test('getFieldsByType returns empty for no matches', () { ... });
});
```

**Estimated new tests**: ~6

### Success Criteria
- filter_rule.dart: 100% statement coverage (all branches of _valueEquals, all copyWith paths)
- filter_config.dart: 100% statement coverage (getField hit/miss, getFieldsByType filter)

---

## Plan 07-02: Filter Config Builder Tests (5 config files)

**Goal**: Test all 5 entity-specific filter config builders with 100% statement coverage.

### Approach
Each builder follows the same pattern:
1. Takes `l10n` (and optionally `db`)
2. Returns a `FilterConfig` with specific fields
3. Has a `loadDropdownOptions` callback with field-specific switch logic

Testing requires:
- **l10n**: Pump a localized widget to obtain `AppLocalizations` instance, OR use a generated locale directly
- **db**: In-memory database with test data for dropdown loading

### Shared Test Helper
Create a helper to get AppLocalizations for non-widget tests:

```dart
// In test/models/filter/filter_config_test_helper.dart
Future<AppLocalizations> getTestLocalizations() async {
  return AppLocalizations.delegate.load(const Locale('en'));
}
```

### Tasks

#### Task 1: Create test/models/filter/booking_filter_config_test.dart
```dart
group('buildBookingFilterConfig', () {
  test('returns FilterConfig with correct title', () { ... });
  test('has 7 fields (value, shares, category, notes, assetId, accountId, date)', () { ... });
  test('field types are correct (2 numeric, 2 text, 2 dropdown, 1 date)', () { ... });
  test('loadDropdownOptions for assetId returns assets used in bookings', () { ... });
  test('loadDropdownOptions for accountId returns non-archived accounts', () { ... });
  test('loadDropdownOptions for unknown field returns empty list', () { ... });
});
```

#### Task 2: Create test/models/filter/transfer_filter_config_test.dart
Same pattern — 7 fields, 3 dropdown fields. Test both `sendingAccountId` and `receivingAccountId` explicitly to confirm the OR branch is hit for each.

#### Task 3: Create test/models/filter/account_filter_config_test.dart
No database needed (dropdown loads from AccountTypes enum):
```dart
test('loadDropdownOptions for type returns all AccountTypes', () { ... });
```

#### Task 4: Create test/models/filter/trade_filter_config_test.dart
10 fields, most complex config. Test _getTradeTypeName via the dropdown options:
```dart
test('loadDropdownOptions for type returns all TradeTypes with localized names', () { ... });
test('loadDropdownOptions for assetId returns assets used in trades', () { ... });
test('loadDropdownOptions for sourceAccountId returns non-archived accounts', () { ... });
test('loadDropdownOptions for targetAccountId returns non-archived accounts', () { ... });
```

#### Task 5: Create test/models/filter/asset_filter_config_test.dart
No database needed. Test AssetTypes enum dropdown options.

### Success Criteria
- Each config builder file has 100% statement coverage
- All dropdown loading branches tested (each fieldId case + default/unknown case)
- All field counts and types verified

**Estimated new tests**: ~30-35 across 5 files

---

## Plan 07-03: Filter Widget Tests (filter_panel, filter_rule_editor, expand existing)

**Goal**: Test filter_panel.dart and filter_rule_editor.dart from scratch, expand 3 existing widget test files to 100% coverage.

### Tasks

#### Task 1: Create test/widgets/filter/filter_panel_test.dart
FilterPanel is a complex stateful widget. Test key behaviors:

```dart
group('FilterPanel', () {
  // Setup: create a FilterConfig with mixed field types

  testWidgets('renders header with title and close button', (tester) async { ... });
  testWidgets('starts in edit mode when no existing rules', (tester) async { ... });
  testWidgets('shows rules list when rules exist', (tester) async { ... });
  testWidgets('add rule button switches to edit mode', (tester) async { ... });
  testWidgets('delete rule removes it and calls onRulesChanged', (tester) async { ... });
  testWidgets('delete last rule closes panel', (tester) async { ... });
  testWidgets('clear all removes all rules and closes', (tester) async { ... });
  testWidgets('close button calls onClose', (tester) async { ... });
  testWidgets('formatValue displays date values correctly', (tester) async { ... });
  testWidgets('formatValue displays list values with truncation', (tester) async { ... });
  testWidgets('formatValue shows dash for null value', (tester) async { ... });
  testWidgets('formatValue shows dash for empty list', (tester) async { ... });
  testWidgets('formatValue falls back to toString for unknown date parse', (tester) async { ... });
  testWidgets('rule card shows fieldId when field not in config', (tester) async { ... });
  testWidgets('tapping rule card enters edit mode and saving updates the rule', (tester) async { ... });
  testWidgets('cancel during edit with empty rules closes panel', (tester) async { ... });
  testWidgets('cancel during edit of existing rule returns to list', (tester) async { ... });
});
```

**Estimated tests**: ~17

#### Task 2: Create test/widgets/filter/filter_rule_editor_test.dart
3-step editor flow (field → operator → value → save):

```dart
group('FilterRuleEditor', () {
  testWidgets('shows field selection chips', (tester) async { ... });
  testWidgets('selecting field shows operator selection', (tester) async { ... });
  testWidgets('auto-selects operator when field has only one', (tester) async { ... });
  testWidgets('selecting operator shows value input', (tester) async { ... });
  testWidgets('save button disabled until all selections made', (tester) async { ... });
  testWidgets('save button calls onSave with correct FilterRule', (tester) async { ... });
  testWidgets('cancel button calls onCancel', (tester) async { ... });
  testWidgets('pre-fills from existingRule', (tester) async { ... });
  testWidgets('changing field resets operator and value', (tester) async { ... });
  testWidgets('changing operator resets value', (tester) async { ... });
  testWidgets('numeric field shows NumericFilterInput', (tester) async { ... });
  testWidgets('text field shows TextFilterInput', (tester) async { ... });
  testWidgets('dropdown field shows DropdownFilterInput', (tester) async { ... });
  testWidgets('between operator shows NumericRangeInput', (tester) async { ... });
});
```

**Estimated tests**: ~14

#### Task 3: Expand test/widgets/filter/filter_value_inputs_test.dart
Add missing coverage for untested widgets:

```dart
group('NumericRangeInput', () {
  testWidgets('renders two NumericFilterInputs with from/to labels', (tester) async { ... });
  testWidgets('calls onChanged when both values set', (tester) async { ... });
});

group('DropdownFilterInput', () {
  testWidgets('shows loading indicator while options load', (tester) async { ... });
  testWidgets('renders FilterChips for each option', (tester) async { ... });
  testWidgets('toggles selection on tap', (tester) async { ... });
  testWidgets('calls onChanged with updated selection list', (tester) async { ... });
  testWidgets('pre-selects chips from selectedIds', (tester) async { ... });
});

group('DateFilterInput', () {
  testWidgets('renders date placeholder when no value', (tester) async { ... });
  testWidgets('displays formatted date from int value', (tester) async { ... });
  testWidgets('opens date picker on tap', (tester) async { ... });
  testWidgets('calls onChanged with YYYYMMDD int', (tester) async { ... });
});

group('DateRangeInput', () {
  testWidgets('renders two DateFilterInputs with from/to labels', (tester) async { ... });
});

group('getOperatorDisplayName', () {
  test('returns correct l10n string for each operator', () { ... });
});
```

**Estimated new tests**: ~14

#### Task 4: Expand test/widgets/filter/filter_badge_test.dart
Add boundary tests:

```dart
testWidgets('shows exact count for 9', (tester) async { ... });
testWidgets('shows 9+ for 10', (tester) async { ... });
testWidgets('shows 9+ for very large count', (tester) async { ... });
```

**Estimated new tests**: ~3

#### Task 5: Expand test/widgets/filter/liquid_glass_search_bar_test.dart
Add missing coverage:

```dart
testWidgets('hides clear button when text is empty', (tester) async { ... });
testWidgets('uses custom focusNode when provided', (tester) async { ... });
```

**Estimated new tests**: ~2

### Success Criteria
- filter_panel.dart: All state transitions tested (edit/view mode, add/delete/clear rules)
- filter_rule_editor.dart: Full 3-step flow tested, all input type dispatching verified
- filter_value_inputs.dart: All 5 input widgets tested + getOperatorDisplayName helper
- filter_badge.dart: Boundary values (9, 10) tested
- liquid_glass_search_bar.dart: Empty state and focusNode tested

---

## Execution Order
1. **Plan 07-01** (models) — no dependencies, pure unit tests
2. **Plan 07-02** (config builders) — needs Plan 01's filter_config tests as baseline
3. **Plan 07-03** (widgets) — needs config builders working for FilterPanel/FilterRuleEditor tests

## Ralph Loop
Each plan: implement tests → `flutter test` → fix failures → repeat → `flutter analyze` → fix issues → done.

## Total Estimated Tests
- Plan 01: ~15 new tests
- Plan 02: ~32 new tests
- Plan 03: ~50 new tests
- **Total: ~97 new tests**
