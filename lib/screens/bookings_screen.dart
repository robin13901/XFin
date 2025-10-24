import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:xfin/database/app_database.dart';
import 'package:xfin/database/bookings_dao.dart';
import 'package:xfin/widgets/booking_form.dart';
import 'package:xfin/widgets/delete_booking_dialog.dart';

class BookingsScreen extends StatelessWidget {
  const BookingsScreen({super.key});

  void _showBookingForm(BuildContext context, Booking? booking) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => BookingForm(booking: booking),
    );
  }

  void _showDeleteDialog(BuildContext context, BookingWithAccounts bookingWithAccounts) {
    showDialog(
      context: context,
      builder: (_) => DeleteBookingDialog(bookingWithAccounts: bookingWithAccounts),
    );
  }

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<AppDatabase>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bookings'),
      ),
      body: StreamBuilder<List<BookingWithAccounts>>(
        stream: db.bookingsDao.watchBookingsWithAccounts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('An error occurred: ${snapshot.error}'));
          }
          final bookingsWithAccounts = snapshot.data ?? [];
          if (bookingsWithAccounts.isEmpty) {
            return const Center(child: Text('No bookings yet.'));
          }

          final currencyFormat = NumberFormat.currency(locale: 'de_DE', symbol: '€');
          final dateFormat = DateFormat.yMd();

          return ListView.builder(
            itemCount: bookingsWithAccounts.length,
            itemBuilder: (context, index) {
              final item = bookingsWithAccounts[index];
              final booking = item.booking;

              String accountFlowText;
              Color amountColor;

              final isTransfer = booking.sendingAccountId != null;

              if (isTransfer) {
                accountFlowText = '${item.sendingAccount!.name} → ${item.receivingAccount!.name}';
                amountColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
              } else {
                accountFlowText = item.receivingAccount?.name ?? 'Unknown Account';
                amountColor = booking.amount < 0 ? Colors.red : Colors.green;
              }

              final dateText = dateFormat.format(DateTime.fromMillisecondsSinceEpoch(booking.date));

              return ListTile(
                title: Text(booking.reason ?? 'Überweisung'),
                subtitle: Text(accountFlowText),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      currencyFormat.format(booking.amount),
                      style: TextStyle(color: amountColor, fontWeight: FontWeight.bold),
                    ),
                    Text(dateText, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
                onTap: () => _showBookingForm(context, booking),
                onLongPress: () => _showDeleteDialog(context, item),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showBookingForm(context, null),
        child: const Icon(Icons.add),
      ),
    );
  }
}
