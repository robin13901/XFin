import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:xfin/providers/language_provider.dart';
import 'package:xfin/providers/theme_provider.dart';
import 'package:xfin/l10n/app_localizations.dart';

import 'package:xfin/database/app_database.dart';
import 'package:xfin/database/connection/connection.dart' as connection;
import 'package:xfin/utils/db_backup.dart';

import '../widgets/liquid_glass_widgets.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _exportDb(BuildContext context) async {
    try {
      await DbBackup.exportAndShareDatabase(context);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    }
  }

  Future<void> _importDb(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Import database'),
        content: const Text(
          'Importing will replace all current data. This cannot be undone. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!context.mounted) return;

    AppDatabase? currentDb;
    try {
      currentDb = Provider.of<AppDatabase>(context, listen: false);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Database provider not found')),
      );
      return;
    }

    final newDb = await DbBackup.importDatabaseFromPicker(
      context,
      currentDb,
      recreateDb: () async => AppDatabase(connection.connect()),
    );

    if (!context.mounted) return;

    if (newDb != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Database replaced. Restart the app to apply changes.'),
        ),
      );
    }
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
              top:
              MediaQuery.of(context).padding.top + kToolbarHeight,
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

              // Export DB
              ListTile(
                leading: const Icon(Icons.upload_file),
                title: const Text('Export database'),
                onTap: () => _exportDb(context),
              ),

              // Import DB (with confirmation)
              ListTile(
                leading: const Icon(Icons.download_rounded),
                title: const Text('Import database'),
                onTap: () => _importDb(context),
              ),
            ],
          ),
          buildLiquidGlassAppBar(context, title: Text(l10n.settings)),
        ],
      ),
    );
  }
}
