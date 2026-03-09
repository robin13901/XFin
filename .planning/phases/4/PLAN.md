# Phase 4 Plan — Test Coverage: Widget Tests

## Overview
3 plans covering the 5 remaining untested widget files. Ordered by complexity: simple stateless widgets first, then moderate-complexity widgets, then the complex chart widget.

**Scope Adjustment**: R1.1 (form_fields), R1.2 (filter_panel), R1.3 (filter_rule_editor), R1.4 (filter_value_inputs) were already completed in Phases 3 and 7. This phase covers R1.5-R1.9 only.

---

## Plan 04-01: Simple Widgets (inflow_outflow_toggle, dialogs)

**Goal**: Test the two simplest widget files — 82 + 104 lines, minimal dependencies.

### Tasks

#### Task 1: Create test/widgets/inflow_outflow_toggle_test.dart

InflowOutflowToggle is a pure StatelessWidget with no Provider dependencies — only needs MaterialApp + Theme.

```dart
group('InflowOutflowToggle', () {
  // Rendering
  testWidgets('renders both inflow and outflow labels', (tester) async { ... });
  testWidgets('shows inflow segment selected when showInflows is true', (tester) async {
    // Verify: inflow segment has indigoAccent background, outflow has transparent
  });
  testWidgets('shows outflow segment selected when showInflows is false', (tester) async { ... });

  // Interaction
  testWidgets('tapping inflow segment calls onChanged(true)', (tester) async { ... });
  testWidgets('tapping outflow segment calls onChanged(false)', (tester) async { ... });

  // Theming
  testWidgets('uses dark theme colors when brightness is dark', (tester) async {
    // Verify border is white, unselected fill is Color(0xFF151515)
  });
  testWidgets('uses light theme colors when brightness is light', (tester) async {
    // Verify border is black, unselected fill is white
  });
});
```

**Pump helper**: Simple MaterialApp wrapping — no Provider/DB needed.

```dart
Widget buildToggle({bool showInflows = true, ValueChanged<bool>? onChanged}) {
  return MaterialApp(
    home: Scaffold(
      body: InflowOutflowToggle(
        showInflows: showInflows,
        inflowLabel: 'Inflow',
        outflowLabel: 'Outflow',
        onChanged: onChanged ?? (_) {},
      ),
    ),
  );
}
```

**Estimated tests**: 7

#### Task 2: Create test/widgets/dialogs_test.dart

Three dialog functions: `showDeleteDialog`, `showErrorDialog`, `showInfoDialog`. All require l10n + Navigator context.

```dart
group('showInfoDialog', () {
  testWidgets('renders title, content, and OK button', (tester) async { ... });
  testWidgets('dismisses on OK tap', (tester) async { ... });
});

group('showErrorDialog', () {
  testWidgets('shows error title from l10n and provided content', (tester) async { ... });
  testWidgets('dismisses on OK tap', (tester) async { ... });
});

group('showDeleteDialog', () {
  // Each entity type shows different title/content
  testWidgets('shows account delete confirmation', (tester) async { ... });
  testWidgets('shows asset delete confirmation', (tester) async { ... });
  testWidgets('shows booking delete confirmation', (tester) async { ... });
  testWidgets('shows periodicBooking delete confirmation', (tester) async { ... });
  testWidgets('shows trade delete confirmation', (tester) async { ... });
  testWidgets('shows transfer delete confirmation', (tester) async { ... });
  testWidgets('shows periodicTransfer delete confirmation', (tester) async { ... });
  testWidgets('returns early when no entity provided', (tester) async { ... });

  // Confirm/cancel behavior
  testWidgets('confirming delete calls DAO delete method', (tester) async {
    // Insert account in test DB, call showDeleteDialog(account: ...), confirm, verify deleted
  });
  testWidgets('cancelling delete does not call DAO delete', (tester) async { ... });
});
```

**Pump helper**: Needs l10n + DatabaseProvider + BaseCurrencyProvider — use `FormTestHelpers.pumpFormInPlace` pattern.

**Estimated tests**: 14

### Success Criteria
- inflow_outflow_toggle.dart: 100% coverage (both segments, both themes, both taps)
- dialogs.dart: 100% coverage (all 3 functions, all 7 entity branches, confirm + cancel)

