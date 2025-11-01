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
class AccountsDao extends DatabaseAccessor<AppDatabase> with _$AccountsDaoMixin {
  AccountsDao(super.db);

  Future<bool> hasBookings(int accountId) async {
    final query = select(bookings)..where((b) => b.accountId.equals(accountId));
    return (await query.get()).isNotEmpty;
  }

  Future<bool> hasTransfers(int accountId) async {
    final query = select(transfers)
      ..where((t) => t.sendingAccountId.equals(accountId) | t.receivingAccountId.equals(accountId));
    return (await query.get()).isNotEmpty;
  }

  Future<bool> hasTrades(int accountId) async {
    final query = select(trades)
      ..where((t) => t.clearingAccountId.equals(accountId) | t.portfolioAccountId.equals(accountId));
    return (await query.get()).isNotEmpty;
  }

  Future<bool> hasPeriodicBookings(int accountId) async {
    final query = select(periodicBookings)..where((pb) => pb.accountId.equals(accountId));
    return (await query.get()).isNotEmpty;
  }

  Future<bool> hasPeriodicTransfers(int accountId) async {
    final query = select(periodicTransfers)
      ..where((pt) => pt.sendingAccountId.equals(accountId) | pt.receivingAccountId.equals(accountId));
    return (await query.get()).isNotEmpty;
  }

  Future<bool> hasGoals(int accountId) async {
    final query = select(goals)..where((g) => g.accountId.equals(accountId));
    return (await query.get()).isNotEmpty;
  }

  Future<bool> hasAssetsOnAccounts(int accountId) async {
    final query = select(assetsOnAccounts)..where((aoa) => aoa.accountId.equals(accountId));
    return (await query.get()).isNotEmpty;
  }

  Stream<List<Account>> watchAllAccounts() =>
      (select(accounts)..where((a) => a.isArchived.equals(false))).watch();

  Stream<List<Account>> watchArchivedAccounts() =>
      (select(accounts)..where((a) => a.isArchived.equals(true))).watch();
      
  Future<int> addAccount(AccountsCompanion entry) => into(accounts).insert(entry);
  
  Future<void> deleteAccount(int id) => (delete(accounts)..where((a) => a.id.equals(id))).go();

  Future<void> setArchived(int id, bool isArchived) {
    return (update(accounts)..where((a) => a.id.equals(id)))
        .write(AccountsCompanion(isArchived: Value(isArchived)));
  }

  Future<Account> getAccount(int id) =>
      (select(accounts)..where((a) => a.id.equals(id))).getSingle();

  Future<void> updateBalance(int accountId, double delta) {
    return customUpdate(
      'UPDATE accounts SET balance = balance + ? WHERE id = ?',
      variables: [Variable(delta), Variable(accountId)],
      updates: {accounts},
    );
  }
}
