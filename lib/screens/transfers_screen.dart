import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:xfin/database/app_database.dart';
import 'package:xfin/l10n/app_localizations.dart';
import 'package:xfin/widgets/transfer_form.dart';

import '../database/daos/transfers_dao.dart';
import '../providers/database_provider.dart';
import '../widgets/dialogs.dart';
import '../widgets/liquid_glass_widgets.dart';

class TransfersScreen extends StatefulWidget {
  const TransfersScreen({super.key});

  @override
  State<TransfersScreen> createState() => _TransfersScreenState();
}

class _TransfersScreenState extends State<TransfersScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sheetAnimController;
  late final AppDatabase db;
  late final Future<List<Asset>> assetsFuture;

  @override
  void initState() {
    super.initState();
    db = context.read<DatabaseProvider>().db;
    assetsFuture = db.assetsDao.getAllAssets();
    // Zero-duration controller already at value 1 -> sheet appears instantly (no open animation).
    _sheetAnimController =
    AnimationController(vsync: this, duration: Duration.zero)..value = 1.0;
  }

  @override
  void dispose() {
    _sheetAnimController.dispose();
    super.dispose();
  }

  Future<void> _showTransferForm(BuildContext context, Transfer? transfer) async {
    final assets = await assetsFuture;
    if (!context.mounted) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      transitionAnimationController: _sheetAnimController,
      builder: (_) => TransferForm(transfer: transfer, preloadedAssets: assets),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Stack(
        children: [
          StreamBuilder<List<TransferWithAccountsAndAsset>>(
            stream: db.transfersDao.watchTransfersWithAccountsAndAsset(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                    child:
                    Text(l10n.anErrorOccurred(snapshot.error.toString())));
              }

              final items = snapshot.data ?? [];
              if (items.isEmpty) {
                return Center(child: Text(l10n.noTransfersYet));
              }

              final currencyFormat =
              NumberFormat.currency(locale: 'de_DE', symbol: '€');
              final dateFormat = DateFormat('dd.MM.yyyy');

              return ListView.builder(
                padding: EdgeInsets.only(
                  top:
                  MediaQuery.of(context).padding.top + kToolbarHeight,
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
                            currencyFormat.format(transfer.value),
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
                                  text: currencyFormat.format(transfer.value),
                                  style: const TextStyle(color: Colors.indigoAccent),
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
                    onLongPress: () => showDeleteDialog(context, transfer: transfer),
                  );
                },
              );
            },
          ),
          buildLiquidGlassAppBar(context, title: Text(l10n.transfers)),
          buildFAB(
              context: context, onTap: () => _showTransferForm(context, null)),
        ],
      ),
    );
  }
}
