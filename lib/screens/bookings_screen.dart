import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:xfin/database/app_database.dart';
import 'package:xfin/database/daos/bookings_dao.dart';
import 'package:xfin/l10n/app_localizations.dart';
import 'package:xfin/widgets/booking_form.dart';
import 'package:xfin/widgets/delete_booking_dialog.dart';

import '../widgets/liquid_glass_widgets.dart';


class BookingsScreen extends StatelessWidget {
  const BookingsScreen({super.key});

  static void showBookingForm(BuildContext context, Booking? booking, Stopwatch stopwatch) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => BookingForm(booking: booking, stopwatch: stopwatch,),
    );
  }

  Future<void> _showDeleteDialog(BuildContext context,
      BookingWithAccountAndAsset bookingWithAccountAndAsset) async {
    await showDialog(
      context: context,
      builder: (_) => DeleteBookingDialog(
          bookingWithAccountAndAsset: bookingWithAccountAndAsset),
    );
  }

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<AppDatabase>(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Stack(
        children: [
          StreamBuilder<List<BookingWithAccountAndAsset>>(
            stream: db.bookingsDao.watchBookingsWithAccountAndAsset(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                    child:
                        Text(l10n.anErrorOccurred(snapshot.error.toString())));
              }
              final bookingsWithAccounts = snapshot.data ?? [];
              if (bookingsWithAccounts.isEmpty) {
                return Center(child: Text(l10n.noBookingsYet));
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
                itemCount: bookingsWithAccounts.length,
                itemBuilder: (context, index) {
                  final item = bookingsWithAccounts[index];
                  final booking = item.booking;
                  final asset = item.asset;

                  Color amountColor =
                      booking.shares < 0 ? Colors.red : Colors.green;

                  final dateString = booking.date.toString();
                  final date = DateTime.parse(
                      '${dateString.substring(0, 4)}-${dateString.substring(4, 6)}-${dateString.substring(6, 8)}');
                  final dateText = dateFormat.format(date);

                  return ListTile(
                    title: Text(booking.category),
                    subtitle: Text(item.account.name),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (asset.id == 1) ...[
                          Text(
                            currencyFormat.format(booking.value),
                            style: TextStyle(
                                color: amountColor,
                                fontWeight: FontWeight.bold),
                          ),
                        ] else ...[
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text:
                                  '${booking.shares} ${Unicode.RLI}${asset.currencySymbol ?? asset.tickerSymbol}${Unicode.PDI} ≈ ',
                                  style: const TextStyle(color: Colors.grey),
                                ),
                                TextSpan(
                                  text: currencyFormat.format(booking.value),
                                  style: TextStyle(color: amountColor),
                                ),
                              ],
                            ),
                          ),
                        ],
                        Text(dateText,
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                    onTap: () => showBookingForm(context, booking, Stopwatch()),
                    onLongPress: () => _showDeleteDialog(context, item),
                  );
                },
              );
            },
          ),
          buildLiquidGlassAppBar(context, title: Text(l10n.bookings)),
        ],
      ),
    );
  }
}
