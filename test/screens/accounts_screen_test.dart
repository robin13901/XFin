import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:xfin/database/app_database.dart';
import 'package:xfin/database/daos/accounts_dao.dart';
import 'package:xfin/database/tables.dart';
import 'package:xfin/l10n/app_localizations.dart';
import 'package:xfin/screens/accounts_screen.dart';
import 'package:xfin/widgets/account_form.dart';

class FakeAppDatabase extends Fake implements AppDatabase {
  FakeAppDatabase({required this.accountsDao});

  @override
  final AccountsDao accountsDao;
}

class FakeAccountsDao extends Fake implements AccountsDao {
  final StreamController<List<Account>> _allAccountsController =
      StreamController.broadcast();
  final StreamController<List<Account>> _archivedAccountsController =
      StreamController.broadcast();

  bool _hasBookings = false;

  void setHasBookings(bool value) {
    _hasBookings = value;
  }

  void emitAllAccounts(List<Account> accounts) =>
      _allAccountsController.add(accounts);
  void emitArchivedAccounts(List<Account> accounts) =>
      _archivedAccountsController.add(accounts);

  @override
  Stream<List<Account>> watchAllAccounts() => _allAccountsController.stream;

  @override
  Stream<List<Account>> watchArchivedAccounts() =>
      _archivedAccountsController.stream;

  @override
  Future<int> addAccount(AccountsCompanion account) async => 1;

  @override
  Future<int> deleteAccount(int id) async => 1;

  @override
  Future<bool> hasBookings(int accountId) async => _hasBookings;

  @override
  Future<bool> hasGoals(int accountId) async => false;

  @override
  Future<bool> hasPeriodicBookings(int accountId) async => false;

  @override
  Future<bool> hasPeriodicTransfers(int accountId) async => false;

  @override
  Future<bool> hasTrades(int accountId) async => false;

  @override
  Future<bool> hasTransfers(int accountId) async => false;

  @override
  Future<int> setArchived(int id, bool isArchived) async => 1;
}

void main() {
  group('AccountsScreen', () {
    late AppDatabase mockDb;
    late FakeAccountsDao fakeAccountsDao;

    const account = Account(
      id: 1,
      name: 'Test Account',
      balance: 1000,
      initialBalance: 1000,
      type: AccountTypes.cash,
      isArchived: false,
    );

    const archivedAccount = Account(
      id: 2,
      name: 'Archived Account',
      balance: 500,
      initialBalance: 500,
      type: AccountTypes.cash,
      isArchived: true,
    );

    setUp(() {
      fakeAccountsDao = FakeAccountsDao();
      mockDb = FakeAppDatabase(accountsDao: fakeAccountsDao);
    });

    Future<AppLocalizations> setupWidget(WidgetTester tester) async {
      await tester.pumpWidget(
        Provider<AppDatabase>.value(
          value: mockDb,
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: AccountsScreen(),
          ),
        ),
      );
      return AppLocalizations.of(tester.element(find.byType(AccountsScreen)))!;
    }

    testWidgets('should display a loading indicator when waiting for data',
        (WidgetTester tester) async {
      await setupWidget(tester);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should display active accounts', (WidgetTester tester) async {
      await setupWidget(tester);

      fakeAccountsDao.emitAllAccounts([account]);
      fakeAccountsDao.emitArchivedAccounts([]);

      await tester.pumpAndSettle();

      expect(find.text('Test Account'), findsOneWidget);
      expect(find.textContaining('1.000,00'), findsOneWidget);
    });

    testWidgets(
        'should show archive dialog for cash account with references on long press',
        (WidgetTester tester) async {
      final l10n = await setupWidget(tester);
      fakeAccountsDao.setHasBookings(true);

      fakeAccountsDao.emitAllAccounts([account]);
      fakeAccountsDao.emitArchivedAccounts([]);

      await tester.pumpAndSettle();

      await tester.longPress(find.text('Test Account'));
      await tester.pumpAndSettle();

      expect(find.text(l10n.cannotDeleteAccount), findsOneWidget);
      expect(find.text(l10n.accountHasReferencesArchiveInstead), findsOneWidget);

      await tester.tap(find.text(l10n.archive));
      await tester.pumpAndSettle();
    });

    testWidgets(
        'should show delete dialog for account without references on long press',
        (WidgetTester tester) async {
      final l10n = await setupWidget(tester);
      await setupWidget(tester);

      fakeAccountsDao.emitAllAccounts([account]);
      fakeAccountsDao.emitArchivedAccounts([]);

      await tester.pumpAndSettle();

      await tester.longPress(find.text('Test Account'));
      await tester.pumpAndSettle();

      expect(find.text(l10n.deleteAccount), findsOneWidget);
      expect(find.text(l10n.confirmDeleteAccount), findsOneWidget);

      await tester.tap(find.text(l10n.confirm));
      await tester.pumpAndSettle();
    });

    testWidgets('should show unarchive dialog on archived account tap',
        (WidgetTester tester) async {
      final l10n = await setupWidget(tester);

      fakeAccountsDao.emitAllAccounts([]);
      fakeAccountsDao.emitArchivedAccounts([archivedAccount]);

      await tester.pumpAndSettle();

      await tester.tap(find.byType(ExpansionTile));
      await tester.pumpAndSettle();

      expect(find.text('Archived Account'), findsOneWidget);

      await tester.tap(find.text('Archived Account'));
      await tester.pumpAndSettle();

      expect(find.text(l10n.unarchiveAccount), findsOneWidget);
      expect(find.text(l10n.confirmUnarchiveAccount), findsOneWidget);

      await tester.tap(find.text(l10n.confirm));
      await tester.pumpAndSettle();
    });

    testWidgets('should display message when no active accounts exist',
        (WidgetTester tester) async {
      final l10n = await setupWidget(tester);

      fakeAccountsDao.emitAllAccounts([]);
      fakeAccountsDao.emitArchivedAccounts([]);

      await tester.pumpAndSettle();

      expect(find.text(l10n.noActiveAccounts), findsOneWidget);
    });

    testWidgets('should open account form when FAB is tapped',
        (WidgetTester tester) async {
      await setupWidget(tester);

      fakeAccountsDao.emitAllAccounts([]);
      fakeAccountsDao.emitArchivedAccounts([]);

      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.byType(AccountForm), findsOneWidget);
    });
  });
}
