# State — Milestone 1.1.0: Code Quality & Architecture

## Current Phase
Phase 4: Test Coverage — Widget Tests — **DONE**

## Completed Phases
### Phase 4: Test Coverage — Widget Tests — **DONE**
- **Plan 01**: Created `inflow_outflow_toggle_test.dart` (21 tests) and `dialogs_test.dart` (24 tests):
  - InflowOutflowToggle: rendering, selected/unselected states, tap callbacks, dark/light theme colors, border/padding/animation
  - Dialogs: showInfoDialog, showErrorDialog, showDeleteDialog for all 7 entity types, confirm/cancel with real DB, early return on no entity
- **Plan 02**: Created `charts_test.dart` (24 tests) and `reusables_test.dart` (20 tests):
  - AllocationItem: construction with required/optional fields, zero/negative values
  - AllocationPieChart: rendering, empty items, percentage title threshold (8%), zero total, chartColors
  - AllocationBreakdownSection: title, ListTiles, currency/percentage formatting, onItemTap, color cycling
  - Reusables: buildLiquidGlassFAB positioning/icon/tap, constructor initialization, buildAssetsDropdown, buildEnumDropdown
- **Plan 03**: Created `analysis_line_chart_section_test.dart` (39 tests):
  - Header display: formatted value, profit/loss arrows with colors, range text for all ranges, valueLabel + topRight
  - Range selection: 4 buttons, selected styling, callbacks, data slicing (1W=7 points, MAX=all)
  - Indicator toggles: SMA/EMA/BB/SMA200 render/hide/callbacks, selected/unselected decoration
  - Chart rendering: LineChart present, indicator lines with correct colors, edge cases (<7, <30 points, single point)
  - getRangeText: all 4 German labels
  - Touch interaction: date formatting, touched value, day-over-day profit, profit vs startValue, zero profit
  - Profit calculation: MAX vs startValue, filtered range vs first data point, empty valueLabel hidden
- All 922 tests pass, zero flutter analyze issues

### Phase 7: Filter Model & Widget Tests — **DONE**
- **Plan 01**: Expanded `filter_rule_test.dart` (+14 tests) and created `filter_config_test.dart` (7 tests):
  - FilterRule: copyWith, equality/inequality for fieldId/operator/lists, _valueEquals branches, hashCode, identity
  - FilterConfig: DropdownOption, getField hit/miss, getFieldsByType match/empty
- **Plan 02**: Created 5 entity-specific filter config builder tests (30 tests total):
  - `booking_filter_config_test.dart` — 7 tests (fields, types, dropdown loading for assetId/accountId)
  - `transfer_filter_config_test.dart` — 8 tests (fields, types, dropdown loading for assetId/sendingAccountId/receivingAccountId)
  - `account_filter_config_test.dart` — 7 tests (fields, types, AccountTypes enum dropdown)
  - `trade_filter_config_test.dart` — 9 tests (10 fields, TradeTypes dropdown, assetId/sourceAccountId/targetAccountId)
  - `asset_filter_config_test.dart` — 7 tests (fields, types, AssetTypes enum dropdown)
  - Shared helper: `filter_config_test_helper.dart` for non-widget l10n access
- **Plan 03**: Created `filter_panel_test.dart` (19 tests), `filter_rule_editor_test.dart` (16 tests), expanded 3 existing files (+19 tests):
  - FilterPanel: header, edit/view mode, add/delete/clear rules, formatValue branches (null, empty list, list truncation, date, date range, unknown field)
  - FilterRuleEditor: 3-step flow (field→operator→value), auto-select single operator, save/cancel, pre-fill, field change resets, all input type dispatching
  - filter_value_inputs: NumericRangeInput, DropdownFilterInput (loading/rendering/selection), DateFilterInput, DateRangeInput, getOperatorDisplayName
  - filter_badge: boundary values (9, 10, 999)
  - liquid_glass_search_bar: empty state, custom focusNode
- All 794 tests pass, zero flutter analyze issues

