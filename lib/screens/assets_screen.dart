import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xfin/database/app_database.dart';
import 'package:xfin/l10n/app_localizations.dart';
import 'package:xfin/utils/format.dart';
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
        .where((a) => !a.isArchived && a.id != 1)
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
    final colors = [
      const Color(0xFF3B82F6),
      const Color(0xFF2563EB),
      const Color(0xFF1D4ED8),
      const Color(0xFF1E40AF),
      const Color(0xFF3730A3),
      const Color(0xFF312E81),
    ];
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
              color: colors[index % colors.length],
              radius: 88,
              title: ratio >= 0.08 ? '${(ratio * 100).toStringAsFixed(0)}%' : '',
              titleStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildAnalysisTab(BuildContext context, AppDatabase db) {
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
            bottom: 120,
            left: 12,
            right: 12,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: AssetTypes.values.map((type) {
                  final selected = _selectedType == type;
                  return ChoiceChip(
                    label: Text(type.name.toUpperCase()),
                    selected: selected,
                    onSelected: (_) => setState(() {
                      _selectedType = selected ? null : type;
                    }),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              if (items.isEmpty)
                const Center(child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('No allocation data yet.'),
                ))
              else ...[
                _buildAllocationChart(items),
                const SizedBox(height: 16),
                Text(
                  _selectedType == null ? 'Assets' : '${_selectedType!.name.toUpperCase()} Assets',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                ...List.generate(items.length, (index) {
                  final item = items[index];
                  final ratio = total == 0 ? 0 : item.value / total;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      radius: 8,
                      backgroundColor: [
                        const Color(0xFF3B82F6),
                        const Color(0xFF2563EB),
                        const Color(0xFF1D4ED8),
                        const Color(0xFF1E40AF),
                        const Color(0xFF3730A3),
                        const Color(0xFF312E81),
                      ][index % 6],
                    ),
                    title: Text(item.label, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(formatCurrency(item.value)),
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
            bottom: 120,
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
              trailing: Text(asset.type.name.toUpperCase()),
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
              _buildAnalysisTab(context, db),
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
