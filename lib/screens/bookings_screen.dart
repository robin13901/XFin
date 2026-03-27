import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xfin/database/app_database.dart';
import 'package:xfin/database/daos/bookings_dao.dart';
import 'package:xfin/l10n/app_localizations.dart';

import '../constants/spacing.dart';
import '../mixins/database_provider_mixin.dart';
import '../mixins/nav_bar_visibility_mixin.dart';
import '../mixins/search_filter_mixin.dart';
import '../models/filter/booking_filter_config.dart';
import '../providers/database_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/format.dart';
import '../widgets/dialogs.dart';
import '../widgets/filter/filter_badge.dart';
import '../widgets/filter/filter_panel.dart';
import '../widgets/filter/liquid_glass_search_bar.dart';
import '../widgets/forms/booking_form.dart';
import '../widgets/liquid_glass_widgets.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  /// Show the booking form with preloaded data.
  ///
  /// Looks up the [BookingsScreenState] via the given [key] (preferred) or
  /// by walking the ancestor tree from [context].  Falls back to a plain
  /// async-loading form if neither yields a state.
  static Future<void> showBookingForm(
    BuildContext context,
    Booking? booking, {
    GlobalKey<BookingsScreenState>? key,
  }) {
    final state = key?.currentState ??
        context.findAncestorStateOfType<BookingsScreenState>();
    if (state != null) {
      return state._showBookingForm(context, booking);
    }
    // Fallback: open without preloaded data.
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => BookingForm(booking: booking),
    );
  }

  @override
  State<BookingsScreen> createState() => BookingsScreenState();
}

class BookingsScreenState extends State<BookingsScreen>
    with SingleTickerProviderStateMixin, DatabaseProviderMixin<BookingsScreen>, NavBarVisibilityMixin<BookingsScreen>, SearchFilterMixin<BookingsScreen> {
  late final ScrollController _scrollController;
  late final AnimationController _sheetAnimController;
  final List<BookingWithAccountAndAsset> _items = [];

  bool _isLoading = false;
  bool _hasMore = true;

  static const int _initialLimit = 15;
  static const int _pageSize = 30;
  StreamSubscription<List<BookingWithAccountAndAsset>>? _pageSub;
  int _currentLimit = _initialLimit;

  bool _initialized = false;

  // Preloaded form data — fetched eagerly so the form opens instantly.
  late Future<List<Asset>> _assetsFuture;
  late Future<List<Account>> _accountsFuture;
  late Future<List<String>> _categoriesFuture;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);

    // Zero-duration controller so the bottom-sheet appears instantly.
    _sheetAnimController =
        AnimationController(vsync: this, duration: Duration.zero)..value = 1.0;

    // Start preloading form data immediately (background).
    final appDb = context.read<DatabaseProvider>().db;
    _assetsFuture = appDb.assetsDao.getAllAssets();
    _accountsFuture = appDb.accountsDao.getAllAccounts();
    _categoriesFuture = appDb.bookingsDao.getDistinctCategories();
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
    _sheetAnimController.dispose();
    restoreNavBarVisibility();
    super.dispose();
  }

  /// Show the booking form with preloaded data — no delay.
  Future<void> _showBookingForm(BuildContext context, Booking? booking) async {
    final assets = await _assetsFuture;
    final accounts = (await _accountsFuture).where((a) => !a.isArchived).toList();
    final categories = await _categoriesFuture;

    if (!context.mounted) return;

    final isAurora = ThemeProvider.instance.isAurora;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      transitionAnimationController: _sheetAnimController,
      backgroundColor: isAurora ? Colors.transparent : null,
      builder: (_) {
        final form = BookingForm(
          booking: booking,
          preloadedAssets: assets,
          preloadedAccounts: accounts,
          preloadedCategories: categories,
        );
        if (!isAurora) return form;

        // Lightweight glass-blur card wrapping the form.
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xCC111214),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                border: Border(
                  top: BorderSide(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
              ),
              child: form,
            ),
          ),
        );
      },
    );

    // Refresh preload cache after form closes (data may have changed).
    _assetsFuture = db.assetsDao.getAllAssets();
    _accountsFuture = db.accountsDao.getAllAccounts();
    _categoriesFuture = db.bookingsDao.getDistinctCategories();
  }

  @override
  void onSearchFilterChanged() {
    _loadInitial();
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
      searchQuery: searchQuery.isNotEmpty ? searchQuery : null,
      filterRules: filterRules.isNotEmpty ? filterRules : null,
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final statusBarHeight = MediaQuery.of(context).padding.top;
    updateKeyboardVisibility(context);

    return Scaffold(
      backgroundColor:
          ThemeProvider.instance.isAurora ? Colors.transparent : null,
      body: Stack(
        children: [
          if (_items.isEmpty && _isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_items.isEmpty)
            Center(
              child: Text(
                searchQuery.isNotEmpty || filterRules.isNotEmpty
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
                  onTap: () => _showBookingForm(context, booking),
                  onLongPress: () =>
                      showDeleteDialog(context, booking: booking),
                );
              },
            ),

          // Search bar (below app bar) - overlay mode
          if (showSearchBar)
            Positioned(
              top: statusBarHeight + kToolbarHeight + 8,
              left: 16,
              right: 16,
              child: LiquidGlassSearchBar(
                controller: searchController,
                focusNode: searchFocusNode,
                hintText: l10n.searchBookings,
                onChanged: onSearchChanged,
              ),
            ),

          // Filter panel overlay
          if (showFilterPanel)
            FilterPanel(
              config: buildBookingFilterConfig(l10n, db),
              currentRules: filterRules,
              onRulesChanged: onFilterRulesChanged,
              onClose: closeFilterPanel,
            ),

          // App bar with actions
          buildLiquidGlassAppBar(
            context,
            title: Text(l10n.bookings),
            showBackButton: false,
            actions: [
              IconButton(
                icon: Icon(
                  showSearchBar ? Icons.search_off : Icons.search,
                  size: 22,
                ),
                onPressed: toggleSearch,
              ),
              FilterBadge(
                count: activeFilterCount,
                child: IconButton(
                  icon: const Icon(Icons.filter_list, size: 22),
                  onPressed: openFilterPanel,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
