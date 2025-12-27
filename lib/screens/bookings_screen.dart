import 'dart:async';

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

  final Stopwatch _stopwatch = Stopwatch();

  @override
  void initState() {
    super.initState();
    _stopwatch.start();

    _scrollController = ScrollController()..addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint(
        'BookingsScreen: first frame painted at ${DateTime.now()} '
            '(${_stopwatch.elapsedMilliseconds} ms)',
      );
    });
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
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >
        _scrollController.position.maxScrollExtent - 300) {
      _loadMore();
    }
  }

  int? get _lastDate =>
      _items.isNotEmpty ? _items.last.booking.date : null;

  double? get _lastShares =>
      _items.isNotEmpty ? _items.last.booking.shares : null;

  Future<void> _loadInitial() async {
    debugPrint(
      'BookingsScreen: loading INITIAL page at ${_stopwatch.elapsedMilliseconds} ms',
    );

    _items.clear();
    _hasMore = true;

    await _loadPage(limit: _initialLimit);
  }

  Future<void> _loadMore() async {
    if (_isLoading || !_hasMore) return;
    await _loadPage(limit: _pageSize);
  }

  Future<void> _loadPage({required int limit}) async {
    _isLoading = true;
    setState(() {});

    try {
      final page = await db.bookingsDao
          .watchBookingsPage(
        limit: limit,
        lastDate: _lastDate,
        lastShares: _lastShares,
      )
          .first;

      debugPrint(
        'BookingsScreen: received ${page.length} rows '
            'after ${_stopwatch.elapsedMilliseconds} ms',
      );

      // If the page is smaller than the requested limit, we've reached the end.
      // This prevents an always-visible loading spinner at the bottom which
      // would keep widget tests from settling (pumpAndSettle).
      if (page.isEmpty) {
        _hasMore = false;
      } else {
        final existingIds = _items.map((e) => e.booking.id).toSet();
        for (final item in page) {
          if (!existingIds.contains(item.booking.id)) {
            _items.add(item);
          }
        }
        // If we received fewer rows than requested, there are no more pages.
        if (page.length < limit) {
          _hasMore = false;
        } else {
          _hasMore = true;
        }
      }
    } catch (e, st) {
      debugPrint('BookingsScreen: error loading page: $e\n$st');
      // On error keep _hasMore as-is (or you could set to false to stop retry).
    } finally {
      _isLoading = false;
      if (mounted) setState(() {});
    }
  }

  Future<void> _showDeleteDialog(
      BuildContext context,
      BookingWithAccountAndAsset bookingWithAccountAndAsset) async {
    await showDialog(
      context: context,
      builder: (_) => DeleteBookingDialog(
        bookingWithAccountAndAsset: bookingWithAccountAndAsset,
      ),
    );
  }

  static final _currencyFormat =
  NumberFormat.currency(locale: 'de_DE', symbol: '€');
  static final _dateFormat = DateFormat('dd.MM.yyyy');

  @override
  Widget build(BuildContext context) {
    debugPrint(
      'BookingsScreen: build called at ${_stopwatch.elapsedMilliseconds} ms '
          '(items=${_items.length}, loading=$_isLoading)',
    );

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

                final amountColor =
                booking.shares < 0 ? Colors.red : Colors.green;

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
                            color: amountColor,
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
                                TextStyle(color: amountColor),
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
                  onLongPress: () => _showDeleteDialog(context, item),
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