# Phase 1 Plan: Dead Code Cleanup & DAO Consistency

## Goal
Establish a clean foundation by removing dead code, standardizing DAO naming conventions, and correcting table declarations — before larger refactors in subsequent phases.

## Requirements Covered
- R5.1: Standardize public/private method naming across all DAOs
- R5.2: Review and correct `@DriftAccessor(tables: [...])` declarations
- R5.3: Remove commented-out dead code in `trades_dao.dart`
- R5.4: Remove or resolve `// ignore: unused_element` in `bookings_screen.dart`

## Pre-conditions
- All 512+ tests currently pass
- Zero flutter analyze issues

---

## Task 1: Remove Dead Code

### 1a: Remove commented-out CSV import code in trades_dao.dart
**File**: `lib/database/daos/trades_dao.dart`
**Action**: Delete lines 293-363 (commented-out `insertFromCsv()` method and CSV test data)
**Verification**: File compiles, tests pass

### 1b: Remove unused `_onDbChanged()` method in bookings_screen.dart
**File**: `lib/screens/bookings_screen.dart`
**Action**: Delete lines 75-81 (the `// ignore: unused_element` directive and the `_onDbChanged()` method)
**Verification**: File compiles, no analyzer warnings

### 1c: Run tests after dead code removal
**Command**: `flutter test`
**Expected**: All tests pass (no behavioral changes)

---

## Task 2: Standardize DAO Method Naming

### Convention to Apply
Based on analysis, the **majority pattern** across DAOs is:
- **Private** `_insert()`, `_update()`, `_delete()` for raw CRUD operations
- **Public** business-logic methods like `createBooking()`, `updateBooking()`, `deleteBooking()` that wrap CRUD in transactions with side effects

DAOs already following this pattern: `bookings_dao`, `trades_dao`, `transfers_dao`, `assets_on_accounts_dao`

### 2a: accounts_dao.dart — Make raw CRUD consistently private
**Current state**:
- `insert()` is public (should be `_insert()` since `createAccount()` is the public API)
- `_updateAccount()` is private (correct)
- `_deleteAccount()` is private (correct)
- `deleteAccount()` is the public business-logic wrapper (correct)

**Action**:
- Rename `insert()` → `_insert()` on the raw insert method
- Update `createAccount()` to call `_insert()` instead of `insert()`
- Update `accounts_dao_test.dart` line 34: change `accountsDao.insert(...)` to use `accountsDao.createAccount(...)` instead
- No external callers in lib/screens/ (screens use `createAccount()` only)

### 2b: assets_dao.dart — Make raw CRUD consistently private
**Current state**:
- `insert()` is public
- `deleteAsset()` directly deletes (no separate private method)
- `updateAsset()` directly updates

**Action**:
- Review if `insert()` is called externally (from forms/screens). If only called from within DAO or from test setup, make private.
- Keep `deleteAsset()` and `updateAsset()` as-is since they ARE the business-logic methods (no separate raw CRUD).
- Decision: assets_dao uses a simpler pattern since operations don't need transaction wrapping with side effects. Document this as acceptable variant.

### 2c: periodic_bookings_dao.dart — Consistent naming
**Current state**: Uses `insertPeriodicBooking()`, `updatePeriodicBooking()`, `deletePeriodicBooking()` (all public, direct operations)

**Action**: This pattern is acceptable — these are simple CRUD without transaction side effects. No changes needed. Already consistent.

### 2d: periodic_transfers_dao.dart — Same as periodic_bookings
**Action**: No changes needed. Already consistent.

### 2e: goals_dao.dart — Empty DAO
**Current state**: No methods at all.
**Action**: Leave as-is for Phase 1. This is a future feature gap, not a naming issue.

### 2f: Run tests after naming changes
**Command**: `flutter test`
**Expected**: All tests pass

---

## Task 3: Correct @DriftAccessor Table Declarations

### Research Summary — Mismatches Found

| DAO | Unused Declarations | Missing Declarations |
|-----|---------------------|----------------------|
| accounts_dao | PeriodicBookings, PeriodicTransfers, Goals | — |
| analysis_dao | Accounts, PeriodicTransfers, Goals, AssetsOnAccounts | — |
| assets_dao | — | Bookings, Transfers |
| assets_on_accounts_dao | Accounts, Assets | — |
| trades_dao | Accounts, AssetsOnAccounts, Bookings, Transfers | — |
| transfers_dao | AssetsOnAccounts | — |
| goals_dao | Goals, Accounts (empty DAO) | — |

### Important Note on Drift Table Declarations
Drift uses `@DriftAccessor(tables: [...])` to generate mixin code that provides typed table accessors. Tables listed here give the DAO direct access to query those tables. **However**, DAOs can also access tables through `db.otherDao` or `db.select(db.someTable)` bypassing the declared tables.

**Strategy**: Only remove declarations for tables that are genuinely not accessed in ANY way within the DAO. Be conservative — if in doubt, keep the declaration.

