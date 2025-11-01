import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables.dart';

part 'accounts_dao.g.dart';

@DriftAccessor(tables: [Accounts])
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

  // Old
  Stream<List<Account>> watchAllAccounts() => select(accounts).watch();
  Future<int> addAccount(AccountsCompanion entry) => into(accounts).insert(entry);
  Future<Account> getAccount(int id) => (select(accounts)..where((a) => a.id.equals(id))).getSingle();

  /// Atomically updates the balance of an account by a given delta.
  Future<void> updateBalance(int accountId, double delta) {
    return customUpdate(
      'UPDATE accounts SET balance = balance + ? WHERE id = ?',
      variables: [Variable(delta), Variable(accountId)],
      updates: {accounts}, // Tell drift that the accounts table has changed.
    );
  }
}
