import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:xfin/database/app_database.dart';
import 'package:xfin/database/daos/bookings_dao.dart';
import 'package:xfin/l10n/app_localizations.dart';
import 'package:xfin/widgets/booking_form.dart';

import '../providers/database_provider.dart';
import '../widgets/dialogs.dart';
import '../widgets/liquid_glass_widgets.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  static void showBookingForm(BuildContext context, Booking? booking) {
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
  late AppDatabase db;
  late final ScrollController _scrollController;

  final List<BookingWithAccountAndAsset> _items = [];

  bool _isLoading = false;
  bool _hasMore = true;

  static const int _initialLimit = 15;
  static const int _pageSize = 30;
  StreamSubscription<List<BookingWithAccountAndAsset>>? _pageSub;
  int _currentLimit = _initialLimit;

  static final _currencyFormat = NumberFormat.currency(locale: 'de_DE', symbol: '€');
  static final _dateFormat = DateFormat('dd.MM.yyyy');

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);

    final dbProvider = context.read<DatabaseProvider>();
    db = dbProvider.db;
    dbProvider.addListener(_onDbChanged);

    _loadInitial();
  }

  void _onDbChanged() {
    if (!mounted) return;
    final newDb = context.read<DatabaseProvider>().db;
    if (identical(newDb, db)) return;

    setState(() {
      db = newDb;
      _loadInitial();
    });
  }

  @override
  void dispose() {
    // Remove listener first so we don't receive callbacks while disposing.
    try {
      context.read<DatabaseProvider>().removeListener(_onDbChanged);
    } catch (_) {}

    // Cancel subscriptions and controllers before super.dispose()
    _pageSub?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();

    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels > _scrollController.position.maxScrollExtent - 300) {
      _loadMore();
    }
  }

  Future<void> _loadInitial() async {
    _pageSub?.cancel();
    _items.clear();
    _hasMore = true;
    _currentLimit = _initialLimit;
    _subscribeForLimit(_currentLimit);
  }

  Future<void> _loadMore() async {
    if (_isLoading || !_hasMore) return;
    _currentLimit += _pageSize;
    _subscribeForLimit(_currentLimit);
  }

  void _subscribeForLimit(int limit) {
    _pageSub?.cancel();

    _isLoading = true;
    setState(() {});

    _pageSub = db.bookingsDao.watchBookingsPage(limit: limit).listen((page) {
      _isLoading = false;

      _items
        ..clear()
        ..addAll(page);

      _hasMore = page.length >= limit;

      if (mounted) setState(() {});
    }, onError: (e) {
      _isLoading = false;
      if (mounted) setState(() {});
    });
  }

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
                top: MediaQuery.of(context).padding.top + kToolbarHeight,
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

                final valueColor = booking.value < 0 ? Colors.red : Colors.green;

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
                          style: TextStyle(color: valueColor, fontWeight: FontWeight.bold),
                        )
                      else
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(text: '${booking.shares} ${asset.currencySymbol ?? asset.tickerSymbol} ≈ ', style: const TextStyle(color: Colors.grey)),
                              TextSpan(text: _currencyFormat.format(booking.value), style: TextStyle(color: valueColor)),
                            ],
                          ),
                        ),
                      Text(dateText, style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                  onTap: () => BookingsScreen.showBookingForm(context, booking),
                  onLongPress: () => showDeleteDialog(context, booking: booking),
                );
              },
            ),
          buildLiquidGlassAppBar(context, title: Text(l10n.bookings)),
        ],
      ),
    );
  }
}
