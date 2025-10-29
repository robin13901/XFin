import 'package:drift/drift.dart';
import 'package:xfin/database/app_database.dart';
import 'package:xfin/database/tables.dart';

part 'accounts_dao.g.dart';

@DriftAccessor(tables: [Accounts])
class AccountsDao extends DatabaseAccessor<AppDatabase> with _$AccountsDaoMixin {
  AccountsDao(super.db);

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
