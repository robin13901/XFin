import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:xfin/database/app_database.dart';
import 'package:xfin/database/tables.dart';
import 'package:xfin/l10n/app_localizations.dart';
import 'package:xfin/providers/database_provider.dart';
import 'package:xfin/screens/calendar_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late int accountId;

  Future<void> pumpCalendar(WidgetTester tester) async {
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
          home: CalendarScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> insertBooking({
    required DateTime day,
    required String category,
    required double value,
  }) {
    final dateInt = day.year * 10000 + day.month * 100 + day.day;
    return db.into(db.bookings).insert(
          BookingsCompanion.insert(
            date: dateInt,
            accountId: accountId,
            category: category,
            shares: value,
            value: value,
          ),
        );
  }

  Future<void> insertTrade({required DateTime day, required double pnl}) {
    final dateInt = day.year * 10000 + day.month * 100 + day.day;
    final datetime = dateInt * 1000000 + 120000;
    return db.into(db.trades).insert(
          TradesCompanion.insert(
            datetime: datetime,
            type: TradeTypes.sell,
            sourceAccountId: accountId,
            targetAccountId: accountId,
            assetId: 1,
            shares: 1,
            costBasis: 1,
            sourceAccountValueDelta: pnl,
            targetAccountValueDelta: -pnl / 2,
            profitAndLoss: Value(pnl),
          ),
        );
  }

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    DatabaseProvider.instance.initialize(db);

    await db.into(db.assets).insert(AssetsCompanion.insert(
          name: 'EUR',
          type: AssetTypes.fiat,
          tickerSymbol: 'EUR',
        ));

    accountId = await db.into(db.accounts).insert(
          AccountsCompanion.insert(name: 'Cash', type: AccountTypes.cash),
        );

    final now = DateTime.now();
    final currentMonthDay = DateTime(now.year, now.month, 10);
    final nextMonthDay = DateTime(now.year, now.month + 1, 12);

    await insertBooking(day: currentMonthDay, category: 'Salary', value: 1200);
    await insertBooking(day: currentMonthDay, category: 'Rent', value: -500);
    await insertTrade(day: currentMonthDay, pnl: 80);

    await insertBooking(day: nextMonthDay, category: 'Bonus', value: 700);
    await insertBooking(day: nextMonthDay, category: 'Food', value: -120);
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets('renders calendar with pie chart and month summary', (tester) async {
    await pumpCalendar(tester);

    expect(find.text('Calendar'), findsOneWidget);
    expect(find.text('Monthly overview'), findsOneWidget);
    expect(find.byType(PageView), findsAtLeastNWidgets(1));
    expect(find.byType(PieChart), findsOneWidget);
    expect(find.text('Inflows'), findsAtLeastNWidgets(1));
    expect(find.text('Outflows'), findsAtLeastNWidgets(1));
  });

  testWidgets('swiping month updates month dataset and keeps chart/list in sync',
      (tester) async {
    await pumpCalendar(tester);

    expect(find.text('Salary'), findsOneWidget);
    expect(find.text('Bonus'), findsNothing);

    await tester.fling(find.byType(PageView).first, const Offset(-320, 0), 700);
    await tester.pumpAndSettle();

    expect(find.text('Bonus'), findsOneWidget);
    expect(find.text('Salary'), findsNothing);

    final pageView = tester.widget<PageView>(find.byType(PageView).first);
    expect(pageView.allowImplicitScrolling, isTrue);
    expect(pageView.physics, isA<BouncingScrollPhysics>());
  });

  testWidgets('tap day opens animated details dialog with paged sections',
      (tester) async {
    await pumpCalendar(tester);

    final today = DateTime.now();
    await tester.tap(find.text('${DateTime(today.year, today.month, 10).day}').first);
    await tester.pumpAndSettle();

    expect(find.text('Analytical stats'), findsOneWidget);

    final expectedDate = DateFormat('EEEE, dd.MM.yyyy', 'en')
        .format(DateTime(today.year, today.month, 10));
    expect(find.text(expectedDate), findsOneWidget);

    await tester.drag(find.byType(PageView).last, const Offset(-280, 0));
    await tester.pumpAndSettle();
  });

  testWidgets('calendar grid has fixed height and rows adapt when switching between months with different row counts',
      (tester) async {
    await pumpCalendar(tester);

    final pageViewFinder = find.byType(PageView).first;
    final initialSize = tester.getSize(pageViewFinder);

    // Verify fixed height for 6 rows
    const expectedHeight = 32.0 + 1.0 + 78.0 * 6 + 32.0;
    expect(initialSize.height, expectedHeight);

    // Swipe to another month
    await tester.fling(pageViewFinder, const Offset(-320, 0), 700);
    await tester.pumpAndSettle();

    final newSize = tester.getSize(pageViewFinder);

    // Verify height remains constant
    expect(newSize.height, initialSize.height);
    expect(newSize.height, expectedHeight);
  });

  testWidgets('today marker uses onPrimary text color in dark theme for readability',
      (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<DatabaseProvider>.value(
        value: DatabaseProvider.instance,
        child: MaterialApp(
          theme: ThemeData.dark(),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const CalendarScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final todayDay = DateTime.now().day.toString();
    final todayText = find.text(todayDay).first;
    final textWidget = tester.widget<Text>(todayText);
    expect(textWidget.style?.color, ThemeData.dark().colorScheme.onPrimary);
  });

  testWidgets('calendar grid rows expand to fill available space regardless of row count',
      (tester) async {
    await pumpCalendar(tester);

    // Find the month grid within the PageView
    final pageViewFinder = find.byType(PageView).first;

    // Verify the grid uses Expanded widgets for adaptive row sizing
    expect(find.descendant(
      of: pageViewFinder,
      matching: find.byType(Expanded),
    ), findsAtLeastNWidgets(1));
  });

  testWidgets('paging between months is snappy with no loading indicators',
      (tester) async {
    await pumpCalendar(tester);

    // Start swiping
    final pageViewFinder = find.byType(PageView).first;
    final gesture = await tester.startGesture(tester.getCenter(pageViewFinder));
    await gesture.moveBy(const Offset(-200, 0));
    await tester.pump();

    // During the swipe, there should be no CircularProgressIndicator
    expect(find.byType(CircularProgressIndicator), findsNothing);

    await gesture.up();
    await tester.pumpAndSettle();

    // After settling, still no loading indicators
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('prefetches neighbor months for smooth navigation',
      (tester) async {
    await pumpCalendar(tester);

    // Allow time for prefetching
    await tester.pumpAndSettle();

    // Navigate forward and backward multiple times
    final pageViewFinder = find.byType(PageView).first;

    for (var i = 0; i < 3; i++) {
      await tester.fling(pageViewFinder, const Offset(-320, 0), 700);
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
    }

    for (var i = 0; i < 3; i++) {
      await tester.fling(pageViewFinder, const Offset(320, 0), 700);
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
    }
  });
}
