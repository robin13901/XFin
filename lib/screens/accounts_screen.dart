import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:xfin/database/app_database.dart';
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

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<AppDatabase>(context);
    final currencyFormat = NumberFormat.currency(locale: 'de_DE', symbol: '€');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Accounts'),
      ),
      body: StreamBuilder<List<Account>>(
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
            return const Center(child: Text('No accounts yet. Tap + to add one!'));
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
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAccountForm(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
