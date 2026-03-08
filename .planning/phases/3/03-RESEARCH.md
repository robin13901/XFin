# Phase 3: Refactor Large Files - Research

**Researched:** 2026-03-08
**Domain:** Flutter/Dart file splitting and module extraction
**Confidence:** HIGH

## Summary

Phase 3 targets three oversized files for decomposition into focused, single-responsibility modules. The analysis is based on complete reading of all three source files, their test files, and all import consumers across the codebase.

**form_fields.dart** (602 lines) is a single `FormFields` class containing 15 widget-building methods. These naturally group into date/time fields (2 methods), dropdown fields (6 methods), text/numeric fields (5 methods), and layout helpers (2 methods). All consumers import through `../form_fields.dart` or `package:xfin/widgets/form_fields.dart`. A barrel file re-exporting from subdirectory modules will allow all 8 consumer files to update to a single import path.

**calendar_screen.dart** (922 lines) contains 12 classes: the main screen widget+state, a private scroll physics class, 5 private display widgets, 3 private data classes, and 1 pager widget+state. `_SnappyPageScrollPhysics` is self-contained (28 lines) and used in 2 places within the file. The data loading/caching logic is tightly coupled to the `_CalendarScreenState`, but the summary section (3 widgets totaling ~200 lines) and day details pager (~170 lines) can be extracted to separate files.

**analysis_dao.dart** (770 lines) has 6 private timeframe utility methods (lines 21-98) that perform date-integer conversions and month/timeframe boundary calculations. These are used by 15+ DAO query methods. Extracting them to standalone functions in a `timeframe_helper.dart` reduces the DAO to ~670 lines. The two data classes (`MonthlyAnalysisSnapshot`, `CalendarDayDetails`, lines 732-769) could also be moved to a models file to further reduce the DAO size below 400 lines.

**Primary recommendation:** Execute in order: (1) form_fields split (lowest risk, barrel file makes import changes trivial), (2) calendar_screen extraction (moderate risk, private classes need to become public), (3) analysis_dao extraction (moderate risk, private methods become top-level functions with changed signatures).

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| R4.1 | Split `widgets/form_fields.dart` (602 lines) into focused modules grouped by field type | FormFields class has 15 methods in clear groupings: date (2), dropdown (6), text/numeric (5), layout (2). Barrel file approach preserves existing import paths. |
| R4.2 | Refactor `screens/calendar_screen.dart` (922 lines) -- extract pagination logic, data caching, and custom scroll physics | _SnappyPageScrollPhysics is 28 lines, self-contained. Summary section (3 widgets, ~200 lines) and day details pager (~170 lines) are extractable. Data caching is coupled to state. |
| R4.3 | Review `database/daos/analysis_dao.dart` (770 lines) -- extract timeframe calculation utilities | 6 private timeframe utilities (lines 21-98, ~78 lines) plus 2 data classes (lines 732-769, ~38 lines) are extractable, reducing DAO to ~650 lines. |
</phase_requirements>

## Current File Analysis

### 1. `lib/widgets/form_fields.dart` (602 lines)

**Structure:** Single `FormFields` class with constructor taking `(AppLocalizations, Validator, BuildContext)`.

| Line Range | Method | Category | Description |
|------------|--------|----------|-------------|
| 19-71 | `dateAndAssetRow()` | Date + Dropdown combo | Date picker + asset dropdown in a Row |
| 73-91 | `sharesField()` | Text/Numeric | Shares input with asset-aware suffix |
| 93-122 | `sharesAndCostBasisRow()` | Text/Numeric | Shares + cost basis in a Row |
| 124-133 | `notesField()` | Text | Simple text input for notes |
| 135-170 | `categoryField()` | Text | Autocomplete category input |
| 172-201 | `accountDropdown()` | Dropdown | Account selector with validation |
| 203-226 | `assetsDropdown()` | Dropdown | Asset selector |
| 228-262 | `cyclesDropdown()` | Dropdown | Cycle frequency selector |
| 264-279 | `footerButtons()` | Layout | Cancel/Save button row |
| 293-316 | `basicTextField()` | Text | Generic labeled text input |
| 331-384 | `dateTimeField()` | Date | Date+time picker field |
| 403-454 | `numericInputRow()` | Text/Numeric | Two numeric fields side by side |
| 467-502 | `accountTypeDropdown()` | Dropdown | Account type selector |
| 515-535 | `assetTypeDropdown()` | Dropdown | Asset type selector |
| 549-572 | `tradeTypeDropdown()` | Dropdown | Trade type selector |
| 587-601 | `checkboxField()` | Layout | Styled checkbox list tile |

