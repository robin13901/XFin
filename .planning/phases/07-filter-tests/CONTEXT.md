# Phase 7 Context — Filter Model & Widget Tests

## Phase Goal
Add comprehensive tests for all filter model classes and filter widget files, achieving 100% statement coverage.

## Requirements Covered
- R1.2: filter_panel.dart tests
- R1.3: filter_rule_editor.dart tests
- R1.4: filter_value_inputs.dart tests (expand existing)

## Source Files to Test

### Models (lib/models/filter/) — 7 files
| File | Lines | Existing Tests | Status |
|------|-------|---------------|--------|
| filter_rule.dart | 127 | filter_rule_test.dart (15 tests) | Expand gaps |
| filter_config.dart | 40 | NONE | New |
| booking_filter_config.dart | 68 | NONE | New |
| transfer_filter_config.dart | 69 | NONE | New |
| account_filter_config.dart | 41 | NONE | New |
| trade_filter_config.dart | 98 | NONE | New |
| asset_filter_config.dart | 51 | NONE | New |

### Widgets (lib/widgets/filter/) — 5 files
| File | Lines | Existing Tests | Status |
|------|-------|---------------|--------|
| filter_badge.dart | 50 | filter_badge_test.dart (4 tests) | Expand gaps |
| filter_panel.dart | 277 | NONE | New |
| filter_rule_editor.dart | 218 | NONE | New |
| filter_value_inputs.dart | 362 | filter_value_inputs_test.dart (8 tests) | Expand gaps |
| liquid_glass_search_bar.dart | 80 | liquid_glass_search_bar_test.dart (7 tests) | Expand gaps |

## Key Dependencies
- test/widgets/test_helpers.dart — FormTestHelpers (db setup, widget pumping, date picking)
- AppDatabase (in-memory for config builder tests)
- AppLocalizations (l10n for all configs and operator display names)
- ThemeProvider (for search bar theme tests)

## Testing Patterns (from existing tests)
- Simple widgets: pump directly in MaterialApp > Scaffold > body
- DB-dependent tests: use FormTestHelpers.createTestDatabase(), insertBaseCurrency(), insertTestAccounts(), insertTestAssets()
- Localization: wrap in MaterialApp with AppLocalizations.delegate + supportedLocales
- State management: use StatefulBuilder for tracking callback values
