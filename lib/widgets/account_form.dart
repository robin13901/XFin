import 'dart:async';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xfin/database/app_database.dart';
import 'package:xfin/database/tables.dart';
import 'package:xfin/l10n/app_localizations.dart';
import 'package:xfin/providers/base_currency_provider.dart';
import 'package:xfin/widgets/reusables.dart';
import '../utils/validators.dart';

class AccountForm extends StatefulWidget {
  const AccountForm({super.key});

  @override
  State<AccountForm> createState() => _AccountFormState();
}

class _AccountFormState extends State<AccountForm> {
  // Step 1: Account Details
  final _step1FormKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late AccountTypes _type;
  late List<String> _existingAccountNames;

  // Step 2: Assets
  final _assetFormKey = GlobalKey<FormState>();
  late TextEditingController _sharesController;
  late TextEditingController _pricePerShareController;
  int? _selectedAssetId;
  final List<AssetOnAccount> _pendingAssets = [];
  List<Asset> _allAssets = [];
  Map<int, Asset> _assetMap = {};

  // Navigation state
  int _currentStep = 0;

  // Cached collaborators
  late AppDatabase _db;
  late Reusables _reusables;

  // Progressive rendering: show cheap UI immediately, heavy UI after first frame + data load
  bool _renderHeavy = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _db = Provider.of<AppDatabase>(context, listen: false);
    _reusables = Reusables(context);
  }

  @override
  void initState() {
    super.initState();

    // Step 1 init
    _nameController = TextEditingController();
    _type = AccountTypes.cash;
    _existingAccountNames = [];

    // Step 2 init
    _sharesController = TextEditingController();
    _pricePerShareController = TextEditingController();

    // Defer loading static DB data until after first frame to guarantee immediate first paint.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // start stopwatch or logging if needed elsewhere
      _loadStaticData().then((_) {
        if (mounted) setState(() => _renderHeavy = true);
      });
    });
  }

  Future<void> _loadStaticData() async {
    final assets = await _db.assetsDao.getAllAssets();

    setState(() {
      _allAssets = assets;
      _assetMap = { for (final a in assets) a.id: a };
      _renderHeavy = true;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _sharesController.dispose();
    _pricePerShareController.dispose();
    super.dispose();
  }

  // --- Actions ---

  void _onNext() {
    if (_step1FormKey.currentState!.validate()) {
      setState(() {
        _currentStep = 1;
      });
    }
  }

  void _onBack() {
    setState(() {
      _currentStep = 0;
    });
  }

  void _addAssetToBuffer(AppLocalizations l10n, List<Asset> availableAssets) {
    if (_assetFormKey.currentState!.validate()) {
      if (_selectedAssetId == null) return;

      // Check uniqueness
      final isAlreadyAdded =
      _pendingAssets.any((pa) => pa.assetId == _selectedAssetId);
      if (isAlreadyAdded) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.assetAlreadyAdded)),
        );
        return;
      }

      // Parse values
      final shares = double.parse(_sharesController.text.replaceAll(',', '.'));
      final pricePerShare = _selectedAssetId == 1
          ? 1.0
          : double.parse(_pricePerShareController.text.replaceAll(',', '.'));
      final value = shares * pricePerShare;

      setState(() {
        _pendingAssets.add(AssetOnAccount(
          accountId: 0,
          assetId: _selectedAssetId!,
          value: value,
          shares: shares,
          netCostBasis: pricePerShare,
          brokerCostBasis: pricePerShare,
          buyFeeTotal: 0,
        ));

        // Reset asset input fields
        _selectedAssetId = null;
        _sharesController.clear();
        _pricePerShareController.clear();
      });
    }
  }

  void _removeAssetFromBuffer(int index) {
    setState(() {
      _pendingAssets.removeAt(index);
    });
  }

  Future<void> _saveForm() async {
    final db = _db;
    final name = _nameController.text.trim();

    await db.transaction(() async {
      final initialBalance =
      _pendingAssets.fold<double>(0.0, (sum, pa) => sum + pa.value);
      final accountId = await db.accountsDao.insert(AccountsCompanion.insert(
        name: name,
        type: _type,
        balance: drift.Value(initialBalance),
        initialBalance: drift.Value(initialBalance),
      ));

      for (var pa in _pendingAssets) {
        AssetOnAccount aoa = pa.copyWith(accountId: accountId);
        await db.assetsOnAccountsDao.updateAOA(aoa);
        await db.assetsDao.updateAsset(aoa.assetId, aoa.shares, aoa.value);
      }
    });

    if (mounted) Navigator.of(context).pop();
  }

  // --- UI Helpers ---

  String _getAccountTypeName(AppLocalizations l10n, AccountTypes type) {
    switch (type) {
      case AccountTypes.cash:
        return l10n.cash;
      case AccountTypes.bankAccount:
        return l10n.bankAccount;
      case AccountTypes.portfolio:
        return l10n.portfolio;
      case AccountTypes.cryptoWallet:
        return l10n.cryptoWallet;
    }
  }

  String _getAccountTypeInfo(AppLocalizations l10n, AccountTypes type) {
    switch (type) {
      case AccountTypes.cash:
        return l10n.cashInfo;
      case AccountTypes.bankAccount:
        return l10n.bankAccountInfo;
      case AccountTypes.portfolio:
        return l10n.portfolioInfo;
      case AccountTypes.cryptoWallet:
        return l10n.cryptoWalletInfo;
    }
  }

  void _showTypeInfoDialog(AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_getAccountTypeName(l10n, _type)),
        content: Text(_getAccountTypeInfo(l10n, _type)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.ok),
          ),
        ],
      ),
    );
  }

  List<Asset> _filterAssetsForType(List<Asset> allAssets) {
    switch (_type) {
      case AccountTypes.bankAccount: // Only Base Currency (ID 1)
        return allAssets.where((a) => a.id == 1).toList();
      case AccountTypes.cash: // Only Currency Assets
        return allAssets.where((a) => a.type == AssetTypes.fiat).toList();
      case AccountTypes.cryptoWallet: // Only Crypto Assets
        return allAssets.where((a) => a.type == AssetTypes.crypto).toList();
      case AccountTypes.portfolio: // All assets
        return allAssets;
    }
  }

  // --- View Builders ---

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: MediaQuery.of(context).viewInsets,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: AnimatedCrossFade(
            duration: const Duration(milliseconds: 50),
            crossFadeState: _currentStep == 0
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: _buildStep1(context, l10n),
            secondChild: _buildStep2(context, l10n),
          ),
        ),
      ),
    );
  }

  Widget _buildStep1(BuildContext context, AppLocalizations l10n) {
    final validator = Validator(l10n);

    return Form(
      key: _step1FormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 6),
          TextFormField(
            key: const Key('account_name_field'),
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: l10n.accountName,
              border: const OutlineInputBorder(),
            ),
            validator: (value) =>
                validator.validateIsUnique(value, _existingAccountNames),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<AccountTypes>(
            key: const Key('account_type_dropdown'),
            initialValue: _type,
            decoration: InputDecoration(
              labelText: l10n.type,
              border: const OutlineInputBorder(),
            ),
            items: AccountTypes.values.map((type) {
              return DropdownMenuItem(
                value: type,
                child: Text(_getAccountTypeName(l10n, type)),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null && value != _type) {
                setState(() {
                  _type = value;
                  _selectedAssetId = null;
                });
              }
            },
            validator: (value) => value == null ? l10n.pleaseSelectAType : null,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.cancel),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _onNext,
                child: Text(l10n.next),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStep2(BuildContext context, AppLocalizations l10n) {
    final currencyProvider = Provider.of<BaseCurrencyProvider>(context);
    final reusables = _reusables;

    // If heavy UI not ready yet, show a lightweight placeholder that paints instantly.
    if (!_renderHeavy) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${_nameController.text} (${_getAccountTypeName(l10n, _type)})',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.info_outline, size: 20),
                onPressed: () => _showTypeInfoDialog(l10n),
                tooltip: l10n.info,
              ),
            ],
          ),
          const SizedBox(height: 16),
          const SizedBox(
            height: 56,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          const SizedBox(height: 16),
          // Footer buttons (allow navigation/back even while loading)
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(onPressed: _onBack, child: Text(l10n.back)),
              const SizedBox(width: 8),
              ElevatedButton(onPressed: _saveForm, child: Text(l10n.save)),
            ],
          ),
        ],
      );
    }

    // Heavy UI path: static data is loaded and we can build full controls.
    final allAssets = _allAssets;
    final filteredAssets = _filterAssetsForType(allAssets);
    final Asset? selectedAsset = _assetMap[_selectedAssetId];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '${_nameController.text} (${_getAccountTypeName(l10n, _type)})',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.info_outline, size: 20),
              onPressed: () => _showTypeInfoDialog(l10n),
              tooltip: l10n.info,
            ),
          ],
        ),

        // List of added assets (one-liners)
        if (_pendingAssets.isNotEmpty)
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _pendingAssets.length,
            itemBuilder: (context, index) {
              final item = _pendingAssets[index];
              final asset = _assetMap[item.assetId];
              final oneLine =
                  '${item.shares} ${asset?.tickerSymbol ?? ''} @ ${item.netCostBasis} ${currencyProvider.symbol} ≈ ${currencyProvider.format.format(item.value)}';

              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  oneLine,
                  style: const TextStyle(
                      fontStyle: FontStyle.italic, color: Colors.grey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.grey),
                  onPressed: () => _removeAssetFromBuffer(index),
                ),
              );
            },
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              l10n.noAssetsAddedYet,
              style: const TextStyle(
                  fontStyle: FontStyle.italic, color: Colors.grey),
            ),
          ),

        const SizedBox(height: 16),

        // Asset add form (uses preloaded asset list)
        Form(
          key: _assetFormKey,
          child: Column(
            children: [
              DropdownButtonFormField<int>(
                key: const Key('assets_dropdown'),
                initialValue: _selectedAssetId,
                decoration: InputDecoration(
                  labelText: l10n.asset,
                  border: const OutlineInputBorder(),
                  errorMaxLines: 2,
                ),
                items: filteredAssets.map((asset) {
                  return DropdownMenuItem(
                    value: asset.id,
                    child: Text(asset.name),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != _selectedAssetId) {
                    setState(() {
                      _selectedAssetId = value;
                    });
                  }
                },
                validator: (value) {
                  if (value == null) return l10n.requiredField;
                  final isAlreadyAdded =
                  _pendingAssets.any((pa) => pa.assetId == value);
                  if (isAlreadyAdded) return l10n.assetAlreadyAdded;
                  return null;
                },
              ),
              const SizedBox(height: 16),
              reusables.buildSharesInputRow(
                  _sharesController, _pricePerShareController, selectedAsset),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _addAssetToBuffer(l10n, filteredAssets),
                  icon: const Icon(Icons.add),
                  label: Text(l10n.addAsset),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // Navigation Buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: _onBack,
              child: Text(l10n.back),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _saveForm,
              child: Text(l10n.save),
            ),
          ],
        ),
      ],
    );
  }
}