**Dependencies (imports):**
- `flutter/material.dart`
- `xfin/l10n/app_localizations.dart`
- `xfin/utils/format.dart`
- `../database/app_database.dart`
- `../database/tables.dart`
- `../providers/base_currency_provider.dart`
- `../utils/date_picker_locale.dart`
- `../utils/global_constants.dart`
- `../utils/validators.dart`

**Consumers (8 files):**
| File | Import Path |
|------|-------------|
| `lib/mixins/form_base_mixin.dart` | `../widgets/form_fields.dart` |
| `lib/widgets/forms/account_form.dart` | `../form_fields.dart` |
| `lib/widgets/forms/asset_form.dart` | `../form_fields.dart` |
| `lib/widgets/forms/booking_form.dart` | `../form_fields.dart` |
| `lib/widgets/forms/periodic_booking_form.dart` | `../form_fields.dart` |
| `lib/widgets/forms/periodic_transfer_form.dart` | `../form_fields.dart` |
| `lib/widgets/forms/trade_form.dart` | `../form_fields.dart` |
| `lib/widgets/forms/transfer_form.dart` | `package:xfin/widgets/form_fields.dart` |
| `test/widgets/forms/form_fields_test.dart` | `package:xfin/widgets/form_fields.dart` |

### 2. `lib/screens/calendar_screen.dart` (922 lines)

**Structure:** 12 classes in a single file.

| Line Range | Class | Type | Lines | Extractable? |
|------------|-------|------|-------|-------------|
| 20-25 | `CalendarScreen` | StatefulWidget | 6 | No (entry point) |
| 28-55 | `_SnappyPageScrollPhysics` | ScrollPhysics | 28 | YES -- self-contained, reusable |
| 57-443 | `_CalendarScreenState` | State | 387 | No (main state, but some methods extractable) |
| 445-461 | `_MonthHeader` | StatelessWidget | 17 | YES -- independent display widget |
| 463-529 | `_MonthSummarySection` | StatelessWidget | 67 | YES -- display only |
| 532-615 | `_CategoryListWrapper` | StatelessWidget | 84 | YES -- display only |
| 617-627 | `_CalendarScreenData` | Data class | 11 | YES -- simple data holder |
| 629-805 | `_MonthGrid` | StatelessWidget | 177 | YES -- large, independent display |
| 807-812 | `_DayDetailsPage` | Data class | 6 | YES -- simple data holder |
| 814-824 | `_SimpleDetailRow` | Data class | 11 | YES -- simple data holder |
| 826-833 | `_DayDetailsPager` | StatefulWidget | 8 | YES -- display only |
| 836-922 | `_DayDetailsPagerState` | State | 87 | YES -- display only |

**Key observations:**
- `_SnappyPageScrollPhysics` is used at lines 394 and 885 within the file. When extracted, it must become public (`SnappyPageScrollPhysics`).
- The data caching logic (lines 69-149: `_monthFutureCache`, `_monthDataCache`, `_ensureMonthData`, `_prefetchAround`, etc.) is tightly coupled to `_CalendarScreenState` via `context.read<DatabaseProvider>()` and `mounted` checks. Extracting to a separate class would require significant refactoring with unclear benefit.
- The day details dialog builder (lines 152-311: `_openDayDetails`, `_buildDetailPages`, `_compactList`, `_statLine`) is tightly coupled to `_CalendarScreenState` methods and could be extracted as a separate widget but the private helper methods would need restructuring.

**Consumers (1 file):**
| File | Import Path |
|------|-------------|
| `lib/widgets/more_pane.dart` | `package:xfin/screens/calendar_screen.dart` |

**Test file:** `test/screens/calendar_screen_test.dart` (257 lines)

### 3. `lib/database/daos/analysis_dao.dart` (770 lines)

**Structure:** `AnalysisDao` class (730 lines) + 2 data classes (38 lines).

**Private timeframe utility methods (lines 21-98):**