---

## Plan 04-02: Moderate Widgets (charts, reusables)

**Goal**: Test charts.dart (104 lines, 3 classes) and reusables.dart (309 lines, 3 active methods).

### Tasks

#### Task 1: Create test/widgets/charts_test.dart

Depends on: `fl_chart`, `format.dart`, `global_constants.dart` (chartColors).

```dart
group('AllocationItem', () {
  test('creates with required fields', () { ... });
  test('creates with optional type and asset', () { ... });
});

group('AllocationPieChart', () {
  testWidgets('renders PieChart widget', (tester) async { ... });
  testWidgets('renders with empty items list', (tester) async {
    // Should not crash — but items list empty means no sections
  });
  testWidgets('shows percentage title for large slices (>= 8%)', (tester) async { ... });
  testWidgets('hides percentage title for small slices (< 8%)', (tester) async { ... });
  testWidgets('handles zero total gracefully (all values 0)', (tester) async { ... });
});

group('AllocationBreakdownSection', () {
  testWidgets('renders title text', (tester) async { ... });
  testWidgets('renders pie chart and list tiles for each item', (tester) async { ... });
  testWidgets('displays formatted currency and percentage', (tester) async { ... });
  testWidgets('calls onItemTap when list tile tapped', (tester) async { ... });
  testWidgets('list tile not tappable when onItemTap is null', (tester) async { ... });
  testWidgets('handles zero total with 0% display', (tester) async { ... });
  testWidgets('cycles through chartColors for items exceeding color count', (tester) async {
    // 11+ items should wrap around to chartColors[0]
  });
});
```

**Pump helper**: MaterialApp only — no Provider/DB needed. Note: `formatCurrency` uses `BaseCurrencyProvider.symbol` statically, so call `BaseCurrencyProvider.symbol = '€'` in `setUp()` or assert formatted output with pattern matching rather than exact values.

**Estimated tests**: 14

#### Task 2: Create test/widgets/reusables_test.dart

Active methods in Reusables:
1. `buildLiquidGlassFAB` (static) — uses LiquidGlass widgets
2. `buildAssetsDropdown` (instance) — needs l10n + BaseCurrencyProvider
3. `buildEnumDropdown` (instance) — needs l10n + BaseCurrencyProvider

Note: ~160 lines of commented-out code should be ignored (dead code from Phase 1).

```dart
group('Reusables.buildLiquidGlassFAB', () {
  testWidgets('renders FAB with add icon', (tester) async { ... });
  testWidgets('calls onTap when pressed', (tester) async { ... });
  testWidgets('is positioned at bottom-right', (tester) async {
    // Verify Positioned(right: 23, bottom: 100)
  });
});

group('Reusables constructor', () {
  testWidgets('initializes validator and currencyProvider from context', (tester) async { ... });
});

group('Reusables.buildAssetsDropdown', () {
  testWidgets('renders dropdown with asset label', (tester) async { ... });
  testWidgets('shows asset names in dropdown items', (tester) async { ... });
  testWidgets('shows ticker symbol for selected item', (tester) async { ... });
  testWidgets('calls onChanged when item selected', (tester) async { ... });
  testWidgets('shows validation error from validator', (tester) async { ... });
  testWidgets('handles null initial assetId', (tester) async { ... });
});

group('Reusables.buildEnumDropdown', () {
  testWidgets('renders dropdown with custom label', (tester) async { ... });
  testWidgets('shows display function output for each item', (tester) async { ... });
  testWidgets('calls onChanged on selection', (tester) async { ... });
  testWidgets('shows validation error from validator', (tester) async { ... });
  testWidgets('handles null initialValue', (tester) async { ... });
});
```

**Pump helper**: Needs l10n + BaseCurrencyProvider for instance methods. Use `FormTestHelpers.pumpFormInPlace` for tests needing Reusables instance. `buildLiquidGlassFAB` is static and needs only MaterialApp.

**Estimated tests**: 16

### Success Criteria
- charts.dart: 100% coverage (AllocationItem, AllocationPieChart, AllocationBreakdownSection)
- reusables.dart: 100% coverage of active (non-commented) code

---

## Plan 04-03: Complex Widget (analysis_line_chart_section)

