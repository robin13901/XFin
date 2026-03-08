import 'dart:async';

import 'package:flutter/material.dart';
import 'package:xfin/database/app_database.dart';
import 'package:xfin/database/daos/bookings_dao.dart';
import 'package:xfin/l10n/app_localizations.dart';

import '../constants/spacing.dart';
import '../mixins/database_provider_mixin.dart';
import '../mixins/nav_bar_visibility_mixin.dart';
import '../models/filter/booking_filter_config.dart';
import '../models/filter/filter_rule.dart';
import '../utils/format.dart';
import '../utils/modal_helper.dart';
import '../widgets/dialogs.dart';
import '../widgets/filter/filter_badge.dart';
import '../widgets/filter/filter_panel.dart';
import '../widgets/filter/liquid_glass_search_bar.dart';
import '../widgets/forms/booking_form.dart';
import '../widgets/liquid_glass_widgets.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  static void showBookingForm(BuildContext context, Booking? booking) {
    showFormModal(context, BookingForm(booking: booking));
  }

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen>
    with DatabaseProviderMixin<BookingsScreen>, NavBarVisibilityMixin<BookingsScreen> {
  late final ScrollController _scrollController;
  final List<BookingWithAccountAndAsset> _items = [];

  bool _isLoading = false;
  bool _hasMore = true;

  static const int _initialLimit = 15;
  static const int _pageSize = 30;
  StreamSubscription<List<BookingWithAccountAndAsset>>? _pageSub;
  int _currentLimit = _initialLimit;

  bool _initialized = false;

  // Search state
  bool _showSearchBar = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _searchDebounce;
  final FocusNode _searchFocusNode = FocusNode();

  // Filter state
  List<FilterRule> _filterRules = [];
  bool _showFilterPanel = false;

  int get _activeFilterCount => _filterRules.length;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    _searchFocusNode.addListener(_onSearchFocusChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _loadInitial();
    }
  }

  @override
  void dispose() {
    _pageSub?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    _searchDebounce?.cancel();
    _searchFocusNode.removeListener(_onSearchFocusChanged);
    _searchFocusNode.dispose();
    restoreNavBarVisibility();
    super.dispose();
  }

  void _onSearchFocusChanged() {
    setSearchFocused(_searchFocusNode.hasFocus);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels >
        _scrollController.position.maxScrollExtent - 300) {
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
    if (mounted) setState(() {});

    _pageSub = db.bookingsDao
        .watchBookingsPage(
      limit: limit,
      searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
      filterRules: _filterRules.isNotEmpty ? _filterRules : null,
    )
        .listen((page) {
      if (!mounted) return;
      _isLoading = false;
      _items
        ..clear()
        ..addAll(page);
      _hasMore = page.length >= limit;
      if (mounted) setState(() {});
    }, onError: (e) {
      if (!mounted) return;
      _isLoading = false;
      if (mounted) setState(() {});
    });
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (_searchQuery != value) {
        setState(() => _searchQuery = value);
        _loadInitial();
      }
    });
  }

  void _showSearch() {
    setState(() => _showSearchBar = true);
    // Request focus after frame builds
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  void _hideSearch() {
    _searchFocusNode.unfocus();
    setState(() {
      _showSearchBar = false;
      _searchController.clear();
      if (_searchQuery.isNotEmpty) {
        _searchQuery = '';
        _loadInitial();
      }
    });
  }

  void _onFilterRulesChanged(List<FilterRule> rules) {
    setState(() => _filterRules = rules);
    _loadInitial();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final statusBarHeight = MediaQuery.of(context).padding.top;
    // Add space for search bar only when visible
    final searchBarSpace = _showSearchBar ? 60.0 : 0.0;
    updateKeyboardVisibility(context);

    return Scaffold(
      body: Stack(
        children: [
          if (_items.isEmpty && _isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_items.isEmpty)
            Center(
              child: Text(
                _searchQuery.isNotEmpty || _filterRules.isNotEmpty
                    ? l10n.noMatchingBookings
                    : l10n.noBookingsYet,
              ),
            )
          else
            ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.only(
                top: statusBarHeight + kToolbarHeight + searchBarSpace,
                bottom: 92,
              ),
              itemCount: _items.length + (_hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= _items.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: Spacing.medium),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final item = _items[index];
                final booking = item.booking;
                final asset = item.asset;
                final valueColor =
                    booking.value < 0 ? Colors.red : Colors.green;
                final dateText =
                    dateFormat.format(intToDateTime(booking.date)!);

                return ListTile(
                  title: Text(booking.category),
                  subtitle: Text(item.account.name),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (asset.id == 1)
                        Text(
                          formatCurrency(booking.value),
                          style: TextStyle(
                              color: valueColor, fontWeight: FontWeight.bold),
                        )
                      else
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                  text:
                                      '${booking.shares} ${asset.currencySymbol ?? asset.tickerSymbol} ≈ ',
                                  style: const TextStyle(color: Colors.grey)),
                              TextSpan(
                                  text: formatCurrency(booking.value),
                                  style: TextStyle(
                                      color: valueColor,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      Text(dateText,
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                  onTap: () => BookingsScreen.showBookingForm(context, booking),
                  onLongPress: () =>
                      showDeleteDialog(context, booking: booking),
                );
              },
            ),

          // Search bar (below app bar) - overlay mode
          if (_showSearchBar)
            Positioned(
              top: statusBarHeight + kToolbarHeight + 8,
              left: 16,
              right: 16,
              child: LiquidGlassSearchBar(
                controller: _searchController,
                focusNode: _searchFocusNode,
                hintText: l10n.searchBookings,
                onChanged: _onSearchChanged,
              ),
            ),

          // Filter panel overlay
          if (_showFilterPanel)
            FilterPanel(
              config: buildBookingFilterConfig(l10n, db),
              currentRules: _filterRules,
              onRulesChanged: _onFilterRulesChanged,
              onClose: () {
                setState(() => _showFilterPanel = false);
                setFilterPanelOpen(false);
              },
            ),

          // App bar with actions
          buildLiquidGlassAppBar(
            context,
            title: Text(l10n.bookings),
            showBackButton: false,
            actions: [
              IconButton(
                icon: Icon(
                  _showSearchBar ? Icons.search_off : Icons.search,
                  size: 22,
                ),
                onPressed: _showSearchBar ? _hideSearch : _showSearch,
              ),
              FilterBadge(
                count: _activeFilterCount,
                child: IconButton(
                  icon: const Icon(Icons.filter_list, size: 22),
                  onPressed: () {
                    setState(() => _showFilterPanel = true);
                    setFilterPanelOpen(true);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
