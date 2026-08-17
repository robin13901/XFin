## Flutter Testing Workflow

**IMPORTANT: Always follow this testing workflow when working on Flutter code:**

1. **Write Tests First**
   - Ensure every new or modified code is comprehensively tested in the corresponding test file
   - Add new tests when necessary to cover all code paths
   - **Follow modern Dart best practices** for test writing
   - **Aim for 100% statement coverage** on all new/modified code
   - **Use test helper/utility files** for common test utilities and setup functions. If they are not yet created in the test directory, create them.

2. **Run `flutter test`**
   - Execute all tests after completing implementation
   - If tests fail: debug and fix iteratively until all tests of the entire project pass
   - All tests must pass before considering the task complete

3. **Run `flutter analyze`**
   - Execute after all tests pass
   - Fix all errors and warnings iteratively
   - Code must have zero issues before completion

This workflow is mandatory for all Flutter development tasks in this project.