**Goal**: Test analysis_line_chart_section.dart (461 lines) — the most complex widget with indicators, touch handling, and range selection.

### Dependencies
- `fl_chart` (FlSpot, LineChart, LineTouchData)
- `intl` (DateFormat for axis labels)
- `ThemeProvider.isDark()` (static singleton — need to handle in tests)
- `IndicatorCalculator` (calculateSma, calculateEma, calculateBb)
- `AppColors` (green, red)
- `format.dart` (formatPercent)

### Test Data Helper

```dart
/// Generate N days of FlSpot data starting from a date.
List<FlSpot> generateTestData(int days, {double startValue = 100.0, double dailyDelta = 1.0}) {
  final start = DateTime(2024, 1, 1);
  return List.generate(days, (i) {
    final date = start.add(Duration(days: i));
    return FlSpot(
      date.millisecondsSinceEpoch.toDouble(),
      startValue + i * dailyDelta,
    );
  });
}
```

### Tasks

#### Task 1: Test header display (value, profit, date)

```dart
group('Header display', () {
  testWidgets('shows formatted total value', (tester) async { ... });
  testWidgets('shows profit with green arrow_upward when positive', (tester) async { ... });
  testWidgets('shows loss with red arrow_downward when negative', (tester) async { ... });
  testWidgets('shows range text for each time range', (tester) async {
    // 1W -> 'Seit 7 Tagen', 1M -> 'Seit 1 Monat', 1J -> 'Seit 1 Jahr', MAX -> 'Insgesamt'
  });
  testWidgets('shows valueLabel and topRight widget when provided', (tester) async { ... });
  testWidgets('shows centered value when topRight is null', (tester) async { ... });
});
```

**Estimated tests**: 6

#### Task 2: Test range selection buttons

```dart
group('Range selection', () {
  testWidgets('renders all 4 range buttons (1W, 1M, 1J, MAX)', (tester) async { ... });
  testWidgets('selected range has secondary background color', (tester) async { ... });
  testWidgets('tapping range button calls onRangeSelected', (tester) async { ... });
  testWidgets('1W shows last 7 data points', (tester) async {
    // Provide 30 days of data, select 1W, verify chart uses 7 points
  });
  testWidgets('MAX shows all data points', (tester) async { ... });
});
```

**Estimated tests**: 5

#### Task 3: Test indicator toggles

```dart
group('Indicator toggles', () {
  testWidgets('renders SMA, EMA, BB toggle buttons', (tester) async { ... });
  testWidgets('renders SMA200 toggle when showSma200Toggle is true', (tester) async { ... });
  testWidgets('hides SMA200 toggle when showSma200Toggle is false', (tester) async { ... });
  testWidgets('tapping SMA toggle calls onShowSmaChanged with toggled value', (tester) async { ... });
  testWidgets('tapping EMA toggle calls onShowEmaChanged', (tester) async { ... });
  testWidgets('tapping BB toggle calls onShowBbChanged', (tester) async { ... });
  testWidgets('tapping SMA200 toggle calls onShowSma200Changed', (tester) async { ... });
  testWidgets('selected toggle has colored background with opacity', (tester) async { ... });
  testWidgets('unselected toggle has transparent background', (tester) async { ... });
});
```

**Estimated tests**: 9

#### Task 4: Test chart rendering and edge cases

```dart
group('Chart rendering', () {
  testWidgets('renders LineChart widget', (tester) async { ... });
  testWidgets('shows additional SMA line when showSma is true', (tester) async { ... });
  testWidgets('shows additional EMA line when showEma is true', (tester) async { ... });
  testWidgets('shows BB bands when showBb is true', (tester) async { ... });
  testWidgets('handles data with fewer than 7 points for 1W range', (tester) async { ... });
  testWidgets('handles data with fewer than 30 points for 1M range', (tester) async { ... });
  testWidgets('handles single data point without error', (tester) async {
    // Exercises _getBottomTitleInterval spots.length <= 1 guard
  });
});
```

**Estimated tests**: 7

#### Task 5: Test getRangeText (via header display)

`getRangeText` is public and testable directly. `_getBottomTitleInterval` is private — covered indirectly by Task 4's range/data-size tests.

