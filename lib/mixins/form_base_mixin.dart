import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../database/app_database.dart';
import '../l10n/app_localizations.dart';
import '../providers/database_provider.dart';
import '../utils/validators.dart';
import '../widgets/form_fields.dart';

/// Mixin that handles common form initialization for stateful widgets.
///
/// This eliminates duplicated form setup code across multiple form widgets.
///
/// Usage:
/// ```dart
/// class MyFormState extends State<MyForm> with FormBaseMixin<MyForm> {
///   // Form-specific implementation
/// }
/// ```
mixin FormBaseMixin<T extends StatefulWidget> on State<T> {
  final formKey = GlobalKey<FormState>();

  late AppDatabase db;
  late AppLocalizations l10n;
  late Validator validator;
  late FormFields formFields;

  bool renderHeavy = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    db = context.read<DatabaseProvider>().db;
    l10n = AppLocalizations.of(context)!;
    validator = Validator(l10n);
    formFields = FormFields(l10n, validator, context);
  }

  /// Call this method to enable heavy rendering after loading data.
  void enableHeavyRendering() {
    if (mounted) {
      setState(() {
        renderHeavy = true;
      });
    }
  }
}