| Line Range | Method | Signature | Description |
|------------|--------|-----------|-------------|
| 21-28 | `_getMonthStartEnd` | `(int, int) fn(DateTime)` | Calculates month boundary date-ints |
| 32-45 | `_getMonthTimeframeIntersection` | `(int, int)? fn(DateTime)` | Intersects month with global filter dates |
| 47 | `_monthStartDateTimeInt` | `int fn(int)` | Converts date-int to datetime-int start |
| 49 | `_monthEndDateTimeInt` | `int fn(int)` | Converts date-int to datetime-int end |
| 51-94 | `_getDaysInTimeFrame` | `Future<int> fn()` | Calculates days in active timeframe (USES DB QUERIES) |
| 96-98 | `_getMonthsInTimeFrame` | `Future<double> fn()` | Days / 30.436875 |

**Data classes (lines 732-769):**

| Line Range | Class | Description |
|------------|-------|-------------|
| 732-746 | `MonthlyAnalysisSnapshot` | Monthly summary with inflows, outflows, profit, category maps |
| 749-769 | `CalendarDayDetails` | Day-level details with bookings, transfers, trades lists |

**External consumers of data classes:**
- `calendar_screen.dart` uses both `MonthlyAnalysisSnapshot` and `CalendarDayDetails`
- `test/database/daos/analysis_dao_test.dart` tests both
- `test/screens/analysis_screen_test.dart` mocks `AnalysisDao` (not the data classes directly)

**Key complexity:** `_getDaysInTimeFrame()` (lines 51-94) is NOT a pure utility -- it performs database queries (`selectOnly(bookings)`, `selectOnly(transfers)`, `selectOnly(trades)`) to find the earliest transaction date. This method cannot be trivially extracted to a standalone function without also passing the database accessors.

## Proposed Split Strategy

### Strategy 1: form_fields.dart -> form_fields/ directory

**Approach:** Keep the single `FormFields` class but split into partial-like files using Dart's `part`/`part of` mechanism, OR split into separate category files with a barrel file that re-exports everything.

**Recommended: Barrel file approach** (no `part` files -- cleaner, more maintainable).

```
lib/widgets/form_fields/
  form_fields.dart       # Barrel file: export all sub-modules
  date_fields.dart       # dateAndAssetRow(), dateTimeField()
  dropdown_fields.dart   # accountDropdown(), assetsDropdown(), cyclesDropdown(),
                         # accountTypeDropdown(), assetTypeDropdown(), tradeTypeDropdown()
  text_fields.dart       # sharesField(), sharesAndCostBasisRow(), notesField(),
                         # categoryField(), basicTextField(), numericInputRow()
  layout_fields.dart     # footerButtons(), checkboxField()
```

**Challenge:** The `FormFields` class is a single class with constructor state (`_l10n`, `_validator`, `_context`). Splitting methods across files requires one of:

1. **Extension methods on FormFields** -- each file adds methods to the base class. Dart does not support extension methods that access private fields. NOT viable.
2. **Mixins** -- each category is a mixin that the `FormFields` class uses. Mixins would need the l10n/validator/context passed via abstract getters. This works but adds complexity.
3. **Separate classes per category** -- `DateFields`, `DropdownFields`, `TextFields`, `LayoutFields` each take the same constructor params. The barrel file re-exports all. `FormFields` becomes a facade class delegating to sub-classes. Clean but changes the API slightly.
4. **Keep one class, just move the file** -- Move `form_fields.dart` into `form_fields/form_fields.dart` and create a barrel. This achieves the directory structure goal but doesn't split the class itself. The simplest approach, but doesn't reduce the 602-line file.
5. **Split into files using `part` directive** -- The class stays unified, but code lives in separate files. This keeps the API identical and splits the physical file size. Standard Dart approach.

**Recommended approach: `part` directive**. This is the standard Dart pattern for splitting a single class across files while maintaining the same API. No consumer code changes needed except import path updates if the file moves.

Actually, revisiting: the roadmap specifies separate files (`date_fields.dart`, `dropdown_fields.dart`, `text_fields.dart`, `form_fields.dart` barrel). The cleanest way to honor this is the **mixin approach**:

```dart
// date_fields.dart
mixin DateFieldsMixin {
  AppLocalizations get l10n;
  Validator get validator;
  BuildContext get formContext;

  Widget dateAndAssetRow(...) { ... }
  Widget dateTimeField(...) { ... }
}

// form_fields.dart (barrel / main class)
class FormFields with DateFieldsMixin, DropdownFieldsMixin, TextFieldsMixin, LayoutFieldsMixin {
  @override final AppLocalizations l10n;
  @override final Validator validator;
  @override final BuildContext formContext;
  FormFields(this.l10n, this.validator, this.formContext);
}
```

**HOWEVER**, the simplest and most idiomatic approach is the **`part` directive**:

