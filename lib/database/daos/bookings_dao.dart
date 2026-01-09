import 'package:drift/drift.dart';
import '../../l10n/app_localizations.dart';
import '../app_database.dart';
import '../tables.dart';

part 'bookings_dao.g.dart';

@DriftAccessor(tables: [Bookings, Accounts, Assets])
class BookingsDao extends DatabaseAccessor<AppDatabase>
    with _$BookingsDaoMixin {
  BookingsDao(super.db);

  Stream<List<BookingWithAccountAndAsset>> watchBookingsWithAccountAndAsset() {
    final query = select(bookings).join([
      leftOuterJoin(accounts, accounts.id.equalsExp(bookings.accountId)),
      leftOuterJoin(assets, assets.id.equalsExp(bookings.assetId)),
    ]);

    query.where(accounts.isArchived.equals(false));
    query.orderBy([
      OrderingTerm.desc(bookings.date),
      OrderingTerm.desc(bookings.shares),
    ]);

    return query.watch().map(_mapRows);
  }

  List<BookingWithAccountAndAsset> _mapRows(
    List<TypedResult> rows,
  ) {
    return rows.map((row) {
      return BookingWithAccountAndAsset(
        booking: row.readTable(bookings),
        account: row.readTable(accounts),
        asset: row.readTable(assets),
      );
    }).toList();
  }

  Stream<List<BookingWithAccountAndAsset>> watchBookingsPage({
    required int limit,
    int? lastDate,
    double? lastValue,
  }) {
    final query = select(bookings).join([
      leftOuterJoin(accounts, accounts.id.equalsExp(bookings.accountId)),
      leftOuterJoin(assets, assets.id.equalsExp(bookings.assetId)),
    ]);

    // Only non-archived accounts
    query.where(accounts.isArchived.equals(false));

    // Keyset pagination condition
    if (lastDate != null && lastValue != null) {
      query.where(
        bookings.date.isSmallerThanValue(lastDate) |
            (bookings.date.equals(lastDate) &
                bookings.value.isSmallerThanValue(lastValue)),
      );
    }

    query.orderBy([
      OrderingTerm.desc(bookings.date),
      OrderingTerm.desc(bookings.value),
    ]);

    query.limit(limit);

    return query.watch().map(_mapRows);
  }

  Future<Booking?> findMergeableBooking(BookingsCompanion newBooking) async {
    if (newBooking.notes.present && newBooking.notes.value != null) return null;
    final newShares = newBooking.shares.value;
    final query = select(bookings)
      ..where((tbl) =>
          tbl.date.equals(newBooking.date.value) &
          tbl.category.equals(newBooking.category.value) &
          tbl.accountId.equals(newBooking.accountId.value) &
          tbl.assetId.equals(newBooking.assetId.value) &
          tbl.excludeFromAverage.equals(newBooking.excludeFromAverage.value) &
          tbl.notes.isNull() &
          ((tbl.shares.isBiggerThanValue(0) & Constant(newShares > 0)) |
              (tbl.shares.isSmallerThanValue(0) & Constant(newShares < 0))));
    return await query.getSingleOrNull();
  }

  Stream<List<String>> watchDistinctCategories() {
    final query = selectOnly(bookings, distinct: true)
      ..addColumns([bookings.category]);
    return query.watch().map(
        (rows) => rows.map((row) => row.read(bookings.category)!).toList());
  }

  Future<List<String>> getDistinctCategories() async {
    final query = selectOnly(bookings, distinct: true)
      ..addColumns([bookings.category]);

    final rows = await query.get();
    return rows.map((row) => row.read(bookings.category)!).toList();
  }

  // Methods that are not transactional
  Future<int> _addBooking(BookingsCompanion entry) =>
      into(bookings).insert(entry);

  Future<bool> _updateBooking(BookingsCompanion entry) =>
      update(bookings).replace(entry);

  Future<int> _deleteBooking(int id) =>
      (delete(bookings)..where((tbl) => tbl.id.equals(id))).go();

  Future<Booking> getBooking(int id) =>
      (select(bookings)..where((tbl) => tbl.id.equals(id))).getSingle();

  Future<List<Booking>> getAllBookings() => select(bookings).get();

  Future<BookingsCompanion> calculateCostBasisAndValue(BookingsCompanion booking,
      {Booking? oldBooking}) async {
    final assetId = booking.assetId.value;
    final accountId = booking.accountId.value;
    final shares = booking.shares.value;
    final datetime = booking.date.value * 1000000;
    double costBasis, value = 0.0;

    // Only recalculate if booking is a withdrawal
    if (shares > 0) return booking;

    if (assetId == 1) {
      costBasis = 1;
    } else {
      final fifo = await db.assetsOnAccountsDao.buildFiFoQueue(
          assetId, accountId,
          upToDatetime: datetime, oldBooking: oldBooking);

      double sharesToConsume = shares.abs();
      while (sharesToConsume > 0 && fifo.isNotEmpty) {
        final currentLot = fifo.first;
        final lotShares = currentLot['shares']!;
        final lotCostBasis = currentLot['costBasis']!;

        if (lotShares <= sharesToConsume + 1e-12) {
          sharesToConsume -= lotShares;
          value += lotShares * lotCostBasis;
          fifo.removeFirst();
        } else {
          currentLot['shares'] = lotShares - sharesToConsume;
          value += sharesToConsume * lotCostBasis;
          sharesToConsume = 0;
        }
      }
      costBasis = value / shares.abs();
    }
    value = shares * costBasis;
    return booking.copyWith(costBasis: Value(costBasis), value: Value(value));
  }

  Future<void> createBooking(BookingsCompanion booking, AppLocalizations l10n) {
    return transaction(() async {
      if (!booking.costBasis.present) {
        booking = await calculateCostBasisAndValue(booking);
      }

      final bookingId = await _addBooking(booking);

      await db.assetsOnAccountsDao.updateAOA(AssetOnAccount(
          accountId: booking.accountId.value,
          assetId: booking.assetId.value,
          value: booking.value.value,
          shares: booking.shares.value,
          netCostBasis: 0,
          brokerCostBasis: 0,
          buyFeeTotal: 0));
      await db.assetsDao.updateAsset(
          booking.assetId.value, booking.shares.value, booking.value.value);

      await db.accountsDao
          .updateBalance(booking.accountId.value, booking.value.value);

      await db.assetsOnAccountsDao.recalculateSubsequentEvents(
        l10n: l10n,
        assetId: booking.assetId.value,
        accountId: booking.accountId.value,
        upToDatetime: booking.date.value * 1000000,
        upToType: '_booking',
        upToId: bookingId,
      );
    });
  }

// // NEW/EXPERIMENTAL version
  Future<void> updateBooking(Booking oldBooking, BookingsCompanion newBooking, AppLocalizations l10n) {
    return transaction(() async {
      newBooking = await calculateCostBasisAndValue(newBooking, oldBooking: oldBooking);

      // Persist the new booking row first (you already had this).
      await _updateBooking(newBooking);

      // --- compute the deltas and apply the immediate numeric adjustments ---
      final oldShares = oldBooking.shares;
      final oldValue = oldBooking.value;
      final newShares = newBooking.shares.value;
      final newValue = newBooking.value.value;

      final sharesDelta = newShares - oldShares;
      final valueDelta = newValue - oldValue;

      final oldAccountId = oldBooking.accountId;
      final oldAssetId = oldBooking.assetId;
      final newAccountId = newBooking.accountId.value;
      final newAssetId = newBooking.assetId.value;

      // We'll collect recalc tasks in this set (avoid duplicates).
      // Each entry is a tuple (assetId, accountId, datetime)
      final Set<String> recalcTasks = {};

      // Helper to add a task (string key to make set dedupe easy)
      void addRecalcTask(int assetId, int accountId, int dateUtc) {
        // dateUtc is yyyyMMddhhmmss (we'll store as int)
        final key = '$assetId|$accountId|$dateUtc';
        recalcTasks.add(key);
      }

      // For update we want to schedule recalculation for all affected (asset,account) pairs.
      // Old booking affected (it was present before update): oldAssetId, oldAccountId, at oldBooking.date
      final oldKeyDt = oldBooking.date * 1000000;
      addRecalcTask(oldAssetId, oldAccountId, oldKeyDt);

      // New booking (after update) affects newAssetId/newAccountId at newBooking.date
      final newKeyDt = newBooking.date.value *
          1000000; // defensive; normally newBooking.date is present
      addRecalcTask(newAssetId, newAccountId, newKeyDt);

      // Now apply the immediate numeric changes you already had in your code
      // CASE 1 — Same Account
      if (oldAccountId == newAccountId) {
        // A) Update the account balance by the delta
        await db.accountsDao.updateBalance(oldAccountId, valueDelta);

        // CASE 1A — Same Account, Same Asset
        if (oldAssetId == newAssetId) {
          // direct adjustment by deltas
          await db.assetsDao.updateAsset(oldAssetId, sharesDelta, valueDelta);
          await db.assetsOnAccountsDao.updateAOA(AssetOnAccount(
              accountId: oldAccountId,
              assetId: oldAssetId,
              value: valueDelta,
              shares: sharesDelta,
              netCostBasis: 0,
              brokerCostBasis: 0,
              buyFeeTotal: 0));
        } else {
          // CASE 1B — Same Account, Different Assets
          // remove old asset effect
          await db.assetsDao.updateAsset(oldAssetId, -oldShares, -oldValue);
          await db.assetsOnAccountsDao.updateAOA(AssetOnAccount(
              accountId: oldAccountId,
              assetId: oldAssetId,
              value: -oldValue,
              shares: -oldShares,
              netCostBasis: 0,
              brokerCostBasis: 0,
              buyFeeTotal: 0));

          // add new asset effect
          await db.assetsDao.updateAsset(newAssetId, newShares, newValue);
          await db.assetsOnAccountsDao.updateAOA(AssetOnAccount(
              accountId: oldAccountId,
              assetId: newAssetId,
              value: newValue,
              shares: newShares,
              netCostBasis: 0,
              brokerCostBasis: 0,
              buyFeeTotal: 0));
        }

        // CASE 2 — Different Accounts
      } else {
        // Remove old booking value from old account
        await db.accountsDao.updateBalance(oldAccountId, -oldValue);
        // Add new booking value to new account
        await db.accountsDao.updateBalance(newAccountId, newValue);

        // CASE 2A — Different Accounts, Same Asset
        if (oldAssetId == newAssetId) {
          // Update asset with deltas
          await db.assetsDao.updateAsset(oldAssetId, sharesDelta, valueDelta);

          // Update asset on old account (remove old)
          await db.assetsOnAccountsDao.updateAOA(AssetOnAccount(
              accountId: oldAccountId,
              assetId: oldAssetId,
              value: -oldValue,
              shares: -oldShares,
              netCostBasis: 0,
              brokerCostBasis: 0,
              buyFeeTotal: 0));

          // Update asset on new account (add new)
          await db.assetsOnAccountsDao.updateAOA(AssetOnAccount(
              accountId: newAccountId,
              assetId: oldAssetId,
              value: newValue,
              shares: newShares,
              netCostBasis: 0,
              brokerCostBasis: 0,
              buyFeeTotal: 0));
        } else {
          // CASE 2B — Different Accounts, Different Assets
          // Update old asset (remove)
          await db.assetsDao.updateAsset(oldAssetId, -oldShares, -oldValue);
          // Update new asset (add)
          await db.assetsDao.updateAsset(newAssetId, newShares, newValue);

          // Remove old asset from old account
          await db.assetsOnAccountsDao.updateAOA(AssetOnAccount(
              accountId: oldAccountId,
              assetId: oldAssetId,
              value: -oldValue,
              shares: -oldShares,
              netCostBasis: 0,
              brokerCostBasis: 0,
              buyFeeTotal: 0));

          // Add new asset on new account
          await db.assetsOnAccountsDao.updateAOA(AssetOnAccount(
              accountId: newAccountId,
              assetId: newAssetId,
              value: newValue,
              shares: newShares,
              netCostBasis: 0,
              brokerCostBasis: 0,
              buyFeeTotal: 0));
        }
      }

      // --- AFTER all immediate numeric updates: run recalc for each affected pair ---
      // Convert the deduped string keys back to (assetId, accountId, datetime)
      for (final k in recalcTasks) {
        final parts = k.split('|');
        final assetIdToRecalc = int.parse(parts[0]);
        final accountIdToRecalc = int.parse(parts[1]);
        final dt = int.parse(parts[2]); // already yyyyMMddhhmmss

        await db.assetsOnAccountsDao.recalculateSubsequentEvents(
          l10n: l10n,
          assetId: assetIdToRecalc,
          accountId: accountIdToRecalc,
          upToDatetime: dt,
          upToType: '_booking',
          upToId: oldBooking.id, // existing booking id (same for update)
        );
      }
    });
  }

  Future<void> deleteBooking(int id, AppLocalizations l10n) {
    return transaction(() async {
      final booking = await getBooking(id);
      await _deleteBooking(id);
      await db.accountsDao.updateBalance(booking.accountId, -booking.value);
      await db.assetsOnAccountsDao.updateAOA(AssetOnAccount(
          accountId: booking.accountId,
          assetId: booking.assetId,
          value: -booking.value,
          shares: -booking.shares,
          netCostBasis: 0,
          brokerCostBasis: 0,
          buyFeeTotal: 0));
      await db.assetsDao
          .updateAsset(booking.assetId, -booking.shares, -booking.value);

      // --- NEW / EXPERIMENTAL ------------------------------------------------
      final keyDt = booking.date * 1000000;
      await db.assetsOnAccountsDao.recalculateSubsequentEvents(
        l10n: l10n,
        assetId: booking.assetId,
        accountId: booking.accountId,
        upToDatetime: keyDt,
        upToType: '_booking',
        upToId: booking.id,
      );
      // -----------------------------------------------------------------------
    });
  }
}

// Data class to hold a booking with its associated account and asset objects.
class BookingWithAccountAndAsset {
  final Booking booking;
  final Account account;
  final Asset asset;

  BookingWithAccountAndAsset(
      {required this.booking, required this.account, required this.asset});
}
