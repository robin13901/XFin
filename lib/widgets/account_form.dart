import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xfin/database/app_database.dart';
import 'package:xfin/database/tables.dart';
import 'package:xfin/l10n/app_localizations.dart';
import 'package:xfin/providers/base_currency_provider.dart';
import '../validators.dart';

class AccountForm extends StatefulWidget {
  const AccountForm({super.key});

  @override
  State<AccountForm> createState() => _AccountFormState();
}

class _AccountFormState extends State<AccountForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _initialBalanceController;
  late AccountTypes _type;
  late List<String> _existingAccountNames;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _initialBalanceController = TextEditingController();
    _type = AccountTypes.cash;
    _existingAccountNames = [];

    final db = Provider.of<AppDatabase>(context, listen: false);
    db.accountsDao.getAllAccounts().then((accounts) {
      if (!mounted) return;
      setState(() {
        _existingAccountNames = accounts.map((a) => a.name).toList();
      });
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _initialBalanceController.dispose();
    super.dispose();
  }

  Future<void> _saveForm() async {
    if (_formKey.currentState!.validate()) {
      final db = Provider.of<AppDatabase>(context, listen: false);

      final name = _nameController.text.trim();
      final initialBalance = _type == AccountTypes.portfolio
          ? 0.0
          : double.parse(_initialBalanceController.text.replaceAll(',', '.'));

      final account = AccountsCompanion(
        name: drift.Value(name),
        balance: drift.Value(initialBalance),
        initialBalance: drift.Value(initialBalance),
        type: drift.Value(_type),
      );
      await db.accountsDao.createAccount(account);

      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  String _getAccountTypeName(AppLocalizations l10n, AccountTypes type) {
    switch (type) {
      case AccountTypes.cash:
        return l10n.cash;
      case AccountTypes.portfolio:
        return l10n.portfolio;
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
                const SizedBox(height: 6),
                TextFormField(
                  key: const Key('account_name_field'),
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: l10n.accountName,
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) => validator.validateUniqueAccountName(value, _existingAccountNames),
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
                    if (value != null) {
                      setState(() {
                        _type = value;
                      });
                    }
                  },
                  validator: (value) => value == null ? l10n.pleaseSelectAType : null,
                ),
                if (_type == AccountTypes.cash) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const Key('initial_balance_field'),
                    controller: _initialBalanceController,
                    decoration: InputDecoration(
                      labelText: l10n.initialBalance,
                      border: const OutlineInputBorder(),
                      suffixText: currencyProvider.symbol, // Use the symbol from the provider
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: false),
                    validator: (value) => validator.validateMaxTwoDecimalsGreaterEqualZero(value),
                  ),
                ],
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