```dart
group('getRangeText', () {
  // getRangeText is tested via widget rendering in Task 1's range text tests.
  // Additional direct unit test for all 5 branches:
  testWidgets('displays correct range text for 1W', (tester) async { ... });
  testWidgets('displays correct range text for 1M', (tester) async { ... });
  testWidgets('displays correct range text for 1J', (tester) async { ... });
  testWidgets('displays correct range text for MAX (Insgesamt)', (tester) async { ... });
});
```

**Estimated tests**: 4

#### Task 6: Test touched spot behavior

```dart
group('Touch interaction', () {
  testWidgets('shows formatted date (dd.MM.yyyy) when touchedSpot is provided', (tester) async { ... });
  testWidgets('shows touched spot value instead of last value', (tester) async { ... });
  testWidgets('calculates day-over-day profit for touched spot (spotIndex > 0)', (tester) async { ... });
  testWidgets('calculates profit vs startValue when first spot touched on MAX range', (tester) async {
    // Exercises spotIndex == 0, currentData.length == allData.length branch
  });
  testWidgets('shows zero profit when first spot touched on filtered range', (tester) async {
    // Exercises spotIndex == 0, currentData.length < allData.length branch
  });
});
```

**Estimated tests**: 5

#### Task 7: Test profit calculation paths (no touch)

```dart
group('Profit calculation', () {
  testWidgets('MAX range: profit = last value - startValue', (tester) async { ... });
  testWidgets('filtered range (1W): profit = last value - first value of range', (tester) async { ... });
  testWidgets('hides valueLabel text when topRight is provided but valueLabel is empty', (tester) async { ... });
});
```

**Estimated tests**: 3

### Pump Helper

```dart
Widget buildChart({
  required List<FlSpot> data,
  double startValue = 100.0,
  String selectedRange = 'MAX',
  bool showSma = false,
  bool showEma = false,
  bool showBb = false,
  bool showSma200 = false,
  bool showSma200Toggle = true,
  LineBarSpot? touchedSpot,
  ValueChanged<String>? onRangeSelected,
  ValueChanged<bool>? onShowSmaChanged,
  // ... other callbacks
}) {
  return MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: AnalysisLineChartSection(
          allData: data,
          startValue: startValue,
          selectedRange: selectedRange,
          onRangeSelected: onRangeSelected ?? (_) {},
          showSma: showSma,
          showEma: showEma,
          showBb: showBb,
          showSma200: showSma200,
          onShowSmaChanged: onShowSmaChanged ?? (_) {},
          onShowEmaChanged: (_) {},
          onShowBbChanged: (_) {},
          onShowSma200Changed: (_) {},
          touchedSpot: touchedSpot,
          onTouchedSpotChanged: (_) {},
          onPointerDown: () {},
          onPointerUpOrCancel: () {},
          valueFormatter: (v) => v.toStringAsFixed(2),
        ),
      ),
    ),
  );
}
```

**Note on ThemeProvider**: `ThemeProvider.isDark()` uses a static singleton. In tests, the default `ThemeMode.system` with test `platformDispatcher` should resolve to light mode. No special mocking needed.

### Success Criteria
- analysis_line_chart_section.dart: All render paths tested (header variants, range selection, indicator toggles, chart data slicing, edge cases, profit calculations, touch interactions)
- getRangeText: All 5 cases covered (4 ranges + unknown)
- Touch interaction: All profit calculation branches verified (day-over-day, vs startValue, zero profit)
- Profit calculation: Both MAX (vs startValue) and filtered (vs first data point) paths tested

---

## Execution Order
1. **Plan 04-01** (simple widgets) — no dependencies, fast to implement
2. **Plan 04-02** (moderate widgets) — charts need fl_chart in test, reusables need Provider setup
3. **Plan 04-03** (complex chart) — most complex, benefits from patterns established in 01/02

## Ralph Loop
Each plan: implement tests -> `flutter test` -> fix failures -> repeat -> `flutter analyze` -> fix issues -> done.

## Total Estimated Tests
- Plan 01: ~21 tests (7 toggle + 14 dialogs)
- Plan 02: ~30 tests (14 charts + 16 reusables)
- Plan 03: ~37 tests (6 header + 5 range + 9 toggles + 7 chart + 4 getRangeText + 5 touch + 3 profit)
- **Total: ~88 new tests**
