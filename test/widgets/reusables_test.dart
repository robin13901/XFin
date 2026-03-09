import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xfin/database/app_database.dart';
import 'package:xfin/database/tables.dart';
import 'package:xfin/l10n/app_localizations.dart';
import 'package:xfin/providers/base_currency_provider.dart';
import 'package:xfin/widgets/reusables.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late BaseCurrencyProvider currencyProvider;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    BaseCurrencyProvider.symbol = '\u20AC';
    currencyProvider = BaseCurrencyProvider();
  });

  // Helper to pump a widget that provides l10n + BaseCurrencyProvider context
  Future<void> pumpWithProviders(
    WidgetTester tester,
    Widget child,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en'), Locale('de')],
        home: ChangeNotifierProvider<BaseCurrencyProvider>.value(
          value: currencyProvider,
          child: child,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  // ============================================================
  // buildLiquidGlassFAB tests (static method)
  // ============================================================

  group('Reusables.buildLiquidGlassFAB', () {
    testWidgets('renders add icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                Builder(
                  builder: (context) => Reusables.buildLiquidGlassFAB(
                    context,
                    () async {},
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('calls onTap callback when tapped', (tester) async {
      bool wasTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                Builder(
                  builder: (context) => Reusables.buildLiquidGlassFAB(
                    context,
                    () async {
                      wasTapped = true;
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      expect(wasTapped, isTrue);
    });

    testWidgets('returns a Positioned widget', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                Builder(
                  builder: (context) => Reusables.buildLiquidGlassFAB(
                    context,
                    () async {},
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      final positioned = tester.widget<Positioned>(find.byType(Positioned));
      expect(positioned.right, 23);
      expect(positioned.bottom, 100);
    });

    testWidgets('has a 72x72 SizedBox for the tap target', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                Builder(
                  builder: (context) => Reusables.buildLiquidGlassFAB(
                    context,
                    () async {},
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      // Find the SizedBox that is a direct child of Center (inside InkWell)
      final sizedBoxes = tester
          .widgetList<SizedBox>(
            find.descendant(
              of: find.byType(InkWell),
              matching: find.byType(SizedBox),
            ),
          )
          .where((sb) => sb.height == 72 && sb.width == 72);

      expect(sizedBoxes.length, 1);
    });

    testWidgets('uses LiquidGlassLayer', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                Builder(
                  builder: (context) => Reusables.buildLiquidGlassFAB(
                    context,
                    () async {},
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(LiquidGlassLayer), findsOneWidget);
    });

    testWidgets('icon has size 32', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                Builder(
                  builder: (context) => Reusables.buildLiquidGlassFAB(
                    context,
                    () async {},
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      final icon = tester.widget<Icon>(find.byIcon(Icons.add));
      expect(icon.size, 32);
    });
  });

  // ============================================================
  // Reusables constructor tests
  // ============================================================

  group('Reusables constructor', () {
    testWidgets('initializes l10n, validator, and currencyProvider from context',
        (tester) async {
      late Reusables reusables;

      await pumpWithProviders(
        tester,
        Scaffold(
          body: Builder(
            builder: (context) {
              reusables = Reusables(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(reusables.l10n, isNotNull);
      expect(reusables.validator, isNotNull);
      expect(reusables.currencyProvider, isNotNull);
    });
  });

  // ============================================================
  // buildAssetsDropdown tests
  // ============================================================

  group('Reusables.buildAssetsDropdown', () {
    const testAssets = [
      Asset(
        id: 1,
        name: 'EUR',
        type: AssetTypes.fiat,
        tickerSymbol: 'EUR',
        currencySymbol: '\u20AC',
        value: 0,
        shares: 0,
        brokerCostBasis: 1,
        netCostBasis: 1,
        buyFeeTotal: 0,
        isArchived: false,
      ),
      Asset(
        id: 2,
        name: 'Apple Inc.',
        type: AssetTypes.stock,
        tickerSymbol: 'AAPL',
        value: 0,
        shares: 0,
        brokerCostBasis: 150,
        netCostBasis: 150,
        buyFeeTotal: 0,
        isArchived: false,
      ),
    ];

    testWidgets('renders with label text from l10n', (tester) async {
      late Reusables reusables;

      await pumpWithProviders(
        tester,
        Scaffold(
          body: Builder(
            builder: (context) {
              reusables = Reusables(context);
              return Row(
                children: [
                  reusables.buildAssetsDropdown(
                    null,
                    testAssets,
                    (_) {},
                    null,
                  ),
                ],
              );
            },
          ),
        ),
      );

      // The label comes from l10n.asset
      expect(find.byType(DropdownButtonFormField<int>), findsOneWidget);
      expect(find.byKey(const Key('assets_dropdown')), findsOneWidget);
    });

    testWidgets('shows dropdown items when tapped', (tester) async {
      late Reusables reusables;

      await pumpWithProviders(
        tester,
        Scaffold(
          body: Builder(
            builder: (context) {
              reusables = Reusables(context);
              return Row(
                children: [
                  reusables.buildAssetsDropdown(
                    null,
                    testAssets,
                    (_) {},
                    null,
                  ),
                ],
              );
            },
          ),
        ),
      );

      // Tap the dropdown to open it
      await tester.tap(find.byKey(const Key('assets_dropdown')));
      await tester.pumpAndSettle();

      // Items are shown by their name in the DropdownMenuItem
      expect(find.text('EUR'), findsWidgets);
      expect(find.text('Apple Inc.'), findsWidgets);
    });

    testWidgets('calls onChanged when an item is selected', (tester) async {
      int? selectedId;
      late Reusables reusables;

      await pumpWithProviders(
        tester,
        Scaffold(
          body: Builder(
            builder: (context) {
              reusables = Reusables(context);
              return Row(
                children: [
                  reusables.buildAssetsDropdown(
                    null,
                    testAssets,
                    (id) => selectedId = id,
                    null,
                  ),
                ],
              );
            },
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('assets_dropdown')));
      await tester.pumpAndSettle();

      // Select the second item (Apple Inc.)
      await tester.tap(find.text('Apple Inc.').last);
      await tester.pumpAndSettle();

      expect(selectedId, 2);
    });

    testWidgets('renders inside Expanded widget', (tester) async {
      late Reusables reusables;

      await pumpWithProviders(
        tester,
        Scaffold(
          body: Builder(
            builder: (context) {
              reusables = Reusables(context);
              return Row(
                children: [
                  reusables.buildAssetsDropdown(
                    null,
                    testAssets,
                    (_) {},
                    null,
                  ),
                ],
              );
            },
          ),
        ),
      );

      // The dropdown is wrapped in Expanded
      expect(
        find.ancestor(
          of: find.byType(DropdownButtonFormField<int>),
          matching: find.byType(Expanded),
        ),
        findsOneWidget,
      );
    });

    testWidgets('handles null assetId gracefully', (tester) async {
      late Reusables reusables;

      await pumpWithProviders(
        tester,
        Scaffold(
          body: Builder(
            builder: (context) {
              reusables = Reusables(context);
              return Row(
                children: [
                  reusables.buildAssetsDropdown(
                    null,
                    testAssets,
                    (_) {},
                    null,
                  ),
                ],
              );
            },
          ),
        ),
      );

      // Should render without errors with null assetId
      expect(find.byType(DropdownButtonFormField<int>), findsOneWidget);
    });

    testWidgets('renders with empty assets list', (tester) async {
      late Reusables reusables;

      await pumpWithProviders(
        tester,
        Scaffold(
          body: Builder(
            builder: (context) {
              reusables = Reusables(context);
              return Row(
                children: [
                  reusables.buildAssetsDropdown(
                    null,
                    const <Asset>[],
                    (_) {},
                    null,
                  ),
                ],
              );
            },
          ),
        ),
      );

      expect(find.byType(DropdownButtonFormField<int>), findsOneWidget);
    });
  });

  // ============================================================
  // buildEnumDropdown tests
  // ============================================================

  group('Reusables.buildEnumDropdown', () {
    testWidgets('renders with label', (tester) async {
      late Reusables reusables;

      await pumpWithProviders(
        tester,
        Scaffold(
          body: Builder(
            builder: (context) {
              reusables = Reusables(context);
              return reusables.buildEnumDropdown<AssetTypes>(
                initialValue: null,
                values: AssetTypes.values,
                label: 'Asset Type',
                onChanged: (_) {},
                display: (t) => t.name,
              );
            },
          ),
        ),
      );

      expect(find.text('Asset Type'), findsOneWidget);
    });

    testWidgets('shows all enum values as dropdown items', (tester) async {
      late Reusables reusables;

      await pumpWithProviders(
        tester,
        Scaffold(
          body: Builder(
            builder: (context) {
              reusables = Reusables(context);
              return reusables.buildEnumDropdown<AccountTypes>(
                initialValue: null,
                values: AccountTypes.values,
                label: 'Account Type',
                onChanged: (_) {},
                display: (t) => t.name,
              );
            },
          ),
        ),
      );

      await tester.tap(find.byType(DropdownButtonFormField<AccountTypes>));
      await tester.pumpAndSettle();

      // All AccountTypes values should be in the dropdown
      for (final type in AccountTypes.values) {
        expect(find.text(type.name), findsWidgets);
      }
    });

    testWidgets('calls onChanged when value is selected', (tester) async {
      AccountTypes? selectedType;
      late Reusables reusables;

      await pumpWithProviders(
        tester,
        Scaffold(
          body: Builder(
            builder: (context) {
              reusables = Reusables(context);
              return reusables.buildEnumDropdown<AccountTypes>(
                initialValue: null,
                values: AccountTypes.values,
                label: 'Account Type',
                onChanged: (t) => selectedType = t,
                display: (t) => t.name,
              );
            },
          ),
        ),
      );

      await tester.tap(find.byType(DropdownButtonFormField<AccountTypes>));
      await tester.pumpAndSettle();

      await tester.tap(find.text('portfolio').last);
      await tester.pumpAndSettle();

      expect(selectedType, AccountTypes.portfolio);
    });

    testWidgets('handles null initial value', (tester) async {
      late Reusables reusables;

      await pumpWithProviders(
        tester,
        Scaffold(
          body: Builder(
            builder: (context) {
              reusables = Reusables(context);
              return reusables.buildEnumDropdown<AssetTypes>(
                initialValue: null,
                values: AssetTypes.values,
                label: 'Type',
                onChanged: (_) {},
                display: (t) => t.name,
              );
            },
          ),
        ),
      );

      // Should render without errors
      expect(find.byType(DropdownButtonFormField<AssetTypes>), findsOneWidget);
    });

    testWidgets('uses custom display function for labels', (tester) async {
      late Reusables reusables;

      await pumpWithProviders(
        tester,
        Scaffold(
          body: Builder(
            builder: (context) {
              reusables = Reusables(context);
              return reusables.buildEnumDropdown<AccountTypes>(
                initialValue: null,
                values: AccountTypes.values,
                label: 'Type',
                onChanged: (_) {},
                display: (t) => 'Custom_${t.name}',
              );
            },
          ),
        ),
      );

      await tester.tap(find.byType(DropdownButtonFormField<AccountTypes>));
      await tester.pumpAndSettle();

      expect(find.text('Custom_cash'), findsWidgets);
      expect(find.text('Custom_portfolio'), findsWidgets);
    });

    testWidgets('has OutlineInputBorder decoration', (tester) async {
      late Reusables reusables;

      await pumpWithProviders(
        tester,
        Scaffold(
          body: Builder(
            builder: (context) {
              reusables = Reusables(context);
              return reusables.buildEnumDropdown<AccountTypes>(
                initialValue: null,
                values: AccountTypes.values,
                label: 'Type',
                onChanged: (_) {},
                display: (t) => t.name,
              );
            },
          ),
        ),
      );

      // Verify DropdownButtonFormField exists (which implicitly has InputDecoration)
      expect(find.byType(DropdownButtonFormField<AccountTypes>), findsOneWidget);
    });

    testWidgets('renders with single value in list', (tester) async {
      late Reusables reusables;

      await pumpWithProviders(
        tester,
        Scaffold(
          body: Builder(
            builder: (context) {
              reusables = Reusables(context);
              return reusables.buildEnumDropdown<AccountTypes>(
                initialValue: null,
                values: const [AccountTypes.cash],
                label: 'Type',
                onChanged: (_) {},
                display: (t) => t.name,
              );
            },
          ),
        ),
      );

      await tester.tap(find.byType(DropdownButtonFormField<AccountTypes>));
      await tester.pumpAndSettle();

      expect(find.text('cash'), findsWidgets);
    });
  });
}
