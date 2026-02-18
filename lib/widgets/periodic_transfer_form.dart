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

class PeriodicTransferForm extends StatefulWidget {
  final PeriodicTransfer? periodicTransfer;
  final List<Asset>? preloadedAssets;
  final List<Account>? preloadedAccounts;

  const PeriodicTransferForm({
    super.key,
    this.periodicTransfer,
    this.preloadedAssets,
    this.preloadedAccounts,
  });

  @override
  State<PeriodicTransferForm> createState() => _PeriodicTransferFormState();
}

class _PeriodicTransferFormState extends State<PeriodicTransferForm> {
  final _formKey = GlobalKey<FormState>();
  late AppDatabase _db;
  late AppLocalizations _l10n;
  late Validator _validator;
  late FormFields _formFields;

  // Controllers
  late TextEditingController _dateCtrl;
  late TextEditingController _sharesCtrl;
  late TextEditingController _notesCtrl;

  // Form values
  late DateTime _nextExecDate;
  late Cycles _selectedCycle;
  int? _sendingAccountId;
  int? _receivingAccountId;
  int? _assetId;

  // Data from DB
  List<Asset> _assets = [];
  List<Account> _accounts = [];

  bool get _isEditing => widget.periodicTransfer != null;

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
    _db = context.read<DatabaseProvider>().db;
    final pt = widget.periodicTransfer;

    _nextExecDate =
        pt == null ? addMonths(DateTime.now(), 1) : intToDateTime(pt.nextExecutionDate)!;
    _selectedCycle = pt?.cycle ?? Cycles.monthly;
    _assetId = pt?.assetId ?? 1;

    _dateCtrl = TextEditingController(text: dateFormat.format(_nextExecDate));
    _sharesCtrl = TextEditingController(text: pt?.value.toString() ?? '');
    _notesCtrl = TextEditingController(text: pt?.notes ?? '');

    _assets = widget.preloadedAssets ?? [];
    _accounts = widget.preloadedAccounts ?? [];

    if (_isEditing) {
      _sendingAccountId = widget.periodicTransfer!.sendingAccountId;
      _receivingAccountId = widget.periodicTransfer!.receivingAccountId;
    }
  }

  @override
  void dispose() {
    _dateCtrl.dispose();
    _sharesCtrl.dispose();
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
    if (_sendingAccountId == _receivingAccountId) {
      showErrorDialog(context, _l10n.sendingAndReceivingMustDiffer);
      return;
    }

    final intNextExecutionDate = dateTimeToInt(_nextExecDate);
    final shares = double.parse(_sharesCtrl.text.replaceAll(',', '.'));
    final value = shares;
    final notes = _notesCtrl.text.trim();
    final monthlyAverageFactor = _monthlyFactorForCycle(_selectedCycle);

    final companion = PeriodicTransfersCompanion(
      nextExecutionDate: drift.Value(intNextExecutionDate),
      assetId: drift.Value(_assetId!),
      sendingAccountId: drift.Value(_sendingAccountId!),
      receivingAccountId: drift.Value(_receivingAccountId!),
      shares: drift.Value(shares),
      costBasis: const drift.Value(1),
      value: drift.Value(value),
      notes: notes.isEmpty ? const drift.Value.absent() : drift.Value(notes),
      cycle: drift.Value(_selectedCycle),
      monthlyAverageFactor: drift.Value(monthlyAverageFactor),
    );

    try {
      if (_isEditing) {
        final id = widget.periodicTransfer!.id;
        final toSave = companion.copyWith(id: drift.Value(id));
        await _db.periodicTransfersDao.updatePeriodicTransfer(toSave);
      } else {
        await _db.periodicTransfersDao.insertPeriodicTransfer(companion);
      }
      if (mounted) Navigator.of(context).pop();
      int executedCount = await _db.periodicTransfersDao.executePending(_l10n);
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
                  assetsEditable: true,
                  assetId: _assetId,
                  onAssetChanged: (v) => setState(() => _assetId = v),
                ),
                const SizedBox(height: 16),
                _formFields.cyclesDropdown(
                  cycles: Cycles.values,
                  value: Cycles.values.indexOf(_selectedCycle),
                  onChanged: (v) =>
                      setState(() => _selectedCycle = Cycles.values[v!]),
                ),
                const SizedBox(height: 16),
                _formFields.accountDropdown(
                  accounts: _accounts,
                  value: _sendingAccountId,
                  onChanged: (v) => setState(() => _sendingAccountId = v),
                  label: _l10n.sendingAccount,
                  key: const Key('sending_account_dropdown'),
                ),
                const SizedBox(height: 16),
                _formFields.accountDropdown(
                  accounts: _accounts,
                  value: _receivingAccountId,
                  onChanged: (v) => setState(() => _receivingAccountId = v),
                  label: _l10n.receivingAccount,
                  key: const Key('receiving_account_dropdown'),
                ),
                const SizedBox(height: 16),
                _formFields.sharesField(
                  _sharesCtrl,
                  _assets.firstWhere((a) => a.id == _assetId),
                  signedShares: false,
                ),
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