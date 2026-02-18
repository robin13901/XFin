import 'dart:async';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:oktoast/oktoast.dart';
import 'package:provider/provider.dart';
import 'package:xfin/database/app_database.dart';
import 'package:xfin/l10n/app_localizations.dart';
import 'package:xfin/utils/format.dart';
import 'package:xfin/widgets/reusables.dart';
import '../database/tables.dart';
import '../providers/database_provider.dart';
import '../utils/validators.dart';
import 'form_fields.dart';

class BookingForm extends StatefulWidget {
  final Booking? booking;

  const BookingForm({super.key, this.booking});

  @override
  State<BookingForm> createState() => _BookingFormState();
}

class _BookingFormState extends State<BookingForm> {
  final _formKey = GlobalKey<FormState>();

  late AppDatabase _db;
  late AppLocalizations _l10n;
  late Validator _validator;
  late Reusables _reusables;
  late FormFields _formFields;

  // Controllers
  late TextEditingController _dateCtrl;
  late TextEditingController _sharesCtrl;
  late TextEditingController _costBasisCtrl;
  late TextEditingController _catCtrl;
  late TextEditingController _notesCtrl;

  // Form values
  late DateTime _date;
  int? _accountId;
  int? _assetId;
  bool _excludeFromAverage = false;
  bool _isGenerated = false;

  // Static DB data (loaded once)
  List<Asset> _allAssets = [];
  List<Account> _allAccounts = [];
  List<String> _distinctCategories = [];
  Map<int, Asset> _assetMap = {};

  bool _renderHeavy = false;
  bool _hideCostBasis = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _db = context
        .read<DatabaseProvider>()
        .db;
    _l10n = AppLocalizations.of(context)!;
    _validator = Validator(_l10n);
    _reusables = Reusables(context);
    _formFields = FormFields(_l10n, _validator, context);
  }

  @override
  void initState() {
    super.initState();
    final b = widget.booking;

    _date = b == null ? DateTime.now() : intToDateTime(b.date)!;
    _accountId = b?.accountId;
    _assetId = b?.assetId ?? 1;
    _excludeFromAverage = b?.excludeFromAverage ?? false;
    _isGenerated = b?.isGenerated ?? false;

    _dateCtrl = TextEditingController(text: dateFormat.format(_date));
    _sharesCtrl = TextEditingController(text: b?.shares.toString());
    _costBasisCtrl = TextEditingController(text: b?.costBasis.toString());
    _catCtrl = TextEditingController(text: b?.category);
    _notesCtrl = TextEditingController(text: b?.notes);

    _hideCostBasis = _sharesCtrl.text.trim().startsWith('-');
    _sharesCtrl.addListener(_onSharesChanged);

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
    _costBasisCtrl.dispose();
    _catCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  // ───────────────────────── UI ─────────────────────────

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: MediaQuery
          .of(context)
          .viewInsets,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _formFields.dateAndAssetRow(
                    dateController: _dateCtrl,
                    date: _date,
                    onDateChanged: (v) => setState(() => _date = v),
                    assets: _allAssets,
                    assetId: _assetId,
                    onAssetChanged: (v) => setState(() => _assetId = v)),
                if (_renderHeavy) ...[
                  const SizedBox(height: 16),
                  _sharesRow(),
                  const SizedBox(height: 16),
                  _formFields.categoryField(_catCtrl, _distinctCategories),
                  const SizedBox(height: 16),
                  _formFields.accountDropdown(
                    accounts: _allAccounts,
                    value: _accountId,
                    onChanged: (v) {
                      if (v != _accountId) setState(() => _accountId = v);
                    },
                  )
                ],
                const SizedBox(height: 16),
                _formFields.notesField(_notesCtrl),
                _excludeCheckbox(),
                if (widget.booking != null) ...[
                  _generatedCheckbox(),
                ],
                const SizedBox(height: 16),
                _formFields.footerButtons(context, _saveForm),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sharesRow() {
    return _reusables.buildSharesInputRow(
      _sharesCtrl,
      _costBasisCtrl,
      _assetMap[_assetId],
      hideCostBasis: _hideCostBasis,
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

  Widget _generatedCheckbox() {
    return CheckboxListTile(
      title: Text(_l10n.isGenerated),
      value: _isGenerated,
      onChanged: (v) => setState(() => _isGenerated = v ?? false),
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
    );
  }

  // ───────────────────────── Actions ─────────────────────────

  Future<void> _saveForm() async {
    if (!_formKey.currentState!.validate()) return;
    final dateInt = int.parse(DateFormat('yyyyMMdd').format(_date));

    // --- Parsing ---
    final shares = double.parse(_sharesCtrl.text.replaceAll(',', '.'));

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
    var companion = BookingsCompanion(
      date: drift.Value(dateInt),
      category: drift.Value(_catCtrl.text.trim()),
      notes: drift.Value(_notesCtrl.text.isEmpty ? null : _notesCtrl.text),
      excludeFromAverage: drift.Value(_excludeFromAverage),
      isGenerated: drift.Value(_isGenerated),
      shares: drift.Value(shares),
      assetId: drift.Value(_assetId!),
      accountId: drift.Value(_accountId!),
    );

    if (shares > 0) {
      double costBasis = _assetId == 1
          ? 1
          : double.parse(_costBasisCtrl.text.replaceAll(',', '.'));
      companion = companion.copyWith(
          costBasis: drift.Value(costBasis),
          value: drift.Value(shares * costBasis));
    } else {
      companion = await _db.bookingsDao.calculateCostBasisAndValue(companion);
    }

    final value = companion.value.value;

    Booking? original = widget.booking;

    // --- Merge Logic ---
    if (original == null && _notesCtrl.text.isEmpty) {
      final mergeCandidate =
      await _db.bookingsDao.findMergeableBooking(companion);

      if (mergeCandidate != null && mounted) {
        final mergedShares = mergeCandidate.shares + shares;
        final mergedValue = mergeCandidate.value + value;
        final mergedCostBasis = mergedValue / mergedShares;
        final mergedComp = mergeCandidate.toCompanion(false).copyWith(
            shares: drift.Value(mergedShares),
            value: drift.Value(mergedValue),
            costBasis: drift.Value(mergedCostBasis));

        if (mounted) {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (ctx) =>
                AlertDialog(
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
          }
        }
      }
    }

    if (original != null) {
      companion = companion.copyWith(id: drift.Value(original.id));
    }

    original != null
        ? await _db.bookingsDao.updateBooking(original, companion, _l10n)
        : await _db.bookingsDao.createBooking(companion, _l10n);

    if (mounted) Navigator.of(context).pop();
  }
}
