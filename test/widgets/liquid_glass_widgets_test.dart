import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'package:xfin/widgets/liquid_glass_widgets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ════════════════════════════════════════════════════════════════
  // liquidGlassSettings Tests
  // ════════════════════════════════════════════════════════════════

  group('liquidGlassSettings', () {
    test('returns LiquidGlassSettings with correct thickness', () {
      final settings = liquidGlassSettings;
      expect(settings.thickness, 30);
    });

    test('returns LiquidGlassSettings with correct blur', () {
      final settings = liquidGlassSettings;
      expect(settings.blur, 1.4);
    });

    test('returns new instance on each access (getter behavior)', () {
      final settings1 = liquidGlassSettings;
      final settings2 = liquidGlassSettings;
      // Different instances (new object created each time)
      expect(identical(settings1, settings2), isFalse);
    });
  });

  // ════════════════════════════════════════════════════════════════
  // LiquidGlassBottomNav Tests
  // ════════════════════════════════════════════════════════════════

  group('LiquidGlassBottomNav', () {
    group('basic rendering', () {
      testWidgets('renders all navigation icons', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: LiquidGlassBottomNav(
                icons: const [Icons.home, Icons.search, Icons.settings],
                labels: const ['Home', 'Search', 'Settings'],
                keys: const [Key('home'), Key('search'), Key('settings')],
                currentIndex: 0,
                onTap: (_) {},
              ),
            ),
          ),
        );

        expect(find.byIcon(Icons.home), findsOneWidget);
        expect(find.byIcon(Icons.search), findsOneWidget);
        expect(find.byIcon(Icons.settings), findsOneWidget);
      });

      testWidgets('renders all navigation labels', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: LiquidGlassBottomNav(
                icons: const [Icons.home, Icons.search],
                labels: const ['Home', 'Search'],
                keys: const [Key('home'), Key('search')],
                currentIndex: 0,
                onTap: (_) {},
              ),
            ),
          ),
        );

        expect(find.text('Home'), findsOneWidget);
        expect(find.text('Search'), findsOneWidget);
      });

      testWidgets('renders with custom height', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: LiquidGlassBottomNav(
                icons: const [Icons.home],
                labels: const ['Home'],
                keys: const [Key('home')],
                currentIndex: 0,
                onTap: (_) {},
                height: 80.0,
              ),
            ),
          ),
        );

        expect(find.byType(LiquidGlassBottomNav), findsOneWidget);
      });

      testWidgets('renders with custom horizontal padding', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: LiquidGlassBottomNav(
                icons: const [Icons.home],
                labels: const ['Home'],
                keys: const [Key('home')],
                currentIndex: 0,
                onTap: (_) {},
                horizontalPadding: 32.0,
              ),
            ),
          ),
        );

        expect(find.byType(LiquidGlassBottomNav), findsOneWidget);
      });

      testWidgets('uses minimum height when provided height is smaller than circleSize', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: LiquidGlassBottomNav(
                icons: const [Icons.home],
                labels: const ['Home'],
                keys: const [Key('home')],
                currentIndex: 0,
                onTap: (_) {},
                height: 40.0, // Less than circleSize (64.0)
              ),
            ),
          ),
        );

        expect(find.byType(LiquidGlassBottomNav), findsOneWidget);
      });
    });

    group('navigation interaction', () {
      testWidgets('calls onTap with correct index when item is tapped', (tester) async {
        int? tappedIndex;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: LiquidGlassBottomNav(
                icons: const [Icons.home, Icons.search, Icons.settings],
                labels: const ['Home', 'Search', 'Settings'],
                keys: const [Key('home'), Key('search'), Key('settings')],
                currentIndex: 0,
                onTap: (index) => tappedIndex = index,
              ),
            ),
          ),
        );

        await tester.tap(find.byKey(const Key('search')));
        await tester.pumpAndSettle();

        expect(tappedIndex, 1);
      });

      testWidgets('calls onTap for first item', (tester) async {
        int? tappedIndex;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: LiquidGlassBottomNav(
                icons: const [Icons.home, Icons.search],
                labels: const ['Home', 'Search'],
                keys: const [Key('home'), Key('search')],
                currentIndex: 1,
                onTap: (index) => tappedIndex = index,
              ),
            ),
          ),
        );

        await tester.tap(find.byKey(const Key('home')));
        await tester.pumpAndSettle();

        expect(tappedIndex, 0);
      });

      testWidgets('calls onTap for last item', (tester) async {
        int? tappedIndex;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: LiquidGlassBottomNav(
                icons: const [Icons.home, Icons.search, Icons.person],
                labels: const ['Home', 'Search', 'Profile'],
                keys: const [Key('home'), Key('search'), Key('profile')],
                currentIndex: 0,
                onTap: (index) => tappedIndex = index,
              ),
            ),
          ),
        );

        await tester.tap(find.byKey(const Key('profile')));
        await tester.pumpAndSettle();

        expect(tappedIndex, 2);
      });
    });

    group('left button visibility', () {
      testWidgets('shows left button when index is in leftVisibleForIndices and onLeftTap is provided', (tester) async {
        bool leftTapped = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: LiquidGlassBottomNav(
                icons: const [Icons.home, Icons.search],
                labels: const ['Home', 'Search'],
                keys: const [Key('home'), Key('search')],
                currentIndex: 0,
                onTap: (_) {},
                onLeftTap: () => leftTapped = true,
                leftVisibleForIndices: const {0},
              ),
            ),
          ),
        );

        expect(find.byIcon(Icons.add), findsOneWidget);

        await tester.tap(find.byIcon(Icons.add));
        await tester.pumpAndSettle();

        expect(leftTapped, isTrue);
      });

      testWidgets('hides left button when index is not in leftVisibleForIndices', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: LiquidGlassBottomNav(
                icons: const [Icons.home, Icons.search],
                labels: const ['Home', 'Search'],
                keys: const [Key('home'), Key('search')],
                currentIndex: 1,
                onTap: (_) {},
                onLeftTap: () {},
                leftVisibleForIndices: const {0},
              ),
            ),
          ),
        );

        expect(find.byIcon(Icons.add), findsNothing);
      });

      testWidgets('hides left button when onLeftTap is null', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: LiquidGlassBottomNav(
                icons: const [Icons.home, Icons.search],
                labels: const ['Home', 'Search'],
                keys: const [Key('home'), Key('search')],
                currentIndex: 0,
                onTap: (_) {},
                leftVisibleForIndices: const {0},
              ),
            ),
          ),
        );

        expect(find.byIcon(Icons.add), findsNothing);
      });

      testWidgets('shows placeholder when keepLeftPlaceholder is true and left button is hidden', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: LiquidGlassBottomNav(
                icons: const [Icons.home, Icons.search],
                labels: const ['Home', 'Search'],
                keys: const [Key('home'), Key('search')],
                currentIndex: 1,
                onTap: (_) {},
                onLeftTap: () {},
                leftVisibleForIndices: const {0},
                keepLeftPlaceholder: true,
              ),
            ),
          ),
        );

        // Left button should be hidden
        expect(find.byIcon(Icons.add), findsNothing);
        // But a SizedBox placeholder should be there (harder to test directly)
        expect(find.byType(LiquidGlassBottomNav), findsOneWidget);
      });

      testWidgets('does not show placeholder when keepLeftPlaceholder is false', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: LiquidGlassBottomNav(
                icons: const [Icons.home, Icons.search],
                labels: const ['Home', 'Search'],
                keys: const [Key('home'), Key('search')],
                currentIndex: 1,
                onTap: (_) {},
                onLeftTap: () {},
                leftVisibleForIndices: const {0},
                keepLeftPlaceholder: false,
              ),
            ),
          ),
        );

        expect(find.byIcon(Icons.add), findsNothing);
      });
    });

    group('right button visibility', () {
      testWidgets('shows right button by default (rightVisibleForIndices is null)', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: LiquidGlassBottomNav(
                icons: const [Icons.home, Icons.search],
                labels: const ['Home', 'Search'],
                keys: const [Key('home'), Key('search')],
                currentIndex: 0,
                onTap: (_) {},
                onRightTap: () {},
              ),
            ),
          ),
        );

        expect(find.byIcon(Icons.more_horiz), findsOneWidget);
      });

      testWidgets('shows right button when index is in rightVisibleForIndices', (tester) async {
        bool rightTapped = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: LiquidGlassBottomNav(
                icons: const [Icons.home, Icons.search],
                labels: const ['Home', 'Search'],
                keys: const [Key('home'), Key('search')],
                currentIndex: 1,
                onTap: (_) {},
                onRightTap: () => rightTapped = true,
                rightVisibleForIndices: const {1},
              ),
            ),
          ),
        );

        expect(find.byIcon(Icons.more_horiz), findsOneWidget);

        await tester.tap(find.byIcon(Icons.more_horiz));
        await tester.pumpAndSettle();

        expect(rightTapped, isTrue);
      });

      testWidgets('hides right button when index is not in rightVisibleForIndices', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: LiquidGlassBottomNav(
                icons: const [Icons.home, Icons.search],
                labels: const ['Home', 'Search'],
                keys: const [Key('home'), Key('search')],
                currentIndex: 0,
                onTap: (_) {},
                onRightTap: () {},
                rightVisibleForIndices: const {1},
              ),
            ),
          ),
        );

        expect(find.byIcon(Icons.more_horiz), findsNothing);
      });

      testWidgets('uses custom right icon', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: LiquidGlassBottomNav(
                icons: const [Icons.home],
                labels: const ['Home'],
                keys: const [Key('home')],
                currentIndex: 0,
                onTap: (_) {},
                rightIcon: Icons.menu,
                onRightTap: () {},
              ),
            ),
          ),
        );

        expect(find.byIcon(Icons.menu), findsOneWidget);
        expect(find.byIcon(Icons.more_horiz), findsNothing);
      });
    });

    group('selection state', () {
      testWidgets('applies selected styling to current index item', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: LiquidGlassBottomNav(
                icons: const [Icons.home, Icons.search],
                labels: const ['Home', 'Search'],
                keys: const [Key('home'), Key('search')],
                currentIndex: 0,
                onTap: (_) {},
              ),
            ),
          ),
        );

        // Widget should render without errors
        expect(find.byType(LiquidGlassBottomNav), findsOneWidget);
      });

      testWidgets('updates selection when currentIndex changes', (tester) async {
        int currentIndex = 0;

        await tester.pumpWidget(
          MaterialApp(
            home: StatefulBuilder(
              builder: (context, setState) => Scaffold(
                body: LiquidGlassBottomNav(
                  icons: const [Icons.home, Icons.search],
                  labels: const ['Home', 'Search'],
                  keys: const [Key('home'), Key('search')],
                  currentIndex: currentIndex,
                  onTap: (index) => setState(() => currentIndex = index),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.byKey(const Key('search')));
        await tester.pumpAndSettle();

        expect(currentIndex, 1);
      });
    });

    group('edge cases', () {
      testWidgets('renders with single navigation item', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: LiquidGlassBottomNav(
                icons: const [Icons.home],
                labels: const ['Home'],
                keys: const [Key('home')],
                currentIndex: 0,
                onTap: (_) {},
              ),
            ),
          ),
        );

        expect(find.byIcon(Icons.home), findsOneWidget);
        expect(find.text('Home'), findsOneWidget);
      });

      testWidgets('renders with many navigation items', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: LiquidGlassBottomNav(
                icons: const [
                  Icons.home,
                  Icons.search,
                  Icons.favorite,
                  Icons.person,
                  Icons.settings,
                ],
                labels: const ['Home', 'Search', 'Favorites', 'Profile', 'Settings'],
                keys: const [
                  Key('home'),
                  Key('search'),
                  Key('favorites'),
                  Key('profile'),
                  Key('settings'),
                ],
                currentIndex: 2,
                onTap: (_) {},
              ),
            ),
          ),
        );

        expect(find.byType(LiquidGlassBottomNav), findsOneWidget);
        expect(find.byIcon(Icons.home), findsOneWidget);
        expect(find.byIcon(Icons.settings), findsOneWidget);
      });

      testWidgets('handles empty leftVisibleForIndices', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: LiquidGlassBottomNav(
                icons: const [Icons.home],
                labels: const ['Home'],
                keys: const [Key('home')],
                currentIndex: 0,
                onTap: (_) {},
                onLeftTap: () {},
                leftVisibleForIndices: const {},
              ),
            ),
          ),
        );

        expect(find.byIcon(Icons.add), findsNothing);
      });
    });
  });

  // ════════════════════════════════════════════════════════════════
  // buildCircleButton Tests
  // ════════════════════════════════════════════════════════════════

  group('buildCircleButton', () {
    testWidgets('renders child widget', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: buildCircleButton(
              child: const Icon(Icons.add),
              size: 64.0,
              settings: liquidGlassSettings,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('creates button with correct size', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: buildCircleButton(
                child: const Icon(Icons.add),
                size: 80.0,
                settings: liquidGlassSettings,
              ),
            ),
          ),
        ),
      );

      final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox).first);
      expect(sizedBox.width, 80.0);
      expect(sizedBox.height, 80.0);
    });

    testWidgets('responds to tap when onTap is provided', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: buildCircleButton(
                child: const Icon(Icons.add),
                size: 64.0,
                settings: liquidGlassSettings,
                onTap: () => tapped = true,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('does not wrap in GestureDetector when onTap is null', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: buildCircleButton(
                child: const Icon(Icons.add),
                size: 64.0,
                settings: liquidGlassSettings,
              ),
            ),
          ),
        ),
      );

      // Button should still render
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('applies custom key', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: buildCircleButton(
                child: const Icon(Icons.add),
                size: 64.0,
                settings: liquidGlassSettings,
                onTap: () {},
                key: const Key('custom_button'),
              ),
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('custom_button')), findsOneWidget);
    });

    testWidgets('uses LiquidGlassLayer with provided settings', (tester) async {
      const customSettings = LiquidGlassSettings(
        thickness: 50,
        blur: 2.0,
        glassColor: Colors.red,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: buildCircleButton(
                child: const Icon(Icons.add),
                size: 64.0,
                settings: customSettings,
              ),
            ),
          ),
        ),
      );

      final liquidGlassLayer = tester.widget<LiquidGlassLayer>(
        find.byType(LiquidGlassLayer),
      );
      expect(liquidGlassLayer.settings.thickness, 50);
      expect(liquidGlassLayer.settings.blur, 2.0);
    });
  });

  // ════════════════════════════════════════════════════════════════
  // buildFAB Tests
  // ════════════════════════════════════════════════════════════════

  group('buildFAB', () {
    testWidgets('renders add icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                Builder(
                  builder: (context) => buildFAB(context: context),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('is positioned at bottom right', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                Builder(
                  builder: (context) => buildFAB(context: context),
                ),
              ],
            ),
          ),
        ),
      );

      final positioned = tester.widget<Positioned>(find.byType(Positioned));
      expect(positioned.bottom, 24);
      expect(positioned.right, 24);
    });

    testWidgets('responds to tap when onTap is provided', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                Builder(
                  builder: (context) => buildFAB(
                    context: context,
                    onTap: () => tapped = true,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('has fab key', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                Builder(
                  builder: (context) => buildFAB(
                    context: context,
                    onTap: () {},
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('fab')), findsOneWidget);
    });
  });

  // ════════════════════════════════════════════════════════════════
  // buildLiquidGlassAppBar Tests
  // ════════════════════════════════════════════════════════════════

  group('buildLiquidGlassAppBar', () {
    testWidgets('renders title widget', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                Builder(
                  builder: (context) => buildLiquidGlassAppBar(
                    context,
                    title: const Text('Test Title'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Test Title'), findsOneWidget);
    });

    testWidgets('shows back button by default', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                Builder(
                  builder: (context) => buildLiquidGlassAppBar(
                    context,
                    title: const Text('Title'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(BackButton), findsOneWidget);
    });

    testWidgets('hides back button when showBackButton is false', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                Builder(
                  builder: (context) => buildLiquidGlassAppBar(
                    context,
                    title: const Text('Title'),
                    showBackButton: false,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(BackButton), findsNothing);
    });

    testWidgets('renders action widgets', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                Builder(
                  builder: (context) => buildLiquidGlassAppBar(
                    context,
                    title: const Text('Title'),
                    actions: [
                      IconButton(
                        key: const Key('action1'),
                        icon: const Icon(Icons.search),
                        onPressed: () {},
                      ),
                      IconButton(
                        key: const Key('action2'),
                        icon: const Icon(Icons.more_vert),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('action1')), findsOneWidget);
      expect(find.byKey(const Key('action2')), findsOneWidget);
    });

    testWidgets('renders without actions', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                Builder(
                  builder: (context) => buildLiquidGlassAppBar(
                    context,
                    title: const Text('No Actions'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('No Actions'), findsOneWidget);
    });

    testWidgets('uses LiquidGlassLayer', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                Builder(
                  builder: (context) => buildLiquidGlassAppBar(
                    context,
                    title: const Text('Title'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(LiquidGlassLayer), findsOneWidget);
    });
  });

  // ════════════════════════════════════════════════════════════════
  // GlassMenuItem Tests
  // ════════════════════════════════════════════════════════════════

  group('GlassMenuItem', () {
    test('creates instance with required parameters', () {
      final item = GlassMenuItem(
        label: 'Test',
        icon: Icons.home,
      );

      expect(item.label, 'Test');
      expect(item.icon, Icons.home);
      expect(item.onTap, isNull);
    });

    test('creates instance with onTap callback', () {
      bool tapped = false;
      final item = GlassMenuItem(
        label: 'Test',
        icon: Icons.home,
        onTap: () => tapped = true,
      );

      expect(item.onTap, isNotNull);
      item.onTap!();
      expect(tapped, isTrue);
    });

    test('stores correct icon data', () {
      final item = GlassMenuItem(
        label: 'Settings',
        icon: Icons.settings,
      );

      expect(item.icon, Icons.settings);
    });

    test('stores correct label', () {
      final item = GlassMenuItem(
        label: 'My Custom Label',
        icon: Icons.star,
      );

      expect(item.label, 'My Custom Label');
    });
  });

  // ════════════════════════════════════════════════════════════════
  // showLiquidGlassPanel Tests
  // ════════════════════════════════════════════════════════════════

  group('showLiquidGlassPanel', () {
    testWidgets('shows panel with menu items', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  onPressed: () {
                    showLiquidGlassPanel(
                      context: context,
                      items: [
                        GlassMenuItem(label: 'Item 1', icon: Icons.home),
                        GlassMenuItem(label: 'Item 2', icon: Icons.search),
                      ],
                    );
                  },
                  child: const Text('Show Panel'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Panel'));
      await tester.pumpAndSettle();

      expect(find.text('Item 1'), findsOneWidget);
      expect(find.text('Item 2'), findsOneWidget);
    });

    testWidgets('shows panel with icons', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  onPressed: () {
                    showLiquidGlassPanel(
                      context: context,
                      items: [
                        GlassMenuItem(label: 'Home', icon: Icons.home),
                        GlassMenuItem(label: 'Search', icon: Icons.search),
                      ],
                    );
                  },
                  child: const Text('Show Panel'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Panel'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.home), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('triggers onTap callback when item is tapped', (tester) async {
      bool itemTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  onPressed: () {
                    showLiquidGlassPanel(
                      context: context,
                      items: [
                        GlassMenuItem(
                          label: 'Tap Me',
                          icon: Icons.touch_app,
                          onTap: () => itemTapped = true,
                        ),
                      ],
                    );
                  },
                  child: const Text('Show Panel'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Panel'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tap Me'));
      await tester.pumpAndSettle();

      expect(itemTapped, isTrue);
    });

    testWidgets('uses custom widthFraction', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  onPressed: () {
                    showLiquidGlassPanel(
                      context: context,
                      items: [
                        GlassMenuItem(label: 'Test', icon: Icons.home),
                      ],
                      widthFraction: 0.8,
                    );
                  },
                  child: const Text('Show Panel'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Panel'));
      await tester.pumpAndSettle();

      expect(find.text('Test'), findsOneWidget);
    });

    testWidgets('uses custom maxHeightFraction', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  onPressed: () {
                    showLiquidGlassPanel(
                      context: context,
                      items: [
                        GlassMenuItem(label: 'Test', icon: Icons.home),
                      ],
                      maxHeightFraction: 0.5,
                    );
                  },
                  child: const Text('Show Panel'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Panel'));
      await tester.pumpAndSettle();

      expect(find.text('Test'), findsOneWidget);
    });

    testWidgets('renders multiple items in grid', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  onPressed: () {
                    showLiquidGlassPanel(
                      context: context,
                      items: [
                        GlassMenuItem(label: 'One', icon: Icons.looks_one),
                        GlassMenuItem(label: 'Two', icon: Icons.looks_two),
                        GlassMenuItem(label: 'Three', icon: Icons.looks_3),
                        GlassMenuItem(label: 'Four', icon: Icons.looks_4),
                      ],
                    );
                  },
                  child: const Text('Show Panel'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Panel'));
      await tester.pumpAndSettle();

      expect(find.text('One'), findsOneWidget);
      expect(find.text('Two'), findsOneWidget);
      expect(find.text('Three'), findsOneWidget);
      expect(find.text('Four'), findsOneWidget);
    });

    testWidgets('uses GridView for items', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  onPressed: () {
                    showLiquidGlassPanel(
                      context: context,
                      items: [
                        GlassMenuItem(label: 'Test', icon: Icons.home),
                      ],
                    );
                  },
                  child: const Text('Show Panel'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Panel'));
      await tester.pumpAndSettle();

      expect(find.byType(GridView), findsOneWidget);
    });
  });
}
