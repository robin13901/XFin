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
import 'package:xfin/screens/assets_screen.dart';
import 'package:xfin/widgets/asset_form.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late BaseCurrencyProvider currencyProvider;

  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<AppLocalizations> pumpWidget(WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<DatabaseProvider>.value(value: DatabaseProvider.instance),
          ChangeNotifierProvider<BaseCurrencyProvider>.value(value: currencyProvider),
        ],
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [Locale('en'), Locale('de')],
          home: AssetsScreen(),
        ),
      ),
    );
    return AppLocalizations.of(tester.element(find.byType(AssetsScreen)))!;
  }

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    DatabaseProvider.instance.initialize(db);
    currencyProvider = BaseCurrencyProvider();
    await currencyProvider.initialize(const Locale('en'));
    await db.into(db.assets).insert(AssetsCompanion.insert(
          name: 'EUR',
          type: AssetTypes.fiat,
          tickerSymbol: 'EUR',
        ));
    await db.into(db.assets).insert(const AssetsCompanion.insert(
          name: 'BTC',
          type: AssetTypes.crypto,
          tickerSymbol: 'BTC',
          value: Value(500),
          shares: Value(1),
          netCostBasis: Value(500),
          brokerCostBasis: Value(500),
        ));
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets('defaults to assets tab and opens add form via right FAB', (tester) => tester.runAsync(() async {
        await pumpWidget(tester);
        await tester.pumpAndSettle();

        expect(find.text('BTC'), findsOneWidget);
        expect(find.byKey(const Key('fab')), findsOneWidget);

        await tester.tap(find.byKey(const Key('fab')));
        await tester.pumpAndSettle();

        expect(find.byType(AssetForm), findsOneWidget);
      }));

  testWidgets('switching to analysis hides FAB and supports allocation drilldown', (tester) => tester.runAsync(() async {
        await pumpWidget(tester);
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('assets_nav_analysis')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('fab')), findsNothing);
        expect(find.text('CRYPTO'), findsOneWidget);

        await tester.tap(find.text('CRYPTO').first);
        await tester.pumpAndSettle();

        expect(find.text('CRYPTO Assets'), findsOneWidget);
        expect(find.text('BTC'), findsOneWidget);
      }));

  testWidgets('long press protected asset shows cannot-delete dialog', (tester) => tester.runAsync(() async {
        final l10n = await pumpWidget(tester);
        await tester.pumpAndSettle();

        final center = tester.getCenter(find.text('EUR'));
        final gesture = await tester.startGesture(center);
        await tester.pump();
        await Future.delayed(kLongPressTimeout);
        await gesture.up();
        await tester.pumpAndSettle();

        expect(find.text(l10n.cannotDeleteAsset), findsOneWidget);
        expect(find.text(l10n.assetHasReferences), findsOneWidget);
      }));
}
