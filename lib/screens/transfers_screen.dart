import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xfin/database/app_database.dart';
import 'package:xfin/l10n/app_localizations.dart';

import '../database/daos/transfers_dao.dart';
import '../models/filter/transfer_filter_config.dart';
import '../mixins/nav_bar_visibility_mixin.dart';
import '../mixins/search_filter_mixin.dart';
import '../providers/database_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/format.dart';
import '../widgets/aurora_background.dart';
import '../widgets/dialogs.dart';
import '../widgets/filter/filter_badge.dart';
import '../widgets/filter/filter_panel.dart';
import '../widgets/filter/liquid_glass_search_bar.dart';
import '../widgets/forms/transfer_form.dart';
import '../widgets/liquid_glass_widgets.dart';

class TransfersScreen extends StatefulWidget {
  const TransfersScreen({super.key});

  @override
  State<TransfersScreen> createState() => _TransfersScreenState();
}

class _TransfersScreenState extends State<TransfersScreen>
    with SingleTickerProviderStateMixin, NavBarVisibilityMixin<TransfersScreen>, SearchFilterMixin<TransfersScreen> {
  late final AnimationController _sheetAnimController;
  late final AppDatabase db;
  late final Future<List<Asset>> assetsFuture;
  final ValueNotifier<bool> _navBarVisible = ValueNotifier<bool>(true);

  @override
  ValueNotifier<bool>? get localNavBarVisible => _navBarVisible;

  @override
  void initState() {
    super.initState();
    db = context.read<DatabaseProvider>().db;
    assetsFuture = db.assetsDao.getAllAssets();
    _sheetAnimController =
        AnimationController(vsync: this, duration: Duration.zero)..value = 1.0;
  }

  @override
  void dispose() {
    _sheetAnimController.dispose();
    _navBarVisible.dispose();
    super.dispose();
  }

  Future<void> _showTransferForm(
      BuildContext context, Transfer? transfer) async {
    final assets = await assetsFuture;
    if (!context.mounted) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      transitionAnimationController: _sheetAnimController,
      builder: (_) =>
          TransferForm(transfer: transfer, preloadedAssets: assets),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final statusBarHeight = MediaQuery.of(context).padding.top;
    updateKeyboardVisibility(context);

    return Scaffold(
      backgroundColor:
          context.watch<ThemeProvider>().isAurora ? Colors.transparent : null,
      body: Stack(
        children: [
          buildAuroraLayer(context),
          StreamBuilder<List<TransferWithAccountsAndAsset>>(
            stream: db.transfersDao.watchTransfersWithAccountsAndAsset(
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

              final items = snapshot.data ?? [];
              if (items.isEmpty) {
                return Center(
                  child: Text(
                    searchQuery.isNotEmpty || filterRules.isNotEmpty
                        ? l10n.noMatchingBookings
                        : l10n.noTransfersYet,
                  ),
                );
              }

              return ListView.builder(
                padding: EdgeInsets.only(
                  top: statusBarHeight + kToolbarHeight + searchBarSpace,
                  bottom: 92,
                ),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final it = items[index];
                  final transfer = it.transfer;
                  final asset = it.asset;

                  final dateString = transfer.date.toString();
                  final date = DateTime.parse(
                      '${dateString.substring(0, 4)}-${dateString.substring(4, 6)}-${dateString.substring(6, 8)}');
                  final dateText = dateFormat.format(date);

                  return ListTile(
                    title: Text(
                        '${it.sendingAccount.name} → ${it.receivingAccount.name}'),
                    subtitle: Text(asset.name),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (asset.id == 1) ...[
                          Text(
                            formatCurrency(transfer.value),
                            style: const TextStyle(
                                color: Colors.indigoAccent,
                                fontWeight: FontWeight.bold),
                          ),
                        ] else ...[
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text:
                                      '${transfer.shares} ${asset.currencySymbol ?? asset.tickerSymbol} ≈ ',
                                  style: const TextStyle(color: Colors.grey),
                                ),
                                TextSpan(
                                  text: formatCurrency(transfer.value),
                                  style: const TextStyle(
                                      color: Colors.indigoAccent,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                        Text(dateText,
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                    onTap: () => _showTransferForm(context, transfer),
                    onLongPress: () =>
                        showDeleteDialog(context, transfer: transfer),
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
                hintText: l10n.searchTransfers,
                onChanged: onSearchChanged,
              ),
            ),

          // Filter panel
          if (showFilterPanel)
            FilterPanel(
              config: buildTransferFilterConfig(l10n, db),
              currentRules: filterRules,
              onRulesChanged: onFilterRulesChanged,
              onClose: closeFilterPanel,
            ),

          buildLiquidGlassAppBar(
            context,
            title: Text(l10n.transfers),
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
            child: buildFAB(
                context: context, onTap: () => _showTransferForm(context, null)),
          ),
        ],
      ),
    );
  }
}
