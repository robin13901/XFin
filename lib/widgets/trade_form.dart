import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:oktoast/oktoast.dart';
import 'package:provider/provider.dart';
import 'package:xfin/database/app_database.dart';
import 'package:xfin/database/tables.dart';
import 'package:xfin/l10n/app_localizations.dart';

import '../providers/base_currency_provider.dart';
import '../validators.dart';

class TradeForm extends StatefulWidget {
  final Trade? trade;

  const TradeForm({super.key, this.trade});

  @override
  State<TradeForm> createState() => _TradeFormState();
}

class _TradeFormState extends State<TradeForm> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late TextEditingController _dateController;
  late TextEditingController _sharesController;
  late TextEditingController _pricePerShareController;
  late TextEditingController _tradingFeeController;
  late TextEditingController _taxController;

  // Form Values
  DateTime? _selectedDate;
  Asset? _selectedAsset;
  TradeTypes? _tradeType;
  Account? _selectedClearingAccount;
  Account? _selectedPortfolioAccount;

  // Data from DB
  List<Asset> _assets = [];
  List<Account> _cashAccounts = [];
  List<Account> _portfolioAccounts = [];
  double _ownedShares = 0;

  bool get _isEditing => widget.trade != null;

  @override
  void initState() {
    super.initState();
    _dateController = TextEditingController();
    _sharesController = TextEditingController();
    _pricePerShareController = TextEditingController();
    _tradingFeeController = TextEditingController();
    _taxController = TextEditingController();

    if (_isEditing) {
      // Editing logic to be implemented if needed
    }

    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final currencyProvider =
        Provider.of<BaseCurrencyProvider>(context, listen: false);
    final db = Provider.of<AppDatabase>(context, listen: false);
    final allAssets = await db.assetsDao.watchAllAssets().first;
    final allAccounts = await db.accountsDao.watchAllAccounts().first;

    if (mounted) {
      setState(() {
        _assets = allAssets
            .where((a) => a.tickerSymbol != currencyProvider.tickerSymbol)
            .toList();
        _cashAccounts =
            allAccounts.where((a) => a.type == AccountTypes.cash).toList();
        _portfolioAccounts =
            allAccounts.where((a) => a.type == AccountTypes.portfolio).toList();
      });
    }
  }

  @override
  void dispose() {
    _dateController.dispose();
    _sharesController.dispose();
    _pricePerShareController.dispose();
    _tradingFeeController.dispose();
    _taxController.dispose();
    super.dispose();
  }

  Future<void> _fetchOwnedShares() async {
    if (_selectedAsset == null || _selectedPortfolioAccount == null) return;
    final db = Provider.of<AppDatabase>(context, listen: false);
    try {
      final assetOnAccount = await db.assetsOnAccountsDao
          .getAssetOnAccount(_selectedPortfolioAccount!.id, _selectedAsset!.id);
      if (mounted) setState(() => _ownedShares = assetOnAccount.sharesOwned);
    } catch (e) {
      // Asset not in account, so 0 shares owned.
      if (mounted) setState(() => _ownedShares = 0);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null) {
      if (!context.mounted) return;
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDate ?? DateTime.now()),
      );
      if (pickedTime != null) {
        final picked = DateTime(pickedDate.year, pickedDate.month,
            pickedDate.day, pickedTime.hour, pickedTime.minute);
        if (picked != _selectedDate) {
          setState(() {
            _selectedDate = picked;
            _dateController.text =
                "${DateFormat('dd.MM.yyyy, HH:mm').format(picked)} Uhr";
          });
        }
      }
    }
  }

  Future<void> _saveForm() async {
    if (!_formKey.currentState!.validate()) return;

    final l10n = AppLocalizations.of(context)!;
    final db = Provider.of<AppDatabase>(context, listen: false);

    final trade = TradesCompanion(
        datetime: drift.Value(
            int.parse(DateFormat('yyyyMMddHHmmss').format(_selectedDate!))),
        assetId: drift.Value(_selectedAsset!.id),
        type: drift.Value(_tradeType!),
        shares: drift.Value(double.parse(_sharesController.text)),
        pricePerShare: drift.Value(double.parse(_pricePerShareController.text)),
        tradingFee: drift.Value(double.parse(_tradingFeeController.text)),
        tax: _tradeType == TradeTypes.sell
            ? drift.Value(double.parse(_taxController.text))
            : const drift.Value(0),
        clearingAccountId: drift.Value(_selectedClearingAccount!.id),
        portfolioAccountId: drift.Value(_selectedPortfolioAccount!.id));

    try {
      if (await db.accountsDao.leadsToInconsistentBalanceHistory(
        newTrade: trade,
      )) {
        showToast(l10n.actionCancelledDueToDataInconsistency);
        return;
      }
      await db.tradesDao.processTrade(trade);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error processing trade: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyProvider = Provider.of<BaseCurrencyProvider>(context);
    final l10n = AppLocalizations.of(context)!;
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
                        border: const OutlineInputBorder()),
                    items: TradeTypes.values
                        .map((type) => DropdownMenuItem(
                            value: type, child: Text(type.name)))
                        .toList(),
                    onChanged: (value) => setState(() => _tradeType = value!),
                    validator: (value) =>
                        value == null ? l10n.pleaseSelectAType : null),
                const SizedBox(height: 16),
                DropdownButtonFormField<Asset>(
                  initialValue: _selectedAsset,
                  decoration: InputDecoration(
                      labelText: l10n.asset,
                      border: const OutlineInputBorder()),
                  items: _assets
                      .map((asset) => DropdownMenuItem(
                          value: asset, child: Text(asset.name)))
                      .toList(),
                  onChanged: (value) {
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
                        controller: _tradingFeeController,
                        decoration: InputDecoration(
                          labelText: l10n.tradingFee,
                          border: const OutlineInputBorder(),
                          suffixText: currencyProvider.symbol,
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true, signed: true),
                        validator: (value) => validator
                            .validateMaxTwoDecimalsGreaterEqualZero(value),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _pricePerShareController,
                        decoration: InputDecoration(
                          labelText: l10n.pricePerShare,
                          border: const OutlineInputBorder(),
                          suffixText: currencyProvider.symbol,
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
                            suffixText: currencyProvider.symbol,
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
                        border: const OutlineInputBorder()),
                    items: _cashAccounts
                        .map((account) => DropdownMenuItem(
                            value: account, child: Text(account.name)))
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _selectedClearingAccount = value),
                    validator: (value) {
                      String? error = validator.validateNotInitial(value?.name);
                      if (_tradeType == TradeTypes.buy) {
                        try {
                          double shares = double.parse(_sharesController.text);
                          double pricePerShare =
                          double.parse(_pricePerShareController.text);
                          double tradingFee =
                          double.parse(_tradingFeeController.text);
                          double clearingAccountValueDelta =
                              shares * pricePerShare + tradingFee;
                          if (value!.balance < clearingAccountValueDelta) {
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
                  initialValue: _selectedPortfolioAccount,
                  decoration: InputDecoration(
                      labelText: l10n.portfolioAccount,
                      border: const OutlineInputBorder()),
                  items: _portfolioAccounts
                      .map((account) => DropdownMenuItem(
                          value: account, child: Text(account.name)))
                      .toList(),
                  onChanged: (value) {
                    setState(() => _selectedPortfolioAccount = value);
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
