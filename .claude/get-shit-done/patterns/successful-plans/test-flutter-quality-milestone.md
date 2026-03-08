---
name: flutter-quality-milestone
domain: test
tech: [flutter, dart, drift]
success_rate: 100%
times_used: 1
source_project: XFin
captured_at: 2026-03-08
---

## Context
Use this pattern when planning a code-quality-only milestone for a Flutter app — no new features, focused entirely on internal improvements (dead code, test coverage, refactoring, consistency).

## Pattern

### Phase Ordering (Dependency-First)
1. **Cleanup first**: Dead code removal, naming fixes, declaration corrections
   - Establishes a clean baseline for subsequent work
   - Low risk, high confidence — builds momentum
2. **Structural refactoring**: Extract mixins, split large files
   - Depends on clean baseline from phase 1
   - Can parallelize independent extractions (mixin + file splits)
3. **Test coverage**: Add tests for newly refactored modules
   - Must follow refactoring (test the final structure, not the pre-refactor one)
4. **Error handling**: Add validation and error paths
   - Can run in parallel with test coverage if independent

### Key Decisions
- **Mixin over base class** for shared screen behavior (search/filter): preserves screen independence, easier to compose
- **6 focused phases** rather than 2-3 large ones: easier to verify, commit atomically, and roll back
- **Requirement traceability**: Every phase maps to specific R-numbers from REQUIREMENTS.md

### Common Pitfalls
- Don't rename widely-used public APIs in a cleanup phase — the churn isn't worth it
- Tests that create fresh databases mid-test need careful datetime formatting (XFin trades use YYYYMMDDHHMMSS format, not epoch seconds)
- Drift's `dontWarnAboutMultipleDatabases` warning in tests is cosmetic when tests intentionally create fresh dbs

### Success Criteria Template
For quality milestones, always include:
- [ ] All pre-existing tests still pass (regression gate)
- [ ] Zero flutter analyze issues maintained
- [ ] New test files achieve 100% statement coverage
- [ ] No non-generated file exceeds target line limit
