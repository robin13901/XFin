import 'package:drift/drift.dart';
import '../../utils/global_constants.dart';
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

  Future<int> insert(AccountsCompanion entry) => into(accounts).insert(entry);

  Future<bool> _updateAccount(AccountsCompanion entry) =>
      update(accounts).replace(entry);

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
          t.sourceAccountId.equals(accountId) |
          t.targetAccountId.equals(accountId));
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

  Future<void> updateBalance(int accountId, double delta) async {
    Account a = await getAccount(accountId);
    double newBalance = a.balance + delta;
    Account modifiedAccount = a.copyWith(balance: normalize(newBalance));
    await _updateAccount(modifiedAccount.toCompanion(false));
  }

  Future<void> setArchived(int id, bool isArchived) {
    return (update(accounts)..where((a) => a.id.equals(id)))
        .write(AccountsCompanion(isArchived: Value(isArchived)));
  }

  Future<void> _deleteAccount(int id) =>
      (delete(accounts)..where((a) => a.id.equals(id))).go();

  Future<void> deleteAccount(int id) {
    return transaction(() async {
      await _deleteAccount(id);

      final List<AssetOnAccount> allAOAs =
          await db.assetsOnAccountsDao.getAOAsForAccount(id);

      for (var aoa in allAOAs) {
        await db.assetsDao
            .updateAsset(aoa.assetId, -aoa.shares, -aoa.value);
        await db.assetsOnAccountsDao.deleteAOA(aoa);
      }
    });
  }

  Future<bool> leadsToInconsistentBalanceHistory({
    int? accountId,
    Booking? originalBooking,
    BookingsCompanion? newBooking,
    Trade? originalTrade,
    TradesCompanion? newTrade,
    Transfer? originalTransfer,
    TransfersCompanion? newTransfer,
  }) async {
    Set<int> accountIds = {};
    if (accountId != null) accountIds.add(accountId);
    if (originalBooking != null) accountIds.add(originalBooking.accountId);
    if (newBooking != null) accountIds.add(newBooking.accountId.value);
    if (originalTrade != null) {
      accountIds.add(originalTrade.sourceAccountId);
      accountIds.add(originalTrade.targetAccountId);
    }
    if (newTrade != null) {
      accountIds.add(newTrade.sourceAccountId.value);
      accountIds.add(newTrade.targetAccountId.value);
    }
    if (originalTransfer != null) {
      accountIds.add(originalTransfer.sendingAccountId);
      accountIds.add(originalTransfer.receivingAccountId);
    }
    if (newTransfer != null) {
      accountIds.add(newTransfer.sendingAccountId.value);
      accountIds.add(newTransfer.receivingAccountId.value);
    }

    for (var accountId in accountIds) {
      // Launch DB queries in parallel
      final accountFuture = getAccount(accountId);
      final bookingsFuture =
      (select(bookings)..where((b) => b.accountId.equals(accountId))).get();
      final sendingTransfersFuture =
      (select(transfers)..where((t) => t.sendingAccountId.equals(accountId))).get();
      final receivingTransfersFuture =
      (select(transfers)..where((t) => t.receivingAccountId.equals(accountId))).get();
      final clearingTradesFuture =
      (select(trades)..where((t) => t.sourceAccountId.equals(accountId))).get();
      final portfolioTradesFuture =
      (select(trades)..where((t) => t.targetAccountId.equals(accountId))).get();

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

      // Aggregation map keyed by date-int (yyyyMMdd for bookings/transfers, truncated for trades)
      final Map<int, double> sumsByDate = {};

      // Bookings
      for (final b in accountBookings) {
        if (originalBooking != null && b.id == originalBooking.id) continue;
        final date = b.date;
        sumsByDate[date] = (sumsByDate[date] ?? 0) + b.value;
      }

      // Transfers (sending) — subtract
      for (final t in sendingTransfers) {
        if (originalTransfer != null && t.id == originalTransfer.id) continue;
        final date = t.date;
        sumsByDate[date] = (sumsByDate[date] ?? 0) - t.value;
      }

      // Transfers (receiving) — add
      for (final t in receivingTransfers) {
        if (originalTransfer != null && t.id == originalTransfer.id) continue;
        final date = t.date;
        sumsByDate[date] = (sumsByDate[date] ?? 0) + t.value;
      }

      // Trades (regarding clearing account)
      for (final t in clearingTrades) {
        if (originalTrade != null && t.id == originalTrade.id) continue;
        final date = t.datetime ~/ 1000000;
        sumsByDate[date] = (sumsByDate[date] ?? 0) + t.sourceAccountValueDelta;
      }

      // Trades (regarding portfolio account)
      for (final t in portfolioTrades) {
        // if (originalTrade != null && t.id == originalTrade.id) continue; // TODO figure out
        final date = t.datetime ~/ 1000000;
        sumsByDate[date] = (sumsByDate[date] ?? 0) + t.targetAccountValueDelta;
      }

      // New/updated booking
      if (newBooking != null && accountId == newBooking.accountId.value) {
        final newDate = newBooking.date.value;
        sumsByDate[newDate] =
            (sumsByDate[newDate] ?? 0) + newBooking.value.value;
      }

      // New/updated transfer — apply to sending (subtract) and receiving (add)
      if (newTransfer != null) {
        final newDate = newTransfer.date.value;
        final newBase = newTransfer.value.value;
        if (accountId == newTransfer.sendingAccountId.value) {
          sumsByDate[newDate] = (sumsByDate[newDate] ?? 0) - newBase;
        }
        if (accountId == newTransfer.receivingAccountId.value) {
          sumsByDate[newDate] = (sumsByDate[newDate] ?? 0) + newBase;
        }
      }

      // New trade — apply to clearing and portfolio
      if (newTrade != null) {
        final newDate = newTrade.datetime.value ~/ 1000000;
        if (accountId == newTrade.sourceAccountId.value) {
          final sourceAccountValueDelta = newTrade.sourceAccountValueDelta.value;
          sumsByDate[newDate] = (sumsByDate[newDate] ?? 0) + sourceAccountValueDelta;
        }
        // if (accountId == newTrade.targetAccountId.value) { // TODO figure out
        //   final targetAccountValueDelta = newTrade.targetAccountValueDelta.value;
        //   sumsByDate[newDate] = (sumsByDate[newDate] ?? 0) + targetAccountValueDelta;
        // }
      }

      // Process sorted dates
      final sortedDates = sumsByDate.keys.toList()..sort();

      for (final date in sortedDates) {
        runningBalance += sumsByDate[date]!;
        if (runningBalance < -0.00001) {
          return true;
        }
      }
    }

    return false;
  }

}
