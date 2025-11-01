import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xfin/providers/language_provider.dart';
import 'package:xfin/providers/theme_provider.dart';
import 'package:xfin/l10n/app_localizations.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
      ),
      body: ListView(
        children: [
          ListTile(
            title: Text(l10n.theme),
            trailing: DropdownButton<ThemeMode>(
              value: themeProvider.themeMode,
              onChanged: (ThemeMode? newValue) {
                if (newValue != null) {
                  themeProvider.setThemeMode(newValue);
                }
              },
              items: [
                DropdownMenuItem(
                  value: ThemeMode.system,
                  child: Text(l10n.system),
                ),
                DropdownMenuItem(
                  value: ThemeMode.light,
                  child: Text(l10n.light),
                ),
                DropdownMenuItem(
                  value: ThemeMode.dark,
                  child: Text(l10n.dark),
                ),
              ],
            ),
          ),
          ListTile(
            title: Text(l10n.language),
            trailing: DropdownButton<Locale>(
              value: languageProvider.appLocale,
              onChanged: (Locale? newValue) {
                if (newValue != null) {
                  languageProvider.setLocale(newValue);
                }
              },
              items: [
                DropdownMenuItem(
                  value: const Locale('en'),
                  child: Text(l10n.english),
                ),
                DropdownMenuItem(
                  value: const Locale('de'),
                  child: Text(l10n.german),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
