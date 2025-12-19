import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:xfin/database/app_database.dart';
import 'package:xfin/l10n/app_localizations.dart';
import 'package:xfin/utils/global_constants.dart';
import 'package:xfin/widgets/trade_form.dart';
import 'package:xfin/database/daos/trades_dao.dart';

import '../database/tables.dart';
import '../widgets/liquid_glass_widgets.dart'; // Import TradeWithAsset

class TradesScreen extends StatelessWidget {
  const TradesScreen({super.key});

  void _showTradeForm(BuildContext context, {Trade? trade}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => TradeForm(trade: trade),
    );
  }

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<AppDatabase>(context);
    final l10n = AppLocalizations.of(context)!;
    final currencyFormat = NumberFormat.currency(locale: 'de_DE', symbol: '€');
    final dateTimeFormatter = DateFormat('dd.MM.yyyy, HH:mm');
    final pnlFormat =
        NumberFormat.currency(locale: 'de_DE', symbol: '€', decimalDigits: 2);
    final formatter = NumberFormat.decimalPattern('de_DE');
    formatter.minimumFractionDigits = 2;
    formatter.maximumFractionDigits = 2;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.trades),
      ),
      body: Stack(
        children: [
          StreamBuilder<List<TradeWithAsset>>(
            stream: db.tradesDao.watchAllTrades(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                    child: Text(l10n.error(snapshot.error.toString())));
              }
              final tradesWithAssets = snapshot.data ?? [];
              if (tradesWithAssets.isEmpty) {
                return Center(child: Text(l10n.noTrades));
              }

              return ListView.builder(
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
                        '${l10n.datetime}: ${dateTimeFormatter.format(datetime)} Uhr'),
                    Text(
                        '${l10n.value}: ${currencyFormat.format(trade.targetAccountValueDelta.abs())}'),
                    Text('${l10n.fee}: ${currencyFormat.format(trade.fee)}'),
                    if (trade.type == TradeTypes.sell)
                      Text('${l10n.tax}: ${currencyFormat.format(trade.tax)}'),
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
                              text: pnlFormat.format(trade.profitAndLoss),
                              // Value in color
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
                              // Value in color
                              style: TextStyle(color: pnlColor),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListTile(
                    title: Text(
                        '${trade.type.name.toUpperCase()} ${preciseDecimal(trade.shares)} ${asset.tickerSymbol} @ ${currencyFormat.format(trade.costBasis)}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: subtitleWidgets,
                    ),
                    // onTap: () => _showTradeForm(context, trade: trade),
                    // onLongPress: () => {}, // Deleting trades requires recalculation logic
                  );
                },
              );
            },
          ),
          buildFAB(context: context, onTap: () => _showTradeForm(context)), //DevTestScreen().parseAndInsertCsv(context)),
        ],
      ),
    );
  }
}
