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
    expect(find.text('Bookings'), findsOneWidget);
    expect(find.text('Trades'), findsOneWidget);
    expect(find.text('Transfers'), findsNothing);
    expect(find.text('Swipe left or right for more details'), findsNothing);

    final expectedDate = DateFormat('EEEE, dd.MM.yyyy', 'en')
        .format(DateTime(today.year, today.month, 10));
    expect(find.text(expectedDate), findsOneWidget);

    await tester.drag(find.byType(PageView).last, const Offset(-280, 0));
    await tester.pumpAndSettle();

    expect(find.text('Salary'), findsOneWidget);
  });

  testWidgets('uses stable calendar pager viewport height to avoid row-count overflow during swipe',
      (tester) async {
    await pumpCalendar(tester);

    final pageViewFinder = find.byType(PageView).first;
    final pageSize = tester.getSize(pageViewFinder);

    final now = DateTime.now();
    DateTime addMonths(DateTime date, int delta) {
      final totalMonths = date.year * 12 + (date.month - 1) + delta;
      final year = totalMonths ~/ 12;
      final month = totalMonths % 12 + 1;
      return DateTime(year, month, 1);
    }

    int gridRowCount(DateTime month) {
      final firstDayOfMonth = DateTime(month.year, month.month, 1);
      final lastDayOfMonth = DateTime(month.year, month.month + 1, 0);
      final firstWeekdayOffset = (firstDayOfMonth.weekday + 6) % 7;
      final trailingDays = (7 - lastDayOfMonth.weekday) % 7;
      final totalDays = firstWeekdayOffset + lastDayOfMonth.day + trailingDays;
      return (totalDays / 7).ceil();
    }

    final current = DateTime(now.year, now.month, 1);
    final neighborRows = [
      gridRowCount(addMonths(current, -1)),
      gridRowCount(current),
      gridRowCount(addMonths(current, 1)),
    ];
    final expectedMaxRows = neighborRows.reduce((a, b) => a > b ? a : b);
    const expectedHeight = 32.0 + 1.0 + 78.0 * 6 + 12.0;
    expect(expectedMaxRows, inInclusiveRange(4, 6));
    if (expectedMaxRows == 6) {
      expect(pageSize.height, expectedHeight);
    } else {
      expect(pageSize.height, greaterThanOrEqualTo(32.0 + 1.0 + 78.0 * expectedMaxRows + 12.0));
    }
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
}
