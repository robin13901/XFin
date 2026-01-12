import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:xfin/l10n/app_localizations.dart';
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
        await db.assetsDao.updateAsset(aoa.assetId, -aoa.shares, -aoa.value, 0);
        await db.assetsOnAccountsDao.deleteAOA(aoa);
      }
    });
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

// --- TEMP: DB REBUILD --------------------------------------------------------
  Future<void> insertAllEventsFromCsv(AppLocalizations l10n) {
    return transaction(() async {
      List<BookingsCompanion> bookings = parseBookings();
      List<TransfersCompanion> transfers = parseTransfers();
      List<TradesCompanion> trades = parseTrades();

      int totalEvents = bookings.length + transfers.length + trades.length;
      int successfulEvents = 0;

      while (bookings.isNotEmpty || transfers.isNotEmpty || trades.isNotEmpty) {
        int nextBookingDatetime = bookings.isNotEmpty
            ? bookings.first.date.value * 1000000
            : 99999999999999;
        int nextTransferDatetime = transfers.isNotEmpty
            ? transfers.first.date.value * 1000000
            : 99999999999999;
        int nextTradeDatetime =
            trades.isNotEmpty ? trades.first.datetime.value : 99999999999999;

        int nextKey = nextBookingDatetime <= nextTransferDatetime &&
                nextBookingDatetime <= nextTradeDatetime
            ? 1
            : nextTransferDatetime <= nextTradeDatetime
                ? 2
                : 3;

        if (nextKey == 1) {
          BookingsCompanion bookingToInsert = bookings.removeAt(0);
          await db.bookingsDao.createBooking(bookingToInsert, l10n);
        } else if (nextKey == 2) {
          TransfersCompanion transferToInsert = transfers.removeAt(0);
          await db.transfersDao.createTransfer(transferToInsert, l10n);
        } else {
          TradesCompanion tradeToInsert = trades.removeAt(0);
          await db.tradesDao.insertTrade(tradeToInsert, l10n);
        }
        successfulEvents++;
        if (kDebugMode) {
          print('Successfully inserted $successfulEvents/$totalEvents events.');
        }
      }
    });
  }

  Future<void> insertAssetsFromCsv() {
    return transaction(() async {
      List<String> rows = assetsCsv.split('\n');
      rows.removeLast();
      for (final row in rows) {
        final fields = row.split(';');
        db.assetsDao.insert(AssetsCompanion(
            name: Value(fields[0]),
            type: Value(const AssetTypesConverter().fromSql(fields[1])),
            tickerSymbol:
                fields[2] == "" ? const Value.absent() : Value(fields[2]),
            currencySymbol: Value(fields[3])));
      }
    });
  }

  Future<void> insertAccountsFromCsv(String accountsCsv) {
    return transaction(() async {
      List<String> rows = accountsCsv.split('\n');
      rows.removeLast();
      for (final row in rows) {
        final fields = row.split(';');
        AccountsCompanion account = AccountsCompanion(
            name: Value(fields[0]),
            type: Value(const AccountTypesConverter().fromSql(fields[1])),
            isArchived: Value(fields[3] == "1"));
        List<AssetOnAccount> pendingAOAs = [
          AssetOnAccount(
            accountId: 0,
            assetId: 1,
            value: normalize(double.parse(fields[2])),
            shares: normalize(double.parse(fields[2])),
            netCostBasis: 1,
            brokerCostBasis: 1,
            buyFeeTotal: 0,
          )
        ];
        db.accountsDao.createAccount(account, pendingAOAs);
      }
    });
  }

  List<BookingsCompanion> parseBookings() {
    List<BookingsCompanion> bookings = [];
    List<String> rows = bookingsCsv.split('\n');
    rows.removeLast();
    for (final row in rows) {
      final fields = row.split(';');
      bookings.add(BookingsCompanion(
        date: Value(int.parse(fields[0])),
        assetId: Value(int.parse(fields[1])),
        accountId: Value(int.parse(fields[2])),
        category: Value(fields[3]),
        shares: Value(normalize(double.parse(fields[4]))),
        costBasis: double.parse(fields[4]) < 0
            ? const Value.absent()
            : Value(normalize(double.parse(fields[5]))),
        // we want to recalculate this for withdrawals
        value: Value(normalize(double.parse(fields[6]))),
        notes: fields[7] == "" ? const Value.absent() : Value(fields[7]),
        excludeFromAverage: Value(fields[8] == '1'),
        isGenerated: Value(fields[9] == '1'),
      ));
    }
    return bookings;
  }

  List<TransfersCompanion> parseTransfers() {
    List<TransfersCompanion> transfers = [];
    List<String> rows = transfersCsv.split('\n');
    rows.removeLast();
    for (final row in rows) {
      final fields = row.split(';');
      transfers.add(TransfersCompanion(
        date: Value(int.parse(fields[0])),
        sendingAccountId: Value(int.parse(fields[1])),
        receivingAccountId: Value(int.parse(fields[2])),
        assetId: Value(int.parse(fields[3])),
        shares: Value(normalize(double.parse(fields[4]))),
        costBasis: const Value.absent(),
        // we want to recalculate this
        value: const Value.absent(),
        // we want to recalculate this
        notes: fields[7] == "" ? const Value.absent() : Value(fields[7]),
        isGenerated: Value(fields[8] == '1'),
      ));
    }
    return transfers;
  }

  List<TradesCompanion> parseTrades() {
    List<TradesCompanion> trades = [];
    List<String> rows = tradesCsv.split('\n');
    rows.removeLast();
    for (final row in rows) {
      final fields = row.split(';');
      trades.add(TradesCompanion(
        datetime: Value(int.parse(fields[0])),
        type: Value(const TradeTypesConverter().fromSql(fields[1])),
        sourceAccountId: Value(int.parse(fields[2])),
        targetAccountId: Value(int.parse(fields[3])),
        assetId: Value(int.parse(fields[4])),
        shares: Value(normalize(double.parse(fields[5]))),
        costBasis: Value(normalize(double.parse(fields[6]))),
        fee: Value(normalize(double.parse(fields[7]))),
        tax: Value(normalize(double.parse(fields[8]))),
        // recalculate all other fields
      ));
    }
    return trades;
  }

  static const assetsCsv = '''
''';
  static const accountsCsv1 = '''
Portemonnaie;cash;4.0;0
Kiste;cash;1020.0;0
Sparkassenkonto;bankAccount;1122.85;0
Flasche;cash;875.25;0
Geburtstagsgeschenk;bankAccount;6371.57;0
DiBa Konto;bankAccount;12049.26;0
Trade Republic Konto;bankAccount;0.0;0
Trade Republic Depot;portfolio;0.0;0
Deka Depot;portfolio;0.0;0
EquatePlus;portfolio;0.0;0
Bitget Spot;portfolio;0.0;0
C24 Girokonto;bankAccount;0.0;0
Scalable Capital;portfolio;0.0;0
''';
  static const accountsCsv2 = '''
Ledger Nano X;cryptoWallet;0.0;0
''';
  static const bookingsCsv = '''
''';
  static const transfersCsv = '''
''';
  static const tradesCsv = '''
''';

  static const assetsQuery = '''
  select name, type, ticker_symbol, currency_symbol from assets where id <> 1;
''';
  static const accountsQuery = '''
  select name, type, initial_balance, is_archived from accounts where name <> 'Währungssammlung';
''';
  static const bookingsQuery = '''
  select date, asset_id, account_id, category, shares, cost_basis, value, notes, exclude_from_average, is_generated from bookings order by date, value;
''';
  static const transfersQuery = '''
  select date, sending_account_id, receiving_account_id, asset_id, shares, cost_basis, value, notes, is_generated from transfers order by date, value;
''';
  static const tradesQuery = '''
  select datetime, type, source_account_id, target_account_id, asset_id, shares, cost_basis, fee, tax from trades order by datetime, type, shares*cost_basis;
''';
// -----------------------------------------------------------------------------
}
