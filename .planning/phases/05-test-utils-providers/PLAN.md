# Plan 05-01 — Unit/Widget Tests for Utilities & Providers

## Goal
Close remaining test coverage gaps for `spacing.dart`, `modal_helper.dart`, `snappy_scroll_physics.dart`, and `database_provider.dart`.

## Tasks

### Task 1: `test/constants/spacing_test.dart`
- Verify numeric constants: tiny=4, small=8, medium=16, large=24, huge=32
- Verify vertical SizedBox widgets have correct height
- Verify horizontal SizedBox widgets have correct width
- ~15 tests

### Task 2: `test/utils/modal_helper_test.dart`
- Verify `showFormModal` opens a ModalBottomSheet
- Verify `isScrollControlled: true` is passed
- Verify the formWidget is rendered inside the sheet
- Verify the Future returns the result when sheet is dismissed
- ~4-6 tests (widget tests)

### Task 3: `test/utils/snappy_scroll_physics_test.dart`
- Verify `applyTo` returns `SnappyPageScrollPhysics`
- Verify `minFlingDistance` == 1.0
- Verify `minFlingVelocity` == 15.0
- Verify `maxFlingVelocity` == 20000.0
- Verify `carriedMomentum` clamping and sign behavior
- Verify `spring` properties (mass, stiffness, ratio)
- ~8-10 tests

### Task 4: `test/providers/database_provider_test.dart`
- Verify singleton pattern (`instance` getter returns same object)
- Verify `initialize` sets db and calls `notifyListeners`
- Verify `replaceDatabase` closes old db, sets new, calls `notifyListeners`
- Verify `@visibleForTesting` instance setter works
- ~6-8 tests

## Success Criteria
- All 4 test files created with 100% statement coverage of source
- Full project test suite passes
- Zero flutter analyze issues
