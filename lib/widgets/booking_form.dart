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

class BookingForm extends StatefulWidget {
  final Booking? booking;

  const BookingForm({super.key, this.booking});

  @override
  State<BookingForm> createState() => _BookingFormState();
}

class _BookingFormState extends State<BookingForm> {
  final _formKey = GlobalKey<FormState>();

  // Helpers
  AppDatabase get _db => Provider.of<AppDatabase>(context, listen: false);

  AppLocalizations get _l10n => AppLocalizations.of(context)!;

  Validator get _validator => Validator(_l10n);

  Reusables get _reusables => Reusables(context);

  // Form State
  late DateTime _date;
  late TextEditingController _sharesCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _catCtrl;
  late TextEditingController _notesCtrl;

  int? _accountId;
  int? _assetId;
  bool _excludeFromAverage = false;
  bool _isGenerated = false;
  bool _hideCostBasis = false;

  // Data
  List<Asset> _allAssets = [];
  Map<int, Asset> _assetMap = {};
  List<String> _distinctCategories = [];
  StreamSubscription? _catSub;

  @override
  void initState() {
    super.initState();
    final b = widget.booking;

    // 1. Data Fetching
    _catSub = _db.bookingsDao.watchDistinctCategories().listen((c) {
      if (mounted) setState(() => _distinctCategories = c);
    });

    _db.assetsDao.getAllAssets().then((assets) {
      if (mounted) {
        setState(() {
          _allAssets = assets;
          _assetMap = {for (var a in assets) a.id: a};
        });
      }
    });

    // 2. Controller Initialization (Edit vs Create handled via null-aware)
    if (b != null) {
      final ds = b.date.toString();
      _date = DateTime.parse(
          '${ds.substring(0, 4)}-${ds.substring(4, 6)}-${ds.substring(6, 8)}');
    } else {
      _date = DateTime.now();
    }

    _sharesCtrl = TextEditingController(text: b?.shares.toString());
    _priceCtrl = TextEditingController(text: b?.costBasis.toString());
    _catCtrl = TextEditingController(text: b?.category);
    _notesCtrl = TextEditingController(text: b?.notes);

    _accountId = b?.accountId;
    _assetId = b?.assetId ?? 1; // Default to 1 (usually base currency)
    _excludeFromAverage = b?.excludeFromAverage ?? false;
    _isGenerated = b?.isGenerated ?? false;

    // 3. Listener Setup
    _hideCostBasis = _sharesCtrl.text.trim().startsWith('-');
    _sharesCtrl.addListener(_onSharesChanged);
  }

  void _onSharesChanged() {
    final shouldHide = _sharesCtrl.text.trim().startsWith('-');
    if (shouldHide != _hideCostBasis) {
      setState(() => _hideCostBasis = shouldHide);
    }
  }

  @override
  void dispose() {
    _sharesCtrl.removeListener(_onSharesChanged);
    _sharesCtrl.dispose();
    _priceCtrl.dispose();
    _catCtrl.dispose();
    _notesCtrl.dispose();
    _catSub?.cancel();
    super.dispose();
  }

