import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:xfin/database/app_database.dart';
import 'package:xfin/database/daos/bookings_dao.dart';
import 'package:xfin/l10n/app_localizations.dart';

class DeleteBookingDialog extends StatelessWidget {
  final BookingWithAccount bookingWithAccount;

  const DeleteBookingDialog({super.key, required this.bookingWithAccount});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final db = Provider.of<AppDatabase>(context, listen: false);
    final booking = bookingWithAccount.booking;
    final currencyFormat = NumberFormat.currency(locale: 'de_DE', symbol: '€');

    final dateString = booking.date.toString();
    final date = DateTime.parse(
        '${dateString.substring(0, 4)}-${dateString.substring(4, 6)}-${dateString.substring(6, 8)}');
    final day = DateFormat('dd').format(date);
    final month = DateFormat('MMM', 'de_DE').format(date);
    final year = DateFormat('yyyy').format(date);

    String accountName = bookingWithAccount.account?.name ?? 'Unknown Account';
    Color amountColor = booking.amount < 0 ? Colors.red : Colors.green;

    return AlertDialog(
      title: Text(
        l10n.deleteBookingConfirmation,
        textScaler: const TextScaler.linear(0.8),
      ),
      contentPadding: const EdgeInsets.all(2),
      content: Card(
        margin: const EdgeInsets.all(16.0),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    day,
                    textScaler: const TextScaler.linear(0.8)
                  ),
                  Text(
                      month,
                      textScaler: const TextScaler.linear(0.8)
                  ),
                  Text(
                      year,
                      textScaler: const TextScaler.linear(0.8)
                  )
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(booking.category, style: Theme.of(context).textTheme.titleMedium),
                    Text(accountName, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Text(
                currencyFormat.format(booking.amount),
                style: TextStyle(color: amountColor, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton.tonal(
          onPressed: () async {
            await db.bookingsDao.deleteBookingAndUpdateAccount(booking.id);
            if (context.mounted) {
              Navigator.of(context).pop(); // Close the dialog
            }
          },
          child: Text(l10n.delete),
        ),
      ],
    );
  }
}
