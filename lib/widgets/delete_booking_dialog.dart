import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:xfin/database/app_database.dart';
import 'package:xfin/database/daos/bookings_dao.dart';

class DeleteBookingDialog extends StatelessWidget {
  final BookingWithAccount bookingWithAccounts;

  const DeleteBookingDialog({super.key, required this.bookingWithAccounts});

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<AppDatabase>(context, listen: false);
    final booking = bookingWithAccounts.booking;
    final currencyFormat = NumberFormat.currency(locale: 'de_DE', symbol: '€');

    final dateString = booking.date.toString();
    final date = DateTime.parse(
        '${dateString.substring(0, 4)}-${dateString.substring(4, 6)}-${dateString.substring(6, 8)}');
    final day = DateFormat('dd').format(date);
    final month = DateFormat('MMM', 'de_DE').format(date);
    final year = DateFormat('yyyy').format(date);

    String accountName = bookingWithAccounts.account?.name ?? 'Unknown Account';
    Color amountColor = booking.amount < 0 ? Colors.red : Colors.green;

    return AlertDialog(
      title: const Text(
          'Willst du diesen Eintrag wirklich löschen?',
        textScaler: TextScaler.linear(0.8),
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
                    Text(booking.reason, style: Theme.of(context).textTheme.titleMedium),
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
          child: const Text('Abbrechen'),
        ),
        FilledButton.tonal(
          onPressed: () async {
            await db.bookingsDao.deleteBookingAndUpdateAccount(booking.id);
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
