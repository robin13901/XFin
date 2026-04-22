import 'dart:async';

import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xfin/database/app_database.dart';
import 'package:xfin/database/tables.dart';
import 'package:xfin/l10n/app_localizations.dart';
import 'package:xfin/providers/live_price_provider.dart';
import 'package:xfin/services/price_provider.dart';

import '../../providers/database_provider.dart';
import '../../utils/validators.dart';
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

  late TextEditingController _nameController;
  late TextEditingController _tickerSymbolController;
  late TextEditingController _currencySymbolController;
  late TextEditingController _apiIdentifierController;
  late AssetTypes _type;
  late List<String> _existingAssetNames;
  late List<String> _existingTickerSymbols;
  List<SymbolSearchResult> _searchResults = [];
  Timer? _debounceTimer;
  bool _isSearching = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _db = context.read<DatabaseProvider>().db;
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
    _apiIdentifierController =
        TextEditingController(text: widget.asset?.apiIdentifier);

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
    _apiIdentifierController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onApiIdentifierSearch(String query) {
    _debounceTimer?.cancel();
    if (query.length < 2) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }
    setState(() => _isSearching = true);
    _debounceTimer = Timer(const Duration(milliseconds: 400), () async {
      final priceService = context.read<LivePriceProvider>().priceService;
      if (priceService == null) {
        if (mounted) setState(() => _isSearching = false);
        return;
      }
      try {
        final results = await priceService.searchSymbols(query, _type);
        if (mounted) {
          setState(() {
            _searchResults = results;
            _isSearching = false;
          });
        }
      } catch (_) {
        if (mounted) setState(() => _isSearching = false);
      }
    });
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

      final apiId = _apiIdentifierController.text.trim();
      final apiIdentifier = apiId.isEmpty ? null : apiId;

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
      if (mounted) Navigator.of(context).pop();
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
                        _searchResults = [];
                        _apiIdentifierController.clear();
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
                _buildApiIdentifierField(),
                const SizedBox(height: 16),
                _formFields.footerButtons(context, _saveForm),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildApiIdentifierField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          key: const Key('api_identifier_field'),
          controller: _apiIdentifierController,
          decoration: InputDecoration(
            labelText: 'API-Identifier (Live-Preis)',
            border: const OutlineInputBorder(),
            suffixIcon: _isSearching
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : _apiIdentifierController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _apiIdentifierController.clear();
                          setState(() => _searchResults = []);
                        },
                      )
                    : null,
            helperText: _type == AssetTypes.crypto
                ? 'Suche nach Crypto-Name (z.B. "Bitcoin")'
                : _type == AssetTypes.fiat
                    ? 'ISO-Code eingeben (z.B. "USD", "CHF")'
                    : 'Suche nach Aktie/ETF (z.B. "Apple", "MSCI")',
            helperMaxLines: 2,
          ),
          onChanged: _onApiIdentifierSearch,
        ),
        if (_searchResults.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            constraints: const BoxConstraints(maxHeight: 180),
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: _searchResults.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final result = _searchResults[index];
                return ListTile(
                  dense: true,
                  leading: Icon(
                    _type == AssetTypes.crypto
                        ? Icons.currency_bitcoin
                        : Icons.show_chart,
                    size: 20,
                  ),
                  title: Text(result.name, overflow: TextOverflow.ellipsis),
                  subtitle: Text(
                    result.symbol +
                        (result.exchange != null
                            ? ' · ${result.exchange}'
                            : '') +
                        (result.type != null ? ' · ${result.type}' : ''),
                    style: Theme.of(context).textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () {
                    _apiIdentifierController.text = result.symbol;
                    setState(() => _searchResults = []);
                  },
                );
              },
            ),
          ),
      ],
    );
  }
}
