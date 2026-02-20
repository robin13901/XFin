import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:xfin/providers/language_provider.dart';
import 'package:xfin/providers/theme_provider.dart';
import 'package:xfin/l10n/app_localizations.dart';

import 'package:xfin/database/app_database.dart';
import 'package:xfin/utils/db_backup.dart';
import 'package:xfin/utils/date_picker_locale.dart';
import 'package:xfin/utils/format.dart';

import 'package:xfin/utils/global_constants.dart';

import '../providers/database_provider.dart';
import '../widgets/liquid_glass_widgets.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late DateTime? _startDate, _endDate;
  late bool _isSinceStartSelected, _isTodaySelected;

  @override
  void initState() {
    super.initState();

    _startDate = filterStartDate == 0 ? null : intToDateTime(filterStartDate);
    _endDate = filterEndDate == 99999999 ? null : intToDateTime(filterEndDate);
    _isSinceStartSelected = _startDate == null;
    _isTodaySelected = _endDate == null;
  }

  Future<void> _saveStartPref(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(PrefKeys.filterStartDate, value);
    filterStartDate = value;
  }

  Future<void> _saveEndPref(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(PrefKeys.filterEndDate, value);
    filterEndDate = value;
  }

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

  Future<void> _pickStartDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      locale: resolveDatePickerLocale(Localizations.localeOf(context)),
      initialDate: _startDate ?? now,
      firstDate: DateTime(1900),
      lastDate: DateTime(now.year + 10),
    );

    if (picked != null && mounted) {
      setState(() {
        _startDate = picked;
        _isSinceStartSelected = false;
      });
      await _saveStartPref(dateTimeToInt(picked));
      // Optional: also notify your provider/database about the changed filter.
      // e.g. context.read<DatabaseProvider>().setStartFilter(picked);
    }
  }

  Future<void> _pickEndDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      locale: resolveDatePickerLocale(Localizations.localeOf(context)),
      initialDate: _endDate ?? now,
      firstDate: DateTime(1900),
      lastDate: DateTime(now.year + 10),
    );

    if (picked != null && mounted) {
      setState(() {
        _endDate = picked;
        _isTodaySelected = false;
      });
      await _saveEndPref(dateTimeToInt(picked));
      // Optional: also notify your provider/database about the changed filter.
      // e.g. context.read<DatabaseProvider>().setEndFilter(picked);
    }
  }

  ButtonStyle _outlinedStyle(BuildContext context, bool selected) {
    final color = Theme.of(context).colorScheme.primary;
    return OutlinedButton.styleFrom(
      side: BorderSide(color: selected ? color : Colors.transparent, width: 2),
      foregroundColor: selected ? color : null,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
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
                title: Text(l10n.startDate),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OutlinedButton(
                      style: _outlinedStyle(context, _isSinceStartSelected),
                      onPressed: () async {
                        setState(() {
                          _isSinceStartSelected = true;
                          _startDate = null;
                        });
                        await _saveStartPref(0);
                      },
                      child: Text(l10n.sinceStart),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      style: _outlinedStyle(context, !_isSinceStartSelected),
                      onPressed: () => _pickStartDate(context),
                      child: Text(
                        _isSinceStartSelected
                            ? l10n.pickDate
                            : dateFormat.format(_startDate!),
                      ),
                    ),
                  ],
                ),
              ),
              ListTile(
                title: Text(l10n.endDate),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OutlinedButton(
                      style: _outlinedStyle(context, _isTodaySelected),
                      onPressed: () async {
                        setState(() {
                          _isTodaySelected = true;
                          _endDate = null;
                        });
                        await _saveEndPref(99999999);
                      },
                      child: Text(l10n.today),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      style: _outlinedStyle(context, !_isTodaySelected),
                      onPressed: () => _pickEndDate(context),
                      child: Text(
                        _isTodaySelected
                            ? l10n.pickDate
                            : dateFormat.format(_endDate!),
                      ),
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
