import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:xfin/providers/language_provider.dart';
import 'package:xfin/providers/theme_provider.dart';
import 'package:xfin/l10n/app_localizations.dart';

import 'package:xfin/database/app_database.dart';
import 'package:xfin/utils/db_backup.dart';

import '../providers/database_provider.dart';
import '../widgets/liquid_glass_widgets.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _exportDb(BuildContext context, AppLocalizations l10n) async {
    await DbBackup.exportAndShareDatabase(context, l10n);
  }

  Future<void> _importDb(BuildContext context, AppLocalizations l10n) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.importDatabase),
        content: Text(l10n.importDatabaseWarning),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;
    AppDatabase currentDb = context.read<DatabaseProvider>().db;
    await DbBackup.importDatabaseFromPicker(context, currentDb, l10n);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Stack(
        children: [
          ListView(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + kToolbarHeight,
            ),
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
              const Divider(),
              ListTile(
                leading: const Icon(Icons.upload_file),
                title: Text(l10n.exportDatabase),
                onTap: () => _exportDb(context, l10n),
              ),
              ListTile(
                leading: const Icon(Icons.download_rounded),
                title: Text(l10n.importDatabase),
                onTap: () => _importDb(context, l10n),
              ),
            ],
          ),
          buildLiquidGlassAppBar(context, title: Text(l10n.settings)),
        ],
      ),
    );
  }
}
