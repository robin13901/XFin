import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:xfin/database/app_database.dart';
import 'package:xfin/database/tables.dart';
import 'package:xfin/l10n/app_localizations.dart';

import '../providers/base_currency_provider.dart';
import '../providers/database_provider.dart';
import '../utils/format.dart';
import '../utils/validators.dart';
import 'dialogs.dart';

class TradeForm extends StatefulWidget {
  final Trade? trade;

  // New optional preloaded data (fast-path)
  final List<Asset>? preloadedAssets;
  final List<Account>? preloadedAccounts;


  const TradeForm(
      {super.key, this.trade, this.preloadedAssets, this.preloadedAccounts});

  @override
  State<TradeForm> createState() => _TradeFormState();
}

class _TradeFormState extends State<TradeForm> {
  final _formKey = GlobalKey<FormState>();
  late AppLocalizations l10n;
  late final AppDatabase db;

  // Controllers
  late TextEditingController _dateController;
  late TextEditingController _sharesController;
  late TextEditingController _costBasisController;
  late TextEditingController _feeController;
  late TextEditingController _taxController;

  // Form Values
  late DateTime _datetime;
  Asset? _selectedAsset;
  TradeTypes? _tradeType;
  Account? _selectedClearingAccount;
  Account? _selectedInvestmentAccount;

  // Data from DB
  List<Asset> _assets = [];
  List<Account> _clearingAccounts = [];
  List<Account> _investmentAccounts = [];
  double _ownedShares = 0;

  bool get _isEditing => widget.trade != null;

  @override
  void initState() {
    super.initState();
    Trade? t = widget.trade;
    db = context.read<DatabaseProvider>().db;

    _datetime = t == null ? DateTime.now() : intToDateTime(t.datetime)!;
    _tradeType = t?.type;

    _dateController =
        TextEditingController(text: dateTimeFormat.format(_datetime));
    _sharesController = TextEditingController(text: t?.shares.toString());
    _costBasisController = TextEditingController(text: t?.costBasis.toString());
    _feeController = TextEditingController(text: t?.fee.toString());
    _taxController = TextEditingController(text: t?.tax.toString());

    // If both assets + accounts were preloaded, use them synchronously to avoid flicker.
    if (widget.preloadedAssets != null && widget.preloadedAccounts != null) {
      final currencyProvider =
          Provider.of<BaseCurrencyProvider>(context, listen: false);

      final allAssets = widget.preloadedAssets!;
      final allAccounts = widget.preloadedAccounts!;

      // Filter assets same as original logic
      _assets = allAssets
          .where((a) => a.tickerSymbol != currencyProvider.tickerSymbol)
          .toList();

      _clearingAccounts = allAccounts;
      _investmentAccounts =
          allAccounts.where((a) => a.type != AccountTypes.bankAccount).toList();

      if (t != null) {
        _selectedAsset = allAssets.firstWhere((a) => a.id == t.assetId);
        _selectedClearingAccount =
            allAccounts.firstWhere((a) => a.id == t.sourceAccountId);
        _selectedInvestmentAccount =
            allAccounts.firstWhere((a) => a.id == t.targetAccountId);
      } else {
        // keep nulls; user will select
      }

      // If an investment account & asset is known, fetch owned shares (async).
      if (_selectedAsset != null && _selectedInvestmentAccount != null) {
        _fetchOwnedShares(); // will set state when done
      }
    } else {
      // fallback to original async load (non-blocking UI)
      _loadInitialData(t);
    }
  }

  Future<void> _loadInitialData(Trade? t) async {
    final currencyProvider =
        Provider.of<BaseCurrencyProvider>(context, listen: false);
    final allAssets = await db.assetsDao.getAllAssets();
    final allAccounts = await db.accountsDao.getAllAccounts();

    if (t != null) {
      _selectedAsset = allAssets.firstWhere((a) => a.id == t.assetId);
      _selectedClearingAccount =
          allAccounts.firstWhere((a) => a.id == t.sourceAccountId);
      _selectedInvestmentAccount =
          allAccounts.firstWhere((a) => a.id == t.targetAccountId);
    }

    if (mounted) {
      setState(() {
        _assets = allAssets
            .where((a) => a.tickerSymbol != currencyProvider.tickerSymbol)
            .toList();
        _clearingAccounts = allAccounts;
        _investmentAccounts = allAccounts
            .where((a) => a.type != AccountTypes.bankAccount)
            .toList();
      });

      if (_selectedAsset != null && _selectedInvestmentAccount != null) {
        await _fetchOwnedShares();
      }
    }
  }