```dart
// lib/widgets/form_fields/form_fields.dart
import ...;
part 'date_fields.dart';
part 'dropdown_fields.dart';
part 'text_fields.dart';
part 'layout_fields.dart';

class FormFields {
  final AppLocalizations _l10n;
  final Validator _validator;
  final BuildContext _context;
  FormFields(this._l10n, this._validator, this._context);
}

// lib/widgets/form_fields/date_fields.dart
part of 'form_fields.dart';
// (extension on FormFields containing the date methods)
// Actually: `part of` shares the class scope, so methods go directly inside the class.
```

Wait -- `part` files share the library scope, so all methods remain in the `FormFields` class. The class declaration can be split but each `part` file would need to contain method definitions within the class body. In Dart, you cannot split a class body across `part` files without the `augment` feature (Dart 3+ augmentations, still experimental).

**Final recommended approach:** Use the **mixin approach** as described above. Each mixin file is self-contained, the barrel file creates the unified `FormFields` class. This is clean, testable, and matches the roadmap's file structure exactly.

**Estimated line counts after split:**
- `date_fields.dart`: ~100 lines (2 methods + mixin boilerplate)
- `dropdown_fields.dart`: ~200 lines (6 methods + mixin boilerplate)
- `text_fields.dart`: ~200 lines (5 methods + mixin boilerplate)
- `layout_fields.dart`: ~40 lines (2 methods + mixin boilerplate)
- `form_fields.dart` (barrel): ~30 lines (class + re-exports)

### Strategy 2: calendar_screen.dart extraction

**Approach:** Extract into 3 files, keeping the main screen and state in the original file.

```
lib/screens/calendar_screen.dart           # CalendarScreen, _CalendarScreenState (remains ~390 lines)
lib/utils/snappy_scroll_physics.dart       # SnappyPageScrollPhysics (public, ~30 lines)
lib/screens/calendar/month_grid.dart       # _MonthGrid -> MonthGrid (~180 lines)
lib/screens/calendar/day_details.dart      # _DayDetailsPager, _DayDetailsPage, _SimpleDetailRow (~170 lines)
lib/screens/calendar/month_summary.dart    # _MonthSummarySection, _CategoryListWrapper, _MonthHeader (~170 lines)
lib/screens/calendar/calendar_data.dart    # _CalendarScreenData -> CalendarScreenData (~15 lines)
```

**Key changes required:**
1. `_SnappyPageScrollPhysics` becomes `SnappyPageScrollPhysics` (public) in `utils/snappy_scroll_physics.dart`
2. All `_` prefixed private widget classes become public when extracted to separate files
3. Data class `_CalendarScreenData` becomes public `CalendarScreenData`
4. Helper methods `_compactList`, `_statLine`, `_buildDetailPages` from `_CalendarScreenState` -- these are only used by `_openDayDetails`. They could move with the day details dialog or remain in the state.

**Risk assessment:** Making classes public changes the library API surface. Since these are internal screen widgets (not reusable), this is acceptable. The `_CalendarScreenState` with data loading/caching stays at ~390 lines (under 400 target).

**Estimated line counts after split:**
- `calendar_screen.dart`: ~390 lines (CalendarScreen + _CalendarScreenState + build methods)
- `snappy_scroll_physics.dart`: ~30 lines
- `month_grid.dart`: ~180 lines
- `day_details.dart`: ~170 lines
- `month_summary.dart`: ~170 lines
- `calendar_data.dart`: ~15 lines

**Alternative simpler approach:** Extract only `_SnappyPageScrollPhysics` and the summary/details widgets, keeping `_MonthGrid` in the main file. This reaches the ~400 line target with fewer file moves. However, the main file would be ~560 lines with MonthGrid included, which exceeds the target.

### Strategy 3: analysis_dao.dart timeframe extraction

**Approach:** Extract pure utility functions to `utils/timeframe_helper.dart`. Keep database-dependent methods in the DAO.

**Extractable as pure functions (no DB dependency):**
| Method | New Signature |
|--------|---------------|
| `_getMonthStartEnd(DateTime)` | `(int, int) getMonthStartEnd(DateTime date)` |
| `_getMonthTimeframeIntersection(DateTime)` | `(int, int)? getMonthTimeframeIntersection(DateTime date)` |
| `_monthStartDateTimeInt(int)` | `int monthStartDateTimeInt(int startDate)` |
| `_monthEndDateTimeInt(int)` | `int monthEndDateTimeInt(int endDate)` |

