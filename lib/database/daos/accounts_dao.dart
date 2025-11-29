import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables.dart';

part 'accounts_dao.g.dart';

@DriftAccessor(tables: [
  Accounts,
  Bookings,
  Transfers,
  Trades,
  PeriodicBookings,
  PeriodicTransfers,
  Goals,
  AssetsOnAccounts
])
class AccountsDao extends DatabaseAccessor<AppDatabase>
    with _$AccountsDaoMixin {
  AccountsDao(super.db);

  Future<int> _insert(AccountsCompanion entry) => into(accounts).insert(entry);

  Future<int> createAccount(AccountsCompanion account) {
    return transaction(() async {
      int accountId = await _insert(account);
      if (account.type.value == AccountTypes.cash) {
        if (account.initialBalance.present) {
          await db.assetsDao
              .updateBaseCurrencyAsset(account.initialBalance.value);
        }

        final assetOnAccount = AssetsOnAccountsCompanion(
          accountId: Value(accountId),
          assetId: const Value(1),
          value: account.initialBalance,
          sharesOwned: account.initialBalance,
          netCostBasis: const Value(1.0),
          brokerCostBasis: const Value(1.0),
          buyFeeTotal: const Value(0.0),
        );
        await db.assetsOnAccountsDao.addAssetOnAccount(assetOnAccount);
      }
      return accountId;
    });
  }

  Future<Account> getAccount(int id) =>
      (select(accounts)..where((a) => a.id.equals(id))).getSingle();

  Future<List<Account>> getAllAccounts() => select(accounts).get();

  Future<double> getSumOfInitialBalances() async {
    final allAccounts = await getAllAccounts();
    return allAccounts.fold<double>(
        0.0, (sum, acc) => sum + acc.initialBalance);
  }

  Future<bool> hasBookings(int accountId) async {
    final query = select(bookings)..where((b) => b.accountId.equals(accountId));
    return (await query.get()).isNotEmpty;
  }

  Future<bool> hasTransfers(int accountId) async {
    final query = select(transfers)
      ..where((t) =>
          t.sendingAccountId.equals(accountId) |
          t.receivingAccountId.equals(accountId));
    return (await query.get()).isNotEmpty;
  }

  Future<bool> hasTrades(int accountId) async {
    final query = select(trades)
      ..where((t) =>
          t.clearingAccountId.equals(accountId) |
          t.portfolioAccountId.equals(accountId));
    return (await query.get()).isNotEmpty;
  }

  Future<bool> hasPeriodicBookings(int accountId) async {
    final query = select(periodicBookings)
      ..where((pb) => pb.accountId.equals(accountId));
    return (await query.get()).isNotEmpty;
  }

  Future<bool> hasPeriodicTransfers(int accountId) async {
    final query = select(periodicTransfers)
      ..where((pt) =>
          pt.sendingAccountId.equals(accountId) |
          pt.receivingAccountId.equals(accountId));
    return (await query.get()).isNotEmpty;
  }

  Future<bool> hasGoals(int accountId) async {
    final query = select(goals)..where((g) => g.accountId.equals(accountId));
    return (await query.get()).isNotEmpty;
  }

  Future<bool> hasAssets(int accountId) async {
    final query = select(assetsOnAccounts)
      ..where((aoa) => aoa.accountId.equals(accountId));
    return (await query.get()).isNotEmpty;
  }

  Stream<List<Account>> watchAllAccounts() =>
      (select(accounts)..where((a) => a.isArchived.equals(false))).watch();

  Stream<List<Account>> watchCashAccounts() => (select(accounts)
        ..where((a) =>
            a.isArchived.equals(false) & a.type.equalsValue(AccountTypes.cash)))
      .watch();

  Stream<List<Account>> watchArchivedAccounts() =>
      (select(accounts)..where((a) => a.isArchived.equals(true))).watch();

  Future<void> updateBalance(int accountId, double delta) {
    return customUpdate(
      'UPDATE accounts SET balance = balance + ? WHERE id = ?',
      variables: [Variable(delta), Variable(accountId)],
      updates: {accounts},
    );
  }

  Future<void> setArchived(int id, bool isArchived) {
    return (update(accounts)..where((a) => a.id.equals(id)))
        .write(AccountsCompanion(isArchived: Value(isArchived)));
  }

  Future<void> deleteAccount(int id) =>
      (delete(accounts)..where((a) => a.id.equals(id))).go();

  Future<bool> leadsToInconsistentBalanceHistory({
    Booking? originalBooking,
    BookingsCompanion? newBooking,
    TradesCompanion? newTrade,
  }) async {
    Set<int> accountIds = {};
    if (originalBooking != null) accountIds.add(originalBooking.accountId);
    if (newBooking != null) accountIds.add(newBooking.accountId.value);
    if (newTrade != null) {
      accountIds.add(newTrade.clearingAccountId.value);
      accountIds.add(newTrade.portfolioAccountId.value);
    }

    for (var accountId in accountIds) {
      // Launch DB queries in parallel
      final accountFuture = getAccount(accountId);
      final bookingsFuture =
          (select(bookings)..where((b) => b.accountId.equals(accountId))).get();
      final sendingTransfersFuture = (select(transfers)
            ..where((t) => t.sendingAccountId.equals(accountId)))
          .get();
      final receivingTransfersFuture = (select(transfers)
            ..where((t) => t.receivingAccountId.equals(accountId)))
          .get();
      final clearingTradesFuture = (select(trades)
            ..where((t) => t.clearingAccountId.equals(accountId)))
          .get();
      final portfolioTradesFuture = (select(trades)
            ..where((t) => t.portfolioAccountId.equals(accountId)))
          .get();

      final results = await Future.wait([
        accountFuture,
        bookingsFuture,
        sendingTransfersFuture,
        receivingTransfersFuture,
        clearingTradesFuture,
        portfolioTradesFuture
      ]);

      final account = results[0] as Account;
      final accountBookings = results[1] as List<Booking>;
      final sendingTransfers = results[2] as List<Transfer>;
      final receivingTransfers = results[3] as List<Transfer>;
      final clearingTrades = results[4] as List<Trade>;
      final portfolioTrades = results[5] as List<Trade>;

      var runningBalance = account.initialBalance;

      // Aggregation map
      final Map<int, double> sumsByDate = {};

      // Bookings
      for (final booking in accountBookings) {
        if (originalBooking != null && booking.id == originalBooking.id) {
          continue;
        }

        final date = booking.date;
        sumsByDate[date] = (sumsByDate[date] ?? 0) + booking.amount;
      }

      // Transfers (sending)
      for (final t in sendingTransfers) {
        final date = t.date;
        sumsByDate[date] = (sumsByDate[date] ?? 0) - t.amount;
      }

      // Transfers (receiving)
      for (final t in receivingTransfers) {
        final date = t.date;
        sumsByDate[date] = (sumsByDate[date] ?? 0) + t.amount;
      }

      // Trades (regarding clearing account)
      for (final trade in clearingTrades) {
        final date = trade.datetime ~/
            1000000; // This effectively allows inconsistencies on sub-day levels but since the finest granularity we will display in visible elements is per-day, this is fine for now
        sumsByDate[date] =
            (sumsByDate[date] ?? 0) + trade.clearingAccountValueDelta;
      }

      // Trades (regarding portfolio account)
      for (final trade in portfolioTrades) {
        final date = trade.datetime ~/
            1000000; // This effectively allows inconsistencies on sub-day levels but since the finest granularity we will display in visible elements is per-day, this is fine for now
        sumsByDate[date] =
            (sumsByDate[date] ?? 0) + trade.portfolioAccountValueDelta;
      }

      // New/updated booking
      if (newBooking != null && accountId == newBooking.accountId.value) {
        final newDate = newBooking.date.value;
        sumsByDate[newDate] =
            (sumsByDate[newDate] ?? 0) + newBooking.amount.value;
      }

      // Process sorted dates
      final sortedDates = sumsByDate.keys.toList()..sort();

      for (final date in sortedDates) {
        runningBalance += sumsByDate[date]!;
        if (runningBalance < 0) return true;
      }
    }

    return false;
  }

}
