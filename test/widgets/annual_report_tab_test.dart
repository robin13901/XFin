import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xfin/database/app_database.dart';
import 'package:xfin/database/tables.dart';
import 'package:xfin/l10n/app_localizations.dart';
import 'package:xfin/providers/base_currency_provider.dart';
import 'package:xfin/providers/database_provider.dart';
import 'package:xfin/providers/theme_provider.dart';
import 'package:xfin/widgets/annual_report_tab.dart';

void main() {
  late AppDatabase db;
  late BaseCurrencyProvider currencyProvider;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    DatabaseProvider.instance.initialize(db);
    const locale = Locale('en');
    currencyProvider = BaseCurrencyProvider();
    await currencyProvider.initialize(locale);

    // Insert base data
    await db.into(db.assets).insert(const AssetsCompanion(
      name: Value('EUR'), type: Value(AssetTypes.fiat),
      tickerSymbol: Value('EUR'), value: Value(0), shares: Value(0),
      brokerCostBasis: Value(1), netCostBasis: Value(1), buyFeeTotal: Value(0),
    ));
    await db.into(db.assets).insert(const AssetsCompanion(
      name: Value('Stock A'), type: Value(AssetTypes.stock),
      tickerSymbol: Value('STA'), value: Value(0), shares: Value(0),
      brokerCostBasis: Value(0), netCostBasis: Value(0), buyFeeTotal: Value(0),
    ));
    await db.into(db.accounts).insert(const AccountsCompanion(
      name: Value('Source'), balance: Value(10000),
      initialBalance: Value(10000), type: Value(AccountTypes.cash),
    ));
    await db.into(db.accounts).insert(const AccountsCompanion(
      name: Value('Target'), balance: Value(0),
      initialBalance: Value(0), type: Value(AccountTypes.portfolio),
    ));
  });

  tearDown(() async {
    await db.close();
  });

  Future<AppLocalizations> pumpWidget(WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<DatabaseProvider>.value(
              value: DatabaseProvider.instance),
          ChangeNotifierProvider<BaseCurrencyProvider>.value(
              value: currencyProvider),
          ChangeNotifierProvider<ThemeProvider>.value(value: ThemeProvider.instance),
        ],
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: AnnualReportTab()),
        ),
      ),
    );
    return AppLocalizations.of(tester.element(find.byType(AnnualReportTab)))!;
  }

  testWidgets('displays current year by default', (tester) => tester.runAsync(() async {
    await pumpWidget(tester);
    await tester.pumpAndSettle();

    expect(find.text('${DateTime.now().year}'), findsOneWidget);

    await tester.pumpWidget(Container());
  }));

  testWidgets('year navigation buttons work', (tester) => tester.runAsync(() async {
    await pumpWidget(tester);
    await tester.pumpAndSettle();

    final currentYear = DateTime.now().year;
    expect(find.text('$currentYear'), findsOneWidget);

    // Navigate back
    await tester.tap(find.byKey(const Key('year_back')));
    await tester.pumpAndSettle();
    expect(find.text('${currentYear - 1}'), findsOneWidget);

    // Navigate forward
    await tester.tap(find.byKey(const Key('year_forward')));
    await tester.pumpAndSettle();
    expect(find.text('$currentYear'), findsOneWidget);

    await tester.pumpWidget(Container());
  }));

  testWidgets('forward button disabled at current year', (tester) => tester.runAsync(() async {
    await pumpWidget(tester);
    await tester.pumpAndSettle();

    final forwardButton = tester.widget<IconButton>(find.byKey(const Key('year_forward')));
    expect(forwardButton.onPressed, isNull);

    await tester.pumpWidget(Container());
  }));

  testWidgets('renders bar chart', (tester) => tester.runAsync(() async {
    await pumpWidget(tester);
    await tester.pumpAndSettle();

    expect(find.byType(BarChart), findsOneWidget);

    await tester.pumpWidget(Container());
  }));

  testWidgets('renders segmented button for metric selection', (tester) => tester.runAsync(() async {
    final l10n = await pumpWidget(tester);
    await tester.pumpAndSettle();

    expect(find.byType(SegmentedButton<ReportMetric>), findsOneWidget);
    expect(find.text(l10n.profitAndLossAbbrev), findsOneWidget);
    expect(find.text(l10n.tradeCount), findsOneWidget);

    await tester.pumpWidget(Container());
  }));

  testWidgets('renders summary cards', (tester) => tester.runAsync(() async {
    final l10n = await pumpWidget(tester);
    await tester.pumpAndSettle();

    expect(find.text(l10n.totalProfitAndLoss), findsOneWidget);
    expect(find.text(l10n.totalFees), findsOneWidget);
    expect(find.text(l10n.totalBuys), findsOneWidget);
    expect(find.text(l10n.totalSells), findsOneWidget);
    expect(find.text(l10n.totalTradesVolume), findsOneWidget);

    await tester.pumpWidget(Container());
  }));

  testWidgets('tapping one toggleable card toggles all toggleable cards as a group',
      (tester) async {
    // Insert a buy and a sell trade in current year
    final year = DateTime.now().year;
    await db.into(db.trades).insert(TradesCompanion(
      datetime: Value(year * 10000000000 + 501120000),
      assetId: const Value(2), type: const Value(TradeTypes.buy),
      shares: const Value(2), costBasis: const Value(10),
      fee: const Value(1), tax: const Value(0),
      sourceAccountId: const Value(1), targetAccountId: const Value(2),
      sourceAccountValueDelta: const Value(-21),
      targetAccountValueDelta: const Value(20),
      profitAndLoss: const Value(0), returnOnInvest: const Value(0),
    ));
    await db.into(db.trades).insert(TradesCompanion(
      datetime: Value(year * 10000000000 + 601120000),
      assetId: const Value(2), type: const Value(TradeTypes.sell),
      shares: const Value(1), costBasis: const Value(20),
      fee: const Value(2), tax: const Value(0),
      sourceAccountId: const Value(1), targetAccountId: const Value(2),
      sourceAccountValueDelta: const Value(18),
      targetAccountValueDelta: const Value(-10),
      profitAndLoss: const Value(8), returnOnInvest: const Value(0.8),
    ));

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<DatabaseProvider>.value(
              value: DatabaseProvider.instance),
          ChangeNotifierProvider<BaseCurrencyProvider>.value(
              value: currencyProvider),
          ChangeNotifierProvider<ThemeProvider>.value(value: ThemeProvider.instance),
        ],
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: AnnualReportTab()),
        ),
      ),
    );
    // Let the FutureBuilder resolve
    await tester.pumpAndSettle();

    // Verify sells card shows EUR formatted value initially
    final sellsGesture = find.byKey(const Key('card_tap_sells'));
    expect(sellsGesture, findsOneWidget);
    var sellsText = tester.widget<Text>(
        find.descendant(of: sellsGesture, matching: find.byType(Text)));
    expect(sellsText.data, contains('€'));

    // Ensure buys card is visible and tap it
    final buysCardTap = find.byKey(const Key('card_tap_buys'));
    expect(buysCardTap, findsOneWidget);
    await tester.ensureVisible(buysCardTap);
    await tester.pumpAndSettle();
    await tester.tap(buysCardTap);
    await tester.pumpAndSettle();

    // After tap: sells should show count "1"
    sellsText = tester.widget<Text>(
        find.descendant(of: sellsGesture, matching: find.byType(Text)));
    expect(sellsText.data, '1');

    // Volume should show count "2"
    final volumeGesture = find.byKey(const Key('card_tap_volume'));
    final volumeText = tester.widget<Text>(
        find.descendant(of: volumeGesture, matching: find.byType(Text)));
    expect(volumeText.data, '2');

    // Tap again to toggle back
    await tester.tap(find.byKey(const Key('card_tap_buys')));
    await tester.pumpAndSettle();

    final sellsAfter = tester.widget<Text>(
        find.descendant(of: sellsGesture, matching: find.byType(Text)));
    expect(sellsAfter.data, contains('€'));

    await tester.pumpWidget(Container());
  });
}
