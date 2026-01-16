import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/gestures.dart';
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
import 'package:xfin/screens/transfers_screen.dart';
import 'package:xfin/widgets/transfer_form.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late BaseCurrencyProvider currencyProvider;
  late AppLocalizations l10n;

  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    DatabaseProvider.instance.initialize(db);
    currencyProvider = BaseCurrencyProvider();

    const locale = Locale('en');
    l10n = await AppLocalizations.delegate.load(locale);

    await currencyProvider.initialize(locale);

    // Insert base currency asset (id=1)
    await db.into(db.assets).insert(AssetsCompanion.insert(
      name: 'EUR',
      type: AssetTypes.fiat,
      tickerSymbol: 'EUR',
    ));
  });

  tearDown(() async {
    await db.close();
  });

  Future<AppLocalizations> pumpTransfersScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<DatabaseProvider>.value(value: DatabaseProvider.instance),
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
          supportedLocales: [Locale('en'), Locale('de')],
          home: TransfersScreen(),
        ),
      ),
    );

    // Return the localization instance so tests can access localized strings
    return AppLocalizations.of(tester.element(find.byType(TransfersScreen)))!;
  }

  testWidgets(
      'shows loading indicator then empty message when no transfers',
          (tester) => tester.runAsync(() async {
        final l10n = await pumpTransfersScreen(tester);

        // Initially StreamBuilder is waiting -> CircularProgressIndicator
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        await tester.pumpAndSettle();

        expect(find.text(l10n.noTransfersYet), findsOneWidget);
        expect(find.byType(ListView), findsNothing);

        await tester.pumpWidget(Container());
      }));

  group('with transfers', () {
    late int senderId;
    late int receiverId;

    setUp(() async {
      // Insert two accounts
      senderId = await db.accountsDao.insert(AccountsCompanion.insert(
        name: 'Sender',
        type: AccountTypes.cash,
        balance: const Value(100),
      ));
      receiverId = await db.accountsDao.insert(AccountsCompanion.insert(
        name: 'Receiver',
        type: AccountTypes.cash,
        balance: const Value(50),
      ));

      // Insert one transfer
      await db.transfersDao.createTransfer(TransfersCompanion.insert(
        sendingAccountId: senderId,
        receivingAccountId: receiverId,
        assetId: const Value(1),
        shares: 10,
        value: 10.0,
        date: 20250101,
      ), l10n);
    });

    testWidgets('displays transfer in list', (tester) => tester.runAsync(() async {
      await pumpTransfersScreen(tester);
      await tester.pumpAndSettle();

      expect(find.text('Sender → Receiver'), findsOneWidget);
      expect(find.text('EUR'), findsOneWidget);
      expect(find.textContaining('€'), findsOneWidget);

      await tester.pumpWidget(Container());
    }));

    testWidgets('tapping FAB opens TransferForm modal',
            (tester) => tester.runAsync(() async {
          await pumpTransfersScreen(tester);
          await tester.pumpAndSettle();

          final fabFinder = find.byIcon(Icons.add);
          expect(fabFinder, findsOneWidget);

          await tester.tap(fabFinder);
          await tester.pumpAndSettle();

          expect(find.byType(TransferForm), findsOneWidget);

          await tester.pumpWidget(Container());
        }));

    testWidgets('long-press delete transfer shows dialog and deletes it',
            (tester) => tester.runAsync(() async {
          final l10n = await pumpTransfersScreen(tester);
          await tester.pumpAndSettle();

          // Long press the transfer list tile
          final center = tester.getCenter(find.text('Sender → Receiver'));
          TestGesture gesture = await tester.startGesture(center);
          await tester.pump();
          await Future.delayed(kLongPressTimeout);
          await gesture.up();
          await tester.pumpAndSettle();

          // Confirm deletion dialog
          expect(find.text(l10n.deleteTransfer), findsOneWidget);
          await tester.tap(find.text(l10n.delete));
          await tester.pumpAndSettle();

          // Transfer should be removed
          expect((await db.select(db.transfers).get()).isEmpty, isTrue);

          await tester.pumpWidget(Container());
        }));
  });
}
