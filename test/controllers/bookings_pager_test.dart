import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xfin/controllers/bookings_pager.dart';
import 'package:xfin/database/app_database.dart';
import 'package:xfin/database/daos/bookings_dao.dart';
import 'package:xfin/database/tables.dart';

void main() {
  late AppDatabase db;
  late BookingsDao dao;
  late BookingsPager pager;

  final sampleAccount = AccountsCompanion.insert(
    id: const Value(1),
    name: 'Cash Account',
    balance: const Value(0),
    initialBalance: const Value(0),
    type: AccountTypes.cash,
    isArchived: const Value(false),
  );

  final sampleAsset = AssetsCompanion.insert(
    id: const Value(1),
    name: 'EUR',
    type: AssetTypes.fiat,
    tickerSymbol: 'EUR',
    netCostBasis: const Value(1),
    brokerCostBasis: const Value(1),
    isArchived: const Value(false),
  );

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    dao = BookingsDao(db);
    pager = BookingsPager(dao);

    await db.into(db.accounts).insert(sampleAccount);
    await db.into(db.assets).insert(sampleAsset);
  });

  tearDown(() async {
    try {
      pager.dispose();
    } catch (_) {}
    await db.close();
  });

  BookingsCompanion createBooking(int id, int date, double shares) {
    return BookingsCompanion.insert(
      id: Value(id),
      date: date,
      shares: shares,
      costBasis: const Value(1),
      assetId: const Value(1),
      value: 1,
      category: 'Test',
      accountId: 1,
      excludeFromAverage: const Value(false),
      isGenerated: const Value(false),
    );
  }

  test('loadInitial loads page and exposes items', () async {
    await db.into(db.bookings).insert(createBooking(1, 20250101, 10));
    await db.into(db.bookings).insert(createBooking(2, 20250101, 5));

    pager.loadInitial();
    await Future<void>.delayed(Duration.zero);

    expect(pager.items.length, 2);
    expect(pager.items[0].booking.id, 1);
    expect(pager.items[1].booking.id, 2);
    expect(pager.hasMore, isTrue);
  });

  test('loadInitial sets hasMore = false when DB is empty', () async {
    pager.loadInitial();
    await Future<void>.delayed(Duration.zero);

    expect(pager.items, isEmpty);
    expect(pager.hasMore, isFalse);
  });

  test('loadMore loads the next page and appends items', () async {
    for (int i = 0; i < 20; i++) {
      await db.into(db.bookings).insert(
        createBooking(i + 1, 20250101 + i, 10),
      );
    }

    pager.loadInitial();
    await Future<void>.delayed(Duration.zero);

    expect(pager.items.length, 15);
    expect(pager.hasMore, isTrue);

    pager.loadMore();
    await Future<void>.delayed(Duration.zero);

    expect(pager.items.length, 20);
  });

  test('dispose cancels active subscription', () async {
    await db.into(db.bookings).insert(createBooking(1, 20250101, 10));
    pager.loadInitial();
    await Future<void>.delayed(Duration.zero);

    expect(pager.items.length, 1);
    pager.dispose();
    await db.into(db.bookings).insert(createBooking(2, 20250102, 10));
    await Future<void>.delayed(Duration.zero);
  });
}