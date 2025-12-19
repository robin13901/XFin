import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xfin/database/tables.dart';
import 'package:xfin/l10n/app_localizations.dart';

import '../database/app_database.dart';
import '../providers/base_currency_provider.dart';
import '../providers/language_provider.dart';

class CurrencySelectionScreen extends StatefulWidget {
  const CurrencySelectionScreen({super.key});

  @override
  State<CurrencySelectionScreen> createState() => _CurrencySelectionScreenState();
}

class _CurrencySelectionScreenState extends State<CurrencySelectionScreen> {
  String? _selectedCurrency;
  final List<String> _availableCurrencies = ['EUR', 'USD', 'GBP', 'JPY'];
  final List<String> _currencySymbols = ['€', '\$', '£', '¥'];

  Future<void> _saveCurrency(String currency) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_currency', currency);
    await prefs.setBool('currency_selected', true);
  }

  void _onCurrencySelected(String currency) {
    setState(() {
      _selectedCurrency = currency;
    });
  }

  void _confirmSelection() async {
    if (_selectedCurrency != null) {
      await _saveCurrency(_selectedCurrency!);
      if (mounted) {
        final db = Provider.of<AppDatabase>(context, listen: false);
        final currencySymbol = _currencySymbols[_availableCurrencies.indexOf(_selectedCurrency!)];
        final asset = AssetsCompanion(
          name: drift.Value(_selectedCurrency!),
          type: const drift.Value(AssetTypes.fiat),
          tickerSymbol: drift.Value(_selectedCurrency!),
          currencySymbol: drift.Value(currencySymbol),
          value: const drift.Value(0.0),
          shares: const drift.Value(0.0),
          netCostBasis: const drift.Value(1.0),
          brokerCostBasis: const drift.Value(1.0),
          buyFeeTotal: const drift.Value(0.0),
        );
        await db.assetsDao.insert(asset);
      }
      if (mounted) await Provider.of<BaseCurrencyProvider>(context, listen: false).initialize(Provider.of<LanguageProvider>(context, listen: false).appLocale);
      if (mounted) Navigator.of(context).pushReplacementNamed('/main');
    } else {
      // Show a snackbar or toast to prompt user to select a currency
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.pleaseSelectCurrency)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.selectCurrency),
        automaticallyImplyLeading: false, // Prevent going back
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.currencySelectionPrompt,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.builder(
                itemCount: _availableCurrencies.length,
                itemBuilder: (context, index) {
                  final currency = _availableCurrencies[index];
                  return ListTile(
                    title: Text(currency),
                    leading: Icon(
                      _selectedCurrency == currency
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                    ),
                    onTap: () {
                      _onCurrencySelected(currency);
                    },
                  );
                },
              ),
            ),
            Center(
              child: ElevatedButton(
                onPressed: _confirmSelection,
                child: Text(l10n.confirm),
              ),
            ),
          ],
        ),
      ),
    );
  }
}