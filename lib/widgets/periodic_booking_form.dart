import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xfin/utils/format.dart';
import 'package:xfin/utils/global_constants.dart';

import '../database/app_database.dart';
import '../database/tables.dart';
import '../l10n/app_localizations.dart';
import '../providers/database_provider.dart';
import '../utils/validators.dart';
import 'dialogs.dart';
import 'form_fields.dart';

class PeriodicBookingForm extends StatefulWidget {
  final PeriodicBooking? periodicBooking;
  final List<Asset>? preloadedAssets;
  final List<Account>? preloadedAccounts;

  const PeriodicBookingForm({
    super.key,
    this.periodicBooking,
    this.preloadedAssets,
    this.preloadedAccounts,
  });

  @override
  State<PeriodicBookingForm> createState() => _PeriodicBookingFormState();
}

class _PeriodicBookingFormState extends State<PeriodicBookingForm> {
  final _formKey = GlobalKey<FormState>();
  late AppDatabase _db;
  late AppLocalizations _l10n;
  late Validator _validator;
  late FormFields _formFields;

  // Controllers
  late TextEditingController _dateCtrl;
  late TextEditingController _sharesCtrl;
  late TextEditingController _categoryCtrl;
  late TextEditingController _notesCtrl;

  // Form values
  static const int _assetId = 1;
  late DateTime _nextExecDate;
  late Cycles _selectedCycle;
  int? _accountId;

  // Data from DB
  List<Asset> _assets = [];
  List<Account> _accounts = [];
  List<String> _distinctCategories = [];

  bool get _isEditing => widget.periodicBooking != null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _l10n = AppLocalizations.of(context)!;
    _validator = Validator(_l10n);
    _formFields = FormFields(_l10n, _validator, context);
  }

  @override
  void initState() {
    super.initState();
    final pb = widget.periodicBooking;
    _db = context.read<DatabaseProvider>().db;

    _nextExecDate =
        pb == null ? addMonths(DateTime.now(), 1) : intToDateTime(pb.nextExecutionDate)!;
    _selectedCycle = pb?.cycle ?? Cycles.monthly;

    _db.bookingsDao
        .getDistinctCategories()
        .then((v) => setState(() => _distinctCategories = v));

    _dateCtrl = TextEditingController(text: dateFormat.format(_nextExecDate));
    _sharesCtrl = TextEditingController(text: pb?.shares.toString() ?? '');
    _categoryCtrl = TextEditingController(text: pb?.category ?? '');
    _notesCtrl = TextEditingController(text: pb?.notes ?? '');

    _assets = widget.preloadedAssets ?? [];
    _accounts = widget.preloadedAccounts ?? [];

    if (_isEditing) _accountId = widget.periodicBooking!.accountId;
  }

  @override
  void dispose() {
    _dateCtrl.dispose();
    _sharesCtrl.dispose();
    _categoryCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  double _monthlyFactorForCycle(Cycles c) {
    switch (c) {
      case Cycles.daily:
        return 30.436875;
      case Cycles.weekly:
        return 30.436875 / 7;
      case Cycles.monthly:
        return 1.0;
      case Cycles.quarterly:
        return 1.0 / 3.0;
      case Cycles.yearly:
        return 1.0 / 12.0;
    }
  }

  Future<void> _saveForm() async {
    if (!_formKey.currentState!.validate()) return;

    final intNextExecutionDate = dateTimeToInt(_nextExecDate);
    final shares = double.parse(_sharesCtrl.text.replaceAll(',', '.'));
    final notes = _notesCtrl.text.trim();
    final monthlyAverageFactor = _monthlyFactorForCycle(_selectedCycle);

    final companion = PeriodicBookingsCompanion(
      nextExecutionDate: drift.Value(intNextExecutionDate),
      assetId: const drift.Value(_assetId),
      accountId: drift.Value(_accountId!),
      shares: drift.Value(shares),
      costBasis: const drift.Value(1),
      value: drift.Value(shares),
      category: drift.Value(_categoryCtrl.text.trim()),
      notes: notes.isEmpty ? const drift.Value.absent() : drift.Value(notes),
      cycle: drift.Value(_selectedCycle),
      monthlyAverageFactor: drift.Value(monthlyAverageFactor),
    );

    try {
      if (_isEditing) {
        final id = widget.periodicBooking!.id;
        final toSave = companion.copyWith(id: drift.Value(id));
        await _db.periodicBookingsDao.updatePeriodicBooking(toSave);
      } else {
        await _db.periodicBookingsDao.insertPeriodicBooking(companion);
      }
      if (mounted) Navigator.of(context).pop();
      int executedCount = await _db.periodicBookingsDao.executePending(_l10n);
      if (executedCount > 0 && mounted) {
        showInfoDialog(context, _l10n.standingOrdersExecuted,
            _l10n.nStandingOrdersExecuted(executedCount));
      }
    } catch (e) {
      if (mounted) showErrorDialog(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: MediaQuery.of(context).viewInsets,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _formFields.dateAndAssetRow(
                    dateController: _dateCtrl,
                    date: _nextExecDate,
                    dateLabel: _l10n.nextExecutionDate,
                    customDateValidator: _validator.validateDateInFuture,
                    onDateChanged: (v) => setState(() => _nextExecDate = v),
                    assets: _assets,
                    assetsEditable: false,
                    assetId: _assetId),
                const SizedBox(height: 16),
                _formFields.cyclesDropdown(
                    cycles: Cycles.values,
                    value: 2,
                    onChanged: (v) =>
                        setState(() => _selectedCycle = Cycles.values[v!])),
                const SizedBox(height: 16),
                _formFields.accountDropdown(
                    accounts: _accounts,
                    value: _accountId,
                    onChanged: (v) => setState(() => _accountId = v)),
                const SizedBox(height: 16),
                _formFields.sharesField(
                    _sharesCtrl, _assets.firstWhere((a) => a.id == _assetId)),
                const SizedBox(height: 16),
                _formFields.categoryField(_categoryCtrl, _distinctCategories),
                const SizedBox(height: 12),
                _formFields.notesField(_notesCtrl),
                const SizedBox(height: 20),
                _formFields.footerButtons(context, _saveForm),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
