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
import '../utils/date_picker_locale.dart';
import '../utils/validators.dart';
import 'dialogs.dart';
import 'form_fields.dart';

class TradeForm extends StatefulWidget {
  final Trade? trade;

  final List<Asset>? preloadedAssets;
  final List<Account>? preloadedAccounts;

  const TradeForm(
      {super.key, this.trade, this.preloadedAssets, this.preloadedAccounts});

  @override
  State<TradeForm> createState() => _TradeFormState();
}

class _TradeFormState extends State<TradeForm> {
  final _formKey = GlobalKey<FormState>();
  late AppLocalizations _l10n;
  late AppDatabase _db;
  late Validator _validator;
  late FormFields _formFields;

  // Controllers
  late TextEditingController _dateController;
  late TextEditingController _sharesController;
  late TextEditingController _costBasisController;
  late TextEditingController _feeController;
  late TextEditingController _taxController;

  // Form Values
  late DateTime _datetime;
  TradeTypes? _tradeType;
  int? _assetId, _clearingAccountId, _portfolioAccountId;

  // Data from DB
  List<Asset> _allAssets = [];
  List<Asset> _dropdownAssets = [];
  List<Account> _clearingAccounts = [];
  List<Account> _investmentAccounts = [];
  double _ownedShares = 0;

  bool get _isEditing => widget.trade != null;

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
    Trade? t = widget.trade;

    _db = context.read<DatabaseProvider>().db;

    _datetime = t == null ? DateTime.now() : intToDateTime(t.datetime)!;
    _tradeType = t?.type;

    _dateController =
        TextEditingController(text: dateTimeFormat.format(_datetime));
    _sharesController = TextEditingController(text: t?.shares.toString());
    _costBasisController = TextEditingController(text: t?.costBasis.toString());
    _feeController = TextEditingController(text: t?.fee.toString());
    _taxController = TextEditingController(text: t?.tax.toString());

