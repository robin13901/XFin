import 'dart:async';

import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xfin/database/app_database.dart';
import 'package:xfin/database/tables.dart';
import 'package:xfin/l10n/app_localizations.dart';
import 'package:xfin/providers/live_price_provider.dart';
import 'package:xfin/services/price_service.dart';

import '../../providers/database_provider.dart';
import '../../utils/validators.dart';
import '../api_identifier_search_page.dart';
import '../form_fields/form_fields.dart';

class AssetForm extends StatefulWidget {
  final Asset? asset;

  const AssetForm({super.key, this.asset});

  bool get isEditing => asset != null;

  @override
  State<AssetForm> createState() => _AssetFormState();
}

class _AssetFormState extends State<AssetForm> {
  final _formKey = GlobalKey<FormState>();

  late AppDatabase _db;
  late AppLocalizations _l10n;
  late Validator _validator;
  late FormFields _formFields;
  bool _formFieldsInitialized = false;
  PriceService? _priceService;

  late TextEditingController _nameController;
  late TextEditingController _tickerSymbolController;
  late TextEditingController _currencySymbolController;
  String? _apiIdentifier;
  late AssetTypes _type;
  late List<String> _existingAssetNames;
  late List<String> _existingTickerSymbols;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _db = context.read<DatabaseProvider>().db;
    _priceService = context.read<LivePriceProvider>().priceService;
    if (!_formFieldsInitialized) {
      _formFieldsInitialized = true;
      _l10n = AppLocalizations.of(context)!;
      _validator = Validator(_l10n);
      _formFields = FormFields(_l10n, _validator, context);
    }
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
    _apiIdentifier = widget.asset?.apiIdentifier;

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

  Future<void> _openApiSearch() async {
    if (_priceService == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Price-Service nicht verfügbar')),
        );
      }
      return;
    }

    final result = await Navigator.of(context, rootNavigator: true)
        .push<String>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => ApiIdentifierSearchPage(
          priceService: _priceService!,
          assetType: _type,
          currentValue: _apiIdentifier,
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() => _apiIdentifier = result);
    }
  }

  Future<void> _saveForm() async {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text.trim();
      final tickerSymbol = _tickerSymbolController.text.trim();
      var currencySymbol =
          _type == AssetTypes.fiat || _type == AssetTypes.crypto
              ? _currencySymbolController.text.trim()
              : null;
      if (currencySymbol == "") currencySymbol = null;

      final apiIdentifier =
          _apiIdentifier != null && _apiIdentifier!.isNotEmpty
              ? _apiIdentifier
              : null;

      if (widget.isEditing) {
        await _db.assetsDao.updateMetadata(
          widget.asset!.id,
          name: name,
          tickerSymbol: tickerSymbol,
          currencySymbol: currencySymbol,
          apiIdentifier: apiIdentifier,
          type: _type,
        );
      } else {
        await _db.assetsDao.insert(AssetsCompanion.insert(
            name: name,
            type: _type,
            tickerSymbol: tickerSymbol,
            currencySymbol: drift.Value(currencySymbol),
            apiIdentifier: drift.Value(apiIdentifier)));
      }

      // Refresh live streams so the new/updated asset is included
      if (mounted) {
        final liveProvider = context.read<LivePriceProvider>();
        if (liveProvider.isLive) {
          liveProvider.refreshAssets();
        }
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final validator = Validator(l10n);
    final isEditing = widget.isEditing;

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
                    if (value != null && !isEditing) {
                      setState(() {
                        _type = value;
                        _apiIdentifier = null;
                      });
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
                if (widget.asset?.id == 1)
                  InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'API-Identifier (Live-Preis)',
                      border: OutlineInputBorder(),
                      enabled: false,
                    ),
                    child: Text(
                      'Nicht verfügbar (Basiswährung = 1)',
                      style: TextStyle(color: Theme.of(context).disabledColor),
                    ),
                  )
                else
                GestureDetector(
                  onTap: _openApiSearch,
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'API-Identifier (Live-Preis)',
                      border: const OutlineInputBorder(),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_apiIdentifier != null)
                            IconButton(
                              icon: const Icon(Icons.clear, size: 20),
                              onPressed: () =>
                                  setState(() => _apiIdentifier = null),
                            ),
                          const Padding(
                            padding: EdgeInsets.only(right: 12),
                            child: Icon(Icons.search, size: 20),
                          ),
                        ],
                      ),
                    ),
                    child: Text(
                      _apiIdentifier ?? 'Tippen zum Suchen...',
                      style: _apiIdentifier != null
                          ? null
                          : TextStyle(color: Theme.of(context).hintColor),
                    ),
                  ),
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
