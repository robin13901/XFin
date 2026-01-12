import 'dart:ui';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:xfin/database/app_database.dart';
import 'package:xfin/database/daos/bookings_dao.dart';
import 'package:xfin/database/tables.dart';
import 'package:xfin/l10n/app_localizations.dart';

void main() {
  late AppDatabase db;
  late BookingsDao bookingsDao;
  late int baseCurrencyAssetId;
  late int accountId;
  late Asset assetOne;
  late Account portfolio1;
  late AppLocalizations l10n;

  setUp(() async {
    // Make sure prefs are clean (some DAOs/tests rely on SharedPreferences)
    SharedPreferences.setMockInitialValues({});

    const locale = Locale('en');
    l10n = await AppLocalizations.delegate.load(locale);

    db = AppDatabase(NativeDatabase.memory());
    bookingsDao = db.bookingsDao;

    // Insert base currency asset
    baseCurrencyAssetId =
        await db.into(db.assets).insert(AssetsCompanion.insert(
              name: 'EUR',
              type: AssetTypes.fiat,
              tickerSymbol: 'EUR',
            ));

    assetOne = const Asset(
        id: 2,
        name: 'Asset One',
        type: AssetTypes.stock,
        tickerSymbol: 'ONE',
        currencySymbol: '',
        value: 0,
        shares: 0,
        netCostBasis: 0,
        brokerCostBasis: 0,
        buyFeeTotal: 0,
        isArchived: false);

    portfolio1 = const Account(
        id: 2,
        name: 'Portfolio Account',
        balance: 0,
        initialBalance: 0,
        type: AccountTypes.portfolio,
        isArchived: false);

    accountId = await db.into(db.accounts).insert(AccountsCompanion.insert(
          name: 'Test Account',
          type: AccountTypes.cash,
        ));

    await db.into(db.assetsOnAccounts).insert(AssetsOnAccountsCompanion.insert(
        accountId: accountId, assetId: baseCurrencyAssetId));

    await db.into(db.assets).insert(assetOne.toCompanion(false));
    await db.into(db.accounts).insert(portfolio1.toCompanion(false));
  });

  tearDown(() async {
    await db.close();
  });

  group('BookingsDao basic CRUD and streams', () {
    test('createBooking persists booking and updates account balance',
        () async {
      final booking = BookingsCompanion.insert(
        date: 20250101,
        shares: 50.0,
        category: 'Salary',
        accountId: accountId,
        assetId: Value(baseCurrencyAssetId),
        value: 50.0,
      );

      await bookingsDao.createBooking(booking, l10n);

      // Booking should exist in DB
      final all = await bookingsDao.getAllBookings();
      expect(all.length, 1);
      final stored = all.first;
      expect(stored.shares, 50.0);
      expect(stored.accountId, accountId);
      expect(stored.assetId, baseCurrencyAssetId);
      expect(stored.value, 50.0);

      // Account balance should have been incremented by value (+50)
      final acc = await (db.select(db.accounts)
            ..where((t) => t.id.equals(accountId)))
          .getSingle();
      expect(acc.balance, closeTo(50.0, 1e-9));
    });

    test('getBooking returns correct booking; getAllBookings returns list',
        () async {
      final id = await db.into(db.bookings).insert(BookingsCompanion.insert(
            date: 20240101,
            shares: -20.0,
            category: 'Food',
            accountId: accountId,
            assetId: Value(baseCurrencyAssetId),
            value: -20.0,
          ));

      final fetched = await bookingsDao.getBooking(id);
      expect(fetched.id, id);
      expect(fetched.shares, -20.0);

      final all = await bookingsDao.getAllBookings();
      expect(all.any((b) => b.id == id), isTrue);
    });

    test('watchDistinctCategories returns unique categories', () async {
      await db.into(db.bookings).insert(BookingsCompanion.insert(
            date: 20240101,
            shares: 10.0,
            category: 'X',
            accountId: accountId,
            assetId: Value(baseCurrencyAssetId),
            value: 10.0,
          ));
      await db.into(db.bookings).insert(BookingsCompanion.insert(
            date: 20240102,
            shares: 20.0,
            category: 'Y',
            accountId: accountId,
            assetId: Value(baseCurrencyAssetId),
            value: 20.0,
          ));
      await db.into(db.bookings).insert(BookingsCompanion.insert(
            date: 20240103,
            shares: 30.0,
            category: 'X',
            // duplicate category
            accountId: accountId,
            assetId: Value(baseCurrencyAssetId),
            value: 30.0,
          ));

      final categories = await bookingsDao.watchDistinctCategories().first;
      // Should contain X and Y exactly once (ordering is not guaranteed)
      expect(categories.toSet(), equals({'X', 'Y'}));
    });

    test('costBasis correctly calculated in createBooking and updateBooking',
        () async {
      await db.bookingsDao.createBooking(
          BookingsCompanion(
              date: const Value(20250101),
              assetId: Value(assetOne.id),
              accountId: Value(portfolio1.id),
              category: const Value('Test'),
              shares: const Value(0.5),
              costBasis: const Value(100),
              value: const Value(50)),
          l10n);
      await db.bookingsDao.createBooking(
          BookingsCompanion(
              date: const Value(20250102),
              assetId: Value(assetOne.id),
              accountId: Value(portfolio1.id),
              category: const Value('Test'),
              shares: const Value(0.5),
              costBasis: const Value(200),
              value: const Value(100)),
          l10n);

      // Create SUT
      await db.bookingsDao.createBooking(
          BookingsCompanion(
              date: const Value(20250103),
              assetId: Value(assetOne.id),
              accountId: Value(portfolio1.id),
              category: const Value('Test'),
              shares: const Value(-1)),
          l10n);

      // Post-create-checks
      var sut = await db.bookingsDao.getBooking(3);
      expect(sut.shares, closeTo(-1, 1e-9));
      expect(sut.costBasis, closeTo(150, 1e-9));
      expect(sut.value, closeTo(-150, 1e-9));

      // Update SUT
      var updatedBooking = BookingsCompanion(
          id: Value(sut.id),
          date: const Value(20250103),
          assetId: Value(assetOne.id),
          accountId: Value(portfolio1.id),
          category: const Value('Test'),
          shares: const Value(-0.5));
      db.bookingsDao.updateBooking(sut, updatedBooking, l10n);

      // Post-update-checks
      sut = await db.bookingsDao.getBooking(3);
      expect(sut.shares, closeTo(-0.5, 1e-9));
      expect(sut.costBasis, closeTo(100, 1e-9));
      expect(sut.value, closeTo(-50, 1e-9));
    });
  });

  group('BookingsDao - findMergeableBooking', () {
    test('finds mergeable booking when matching (same sign)', () async {
      // existing booking: positive amount
      final existingId =
          await db.into(db.bookings).insert(BookingsCompanion.insert(
                date: 20240202,
                shares: 100.0,
                category: 'Cat',
                accountId: accountId,
                assetId: Value(baseCurrencyAssetId),
                value: 100.0,
              ));

      final candidate = BookingsCompanion.insert(
        date: 20240202,
        shares: 50.0,
        // same sign (positive)
        category: 'Cat',
        accountId: accountId,
        assetId: Value(baseCurrencyAssetId),
        value: 50.0,
        excludeFromAverage: const Value(false),
      );

      final merged = await bookingsDao.findMergeableBooking(candidate);
      expect(merged, isNotNull);
      expect(merged!.id, existingId);
    });

    test('does not merge when sign differs or notes present', () async {
      // existing booking positive
      await db.into(db.bookings).insert(BookingsCompanion.insert(
            date: 20240303,
            shares: 40.0,
            category: 'C2',
            accountId: accountId,
            assetId: Value(baseCurrencyAssetId),
            value: 40.0,
          ));

      // candidate is negative -> should not match
      final candidateNeg = BookingsCompanion.insert(
        date: 20240303,
        shares: -5.0,
        category: 'C2',
        accountId: accountId,
        assetId: Value(baseCurrencyAssetId),
        value: -5.0,
        excludeFromAverage: const Value(false),
      );

      final r1 = await bookingsDao.findMergeableBooking(candidateNeg);
      expect(r1, isNull);

      // candidate with notes (not null) should also not match existing
      final candidateWithNotes = BookingsCompanion(
        date: const Value(20240303),
        shares: const Value(10.0),
        category: const Value('C2'),
        accountId: Value(accountId),
        assetId: Value(baseCurrencyAssetId),
        value: const Value(10.0),
        notes: const Value('some note'),
        excludeFromAverage: const Value(false),
      );
      final r2 = await bookingsDao.findMergeableBooking(candidateWithNotes);
      expect(r2, isNull);
    });
  });

  group('BookingsDao - watchBookingsPage (keyset pagination)', () {
    test('watchBookingsPage returns correct pages and respects keyset cursor',
        () async {
      // Prepare account
      final acc = await db.into(db.accounts).insert(AccountsCompanion.insert(
            name: 'PagerAcc',
            type: AccountTypes.cash,
            isArchived: const Value(false),
          ));

      // Ensure this account has baseCurrency asset on it
      await db
          .into(db.assetsOnAccounts)
          .insert(AssetsOnAccountsCompanion.insert(
            accountId: acc,
            assetId: baseCurrencyAssetId,
          ));

      // Insert bookings with dates/shares to create deterministic order:
      // A: date 20250104 shares 5
      // B: date 20250103 shares 10
      // C: date 20250103 shares 2
      // D: date 20250102 shares 7
      final idA = await db.into(db.bookings).insert(BookingsCompanion.insert(
            date: 20250104,
            shares: 5.0,
            category: 'A',
            accountId: acc,
            assetId: Value(baseCurrencyAssetId),
            value: 5.0,
          ));
      final idB = await db.into(db.bookings).insert(BookingsCompanion.insert(
            date: 20250103,
            shares: 10.0,
            category: 'B',
            accountId: acc,
            assetId: Value(baseCurrencyAssetId),
            value: 10.0,
          ));
      final idC = await db.into(db.bookings).insert(BookingsCompanion.insert(
            date: 20250103,
            shares: 2.0,
            category: 'C',
            accountId: acc,
            assetId: Value(baseCurrencyAssetId),
            value: 2.0,
          ));
      final idD = await db.into(db.bookings).insert(BookingsCompanion.insert(
            date: 20250102,
            shares: 7.0,
            category: 'D',
            accountId: acc,
            assetId: Value(baseCurrencyAssetId),
            value: 7.0,
          ));

      // First page: limit 2 should return [A, B] (ordered by date desc, shares desc)
      final page1 = await bookingsDao.watchBookingsPage(limit: 2).first;
      expect(page1.length, 2);
      expect(page1[0].booking.id, idA);
      expect(page1[1].booking.id, idB);

      // The last cursor from page1 is B (date=20250103, shares=10)
      final lastDate = page1.last.booking.date;
      final lastShares = page1.last.booking.shares;

      expect(lastDate, 20250103);
      expect(lastShares, 10.0);

      // Second page: request with cursor should return [C, D]
      final page2 = await bookingsDao
          .watchBookingsPage(
              limit: 2, lastDate: lastDate, lastValue: lastShares)
          .first;
      expect(page2.length, 2);
      // Because date desc, shares desc, the rows after (B) are C (same date, lower shares) then D (older date)
      expect(page2[0].booking.id, idC);
      expect(page2[1].booking.id, idD);

      // Third page: there should be no more rows (empty list)
      final page3 = await bookingsDao
          .watchBookingsPage(
              limit: 2,
              lastDate: page2.last.booking.date,
              lastValue: page2.last.booking.shares)
          .first;
      expect(page3, isEmpty);
    });
  });

  group('BookingsDao - updateBooking (4 scenarios)', () {
    late int assetOldId, assetNewId;

    setUp(() async {
      assetOldId = await db.assetsDao.insert(AssetsCompanion.insert(
        name: 'Old Asset',
        type: AssetTypes.stock,
        tickerSymbol: 'OLD',
      ));
      assetNewId = await db.assetsDao.insert(AssetsCompanion.insert(
        name: 'New Asset',
        type: AssetTypes.stock,
        tickerSymbol: 'NEW',
      ));
    });

    test('same account & same asset updates booking and account by delta',
        () async {
      await db.bookingsDao.createBooking(
          BookingsCompanion(
            date: const Value(20240101),
            accountId: Value(accountId),
            assetId: Value(baseCurrencyAssetId),
            category: const Value('Test'),
            shares: const Value(10.0),
            costBasis: const Value(1),
          ),
          l10n);

      var booking = await bookingsDao.getBooking(1);
      expect(booking.shares, 10);
      expect(booking.costBasis, 1);
      expect(booking.value, 10);

      var account = await db.accountsDao.getAccount(accountId);
      expect(account.balance, closeTo(10, 1e-9));

      await bookingsDao.updateBooking(booking, BookingsCompanion(
        id: const Value(1),
        date: const Value(20240101),
        accountId: Value(accountId),
        assetId: Value(baseCurrencyAssetId),
        category: const Value('Test'),
        shares: const Value(15.0),
        costBasis: const Value(1),
      ), l10n);

      booking = await bookingsDao.getBooking(1);
      expect(booking.shares, 15);
      expect(booking.costBasis, 1);
      expect(booking.value, 15);

      account = await db.accountsDao.getAccount(accountId);
      expect(account.balance, closeTo(15, 1e-9));
    });

    test(
        'same account & different asset moves asset but account balance adjusted properly',
        () async {
      await db.bookingsDao.createBooking(
          BookingsCompanion(
            date: const Value(20240202),
            accountId: Value(accountId),
            assetId: Value(assetOldId),
            category: const Value('Swap'),
            shares: const Value(5.0),
            costBasis: const Value(1),
          ),
          l10n);

      final originalBooking = await bookingsDao.getBooking(1);
      expect(originalBooking.assetId, assetOldId);
      expect(originalBooking.shares, 5.0);
      expect(originalBooking.costBasis, 1);
      expect(originalBooking.value, 5.0);

      var account = await db.accountsDao.getAccount(accountId);
      expect(account.balance, closeTo(5, 1e-9));

      await bookingsDao.updateBooking(
          originalBooking,
          BookingsCompanion(
            id: Value(originalBooking.id),
            date: const Value(20240202),
            accountId: Value(accountId),
            assetId: Value(assetNewId),
            category: const Value('Swap'),
            shares: const Value(12.0),
            costBasis: const Value(1),
          ),
          l10n);

      final updatedBooking = await bookingsDao.getBooking(originalBooking.id);
      expect(updatedBooking.assetId, assetNewId);
      expect(updatedBooking.shares, 12.0);
      expect(updatedBooking.costBasis, 1);
      expect(updatedBooking.value, 12.0);

      // Account balance should have changed to 12
      account = await db.accountsDao.getAccount(accountId);
      expect(account.balance, closeTo(12, 1e-9));
    });

    test('different accounts & same asset moves amount between accounts',
        () async {
      final accOld = await db.into(db.accounts).insert(AccountsCompanion.insert(
            name: 'From',
            type: AccountTypes.cash,
            balance: const Value(300.0),
          ));
      final accNew = await db.into(db.accounts).insert(AccountsCompanion.insert(
            name: 'To',
            type: AccountTypes.cash,
            balance: const Value(400.0),
          ));

      await db.into(db.assetsOnAccounts).insert(
          AssetsOnAccountsCompanion.insert(
              accountId: accOld,
              assetId: baseCurrencyAssetId,
              shares: const Value(300),
              value: const Value(300)));
      await db.into(db.assetsOnAccounts).insert(
          AssetsOnAccountsCompanion.insert(
              accountId: accNew,
              assetId: baseCurrencyAssetId,
              shares: const Value(400),
              value: const Value(400)));

      // booking originally on accOld
      final id = await db.into(db.bookings).insert(BookingsCompanion.insert(
            date: 20240303,
            shares: 8.0,
            category: 'Move',
            accountId: accOld,
            assetId: Value(baseCurrencyAssetId),
            value: 8.0,
          ));

      final old = await bookingsDao.getBooking(id);

      // move to accNew, same asset, amount -> 12 base 12
      final updated = BookingsCompanion(
        id: Value(id),
        date: const Value(20240303),
        shares: const Value(12.0),
        category: const Value('Move'),
        accountId: Value(accNew),
        assetId: Value(baseCurrencyAssetId),
        value: const Value(12.0),
      );

      await bookingsDao.updateBooking(old, updated, l10n);

      // old account should have decreased by old base (-8) => 292
      final oldAcc = await (db.select(db.accounts)
            ..where((t) => t.id.equals(accOld)))
          .getSingle();
      expect(oldAcc.balance, closeTo(292.0, 1e-9));

      // new account should have increased by new base (+12) => 412
      final newAcc = await (db.select(db.accounts)
            ..where((t) => t.id.equals(accNew)))
          .getSingle();
      expect(newAcc.balance, closeTo(412.0, 1e-9));
    });

    test(
        'different accounts & different assets does full remove/add between accounts',
        () async {
      final accountOneId = await db.accountsDao.insert(AccountsCompanion.insert(
            name: 'Aold',
            type: AccountTypes.cash,
            balance: const Value(50.0),
          ));
      final accountTwoId = await db.accountsDao.insert(AccountsCompanion.insert(
            name: 'Anew',
            type: AccountTypes.cash,
            balance: const Value(60.0),
          ));

      await db.bookingsDao.createBooking(BookingsCompanion(
        date: const Value(20240404),
        accountId: Value(accountOneId),
        assetId: Value(assetOldId),
        category: const Value('Xchg'),
        shares: const Value(3.0),
        costBasis: const Value(1),
      ), l10n);

      // Prechecks
      var booking = await bookingsDao.getBooking(1);
      expect(booking.accountId, accountOneId);
      expect(booking.assetId, assetOldId);
      expect(booking.shares, closeTo(3, 1e-9));
      expect(booking.costBasis, closeTo(1, 1e-9));
      expect(booking.value, closeTo(3, 1e-9));
      var account1 = await db.accountsDao.getAccount(accountOneId);
      expect(account1.balance, closeTo(53, 1e-9));
      var account2 = await db.accountsDao.getAccount(accountTwoId);
      expect(account2.balance, closeTo(60, 1e-9));

      await bookingsDao.updateBooking(booking, BookingsCompanion(
        id: const Value(1),
        date: const Value(20240404),
        accountId: Value(accountTwoId),
        assetId: Value(assetNewId),
        category: const Value('Xchg'),
        shares: const Value(9.0),
        costBasis: const Value(1),
      ), l10n);

      // Postchecks
      booking = await bookingsDao.getBooking(1);
      expect(booking.accountId, accountTwoId);
      expect(booking.assetId, assetNewId);
      expect(booking.shares, closeTo(9, 1e-9));
      expect(booking.costBasis, closeTo(1, 1e-9));
      expect(booking.value, closeTo(9, 1e-9));
      account1 = await db.accountsDao.getAccount(accountOneId);
      expect(account1.balance, closeTo(50, 1e-9));
      account2 = await db.accountsDao.getAccount(accountTwoId);
      expect(account2.balance, closeTo(69, 1e-9));
    });
  });

  group('BookingsDao - deleteBooking', () {
    test('deletes booking and reverts account balance and assets', () async {
      final accId = await db.into(db.accounts).insert(AccountsCompanion.insert(
            name: 'DelAcc',
            type: AccountTypes.cash,
            balance: const Value(500.0),
          ));

      await db.into(db.assetsOnAccounts).insert(
          AssetsOnAccountsCompanion.insert(
              accountId: accId,
              assetId: baseCurrencyAssetId,
              shares: const Value(500.0),
              value: const Value(500.0)));

      final id = await db.into(db.bookings).insert(BookingsCompanion.insert(
            date: 20250105,
            shares: 25.0,
            category: 'Del',
            accountId: accId,
            assetId: Value(baseCurrencyAssetId),
            value: 25.0,
          ));

      // balance before delete should be unchanged (we didn't call createBooking)
      var acc = await (db.select(db.accounts)..where((t) => t.id.equals(accId)))
          .getSingle();
      expect(acc.balance, closeTo(500.0, 1e-9));

      // Now call deleteBooking, which will read booking and update account (-base)
      await bookingsDao.deleteBooking(id, l10n);

      // Booking removed
      final all = await bookingsDao.getAllBookings();
      expect(all.where((b) => b.id == id), isEmpty);

      // Account should have been decreased by value (-25)
      acc = await (db.select(db.accounts)..where((t) => t.id.equals(accId)))
          .getSingle();
      expect(acc.balance, closeTo(475.0, 1e-9));
    });
  });
}