**NOT extractable as pure functions (requires DB access):**
| Method | Reason |
|--------|--------|
| `_getDaysInTimeFrame()` | Queries `bookings`, `transfers`, `trades` tables for min dates |
| `_getMonthsInTimeFrame()` | Calls `_getDaysInTimeFrame()` |

**Data classes extractable to separate file:**
| Class | Lines | Target File |
|-------|-------|-------------|
| `MonthlyAnalysisSnapshot` | 14 | `lib/database/models/analysis_models.dart` or keep in `analysis_dao.dart` |
| `CalendarDayDetails` | 21 | Same as above |

**Estimated line counts after extraction:**
- `timeframe_helper.dart`: ~50 lines (4 pure functions + imports)
- `analysis_dao.dart`: ~720 lines (still above 400)

**Problem:** Extracting only the pure timeframe helpers reduces the DAO by just ~50 lines (to ~720 lines), which is still well above the ~400 line target. To meaningfully reduce the DAO:

1. Extract data classes to `analysis_models.dart` (~35 lines saved)
2. Extract timeframe helpers (~50 lines saved)
3. Total reduction: ~85 lines -> DAO becomes ~685 lines

**This means the DAO will still exceed 400 lines** after the roadmap's proposed extraction. The DAO's bulk comes from 20+ query methods (each 10-30 lines) that are inherently coupled to the database. Further reduction would require splitting the DAO into multiple DAOs (e.g., `MonthlyAnalysisDao`, `CategoryAnalysisDao`), which is a larger architectural change not in scope.

**Recommendation:** Extract what's prescribed (timeframe helpers + data classes), accept that the DAO remains at ~650-680 lines. Document this as an acceptable exception since every method in the DAO is a genuine database query. The roadmap says "review" for analysis_dao (R4.3), not "must reduce to 400 lines."

## Import Dependency Map

### form_fields.dart consumers (9 files need updates)

| File | Current Import | New Import |
|------|---------------|------------|
| `lib/mixins/form_base_mixin.dart` | `../widgets/form_fields.dart` | `../widgets/form_fields/form_fields.dart` |
| `lib/widgets/forms/account_form.dart` | `../form_fields.dart` | `../form_fields/form_fields.dart` |
| `lib/widgets/forms/asset_form.dart` | `../form_fields.dart` | `../form_fields/form_fields.dart` |
| `lib/widgets/forms/booking_form.dart` | `../form_fields.dart` | `../form_fields/form_fields.dart` |
| `lib/widgets/forms/periodic_booking_form.dart` | `../form_fields.dart` | `../form_fields/form_fields.dart` |
| `lib/widgets/forms/periodic_transfer_form.dart` | `../form_fields.dart` | `../form_fields/form_fields.dart` |
| `lib/widgets/forms/trade_form.dart` | `../form_fields.dart` | `../form_fields/form_fields.dart` |
| `lib/widgets/forms/transfer_form.dart` | `package:xfin/widgets/form_fields.dart` | `package:xfin/widgets/form_fields/form_fields.dart` |
| `test/widgets/forms/form_fields_test.dart` | `package:xfin/widgets/form_fields.dart` | `package:xfin/widgets/form_fields/form_fields.dart` |

### calendar_screen.dart consumers (2 files need updates)

| File | Current Import | Change Needed? |
|------|---------------|---------------|
| `lib/widgets/more_pane.dart` | `package:xfin/screens/calendar_screen.dart` | NO -- CalendarScreen stays in this file |
| `test/screens/calendar_screen_test.dart` | `package:xfin/screens/calendar_screen.dart` | May need additional imports for extracted widgets if tests reference them |

**New imports needed by calendar_screen.dart itself:**
- `import '../utils/snappy_scroll_physics.dart';`
- `import 'calendar/month_grid.dart';`
- `import 'calendar/day_details.dart';`
- `import 'calendar/month_summary.dart';`
- `import 'calendar/calendar_data.dart';`

### analysis_dao.dart consumers (4 files, minimal changes)

| File | Current Import | Change Needed? |
|------|---------------|---------------|
| `lib/database/app_database.dart` | `daos/analysis_dao.dart` | NO |
| `lib/screens/calendar_screen.dart` | `../database/daos/analysis_dao.dart` | May need `import '../utils/timeframe_helper.dart'` only if using helpers directly -- unlikely |
| `test/database/daos/analysis_dao_test.dart` | `package:xfin/database/daos/analysis_dao.dart` | May need `import 'package:xfin/utils/timeframe_helper.dart'` if testing helpers |
| `test/screens/analysis_screen_test.dart` | `package:xfin/database/daos/analysis_dao.dart` | NO -- only mocks the DAO class |

