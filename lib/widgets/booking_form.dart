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

  const BookingForm({
    super.key,
    this.booking,
  });

  @override
  State<BookingForm> createState() => _BookingFormState();
}

class _BookingFormState extends State<BookingForm> {
  final _formKey = GlobalKey<FormState>();

  late AppDatabase _db;
  late AppLocalizations _l10n;
  late Validator _validator;
  late Reusables _reusables;

  // Controllers
  late DateTime _date;
  late TextEditingController _dateCtrl;
  late TextEditingController _sharesCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _catCtrl;
  late TextEditingController _notesCtrl;

  int? _accountId;
  int? _assetId;

  bool _excludeFromAverage = false;
  bool _isGenerated = false;
  bool _hideCostBasis = false;

  // Static DB data (loaded once)
  List<Asset> _allAssets = [];
  List<Account> _allAccounts = [];
  List<String> _distinctCategories = [];
  Map<int, Asset> _assetMap = {};

  /// 🔥 Controls progressive rendering
  bool _renderHeavy = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _db = Provider.of<AppDatabase>(context, listen: false);
    _l10n = AppLocalizations.of(context)!;
    _validator = Validator(_l10n);
    _reusables = Reusables(context);
  }

  @override
  void initState() {
    super.initState();
    final b = widget.booking;

    // --- Date ---
    if (b != null) {
      final ds = b.date.toString();
      _date = DateTime.parse(
        '${ds.substring(0, 4)}-${ds.substring(4, 6)}-${ds.substring(6, 8)}',
      );
    } else {
      _date = DateTime.now();
    }

    // --- Controllers (ONCE) ---
    _dateCtrl =
        TextEditingController(text: DateFormat('dd.MM.yyyy').format(_date));
    _sharesCtrl = TextEditingController(text: b?.shares.toString());
    _priceCtrl = TextEditingController(text: b?.costBasis.toString());
    _catCtrl = TextEditingController(text: b?.category);
    _notesCtrl = TextEditingController(text: b?.notes);

    _accountId = b?.accountId;
    _assetId = b?.assetId ?? 1;
    _excludeFromAverage = b?.excludeFromAverage ?? false;
    _isGenerated = b?.isGenerated ?? false;

    _hideCostBasis = _sharesCtrl.text.trim().startsWith('-');
    _sharesCtrl.addListener(_onSharesChanged);

    // --- Measure first paint ---
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadStaticData().then((_) {
        if (mounted) setState(() => _renderHeavy = true);
      });
    });
  }

  Future<void> _loadStaticData() async {
    final results = await Future.wait([
      _db.assetsDao.getAllAssets(),
      _db.accountsDao.getAllAccounts(),
      _db.bookingsDao.getDistinctCategories(),
    ]);

    _allAssets = results[0] as List<Asset>;
    _allAccounts = results[1] as List<Account>;
    _distinctCategories = results[2] as List<String>;
    _assetMap = {for (final a in _allAssets) a.id: a};
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
    _dateCtrl.dispose();
    _sharesCtrl.dispose();
    _priceCtrl.dispose();
    _catCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  // ───────────────────────── UI ─────────────────────────

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: MediaQuery.of(context).viewInsets,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dateAndAssetRow(),

                if (_renderHeavy) ...[
                  const SizedBox(height: 16),
                  _sharesRow(),
                  const SizedBox(height: 16),
                  _categoryField(),
                  const SizedBox(height: 16),
                  _accountDropdown(),
                ],

                const SizedBox(height: 16),
                _notesField(),
                _excludeCheckbox(),
                const SizedBox(height: 16),
                _footerButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _dateAndAssetRow() {
    return Row(
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
        if (_renderHeavy)
          _reusables.buildAssetsDropdown(
            _assetId!,
            _allAssets,
                (v) => v != _assetId ? setState(() => _assetId = v) : null,
                (v) => v == null ? _l10n.pleaseSelectAnAsset : null,
          )
        else
          const SizedBox(width: 140),
      ],
    );
  }

  Widget _sharesRow() {
    return _reusables.buildSharesInputRow(
      _sharesCtrl,
      _priceCtrl,
      _assetMap[_assetId],
      hideCostBasis: _hideCostBasis,
    );
  }

  Widget _categoryField() {
    return Autocomplete<String>(
      optionsBuilder: (v) => v.text.isEmpty
          ? const []
          : _distinctCategories.where(
            (c) => c.toLowerCase().contains(v.text.toLowerCase()),
      ),
      key: const Key('category_field'),
      onSelected: (s) => _catCtrl.text = s,
      fieldViewBuilder: (_, tCtrl, node, onSubmit) {
        if (tCtrl.text != _catCtrl.text) {
          tCtrl.text = _catCtrl.text;
        }
        return TextFormField(
          controller: tCtrl,
          focusNode: node,
          decoration: InputDecoration(
            labelText: _l10n.category,
            border: const OutlineInputBorder(),
          ),
          validator: _validator.validateNotInitial,
          onChanged: (v) => _catCtrl.text = v,
          onFieldSubmitted: (v) {
            onSubmit();
            _catCtrl.text = v;
          },
        );
      },
    );
  }

  Widget _accountDropdown() {
    return DropdownButtonFormField<int>(
      initialValue: _accountId,
      decoration: InputDecoration(
        labelText: _l10n.account,
        border: const OutlineInputBorder(),
      ),
      items: _allAccounts
          .map(
            (a) => DropdownMenuItem(
          value: a.id,
          child: Text(a.name),
        ),
      )
          .toList(),
      onChanged: (v) =>
      v != _accountId ? setState(() => _accountId = v) : null,
      validator: _validator.validateAccountSelected,
    );
  }

  Widget _notesField() {
    return TextFormField(
      controller: _notesCtrl,
      decoration: InputDecoration(
        labelText: _l10n.notes,
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _excludeCheckbox() {
    return CheckboxListTile(
      title: Text(_l10n.excludeFromAverage),
      value: _excludeFromAverage,
      onChanged: (v) => setState(() => _excludeFromAverage = v ?? false),
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _footerButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(_l10n.cancel),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: _saveForm,
          child: Text(_l10n.save),
        ),
      ],
    );
  }

  // ───────────────────────── Actions ─────────────────────────

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
        _dateCtrl.text = DateFormat('dd.MM.yyyy').format(picked);
      });
    }
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
}