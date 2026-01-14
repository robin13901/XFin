import 'package:drift/drift.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/global_constants.dart';
import '../app_database.dart';
import '../tables.dart';

part 'bookings_dao.g.dart';

@DriftAccessor(tables: [Bookings, Accounts, Assets])
class BookingsDao extends DatabaseAccessor<AppDatabase>
    with _$BookingsDaoMixin {
  BookingsDao(super.db);

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

  Future<int> _insert(BookingsCompanion b) => into(bookings).insert(b);

  Future<bool> _update(BookingsCompanion b) => update(bookings).replace(b);

  Future<int> _delete(int id) =>
      (delete(bookings)..where((tbl) => tbl.id.equals(id))).go();

  Future<Booking> getBooking(int id) =>
      (select(bookings)..where((tbl) => tbl.id.equals(id))).getSingle();

  Future<List<Booking>> getAllBookings() => select(bookings).get();

  Future<List<Booking>> getBookingsAfter(
          int assetId, int accountId, int datetime) =>
      (select(bookings)
            ..where((b) =>
                b.assetId.equals(assetId) &
                b.accountId.equals(accountId) &
                b.date.isBiggerOrEqualValue(datetime ~/ 1000000))
            ..orderBy([
              (b) => OrderingTerm(expression: b.date),
            ]))
          .get();

  Future<List<Booking>> getBookingsForAccount(int accountId) =>
      (select(bookings)..where((b) => b.accountId.equals(accountId))).get();

  Future<List<Booking>> getBookingsForAOA(int assetId, int accountId) =>
      (select(bookings)
            ..where((b) =>
                b.assetId.equals(assetId) & b.accountId.equals(accountId)))
          .get();

  Future<BookingsCompanion> calculateCostBasisAndValue(BookingsCompanion b,
      {Booking? bOld}) async {
    final shares = b.shares.value;
    double costBasis = 1, value = shares * costBasis;

    if (b.assetId.value != 1) {
      if (shares > 0) {
        costBasis = b.costBasis.value;
        value = shares * costBasis;
      } else {
        final fifo = await db.assetsOnAccountsDao.buildFiFoQueue(
            b.assetId.value, b.accountId.value,
            upToDatetime: b.date.value * 1000000, oldBooking: bOld);

        (value, _) = consumeFiFo(fifo, shares.abs());
        costBasis = (value / shares).abs();
      }
    }
    return b.copyWith(
        costBasis: Value(normalize(costBasis)), value: Value(normalize(value)));
  }

  Future<void> createBooking(BookingsCompanion b, AppLocalizations l10n) {
    return transaction(() async {
      if (!b.costBasis.present) {
        b = await calculateCostBasisAndValue(b);
      } else if (!b.value.present) {
        b = b.copyWith(value: Value(b.shares.value * b.costBasis.value));
      }

      final bookingId = await _insert(b);

      await db.tradesDao.applyDbEffects(
          b.assetId.value, b.accountId.value, b.shares.value, b.value.value, 0);

      await db.assetsOnAccountsDao.recalculateSubsequentEvents(
        l10n: l10n,
        assetId: b.assetId.value,
        accountId: b.accountId.value,
        upToDatetime: b.date.value * 1000000,
        upToType: '_booking',
        upToId: bookingId,
      );
    });
  }

  Future<void> updateBooking(
      Booking bOld, BookingsCompanion bNew, AppLocalizations l10n) {
    return transaction(() async {
      bNew = await calculateCostBasisAndValue(bNew, bOld: bOld);

      await _update(bNew);

      await db.tradesDao.applyDbEffects(
          bOld.assetId, bOld.accountId, -bOld.shares, -bOld.value, 0);
      await db.tradesDao.applyDbEffects(bNew.assetId.value,
          bNew.accountId.value, bNew.shares.value, bNew.value.value, 0);

      await db.assetsOnAccountsDao.recalculateSubsequentEvents(
        l10n: l10n,
        assetId: bOld.assetId,
        accountId: bOld.accountId,
        upToDatetime: bOld.date * 1000000,
        upToType: '_booking',
        upToId: bOld.id,
      );

      if (bOld.accountId != bNew.accountId.value ||
          bOld.assetId != bNew.assetId.value) {
        await db.assetsOnAccountsDao.recalculateSubsequentEvents(
          l10n: l10n,
          assetId: bNew.assetId.value,
          accountId: bNew.accountId.value,
          upToDatetime: bNew.date.value * 1000000,
          upToType: '_booking',
          upToId: bOld.id,
        );
      }
    });
  }

  Future<void> deleteBooking(int id, AppLocalizations l10n) {
    return transaction(() async {
      final b = await getBooking(id);
      await _delete(id);
      await db.tradesDao
          .applyDbEffects(b.assetId, b.accountId, -b.shares, -b.value, 0);

      await db.assetsOnAccountsDao.recalculateSubsequentEvents(
        l10n: l10n,
        assetId: b.assetId,
        accountId: b.accountId,
        upToDatetime: b.date * 1000000,
        upToType: '_booking',
        upToId: b.id,
      );
    });
  }
}

class BookingWithAccountAndAsset {
  final Booking booking;
  final Account account;
  final Asset asset;

  BookingWithAccountAndAsset(
      {required this.booking, required this.account, required this.asset});
}