**If data classes are extracted to `analysis_models.dart`:**
- `calendar_screen.dart` would need `import '../database/models/analysis_models.dart'`
- `test/database/daos/analysis_dao_test.dart` would need the models import
- `test/screens/analysis_screen_test.dart` likely unchanged

## Test Impact Analysis

### form_fields_test.dart (973 lines)

**Impact:** MEDIUM. The test file imports `package:xfin/widgets/form_fields.dart` and tests the `FormFields` class methods. Since the mixin approach preserves the `FormFields` class API, all tests should pass with only the import path change. No test logic changes needed.

**Required change:** Update import from `package:xfin/widgets/form_fields.dart` to `package:xfin/widgets/form_fields/form_fields.dart`.

### calendar_screen_test.dart (257 lines)

**Impact:** LOW-MEDIUM. The test file imports `CalendarScreen` which remains in the same file. If tests reference any private classes (they can't -- tests can't access private classes), no changes needed. If tests create mock data matching `_CalendarScreenData` structure (they might construct data through the DB), the public rename wouldn't affect tests.

**Required change:** Likely just verifying tests still pass. May need to import `snappy_scroll_physics.dart` if any test references the physics class (unlikely since it's private in the test's perspective).

### analysis_dao_test.dart (847 lines)

**Impact:** LOW. The test creates a real `AnalysisDao` instance and calls public methods. The timeframe helpers become internal implementation details of the DAO that are called through the public API. The data classes (`MonthlyAnalysisSnapshot`, `CalendarDayDetails`) are used in test assertions.

**Required change:** If data classes move to a separate file, add that import. Otherwise no changes.

## Risk Areas and Edge Cases

### Risk 1: FormFields constructor dependency chain
**What could go wrong:** The mixin approach requires abstract getters (`l10n`, `validator`, `formContext`) that all sub-mixins depend on. If the naming differs from the current `_l10n`, `_validator`, `_context` private fields, subtle bugs could occur.
**Mitigation:** Keep the same internal field names. The mixins use abstract getters that the main class implements using its private fields.

### Risk 2: Private-to-public visibility change in calendar_screen
**What could go wrong:** Making `_MonthGrid`, `_MonthSummarySection` etc. public exposes them in the library API. Other files could start importing and using them directly, creating unintended coupling.
**Mitigation:** The extracted files are in a `screens/calendar/` subdirectory, signaling they are screen-specific. Document that these are internal to the calendar screen. Consider using `@visibleForTesting` annotations where appropriate.

### Risk 3: Circular imports after calendar_screen split
**What could go wrong:** Extracted calendar widgets need to import data types from the main `calendar_screen.dart`, while the main file imports the extracted widgets. This could create circular imports.
**Mitigation:** Extract `CalendarScreenData` to its own file (`calendar_data.dart`) that both the main screen and extracted widgets import. Keep the data flow unidirectional.

### Risk 4: analysis_dao timeframe helpers accessing global state
**What could go wrong:** `_getMonthTimeframeIntersection` uses `filterStartDate` and `filterEndDate` from `global_constants.dart` (global mutable state). When extracted, these become top-level functions that still depend on global mutable state.
**Mitigation:** Pass `filterStartDate` and `filterEndDate` as parameters to the extracted functions instead of reading globals. This makes the functions pure and testable. The DAO calls them with the current global values.

### Risk 5: _getDaysInTimeFrame cannot be extracted
**What could go wrong:** The roadmap says "extract timeframe calculation utilities" but `_getDaysInTimeFrame` and `_getMonthsInTimeFrame` perform database queries. Naively extracting them breaks the Drift accessor pattern.
**Mitigation:** Only extract the 4 pure utility functions. Keep `_getDaysInTimeFrame` and `_getMonthsInTimeFrame` in the DAO. Document why.

### Risk 6: Generated file (analysis_dao.g.dart)
**What could go wrong:** Drift generates `analysis_dao.g.dart` from the `@DriftAccessor` annotation. Moving data classes out of `analysis_dao.dart` should not affect code generation since `MonthlyAnalysisSnapshot` and `CalendarDayDetails` are plain Dart classes (not Drift-generated). But verify by running `flutter pub run build_runner build` if classes are moved.
**Mitigation:** The data classes are NOT annotated with Drift annotations. They are plain Dart classes that happen to live in the same file. Moving them is safe.

