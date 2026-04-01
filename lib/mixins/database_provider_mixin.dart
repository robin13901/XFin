import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../database/app_database.dart';
import '../providers/database_provider.dart';

/// Mixin that handles common database provider setup for stateful widgets.
///
/// Keeps [db] in sync with [DatabaseProvider] and calls [onDatabaseChanged]
/// when the database instance is replaced (e.g. after a backup import).
///
/// Usage:
/// ```dart
/// class MyScreenState extends State<MyScreen> with DatabaseProviderMixin<MyScreen> {
///   @override
///   void onDatabaseChanged() {
///     // re-subscribe streams, refresh futures, etc.
///   }
/// }
/// ```
mixin DatabaseProviderMixin<T extends StatefulWidget> on State<T> {
  late AppDatabase db;
  DatabaseProvider? _dbProvider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = context.read<DatabaseProvider>();
    if (_dbProvider != provider) {
      _dbProvider?.removeListener(_handleDbChanged);
      _dbProvider = provider;
      _dbProvider!.addListener(_handleDbChanged);
    }
    db = provider.db;
  }

  void _handleDbChanged() {
    final newDb = _dbProvider!.db;
    if (identical(newDb, db)) return;
    db = newDb;
    onDatabaseChanged();
  }

  /// Called when the database instance is replaced (e.g. after a backup import).
  /// Override to refresh streams, futures, or other state tied to [db].
  void onDatabaseChanged() {}

  @override
  void dispose() {
    _dbProvider?.removeListener(_handleDbChanged);
    super.dispose();
  }
}
