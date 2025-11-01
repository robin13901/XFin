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

  Future<void> validate(Account account) async {
    if (account.balance < 0) {
      throw Exception('Balance must be greater than or equal to 0.');
    }
    if (account.initialBalance < 0) {
      throw Exception('Initial balance must be greater than or equal to 0.');
    }
  }

  // New methods to check for references
  Future<bool> hasBookings(int accountId) async {
    final query = select(db.bookings)..where((b) => b.accountId.equals(accountId));
    return (await query.get()).isNotEmpty;
  }

  Future<bool> hasTransfers(int accountId) async {
    final query = select(db.transfers)
      ..where((t) => t.sendingAccountId.equals(accountId) | t.receivingAccountId.equals(accountId));
    return (await query.get()).isNotEmpty;
  }

  Future<bool> hasTrades(int accountId) async {
    final query = select(db.trades)
      ..where((t) => t.clearingAccountId.equals(accountId) | t.portfolioAccountId.equals(accountId));
    return (await query.get()).isNotEmpty;
  }

  Future<bool> hasPeriodicBookings(int accountId) async {
    final query = select(db.periodicBookings)..where((pb) => pb.accountId.equals(accountId));
    return (await query.get()).isNotEmpty;
  }

  Future<bool> hasPeriodicTransfers(int accountId) async {
    final query = select(db.periodicTransfers)
      ..where((pt) => pt.sendingAccountId.equals(accountId) | pt.receivingAccountId.equals(accountId));
    return (await query.get()).isNotEmpty;
  }

  Future<bool> hasGoals(int accountId) async {
    final query = select(db.goals)..where((g) => g.accountId.equals(accountId));
    return (await query.get()).isNotEmpty;
  }

  Future<bool> hasAssetsOnAccounts(int accountId) async {
    final query = select(db.assetsOnAccounts)..where((aoa) => aoa.accountId.equals(accountId));
    return (await query.get()).isNotEmpty;
  }

  // Modified and new methods for accounts
  Stream<List<Account>> watchAllAccounts() =>
      (select(db.accounts)..where((a) => a.isArchived.equals(false))).watch();

  Stream<List<Account>> watchArchivedAccounts() =>
      (select(db.accounts)..where((a) => a.isArchived.equals(true))).watch();
      
  Future<int> addAccount(AccountsCompanion entry) => into(db.accounts).insert(entry);
  
  Future<void> deleteAccount(int id) => (delete(db.accounts)..where((a) => a.id.equals(id))).go();

  Future<void> setArchived(int id, bool isArchived) {
    return (update(db.accounts)..where((a) => a.id.equals(id)))
        .write(AccountsCompanion(isArchived: Value(isArchived)));
  }

  Future<Account> getAccount(int id) =>
      (select(db.accounts)..where((a) => a.id.equals(id))).getSingle();

  /// Atomically updates the balance of an account by a given delta.
  Future<void> updateBalance(int accountId, double delta) {
    return customUpdate(
      'UPDATE accounts SET balance = balance + ? WHERE id = ?',
      variables: [Variable(delta), Variable(accountId)],
      updates: {db.accounts}, // Tell drift that the accounts table has changed.
    );
  }
}
