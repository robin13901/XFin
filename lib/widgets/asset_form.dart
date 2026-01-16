import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xfin/database/app_database.dart';
import 'package:xfin/database/tables.dart';
import 'package:xfin/l10n/app_localizations.dart';

import '../providers/database_provider.dart';
import '../utils/validators.dart';

class AssetForm extends StatefulWidget {
  final Asset? asset;

  const AssetForm({super.key, this.asset});

  @override
  State<AssetForm> createState() => _AssetFormState();
}

class _AssetFormState extends State<AssetForm> {
  final _formKey = GlobalKey<FormState>();
  late final AppDatabase db;
  late TextEditingController _nameController;
  late TextEditingController _tickerSymbolController;
  late TextEditingController _currencySymbolController;
  late AssetTypes _type;
  late List<String> _existingAssetNames;
  late List<String> _existingTickerSymbols;

  @override
  void initState() {
    super.initState();
    db = context.read<DatabaseProvider>().db;

    _nameController = TextEditingController(text: widget.asset?.name);
    _tickerSymbolController =
        TextEditingController(text: widget.asset?.tickerSymbol);
    _currencySymbolController =
        TextEditingController(text: widget.asset?.currencySymbol);

    _type = widget.asset?.type ?? AssetTypes.stock;
    _existingAssetNames = [];
    _existingTickerSymbols = [];

    db.assetsDao.watchAllAssets().first.then((assets) {
      if (!mounted) return;
      setState(() {
        _existingAssetNames = assets
            .where((a) => a.id != widget.asset?.id)
            .map((a) => a.name)
            .toList();
        _existingTickerSymbols = assets
            .where((a) => a.id != widget.asset?.id)
            .map((a) => a.tickerSymbol)
            .toList();
      });
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _tickerSymbolController.dispose();
    _currencySymbolController.dispose();
    super.dispose();
  }

  Future<void> _saveForm() async {
    if (_formKey.currentState!.validate()) {
      // Get input values from form
      final name = _nameController.text.trim();
      final tickerSymbol = _tickerSymbolController.text.trim();
      var currencySymbol =
          _type == AssetTypes.fiat || _type == AssetTypes.crypto
              ? _currencySymbolController.text.trim()
              : null;
      if (currencySymbol == "") currencySymbol = null;

      // Insert and pop
      await db.assetsDao.insert(AssetsCompanion.insert(
          name: name,
          type: _type,
          tickerSymbol: tickerSymbol,
          currencySymbol: drift.Value(currencySymbol)));
      if (mounted) Navigator.of(context).pop();
    }
  }

  String _getAssetTypeName(AppLocalizations l10n, AssetTypes type) {
    switch (type) {
      case AssetTypes.stock:
        return l10n.stock;
      case AssetTypes.crypto:
        return l10n.crypto;
      case AssetTypes.etf:
        return l10n.etf;
      case AssetTypes.fund:
        return l10n.fund;
      case AssetTypes.fiat:
        return l10n.fiat;
      case AssetTypes.derivative:
        return l10n.derivative;
    }
  }

  @override
  Widget build(BuildContext context) {
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
                const SizedBox(height: 6),
                TextFormField(
                  key: const Key('asset_name_field'),
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: l10n.assetName,
                    border: const OutlineInputBorder(),
                  ),
                  validator: (_) => validator.validateIsUnique(
                      _nameController.text, _existingAssetNames),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<AssetTypes>(
                  key: const Key('asset_type_dropdown'),
                  initialValue: _type,
                  decoration: InputDecoration(
                    labelText: l10n.type,
                    border: const OutlineInputBorder(),
                  ),
                  items: AssetTypes.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(_getAssetTypeName(l10n, type)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _type = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        key: const Key('ticker_symbol_field'),
                        controller: _tickerSymbolController,
                        textCapitalization: TextCapitalization.characters,
                        decoration: InputDecoration(
                          labelText: l10n.tickerSymbol,
                          border: const OutlineInputBorder(),
                        ),
                        validator: (_) => validator.validateIsUnique(
                            _tickerSymbolController.text,
                            _existingTickerSymbols),
                      ),
                    ),
                    if (_type == AssetTypes.fiat ||
                        _type == AssetTypes.crypto) ...[
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          key: const Key('currency_symbol_field'),
                          controller: _currencySymbolController,
                          textCapitalization: TextCapitalization.characters,
                          decoration: InputDecoration(
                            labelText: l10n.currencySymbol,
                            border: const OutlineInputBorder(),
                          ),
                          validator: (_) => _type == AssetTypes.fiat
                              ? validator.validateNotInitial(
                                  _currencySymbolController.text)
                              : null,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(l10n.cancel),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _saveForm,
                      child: Text(l10n.save),
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
}