    // If both assets + accounts were preloaded, use them synchronously to avoid flicker.
    if (widget.preloadedAssets != null &&
        widget.preloadedAssets!.isNotEmpty &&
        widget.preloadedAccounts != null &&
        widget.preloadedAccounts!.isNotEmpty) {
      _allAssets = widget.preloadedAssets!;
      _dropdownAssets = _allAssets.where((a) => a.id != 1).toList();

      final allAccounts = widget.preloadedAccounts!;
      _clearingAccounts = allAccounts;
      _investmentAccounts =
          allAccounts.where((a) => a.type != AccountTypes.bankAccount).toList();

      if (t != null) {
        _assetId = t.assetId;
        _clearingAccountId = t.sourceAccountId;
        _portfolioAccountId = t.targetAccountId;
      } else {
        _assetId = 1;
      }

      // If an investment account & asset is known, fetch owned shares (async).
      if (_assetId != null && _portfolioAccountId != null) {
        _fetchOwnedShares(); // will set state when done
      }
    } else {
      // fallback to original async load (non-blocking UI)
      _loadInitialData(t);
    }
  }

  Future<void> _loadInitialData(Trade? t) async {
    _allAssets = await _db.assetsDao.getAllAssets();
    final allAccounts = await _db.accountsDao.getAllAccounts();

    if (t != null) {
      _assetId = t.assetId;
      _clearingAccountId = t.sourceAccountId;
      _portfolioAccountId = t.targetAccountId;
    }

    if (mounted) {
      setState(() {
        _dropdownAssets = _allAssets.where((a) => a.id != 1).toList();
        _clearingAccounts = allAccounts;
        _investmentAccounts = allAccounts
            .where((a) => a.type != AccountTypes.bankAccount)
            .toList();
      });

      if (_assetId != null && _portfolioAccountId != null) {
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
    if (_assetId == null || _portfolioAccountId == null) return;
    try {
      final assetOnAccount =
          await _db.assetsOnAccountsDao.getAOA(_portfolioAccountId!, _assetId!);
      if (mounted) setState(() => _ownedShares = assetOnAccount.shares);
    } catch (e) {
      if (mounted) setState(() => _ownedShares = 0);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final pickedDate = await showDatePicker(
      context: context,
      locale: resolveDatePickerLocale(Localizations.localeOf(context)),
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
      assetId: drift.Value(_assetId!),
      type: drift.Value(_tradeType!),
      shares: drift.Value(double.parse(_sharesController.text)),
      costBasis: drift.Value(double.parse(_costBasisController.text)),
      fee: drift.Value(double.parse(_feeController.text)),
      tax: _tradeType == TradeTypes.sell
          ? drift.Value(double.parse(_taxController.text))
          : const drift.Value(0),
      sourceAccountId: drift.Value(_clearingAccountId!),
      targetAccountId: drift.Value(_portfolioAccountId!),
    );

    try {
      if (_isEditing) {
        trade = trade.copyWith(id: drift.Value(widget.trade!.id));
        await _db.tradesDao.updateTrade(trade, _l10n);
      } else {
        await _db.tradesDao.insertTrade(trade, _l10n);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) showErrorDialog(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    Asset asset = _allAssets.firstWhere((a) => a.id == _assetId);

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
                    labelText: _l10n.datetime,
                    border: const OutlineInputBorder(),
                    suffixIcon: const Icon(Icons.calendar_today),
                  ),
                  readOnly: true,
                  onTap: () => _selectDate(context),
                  validator: (value) => _validator.validateNotInitial(value),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<TradeTypes>(
                    initialValue: _tradeType,
                    decoration: InputDecoration(
                        labelText: _l10n.type,
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
                        value == null ? _l10n.pleaseSelectAType : null),
                const SizedBox(height: 16),
                _formFields.assetsDropdown(
                    assets: _dropdownAssets,
                    value: _isEditing ? _assetId : null,
                    onChanged: (v) {
                      setState(() => _assetId = v);
                      // fetch owned shares when portfolio account is selected already
                      _fetchOwnedShares();
                    }),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _sharesController,
                        decoration: InputDecoration(
                            suffixText:
                                asset.currencySymbol ?? asset.tickerSymbol,
                            labelText: _l10n.shares,
                            border: const OutlineInputBorder()),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        validator: (value) =>
                            _validator.validateSufficientSharesToSell(
                                value, _ownedShares, _tradeType),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _feeController,
                        decoration: InputDecoration(
                          labelText: _l10n.fee,
                          border: const OutlineInputBorder(),
                          suffixText: BaseCurrencyProvider.symbol,
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true, signed: true),
                        validator: (value) =>
                            _validator.validateDecimalGreaterEqualZero(value),
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
                          labelText: _l10n.costBasis,
                          border: const OutlineInputBorder(),
                          suffixText: BaseCurrencyProvider.symbol,
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        validator: (value) =>
                            _validator.validateDecimalGreaterZero(value),
                      ),
                    ),
                    if (_tradeType == TradeTypes.sell) ...[
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _taxController,
                          decoration: InputDecoration(
                            labelText: _l10n.tax,
                            border: const OutlineInputBorder(),
                            suffixText: BaseCurrencyProvider.symbol,
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          validator: (value) => _validator
                              .validateMaxTwoDecimalsGreaterEqualZero(value),
                        ),
                      ),
                    ]
                  ],
                ),
                const SizedBox(height: 16),
                _formFields.accountDropdown(
                    key: const Key('clearing_dropdown'),
                    label: _l10n.clearingAccount,
                    accounts: _clearingAccounts,
                    value: _clearingAccountId,
                    customValidator: validateClearingAccount,
                    onChanged: _isEditing
                        ? null
                        : (v) => setState(() => _clearingAccountId = v)),
                const SizedBox(height: 16),
                _formFields.accountDropdown(
                    key: const Key('portfolio_dropdown'),
                    label: _l10n.investmentAccount,
                    accounts: _investmentAccounts,
                    value: _portfolioAccountId,
                    onChanged: _isEditing
                        ? null
                        : (v) {
                            setState(() => _portfolioAccountId = v);
                            _fetchOwnedShares();
                          }),
                const SizedBox(height: 16),
                _formFields.footerButtons(context, _saveForm),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? validateClearingAccount(Account? account) {
    String? error = _validator.validateNotInitial(account?.name);
    if (_tradeType == TradeTypes.buy) {
      try {
        double shares = double.parse(_sharesController.text);
        double costBasis = double.parse(_costBasisController.text);
        double fee = double.parse(_feeController.text);
        double oldClearingAccountValueDelta =
            _isEditing ? widget.trade!.sourceAccountValueDelta : 0;
        double clearingAccountValueDelta = shares * costBasis + fee;
        double accountBalance = account!.balance - oldClearingAccountValueDelta;

        if (accountBalance < clearingAccountValueDelta) {
          error = _l10n.insufficientBalance;
        }
      } catch (e) {
        return error;
      }
    }
    return error;
  }
}
