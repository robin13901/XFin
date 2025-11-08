import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:xfin/database/app_database.dart';
import 'package:xfin/database/daos/bookings_dao.dart';
import 'package:xfin/l10n/app_localizations.dart';
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

  Future<void> _showDeleteDialog(
      BuildContext context, BookingWithAccount bookingWithAccounts) async {
    await showDialog(
      context: context,
      builder: (_) =>
          DeleteBookingDialog(bookingWithAccount: bookingWithAccounts),
    );
  }

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<AppDatabase>(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.bookings),
      ),
      body: StreamBuilder<List<BookingWithAccount>>(
        stream: db.bookingsDao.watchBookingsWithAccount(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
                child: Text(l10n.anErrorOccurred(snapshot.error.toString())));
          }
          final bookingsWithAccounts = snapshot.data ?? [];
          if (bookingsWithAccounts.isEmpty) {
            return Center(child: Text(l10n.noBookingsYet));
          }

          final currencyFormat =
              NumberFormat.currency(locale: 'de_DE', symbol: '€');
          final dateFormat = DateFormat('dd.MM.yyyy');

          return ListView.builder(
            itemCount: bookingsWithAccounts.length,
            itemBuilder: (context, index) {
              final item = bookingsWithAccounts[index];
              final booking = item.booking;

              Color amountColor = booking.amount < 0 ? Colors.red : Colors.green;

              final dateString = booking.date.toString();
              final date = DateTime.parse(
                  '${dateString.substring(0, 4)}-${dateString.substring(4, 6)}-${dateString.substring(6, 8)}');
              final dateText = dateFormat.format(date);

              return ListTile(
                title: Text(booking.category),
                subtitle: Text(item.account?.name ?? l10n.unknownAccount),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      currencyFormat.format(booking.amount),
                      style: TextStyle(
                          color: amountColor, fontWeight: FontWeight.bold),
                    ),
                    Text(dateText,
                        style: Theme.of(context).textTheme.bodySmall),
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