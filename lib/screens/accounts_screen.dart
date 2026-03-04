import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xfin/database/app_database.dart';
import 'package:xfin/l10n/app_localizations.dart';
import 'package:xfin/widgets/forms/account_form.dart';

import '../models/filter/account_filter_config.dart';
import '../models/filter/filter_rule.dart';
import '../providers/base_currency_provider.dart';
import '../providers/database_provider.dart';
import '../utils/format.dart';
import '../utils/modal_helper.dart';
import '../widgets/dialogs.dart';
import '../widgets/filter/filter_badge.dart';
import '../widgets/filter/filter_panel.dart';
import '../widgets/filter/liquid_glass_search_bar.dart';
import '../widgets/liquid_glass_widgets.dart';
import 'account_detail_screen.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  static void showAccountForm(BuildContext context) {
    showFormModal(context, const AccountForm());
  }

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  // Search state
  bool _showSearchBar = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _searchDebounce;
  final FocusNode _searchFocusNode = FocusNode();

  // Filter state
  List<FilterRule> _filterRules = [];
  bool _showFilterPanel = false;

  int get _activeFilterCount => _filterRules.length;

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebounce?.cancel();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (_searchQuery != value) {
        setState(() => _searchQuery = value);
      }
    });
  }

  void _toggleSearch() {
    setState(() {
      _showSearchBar = !_showSearchBar;
      if (!_showSearchBar) {
        _searchController.clear();
        if (_searchQuery.isNotEmpty) {
          _searchQuery = '';
        }
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _searchFocusNode.requestFocus();
        });
      }
    });
  }

  void _onFilterRulesChanged(List<FilterRule> rules) {
    setState(() => _filterRules = rules);
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
      showDeleteDialog(context, account: account);
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
    final db = context.read<DatabaseProvider>().db;
    final l10n = AppLocalizations.of(context)!;
    Provider.of<BaseCurrencyProvider>(context);
    final statusBarHeight = MediaQuery.of(context).padding.top;
    // Add space for search bar only when visible
    final searchBarSpace = _showSearchBar ? 60.0 : 0.0;

    return Scaffold(
      body: Stack(
        children: [
          StreamBuilder<List<Account>>(
            stream: db.accountsDao.watchAllAccounts(
              searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
              filterRules: _filterRules.isNotEmpty ? _filterRules : null,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                showErrorDialog(context, l10n.errorLoadingData);
              }
              final accounts = snapshot.data ?? [];

              return ListView(
                padding: EdgeInsets.only(
                  top: statusBarHeight + kToolbarHeight + searchBarSpace,
                  bottom: 92,
                ),
                children: [
                  if (accounts.isEmpty)
                    Center(
                        child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        _searchQuery.isNotEmpty || _filterRules.isNotEmpty
                            ? l10n.noMatchingBookings
                            : l10n.noActiveAccounts,
                      ),
                    ))
                  else
                    ...accounts.map((account) => ListTile(
                          title: Text(account.name),
                          trailing: Text(
                            formatCurrency(account.balance),
                            style: const TextStyle(
                              color: Colors.green,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AccountDetailScreen(
                                    accountId: account.id),
                              ),
                            );
                          },
                          onLongPress: () =>
                              _handleLongPress(context, db, account, l10n),
                        )),
                  StreamBuilder<List<Account>>(
                    stream: db.accountsDao.watchArchivedAccounts(),
                    builder: (context, archivedSnapshot) {
                      final archivedAccounts =
                          archivedSnapshot.data ?? const <Account>[];
                      if (archivedAccounts.isEmpty) {
                        return const SizedBox.shrink();
                      }

                      return ExpansionTile(
                        title: Text(l10n.archivedAccounts),
                        children: [
                          ...archivedAccounts.map((account) => ListTile(
                                title: Text(account.name),
                                trailing: Text(
                                  formatCurrency(account.balance),
                                  style: TextStyle(
                                    color: account.balance < 0
                                        ? Colors.red
                                        : Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                onTap: () => _handleArchivedAccountTap(
                                    context, db, account, l10n),
                              )),
                        ],
                      );
                    },
                  ),
                ],
              );
            },
          ),

          // Search bar
          if (_showSearchBar)
            Positioned(
              top: statusBarHeight + kToolbarHeight + 8,
              left: 16,
              right: 16,
              child: LiquidGlassSearchBar(
                controller: _searchController,
                focusNode: _searchFocusNode,
                hintText: l10n.searchAccounts,
                onChanged: _onSearchChanged,
              ),
            ),

          // Filter panel
          if (_showFilterPanel)
            FilterPanel(
              config: buildAccountFilterConfig(l10n),
              currentRules: _filterRules,
              onRulesChanged: _onFilterRulesChanged,
              onClose: () => setState(() => _showFilterPanel = false),
            ),

          buildLiquidGlassAppBar(
            context,
            title: Text(l10n.accounts),
            showBackButton: false,
            actions: [
              IconButton(
                icon: Icon(
                  _showSearchBar ? Icons.search_off : Icons.search,
                  size: 22,
                ),
                onPressed: _toggleSearch,
              ),
              FilterBadge(
                count: _activeFilterCount,
                child: IconButton(
                  icon: const Icon(Icons.filter_list, size: 22),
                  onPressed: () => setState(() => _showFilterPanel = true),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