### Phase 3: Refactor Large Files — **DONE**
- **Plan 01**: Split `form_fields.dart` (602 lines) into 4 mixin modules under `lib/widgets/form_fields/`:
  - `date_fields.dart` (150 lines) — DateFieldsMixin
  - `dropdown_fields.dart` (227 lines) — DropdownFieldsMixin
  - `text_fields.dart` (224 lines) — TextFieldsMixin
  - `layout_fields.dart` (60 lines) — LayoutFieldsMixin
  - `form_fields.dart` (25 lines) — Barrel/FormFields class composing all mixins
  - Updated 9 consumer import paths
- **Plan 02**: Extracted `calendar_screen.dart` (922 lines → 410 lines) into focused modules:
  - `lib/utils/snappy_scroll_physics.dart` (30 lines) — Reusable public scroll physics
  - `lib/screens/calendar/calendar_data.dart` (13 lines) — CalendarScreenData
  - `lib/screens/calendar/month_summary.dart` (186 lines) — MonthHeader, MonthSummarySection, CategoryListWrapper
  - `lib/screens/calendar/month_grid.dart` (183 lines) — MonthGrid
  - `lib/screens/calendar/day_details.dart` (124 lines) — DayDetailsPager, DayDetailsPage, SimpleDetailRow
- **Plan 03**: Extracted timeframe helpers and data classes from `analysis_dao.dart`:
  - `lib/utils/timeframe_helper.dart` — 4 pure functions (getMonthStartEnd, getMonthTimeframeIntersection, monthStartDateTimeInt, monthEndDateTimeInt)
  - `lib/database/models/analysis_models.dart` — MonthlyAnalysisSnapshot, CalendarDayDetails
  - `test/utils/timeframe_helper_test.dart` — 20 new tests
  - getMonthTimeframeIntersection now takes filterStart/filterEnd as parameters (pure function)
- All 686 tests pass, zero flutter analyze issues

### Phase 2: Extract Search/Filter Mixin — **DONE**
- Created SearchFilterMixin extracting common search/filter pattern
- Refactored 5 screens to use mixin, eliminating ~350 lines of duplicated code

### Phase 1: Dead Code Cleanup & DAO Consistency — **DONE**
- Removed commented-out CSV import code from trades_dao.dart (70+ lines)
- Removed unused `_onDbChanged()` method and `// ignore: unused_element` from bookings_screen.dart
- Fixed missing return type on `getAssetByTickerSymbol()` in assets_dao.dart
- Corrected @DriftAccessor table declarations across 5 DAOs:
  - analysis_dao: removed 4 unused tables (Accounts, PeriodicTransfers, Goals, AssetsOnAccounts)
  - trades_dao: removed 4 unused tables (Accounts, AssetsOnAccounts, Bookings, Transfers)
  - transfers_dao: removed 1 unused table (AssetsOnAccounts)
  - assets_on_accounts_dao: removed 3 unused tables (Accounts, Assets, Trades)
  - periodic_bookings_dao: added 1 missing table (Assets)
- Regenerated all Drift .g.dart files
- Task 2 (naming) skipped: `insert()` on accounts_dao/assets_dao is widely used externally
- All 189 database tests pass, flutter analyze clean

## Key Decisions
- Milestone scope: 6 phases focused on internal quality (no new features)
- Phase ordering: Cleanup first, then parallel refactoring + testing
- Search/filter extraction: Mixin approach chosen over base class (preserves screen independence)
- accounts_dao.insert() and assets_dao.insert() kept public (used by 15+ test files and 2 production files)

## Discovered Issues
### From Code Analysis (2026-03-08)
- 14 lib/ files with zero test coverage
- 5 screens with duplicated search/filter code (~30 lines each)
- `calendar_screen.dart` at 922 lines (largest non-generated file)
- `form_fields.dart` at 602 lines with no tests
- Only 2 throw statements across all DAOs

### Pre-existing (not from Phase 1)
- (none — account_detail_screen_test.dart failing test was fixed by adding trade data with correct datetime format)

## Blockers
(none)
