import 'dart:ui';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:xfin/database/app_database.dart';
import 'package:xfin/database/daos/periodic_transfers_dao.dart';
import 'package:xfin/database/tables.dart';
import 'package:xfin/l10n/app_localizations.dart';
import 'package:xfin/utils/format.dart';
import 'package:xfin/utils/global_constants.dart';

void main() {
  late AppDatabase db;
  late PeriodicTransfersDao periodicTransfersDao;
  late AppLocalizations l10n;
  late int accountId;
  late int assetId;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});

    const locale = Locale('en');
    l10n = await AppLocalizations.delegate.load(locale);

    db = AppDatabase(NativeDatabase.memory());
    periodicTransfersDao = db.periodicTransfersDao;

    // Insert a test account
    accountId = await db.into(db.accounts).insert(
          const AccountsCompanion(
            name: Value('Test Account'),
            type: Value(AccountTypes.cash),
          ),
        );

    // Insert a test asset (base currency)
    assetId = await db.into(db.assets).insert(
          const AssetsCompanion(
            name: Value('EUR'),
            type: Value(AssetTypes.fiat),
            tickerSymbol: Value('EUR'),
          ),
        );
  });

  tearDown(() async {
    await db.close();
  });

  group('PeriodicTransfersDao CRUD', () {
    test('insertPeriodicTransfer creates a new periodic transfer', () async {
      final now = DateTime.now();
      final ptCompanion = PeriodicTransfersCompanion.insert(
        nextExecutionDate: dateTimeToInt(now),
        assetId: Value(assetId),
        sendingAccountId: accountId,
        receivingAccountId: accountId,
        shares: 100.0,
        value: 100.0,
        notes: const Value('Salary transfer'),
        cycle: const Value(Cycles.monthly),
      );

      final id = await periodicTransfersDao.insertPeriodicTransfer(ptCompanion);
      expect(id, greaterThan(0));

      final all = await periodicTransfersDao.getAll();
      expect(all.length, 1);
      expect(all.first.notes, 'Salary transfer');
    });

    test('updatePeriodicTransfer updates an existing periodic transfer',
        () async {
      final now = DateTime.now();
      final initialPt = PeriodicTransfersCompanion.insert(
        nextExecutionDate: dateTimeToInt(now),
        assetId: Value(assetId),
        sendingAccountId: accountId,
        receivingAccountId: accountId,
        shares: 100.0,
        value: 100.0,
        notes: const Value('Initial'),
        cycle: const Value(Cycles.monthly),
      );
      final id = await periodicTransfersDao.insertPeriodicTransfer(initialPt);

      // create a second account to receive the updated transfer
      final otherAccountId = await db.into(db.accounts).insert(
            const AccountsCompanion(
              name: Value('Other Account'),
              type: Value(AccountTypes.cash),
            ),
          );

      final updatedPt = PeriodicTransfersCompanion(
        id: Value(id),
        nextExecutionDate:
            Value(dateTimeToInt(now.add(const Duration(days: 1)))),
        assetId: Value(assetId),
        sendingAccountId: Value(accountId),
        receivingAccountId: Value(otherAccountId),
        shares: const Value(150.0),
        value: const Value(150.0),
        notes: const Value('Updated Transfer'),
        cycle: const Value(Cycles.weekly),
      );

      await periodicTransfersDao.updatePeriodicTransfer(updatedPt);

      final all = await periodicTransfersDao.getAll();
      expect(all.length, 1);
      expect(all.first.id, id);
      expect(all.first.notes, 'Updated Transfer');
      expect(all.first.shares, 150.0);
      expect(all.first.cycle, Cycles.weekly);
      expect(all.first.receivingAccountId, otherAccountId);
    });

    test('deletePeriodicTransfer removes a periodic transfer', () async {
      final now = DateTime.now();
      final ptCompanion = PeriodicTransfersCompanion.insert(
        nextExecutionDate: dateTimeToInt(now),
        assetId: Value(assetId),
        sendingAccountId: accountId,
        receivingAccountId: accountId,
        shares: 100.0,
        value: 100.0,
        notes: const Value('To delete'),
        cycle: const Value(Cycles.monthly),
      );
      final id = await periodicTransfersDao.insertPeriodicTransfer(ptCompanion);

      await periodicTransfersDao.deletePeriodicTransfer(id);

      final all = await periodicTransfersDao.getAll();
      expect(all, isEmpty);
    });

    test('getAll returns all periodic transfers', () async {
      final now = DateTime.now();
      await periodicTransfersDao
          .insertPeriodicTransfer(PeriodicTransfersCompanion.insert(
        nextExecutionDate: dateTimeToInt(now),
        assetId: Value(assetId),
        sendingAccountId: accountId,
        receivingAccountId: accountId,
        shares: 100.0,
        value: 100.0,
        notes: const Value('PT1'),
        cycle: const Value(Cycles.monthly),
      ));
      await periodicTransfersDao
          .insertPeriodicTransfer(PeriodicTransfersCompanion.insert(
        nextExecutionDate: dateTimeToInt(now.add(const Duration(days: 1))),
        assetId: Value(assetId),
        sendingAccountId: accountId,
        receivingAccountId: accountId,
        shares: 50.0,
        value: 50.0,
        notes: const Value('PT2'),
        cycle: const Value(Cycles.weekly),
      ));

      final all = await periodicTransfersDao.getAll();
      expect(all.length, 2);
      expect(all.any((pt) => pt.notes == 'PT1'), isTrue);
      expect(all.any((pt) => pt.notes == 'PT2'), isTrue);
    });
  });

  group('PeriodicTransfersDao watchAll', () {
    test('watchAll emits a list of PeriodicTransferWithAccountAndAsset',
        () async {
      final now = DateTime.now();
      // create another account and asset to use as sender/receiver and asset
      final otherAccountId = await db.into(db.accounts).insert(
            const AccountsCompanion(
                name: Value('Another Account'), type: Value(AccountTypes.cash)),
          );
      final otherAssetId = await db.into(db.assets).insert(
            const AssetsCompanion(
                name: Value('USD'),
                type: Value(AssetTypes.fiat),
                tickerSymbol: Value('USD')),
          );

      // PT with now (will be ordered later)
      await periodicTransfersDao
          .insertPeriodicTransfer(PeriodicTransfersCompanion.insert(
        nextExecutionDate: dateTimeToInt(now),
        assetId: Value(assetId),
        sendingAccountId: accountId,
        receivingAccountId: accountId,
        shares: 100.0,
        value: 100.0,
        notes: const Value('PT1'),
        cycle: const Value(Cycles.monthly),
      ));

      // PT with now + 1 day (should come first in desc order)
      await periodicTransfersDao
          .insertPeriodicTransfer(PeriodicTransfersCompanion.insert(
        nextExecutionDate: dateTimeToInt(now.add(const Duration(days: 1))),
        assetId: Value(otherAssetId),
        sendingAccountId: otherAccountId,
        receivingAccountId: otherAccountId,
        shares: 50.0,
        value: 50.0,
        notes: const Value('PT2'),
        cycle: const Value(Cycles.weekly),
      ));

      expect(
          periodicTransfersDao.watchAll(),
          emits(
            containsAllInOrder([
              isA<PeriodicTransferWithAccountAndAsset>()
                  .having((p) => p.periodicTransfer.notes, 'notes', 'PT2')
                  .having((p) => p.fromAccount.name, 'from account name',
                      'Another Account')
                  .having((p) => p.toAccount.name, 'to account name',
                      'Another Account')
                  .having((p) => p.asset.tickerSymbol, 'asset ticker', 'USD'),
              isA<PeriodicTransferWithAccountAndAsset>()
                  .having((p) => p.periodicTransfer.notes, 'notes', 'PT1')
                  .having((p) => p.fromAccount.name, 'from account name',
                      'Test Account')
                  .having((p) => p.toAccount.name, 'to account name',
                      'Test Account')
                  .having((p) => p.asset.tickerSymbol, 'asset ticker', 'EUR'),
            ]),
          ));
    });

    test('watchAll filters out archived accounts or assets', () async {
      // Archived sending account
      final archivedSendingId = await db.into(db.accounts).insert(
            const AccountsCompanion(
              name: Value('Archived Sender'),
              type: Value(AccountTypes.cash),
              isArchived: Value(true),
            ),
          );
      // Archived receiving account
      await db.into(db.accounts).insert(
            const AccountsCompanion(
              name: Value('Archived Receiver'),
              type: Value(AccountTypes.cash),
              isArchived: Value(true),
            ),
          );
      // Archived asset
      final archivedAssetId = await db.into(db.assets).insert(
            const AssetsCompanion(
              name: Value('Archived Asset'),
              type: Value(AssetTypes.stock),
              tickerSymbol: Value('ARC'),
              isArchived: Value(true),
            ),
          );

      // PT with normal accounts/asset
      await periodicTransfersDao
          .insertPeriodicTransfer(PeriodicTransfersCompanion.insert(
        nextExecutionDate: dateTimeToInt(DateTime.now()),
        assetId: Value(assetId),
        sendingAccountId: accountId,
        receivingAccountId: accountId,
        shares: 10.0,
        value: 10.0,
        notes: const Value('Normal PT'),
        cycle: const Value(Cycles.monthly),
      ));
      // PT with archived sending account
      await periodicTransfersDao
          .insertPeriodicTransfer(PeriodicTransfersCompanion.insert(
        nextExecutionDate: dateTimeToInt(DateTime.now()),
        assetId: Value(assetId),
        sendingAccountId: archivedSendingId,
        receivingAccountId: accountId,
        shares: 20.0,
        value: 20.0,
        notes: const Value('Archived Sender PT'),
        cycle: const Value(Cycles.monthly),
      ));
      // PT with archived asset
      await periodicTransfersDao
          .insertPeriodicTransfer(PeriodicTransfersCompanion.insert(
        nextExecutionDate: dateTimeToInt(DateTime.now()),
        assetId: Value(archivedAssetId),
        sendingAccountId: accountId,
        receivingAccountId: accountId,
        shares: 30.0,
        value: 30.0,
        notes: const Value('Archived Asset PT'),
        cycle: const Value(Cycles.monthly),
      ));

      final stream = periodicTransfersDao.watchAll();
      final result = await stream.first;

      expect(result.length, 1);
      expect(result.first.periodicTransfer.notes, 'Normal PT');
    });
  });

  group('PeriodicTransfersDao executePending', () {
    test('executes pending periodic transfers and creates new transfers',
        () async {
      final pastDate = DateTime.now().subtract(const Duration(days: 5));
      await periodicTransfersDao
          .insertPeriodicTransfer(PeriodicTransfersCompanion.insert(
        nextExecutionDate: dateTimeToInt(pastDate),
        assetId: Value(assetId),
        sendingAccountId: accountId,
        receivingAccountId: accountId,
        shares: 10.0,
        value: 10.0,
        notes: const Value('Daily Transfer'),
        cycle: const Value(Cycles.daily),
      ));

      final executedCount = await periodicTransfersDao.executePending(l10n);
      expect(executedCount, greaterThan(0));

      // assume transfersDao exposes a method to get created transfers; try to match booking tests style
      final newTransfers = await db.transfersDao.getAllTransfers();
      expect(newTransfers.length, greaterThan(0));
      expect(newTransfers.first.notes, 'Daily Transfer');

      final updatedPt = (await periodicTransfersDao.getAll()).first;
      final expectedNextExecDate =
          dateTimeToInt(pastDate.add(Duration(days: executedCount)));
      expect(updatedPt.nextExecutionDate, expectedNextExecDate);
    });

    test('updates nextExecutionDate correctly for various cycles', () async {
      final now = DateTime.now();
      final pts = [
        // Daily
        PeriodicTransfersCompanion.insert(
          nextExecutionDate:
              dateTimeToInt(now.subtract(const Duration(days: 2))),
          assetId: Value(assetId),
          sendingAccountId: accountId,
          receivingAccountId: accountId,
          shares: 1,
          value: 1,
          notes: const Value('D'),
          cycle: const Value(Cycles.daily),
        ),
        // Weekly
        PeriodicTransfersCompanion.insert(
          nextExecutionDate:
              dateTimeToInt(now.subtract(const Duration(days: 10))),
          assetId: Value(assetId),
          sendingAccountId: accountId,
          receivingAccountId: accountId,
          shares: 1,
          value: 1,
          notes: const Value('W'),
          cycle: const Value(Cycles.weekly),
        ),
        // Monthly
        PeriodicTransfersCompanion.insert(
          nextExecutionDate:
              dateTimeToInt(now.subtract(const Duration(days: 35))),
          assetId: Value(assetId),
          sendingAccountId: accountId,
          receivingAccountId: accountId,
          shares: 1,
          value: 1,
          notes: const Value('M'),
          cycle: const Value(Cycles.monthly),
        ),
        // Quarterly
        PeriodicTransfersCompanion.insert(
          nextExecutionDate:
              dateTimeToInt(now.subtract(const Duration(days: 100))),
          assetId: Value(assetId),
          sendingAccountId: accountId,
          receivingAccountId: accountId,
          shares: 1,
          value: 1,
          notes: const Value('Q'),
          cycle: const Value(Cycles.quarterly),
        ),
        // Yearly
        PeriodicTransfersCompanion.insert(
          nextExecutionDate:
              dateTimeToInt(now.subtract(const Duration(days: 400))),
          assetId: Value(assetId),
          sendingAccountId: accountId,
          receivingAccountId: accountId,
          shares: 1,
          value: 1,
          notes: const Value('Y'),
          cycle: const Value(Cycles.yearly),
        ),
      ];

      for (final pt in pts) {
        await periodicTransfersDao.insertPeriodicTransfer(pt);
      }

      await periodicTransfersDao.executePending(l10n);
      final updatedPts = await periodicTransfersDao.getAll();

      // Check daily
      final dailyPt = updatedPts.firstWhere((pt) => pt.notes == 'D');
      final expectedDailyDate = intToDateTime(pts[0].nextExecutionDate.value)!
          .add(const Duration(days: 3)); // 2 executions
      expect(dailyPt.nextExecutionDate, dateTimeToInt(expectedDailyDate));

      // Check weekly
      final weeklyPt = updatedPts.firstWhere((pt) => pt.notes == 'W');
      final expectedWeeklyDate = intToDateTime(pts[1].nextExecutionDate.value)!
          .add(const Duration(days: 14)); // 2 executions
      expect(weeklyPt.nextExecutionDate, dateTimeToInt(expectedWeeklyDate));

      // Check monthly
      final monthlyPt = updatedPts.firstWhere((pt) => pt.notes == 'M');
      final expectedMonthlyDate = addMonths(
          intToDateTime(pts[2].nextExecutionDate.value)!, 2); // 2 executions
      expect(monthlyPt.nextExecutionDate, dateTimeToInt(expectedMonthlyDate));

      // Check quarterly
      final quarterlyPt = updatedPts.firstWhere((pt) => pt.notes == 'Q');
      final expectedQuarterlyDate = addMonths(
          intToDateTime(pts[3].nextExecutionDate.value)!,
          2 * 3); // 2 executions
      expect(
          quarterlyPt.nextExecutionDate, dateTimeToInt(expectedQuarterlyDate));

      // Check yearly
      final yearlyPt = updatedPts.firstWhere((pt) => pt.notes == 'Y');
      final expectedYearlyDate = addMonths(
          intToDateTime(pts[4].nextExecutionDate.value)!,
          2 * 12); // 2 executions
      expect(yearlyPt.nextExecutionDate, dateTimeToInt(expectedYearlyDate));
    });

    test('does not execute future periodic transfers', () async {
      final futureDate = DateTime.now().add(const Duration(days: 5));
      await periodicTransfersDao
          .insertPeriodicTransfer(PeriodicTransfersCompanion.insert(
        nextExecutionDate: dateTimeToInt(futureDate),
        assetId: Value(assetId),
        sendingAccountId: accountId,
        receivingAccountId: accountId,
        shares: 10.0,
        value: 10.0,
        notes: const Value('Future PT'),
        cycle: const Value(Cycles.daily),
      ));

      final executedCount = await periodicTransfersDao.executePending(l10n);
      expect(executedCount, 0);

      final newTransfers = await db.transfersDao.getAllTransfers();
      expect(newTransfers, isEmpty);

      final updatedPt = (await periodicTransfersDao.getAll()).first;
      expect(updatedPt.nextExecutionDate, dateTimeToInt(futureDate));
    });

    test('handles no periodic transfers gracefully', () async {
      final executedCount = await periodicTransfersDao.executePending(l10n);
      expect(executedCount, 0);
      final newTransfers = await db.transfersDao.getAllTransfers();
      expect(newTransfers, isEmpty);
    });
  });
}
