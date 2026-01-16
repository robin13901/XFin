import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:xfin/database/app_database.dart';
import 'package:xfin/database/daos/accounts_dao.dart';
import 'package:xfin/database/daos/analysis_dao.dart';
import 'package:xfin/l10n/app_localizations.dart';
import 'package:xfin/providers/database_provider.dart';
import 'package:xfin/screens/analysis_screen.dart';

class _MockAppDatabase extends Mock implements AppDatabase {}

class _MockAnalysisDao extends Mock implements AnalysisDao {}

class _MockAccountsDao extends Mock implements AccountsDao {}

void main() {
  late _MockAppDatabase mockDb;
  late _MockAnalysisDao mockAnalysisDao;
  late _MockAccountsDao mockAccountsDao;

  // Common test data
  late List<FlSpot> balanceHistory;
  late double sumOfInitialBalances;
  late double currentMonthInflows;
  late double currentMonthOutflows;
  late double currentMonthProfit;
  late double averageMonthlyInflows;
  late double averageMonthlyOutflows;
  late double averageMonthlyProfit;
  late Map<String, double> currentMonthCategoryInflows;
  late Map<String, double> currentMonthCategoryOutflows;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    // register fallback values for mocktail if matchers require them
    registerFallbackValue(DateTime(2000));
  });

  setUp(() {
    mockDb = _MockAppDatabase();
    DatabaseProvider.instance.initialize(mockDb);
    mockAnalysisDao = _MockAnalysisDao();
    mockAccountsDao = _MockAccountsDao();

    // Wire the mock DB to return the mocked DAOs.
    when(() => mockDb.analysisDao).thenReturn(mockAnalysisDao);
    when(() => mockDb.accountsDao).thenReturn(mockAccountsDao);

    // Build deterministic test data: 10 days of increasing balances
    final now = DateTime.now();
    final dayMs = const Duration(days: 1).inMilliseconds;
    balanceHistory = List.generate(10, (i) {
      final x = (now.millisecondsSinceEpoch + i * dayMs).toDouble();
      final y = 1000.0 + i * 10.0; // increasing balance
      return FlSpot(x, y);
    });

    sumOfInitialBalances = 900.0;
    currentMonthInflows = 300.0;
    currentMonthOutflows = -120.0;
    currentMonthProfit = 180.0;
    averageMonthlyInflows = 250.0;
    averageMonthlyOutflows = -100.0;
    averageMonthlyProfit = 150.0;

    // A few categories such that very small ones are aggregated into '...'
    currentMonthCategoryInflows = {
      'Salary': 280.0,
      'Bonus': 10.0,
      'Tiny': 0.5, // should be aggregated into '...'
      'Micro': 0.3, // aggregated
    };

    currentMonthCategoryOutflows = {
      'Rent': -80.0,
      'Groceries': -30.0,
      'Small': -0.4, // aggregated
    };

    // Default: make analysis DAO futures return immediate values.
    when(() => mockAnalysisDao.getBalanceHistory())
        .thenAnswer((_) async => balanceHistory);
    when(() => mockAccountsDao.getSumOfInitialBalances())
        .thenAnswer((_) async => sumOfInitialBalances);
    when(() => mockAnalysisDao.getTotalInflowsForMonth(any()))
        .thenAnswer((_) async => currentMonthInflows);
    when(() => mockAnalysisDao.getTotalOutflowsForMonth(any()))
        .thenAnswer((_) async => currentMonthOutflows);
    when(() => mockAnalysisDao.getProfitAndLossForMonth(any()))
        .thenAnswer((_) async => currentMonthProfit);
    when(() => mockAnalysisDao.getMonthlyInflows())
        .thenAnswer((_) async => averageMonthlyInflows);
    when(() => mockAnalysisDao.getMonthlyOutflows())
        .thenAnswer((_) async => averageMonthlyOutflows);
    when(() => mockAnalysisDao.getMonthlyProfitAndLoss())
        .thenAnswer((_) async => averageMonthlyProfit);
    when(() => mockAnalysisDao.getMonthlyCategoryInflows())
        .thenAnswer((_) async => currentMonthCategoryInflows);
    when(() => mockAnalysisDao.getMonthlyCategoryOutflows())
        .thenAnswer((_) async => currentMonthCategoryOutflows);
  });

  group('AnalysisScreen widget tests', () {
    // Helper to pump the screen; always await this.
    Future<void> pumpWidget(WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<DatabaseProvider>.value(
          value: DatabaseProvider.instance,
          child: const MaterialApp(
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: AnalysisScreen(),
          ),
        ),
      );
      // Allow the first frame to build (initState etc.)
      await tester.pump();
    }

    testWidgets('displays loading indicator while futures are pending',
        (tester) async {
      // Make balance history future delayed to simulate loading state.
      // IMPORTANT: Do NOT wrap this test in tester.runAsync; we will use
      // tester.pump(Duration) to advance fake timers.
      when(() => mockAnalysisDao.getBalanceHistory()).thenAnswer(
        (_) => Future<List<FlSpot>>.delayed(
          const Duration(milliseconds: 300),
          () => balanceHistory,
        ),
      );

      // pump widget normally (no runAsync)
      await pumpWidget(tester);

      // Immediately after pump, loading indicator should be present
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Advance fake async clock to allow the delayed future to complete.
      // We use a slightly larger duration than the mock delay.
      await tester.pump(const Duration(milliseconds: 350));
      // One more pump to process build triggered by the future completion.
      await tester.pump();

      // Now expect the monthly summary header
      expect(find.text('Monatliche Übersicht'), findsOneWidget);

      await tester.pumpWidget(Container());
    });

    testWidgets('shows error message when a DAO future completes with error',
        (tester) async {
      // Make the DAO return a Future that completes with error (do NOT throw synchronously)
      when(() => mockAnalysisDao.getBalanceHistory())
          .thenAnswer((_) => Future<List<FlSpot>>.error(Exception('boom')));

      await tester.runAsync(() async {
        await pumpWidget(tester);

        // Wait for futures to resolve and UI to rebuild
        await tester.pumpAndSettle();

        // Error text should be visible via FutureBuilder's snapshot.hasError branch
        expect(find.textContaining('Error:'), findsOneWidget);
        expect(find.textContaining('boom'), findsOneWidget);

        await tester.pumpWidget(Container());
      });
    });

    testWidgets('shows "No data available." when balance history is empty',
        (tester) async {
      when(() => mockAnalysisDao.getBalanceHistory())
          .thenAnswer((_) async => <FlSpot>[]);

      await tester.runAsync(() async {
        await pumpWidget(tester);
        await tester.pumpAndSettle();

        expect(find.text('No data available.'), findsOneWidget);

        await tester.pumpWidget(Container());
      });
    });

    testWidgets('renders totals and profit text for default 1W range',
        (tester) async {
      await tester.runAsync(() async {
        await pumpWidget(tester);
        await tester.pumpAndSettle();

        // Default _selectedRange is '1W' and header should show 'Seit 7 Tagen'
        expect(find.text('Seit 7 Tagen'), findsOneWidget);

        // The total balance should be shown and include the euro symbol.
        // The last FlSpot y is 1000 + 9*10 = 1090.0
        final currencyFormat =
            NumberFormat.currency(locale: 'de_DE', symbol: '€');
        final expectedBalance = currencyFormat.format(balanceHistory.last.y);
        expect(find.text(expectedBalance), findsOneWidget);

        await tester.pumpWidget(Container());
      });
    });

    testWidgets('range selection buttons update date text correctly',
        (tester) async {
      await tester.runAsync(() async {
        await pumpWidget(tester);
        await tester.pumpAndSettle();

        // Initially '1W'
        expect(find.text('Seit 7 Tagen'), findsOneWidget);

        // Tap '1M' -> 'Seit 1 Monat'
        await tester.tap(find.text('1M'));
        await tester.pumpAndSettle();
        expect(find.text('Seit 1 Monat'), findsOneWidget);

        // Tap '1J' -> 'Seit 1 Jahr'
        await tester.tap(find.text('1J'));
        await tester.pumpAndSettle();
        expect(find.text('Seit 1 Jahr'), findsOneWidget);

        // Tap 'MAX' -> 'Insgesamt'
        await tester.tap(find.text('MAX'));
        await tester.pumpAndSettle();
        expect(find.text('Insgesamt'), findsOneWidget);

        await tester.pumpWidget(Container());
      });
    });

    testWidgets('toggling indicator checkboxes does not crash and updates UI',
        (tester) async {
      await tester.runAsync(() async {
        await pumpWidget(tester);
        await tester.pumpAndSettle();

        // The indicator checkboxes may be off-screen; ensure they are visible before tapping
        final smaFinder = find.text('30-SMA');
        final emaFinder = find.text('30-EMA');
        final bbFinder = find.text('20-BB');

        // Scroll until visible if necessary
        if (smaFinder.evaluate().isEmpty) {
          await tester.scrollUntilVisible(smaFinder, 50.0);
        }
        await tester.ensureVisible(smaFinder);
        await tester.tap(smaFinder);
        await tester.pumpAndSettle();

        if (emaFinder.evaluate().isEmpty) {
          await tester.scrollUntilVisible(emaFinder, 50.0);
        }
        await tester.ensureVisible(emaFinder);
        await tester.tap(emaFinder);
        await tester.pumpAndSettle();

        if (bbFinder.evaluate().isEmpty) {
          await tester.scrollUntilVisible(bbFinder, 50.0);
        }
        await tester.ensureVisible(bbFinder);
        await tester.tap(bbFinder);
        await tester.pumpAndSettle();

        // No exceptions and widget still present
        expect(find.byType(AnalysisScreen), findsOneWidget);

        await tester.pumpWidget(Container());
      });
    });

    testWidgets(
        'monthly summary shows positive and negative values with correct formatting',
        (tester) async {
      await tester.runAsync(() async {
        // Make one of the monthly profit negative to test color/formatting logic
        when(() => mockAnalysisDao.getMonthlyProfitAndLoss())
            .thenAnswer((_) async => -50.0);

        await pumpWidget(tester);
        await tester.pumpAndSettle();

        // Header present
        expect(find.text('Monatliche Übersicht'), findsOneWidget);

        // The value texts are formatted with euro symbol; ensure the negative value is present
        final currencyFormat =
            NumberFormat.currency(locale: 'de_DE', symbol: '€');
        final neg = currencyFormat.format(-50.0);
        expect(find.text(neg), findsOneWidget);

        await tester.pumpWidget(Container());
      });
    });

    testWidgets(
        'category list collapses small categories into "..." and toggles show all',
        (tester) async {
      await tester.runAsync(() async {
        await pumpWidget(tester);
        await tester.pumpAndSettle();

        // Ensure the category area is visible
        final otherFinder = find.text('...');
        if (otherFinder.evaluate().isEmpty) {
          await tester.scrollUntilVisible(otherFinder, 50.0);
        }
        await tester.ensureVisible(otherFinder);

        // '...' should be present and the "Alle anzeigen" button should be visible
        expect(find.text('...'), findsOneWidget);
        expect(find.text('Alle anzeigen'), findsOneWidget);

        // Ensure the button is visible before tapping
        final alleFinder = find.text('Alle anzeigen');
        if (alleFinder.evaluate().isEmpty) {
          await tester.scrollUntilVisible(alleFinder, 50.0);
        }
        await tester.ensureVisible(alleFinder);
        await tester.tap(alleFinder);
        await tester.pumpAndSettle();

        // Now the small categories should appear and the button should switch to 'Weniger anzeigen'
        expect(find.text('Tiny'), findsOneWidget);
        expect(find.text('Micro'), findsOneWidget);
        expect(find.text('Weniger anzeigen'), findsOneWidget);

        // Tap 'Weniger anzeigen' to collapse again
        final wenigerFinder = find.text('Weniger anzeigen');
        await tester.ensureVisible(wenigerFinder);
        await tester.tap(wenigerFinder);
        await tester.pumpAndSettle();

        expect(find.text('Alle anzeigen'), findsOneWidget);

        await tester.pumpWidget(Container());
      });
    });

    testWidgets(
        'inflow/outflow switch toggles displayed categories and scrollToBottom is invoked',
        (tester) async {
      await tester.runAsync(() async {
        await pumpWidget(tester);
        await tester.pumpAndSettle();

        // Ensure the inflow/outflow switch is visible
        final inflowFinder = find.text('Einnahmen');
        final outflowFinder = find.text('Ausgaben');

        if (inflowFinder.evaluate().isEmpty) {
          await tester.scrollUntilVisible(inflowFinder, 50.0);
        }
        await tester.ensureVisible(inflowFinder);
        await tester.ensureVisible(outflowFinder);

        // Tap Ausgaben to switch to outflows; this triggers a postFrame callback that calls scrollToBottom
        await tester.tap(outflowFinder);
        // pump frames to let the post frame callback fire and the animateTo start
        await tester.pump();
        // Let the animation settle (it uses 300ms duration in code)
        await tester.pump(const Duration(milliseconds: 350));
        await tester.pumpAndSettle();

        // Now category list should show outflow categories (we provided 'Rent', 'Groceries', 'Small')
        expect(find.text('Rent'), findsOneWidget);
        expect(find.text('Groceries'), findsOneWidget);

        // Switch back to inflows
        await tester.tap(inflowFinder);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));
        await tester.pumpAndSettle();

        // Now inflow categories should be visible (Salary and Bonus)
        expect(find.text('Salary'), findsOneWidget);
        expect(find.text('Bonus'), findsOneWidget);

        await tester.pumpWidget(Container());
      });
    });

    testWidgets('handles extreme edge case: single data point gracefully',
        (tester) async {
      // Provide only a single FlSpot to trigger several branches (min/max reduce and touch logic)
      final single = [
        FlSpot(DateTime.now().millisecondsSinceEpoch.toDouble(), 500.0)
      ];
      when(() => mockAnalysisDao.getBalanceHistory())
          .thenAnswer((_) async => single);

      await tester.runAsync(() async {
        await pumpWidget(tester);
        await tester.pumpAndSettle();

        // Should display the single value and not crash
        final currencyFormat =
            NumberFormat.currency(locale: 'de_DE', symbol: '€');
        final expected = currencyFormat.format(500.0);
        expect(find.text(expected), findsOneWidget);

        await tester.pumpWidget(Container());
      });
    });
  });
}
