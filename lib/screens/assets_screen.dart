import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xfin/database/app_database.dart';
import 'package:xfin/database/tables.dart';
import 'package:xfin/l10n/app_localizations.dart';
import 'package:xfin/utils/format.dart';
import 'package:xfin/widgets/forms/asset_form.dart';
import 'package:xfin/widgets/charts.dart';
import 'package:xfin/widgets/dialogs.dart';

import '../models/filter/asset_filter_config.dart';
import '../mixins/nav_bar_visibility_mixin.dart';
import '../mixins/search_filter_mixin.dart';
import '../providers/database_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/aurora_background.dart';
import '../widgets/filter/filter_badge.dart';
import '../widgets/filter/filter_panel.dart';
import '../widgets/filter/liquid_glass_search_bar.dart';
import '../widgets/liquid_glass_widgets.dart';
import 'asset_analysis_detail_screen.dart';

class AssetsScreen extends StatefulWidget {
  const AssetsScreen({super.key});

  @override
  State<AssetsScreen> createState() => _AssetsScreenState();
}

class _AssetsScreenState extends State<AssetsScreen>
    with NavBarVisibilityMixin<AssetsScreen>, SearchFilterMixin<AssetsScreen> {
  int _selectedTab = 1;
  AssetTypes? _selectedType;
  final ValueNotifier<bool> _navBarVisible = ValueNotifier<bool>(true);

  @override
  ValueNotifier<bool>? get localNavBarVisible => _navBarVisible;

  @override
  void dispose() {
    _navBarVisible.dispose();
    super.dispose();
  }

  void _showAssetForm(BuildContext context, {Asset? asset}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => AssetForm(asset: asset),
    );
  }

  Future<void> _handleLongPress(
    BuildContext context,
    AppDatabase db,
    Asset asset,
    AppLocalizations l10n,
  ) async {
    final hasTrades = await db.assetsDao.hasTrades(asset.id);
    final hasAssetsOnAccounts = await db.assetsDao.hasAssetsOnAccounts(asset.id);
    final deletionProhibited = hasTrades || hasAssetsOnAccounts || asset.id == 1;

    if (!context.mounted) return;

    if (deletionProhibited) {
      if (asset.id == 1 || asset.value > 0) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l10n.cannotDeleteAsset),
            content: Text(l10n.assetHasReferences),
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
            title: Text(l10n.cannotDeleteAsset),
            content: Text(l10n.assetHasReferences),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.cancel),
              ),
              TextButton(
                onPressed: () {
                  db.assetsDao.setArchived(asset.id, true);
                  Navigator.of(context).pop();
                },
                child: Text(l10n.archive),
              ),
            ],
          ),
        );
      }
    } else {
      showDeleteDialog(context, asset: asset);
    }
  }

  void _handleArchivedAssetTap(BuildContext context, AppDatabase db, Asset asset) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unarchive Asset'),
        content: const Text('Do you want to unarchive this asset?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              db.assetsDao.setArchived(asset.id, false);
              Navigator.of(context).pop();
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Future<List<AllocationItem>> _loadAllocationItems(AppDatabase db) async {
    final assets = (await db.assetsDao.getAllAssets())
        .where((a) => !a.isArchived)
        .toList();
    if (_selectedType == null) {
      final Map<AssetTypes, double> byType = {};
      for (final asset in assets) {
        byType.update(asset.type, (v) => v + asset.value,
            ifAbsent: () => asset.value);
      }
      return byType.entries
          .map((e) => AllocationItem(
                label: e.key.name.toUpperCase(),
                value: e.value,
                type: e.key,
              ))
          .where((e) => e.value > 0)
          .toList()
        ..sort((a, b) => b.value.compareTo(a.value));
    }

    return assets
        .where((a) => a.type == _selectedType)
        .map((a) => AllocationItem(label: a.name, value: a.value, asset: a))
        .where((e) => e.value > 0)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
  }

  Widget _buildAnalysisTab(
      BuildContext context, AppDatabase db, AppLocalizations l10n) {
    return FutureBuilder<List<AllocationItem>>(
      future: _loadAllocationItems(db),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text(l10n.errorLoadingData));
        }
        final items = snapshot.data ?? [];
        return SingleChildScrollView(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + kToolbarHeight + 12,
            bottom: 96,
            left: 12,
            right: 12,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: AssetTypes.values.map((type) {
                    final selected = _selectedType == type;

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        label: Text(getAssetTypeName(l10n, type, plural: true)),
                        showCheckmark: false,
                        selected: selected,
                        onSelected: (_) => setState(() {
                          _selectedType = selected ? null : type;
                        }),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 32),
              if (items.isEmpty)
                Center(
                    child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(l10n.noAssetsOfThisTypeYet),
                ))
              else ...[
                AllocationBreakdownSection(
                  items: items
                      .map(
                        (item) => AllocationItem(
                          label: _selectedType == null
                              ? getAssetTypeName(l10n, item.type!, plural: true)
                              : item.label,
                          value: item.value,
                          type: item.type,
                          asset: item.asset,
                        ),
                      )
                      .toList(),
                  title: l10n.investments,
                  onItemTap: (item) {
                    if (_selectedType == null && item.type != null) {
                      setState(() => _selectedType = item.type);
                      return;
                    }
                    if (item.asset == null) return;
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            AssetAnalysisDetailScreen(assetId: item.asset!.id),
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildAssetsList(
      BuildContext context, AppDatabase db, AppLocalizations l10n) {
    final statusBarHeight = MediaQuery.of(context).padding.top;

    return StreamBuilder<List<Asset>>(
      stream: db.assetsDao.watchAllAssets(
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
        final assets = snapshot.data ?? [];
        if (assets.isEmpty) {
          return Center(
            child: Text(
              searchQuery.isNotEmpty || filterRules.isNotEmpty
                  ? l10n.noMatchingBookings
                  : l10n.noAssets,
            ),
          );
        }

        return ListView(
          padding: EdgeInsets.only(
            top: statusBarHeight + kToolbarHeight + searchBarSpace,
            bottom: 96,
          ),
          children: [
            ...assets.map((asset) => ListTile(
                  title: Text(asset.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${l10n.shares}: ${asset.shares.toStringAsFixed(4)}'),
                      if (asset.id != 1 && asset.shares > 0) ...[
                        if ((asset.netCostBasis - asset.brokerCostBasis).abs() < 0.01) ...[
                          Text('${l10n.costBasis}: ${formatCurrency(asset.netCostBasis)}'),
                        ] else ...[
                          Text('${l10n.netCostBasis}: ${formatCurrency(asset.netCostBasis)}'),
                          Text('${l10n.brokerCostBasis}: ${formatCurrency(asset.brokerCostBasis)}'),
                        ],
                      ],
                      Text('${l10n.value}: ${formatCurrency(asset.value)}'),
                    ],
                  ),
                  trailing: Text(getAssetTypeName(l10n, asset.type)),
                  onLongPress: () => _handleLongPress(context, db, asset, l10n),
                )),
            StreamBuilder<List<Asset>>(
              stream: db.assetsDao.watchArchivedAssets(),
              builder: (context, archivedSnapshot) {
                final archivedAssets = archivedSnapshot.data ?? const <Asset>[];
                if (archivedAssets.isEmpty) {
                  return const SizedBox.shrink();
                }
                return ExpansionTile(
                  title: const Text('Archived Assets'),
                  children: [
                    ...archivedAssets.map((asset) => ListTile(
                          title: Text(asset.name),
                          trailing: Text(formatCurrency(asset.value), style: TextStyle(
                            color: asset.value < 0 ? Colors.red : Colors.green,
                            fontWeight: FontWeight.bold,
                          )),
                          onTap: () => _handleArchivedAssetTap(context, db, asset),
                        )),
                  ],
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final db = context.read<DatabaseProvider>().db;
    final l10n = AppLocalizations.of(context)!;
    final statusBarHeight = MediaQuery.of(context).padding.top;
    updateKeyboardVisibility(context);

    // Build app bar actions based on selected tab
    final List<Widget> appBarActions = _selectedTab == 1
        ? [
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
          ]
        : [];

    return Scaffold(
      backgroundColor:
          ThemeProvider.instance.isAurora ? Colors.transparent : null,
      body: Stack(
        children: [
          buildAuroraLayer(context),
          IndexedStack(
            index: _selectedTab,
            children: [
              _buildAnalysisTab(context, db, l10n),
              _buildAssetsList(context, db, l10n),
            ],
          ),

          // Search bar (only visible in Assets tab) - overlay mode
          if (showSearchBar && _selectedTab == 1)
            Positioned(
              top: statusBarHeight + kToolbarHeight + 8,
              left: 16,
              right: 16,
              child: LiquidGlassSearchBar(
                controller: searchController,
                focusNode: searchFocusNode,
                hintText: l10n.searchAssets,
                onChanged: onSearchChanged,
              ),
            ),

          // Filter panel
          if (showFilterPanel)
            FilterPanel(
              config: buildAssetFilterConfig(l10n),
              currentRules: filterRules,
              onRulesChanged: onFilterRulesChanged,
              onClose: closeFilterPanel,
            ),

          buildLiquidGlassAppBar(
            context,
            title: Text(l10n.assets),
            actions: appBarActions,
          ),
          Positioned(
            bottom: 16,
            left: 8,
            right: 8,
            child: ValueListenableBuilder<bool>(
              valueListenable: _navBarVisible,
              builder: (context, visible, child) {
                return visible
                    ? RepaintBoundary(child: child!)
                    : const SizedBox.shrink();
              },
              child: LiquidGlassBottomNav(
                icons: const [
                  Icons.analytics_outlined,
                  Icons.account_balance_wallet_outlined
                ],
                labels: const ['Analysis', 'Assets'],
                keys: const [Key('assets_nav_analysis'), Key('assets_nav_list')],
                currentIndex: _selectedTab,
                onTap: (i) => setState(() => _selectedTab = i),
                onLeftTap: null,
                leftVisibleForIndices: const {},
                keepLeftPlaceholder: true,
                rightIcon: Icons.add,
                rightVisibleForIndices: const {1},
                onRightTap: () => _showAssetForm(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
