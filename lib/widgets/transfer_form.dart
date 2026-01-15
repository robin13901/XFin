import 'dart:async';

import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:oktoast/oktoast.dart';
import 'package:provider/provider.dart';
import 'package:xfin/database/app_database.dart';
import 'package:xfin/l10n/app_localizations.dart';
import 'package:xfin/widgets/reusables.dart';
import '../database/tables.dart';
import '../utils/validators.dart';

class TransferForm extends StatefulWidget {
  final Transfer? transfer;
  final List<Asset>? preloadedAssets; // NEW optional parameter

  const TransferForm({super.key, this.transfer, this.preloadedAssets});

  @override
  State<TransferForm> createState() => _TransferFormState();
}

class _TransferFormState extends State<TransferForm> {
  final _formKey = GlobalKey<FormState>();

  // Helpers
  AppDatabase get _db => Provider.of<AppDatabase>(context, listen: false);

  AppLocalizations get _l10n => AppLocalizations.of(context)!;

  Validator get _validator => Validator(_l10n);

  Reusables get _reusables => Reusables(context);

  // Form state
  late DateTime _date;
  late TextEditingController _sharesCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _notesCtrl;
  late TextEditingController _dateCtrl; // moved to state to avoid ephemeral controllers

  int? _sendingAccountId;
  int? _receivingAccountId;
  int? _assetId;

  bool _isGenerated = false;

  // Data
  List<Asset> _allAssets = [];
  Map<int, Asset> _assetMap = {};

  @override
  void initState() {
    super.initState();
    final t = widget.transfer;

    // initialize date
    if (t != null) {
      final ds = t.date.toString();
      _date = DateTime.parse(
          '${ds.substring(0, 4)}-${ds.substring(4, 6)}-${ds.substring(6, 8)}');
    } else {
      _date = DateTime.now();
    }

    // initialize controllers once
    _sharesCtrl = TextEditingController(text: t?.shares.toString());
    _priceCtrl = TextEditingController(text: t?.costBasis.toString());
    _notesCtrl = TextEditingController(text: t?.notes);
    _dateCtrl = TextEditingController(text: DateFormat('dd.MM.yyyy').format(_date));

    _sendingAccountId = t?.sendingAccountId;
    _receivingAccountId = t?.receivingAccountId;
    _assetId = t?.assetId ?? 1; // default asset id 1
    _isGenerated = t?.isGenerated ?? false;

    // Use preloaded assets if provided (fast path)
    if (widget.preloadedAssets != null) {
      _allAssets = widget.preloadedAssets!;
      _assetMap = {for (var a in _allAssets) a.id: a};
    } else {
      // fallback: async load assets as before (non-blocking UI)
      _db.assetsDao.getAllAssets().then((assets) {
        if (!mounted) return;
        setState(() {
          _allAssets = assets;
          _assetMap = {for (var a in assets) a.id: a};
        });
      });
    }
  }