### 3a: accounts_dao.dart
**Current**: `[Accounts, Bookings, Transfers, Trades, PeriodicBookings, PeriodicTransfers, Goals, AssetsOnAccounts]`
**Action**: Remove `PeriodicBookings`, `PeriodicTransfers`, `Goals` — these tables are only accessed via cross-DAO calls (`db.periodicBookingsDao`, etc.), not directly in accounts_dao queries
**New**: `[Accounts, Bookings, Transfers, Trades, AssetsOnAccounts]`

### 3b: analysis_dao.dart
**Current**: `[Accounts, Bookings, Transfers, Trades, PeriodicBookings, PeriodicTransfers, Goals, AssetsOnAccounts]`
**Action**: Verify which tables are accessed with generated accessors (e.g., `bookings`, `trades`) vs through `db.select(db.table)`. Remove only truly unused.
**Investigation needed**: Read the actual queries to confirm. If analysis_dao uses `select(bookings)` directly, `Bookings` must stay. If it uses `db.select(db.bookings)`, it can be removed.
**Conservative approach**: Keep PeriodicBookings (confirmed used), remove Accounts, PeriodicTransfers, Goals, AssetsOnAccounts if truly not referenced.
**New**: `[Bookings, Transfers, Trades, PeriodicBookings]`

### 3c: assets_dao.dart
**Current**: `[Assets, Trades, AssetsOnAccounts]`
**Action**: Add `Bookings`, `Transfers` — these are accessed directly in queries (confirmed at lines 21-22)
**New**: `[Assets, Trades, AssetsOnAccounts, Bookings, Transfers]`

### 3d: assets_on_accounts_dao.dart
**Current**: `[AssetsOnAccounts, Accounts, Assets, Trades, Bookings, Transfers]`
**Action**: Verify if Accounts and Assets are accessed via generated accessors. If only via `db.accountsDao`, they can be removed. But they may be needed for JOIN queries.
**Conservative approach**: Keep as-is unless confirmed unused in direct queries.

### 3e: trades_dao.dart
**Current**: `[Trades, Assets, Accounts, AssetsOnAccounts, Bookings, Transfers]`
**Action**: Verify usage. `applyDbEffects()` accesses other DAOs, not these tables directly. If only `Trades` and `Assets` are used in direct queries, remove the rest.
**New**: `[Trades, Assets]` (if confirmed)

### 3f: transfers_dao.dart
**Current**: `[Transfers, Accounts, Assets, AssetsOnAccounts]`
**Action**: Remove `AssetsOnAccounts` if not used in direct queries.
**New**: `[Transfers, Accounts, Assets]`

### 3g: goals_dao.dart
**Current**: `[Goals, Accounts]`
**Action**: Leave as-is — DAO is empty but declarations anticipate future implementation.

### 3h: periodic_bookings_dao.dart
**Current**: `[PeriodicBookings, Accounts]`
**Action**: Add `Assets` (confirmed used at line 43, 47)
**New**: `[PeriodicBookings, Accounts, Assets]`

### 3i: Regenerate Drift code and run verification
**CRITICAL**: After all table declaration changes, run `dart run build_runner build` to regenerate `.g.dart` files. The generated mixins (e.g., `_$AccountsDaoMixin`) contain typed getters for each declared table — they MUST match the declaration.
**Commands**:
```
dart run build_runner build --delete-conflicting-outputs
flutter test
flutter analyze
```
**Expected**: All `.g.dart` files regenerated, all tests pass, zero analyzer issues

---

## Task 4: Fix Additional Issues Found During Research

### 4a: Fix missing return type in assets_dao.dart
**File**: `lib/database/daos/assets_dao.dart` line 171
**Current**: `Future getAssetByTickerSymbol(String tickerSymbol)`
**Action**: Add return type `Future<Asset?>` (nullable since query may return no result)
**Note**: Only if flutter analyze flags this. If it doesn't flag it, skip (Dart infers types).

### 4b: Run final verification
**Commands**:
```
flutter test
flutter analyze
```
**Expected**: All tests pass, zero issues

---

## Execution Order
1. Task 1 (dead code removal) — lowest risk, quick wins
2. Task 4a (type annotation fix) — quick fix
3. Task 2 (naming standardization) — requires careful refactoring
4. Task 3 (table declarations) — requires build_runner if Drift regeneration needed
5. Final verification (flutter test + flutter analyze)

## Rollback Plan
Each task produces a git commit. If any task breaks tests, revert that commit and investigate.

## Success Criteria
- [ ] Zero commented-out code blocks in DAOs
- [ ] Zero `// ignore: unused_element` directives
- [ ] Consistent `_` prefix for raw CRUD methods in DAOs that also have public business-logic wrappers
- [ ] All `@DriftAccessor(tables: [...])` declarations match actual usage
- [ ] All 512+ tests pass
- [ ] Zero flutter analyze issues
