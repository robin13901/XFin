---
name: drift-dao-cleanup
domain: db
tech: [flutter, dart, drift, sqlite]
success_rate: 100%
times_used: 1
source_project: XFin
captured_at: 2026-03-08
---

## Context
Use this pattern when cleaning up Drift (SQLite ORM) DAO files in a Flutter project: removing dead code, standardizing naming, and correcting `@DriftAccessor(tables: [...])` declarations.

## Pattern

### Tasks
1. **Dead code removal** (lowest risk first)
   - Remove commented-out code blocks
   - Remove unused methods with `// ignore: unused_element`
   - Run tests immediately after

2. **Quick type fixes**
   - Add missing return types on DAO methods (Dart infers but explicit is better)
   - Run tests

3. **Naming standardization** (medium risk)
   - Audit public vs private (`_`) prefixes on CRUD methods
   - Convention: private `_insert()` for raw CRUD, public `createEntity()` for business logic wrappers
   - **Skip renaming if method is widely used externally** (15+ call sites = too much churn for a cleanup phase)

4. **@DriftAccessor table declarations** (highest risk, do last)
   - Audit each DAO: which declared tables are actually used in direct queries vs accessed via `db.otherDao`
   - Only declare tables used directly (via generated mixin accessors like `select(bookings)`)
   - Tables accessed through `db.select(db.table)` or `db.otherDao` don't need declaration
   - **CRITICAL**: Run `dart run build_runner build --delete-conflicting-outputs` after changes
   - Run full test suite after regeneration

### Key Decisions
- **Skip risky renames**: `accounts_dao.insert()` and `assets_dao.insert()` were kept public because they were used by 15+ test files and 2 production files. Renaming would create churn disproportionate to the cleanup benefit.
- **Conservative table declarations**: When unsure if a table is used directly, keep it declared. Removing a needed declaration breaks generated code.
- **Regenerate after every table declaration change**: Don't batch — verify incrementally.

### Common Pitfalls
- Drift `@DriftAccessor(tables: [...])` generates typed mixin code. Removing a table from the list removes the generated accessor — any code using `select(thatTable)` will break at compile time. Always check for direct table access before removing.
- Some DAOs use a simpler pattern (no transaction wrappers) where public CRUD methods are fine. Don't force the private+public wrapper pattern everywhere.
- Empty DAOs (e.g., goals_dao) anticipating future features should be left as-is.

### Wave Structure
```
Wave 1: Dead code removal (independent, safe)
Wave 2: Type fixes (independent, safe)
Wave 3: Naming standardization (requires judgment calls)
Wave 4: Table declaration corrections + build_runner (highest coupling)
Wave 5: Final verification (flutter test + flutter analyze)
```

### Metrics
- Phase 1 removed 70+ lines of dead code across 2 files
- Corrected table declarations across 5 DAOs (removed 12 unused, added 1 missing)
- All 189 database tests passed after changes
- Zero flutter analyze issues
