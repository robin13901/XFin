import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xfin/database/app_database.dart';
import 'package:xfin/database/tables.dart';
import 'package:xfin/l10n/app_localizations.dart';

class AssetForm extends StatefulWidget {
  final Asset? asset;
  const AssetForm({super.key, this.asset});

  @override
  State<AssetForm> createState() => _AssetFormState();
}

class _AssetFormState extends State<AssetForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _tickerSymbolController;
  late AssetTypes _type;
  late List<String> _existingAssetNames;
  late List<String> _existingTickerSymbols;

  bool get _isEditing => widget.asset != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.asset?.name);
    _tickerSymbolController = TextEditingController(text: widget.asset?.tickerSymbol);
    _type = widget.asset?.type ?? AssetTypes.stock;
    _existingAssetNames = [];
    _existingTickerSymbols = [];

    final db = Provider.of<AppDatabase>(context, listen: false);
    db.assetsDao.watchAllAssets().first.then((assets) {
      if (mounted) {
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
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _tickerSymbolController.dispose();
    super.dispose();
  }

  Future<void> _saveForm() async {
    if (_formKey.currentState!.validate()) {
      final db = Provider.of<AppDatabase>(context, listen: false);

      final name = _nameController.text.trim();
      final tickerSymbol = _tickerSymbolController.text.trim();

      final companion = AssetsCompanion(
        name: drift.Value(name),
        type: drift.Value(_type),
        tickerSymbol: drift.Value(tickerSymbol),
        value: const drift.Value(0.0),
        sharesOwned: const drift.Value(0.0),
        netCostBasis: const drift.Value(0.0),
        brokerCostBasis: const drift.Value(0.0),
        buyFeeTotal: const drift.Value(0.0),
      );

      if (_isEditing) {
        // For editing, we only update the existing fields. The new fields are not part of the form.
        // If you intend to edit them, they should be added to the form.
        await db.assetsDao.updateAsset(widget.asset!.copyWith(
          name: name,
          type: _type,
          tickerSymbol: tickerSymbol,
        ));
      } else {
        await db.assetsDao.insert(companion);
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  String? _validateAssetName(String? value) {
    final l10n = AppLocalizations.of(context)!;
    if (value == null || value.isEmpty) {
      return l10n.pleaseEnterAName; // Reusing string
    }
    if (_existingAssetNames.contains(value.trim())) {
      return l10n.assetAlreadyExists; // New string needed
    }
    return null;
  }

  String? _validateTickerSymbol(String? value) {
    final l10n = AppLocalizations.of(context)!;
    if (value == null || value.isEmpty) {
      return l10n.pleaseEnterATickerSymbol; // New string needed
    }
    if (_existingTickerSymbols.contains(value.trim())) {
      return l10n.tickerSymbolAlreadyExists; // New string needed
    }
    return null;
  }

  String _getAssetTypeName(AppLocalizations l10n, AssetTypes type) {
    switch (type) {
      case AssetTypes.stock:
        return l10n.stock;
      case AssetTypes.crypto:
        return l10n.crypto;
      case AssetTypes.etf:
        return l10n.etf;
      case AssetTypes.bond:
        return l10n.bond;
      case AssetTypes.currency:
        return l10n.currency;
      case AssetTypes.commodity:
        return l10n.commodity;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
                    labelText: l10n.assetName, // New string needed
                    border: const OutlineInputBorder(),
                  ),
                  validator: _validateAssetName,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('asset_ticker_symbol_field'),
                  controller: _tickerSymbolController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    labelText: l10n.tickerSymbol, // New string needed
                    border: const OutlineInputBorder(),
                  ),
                  validator: _validateTickerSymbol,
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
                      setState(() {
                        _type = value;
                      });
                    }
                  },
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
                      child: Text(_isEditing ? l10n.update : l10n.save), // Reusing strings
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
