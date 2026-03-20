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
import '../models/filter/trade_filter_config.dart';
import '../mixins/nav_bar_visibility_mixin.dart';
import '../mixins/search_filter_mixin.dart';
import '../providers/database_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/aurora_background.dart';
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
    with SingleTickerProviderStateMixin, NavBarVisibilityMixin<TradesScreen>, SearchFilterMixin<TradesScreen> {
  late final AnimationController _sheetAnimController;
  late final AppDatabase db;
  final ValueNotifier<bool> _navBarVisible = ValueNotifier<bool>(true);

  @override
  ValueNotifier<bool>? get localNavBarVisible => _navBarVisible;

  // Preload futures
  late final Future<List<Asset>> _assetsFuture;
  late final Future<List<Account>> _accountsFuture;

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
    _navBarVisible.dispose();
    super.dispose();
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
    updateKeyboardVisibility(context);

    return Scaffold(
      backgroundColor:
          ThemeProvider.instance.isAurora ? Colors.transparent : null,
      body: Stack(
        children: [
          buildAuroraLayer(context),
          StreamBuilder<List<TradeWithAsset>>(
            stream: db.tradesDao.watchAllTrades(
              searchQuery: searchQuery.isNotEmpty ? searchQuery : null,
              filterRules: filterRules.isNotEmpty ? filterRules : null,
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
                    searchQuery.isNotEmpty || filterRules.isNotEmpty
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

                  final titleText =
                      '${trade.type.name.toUpperCase()} ${preciseDecimal(trade.shares)} ${asset.tickerSymbol} @ ${formatCurrency(trade.costBasis)}';

                  if (trade.type == TradeTypes.sell) {
                    return _SellTradeListItem(
                      trade: trade,
                      asset: asset,
                      titleText: titleText,
                      subtitleWidgets: subtitleWidgets,
                      onTap: () => _showTradeForm(context, trade: trade),
                      onLongPress: () =>
                          showDeleteDialog(context, trade: trade),
                      tradesDao: db.tradesDao,
                    );
                  }

                  return ListTile(
                    title: Text(titleText),
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
          if (showSearchBar)
            Positioned(
              top: statusBarHeight + kToolbarHeight + 8,
              left: 16,
              right: 16,
              child: LiquidGlassSearchBar(
                controller: searchController,
                focusNode: searchFocusNode,
                hintText: l10n.searchTrades,
                onChanged: onSearchChanged,
              ),
            ),

          // Filter panel
          if (showFilterPanel)
            FilterPanel(
              config: buildTradeFilterConfig(l10n, db),
              currentRules: filterRules,
              onRulesChanged: onFilterRulesChanged,
              onClose: closeFilterPanel,
            ),

          buildLiquidGlassAppBar(
            context,
            title: Text(l10n.trades),
            actions: [
              IconButton(
                icon: Icon(
                  showSearchBar ? Icons.search_off : Icons.search,
                  size: 22,
                ),
                onPressed: toggleSearch,
              ),
              FilterBadge(
                count: activeFilterCount,
                child: IconButton(
                  icon: const Icon(Icons.filter_list, size: 22),
                  onPressed: openFilterPanel,
                ),
              ),
            ],
          ),
          ValueListenableBuilder<bool>(
            valueListenable: _navBarVisible,
            builder: (context, visible, child) {
              return visible ? child! : const SizedBox.shrink();
            },
            child: buildFAB(context: context, onTap: () => _showTradeForm(context)),
          ),
        ],
      ),
    );
  }
}

class _SellTradeListItem extends StatefulWidget {
  final Trade trade;
  final Asset asset;
  final String titleText;
  final List<Text> subtitleWidgets;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final TradesDao tradesDao;

  const _SellTradeListItem({
    required this.trade,
    required this.asset,
    required this.titleText,
    required this.subtitleWidgets,
    required this.onTap,
    required this.onLongPress,
    required this.tradesDao,
  });

  @override
  State<_SellTradeListItem> createState() => _SellTradeListItemState();
}

class _SellTradeListItemState extends State<_SellTradeListItem> {
  List<ConsumedLot>? _lots;
  bool _isLoading = false;
  bool _isExpanded = false;

  Future<void> _loadLots() async {
    if (_lots != null || _isLoading) return;
    setState(() => _isLoading = true);
    final lots =
        await widget.tradesDao.getFiFoLotsForSellTrade(widget.trade);
    if (mounted) setState(() { _lots = lots; _isLoading = false; });
  }

  void _toggleExpansion() {
    setState(() => _isExpanded = !_isExpanded);
    if (_isExpanded) _loadLots();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          title: Text(widget.titleText),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: widget.subtitleWidgets,
          ),
          trailing: IconButton(
            icon: Icon(
              _isExpanded ? Icons.expand_less : Icons.expand_more,
              size: 20,
            ),
            onPressed: _toggleExpansion,
          ),
          onTap: widget.onTap,
          onLongPress: widget.onLongPress,
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          child: _isExpanded
              ? Padding(
                  padding: const EdgeInsets.only(
                      left: 16, right: 16, bottom: 8),
                  child: _buildLotsContent(l10n),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildLotsContent(AppLocalizations l10n) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 4),
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (_lots == null || _lots!.isEmpty) {
      return const SizedBox.shrink();
    }

    final isCrypto = widget.asset.type == AssetTypes.crypto;
    final sellDate = intToDateTime(widget.trade.datetime);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 1),
        const SizedBox(height: 4),
        Text(
          l10n.fifoLots,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        ),
        const SizedBox(height: 2),
        ..._lots!.map((lot) {
          final lotDate = lot.datetime > 0 ? intToDateTime(lot.datetime) : null;
          final dateStr =
              lotDate != null ? dateTimeFormat.format(lotDate) : '–';

          Color? lotColor;
          if (isCrypto && sellDate != null && lotDate != null) {
            final held = sellDate.difference(lotDate);
            lotColor =
                held.inDays >= 365 ? Colors.green : Colors.orange;
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 1),
            child: Row(
              children: [
                Text(
                  dateStr,
                  style: TextStyle(fontSize: 12, color: lotColor),
                ),
                const Spacer(),
                Text(
                  l10n.lotShares(
                    preciseDecimal(lot.shares),
                    formatCurrency(lot.costBasis),
                    formatCurrency(lot.shares * lot.costBasis),
                  ),
                  style: TextStyle(fontSize: 12, color: lotColor),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