  @override
  void dispose() {
    _dateController.dispose();
    _sharesController.dispose();
    _costBasisController.dispose();
    _feeController.dispose();
    _taxController.dispose();
    super.dispose();
  }

  Future<void> _fetchOwnedShares() async {
    if (_selectedAsset == null || _selectedInvestmentAccount == null) return;
    try {
      final assetOnAccount = await db.assetsOnAccountsDao
          .getAOA(_selectedInvestmentAccount!.id, _selectedAsset!.id);
      if (mounted) setState(() => _ownedShares = assetOnAccount.shares);
    } catch (e) {
      if (mounted) setState(() => _ownedShares = 0);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _datetime,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null) {
      if (!context.mounted) return;
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_datetime),
      );
      if (pickedTime != null) {
        final picked = DateTime(pickedDate.year, pickedDate.month,
            pickedDate.day, pickedTime.hour, pickedTime.minute);
        if (picked != _datetime) {
          setState(() {
            _datetime = picked;
            _dateController.text =
                "${DateFormat('dd.MM.yyyy, HH:mm').format(picked)} Uhr";
          });
        }
      }
    }
  }

  Future<void> _saveForm() async {
    if (!_formKey.currentState!.validate()) return;

    var trade = TradesCompanion(
      datetime: drift.Value(
          int.parse(DateFormat('yyyyMMddHHmmss').format(_datetime))),
      assetId: drift.Value(_selectedAsset!.id),
      type: drift.Value(_tradeType!),
      shares: drift.Value(double.parse(_sharesController.text)),
      costBasis: drift.Value(double.parse(_costBasisController.text)),
      fee: drift.Value(double.parse(_feeController.text)),
      tax: _tradeType == TradeTypes.sell
          ? drift.Value(double.parse(_taxController.text))
          : const drift.Value(0),
      sourceAccountId: drift.Value(_selectedClearingAccount!.id),
      targetAccountId: drift.Value(_selectedInvestmentAccount!.id),
    );

    try {
      if (_isEditing) {
        trade = trade.copyWith(id: drift.Value(widget.trade!.id));
        await db.tradesDao.updateTrade(trade, l10n);
      } else {
        await db.tradesDao.insertTrade(trade, l10n);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) showErrorDialog(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    Provider.of<BaseCurrencyProvider>(context);
    l10n = AppLocalizations.of(context)!;
    final validator = Validator(l10n);

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
                TextFormField(
                  controller: _dateController,
                  decoration: InputDecoration(
                    labelText: l10n.datetime,
                    border: const OutlineInputBorder(),
                    suffixIcon: const Icon(Icons.calendar_today),
                  ),
                  readOnly: true,
                  onTap: () => _selectDate(context),
                  validator: (value) => validator.validateNotInitial(value),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<TradeTypes>(
                    initialValue: _tradeType,
                    decoration: InputDecoration(
                        labelText: l10n.type,
                        enabled: !_isEditing,
                        border: const OutlineInputBorder()),
                    items: TradeTypes.values
                        .map((type) => DropdownMenuItem(
                            value: type, child: Text(type.name)))
                        .toList(),
                    onChanged: _isEditing
                        ? null
                        : (value) => setState(() => _tradeType = value),
                    validator: (value) =>
                        value == null ? l10n.pleaseSelectAType : null),
                const SizedBox(height: 16),
                DropdownButtonFormField<Asset>(
                  initialValue: _selectedAsset,
                  decoration: InputDecoration(
                      labelText: l10n.asset,
                      enabled: !_isEditing,
                      border: const OutlineInputBorder()),
                  items: _assets
                      .map((asset) => DropdownMenuItem(
                          value: asset, child: Text(asset.name)))
                      .toList(),
                  onChanged: _isEditing
                      ? null
                      : (value) {
                          setState(() => _selectedAsset = value);
                          _fetchOwnedShares();
                        },
                  validator: (value) =>
                      value == null ? l10n.pleaseSelectAnAsset : null,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _sharesController,
                        decoration: InputDecoration(
                            suffixText: _selectedAsset?.currencySymbol ??
                                _selectedAsset?.tickerSymbol,
                            labelText: l10n.shares,
                            border: const OutlineInputBorder()),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        validator: (value) =>
                            validator.validateSufficientSharesToSell(
                                value, _ownedShares, _tradeType),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _feeController,
                        decoration: InputDecoration(
                          labelText: l10n.fee,
                          border: const OutlineInputBorder(),
                          suffixText: BaseCurrencyProvider.symbol,
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true, signed: true),
                        validator: (value) =>
                            validator.validateDecimalGreaterEqualZero(value),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _costBasisController,
                        decoration: InputDecoration(
                          labelText: l10n.costBasis,
                          border: const OutlineInputBorder(),
                          suffixText: BaseCurrencyProvider.symbol,
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        validator: (value) =>
                            validator.validateDecimalGreaterZero(value),
                      ),
                    ),
                    if (_tradeType == TradeTypes.sell) ...[
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _taxController,
                          decoration: InputDecoration(
                            labelText: l10n.tax,
                            border: const OutlineInputBorder(),
                            suffixText: BaseCurrencyProvider.symbol,
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          validator: (value) => validator
                              .validateMaxTwoDecimalsGreaterEqualZero(value),
                        ),
                      ),
                    ]
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<Account>(
                    initialValue: _selectedClearingAccount,
                    decoration: InputDecoration(
                        labelText: l10n.clearingAccount,
                        enabled: !_isEditing,
                        border: const OutlineInputBorder()),
                    items: _clearingAccounts
                        .map((account) => DropdownMenuItem(
                            value: account, child: Text(account.name)))
                        .toList(),
                    onChanged: _isEditing
                        ? null
                        : (value) =>
                            setState(() => _selectedClearingAccount = value),
                    validator: (value) {
                      String? error = validator.validateNotInitial(value?.name);
                      if (_tradeType == TradeTypes.buy) {
                        try {
                          double shares = double.parse(_sharesController.text);
                          double costBasis =
                              double.parse(_costBasisController.text);
                          double fee = double.parse(_feeController.text);
                          double oldClearingAccountValueDelta = _isEditing
                              ? widget.trade!.sourceAccountValueDelta
                              : 0;
                          double clearingAccountValueDelta =
                              shares * costBasis + fee;
                          double accountBalance =
                              value!.balance - oldClearingAccountValueDelta;

                          if (accountBalance < clearingAccountValueDelta) {
                            error = l10n.insufficientBalance;
                          }
                        } catch (e) {
                          return error;
                        }
                      }
                      return error;
                    }),
                const SizedBox(height: 16),
                DropdownButtonFormField<Account>(
                  initialValue: _selectedInvestmentAccount,
                  decoration: InputDecoration(
                      labelText: l10n.investmentAccount,
                      enabled: !_isEditing,
                      border: const OutlineInputBorder()),
                  items: _investmentAccounts
                      .map((account) => DropdownMenuItem(
                          value: account, child: Text(account.name)))
                      .toList(),
                  onChanged: _isEditing
                      ? null
                      : (value) {
                          setState(() => _selectedInvestmentAccount = value);
                          _fetchOwnedShares();
                        },
                  validator: (value) =>
                      value == null ? l10n.pleaseSelectAnAccount : null,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(l10n.cancel)),
                    const SizedBox(width: 8),
                    ElevatedButton(
                        onPressed: _saveForm,
                        child: Text(_isEditing ? l10n.update : l10n.save)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
