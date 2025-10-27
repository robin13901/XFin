import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:xfin/database/app_database.dart';

class AccountForm extends StatefulWidget {
  final Account? account;

  const AccountForm({super.key, this.account});

  @override
  State<AccountForm> createState() => _AccountFormState();
}

class _AccountFormState extends State<AccountForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _initialBalanceController;
  late String _type;
  late List<String> _existingAccountNames;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.account?.name);
    _initialBalanceController =
        TextEditingController(text: widget.account?.balance.toString() ?? '0.0');
    _type = widget.account?.type ?? 'Cash';
    _existingAccountNames = [];

    final db = Provider.of<AppDatabase>(context, listen: false);
    db.accountsDao.watchAllAccounts().first.then((accounts) {
      if (mounted) {
        setState(() {
          _existingAccountNames = accounts
              .map((a) => a.name)
              .where((name) => name != widget.account?.name)
              .toList();
        });
      }
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
      final initialBalance =
          double.parse(_initialBalanceController.text.replaceAll(',', '.'));

      if (widget.account == null) {
        final creationDate =
            int.parse(DateFormat('yyyyMMdd').format(DateTime.now()));
        final companion = AccountsCompanion(
          name: drift.Value(name),
          balance: drift.Value(initialBalance),
          initialBalance: drift.Value(initialBalance),
          type: drift.Value(_type),
          creationDate: drift.Value(creationDate),
        );
        await db.accountsDao.addAccount(companion);
      } else {
        final companion = AccountsCompanion(
          name: drift.Value(name),
          type: drift.Value(_type),
        );
        await db.accountsDao.updateAccount(
            companion.copyWith(id: drift.Value(widget.account!.id)));
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Account Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a name';
                    }
                    if (_existingAccountNames.contains(value.trim())) {
                      return 'An account with this name already exists.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _initialBalanceController,
                  readOnly: widget.account != null,
                  decoration: InputDecoration(
                    labelText: 'Initial Balance',
                    border: const OutlineInputBorder(),
                    suffixText: '€',
                    fillColor:
                        widget.account != null ? Colors.grey[200] : null,
                    filled: widget.account != null,
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                      signed: true, decimal: true),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a balance';
                    }
                    final balance =
                        double.tryParse(value.replaceAll(',', '.'));
                    if (balance == null) {
                      return 'Invalid number';
                    }
                    if (balance < 0) {
                      return 'Initial balance cannot be negative.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _type,
                  decoration: const InputDecoration(
                    labelText: 'Type',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                  ],
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
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _saveForm,
                      child: const Text('Save'),
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
