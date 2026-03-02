import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../database/app_database.dart';
import '../providers/database_provider.dart';

/// Mixin that handles common database provider setup for stateful widgets.
///
/// This eliminates duplicated database provider access code across multiple screens.
///
/// Usage:
/// ```dart
/// class MyScreenState extends State<MyScreen> with DatabaseProviderMixin<MyScreen> {
///   @override
///   void _onDbChanged() {
///     // Handle database changes
///   }
/// }
/// ```
mixin DatabaseProviderMixin<T extends StatefulWidget> on State<T> {
  late AppDatabase db;
  late DatabaseProvider _dbProvider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _dbProvider = context.read<DatabaseProvider>();
    db = _dbProvider.db;
    _dbProvider.addListener(_onDbChanged);
  }

  /// Override this method to handle database changes.
  void _onDbChanged();

  @override
  void dispose() {
    _dbProvider.removeListener(_onDbChanged);
    super.dispose();
  }
}
