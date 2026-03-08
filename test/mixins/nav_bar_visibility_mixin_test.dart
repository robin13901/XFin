import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xfin/mixins/nav_bar_visibility_mixin.dart';
import 'package:xfin/widgets/nav_bar_controller.dart';

/// Test widget that uses NavBarVisibilityMixin with NavBarController (inherited).
class _InheritedTestWidget extends StatefulWidget {
  const _InheritedTestWidget({super.key});

  @override
  State<_InheritedTestWidget> createState() => _InheritedTestWidgetState();
}

class _InheritedTestWidgetState extends State<_InheritedTestWidget>
    with NavBarVisibilityMixin<_InheritedTestWidget> {
  @override
  Widget build(BuildContext context) {
    updateKeyboardVisibility(context);
    return const SizedBox();
  }

  // Expose mixin methods for testing
  void testSetFilterPanelOpen(bool open) => setFilterPanelOpen(open);
  void testSetSearchFocused(bool focused) => setSearchFocused(focused);
  void testRestore() => restoreNavBarVisibility();
}

/// Test widget that uses NavBarVisibilityMixin with local ValueNotifier.
class _LocalTestWidget extends StatefulWidget {
  const _LocalTestWidget({super.key});

  @override
  State<_LocalTestWidget> createState() => _LocalTestWidgetState();
}

class _LocalTestWidgetState extends State<_LocalTestWidget>
    with NavBarVisibilityMixin<_LocalTestWidget> {
  final ValueNotifier<bool> navBarVisible = ValueNotifier<bool>(true);

  @override
  ValueNotifier<bool>? get localNavBarVisible => navBarVisible;

  @override
  Widget build(BuildContext context) {
    updateKeyboardVisibility(context);
    return const SizedBox();
  }

  void testSetFilterPanelOpen(bool open) => setFilterPanelOpen(open);
  void testSetSearchFocused(bool focused) => setSearchFocused(focused);

  @override
  void dispose() {
    navBarVisible.dispose();
    super.dispose();
  }
}

void main() {
  group('NavBarVisibilityMixin', () {
    group('with inherited NavBarController', () {
      testWidgets('hides nav bar when filter panel opens', (tester) async {
        final notifier = ValueNotifier<bool>(true);

        final key = GlobalKey<_InheritedTestWidgetState>();

        await tester.pumpWidget(
          MaterialApp(
            home: NavBarController(
              visible: notifier,
              child: _InheritedTestWidget(key: key),
            ),
          ),
        );

        expect(notifier.value, isTrue);

        key.currentState!.testSetFilterPanelOpen(true);
        await tester.pump();

        expect(notifier.value, isFalse);

        key.currentState!.testSetFilterPanelOpen(false);
        await tester.pump();

        expect(notifier.value, isTrue);

        notifier.dispose();
      });

      testWidgets('restoreNavBarVisibility sets to true', (tester) async {
        final notifier = ValueNotifier<bool>(true);

        final key = GlobalKey<_InheritedTestWidgetState>();

        await tester.pumpWidget(
          MaterialApp(
            home: NavBarController(
              visible: notifier,
              child: _InheritedTestWidget(key: key),
            ),
          ),
        );

        key.currentState!.testSetFilterPanelOpen(true);
        await tester.pump();
        expect(notifier.value, isFalse);

        key.currentState!.testRestore();
        await tester.pump();
        expect(notifier.value, isTrue);

        notifier.dispose();
      });
    });

    group('with local ValueNotifier', () {
      testWidgets('hides nav bar when filter panel opens', (tester) async {
        final key = GlobalKey<_LocalTestWidgetState>();

        await tester.pumpWidget(
          MaterialApp(
            home: _LocalTestWidget(key: key),
          ),
        );

        expect(key.currentState!.navBarVisible.value, isTrue);

        key.currentState!.testSetFilterPanelOpen(true);
        await tester.pump();

        expect(key.currentState!.navBarVisible.value, isFalse);

        key.currentState!.testSetFilterPanelOpen(false);
        await tester.pump();

        expect(key.currentState!.navBarVisible.value, isTrue);
      });

      testWidgets('search focus alone does not hide nav bar', (tester) async {
        final key = GlobalKey<_LocalTestWidgetState>();

        await tester.pumpWidget(
          MaterialApp(
            home: _LocalTestWidget(key: key),
          ),
        );

        // Search focused but no keyboard => should remain visible
        key.currentState!.testSetSearchFocused(true);
        await tester.pump();

        expect(key.currentState!.navBarVisible.value, isTrue);
      });

      testWidgets('filter panel takes precedence over search state',
          (tester) async {
        final key = GlobalKey<_LocalTestWidgetState>();

        await tester.pumpWidget(
          MaterialApp(
            home: _LocalTestWidget(key: key),
          ),
        );

        // Open filter panel
        key.currentState!.testSetFilterPanelOpen(true);
        await tester.pump();
        expect(key.currentState!.navBarVisible.value, isFalse);

        // Closing filter panel should restore, even with search focused
        key.currentState!.testSetSearchFocused(true);
        key.currentState!.testSetFilterPanelOpen(false);
        await tester.pump();

        // Still visible because keyboard is not showing (viewInsets.bottom == 0)
        expect(key.currentState!.navBarVisible.value, isTrue);
      });
    });
  });
}