## Recommended Implementation Order

### Wave 1: form_fields.dart split (lowest risk)
1. Create `lib/widgets/form_fields/` directory
2. Create mixin files: `date_fields.dart`, `dropdown_fields.dart`, `text_fields.dart`, `layout_fields.dart`
3. Create main `form_fields.dart` in the new directory combining all mixins
4. Update all 9 import paths (8 source + 1 test)
5. Delete old `lib/widgets/form_fields.dart`
6. Run `flutter test` + `flutter analyze`

### Wave 2: calendar_screen.dart extraction (moderate risk)
1. Create `lib/utils/snappy_scroll_physics.dart` -- extract and make public
2. Create `lib/screens/calendar/` directory
3. Extract `calendar_data.dart` (data class)
4. Extract `month_summary.dart` (MonthHeader, MonthSummarySection, CategoryListWrapper)
5. Extract `month_grid.dart` (MonthGrid)
6. Extract `day_details.dart` (DayDetailsPager, DayDetailsPage, SimpleDetailRow)
7. Update `calendar_screen.dart` imports and class references (remove `_` prefixes)
8. Run `flutter test` + `flutter analyze`

### Wave 3: analysis_dao.dart extraction (moderate risk)
1. Create `lib/utils/timeframe_helper.dart` with 4 pure functions
2. Update `analysis_dao.dart` to import and call the extracted functions
3. Optionally: extract `MonthlyAnalysisSnapshot` and `CalendarDayDetails` to `lib/database/models/analysis_models.dart`
4. Update consumer imports if data classes moved
5. Run `flutter test` + `flutter analyze`

## Architecture Patterns

### Mixin-based class splitting pattern (for FormFields)
```dart
// lib/widgets/form_fields/date_fields.dart
import 'package:flutter/material.dart';
import 'package:xfin/l10n/app_localizations.dart';
import 'package:xfin/utils/format.dart';
import 'package:xfin/utils/date_picker_locale.dart';
import 'package:xfin/utils/validators.dart';

mixin DateFieldsMixin {
  AppLocalizations get l10n;
  Validator get validator;
  BuildContext get formContext;

  Widget dateAndAssetRow({...}) { ... }
  Widget dateTimeField({...}) { ... }
}
```

```dart
// lib/widgets/form_fields/form_fields.dart
import 'date_fields.dart';
import 'dropdown_fields.dart';
import 'text_fields.dart';
import 'layout_fields.dart';

export 'date_fields.dart';
export 'dropdown_fields.dart';
export 'text_fields.dart';
export 'layout_fields.dart';

class FormFields with DateFieldsMixin, DropdownFieldsMixin, TextFieldsMixin, LayoutFieldsMixin {
  @override
  final AppLocalizations l10n;
  @override
  final Validator validator;
  @override
  final BuildContext formContext;

  FormFields(this.l10n, this.validator, this.formContext);
}
```

**Note:** The current private fields `_l10n`, `_validator`, `_context` become public getters via the mixin pattern. Consumer code uses `formFields.methodName()` which doesn't access these fields directly, so this is safe. The `FormBaseMixin` creates `FormFields(l10n, validator, context)` -- parameter order is preserved.

### Extracted public widget pattern (for CalendarScreen)
```dart
// lib/utils/snappy_scroll_physics.dart
import 'package:flutter/material.dart';

class SnappyPageScrollPhysics extends PageScrollPhysics {
  const SnappyPageScrollPhysics({super.parent});
  // ... same implementation, just public
}
```

### Top-level utility function pattern (for analysis_dao)
```dart
// lib/utils/timeframe_helper.dart

/// Returns (startOfMonth, endOfMonth) as yyyyMMdd integers.
(int, int) getMonthStartEnd(DateTime date) { ... }

/// Returns the intersection of [date]'s month with [filterStart]..[filterEnd],
/// or null if they don't overlap.
(int, int)? getMonthTimeframeIntersection(
  DateTime date, {
  required int filterStart,
  required int filterEnd,
}) { ... }

/// Converts a yyyyMMdd date-int to a yyyyMMddHHmmss datetime-int (start of day).
int monthStartDateTimeInt(int startDate) => startDate * 1000000;

/// Converts a yyyyMMdd date-int to a yyyyMMddHHmmss datetime-int (end of day).
int monthEndDateTimeInt(int endDate) => endDate * 1000000 + 235959;
```

