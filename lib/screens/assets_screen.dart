import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xfin/database/app_database.dart';
import 'package:xfin/database/tables.dart';
import 'package:xfin/l10n/app_localizations.dart';
import 'package:xfin/utils/format.dart';
import 'package:xfin/utils/global_constants.dart';
import 'package:xfin/widgets/asset_form.dart';
import 'package:xfin/widgets/dialogs.dart';

import '../providers/database_provider.dart';
import '../widgets/liquid_glass_widgets.dart';
import 'asset_analysis_detail_screen.dart';

class AssetsScreen extends StatefulWidget {
  const AssetsScreen({super.key});

  @override
  State<AssetsScreen> createState() => _AssetsScreenState();
}

class _AssetsScreenState extends State<AssetsScreen> {
  int _selectedTab = 1;
  AssetTypes? _selectedType;

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
      showDeleteDialog(context, asset: asset);
    }
  }

  Future<List<_AllocationItem>> _loadAllocationItems(AppDatabase db) async {
    final assets = (await db.assetsDao.getAllAssets())
        .where((a) => !a.isArchived)
        .toList();
    if (_selectedType == null) {
      final Map<AssetTypes, double> byType = {};
      for (final asset in assets) {
        byType.update(asset.type, (v) => v + asset.value, ifAbsent: () => asset.value);
      }
      return byType.entries
          .map((e) => _AllocationItem(
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
        .map((a) => _AllocationItem(label: a.name, value: a.value, asset: a))
        .where((e) => e.value > 0)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
  }

  Widget _buildAllocationChart(List<_AllocationItem> items) {
    final total = items.fold<double>(0, (sum, e) => sum + e.value);
    return SizedBox(
      height: 240,
      child: PieChart(
        PieChartData(
          sectionsSpace: 3,
          centerSpaceRadius: 46,
          startDegreeOffset: -90,
          sections: List.generate(items.length, (index) {
            final item = items[index];
            final ratio = total == 0 ? 0.0 : item.value / total;
            return PieChartSectionData(
              value: item.value,
              color: chartColors[index % chartColors.length],
              radius: 88,
              title: ratio >= 0.08 ? '${(ratio * 100).toStringAsFixed(0)}%' : '',
              titleStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildAnalysisTab(BuildContext context, AppDatabase db, AppLocalizations l10n) {
    return FutureBuilder<List<_AllocationItem>>(
      future: _loadAllocationItems(db),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text(snapshot.error.toString()));
        }
        final items = snapshot.data ?? [];
        final total = items.fold<double>(0, (sum, e) => sum + e.value);
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
                Center(child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(l10n.noAssetsOfThisTypeYet),
                ))
              else ...[
                _buildAllocationChart(items),
                const SizedBox(height: 32),
                Text(l10n.investments,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                ...List.generate(items.length, (index) {
                  final item = items[index];
                  double ratio = total == 0 ? 0 : item.value / total;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      radius: 8,
                      backgroundColor: chartColors[index % 10],
                    ),
                    title: Text(_selectedType == null ? getAssetTypeName(l10n, item.type!, plural: true) : item.label, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(formatCurrency(item.value), style: const TextStyle(color: Colors.grey)),
                    trailing: Text(formatPercent(ratio), style: const TextStyle(fontWeight: FontWeight.w700)),
                    onTap: () {
                      if (_selectedType == null && item.type != null) {
                        setState(() => _selectedType = item.type);
                        return;
                      }
                      if (item.asset == null) return;
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => AssetAnalysisDetailScreen(assetId: item.asset!.id)),
                      );
                    },
                  );
                }),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildAssetsList(BuildContext context, AppDatabase db, AppLocalizations l10n) {
    return StreamBuilder<List<Asset>>(
      stream: db.assetsDao.watchAllAssets(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          showErrorDialog(context, snapshot.error.toString());
        }
        final assets = snapshot.data ?? [];
        if (assets.isEmpty) {
          return Center(child: Text(l10n.noAssets));
        }

        return ListView.builder(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + kToolbarHeight,
          ),
          itemCount: assets.length,
          itemBuilder: (context, index) {
            final asset = assets[index];
            return ListTile(
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
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final db = context.read<DatabaseProvider>().db;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: _selectedTab,
            children: [
              _buildAnalysisTab(context, db, l10n),
              _buildAssetsList(context, db, l10n),
            ],
          ),
          buildLiquidGlassAppBar(context, title: Text(l10n.assets)),
          Positioned(
            bottom: 16,
            left: 8,
            right: 8,
            child: LiquidGlassBottomNav(
              icons: const [Icons.analytics_outlined, Icons.account_balance_wallet_outlined],
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
        ],
      ),
    );
  }
}

class _AllocationItem {
  final String label;
  final double value;
  final AssetTypes? type;
  final Asset? asset;

  const _AllocationItem({required this.label, required this.value, this.type, this.asset});
}
