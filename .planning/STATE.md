# State — Milestone 1.1.0: Code Quality & Architecture

## Current Phase
Phase 2: Extract Search/Filter Mixin — **NOT PLANNED** (next to plan)

## Completed Phases
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
