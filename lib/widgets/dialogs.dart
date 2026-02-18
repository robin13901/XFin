import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../database/app_database.dart';
import '../l10n/app_localizations.dart';
import '../providers/database_provider.dart';

Future<void> showDeleteDialog(
  BuildContext context, {
  Account? account,
  Asset? asset,
  Booking? booking,
  PeriodicBooking? periodicBooking,
  Transfer? transfer,
  PeriodicTransfer? periodicTransfer,
  Trade? trade,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final db = context.read<DatabaseProvider>().db;
  String title, content;

  if (account != null) {
    title = l10n.deleteAccount;
    content = l10n.deleteAccountConfirmation;
  } else if (asset != null) {
    title = l10n.deleteAsset;
    content = l10n.deleteAssetConfirmation;
  } else if (booking != null) {
    title = l10n.deleteBooking;
    content = l10n.deleteBookingConfirmation;
  } else if (periodicBooking != null) {
    title = l10n.deleteStandingOrder;
    content = l10n.deleteStandingOrderConfirmation;
  } else if (trade != null) {
    title = l10n.deleteTrade;
    content = l10n.deleteTradeConfirmation;
  } else if (transfer != null) {
    title = l10n.deleteTransfer;
    content = l10n.deleteTransferConfirmation;
  } else if (periodicTransfer != null) {
    title = l10n.deleteStandingOrder;
    content = l10n.deleteStandingOrderConfirmation;
  } else {
    return;
  }

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(l10n.delete),
        ),
      ],
    ),
  );

  if (confirmed == true) {
    if (account != null) {
      await db.accountsDao.deleteAccount(account.id);
    } else if (asset != null) {
      await db.assetsDao.deleteAsset(asset.id);
    } else if (booking != null) {
      await db.bookingsDao.deleteBooking(booking.id, l10n);
    } else if (periodicBooking != null) {
      await db.periodicBookingsDao.deletePeriodicBooking(periodicBooking.id);
    } else if (trade != null) {
      await db.tradesDao.deleteTrade(trade.id, l10n);
    } else if (transfer != null) {
      await db.transfersDao.deleteTransfer(transfer.id, l10n);
    } else if (periodicTransfer != null) {
      await db.periodicTransfersDao.deletePeriodicTransfer(periodicTransfer.id);
    }
  }
}

void showErrorDialog(BuildContext context, String content) {
  final l10n = AppLocalizations.of(context)!;
  showInfoDialog(context, l10n.error, content);
}

void showInfoDialog(BuildContext context, String title, String content) {
  final l10n = AppLocalizations.of(context)!;
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.ok),
        ),
      ],
    ),
  );
}
