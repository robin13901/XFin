import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:xfin/database/app_database.dart';
import 'package:xfin/l10n/app_localizations.dart';
import 'package:xfin/utils/format.dart';
import 'package:xfin/utils/global_constants.dart';
import 'package:xfin/widgets/dialogs.dart';
import 'package:xfin/database/daos/trades_dao.dart';

import '../database/tables.dart';
import '../models/filter/filter_rule.dart';
import '../models/filter/trade_filter_config.dart';
import '../providers/database_provider.dart';
import '../widgets/filter/filter_badge.dart';
import '../widgets/filter/filter_panel.dart';
import '../widgets/filter/liquid_glass_search_bar.dart';
import '../widgets/forms/trade_form.dart';
import '../widgets/liquid_glass_widgets.dart';

class TradesScreen extends StatefulWidget {
  const TradesScreen({super.key});

  @override
  State<TradesScreen> createState() => _TradesScreenState();
}

class _TradesScreenState extends State<TradesScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sheetAnimController;
  late final AppDatabase db;

  // Preload futures
  late final Future<List<Asset>> _assetsFuture;
  late final Future<List<Account>> _accountsFuture;

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
  void initState() {
    super.initState();

    // Zero-duration controller => sheet appears instantly (no open animation).
    _sheetAnimController =
    AnimationController(vsync: this, duration: Duration.zero)..value = 1.0;

    // Start preloading DB data immediately (background).
    db = context.read<DatabaseProvider>().db;
    _assetsFuture = db.assetsDao.getAllAssets();
    _accountsFuture = db.accountsDao.getAllAccounts();
  }

  @override
  void dispose() {
    _sheetAnimController.dispose();
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

  Future<void> _showTradeForm(BuildContext context, {Trade? trade}) async {
    final assets = await _assetsFuture;
    final accounts = await _accountsFuture;

    if (!context.mounted) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      transitionAnimationController: _sheetAnimController,
      builder: (_) => TradeForm(
        trade: trade,
        preloadedAssets: assets,
        preloadedAccounts: accounts,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final formatter = NumberFormat.decimalPattern('de_DE');
    formatter.minimumFractionDigits = 2;
    formatter.maximumFractionDigits = 2;
    final statusBarHeight = MediaQuery.of(context).padding.top;
    // Add space for search bar only when visible
    final searchBarSpace = _showSearchBar ? 60.0 : 0.0;

    return Scaffold(
      body: Stack(
        children: [
          StreamBuilder<List<TradeWithAsset>>(
            stream: db.tradesDao.watchAllTrades(
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
              final tradesWithAssets = snapshot.data ?? [];
              if (tradesWithAssets.isEmpty) {
                return Center(
                  child: Text(
                    _searchQuery.isNotEmpty || _filterRules.isNotEmpty
                        ? l10n.noMatchingBookings
                        : l10n.noTrades,
                  ),
                );
              }

              return ListView.builder(
                padding: EdgeInsets.only(
                  top: statusBarHeight + kToolbarHeight + searchBarSpace,
                  bottom: 92,
                ),
                itemCount: tradesWithAssets.length,
                itemBuilder: (context, index) {
                  final tradeWithAsset = tradesWithAssets[index];
                  final trade = tradeWithAsset.trade;
                  final asset = tradeWithAsset.asset;

                  String rawDatetime = trade.datetime.toString();
                  final datetime = DateTime.parse(
                      '${rawDatetime.substring(0, 8)} ${rawDatetime.substring(8, 14)}');

                  List<Text> subtitleWidgets = [
                    Text(
                        '${l10n.datetime}: ${dateTimeFormat.format(datetime)} Uhr'),
                    Text(
                        '${l10n.value}: ${formatCurrency(trade.targetAccountValueDelta.abs())}'),
                    Text('${l10n.fee}: ${formatCurrency(trade.fee)}'),
                    if (trade.type == TradeTypes.sell)
                      Text('${l10n.tax}: ${formatCurrency(trade.tax)}'),
                  ];

                  if (trade.type == TradeTypes.sell) {
                    final pnlColor =
                    trade.profitAndLoss >= 0 ? Colors.green : Colors.red;

                    subtitleWidgets.add(
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(text: '${l10n.profitAndLoss}: '),
                            TextSpan(
                              text: formatCurrency(trade.profitAndLoss),
                              style: TextStyle(color: pnlColor),
                            ),
                          ],
                        ),
                      ),
                    );
                    subtitleWidgets.add(
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(text: '${l10n.returnOnInvestment}: '),
                            TextSpan(
                              text:
                              '${formatter.format(trade.returnOnInvest * 100)} %',
                              style: TextStyle(color: pnlColor),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListTile(
                    title: Text(
                        '${trade.type.name.toUpperCase()} ${preciseDecimal(trade.shares)} ${asset.tickerSymbol} @ ${formatCurrency(trade.costBasis)}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: subtitleWidgets,
                    ),
                    onTap: () => _showTradeForm(context, trade: trade),
                    onLongPress: () => showDeleteDialog(context, trade: trade),
                  );
                },
              );
            },
          ),

          // Search bar - overlay mode
          if (_showSearchBar)
            Positioned(
              top: statusBarHeight + kToolbarHeight + 8,
              left: 16,
              right: 16,
              child: LiquidGlassSearchBar(
                controller: _searchController,
                focusNode: _searchFocusNode,
                hintText: l10n.searchTrades,
                onChanged: _onSearchChanged,
              ),
            ),

          // Filter panel
          if (_showFilterPanel)
            FilterPanel(
              config: buildTradeFilterConfig(l10n, db),
              currentRules: _filterRules,
              onRulesChanged: _onFilterRulesChanged,
              onClose: () => setState(() => _showFilterPanel = false),
            ),

          buildLiquidGlassAppBar(
            context,
            title: Text(l10n.trades),
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
          buildFAB(context: context, onTap: () => _showTradeForm(context)),
        ],
      ),
    );
  }
}
