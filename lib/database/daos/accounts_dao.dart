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
        await db.assetsDao
            .updateBaseCurrencyAsset(account.initialBalance.value);

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

}
