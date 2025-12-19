import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xfin/database/app_database.dart';
import 'package:xfin/database/tables.dart';
import 'package:xfin/l10n/app_localizations.dart';
import 'package:xfin/providers/base_currency_provider.dart';
import 'package:xfin/screens/trades_screen.dart';
import 'package:xfin/widgets/trade_form.dart';

void main() {
  late AppDatabase db;
  late BaseCurrencyProvider currencyProvider;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    const locale = Locale('en');
    currencyProvider = BaseCurrencyProvider();
    await currencyProvider.initialize(locale);
  });

  tearDown(() async {
    await db.close();
  });

  Future<AppLocalizations> pumpWidget(WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<AppDatabase>.value(value: db),
          ChangeNotifierProvider<BaseCurrencyProvider>.value(
              value: currencyProvider),
        ],
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: TradesScreen(),
        ),
      ),
    );
    return AppLocalizations.of(tester.element(find.byType(TradesScreen)))!;
  }

  // Helper function to get the color of a specific TextSpan within a Text.rich
  Color? getTextSpanColor(WidgetTester tester, Finder parentFinder,
      String fullTextContaining, String valueText) {
    final textRichFinder = find.descendant(
      of: parentFinder,
      matching: find.byWidgetPredicate((widget) {
        if (widget is Text && widget.textSpan is TextSpan) {
          final textSpan = widget.textSpan as TextSpan;
          return textSpan.toPlainText().contains(fullTextContaining);
        }
        return false;
      }),
    );

    expect(textRichFinder, findsOneWidget,
        reason:
            'Could not find the Text.rich widget containing "$fullTextContaining"');
    final textRichWidget = tester.widget<Text>(textRichFinder);
    final rootTextSpan = textRichWidget.textSpan as TextSpan;

    for (final childSpan in rootTextSpan.children ?? []) {
      if (childSpan is TextSpan && childSpan.text == valueText) {
        return childSpan.style?.color;
      }
    }
    return null;
  }

  testWidgets(
      'shows loading indicator and then empty message',
      (tester) => tester.runAsync(() async {
            final l10n = await pumpWidget(tester);
            expect(find.byType(CircularProgressIndicator), findsOneWidget);

            await tester.pumpAndSettle();

            expect(find.text(l10n.noTrades), findsOneWidget);
            expect(find.byType(ListView), findsNothing);

            await tester.pumpWidget(Container());
          }));

  testWidgets(
      'tapping FAB opens TradeForm for new trade',
      (tester) => tester.runAsync(() async {
            await pumpWidget(tester);
            await tester.pumpAndSettle();

            await tester.tap(find.byIcon(Icons.add));
            await tester.pumpAndSettle();

            expect(find.byType(TradeForm), findsOneWidget);
            final form = tester.widget<TradeForm>(find.byType(TradeForm));
            expect(form.trade, isNull);

            await tester.pumpWidget(Container());
          }));

  group('with initial trades', () {
    late Account sourceAccount, targetAccount;
    late Asset asset;
    late NumberFormat pnlFormat;
    late NumberFormat formatter;

    setUp(() async {
      pnlFormat =
          NumberFormat.currency(locale: 'de_DE', symbol: '€', decimalDigits: 2);
      formatter = NumberFormat.decimalPattern('de_DE');
      formatter.minimumFractionDigits = 2;
      formatter.maximumFractionDigits = 2;

      sourceAccount = const Account(
        id: 1,
        name: 'Source Account',
        balance: 10000,
        initialBalance: 10000,
        type: AccountTypes.cash,
        isArchived: false,
      );
      targetAccount = const Account(
        id: 2,
        name: 'Target Account',
        balance: 0,
        initialBalance: 0,
        type: AccountTypes.portfolio,
        isArchived: false,
      );
      await db.into(db.accounts).insert(sourceAccount.toCompanion(false));
      await db.into(db.accounts).insert(targetAccount.toCompanion(false));

      asset = const Asset(
          id: 1,
          name: 'Test Stock',
          type: AssetTypes.stock,
          tickerSymbol: 'TSS',
          currencySymbol: '',
          value: 100,
          shares: 10,
          brokerCostBasis: 1000,
          netCostBasis: 1000,
          buyFeeTotal: 0,
          isArchived: false);
      await db.into(db.assets).insert(asset.toCompanion(false));

      await db
          .into(db.assetsOnAccounts)
          .insert(AssetsOnAccountsCompanion.insert(
            accountId: targetAccount.id,
            assetId: asset.id,
            value: const Value(1000),
            shares: const Value(10),
            netCostBasis: const Value(1000),
            brokerCostBasis: const Value(1000),
            buyFeeTotal: const Value(10),
          ));

      final buyTrade = TradesCompanion.insert(
          type: TradeTypes.buy,
          datetime: 20230101090000,
          assetId: asset.id,
          shares: 5,
          costBasis: 100,
          fee: const Value(5),
          sourceAccountId: sourceAccount.id,
          targetAccountId: targetAccount.id,
          sourceAccountValueDelta: -505,
          targetAccountValueDelta: 500);

      final sellTradePositivePnl = TradesCompanion.insert(
        type: TradeTypes.sell,
        datetime: 20230102100000,
        assetId: asset.id,
        shares: 2,
        costBasis: 120,
        fee: const Value(5),
        tax: const Value(5),
        sourceAccountId: sourceAccount.id,
        targetAccountId: targetAccount.id,
        sourceAccountValueDelta: 230,
        targetAccountValueDelta: -240,
        profitAndLoss: const Value(30),
        // (120 * 2) - (100 * 2) - 5 - 5 = 30
        returnOnInvest: const Value(0.15), // 30 / (2 * 100)
      );

      final sellTradeNegativePnl = TradesCompanion.insert(
        type: TradeTypes.sell,
        datetime: 20230103110000,
        assetId: asset.id,
        shares: 3,
        costBasis: 90,
        fee: const Value(5),
        sourceAccountId: sourceAccount.id,
        targetAccountId: targetAccount.id,
        sourceAccountValueDelta: 265,
        targetAccountValueDelta: -270,
        profitAndLoss: const Value(-35),
        // (90 * 3) - (100 * 3) - 5 = -35
        returnOnInvest: const Value(-0.1167),
      );

      await db.into(db.trades).insert(buyTrade);
      await db.into(db.trades).insert(sellTradePositivePnl);
      await db.into(db.trades).insert(sellTradeNegativePnl);
    });

    testWidgets(
        'displays buy trade correctly',
        (tester) => tester.runAsync(() async {
              final l10n = await pumpWidget(tester);
              await tester.pumpAndSettle();

              expect(find.byType(ListView), findsOneWidget);
              expect(find.textContaining(l10n.noTrades), findsNothing);

              // Verify Buy Trade
              final buyTradeFinder = find.ancestor(
                  of: find.textContaining('BUY 5 TSS @ 100,00'),
                  matching: find.byType(ListTile));
              expect(buyTradeFinder, findsOneWidget);
              expect(
                  find.descendant(
                      of: buyTradeFinder,
                      matching: find.textContaining('01.01.2023, 09:00')),
                  findsOneWidget);
              expect(
                  find.descendant(
                      of: buyTradeFinder,
                      matching: find.textContaining(
                          '${l10n.value}: ${pnlFormat.format(500)}')),
                  findsOneWidget);
              expect(
                  find.descendant(
                      of: buyTradeFinder,
                      matching: find.textContaining(
                          '${l10n.fee}: ${pnlFormat.format(5)}')),
                  findsOneWidget);
              expect(
                  find.descendant(
                      of: buyTradeFinder,
                      matching: find.textContaining(
                          '${l10n.tax}: ${pnlFormat.format(0)}')),
                  findsNothing);
              expect(
                  find.descendant(
                      of: buyTradeFinder,
                      matching: find.textContaining(
                          '${l10n.profitAndLoss}: ${pnlFormat.format(0)}')),
                  findsNothing);
              expect(
                  find.descendant(
                      of: buyTradeFinder,
                      matching: find.textContaining(
                          '${l10n.returnOnInvestment}: ${formatter.format(15)} %')),
                  findsNothing);

              await tester.pumpWidget(Container());
            }));

    testWidgets(
        'displays sell trade with positive P&L correctly',
        (tester) => tester.runAsync(() async {
              final l10n = await pumpWidget(tester);
              await tester.pumpAndSettle();

              expect(find.byType(ListView), findsOneWidget);
              expect(find.textContaining(l10n.noTrades), findsNothing);

              final sellPosFinder = find.ancestor(
                  of: find.textContaining('SELL 2 TSS'),
                  matching: find.byType(ListTile));
              expect(sellPosFinder, findsOneWidget);

              expect(
                  find.descendant(
                      of: sellPosFinder,
                      matching: find.textContaining('02.01.2023, 10:00')),
                  findsOneWidget);
              expect(
                  find.descendant(
                      of: sellPosFinder,
                      matching:
                          find.text('${l10n.value}: ${pnlFormat.format(240)}')),
                  findsOneWidget);
              expect(
                  find.descendant(
                      of: sellPosFinder,
                      matching:
                          find.text('${l10n.fee}: ${pnlFormat.format(5)}')),
                  findsOneWidget);
              expect(
                  find.descendant(
                      of: sellPosFinder,
                      matching:
                          find.text('${l10n.tax}: ${pnlFormat.format(5)}')),
                  findsOneWidget);
              expect(
                  find.descendant(
                      of: sellPosFinder,
                      matching: find.text(
                          '${l10n.profitAndLoss}: ${pnlFormat.format(30)}')),
                  findsOneWidget);
              expect(
                  find.descendant(
                      of: sellPosFinder,
                      matching: find.text(
                          '${l10n.returnOnInvestment}: ${formatter.format(15)} %')),
                  findsOneWidget);

              final pnlColor = getTextSpanColor(
                  tester,
                  sellPosFinder,
                  '${l10n.profitAndLoss}: ${pnlFormat.format(30)}',
                  pnlFormat.format(30));
              expect(pnlColor, Colors.green);

              final roiColor = getTextSpanColor(
                  tester,
                  sellPosFinder,
                  '${l10n.returnOnInvestment}: ${formatter.format(15)} %',
                  '15,00 %');
              expect(roiColor, Colors.green);

              await tester.pumpWidget(Container());
            }));

    testWidgets(
        'displays sell trade with negative P&L correctly',
        (tester) => tester.runAsync(() async {
              final l10n = await pumpWidget(tester);
              await tester.pumpAndSettle();

              expect(find.byType(ListView), findsOneWidget);
              expect(find.textContaining(l10n.noTrades), findsNothing);

              final sellNegFinder = find.ancestor(
                  of: find.textContaining('SELL 3 TSS'),
                  matching: find.byType(ListTile));
              expect(sellNegFinder, findsOneWidget);
              expect(
                  find.descendant(
                      of: sellNegFinder,
                      matching: find.textContaining('03.01.2023, 11:00')),
                  findsOneWidget);
              expect(
                  find.descendant(
                      of: sellNegFinder,
                      matching:
                          find.text('${l10n.value}: ${pnlFormat.format(270)}')),
                  findsOneWidget);
              expect(
                  find.descendant(
                      of: sellNegFinder,
                      matching:
                          find.text('${l10n.fee}: ${pnlFormat.format(5)}')),
                  findsOneWidget);
              expect(
                  find.descendant(
                      of: sellNegFinder,
                      matching:
                          find.text('${l10n.tax}: ${pnlFormat.format(0)}')),
                  findsOneWidget);
              expect(
                  find.descendant(
                      of: sellNegFinder,
                      matching: find.text(
                          '${l10n.profitAndLoss}: ${pnlFormat.format(-35)}')),
                  findsOneWidget);
              expect(
                  find.descendant(
                      of: sellNegFinder,
                      matching: find.text(
                          '${l10n.returnOnInvestment}: ${formatter.format(-11.67)} %')),
                  findsOneWidget);

              final pnlColor = getTextSpanColor(
                  tester,
                  sellNegFinder,
                  '${l10n.profitAndLoss}: ${pnlFormat.format(-35)}',
                  pnlFormat.format(-35));
              expect(pnlColor, Colors.red);

              final roiColor = getTextSpanColor(
                  tester,
                  sellNegFinder,
                  '${l10n.returnOnInvestment}: ${formatter.format(-11.67)} %',
                  '${formatter.format(-11.67)} %');
              expect(roiColor, Colors.red);

              await tester.pumpWidget(Container());
            }));
  });
}
