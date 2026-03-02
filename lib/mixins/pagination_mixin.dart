import 'dart:async';
import 'package:flutter/material.dart';

/// Mixin that handles scroll pagination for list screens.
///
/// This eliminates duplicated pagination code across multiple screens.
///
/// Usage:
/// ```dart
/// class MyScreenState extends State<MyScreen> with PaginationMixin<MyScreen, MyItemType> {
///   @override
///   void loadInitialData() {
///     // Load first page
///   }
///
///   @override
///   void loadMoreData() {
///     // Load next page
///   }
/// }
/// ```
mixin PaginationMixin<T extends StatefulWidget, I> on State<T> {
  final ScrollController scrollController = ScrollController();
  final List<I> items = [];

  bool isLoading = false;
  bool hasMore = true;

  static const int initialLimit = 15;
  static const int pageSize = 30;

  int currentLimit = initialLimit;
  StreamSubscription<List<I>>? pageSub;

  /// Override this method to load initial data.
  void loadInitialData();

  /// Override this method to load more data.
  void loadMoreData();

  @override
  void initState() {
    super.initState();
    scrollController.addListener(onScroll);
  }

  void onScroll() {
    if (!scrollController.hasClients) return;
    if (scrollController.position.pixels > scrollController.position.maxScrollExtent - 300) {
      loadMore();
    }
  }

  Future<void> loadInitial() async {
    pageSub?.cancel();
    items.clear();
    hasMore = true;
    currentLimit = initialLimit;
    loadInitialData();
  }

  Future<void> loadMore() async {
    if (isLoading || !hasMore) return;
    currentLimit += pageSize;
    loadMoreData();
  }

  @override
  void dispose() {
    pageSub?.cancel();
    scrollController.removeListener(onScroll);
    scrollController.dispose();
    super.dispose();
  }
}
