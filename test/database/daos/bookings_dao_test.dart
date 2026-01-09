// test/bookings_dao_test.dart
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
          await db.bookingsDao.createBooking(BookingsCompanion(
              date: const Value(20250101),
              assetId: Value(assetOne.id),
              accountId: Value(portfolio1.id),
              category: const Value('Test'),
              shares: const Value(0.5),
              costBasis: const Value(100),
              value: const Value(50)), l10n);
          await db.bookingsDao.createBooking(BookingsCompanion(
              date: const Value(20250102),
              assetId: Value(assetOne.id),
              accountId: Value(portfolio1.id),
              category: const Value('Test'),
              shares: const Value(0.5),
              costBasis: const Value(200),
              value: const Value(100)), l10n);

          // Create SUT
          await db.bookingsDao.createBooking(BookingsCompanion(
              date: const Value(20250103),
              assetId: Value(assetOne.id),
              accountId: Value(portfolio1.id),
              category: const Value('Test'),
              shares: const Value(-1)), l10n);

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
          await db.into(db.assetsOnAccounts).insert(AssetsOnAccountsCompanion.insert(
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
          final page2 =
          await bookingsDao.watchBookingsPage(limit: 2, lastDate: lastDate, lastValue: lastShares).first;
          expect(page2.length, 2);
          // Because date desc, shares desc, the rows after (B) are C (same date, lower shares) then D (older date)
          expect(page2[0].booking.id, idC);
          expect(page2[1].booking.id, idD);

          // Third page: there should be no more rows (empty list)
          final page3 = await bookingsDao.watchBookingsPage(limit: 2, lastDate: page2.last.booking.date, lastValue: page2.last.booking.shares).first;
          expect(page3, isEmpty);
        });
  });

  group('BookingsDao - updateBooking (4 scenarios)', () {
    test('same account & same asset updates booking and account by delta',
            () async {
          // original booking: amount=10, base=10
          final id = await db.into(db.bookings).insert(BookingsCompanion.insert(
            date: 20240101,
            shares: 10.0,
            category: 'Cat',
            accountId: accountId,
            assetId: Value(baseCurrencyAssetId),
            value: 10.0,
          ));

          final old = await bookingsDao.getBooking(id);

          // new booking: same account & same asset, amount=15 base=15
          final updatedCompanion = BookingsCompanion(
            id: Value(id),
            date: const Value(20240101),
            shares: const Value(15.0),
            category: const Value('Cat'),
            accountId: Value(accountId),
            assetId: Value(baseCurrencyAssetId),
            value: const Value(15.0),
          );

          await bookingsDao.updateBooking(old, updatedCompanion, l10n);

          // booking updated in DB
          final changed = await bookingsDao.getBooking(id);
          expect(changed.shares, 15.0);
          expect(changed.value, 15.0);

          // account balance changed by delta (15 - 10) = +5
          final acc = await (db.select(db.accounts)
            ..where((t) => t.id.equals(accountId)))
              .getSingle();
          expect(acc.balance, closeTo(5.0, 1e-9));
        });

    test(
        'same account & different asset moves asset but account balance adjusted properly',
            () async {
          final assetOld = await db.into(db.assets).insert(AssetsCompanion.insert(
            name: 'OLD',
            type: AssetTypes.stock,
            tickerSymbol: 'OLD',
          ));
          final assetNew = await db.into(db.assets).insert(AssetsCompanion.insert(
            name: 'NEW',
            type: AssetTypes.stock,
            tickerSymbol: 'NEW',
          ));

          await db.into(db.assetsOnAccounts).insert(
              AssetsOnAccountsCompanion.insert(
                  accountId: accountId, assetId: assetOld));
          await db.into(db.assetsOnAccounts).insert(
              AssetsOnAccountsCompanion.insert(
                  accountId: accountId, assetId: assetNew));

          // original booking uses OLD
          final id = await db.into(db.bookings).insert(BookingsCompanion.insert(
            date: 20240202,
            shares: 5.0,
            category: 'Swap',
            accountId: accountId,
            assetId: Value(assetOld),
            value: 5.0,
            excludeFromAverage: const Value(false),
          ));

          final old = await bookingsDao.getBooking(id);

          // new booking keeps same account but uses NEW asset and amount 12 base 12
          final updated = BookingsCompanion(
            id: Value(id),
            date: const Value(20240202),
            shares: const Value(12.0),
            category: const Value('Swap'),
            accountId: Value(accountId),
            assetId: Value(assetNew),
            value: const Value(12.0),
            excludeFromAverage: const Value(false),
          );

          await bookingsDao.updateBooking(old, updated, l10n);

          final changed = await bookingsDao.getBooking(id);
          expect(changed.assetId, assetNew);
          expect(changed.shares, 12.0);

          // account balance should have changed by base delta (12 - 5) = +7
          final acc = await (db.select(db.accounts)
            ..where((t) => t.id.equals(accountId)))
              .getSingle();
          expect(acc.balance, closeTo(7.0, 1e-9));
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
          final accOld = await db.into(db.accounts).insert(AccountsCompanion.insert(
            name: 'Aold',
            type: AccountTypes.cash,
            balance: const Value(50.0),
          ));
          final accNew = await db.into(db.accounts).insert(AccountsCompanion.insert(
            name: 'Anew',
            type: AccountTypes.cash,
            balance: const Value(60.0),
          ));
          final assetOld = await db.into(db.assets).insert(AssetsCompanion.insert(
            name: 'AO',
            type: AssetTypes.stock,
            tickerSymbol: 'AO',
          ));
          final assetNew = await db.into(db.assets).insert(AssetsCompanion.insert(
            name: 'AN',
            type: AssetTypes.stock,
            tickerSymbol: 'AN',
          ));

          await db.into(db.assetsOnAccounts).insert(
              AssetsOnAccountsCompanion.insert(
                  accountId: accOld,
                  assetId: assetNew,
                  shares: const Value(50),
                  value: const Value(50)));
          await db.into(db.assetsOnAccounts).insert(
              AssetsOnAccountsCompanion.insert(
                  accountId: accOld,
                  assetId: assetOld,
                  shares: const Value(0),
                  value: const Value(0)));
          await db.into(db.assetsOnAccounts).insert(
              AssetsOnAccountsCompanion.insert(
                  accountId: accNew,
                  assetId: assetNew,
                  shares: const Value(60),
                  value: const Value(60)));
          await db.into(db.assetsOnAccounts).insert(
              AssetsOnAccountsCompanion.insert(
                  accountId: accNew,
                  assetId: assetOld,
                  shares: const Value(0),
                  value: const Value(0)));

          final id = await db.into(db.bookings).insert(BookingsCompanion.insert(
            date: 20240404,
            shares: 3.0,
            category: 'Xchg',
            accountId: accOld,
            assetId: Value(assetOld),
            value: 3.0,
          ));

          final old = await bookingsDao.getBooking(id);

          final updated = BookingsCompanion(
            id: Value(id),
            date: const Value(20240404),
            shares: const Value(9.0),
            category: const Value('Xchg'),
            accountId: Value(accNew),
            assetId: Value(assetNew),
            value: const Value(9.0),
          );

          await bookingsDao.updateBooking(old, updated, l10n);

          // old account decreased by 3 -> 47
          final aOld = await (db.select(db.accounts)
            ..where((t) => t.id.equals(accOld)))
              .getSingle();
          expect(aOld.balance, closeTo(47.0, 1e-9));

          // new account increased by 9 -> 69
          final aNew = await (db.select(db.accounts)
            ..where((t) => t.id.equals(accNew)))
              .getSingle();
          expect(aNew.balance, closeTo(69.0, 1e-9));

          // booking row should reflect the new account/asset/amount
          final changed = await bookingsDao.getBooking(id);
          expect(changed.accountId, accNew);
          expect(changed.assetId, assetNew);
          expect(changed.shares, 9.0);
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