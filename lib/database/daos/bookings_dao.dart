import 'package:drift/drift.dart';
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

    // Only show bookings from non-archived accounts
    query.where(accounts.isArchived.equals(false));

    query.orderBy([
      OrderingTerm.desc(bookings.date),
      OrderingTerm.desc(bookings.shares),
    ]);

    return query.watch().map((rows) {
      return rows.map((row) {
        return BookingWithAccountAndAsset(
          booking: row.readTable(bookings),
          account: row.readTable(accounts),
          asset: row.readTable(assets),
        );
      }).toList();
    });
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

  // Methods that are not transactional
  Future<int> _addBooking(BookingsCompanion entry) =>
      into(bookings).insert(entry);

  Future<bool> _updateBooking(BookingsCompanion entry) =>
      update(bookings).replace(entry);

  Future<int> _deleteBooking(int id) =>
      (delete(bookings)
        ..where((tbl) => tbl.id.equals(id))).go();

  Future<Booking> getBooking(int id) =>
      (select(bookings)
        ..where((tbl) => tbl.id.equals(id))).getSingle();

  Future<List<Booking>> getAllBookings() => select(bookings).get();

  Future<void> createBooking(BookingsCompanion booking) {
    return transaction(() async {
      await _addBooking(booking);
      await db.accountsDao.updateBalance(
          booking.accountId.value, booking.value.value);
      await db.assetsOnAccountsDao.updateAOA(AssetOnAccount(
          accountId: booking.accountId.value,
          assetId: booking.assetId.value,
          value: booking.value.value,
          shares: booking.shares.value,
          netCostBasis: 0,
          brokerCostBasis: 0,
          buyFeeTotal: 0));
      await db.assetsDao.updateAsset(booking.assetId.value,
          booking.shares.value, booking.value.value);
    });
  }

  Future<void> updateBooking(Booking oldBooking, BookingsCompanion newBooking) {
    return transaction(() async {
      await _updateBooking(newBooking);

      final oldShares = oldBooking.shares;
      final oldValue = oldBooking.value;
      final newShares = newBooking.shares.value;
      final newValue = newBooking.value.value;

      final sharesDelta = newShares - oldShares;
      final valueDelta = newValue -
          oldValue;

      final oldAccountId = oldBooking.accountId;
      final oldAssetId = oldBooking.assetId;
      final newAccountId = newBooking.accountId.value;
      final newAssetId = newBooking.assetId.value;

      // CASE 1 — Same Account
      if (oldAccountId == newAccountId) {
        // A) Update the account balance by the delta
        await db.accountsDao.updateBalance(
            oldAccountId, valueDelta);

        // CASE 1A — Same Account, Same Asset
        if (oldAssetId == newAssetId) {
          // direct adjustment by deltas
          await db.assetsDao.updateAsset(
              oldAssetId, sharesDelta, valueDelta);
          await db.assetsOnAccountsDao.updateAOA(AssetOnAccount(
              accountId: oldAccountId,
              assetId: oldAssetId,
              value: valueDelta,
              shares: sharesDelta,
              netCostBasis: 0,
              brokerCostBasis: 0,
              buyFeeTotal: 0));

          // CASE 1B — Same Account, Different Assets
        } else {
          // remove old asset effect
          await db.assetsDao.updateAsset(
              oldAssetId, -oldShares, -oldValue);
          await db.assetsOnAccountsDao.updateAOA(AssetOnAccount(
              accountId: oldAccountId,
              assetId: oldAssetId,
              value: -oldValue,
              shares: -oldShares,
              netCostBasis: 0,
              brokerCostBasis: 0,
              buyFeeTotal: 0));

          // add new asset effect
          await db.assetsDao.updateAsset(
              newAssetId, newShares, newValue);
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
          await db.assetsDao.updateAsset(
              oldAssetId, sharesDelta, valueDelta);

          // Update asset on old account
          await db.assetsOnAccountsDao.updateAOA(AssetOnAccount(
              accountId: oldAccountId,
              assetId: oldAssetId,
              value: -oldValue,
              shares: -oldShares,
              netCostBasis: 0,
              brokerCostBasis: 0,
              buyFeeTotal: 0));

          // Update asset on new account
          await db.assetsOnAccountsDao.updateAOA(AssetOnAccount(
              accountId: newAccountId,
              assetId: oldAssetId,
              value: newValue,
              shares: newShares,
              netCostBasis: 0,
              brokerCostBasis: 0,
              buyFeeTotal: 0));

          // CASE 2B — Different Accounts, Different Assets
        } else {
          // Update old asset
          await db.assetsDao.updateAsset(
              oldAssetId, -oldShares, -oldValue);
          // Update new asset
          await db.assetsDao.updateAsset(
              newAssetId, newShares, newValue);

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
    });
  }

  Future<void> deleteBooking(int id) {
    return transaction(() async {
      final booking = await getBooking(id);
      await _deleteBooking(id);
      await db.accountsDao.updateBalance(
          booking.accountId, -booking.value);
      await db.assetsOnAccountsDao.updateAOA(AssetOnAccount(
          accountId: booking.accountId,
          assetId: booking.assetId,
          value: -booking.value,
          shares: -booking.shares,
          netCostBasis: 0,
          brokerCostBasis: 0,
          buyFeeTotal: 0));
      await db.assetsDao.updateAsset(
          booking.assetId, -booking.shares, -booking.value);
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
