import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xfin/database/app_database.dart';
import 'package:xfin/l10n/app_localizations.dart';
import 'package:xfin/widgets/account_form.dart';

import '../providers/base_currency_provider.dart';
import '../widgets/liquid_glass_widgets.dart';

class AccountsScreen extends StatelessWidget {
  const AccountsScreen({super.key});

  static void showAccountForm(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const AccountForm(),
    );
  }

  Future<void> _handleLongPress(
    BuildContext context,
    AppDatabase db,
    Account account,
    AppLocalizations l10n,
  ) async {
    bool deletionProhibited = true;

    final hasBookings = await db.accountsDao.hasBookings(account.id);
    final hasTransfers = await db.accountsDao.hasTransfers(account.id);
    final hasTrades = await db.accountsDao.hasTrades(account.id);
    final hasPeriodicBookings =
        await db.accountsDao.hasPeriodicBookings(account.id);
    final hasPeriodicTransfers =
        await db.accountsDao.hasPeriodicTransfers(account.id);
    final hasGoals = await db.accountsDao.hasGoals(account.id);

    deletionProhibited = hasBookings ||
        hasTransfers ||
        hasTrades ||
        hasPeriodicBookings ||
        hasPeriodicTransfers ||
        hasGoals;

    if (!context.mounted) return;

    if (deletionProhibited) {
      if (account.balance > 0) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l10n.cannotDeleteOrArchiveAccount),
            content: Text(l10n.cannotDeleteOrArchiveAccountLong),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.ok),
              ),
            ],
          ),
        );
      } else {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l10n.cannotDeleteAccount),
            content: Text(l10n.accountHasReferencesArchiveInstead),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.cancel),
              ),
              TextButton(
                onPressed: () {
                  db.accountsDao.setArchived(account.id, true);
                  Navigator.of(context).pop();
                },
                child: Text(l10n.archive),
              ),
            ],
          ),
        );
      }
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.deleteAccount),
          content: Text(l10n.confirmDeleteAccount),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () {
                db.accountsDao.deleteAccount(account.id);
                Navigator.of(context).pop();
              },
              child: Text(l10n.confirm),
            ),
          ],
        ),
      );
    }
  }

  void _handleArchivedAccountTap(BuildContext context, AppDatabase db,
      Account account, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.unarchiveAccount),
        content: Text(l10n.confirmUnarchiveAccount),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              db.accountsDao.setArchived(account.id, false);
              Navigator.of(context).pop();
            },
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<AppDatabase>(context);
    final l10n = AppLocalizations.of(context)!;
    final currencyProvider = Provider.of<BaseCurrencyProvider>(context);

    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: StreamBuilder<List<Account>>(
                  stream: db.accountsDao.watchAllAccounts(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(
                          child: Text(l10n.error(snapshot.error.toString())));
                    }
                    final accounts = snapshot.data ?? [];
                    if (accounts.isEmpty) {
                      return Center(child: Text(l10n.noActiveAccounts));
                    }

                    return ListView.builder(
                      padding: EdgeInsets.only(
                        top:
                        MediaQuery.of(context).padding.top + kToolbarHeight,
                        bottom: 92,
                      ),
                      itemCount: accounts.length,
                      itemBuilder: (context, index) {
                        final account = accounts[index];
                        return ListTile(
                          title: Text(account.name),
                          trailing: Text(
                            currencyProvider.format.format(account.balance),
                            style: TextStyle(
                              color: account.balance < 0
                                  ? Colors.red
                                  : Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onTap: () {
                            // TODO: Navigate to account analysis screen.
                          },
                          onLongPress: () =>
                              _handleLongPress(context, db, account, l10n),
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
                    if (snapshot.hasError ||
                        !snapshot.hasData ||
                        snapshot.data!.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    final archivedAccounts = snapshot.data!;

                    return ExpansionTile(
                      title: Text(l10n.archivedAccounts),
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
                                currencyProvider.format.format(account.balance),
                                style: TextStyle(
                                  color: account.balance < 0
                                      ? Colors.red
                                      : Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              onTap: () => _handleArchivedAccountTap(
                                  context, db, account, l10n),
                            );
                          },
                        ),
                      ],
                    );
                  }),
            ],
          ),
          buildLiquidGlassAppBar(context, title: Text(l10n.accounts)),
        ],
      ),
    );
  }
}
