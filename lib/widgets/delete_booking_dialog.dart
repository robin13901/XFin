import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:xfin/database/app_database.dart';
import 'package:xfin/database/bookings_dao.dart';

class DeleteBookingDialog extends StatelessWidget {
  final BookingWithAccounts bookingWithAccounts;

  const DeleteBookingDialog({super.key, required this.bookingWithAccounts});

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<AppDatabase>(context, listen: false);
    final booking = bookingWithAccounts.booking;
    final currencyFormat = NumberFormat.currency(locale: 'de_DE', symbol: '€');

    final date = DateTime.fromMillisecondsSinceEpoch(booking.date);
    final day = DateFormat('dd').format(date);
    final month = DateFormat('MMM', 'de_DE').format(date);
    final year = DateFormat('yyyy').format(date);

    String accountFlowText;
    Color amountColor;

    final isTransfer = booking.sendingAccountId != null;
    if (isTransfer) {
      accountFlowText = '${bookingWithAccounts.sendingAccount!.name} → ${bookingWithAccounts.receivingAccount!.name}';
      amountColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    } else {
      accountFlowText = bookingWithAccounts.receivingAccount?.name ?? 'Unknown Account';
      amountColor = booking.amount < 0 ? Colors.red : Colors.green;
    }

    return AlertDialog(
      title: const Text('Willst du diesen Eintrag wirklich löschen?'),
      content: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [Text(day), Text(month), Text(year)],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(booking.reason, style: Theme.of(context).textTheme.titleMedium),
                    Text(accountFlowText, style: Theme.of(context).textTheme.bodySmall),
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
          child: const Text('Abbrechen'),
        ),
        FilledButton.tonal(
          onPressed: () async {
            await db.bookingsDao.deleteBookingWithBalance(booking.id);
            if (context.mounted) {
              Navigator.of(context).pop(); // Close the dialog
            }
          },
          child: const Text('Löschen'),
        ),
      ],
    );
  }
}
