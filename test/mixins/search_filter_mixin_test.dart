import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xfin/mixins/search_filter_mixin.dart';
import 'package:xfin/models/filter/filter_rule.dart';

/// Test widget that uses SearchFilterMixin.
class _TestSearchFilterWidget extends StatefulWidget {
  final VoidCallback? onSearchFilterChanged;

  const _TestSearchFilterWidget({this.onSearchFilterChanged});

  @override
  State<_TestSearchFilterWidget> createState() =>
      _TestSearchFilterWidgetState();
}

class _TestSearchFilterWidgetState extends State<_TestSearchFilterWidget>
    with SearchFilterMixin<_TestSearchFilterWidget> {
  @override
  void onSearchFilterChanged() {
    widget.onSearchFilterChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SearchFilterMixin', () {
    testWidgets('default state initialization', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: _TestSearchFilterWidget()),
        ),
      );

      final state = tester.state<_TestSearchFilterWidgetState>(
          find.byType(_TestSearchFilterWidget));

      expect(state.showSearchBar, isFalse);
      expect(state.searchQuery, '');
      expect(state.filterRules, isEmpty);
      expect(state.showFilterPanel, isFalse);
      expect(state.activeFilterCount, 0);
      expect(state.searchBarSpace, 0.0);
    });

    testWidgets('toggleSearch() shows search bar', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: _TestSearchFilterWidget()),
        ),
      );

      final state = tester.state<_TestSearchFilterWidgetState>(
          find.byType(_TestSearchFilterWidget));

      state.toggleSearch();
      await tester.pump();

      expect(state.showSearchBar, isTrue);
      expect(state.searchBarSpace, 60.0);
    });

    testWidgets('toggleSearch() hides and clears', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: _TestSearchFilterWidget()),
        ),
      );

      final state = tester.state<_TestSearchFilterWidgetState>(
          find.byType(_TestSearchFilterWidget));

      // Open search bar and set query
      state.toggleSearch();
      await tester.pump();
      state.searchController.text = 'test';
      state.searchQuery = 'test';

      // Close search bar
      state.toggleSearch();
      await tester.pump();

      expect(state.showSearchBar, isFalse);
      expect(state.searchQuery, '');
      // Controller text is cleared by toggleSearch
      expect(state.searchController.text, '');
    });

    testWidgets(
        'toggleSearch() calls onSearchFilterChanged when clearing non-empty query',
        (tester) async {
      int callCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _TestSearchFilterWidget(
              onSearchFilterChanged: () => callCount++,
            ),
          ),
        ),
      );

      final state = tester.state<_TestSearchFilterWidgetState>(
          find.byType(_TestSearchFilterWidget));

      // Open search and set a query
      state.toggleSearch();
      await tester.pump();
      state.searchQuery = 'test';
      state.showSearchBar = true;

      // Close search => should call onSearchFilterChanged
      state.toggleSearch();
      await tester.pump();

      expect(callCount, 1);
    });

    testWidgets(
        'toggleSearch() does NOT call onSearchFilterChanged when query was empty',
        (tester) async {
      int callCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _TestSearchFilterWidget(
              onSearchFilterChanged: () => callCount++,
            ),
          ),
        ),
      );

      final state = tester.state<_TestSearchFilterWidgetState>(
          find.byType(_TestSearchFilterWidget));

      // Open then close with empty query
      state.toggleSearch();
      await tester.pump();
      state.toggleSearch();
      await tester.pump();

      expect(callCount, 0);
    });

    testWidgets('onSearchChanged() debounces at 300ms', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: _TestSearchFilterWidget()),
        ),
      );

      final state = tester.state<_TestSearchFilterWidgetState>(
          find.byType(_TestSearchFilterWidget));

      state.onSearchChanged('test');
      await tester.pump(const Duration(milliseconds: 100));

      // Should still be empty before 300ms
      expect(state.searchQuery, '');

      // Pump remaining 200ms
      await tester.pump(const Duration(milliseconds: 200));

      expect(state.searchQuery, 'test');
    });

    testWidgets('onSearchChanged() cancels previous debounce', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: _TestSearchFilterWidget()),
        ),
      );

      final state = tester.state<_TestSearchFilterWidgetState>(
          find.byType(_TestSearchFilterWidget));

      state.onSearchChanged('a');
      await tester.pump(const Duration(milliseconds: 100));
      state.onSearchChanged('b');
      await tester.pump(const Duration(milliseconds: 300));

      expect(state.searchQuery, 'b');
    });

    testWidgets('onSearchChanged() calls onSearchFilterChanged after debounce',
        (tester) async {
      int callCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _TestSearchFilterWidget(
              onSearchFilterChanged: () => callCount++,
            ),
          ),
        ),
      );

      final state = tester.state<_TestSearchFilterWidgetState>(
          find.byType(_TestSearchFilterWidget));

      state.onSearchChanged('test');
      await tester.pump(const Duration(milliseconds: 300));

      expect(callCount, 1);
    });

    testWidgets('onSearchChanged() skips if value unchanged', (tester) async {
      int callCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _TestSearchFilterWidget(
              onSearchFilterChanged: () => callCount++,
            ),
          ),
        ),
      );

      final state = tester.state<_TestSearchFilterWidgetState>(
          find.byType(_TestSearchFilterWidget));

      // Set query to 'same' first
      state.searchQuery = 'same';

      // Call onSearchChanged with same value
      state.onSearchChanged('same');
      await tester.pump(const Duration(milliseconds: 300));

      expect(callCount, 0);
    });

    testWidgets('onFilterRulesChanged() updates state', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: _TestSearchFilterWidget()),
        ),
      );

      final state = tester.state<_TestSearchFilterWidgetState>(
          find.byType(_TestSearchFilterWidget));

      const rule = FilterRule(
        fieldId: 'test',
        operator: FilterOperator.contains,
        value: 'abc',
      );

      state.onFilterRulesChanged([rule]);
      await tester.pump();

      expect(state.filterRules.length, 1);
      expect(state.activeFilterCount, 1);
    });

    testWidgets('onFilterRulesChanged() calls onSearchFilterChanged',
        (tester) async {
      int callCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _TestSearchFilterWidget(
              onSearchFilterChanged: () => callCount++,
            ),
          ),
        ),
      );

      final state = tester.state<_TestSearchFilterWidgetState>(
          find.byType(_TestSearchFilterWidget));

      const rule = FilterRule(
        fieldId: 'test',
        operator: FilterOperator.contains,
        value: 'abc',
      );

      state.onFilterRulesChanged([rule]);
      await tester.pump();

      expect(callCount, 1);
    });

    testWidgets('closeFilterPanel()', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: _TestSearchFilterWidget()),
        ),
      );

      final state = tester.state<_TestSearchFilterWidgetState>(
          find.byType(_TestSearchFilterWidget));

      state.showFilterPanel = true;
      state.closeFilterPanel();
      await tester.pump();

      expect(state.showFilterPanel, isFalse);
    });

    testWidgets('openFilterPanel()', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: _TestSearchFilterWidget()),
        ),
      );

      final state = tester.state<_TestSearchFilterWidgetState>(
          find.byType(_TestSearchFilterWidget));

      state.openFilterPanel();
      await tester.pump();

      expect(state.showFilterPanel, isTrue);
    });

    testWidgets('dispose cleans up resources', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: _TestSearchFilterWidget()),
        ),
      );

      // Dispose the widget
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: SizedBox()),
        ),
      );

      // No errors expected -- Timer cancelled, FocusNode disposed, etc.
    });

    testWidgets('mounted guard in debounce prevents setState after dispose',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: _TestSearchFilterWidget()),
        ),
      );

      final state = tester.state<_TestSearchFilterWidgetState>(
          find.byType(_TestSearchFilterWidget));

      // Start a debounce
      state.onSearchChanged('test');

      // Dispose the widget before 300ms
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: SizedBox()),
        ),
      );

      // Pump past the debounce timer -- should not throw "setState after dispose"
      await tester.pump(const Duration(milliseconds: 300));
    });

    testWidgets('toggleSearch() requests focus when opening', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: _TestSearchFilterWidget(),
          ),
        ),
      );

      final state = tester.state<_TestSearchFilterWidgetState>(
          find.byType(_TestSearchFilterWidget));

      state.toggleSearch();
      await tester.pump();

      expect(state.showSearchBar, isTrue);
      // The addPostFrameCallback was scheduled; verify it doesn't crash
      await tester.pump();
    });
  });
}
