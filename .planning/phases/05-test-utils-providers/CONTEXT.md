# Phase 5 Context — Test Coverage: Utilities & Providers

## Phase Goal
Close remaining test coverage gaps for utility files and providers.

## Requirements
- **R2.1**: Add tests for `utils/modal_helper.dart`
- **R2.2**: Add tests for `constants/spacing.dart` (if non-trivial)

## Additional Coverage Gaps Found
- `providers/database_provider.dart` — untested (other 3 providers all have tests)
- `utils/snappy_scroll_physics.dart` — untested (extracted in Phase 3, no test created)

## Files to Test

### 1. `lib/utils/modal_helper.dart` (17 lines)
- Single function: `showFormModal<T>(BuildContext context, Widget formWidget)`
- Wraps `showModalBottomSheet` with `isScrollControlled: true`
- Used by `accounts_screen.dart` and `bookings_screen.dart`
- Tests: verify sheet opens, passes formWidget, returns result, isScrollControlled

### 2. `lib/constants/spacing.dart` (27 lines)
- Static constants class with private constructor
- 5 numeric constants: tiny(4), small(8), medium(16), large(24), huge(32)
- 5 vertical SizedBox widgets: vTiny, vSmall, vMedium, vLarge, vHuge
- 5 horizontal SizedBox widgets: hTiny, hSmall, hMedium, hLarge, hHuge
- Tests: verify values, verify SizedBox dimensions

### 3. `lib/providers/database_provider.dart` (27 lines)
- Singleton ChangeNotifier with `_instance` pattern
- `initialize(AppDatabase db)` — sets db, notifyListeners
- `replaceDatabase(AppDatabase newDb)` — closes old, sets new, notifyListeners
- `@visibleForTesting` setter for instance replacement
- Tests: singleton, initialize, replaceDatabase, notifyListeners

### 4. `lib/utils/snappy_scroll_physics.dart` (30 lines)
- Extends PageScrollPhysics
- Custom fling distances/velocities, carriedMomentum, spring
- Tests: verify physics properties, applyTo returns correct type

## Existing Test Patterns
- Test helpers in `test/widgets/test_helpers.dart` (FormTestHelpers)
- Provider tests use in-memory database + ChangeNotifier listener pattern
- Utility tests are pure unit tests