  Future<void> _saveForm() async {
    if (!_formKey.currentState!.validate()) return;

    // --- Parsing ---
    final shares = double.parse(_sharesCtrl.text.replaceAll(',', '.'));
    final price = _assetId == 1
        ? 1.0
        : double.parse(_priceCtrl.text.replaceAll(',', '.'));
    final value = shares * price;

    // --- Validation Checks ---
    // 1. Balance Checks (New Bookings Only)
    if (widget.booking == null && shares < 0) {
      final aoa = await _db.assetsOnAccountsDao.getAOA(_accountId!, _assetId!);
      if (aoa.shares + shares < 0) {
        showToast(_assetId == 1
            ? _l10n.insufficientBalance
            : _l10n.insufficientShares);
        return;
      }
    }

    // 2. Account Type Compatibility
    final acc = await _db.accountsDao.getAccount(_accountId!);
    if (acc.type == AccountTypes.cash) {
      final asset = await _db.assetsDao.getAsset(_assetId!);
      if (asset.type != AssetTypes.fiat) {
        showToast(_l10n.onlyCurrenciesCanBeBookedOnCashAccount);
        return;
      }
    } else if (acc.type == AccountTypes.bankAccount && _assetId != 1) {
      showToast(_l10n.onlyBaseCurrencyCanBeBookedOnBankAccount);
      return;
    } else if (acc.type == AccountTypes.cryptoWallet) {
      final asset = await _db.assetsDao.getAsset(_assetId!);
      if (asset.type != AssetTypes.crypto) {
        showToast(_l10n.onlyCryptoCanBeBookedOnCryptoWallet);
        return;
      }
    }

    // --- Companion Construction ---
    final dateInt = int.parse(DateFormat('yyyyMMdd').format(_date));
    var companion = BookingsCompanion(
      date: drift.Value(dateInt),
      category: drift.Value(_catCtrl.text.trim()),
      notes: drift.Value(_notesCtrl.text.isEmpty ? null : _notesCtrl.text),
      excludeFromAverage: drift.Value(_excludeFromAverage),
      isGenerated: drift.Value(_isGenerated),
      shares: drift.Value(shares),
      costBasis: drift.Value(price),
      value: drift.Value(value),
      assetId: drift.Value(_assetId!),
      accountId: drift.Value(_accountId!),
    );

    Booking? original = widget.booking;
    bool checkedSafe = false;

    // --- Merge Logic ---
    if (original == null && _notesCtrl.text.isEmpty) {
      final mergeCandidate =
          await _db.bookingsDao.findMergeableBooking(companion);

      if (mergeCandidate != null && mounted) {
        final mergedComp = mergeCandidate.toCompanion(false).copyWith(
              shares: drift.Value(mergeCandidate.shares + shares),
              value:
                  drift.Value(mergeCandidate.value + value),
            );

        final isMergeSafe =
            !(await _db.accountsDao.leadsToInconsistentBalanceHistory(
          originalBooking: mergeCandidate,
          newBooking: mergedComp,
        ));

        if (isMergeSafe && mounted) {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(_l10n.mergeBookings),
              content: Text(_l10n.mergeBookingsQuestion),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text(_l10n.createNew)),
                TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text(_l10n.merge)),
              ],
            ),
          );

          if (confirm == true) {
            original = mergeCandidate;
            companion = mergedComp;
            checkedSafe = true;
          }
        }
      }
    }

    if (original != null) {
      companion = companion.copyWith(id: drift.Value(original.id));
    }

    // --- Final Save ---
    if (!checkedSafe) {
      if (await _db.accountsDao.leadsToInconsistentBalanceHistory(
          originalBooking: original, newBooking: companion)) {
        if (mounted) showToast(_l10n.actionCancelledDueToDataInconsistency);
        return;
      }
    }

    original != null
        ? await _db.bookingsDao.updateBooking(original, companion)
        : await _db.bookingsDao.createBooking(companion);

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
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        key: const Key('date_field'),
                        readOnly: true,
                        controller: TextEditingController(
                            text: DateFormat('dd.MM.yyyy').format(_date)),
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
                    _sharesCtrl, _priceCtrl, _assetMap[_assetId],
                    hideCostBasis: _hideCostBasis),
                const SizedBox(height: 16),
                Autocomplete<String>(
                  key: const Key('category_field'),
                  optionsBuilder: (v) => v.text.isEmpty
                      ? const []
                      : _distinctCategories.where((c) =>
                          c.toLowerCase().contains(v.text.toLowerCase())),
                  onSelected: (s) => setState(() => _catCtrl.text = s),
                  fieldViewBuilder: (ctx, tCtrl, node, onSub) {
                    if (widget.booking != null &&
                        _catCtrl.text.isNotEmpty &&
                        tCtrl.text != _catCtrl.text) {
                      tCtrl.text = _catCtrl.text;
                    }
                    return TextFormField(
                      controller: tCtrl,
                      focusNode: node,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                          labelText: _l10n.category,
                          border: const OutlineInputBorder()),
                      validator: _validator.validateNotInitial,
                      onChanged: (val) => _catCtrl.text = val,
                      onFieldSubmitted: (val) {
                        onSub();
                        _catCtrl.text = val;
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),
                StreamBuilder<List<Account>>(
                  stream: _db.accountsDao.watchAllAccounts(),
                  builder: (context, snapshot) {
                    return DropdownButtonFormField<int>(
                      key: const Key('account_dropdown'),
                      initialValue: _accountId,
                      decoration: InputDecoration(
                          labelText: _l10n.account,
                          border: const OutlineInputBorder()),
                      items: (snapshot.data ?? [])
                          .map((a) => DropdownMenuItem(
                              value: a.id, child: Text(a.name)))
                          .toList(),
                      onChanged: (val) => setState(() => _accountId = val),
                      validator: _validator.validateAccountSelected,
                    );
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('notes_field'),
                  controller: _notesCtrl,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                      labelText: _l10n.notes,
                      border: const OutlineInputBorder()),
                ),
                CheckboxListTile(
                  key: const Key('exclude_checkbox'),
                  title: Text(_l10n.excludeFromAverage),
                  value: _excludeFromAverage,
                  onChanged: (val) =>
                      setState(() => _excludeFromAverage = val ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(_l10n.cancel),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                        onPressed: _saveForm, child: Text(_l10n.save)),
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
    if (picked != null && picked != _date) setState(() => _date = picked);
  }
}
