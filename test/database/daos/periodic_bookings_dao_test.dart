
import 'dart:ui';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:xfin/database/app_database.dart';
import 'package:xfin/database/daos/periodic_bookings_dao.dart';
import 'package:xfin/database/tables.dart';
import 'package:xfin/l10n/app_localizations.dart';
import 'package:xfin/utils/format.dart';
import 'package:xfin/utils/global_constants.dart';

void main() {
  late AppDatabase db;
  late PeriodicBookingsDao periodicBookingsDao;
  late AppLocalizations l10n;
  late int accountId;
  late int assetId;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});

    const locale = Locale('en');
    l10n = await AppLocalizations.delegate.load(locale);

    db = AppDatabase(NativeDatabase.memory());
    periodicBookingsDao = db.periodicBookingsDao;

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

  group('PeriodicBookingsDao CRUD', () {
    test('insertPeriodicBooking creates a new periodic booking', () async {
      final now = DateTime.now();
      final pbCompanion = PeriodicBookingsCompanion.insert(
        nextExecutionDate: dateTimeToInt(now),
        assetId: Value(assetId),
        accountId: accountId,
        shares: 100.0,
        value: 100.0,
        category: 'Salary',
        cycle: const Value(Cycles.monthly),
      );

      final id = await periodicBookingsDao.insertPeriodicBooking(pbCompanion);
      expect(id, greaterThan(0));

      final all = await periodicBookingsDao.getAll();
      expect(all.length, 1);
      expect(all.first.category, 'Salary');
    });

    test('updatePeriodicBooking updates an existing periodic booking', () async {
      final now = DateTime.now();
      final initialPb = PeriodicBookingsCompanion.insert(
        nextExecutionDate: dateTimeToInt(now),
        assetId: Value(assetId),
        accountId: accountId,
        shares: 100.0,
        value: 100.0,
        category: 'Salary',
        cycle: const Value(Cycles.monthly),
      );
      final id = await periodicBookingsDao.insertPeriodicBooking(initialPb);

      final updatedPb = PeriodicBookingsCompanion(
        id: Value(id),
        nextExecutionDate: Value(dateTimeToInt(now.add(const Duration(days: 1)))),
        assetId: Value(assetId),
        accountId: Value(accountId),
        shares: const Value(150.0),
        value: const Value(150.0),
        category: const Value('Bonus'),
        cycle: const Value(Cycles.weekly),
      );

      await periodicBookingsDao.updatePeriodicBooking(updatedPb);

      final all = await periodicBookingsDao.getAll();
      expect(all.length, 1);
      expect(all.first.id, id);
      expect(all.first.category, 'Bonus');
      expect(all.first.shares, 150.0);
      expect(all.first.cycle, Cycles.weekly);
    });

    test('deletePeriodicBooking removes a periodic booking', () async {
      final now = DateTime.now();
      final pbCompanion = PeriodicBookingsCompanion.insert(
        nextExecutionDate: dateTimeToInt(now),
        assetId: Value(assetId),
        accountId: accountId,
        shares: 100.0,
        value: 100.0,
        category: 'Salary',
        cycle: const Value(Cycles.monthly),
      );
      final id = await periodicBookingsDao.insertPeriodicBooking(pbCompanion);

      await periodicBookingsDao.deletePeriodicBooking(id);

      final all = await periodicBookingsDao.getAll();
      expect(all, isEmpty);
    });

    test('getAll returns all periodic bookings', () async {
      final now = DateTime.now();
      await periodicBookingsDao.insertPeriodicBooking(PeriodicBookingsCompanion.insert(
        nextExecutionDate: dateTimeToInt(now),
        assetId: Value(assetId),
        accountId: accountId,
        shares: 100.0,
        value: 100.0,
        category: 'PB1',
        cycle: const Value(Cycles.monthly),
      ));
      await periodicBookingsDao.insertPeriodicBooking(PeriodicBookingsCompanion.insert(
        nextExecutionDate: dateTimeToInt(now.add(const Duration(days: 1))),
        assetId: Value(assetId),
        accountId: accountId,
        shares: 50.0,
        value: 50.0,
        category: 'PB2',
        cycle: const Value(Cycles.weekly),
      ));

      final all = await periodicBookingsDao.getAll();
      expect(all.length, 2);
      expect(all.any((pb) => pb.category == 'PB1'), isTrue);
      expect(all.any((pb) => pb.category == 'PB2'), isTrue);
    });
  });

  group('PeriodicBookingsDao watchAll', () {
    test('watchAll emits a list of PeriodicBookingWithAccountAndAsset', () async {
      final now = DateTime.now();
      await db.into(db.accounts).insert(const AccountsCompanion(id: Value(2), name: Value('Another Account'), type: Value(AccountTypes.cash)));
      await db.into(db.assets).insert(const AssetsCompanion(id: Value(2), name: Value('USD'), type: Value(AssetTypes.fiat), tickerSymbol: Value('USD')));

      await periodicBookingsDao.insertPeriodicBooking(PeriodicBookingsCompanion.insert(
        nextExecutionDate: dateTimeToInt(now),
        assetId: Value(assetId),
        accountId: accountId,
        shares: 100.0,
        value: 100.0,
        category: 'PB1',
        cycle: const Value(Cycles.monthly),
      ));
      await periodicBookingsDao.insertPeriodicBooking(PeriodicBookingsCompanion.insert(
        nextExecutionDate: dateTimeToInt(now.add(const Duration(days: 1))),
        assetId: const Value(2),
        accountId: 2,
        shares: 50.0,
        value: 50.0,
        category: 'PB2',
        cycle: const Value(Cycles.weekly),
      ));

      expect(periodicBookingsDao.watchAll(), emits(
        containsAllInOrder([
          isA<PeriodicBookingWithAccountAndAsset>()
              .having((p) => p.periodicBooking.category, 'category', 'PB2')
              .having((p) => p.account.name, 'account name', 'Another Account')
              .having((p) => p.asset.tickerSymbol, 'asset ticker', 'USD'),
          isA<PeriodicBookingWithAccountAndAsset>()
              .having((p) => p.periodicBooking.category, 'category', 'PB1')
              .having((p) => p.account.name, 'account name', 'Test Account')
              .having((p) => p.asset.tickerSymbol, 'asset ticker', 'EUR'),
        ]),
      ));
    });

    test('watchAll filters out archived accounts or assets', () async {
      // Archived account
      final archivedAccountId = await db.into(db.accounts).insert(
            const AccountsCompanion(
              name: Value('Archived Account'),
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

      // PB with normal account/asset
      await periodicBookingsDao.insertPeriodicBooking(PeriodicBookingsCompanion.insert(
        nextExecutionDate: dateTimeToInt(DateTime.now()),
        assetId: Value(assetId),
        accountId: accountId,
        shares: 10.0,
        value: 10.0,
        category: 'Normal PB',
        cycle: const Value(Cycles.monthly),
      ));
      // PB with archived account
      await periodicBookingsDao.insertPeriodicBooking(PeriodicBookingsCompanion.insert(
        nextExecutionDate: dateTimeToInt(DateTime.now()),
        assetId: Value(assetId),
        accountId: archivedAccountId,
        shares: 20.0,
        value: 20.0,
        category: 'Archived Account PB',
        cycle: const Value(Cycles.monthly),
      ));
      // PB with archived asset
      await periodicBookingsDao.insertPeriodicBooking(PeriodicBookingsCompanion.insert(
        nextExecutionDate: dateTimeToInt(DateTime.now()),
        assetId: Value(archivedAssetId),
        accountId: accountId,
        shares: 30.0,
        value: 30.0,
        category: 'Archived Asset PB',
        cycle: const Value(Cycles.monthly),
      ));

      final stream = periodicBookingsDao.watchAll();
      final result = await stream!.first;

      expect(result.length, 1);
      expect(result.first.periodicBooking.category, 'Normal PB');
    });
  });

  group('PeriodicBookingsDao executePending', () {
    test('executes pending periodic bookings and creates new bookings', () async {
      final pastDate = DateTime.now().subtract(const Duration(days: 5));
      await periodicBookingsDao.insertPeriodicBooking(PeriodicBookingsCompanion.insert(
        nextExecutionDate: dateTimeToInt(pastDate),
        assetId: Value(assetId),
        accountId: accountId,
        shares: 10.0,
        value: 10.0,
        category: 'Daily Income',
        cycle: const Value(Cycles.daily),
      ));

      final executedCount = await periodicBookingsDao.executePending(l10n);
      expect(executedCount, greaterThan(0));

      final newBookings = await db.bookingsDao.getAllBookings();
      expect(newBookings.length, greaterThan(0));
      expect(newBookings.first.category, 'Daily Income');

      final updatedPb = (await periodicBookingsDao.getAll()).first;
      final expectedNextExecDate = dateTimeToInt(pastDate.add(Duration(days: executedCount)));
      expect(updatedPb.nextExecutionDate, expectedNextExecDate);
    });

    test('updates nextExecutionDate correctly for various cycles', () async {
      final now = DateTime.now();
      final pbs = [
        // Daily
        PeriodicBookingsCompanion.insert(
          nextExecutionDate: dateTimeToInt(now.subtract(const Duration(days: 2))),
          assetId: Value(assetId),
          accountId: accountId,
          shares: 1, value: 1, category: 'D', cycle: const Value(Cycles.daily),
        ),
        // Weekly
        PeriodicBookingsCompanion.insert(
          nextExecutionDate: dateTimeToInt(now.subtract(const Duration(days: 10))),
          assetId: Value(assetId),
          accountId: accountId,
          shares: 1, value: 1, category: 'W', cycle: const Value(Cycles.weekly),
        ),
        // Monthly
        PeriodicBookingsCompanion.insert(
          nextExecutionDate: dateTimeToInt(now.subtract(const Duration(days: 35))),
          assetId: Value(assetId),
          accountId: accountId,
          shares: 1, value: 1, category: 'M', cycle: const Value(Cycles.monthly),
        ),
        // Quarterly
        PeriodicBookingsCompanion.insert(
          nextExecutionDate: dateTimeToInt(now.subtract(const Duration(days: 100))),
          assetId: Value(assetId),
          accountId: accountId,
          shares: 1, value: 1, category: 'Q', cycle: const Value(Cycles.quarterly),
        ),
        // Yearly
        PeriodicBookingsCompanion.insert(
          nextExecutionDate: dateTimeToInt(now.subtract(const Duration(days: 400))),
          assetId: Value(assetId),
          accountId: accountId,
          shares: 1, value: 1, category: 'Y', cycle: const Value(Cycles.yearly),
        ),
      ];

      for (final pb in pbs) {
        await periodicBookingsDao.insertPeriodicBooking(pb);
      }

      await periodicBookingsDao.executePending(l10n);
      final updatedPbs = await periodicBookingsDao.getAll();

      // Check daily
      final dailyPb = updatedPbs.firstWhere((pb) => pb.category == 'D');
      final expectedDailyDate = intToDateTime(pbs[0].nextExecutionDate.value)!.add(const Duration(days: 3)); // 2 executions
      expect(dailyPb.nextExecutionDate, dateTimeToInt(expectedDailyDate));

      // Check weekly
      final weeklyPb = updatedPbs.firstWhere((pb) => pb.category == 'W');
      final expectedWeeklyDate = intToDateTime(pbs[1].nextExecutionDate.value)!.add(const Duration(days: 14)); // 2 executions
      expect(weeklyPb.nextExecutionDate, dateTimeToInt(expectedWeeklyDate));

      // Check monthly
      final monthlyPb = updatedPbs.firstWhere((pb) => pb.category == 'M');
      final expectedMonthlyDate = addMonths(intToDateTime(pbs[2].nextExecutionDate.value)!, 2); // 2 executions
      expect(monthlyPb.nextExecutionDate, dateTimeToInt(expectedMonthlyDate));

      // Check quarterly
      final quarterlyPb = updatedPbs.firstWhere((pb) => pb.category == 'Q');
      final expectedQuarterlyDate = addMonths(intToDateTime(pbs[3].nextExecutionDate.value)!, 2 * 3); // 2 executions
      expect(quarterlyPb.nextExecutionDate, dateTimeToInt(expectedQuarterlyDate));

      // Check yearly
      final yearlyPb = updatedPbs.firstWhere((pb) => pb.category == 'Y');
      final expectedYearlyDate = addMonths(intToDateTime(pbs[4].nextExecutionDate.value)!, 2 * 12); // 2 executions
      expect(yearlyPb.nextExecutionDate, dateTimeToInt(expectedYearlyDate));
    });

    test('does not execute future periodic bookings', () async {
      final futureDate = DateTime.now().add(const Duration(days: 5));
      await periodicBookingsDao.insertPeriodicBooking(PeriodicBookingsCompanion.insert(
        nextExecutionDate: dateTimeToInt(futureDate),
        assetId: Value(assetId),
        accountId: accountId,
        shares: 10.0,
        value: 10.0,
        category: 'Future PB',
        cycle: const Value(Cycles.daily),
      ));

      final executedCount = await periodicBookingsDao.executePending(l10n);
      expect(executedCount, 0);

      final newBookings = await db.bookingsDao.getAllBookings();
      expect(newBookings, isEmpty);

      final updatedPb = (await periodicBookingsDao.getAll()).first;
      expect(updatedPb.nextExecutionDate, dateTimeToInt(futureDate));
    });

    test('handles no periodic bookings gracefully', () async {
      final executedCount = await periodicBookingsDao.executePending(l10n);
      expect(executedCount, 0);
      final newBookings = await db.bookingsDao.getAllBookings();
      expect(newBookings, isEmpty);
    });
  });
}
