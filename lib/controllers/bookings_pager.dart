import 'dart:async';
import 'package:flutter/cupertino.dart';
import '../database/daos/bookings_dao.dart';

class BookingsPager extends ChangeNotifier {
  BookingsPager(this._dao);

  final BookingsDao _dao;
  final List<BookingWithAccountAndAsset> _items = [];
  StreamSubscription<List<BookingWithAccountAndAsset>>? _sub;

  bool _isLoading = false;
  bool _hasMore = true;

  List<BookingWithAccountAndAsset> get items => List.unmodifiable(_items);
  bool get hasMore => _hasMore;

  void loadInitial() {
    _items.clear();
    _hasMore = true;
    _loadPage(limit: 15);
  }

  void loadMore() {
    if (_isLoading || !_hasMore) return;
    _loadPage(limit: 30);
  }

  void _loadPage({required int limit}) {
    _isLoading = true;
    final last = _items.isNotEmpty ? _items.last : null;

    _sub?.cancel();
    _sub = _dao
        .watchBookingsPage(
      limit: limit,
      lastDate: last?.booking.date,
      lastValue: last?.booking.value,
    ).listen((page) {
      _isLoading = false;

      if (page.isEmpty) {
        _hasMore = false;
        notifyListeners();
        return;
      }

      _items.addAll(page);
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}