  @override
  void dispose() {
    _sharesCtrl.dispose();
    _priceCtrl.dispose();
    _notesCtrl.dispose();
    _dateCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveForm() async {
    if (!_formKey.currentState!.validate()) return;
    final shares = double.parse(_sharesCtrl.text.replaceAll(',', '.'));

    // --- Validation Checks ---
    if (_sendingAccountId == _receivingAccountId) {
      showToast(_l10n.sendingAndReceivingMustDiffer);
      return;
    }

    final aoa =
    await _db.assetsOnAccountsDao.getAOA(_sendingAccountId!, _assetId!);
    double oldShares = widget.transfer == null ? 0 : widget.transfer!.shares;
    if (aoa.shares + oldShares - shares < 0) {
      showToast(
          _assetId == 1 ? _l10n.insufficientBalance : _l10n.insufficientShares);
      return;
    }

    final recAcc = await _db.accountsDao.getAccount(_receivingAccountId!);
    if (recAcc.type == AccountTypes.cash) {
      final asset = await _db.assetsDao.getAsset(_assetId!);
      if (asset.type != AssetTypes.fiat) {
        showToast(_l10n.onlyCurrenciesCanBeBookedOnCashAccount);
        return;
      }
    } else if (recAcc.type == AccountTypes.bankAccount && _assetId != 1) {
      showToast(_l10n.onlyBaseCurrencyCanBeBookedOnBankAccount);
      return;
    } else if (recAcc.type == AccountTypes.cryptoWallet) {
      final asset = await _db.assetsDao.getAsset(_assetId!);
      if (asset.type != AssetTypes.crypto) {
        showToast(_l10n.onlyCryptoCanBeBookedOnCryptoWallet);
        return;
      }
    }

    var value = 0.0;
    if (_assetId == 1) {
      value = shares;
    } else {
      final fifo = await _db.assetsOnAccountsDao.buildFiFoQueue(
          _assetId!, _sendingAccountId!,
          oldTransfer: widget.transfer);
      var sharesToTransfer = shares;
      while (sharesToTransfer > 0 && fifo.isNotEmpty) {
        var currentLot = fifo.first;
        if (currentLot['shares']! <= sharesToTransfer) {
          value += currentLot['shares']! * currentLot['costBasis']!;
          sharesToTransfer -= currentLot['shares']!;
          fifo.removeFirst();
        } else {
          value += sharesToTransfer * currentLot['costBasis']!;
          currentLot['shares'] = currentLot['shares']! - sharesToTransfer;
          sharesToTransfer = 0;
        }
      }
    }

    final dateInt = int.parse(DateFormat('yyyyMMdd').format(_date));
    var companion = TransfersCompanion(
      date: drift.Value(dateInt),
      notes: drift.Value(_notesCtrl.text.isEmpty ? null : _notesCtrl.text),
      isGenerated: drift.Value(_isGenerated),
      shares: drift.Value(shares),
      costBasis: drift.Value(value / shares),
      value: drift.Value(value),
      assetId: drift.Value(_assetId!),
      sendingAccountId: drift.Value(_sendingAccountId!),
      receivingAccountId: drift.Value(_receivingAccountId!),
    );

    if (widget.transfer != null) {
      companion = companion.copyWith(id: drift.Value(widget.transfer!.id));
    }

    if (widget.transfer != null) {
      await _db.transfersDao.updateTransfer(widget.transfer!, companion, _l10n);
    } else {
      await _db.transfersDao.createTransfer(companion, _l10n);
    }

    if (mounted) Navigator.of(context).pop();
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
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        readOnly: true,
                        controller: _dateCtrl,
                        decoration: InputDecoration(
                          labelText: _l10n.date,
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.calendar_today),
                            onPressed: _pickDate,
                          ),
                        ),
                        validator: (_) => _validator.validateDate(_date),
                      ),
                    ),
                    const SizedBox(width: 16),
                    _reusables.buildAssetsDropdown(
                      _assetId!,
                      _allAssets,
                          (val) => setState(() => _assetId = val),
                          (val) => val == null ? _l10n.pleaseSelectAnAsset : null,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _reusables.buildSharesInputRow(
                  _sharesCtrl,
                  _priceCtrl,
                  _assetMap[_assetId],
                  hideCostBasis: true,
                  signedShares: false,
                ),
                const SizedBox(height: 16),
                StreamBuilder<List<Account>>(
                  stream: _db.accountsDao.watchAllAccounts(),
                  builder: (context, snapshot) {
                    final accounts = snapshot.data ?? [];
                    return Column(
                      children: [
                        DropdownButtonFormField<int>(
                          key: const Key('sending_account_dropdown'),
                          initialValue: _sendingAccountId,
                          decoration: InputDecoration(
                            labelText: _l10n.sendingAccount,
                            border: const OutlineInputBorder(),
                          ),
                          items: accounts
                              .map((a) => DropdownMenuItem(
                            value: a.id,
                            child: Text(a.name),
                          ))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _sendingAccountId = v),
                          validator: (v) =>
                          v == null ? _l10n.pleaseSelectAnAccount : null,
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<int>(
                          key: const Key('receiving_account_dropdown'),
                          initialValue: _receivingAccountId,
                          decoration: InputDecoration(
                            labelText: _l10n.receivingAccount,
                            border: const OutlineInputBorder(),
                          ),
                          items: accounts
                              .map((a) => DropdownMenuItem(
                            value: a.id,
                            child: Text(a.name),
                          ))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _receivingAccountId = v),
                          validator: (v) =>
                          v == null ? _l10n.pleaseSelectAnAccount : null,
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _notesCtrl,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: _l10n.notes,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(_l10n.cancel),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _saveForm,
                      child: Text(_l10n.save),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _date) {
      setState(() {
        _date = picked;
        _dateCtrl.text = DateFormat('dd.MM.yyyy').format(_date);
      });
    }
  }
}