import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xfin/database/app_database.dart';
import 'package:xfin/l10n/app_localizations.dart';
import 'package:xfin/utils/format.dart';
import 'package:xfin/widgets/asset_form.dart';
import 'package:xfin/widgets/dialogs.dart';

import '../providers/database_provider.dart';
import '../utils/global_constants.dart';
import '../widgets/liquid_glass_widgets.dart';

class AssetsScreen extends StatelessWidget {
  const AssetsScreen({super.key});

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
    bool deletionProhibited = true;
    final hasTrades = await db.assetsDao.hasTrades(asset.id);
    final hasAssetsOnAccounts =
        await db.assetsDao.hasAssetsOnAccounts(asset.id);
    deletionProhibited = hasTrades || hasAssetsOnAccounts || asset.id == 1;

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

  @override
  Widget build(BuildContext context) {
    final db = context.read<DatabaseProvider>().db;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: StreamBuilder<List<Asset>>(
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
                        top:
                            MediaQuery.of(context).padding.top + kToolbarHeight,
                        bottom: 92,
                      ),
                      itemCount: assets.length,
                      itemBuilder: (context, index) {
                        final asset = assets[index];
                        return ListTile(
                          title: Text(asset.name),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  '${l10n.shares}: ${preciseDecimal(asset.shares)}'),
                              if (asset.id != 1 && asset.shares > 0) ...[
                                if ((asset.netCostBasis - asset.brokerCostBasis)
                                        .abs() <
                                    0.01) ...[
                                  Text(
                                      '${l10n.costBasis}: ${formatCurrency(asset.netCostBasis)}'),
                                ] else ...[
                                  Text(
                                      '${l10n.netCostBasis}: ${formatCurrency(asset.netCostBasis)}'),
                                  Text(
                                      '${l10n.brokerCostBasis}: ${formatCurrency(asset.brokerCostBasis)}'),
                                ],
                              ],
                              Text(
                                  '${l10n.value}: ${formatCurrency(asset.value)}'),
                            ],
                          ),
                          trailing: Text(asset.type.name.toUpperCase()),
                          onLongPress: () =>
                              _handleLongPress(context, db, asset, l10n),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
          buildLiquidGlassAppBar(context, title: Text(l10n.assets)),
          buildFAB(context: context, onTap: () => _showAssetForm(context)),
        ],
      ),
    );
  }
}
