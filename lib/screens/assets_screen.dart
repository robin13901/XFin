import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:xfin/database/app_database.dart';
import 'package:xfin/l10n/app_localizations.dart';
import 'package:xfin/widgets/asset_form.dart';

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
    bool hasReferences = false;
    final hasTrades = await db.assetsDao.hasTrades(asset.id);
    final hasAssetsOnAccounts = await db.assetsDao.hasAssetsOnAccounts(asset.id);
    hasReferences = hasTrades || hasAssetsOnAccounts;

    if (!context.mounted) return;

    if (hasReferences) {
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
          title: Text(l10n.deleteAsset),
          content: Text(l10n.confirmDeleteAsset),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () {
                db.assetsDao.deleteAsset(asset.id);
                Navigator.of(context).pop();
              },
              child: Text(l10n.confirm),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<AppDatabase>(context);
    final l10n = AppLocalizations.of(context)!;
    final currencyFormat = NumberFormat.currency(locale: 'de_DE', symbol: '€');

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.assets),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Asset>>(
              stream: db.assetsDao.watchAllAssets(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text(l10n.error(snapshot.error.toString())));
                }
                final assets = snapshot.data ?? [];
                if (assets.isEmpty) {
                  return Center(
                      child: Text(l10n.noAssets));
                }

                return ListView.builder(
                  itemCount: assets.length,
                  itemBuilder: (context, index) {
                    final asset = assets[index];
                    return ListTile(
                      title: Text(asset.name),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${l10n.value}: ${currencyFormat.format(asset.value)}'),
                          Text('${l10n.sharesOwned}: ${asset.sharesOwned.toStringAsFixed(2)}'),
                          Text('${l10n.netBuyIn}: ${currencyFormat.format(asset.netBuyIn)}'),
                        ],
                      ),
                      trailing: Text(asset.type.name.toUpperCase()),
                      // onTap: () {
                      //   _showAssetForm(context, asset: asset);
                      // },
                      onLongPress: () => _handleLongPress(context, db, asset, l10n),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAssetForm(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
