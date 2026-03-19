import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xfin/database/app_database.dart';
import 'package:xfin/database/tables.dart';
import 'package:xfin/l10n/app_localizations.dart';

import '../../providers/database_provider.dart';
import '../../utils/validators.dart';
import '../form_fields/form_fields.dart';

class AssetForm extends StatefulWidget {
  final Asset? asset;

  const AssetForm({super.key, this.asset});

  @override
  State<AssetForm> createState() => _AssetFormState();
}

class _AssetFormState extends State<AssetForm> {
  final _formKey = GlobalKey<FormState>();

  late AppDatabase _db;
  late AppLocalizations _l10n;
  late Validator _validator;
  late FormFields _formFields;

  late TextEditingController _nameController;
  late TextEditingController _tickerSymbolController;
  late TextEditingController _currencySymbolController;
  late AssetTypes _type;
  late List<String> _existingAssetNames;
  late List<String> _existingTickerSymbols;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _db = context.read<DatabaseProvider>().db;
    _l10n = AppLocalizations.of(context)!;
    _validator = Validator(_l10n);
    _formFields = FormFields(_l10n, _validator, context);
  }

  @override
  void initState() {
    super.initState();
    _db = context.read<DatabaseProvider>().db;

    _nameController = TextEditingController(text: widget.asset?.name);
    _tickerSymbolController =
        TextEditingController(text: widget.asset?.tickerSymbol);
    _currencySymbolController =
        TextEditingController(text: widget.asset?.currencySymbol);

    _type = widget.asset?.type ?? AssetTypes.stock;
    _existingAssetNames = [];
    _existingTickerSymbols = [];

    _db.assetsDao.watchAllAssets().first.then((assets) {
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
      await _db.assetsDao.insert(AssetsCompanion.insert(
          name: name,
          type: _type,
          tickerSymbol: tickerSymbol,
          currencySymbol: drift.Value(currencySymbol)));
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final validator = Validator(l10n);
    return BottomInsetPadding(
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
                _formFields.basicTextField(
                  key: const Key('asset_name_field'),
                  controller: _nameController,
                  label: l10n.assetName,
                  textCapitalization: TextCapitalization.words,
                  validator: (_) => validator.validateIsUnique(
                      _nameController.text, _existingAssetNames),
                ),
                const SizedBox(height: 16),
                _formFields.assetTypeDropdown(
                  value: _type,
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
                      child: _formFields.basicTextField(
                        key: const Key('ticker_symbol_field'),
                        controller: _tickerSymbolController,
                        label: l10n.tickerSymbol,
                        textCapitalization: TextCapitalization.characters,
                        validator: (_) => validator.validateIsUnique(
                            _tickerSymbolController.text,
                            _existingTickerSymbols),
                      ),
                    ),
                    if (_type == AssetTypes.fiat ||
                        _type == AssetTypes.crypto) ...[
                      const SizedBox(width: 16),
                      Expanded(
                        child: _formFields.basicTextField(
                          key: const Key('currency_symbol_field'),
                          controller: _currencySymbolController,
                          label: l10n.currencySymbol,
                          textCapitalization: TextCapitalization.characters,
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
                _formFields.footerButtons(context, _saveForm),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
