import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:xfin/database/app_database.dart';
import 'package:xfin/database/daos/bookings_dao.dart';
import 'package:xfin/l10n/app_localizations.dart';
import 'package:xfin/widgets/booking_form.dart';

import '../widgets/dialogs.dart';
import '../widgets/liquid_glass_widgets.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  static void showBookingForm(
      BuildContext context, Booking? booking) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => BookingForm(booking: booking),
    );
  }

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  late final AppDatabase db;
  late final ScrollController _scrollController;

  final List<BookingWithAccountAndAsset> _items = [];

  bool _isLoading = false;
  bool _hasMore = true;

  static const int _initialLimit = 15;
  static const int _pageSize = 30;
  StreamSubscription<List<BookingWithAccountAndAsset>>? _pageSub;
  int _currentLimit = _initialLimit;

  final Stopwatch _stopwatch = Stopwatch();

  @override
  void initState() {
    super.initState();
    _stopwatch.start();
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    db = Provider.of<AppDatabase>(context, listen: false);

    if (_items.isEmpty) {
      _loadInitial();
    }
  }

  @override
  void dispose() {
    _pageSub?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >
        _scrollController.position.maxScrollExtent - 300) {
      _loadMore();
    }
  }

  Future<void> _loadInitial() async {
    _items.clear();
    _hasMore = true;
    _currentLimit = _initialLimit;
    _subscribeForLimit(_currentLimit);
  }

  Future<void> _loadMore() async {
    if (_isLoading || !_hasMore) return;
    // increase the watched limit and re-subscribe
    _currentLimit += _pageSize;
    _subscribeForLimit(_currentLimit);
  }

  void _subscribeForLimit(int limit) {
    // Cancel previous subscription if any
    _pageSub?.cancel();

    _isLoading = true;
    setState(() {});

    _pageSub = db.bookingsDao
        .watchBookingsPage(limit: limit)
        .listen((page) {
      _isLoading = false;

      // Replace the items with the current page snapshot
      _items
        ..clear()
        ..addAll(page);

      // If we received fewer rows than requested, there's no more to load.
      _hasMore = page.length >= limit;

      if (mounted) setState(() {});
    }, onError: (e) {
      // keep previous _hasMore as-is; show no crash
      _isLoading = false;
      if (mounted) setState(() {});
    });
  }

  static final _currencyFormat =
  NumberFormat.currency(locale: 'de_DE', symbol: '€');
  static final _dateFormat = DateFormat('dd.MM.yyyy');

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Stack(
        children: [
          if (_items.isEmpty && _isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_items.isEmpty)
            Center(child: Text(l10n.noBookingsYet))
          else
            ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.only(
                top:
                MediaQuery.of(context).padding.top + kToolbarHeight,
                bottom: 92,
              ),
              itemCount: _items.length + (_hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= _items.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final item = _items[index];
                final booking = item.booking;
                final asset = item.asset;

                final valueColor =
                booking.value < 0 ? Colors.red : Colors.green;

                final dateString = booking.date.toString();
                final date = DateTime.parse(
                  '${dateString.substring(0, 4)}-'
                      '${dateString.substring(4, 6)}-'
                      '${dateString.substring(6, 8)}',
                );
                final dateText = _dateFormat.format(date);

                return ListTile(
                  title: Text(booking.category),
                  subtitle: Text(item.account.name),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (asset.id == 1)
                        Text(
                          _currencyFormat.format(booking.value),
                          style: TextStyle(
                            color: valueColor,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      else
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text:
                                '${booking.shares} ${Unicode.RLI}${asset.currencySymbol ?? asset.tickerSymbol}${Unicode.PDI} ≈ ',
                                style:
                                const TextStyle(color: Colors.grey),
                              ),
                              TextSpan(
                                text: _currencyFormat
                                    .format(booking.value),
                                style:
                                TextStyle(color: valueColor),
                              ),
                            ],
                          ),
                        ),
                      Text(
                        dateText,
                        style:
                        Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  onTap: () => BookingsScreen.showBookingForm(
                    context,
                    booking,
                  ),
                  onLongPress: () => showDeleteDialog(context, booking: booking),
                );
              },
            ),
          buildLiquidGlassAppBar(
            context,
            title: Text(l10n.bookings),
          ),
        ],
      ),
    );
  }
}