## Common Pitfalls

### Pitfall 1: Breaking the barrel file re-export chain
**What goes wrong:** Consumers import `form_fields/form_fields.dart` but the barrel file doesn't re-export the mixin files, causing unresolved symbols.
**How to avoid:** The barrel file must both `import` the mixin files (for the class definition) AND `export` them (so consumers can access types if needed). Test by running `flutter analyze` immediately after creating the barrel file.

### Pitfall 2: Forgetting to update test imports
**What goes wrong:** Source code compiles but tests fail with "file not found" errors.
**How to avoid:** Search test/ directory for all imports of the changed files. Update systematically.

### Pitfall 3: Private class prefix removal breaking widget keys
**What goes wrong:** Widget keys in tests that use `find.byType(_MonthGrid)` will break when the class becomes `MonthGrid`.
**How to avoid:** Check test files for `find.byType` calls referencing renamed classes. Calendar screen tests likely use `find.byType(CalendarScreen)` which doesn't change.

### Pitfall 4: Mixin method conflicts
**What goes wrong:** Two mixins define methods with the same name, causing Dart compilation errors.
**How to avoid:** The current FormFields has no duplicate method names. Verify during implementation that no mixin introduces naming conflicts.

### Pitfall 5: Context-dependent field in mixin
**What goes wrong:** The `_context` field (renamed to `formContext` in the mixin getter) is used for `showDatePicker` and `showTimePicker`. If the context is stale (widget unmounted), these will throw.
**How to avoid:** This is an existing issue, not introduced by the refactor. Keep the same behavior -- the mixin getter returns the context passed at construction time.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Barrel file pattern | Manual re-exports | Standard `export` directives | Dart has built-in barrel file support |
| Class splitting | Custom delegation pattern | Mixins with abstract getters | Standard Dart pattern, zero runtime cost |
| File organization | Flat file with comments | Directory + barrel file | IDE navigation, git blame, review clarity |

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | flutter_test (built-in) |
| Config file | None (Flutter default) |
| Quick run command | `flutter test` |
| Full suite command | `flutter test` |

### Phase Requirements -> Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| R4.1 | form_fields split preserves all widget behavior | unit (existing) | `flutter test test/widgets/forms/form_fields_test.dart` | Yes (973 lines) |
| R4.2 | calendar_screen extraction preserves screen behavior | widget (existing) | `flutter test test/screens/calendar_screen_test.dart` | Yes (257 lines) |
| R4.3 | analysis_dao extraction preserves query behavior | unit (existing) | `flutter test test/database/daos/analysis_dao_test.dart` | Yes (847 lines) |
| R4.1-3 | All imports compile after restructuring | static analysis | `flutter analyze` | N/A |
| R4.3 | Extracted timeframe helpers work correctly | unit (new) | `flutter test test/utils/timeframe_helper_test.dart` | No -- Wave 0 |

### Sampling Rate
- **Per task commit:** `flutter test` (full suite, ~512+ tests)
- **Per wave merge:** `flutter test && flutter analyze`
- **Phase gate:** Full suite green + zero analyze issues before verify

### Wave 0 Gaps
- [ ] `test/utils/timeframe_helper_test.dart` -- covers extracted pure functions from analysis_dao
- [ ] Optional: `test/utils/snappy_scroll_physics_test.dart` -- covers extracted scroll physics (low priority, behavior tested implicitly through calendar_screen_test)

## Sources

### Primary (HIGH confidence)
- Direct file reading of all 3 target files (form_fields.dart, calendar_screen.dart, analysis_dao.dart)
- Direct file reading of all consumer files via grep search
- Direct file reading of all 3 existing test files
- Direct file reading of `form_base_mixin.dart`, `global_constants.dart`, `format.dart`
- Line counts verified via `wc -l`

### Secondary (MEDIUM confidence)
- Dart mixin pattern for class splitting -- standard Dart language feature, well-documented
- Barrel file (`export`) pattern -- standard Dart convention

## Metadata

**Confidence breakdown:**
- File analysis: HIGH -- all files read completely, all imports traced
- Split strategy: HIGH -- based on actual code structure analysis
- Import dependency map: HIGH -- grep-verified across entire codebase
- Test impact: HIGH -- all test files identified and examined
- Risk areas: MEDIUM -- edge cases around mixin pattern and private-to-public transitions assessed from code but not tested

**Research date:** 2026-03-08
**Valid until:** 2026-04-08 (stable -- no external dependencies involved)
