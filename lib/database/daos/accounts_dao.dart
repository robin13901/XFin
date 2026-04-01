import 'dart:math';

import 'package:drift/drift.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/filter/filter_rule.dart';
import '../../utils/global_constants.dart';
import '../../utils/format.dart';
import '../app_database.dart';
import '../filter_builder.dart';
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

  Future<void> createAccount(
      AccountsCompanion account, List<AssetOnAccount> pendingAOAs) {
    return transaction(() async {
      final initialBalance =
          pendingAOAs.fold<double>(0.0, (sum, pa) => sum + pa.value);
      account = account.copyWith(
          initialBalance: Value(normalize(initialBalance)),
          balance: Value(normalize(initialBalance)));
      final accountId = await insert(account);

      for (var aoa in pendingAOAs) {
        aoa = aoa.copyWith(accountId: accountId);
        await db.assetsOnAccountsDao.updateAOA(aoa);
        await db.assetsDao.updateAsset(aoa.assetId, aoa.shares, aoa.value, 0);
      }
    });
  }

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

  Stream<List<Account>> watchAllAccounts({
    String? searchQuery,
    List<FilterRule>? filterRules,
  }) {
    final query = select(accounts)..where((a) => a.isArchived.equals(false));

    // Apply filter rules
    if (filterRules != null && filterRules.isNotEmpty) {
      final builder = AccountFilterBuilder(accounts);
      final filterExpr = builder.buildExpression(filterRules);
      if (filterExpr != null) {
        query.where((t) => filterExpr);
      }
    }

    return query.watch().map((results) {
      // Apply search query post-filter
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final searchLower = searchQuery.toLowerCase();
        return results
            .where((a) => a.name.toLowerCase().contains(searchLower))
            .toList();
      }
      return results;
    });
  }

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
        await db.assetsDao.updateAsset(aoa.assetId, -aoa.shares, -aoa.value, 0);
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
      final sendingTransfersFuture = (select(transfers)
            ..where((t) => t.sendingAccountId.equals(accountId)))
          .get();
      final receivingTransfersFuture = (select(transfers)
            ..where((t) => t.receivingAccountId.equals(accountId)))
          .get();
      final clearingTradesFuture = (select(trades)
            ..where((t) => t.sourceAccountId.equals(accountId)))
          .get();
      final portfolioTradesFuture = (select(trades)
            ..where((t) => t.targetAccountId.equals(accountId)))
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
          final sourceAccountValueDelta =
              newTrade.sourceAccountValueDelta.value;
          sumsByDate[newDate] =
              (sumsByDate[newDate] ?? 0) + sourceAccountValueDelta;
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

  Future<List<(int date, double delta)>> getBalanceDeltasByDate(int accountId) {
    return customSelect(
      '''
    SELECT date, SUM(delta) AS delta
    FROM (
      SELECT date, value AS delta
      FROM bookings
      WHERE account_id = ?

      UNION ALL

      SELECT date,
             CASE
               WHEN sending_account_id = ? THEN -value
               ELSE value
             END
      FROM transfers
      WHERE sending_account_id = ?
         OR receiving_account_id = ?

      UNION ALL

      SELECT datetime / 1000000 AS date,
             CASE
               WHEN source_account_id = ?
                 THEN source_account_value_delta
               ELSE target_account_value_delta
             END
      FROM trades
      WHERE source_account_id = ?
         OR target_account_id = ?
    )
    GROUP BY date
    ORDER BY date
    ''',
      variables: [
        Variable.withInt(accountId),
        Variable.withInt(accountId),
        Variable.withInt(accountId),
        Variable.withInt(accountId),
        Variable.withInt(accountId),
        Variable.withInt(accountId),
        Variable.withInt(accountId),
      ],
      readsFrom: {bookings, transfers, trades},
    ).map((row) {
      return (row.read<int>('date'), row.read<double>('delta'));
    }).get();
  }

  Future<bool> isInconsistent(int accountId) {
    return transaction(() async {
      final account = await getAccount(accountId);
      final deltas = await db.accountsDao.getBalanceDeltasByDate(accountId);

      var runningBalance = account.initialBalance;
      for (final (_, delta) in deltas) {
        runningBalance += delta;
        if (runningBalance < -1e-9) {
          return true;
        }
      }

      return false;
    });
  }

  Future<AccountDetailsData> getAccountDetails(int accountId) async {
    final futures = await Future.wait([
      getAccount(accountId),
      getBalanceDeltasByDate(accountId),
      (select(bookings)..where((b) => b.accountId.equals(accountId))).get(),
      (select(transfers)
            ..where((t) =>
                t.sendingAccountId.equals(accountId) |
                t.receivingAccountId.equals(accountId)))
          .get(),
      (select(trades)
            ..where((t) =>
                t.sourceAccountId.equals(accountId) |
                t.targetAccountId.equals(accountId)))
          .get(),
      db.assetsOnAccountsDao.getAOAsForAccount(accountId),
      db.assetsDao.getAllAssets(),
    ]);

    final account = futures[0] as Account;
    final deltas = futures[1] as List<(int date, double delta)>;
    final accountBookings = futures[2] as List<Booking>;
    final accountTransfers = futures[3] as List<Transfer>;
    final accountTrades = futures[4] as List<Trade>;
    final aoas = futures[5] as List<AssetOnAccount>;
    final allAssets = futures[6] as List<Asset>;

    // Build balance history
    final balanceHistory = _buildBalanceHistory(account, deltas);

    // Build asset holdings (include all assets with shares)
    final assetMap = {for (final a in allAssets) a.id: a};
    final assetHoldings = aoas
        .where((aoa) => aoa.shares.abs() > 1e-9)
        .map((aoa) => AccountAssetHolding(
              label: assetMap[aoa.assetId]?.name ?? 'Asset ${aoa.assetId}',
              value: aoa.value,
              assetId: aoa.assetId,
            ))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Calculate statistics
    final totalInflows = accountBookings
            .where((b) => b.value > 0)
            .fold(0.0, (s, b) => s + b.value) +
        accountTransfers
            .where((t) => t.receivingAccountId == accountId)
            .fold(0.0, (s, t) => s + t.value) +
        accountTrades
            .where((t) =>
                t.sourceAccountId == accountId && t.sourceAccountValueDelta > 0)
            .fold(0.0, (s, t) => s + t.sourceAccountValueDelta) +
        accountTrades
            .where((t) =>
                t.targetAccountId == accountId && t.targetAccountValueDelta > 0)
            .fold(0.0, (s, t) => s + t.targetAccountValueDelta);
    final totalOutflows = accountBookings
            .where((b) => b.value < 0)
            .fold(0.0, (s, b) => s + b.value) +
        accountTransfers
            .where((t) => t.sendingAccountId == accountId)
            .fold(0.0, (s, t) => s - t.value) +
        accountTrades
            .where((t) =>
        t.sourceAccountId == accountId && t.sourceAccountValueDelta < 0)
            .fold(0.0, (s, t) => s + t.sourceAccountValueDelta) +
        accountTrades
            .where((t) =>
        t.targetAccountId == accountId && t.targetAccountValueDelta < 0)
            .fold(0.0, (s, t) => s + t.targetAccountValueDelta);

    final totalVolume = totalInflows - totalOutflows;

    // Event frequency calculation
    final firstTs = balanceHistory.first.x.toInt();
    final lastTs = balanceHistory.last.x.toInt();
    final monthSpan =
        max(1.0, (lastTs - firstTs) / const Duration(days: 30).inMilliseconds);
    final eventCount =
        accountBookings.length + accountTransfers.length + accountTrades.length;

    return AccountDetailsData(
      account: account,
      balanceHistory: balanceHistory,
      bookingCount: accountBookings.length,
      transferCount: accountTransfers.length,
      tradeCount: accountTrades.length,
      totalInflows: totalInflows,
      totalOutflows: totalOutflows,
      totalVolume: totalVolume,
      netChange: account.balance - account.initialBalance,
      eventFrequency: eventCount / monthSpan,
      assetHoldings: assetHoldings,
    );
  }

  List<FlSpot> _buildBalanceHistory(
      Account account, List<(int date, double delta)> deltas) {
    final history = <FlSpot>[];

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (deltas.isEmpty) {
      history.add(
          FlSpot(today.millisecondsSinceEpoch.toDouble(), account.balance));
      return history;
    }

    // Build a map keyed by millisecondsSinceEpoch (avoids DateTime
    // equality pitfalls with DST) from each delta's date.
    final Map<int, double> deltaByMs = {};
    for (final (dateInt, delta) in deltas) {
      final d = intToDateTime(dateInt)!;
      final ms = DateTime(d.year, d.month, d.day).millisecondsSinceEpoch;
      deltaByMs[ms] = (deltaByMs[ms] ?? 0) + delta;
    }

    // Determine the first date with a delta.
    final firstDelta = deltas.first; // deltas are ORDER BY date ASC from SQL
    final fd = intToDateTime(firstDelta.$1)!;
    final firstDate = DateTime(fd.year, fd.month, fd.day);

    // Walk forward from initialBalance, applying deltas on their date.
    double runningBalance = account.initialBalance;

    for (var date = firstDate;
        !date.isAfter(today);
        date = DateTime(date.year, date.month, date.day + 1)) {
      final ms = date.millisecondsSinceEpoch;
      final delta = deltaByMs[ms];
      if (delta != null) {
        runningBalance += delta;
      }
      history.add(FlSpot(ms.toDouble(), normalize(runningBalance)));
    }

    return history;
  }
}

class AccountDetailsData {
  final Account account;
  final List<FlSpot> balanceHistory;
  final int bookingCount;
  final int transferCount;
  final int tradeCount;
  final double totalInflows;
  final double totalOutflows;
  final double totalVolume;
  final double netChange;
  final double eventFrequency;
  final List<AccountAssetHolding> assetHoldings;

  const AccountDetailsData({
    required this.account,
    required this.balanceHistory,
    required this.bookingCount,
    required this.transferCount,
    required this.tradeCount,
    required this.totalInflows,
    required this.totalOutflows,
    required this.totalVolume,
    required this.netChange,
    required this.eventFrequency,
    required this.assetHoldings,
  });
}

class AccountAssetHolding {
  final String label;
  final double value;
  final int assetId;

  const AccountAssetHolding({
    required this.label,
    required this.value,
    required this.assetId,
  });
}
