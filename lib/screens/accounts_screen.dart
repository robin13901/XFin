import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:xfin/database/app_database.dart';
import 'package:xfin/database/tables.dart';
import 'package:xfin/widgets/account_form.dart';

class AccountsScreen extends StatelessWidget {
  const AccountsScreen({super.key});

  void _showAccountForm(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const AccountForm(),
    );
  }

  Future<void> _handleLongPress(
      BuildContext context, AppDatabase db, Account account) async {
    bool hasReferences = false;
    if (account.type == AccountTypes.cash) {
      final hasBookings = await db.accountsDao.hasBookings(account.id);
      final hasTransfers = await db.accountsDao.hasTransfers(account.id);
      final hasTrades = await db.accountsDao.hasTrades(account.id);
      final hasPeriodicBookings =
          await db.accountsDao.hasPeriodicBookings(account.id);
      final hasPeriodicTransfers =
          await db.accountsDao.hasPeriodicTransfers(account.id);
      final hasGoals = await db.accountsDao.hasGoals(account.id);
      hasReferences = hasBookings ||
          hasTransfers ||
          hasTrades ||
          hasPeriodicBookings ||
          hasPeriodicTransfers ||
          hasGoals;
    } else if (account.type == AccountTypes.portfolio) {
      final hasAssetsOnAccounts =
          await db.accountsDao.hasAssetsOnAccounts(account.id);
      final hasTrades = await db.accountsDao.hasTrades(account.id);
      final hasGoals = await db.accountsDao.hasGoals(account.id);
      hasReferences = hasAssetsOnAccounts || hasTrades || hasGoals;
    }

    if (!context.mounted) return;

    if (hasReferences) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Cannot Delete Account'),
          content: const Text(
              'This account has references and cannot be deleted. Would you like to archive it instead?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                db.accountsDao.setArchived(account.id, true);
                Navigator.of(context).pop();
              },
              child: const Text('Archive'),
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Account'),
          content: const Text('Are you sure you want to delete this account?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                db.accountsDao.deleteAccount(account.id);
                Navigator.of(context).pop();
              },
              child: const Text('Confirm'),
            ),
          ],
        ),
      );
    }
  }

  void _handleArchivedAccountTap(
      BuildContext context, AppDatabase db, Account account) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unarchive Account'),
        content: const Text('Do you want to unarchive this account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              db.accountsDao.setArchived(account.id, false);
              Navigator.of(context).pop();
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<AppDatabase>(context);
    final currencyFormat = NumberFormat.currency(locale: 'de_DE', symbol: '€');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Accounts'),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Account>>(
              stream: db.accountsDao.watchAllAccounts(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final accounts = snapshot.data ?? [];
                if (accounts.isEmpty) {
                  return const Center(
                      child: Text('No active accounts yet. Tap + to add one!'));
                }

                return ListView.builder(
                  itemCount: accounts.length,
                  itemBuilder: (context, index) {
                    final account = accounts[index];
                    return ListTile(
                      title: Text(account.name),
                      trailing: Text(
                        currencyFormat.format(account.balance),
                        style: TextStyle(
                          color: account.balance < 0 ? Colors.red : Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onTap: () {
                        // TODO: Navigate to account analysis screen.
                      },
                      onLongPress: () => _handleLongPress(context, db, account),
                    );
                  },
                );
              },
            ),
          ),
          StreamBuilder<List<Account>>(
              stream: db.accountsDao.watchArchivedAccounts(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox.shrink();
                }
                if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                  return const SizedBox.shrink();
                }

                final archivedAccounts = snapshot.data!;

                return ExpansionTile(
                  title: const Text('Archived Accounts'),
                  children: [
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: archivedAccounts.length,
                      itemBuilder: (context, index) {
                        final account = archivedAccounts[index];
                        return ListTile(
                          title: Text(account.name),
                          trailing: Text(
                            currencyFormat.format(account.balance),
                            style: TextStyle(
                              color:
                                  account.balance < 0 ? Colors.red : Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onTap: () =>
                              _handleArchivedAccountTap(context, db, account),
                        );
                      },
                    ),
                  ],
                );
              }),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAccountForm(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
