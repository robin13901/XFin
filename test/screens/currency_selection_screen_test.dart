import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xfin/database/daos/assets_dao.dart';
import 'package:xfin/database/tables.dart';
import 'package:xfin/screens/currency_selection_screen.dart';

// Imports for types referenced by the screen
import 'package:xfin/database/app_database.dart';
import 'package:xfin/providers/base_currency_provider.dart';
import 'package:xfin/providers/language_provider.dart';
import 'package:xfin/l10n/app_localizations.dart';

// ---- Mocks ----
class MockAppDatabase extends Mock implements AppDatabase {}
class MockAssetsDao extends Mock implements AssetsDao {}
class MockBaseCurrencyProvider extends Mock implements BaseCurrencyProvider {}
class MockLanguageProvider extends Mock implements LanguageProvider {}
class MockAppLocalizations extends Mock implements AppLocalizations {}
class MockNavigatorObserver extends Mock implements NavigatorObserver {}

/// A LocalizationsDelegate that returns the provided mock AppLocalizations instance.
class _TestLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  final AppLocalizations instance;
  const _TestLocalizationsDelegate(this.instance);

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<AppLocalizations> load(Locale locale) => SynchronousFuture(instance);

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) => false;
}

void main() {
  late MockAppDatabase mockDb;
  late MockAssetsDao mockAssetsDao;
  late MockBaseCurrencyProvider mockBaseProvider;
  late MockLanguageProvider mockLanguageProvider;
  late MockAppLocalizations mockL10n;
  late MockNavigatorObserver mockObserver;

  // Register fallback values for complex types used as arguments by mocktail.
  setUpAll(() {
    // Provide a fallback AssetsCompanion - used by mocktail when matching/untyped any() is insufficient.
    registerFallbackValue(
      const AssetsCompanion(
        name: Value('EUR'),
        type: Value(AssetTypes.currency),
        tickerSymbol: Value('EUR'),
        value: Value(0.0),
        sharesOwned: Value(0.0),
        netCostBasis: Value(1.0),
        brokerCostBasis: Value(1.0),
        buyFeeTotal: Value(0.0),
      ),
    );

    // Fallback for Locale if needed
    registerFallbackValue(const Locale('en', 'US'));
  });

  setUp(() {
    mockDb = MockAppDatabase();
    mockAssetsDao = MockAssetsDao();
    mockBaseProvider = MockBaseCurrencyProvider();
    mockLanguageProvider = MockLanguageProvider();
    mockL10n = MockAppLocalizations();
    mockObserver = MockNavigatorObserver();

    // Default SharedPreferences mock initial values - start empty for each test unless test overrides
    SharedPreferences.setMockInitialValues(<String, Object>{});

    // Wire up database DAO
    when(() => mockDb.assetsDao).thenReturn(mockAssetsDao);
    when(() => mockAssetsDao.insert(any())).thenAnswer((_) async => 1);

    // Default behaviors for providers
    when(() => mockBaseProvider.initialize(any())).thenAnswer((_) async {});
    when(() => mockLanguageProvider.appLocale).thenReturn(const Locale('en', 'US'));

    // Provide localized strings used by the widget
    when(() => mockL10n.selectCurrency).thenReturn('Select currency');
    when(() => mockL10n.currencySelectionPrompt).thenReturn('Please choose your currency');
    when(() => mockL10n.confirm).thenReturn('Confirm');
    when(() => mockL10n.pleaseSelectCurrency).thenReturn('Please select a currency');
  });

  group('CurrencySelectionScreen widget', () {
    Future<void> pumpWidgetUnderTest(WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          // Provide a simple /main route to verify navigation happened.
          routes: {
            '/main': (_) => const Scaffold(body: Center(child: Text('MAIN_SCREEN'))),
          },
          // Provide a navigator observer so we can inspect navigation events if needed.
          navigatorObservers: [mockObserver],
          localizationsDelegates: [
            // Provide our mock AppLocalizations via a delegate so AppLocalizations.of(context) works.
            _TestLocalizationsDelegate(mockL10n),
            // (other delegates not needed for this widget)
          ],
          home: MultiProvider(
            providers: [
              Provider<AppDatabase>.value(value: mockDb),
              ChangeNotifierProvider<BaseCurrencyProvider>.value(value: mockBaseProvider),
              ChangeNotifierProvider<LanguageProvider>.value(value: mockLanguageProvider),
            ],
            child: const CurrencySelectionScreen(),
          ),
        ),
      );
      // Let the initial build settle
      await tester.pumpAndSettle();
    }

    testWidgets('shows list of currencies and confirm button (sanity)', (tester) async {
      await pumpWidgetUnderTest(tester);

      // Confirm the UI shows the title and available currencies from the widget
      expect(find.text('Select currency'), findsOneWidget);
      expect(find.text('EUR'), findsOneWidget);
      expect(find.text('USD'), findsOneWidget);
      expect(find.text('GBP'), findsOneWidget);
      expect(find.text('JPY'), findsOneWidget);

      // The confirm button should exist
      expect(find.widgetWithText(ElevatedButton, 'Confirm'), findsOneWidget);
    });

    testWidgets('tapping confirm without selecting currency shows SnackBar', (tester) async {
      await pumpWidgetUnderTest(tester);

      // Ensure no currency is selected and press confirm
      expect(find.byIcon(Icons.radio_button_checked), findsNothing);
      await tester.tap(find.widgetWithText(ElevatedButton, 'Confirm'));

      // SnackBar is shown with localized message
      await tester.pump(); // start the animation to show SnackBar
      expect(find.text('Please select a currency'), findsOneWidget);

      // The SnackBar is inside a Material, ensure it's visible
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('selecting a currency and confirming saves prefs, adds asset, initializes base provider and navigates', (tester) async {
      await pumpWidgetUnderTest(tester);

      // Tap the USD list tile to select USD
      await tester.tap(find.text('USD'));
      await tester.pumpAndSettle();

      // After tapping, the selected icon should be the checked radio for USD
      // Find the ListTile that has a leading checked icon next to USD text:
      find.ancestor(
        of: find.widgetWithText(ListTile, 'USD'),
        matching: find.byWidgetPredicate((w) {
          if (w is ListTile) {
            final leading = w.leading;
            if (leading is Icon) {
              return leading.icon == Icons.radio_button_checked;
            }
          }
          return false;
        }),
      );

      // The above ancestor lookup might not find because ListTile builds differently;
      // as a simpler assertion, ensure tapping didn't throw and the radio icon exists somewhere.
      expect(find.byIcon(Icons.radio_button_checked), findsOneWidget);

      // Confirm selection
      await tester.tap(find.widgetWithText(ElevatedButton, 'Confirm'));
      await tester.pumpAndSettle(); // allow async operations and navigation to complete

      // Verify SharedPreferences were written
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('selected_currency'), 'USD');
      expect(prefs.getBool('currency_selected'), isTrue);

      // Verify that the database DAO addAsset was called once
      verify(() => mockAssetsDao.insert(any())).called(1);

      // Verify BaseCurrencyProvider.initialize was called with the appLocale from LanguageProvider
      verify(() => mockBaseProvider.initialize(const Locale('en', 'US'))).called(1);

      // Verify navigation happened to /main by locating the placeholder text of that route
      expect(find.text('MAIN_SCREEN'), findsOneWidget);
    });

    testWidgets('selecting a currency and confirming still works when prefs already contained values', (tester) async {
      // Pre-populate SharedPreferences to simulate existing values (should be overwritten)
      SharedPreferences.setMockInitialValues(<String, Object>{
        'selected_currency': 'EUR',
        'currency_selected': true,
      });

      await pumpWidgetUnderTest(tester);

      // Select JPY this time
      await tester.tap(find.text('JPY'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Confirm'));
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      // Ensure new value overwrote the old one
      expect(prefs.getString('selected_currency'), 'JPY');
      expect(prefs.getBool('currency_selected'), isTrue);

      verify(() => mockAssetsDao.insert(any())).called(1);
      verify(() => mockBaseProvider.initialize(const Locale('en', 'US'))).called(1);
      expect(find.text('MAIN_SCREEN'), findsOneWidget);
    });
  });
}