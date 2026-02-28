import 'package:fl_chart/fl_chart.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:xfin/database/app_database.dart';
import 'package:xfin/database/tables.dart';
import 'package:xfin/l10n/app_localizations.dart';
import 'package:xfin/providers/database_provider.dart';
import 'package:xfin/screens/calendar_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

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

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    DatabaseProvider.instance.initialize(db);

    await db.into(db.assets).insert(AssetsCompanion.insert(
          name: 'EUR',
          type: AssetTypes.fiat,
          tickerSymbol: 'EUR',
        ));

    final accountId = await db.into(db.accounts).insert(AccountsCompanion.insert(
          name: 'Cash',
          type: AccountTypes.cash,
        ));

    final now = DateTime.now();
    final currentDateInt = now.year * 10000 + now.month * 100 + now.day;
    final currentDatetimeInt = currentDateInt * 1000000 + 120000;

    await db.into(db.bookings).insert(BookingsCompanion.insert(
          date: currentDateInt,
          accountId: accountId,
          category: 'Salary',
          shares: 100,
          value: 100,
        ));
    await db.into(db.bookings).insert(BookingsCompanion.insert(
          date: currentDateInt,
          accountId: accountId,
          category: 'Rent',
          shares: -40,
          value: -40,
        ));
    await db.into(db.trades).insert(TradesCompanion.insert(
          datetime: currentDatetimeInt,
          type: TradeTypes.sell,
          sourceAccountId: accountId,
          targetAccountId: accountId,
          assetId: 1,
          shares: 1,
          costBasis: 1,
          sourceAccountValueDelta: 20,
          targetAccountValueDelta: -18,
          fee: const Value(1),
          tax: const Value(0.5),
          profitAndLoss: const Value(5),
        ));
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets('renders calendar screen with grid and monthly section', (tester) async {
    await pumpCalendar(tester);

    expect(find.text('Calendar'), findsOneWidget);
    expect(find.text('Monatliche Übersicht'), findsOneWidget);
    expect(find.text('Einnahmen'), findsAtLeastNWidgets(1));
    expect(find.text('Ausgaben'), findsAtLeastNWidgets(1));
    expect(find.byType(PageView), findsOneWidget);
  });

  testWidgets('shows pie chart and category list and toggles outflow view', (tester) async {
    await pumpCalendar(tester);

    expect(find.byType(PieChart), findsOneWidget);
    expect(find.text('Salary'), findsOneWidget);

    await tester.tap(find.text('Ausgaben').first);
    await tester.pumpAndSettle();

    expect(find.text('Rent'), findsOneWidget);
  });
}
