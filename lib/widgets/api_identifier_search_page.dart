import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/price_provider.dart';
import '../services/price_service.dart';
import '../database/tables.dart';

class ApiIdentifierSearchPage extends StatefulWidget {
  final PriceService priceService;
  final AssetTypes assetType;
  final String? currentValue;

  const ApiIdentifierSearchPage({
    super.key,
    required this.priceService,
    required this.assetType,
    this.currentValue,
  });

  @override
  State<ApiIdentifierSearchPage> createState() =>
      _ApiIdentifierSearchPageState();
}

class _ApiIdentifierSearchPageState extends State<ApiIdentifierSearchPage> {
  final _searchController = TextEditingController();
  List<SymbolSearchResult> _results = [];
  bool _isSearching = false;
  String? _error;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    if (widget.currentValue != null && widget.currentValue!.isNotEmpty) {
      _searchController.text = widget.currentValue!;
      _doSearch(widget.currentValue!);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.length < 2) {
      setState(() {
        _results = [];
        _isSearching = false;
        _error = null;
      });
      return;
    }
    setState(() => _isSearching = true);
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _doSearch(query);
    });
  }

  Future<void> _doSearch(String query) async {
    setState(() {
      _isSearching = true;
      _error = null;
    });
    try {
      final locale =
          Localizations.localeOf(context).languageCode;
      final results = await widget.priceService
          .searchSymbols(query, widget.assetType, locale: locale);
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        setState(() {
          _results = results;
          _isSearching = false;
          if (results.isEmpty) {
            _error = l10n.noResultsFor(query);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        setState(() {
          _isSearching = false;
          _error = l10n.searchError(e.toString());
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final typeLabel = switch (widget.assetType) {
      AssetTypes.crypto => l10n.assetTypeCrypto,
      AssetTypes.stock => l10n.assetTypeStock,
      AssetTypes.etf => l10n.assetTypeEtf,
      AssetTypes.fund => l10n.assetTypeFund,
      AssetTypes.fiat => l10n.assetTypeFiat,
      AssetTypes.derivative => l10n.assetTypeDerivative,
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.searchAssetType(typeLabel)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: widget.assetType == AssetTypes.crypto
                    ? l10n.searchHintCrypto
                    : widget.assetType == AssetTypes.fiat
                        ? l10n.searchHintFiat
                        : l10n.searchHintGeneral,
                prefixIcon: const Icon(Icons.search),
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
                    : _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _results = [];
                                _error = null;
                              });
                            },
                          )
                        : null,
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          if (_error != null && !_isSearching)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(_error!,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.error)),
            ),
          Expanded(
            child: ListView.separated(
              itemCount: _results.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final r = _results[index];
                return ListTile(
                  leading: CircleAvatar(
                    child: Icon(
                      widget.assetType == AssetTypes.crypto
                          ? Icons.currency_bitcoin
                          : widget.assetType == AssetTypes.fiat
                              ? Icons.attach_money
                              : Icons.show_chart,
                    ),
                  ),
                  title: Text(r.name),
                  subtitle: Text(
                    r.symbol +
                        (r.exchange != null ? ' · ${r.exchange}' : '') +
                        (r.type != null ? ' · ${r.type}' : ''),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).pop(r.symbol),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
