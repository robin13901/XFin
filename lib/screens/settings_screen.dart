import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:xfin/providers/language_provider.dart';
import 'package:xfin/providers/live_price_provider.dart';
import 'package:xfin/providers/privacy_provider.dart';
import 'package:xfin/providers/theme_provider.dart';
import 'package:xfin/l10n/app_localizations.dart';

import 'package:xfin/database/app_database.dart';
import 'package:xfin/services/auth_service.dart';
import 'package:xfin/utils/db_backup.dart';
import 'package:xfin/utils/date_picker_locale.dart';
import 'package:xfin/utils/format.dart';

import 'package:xfin/utils/global_constants.dart';

import '../providers/database_provider.dart';
import '../widgets/aurora_background.dart';
import '../widgets/liquid_glass_widgets.dart';
import '../providers/base_currency_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late DateTime? _startDate, _endDate;
  late bool _isSinceStartSelected, _isTodaySelected;
  Asset? _baseCurrencyAsset;

  bool _passwordSet = false;
  bool _biometricsEnabled = false;
  bool _biometricsAvailable = false;

  @override
  void initState() {
    super.initState();

    _startDate = filterStartDate == 0 ? null : intToDateTime(filterStartDate);
    _endDate = filterEndDate == 99999999 ? null : intToDateTime(filterEndDate);
    _isSinceStartSelected = _startDate == null;
    _isTodaySelected = _endDate == null;

    _loadBaseCurrency();
    _loadSecurityState();
  }

  Future<void> _loadSecurityState() async {
    final passwordSet = await AuthService.instance.isPasswordSet;
    final biometricsEnabled = await AuthService.instance.isBiometricsEnabled;
    final biometricsAvailable = await AuthService.instance.canCheckBiometrics;
    if (mounted) {
      setState(() {
        _passwordSet = passwordSet;
        _biometricsEnabled = biometricsEnabled;
        _biometricsAvailable = biometricsAvailable;
      });
    }
  }

  Future<void> _loadBaseCurrency() async {
    final db = context.read<DatabaseProvider>().db;
    final baseCurrencyProvider = context.read<BaseCurrencyProvider>();
    final assetId = baseCurrencyProvider.assetId;

    final asset = await db.assetsDao.getAsset(assetId);
    if (mounted) {
      setState(() {
        _baseCurrencyAsset = asset;
      });
    }
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

  Future<void> _showSetPasswordDialog(BuildContext context, AppLocalizations l10n, {bool isChange = false}) async {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    String? errorMsg;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(isChange ? l10n.securityChangePassword : l10n.securitySetPassword),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isChange) ...[
                TextField(
                  controller: currentCtrl,
                  obscureText: true,
                  decoration: InputDecoration(labelText: l10n.securityCurrentPassword),
                ),
                const SizedBox(height: 8),
              ],
              TextField(
                controller: newCtrl,
                obscureText: true,
                decoration: InputDecoration(labelText: l10n.securityNewPassword),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: confirmCtrl,
                obscureText: true,
                decoration: InputDecoration(labelText: l10n.securityConfirmPassword),
              ),
              if (errorMsg != null) ...[
                const SizedBox(height: 8),
                Text(errorMsg!, style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () async {
                if (isChange) {
                  final ok = await AuthService.instance.verifyPassword(currentCtrl.text);
                  if (!ok) {
                    setDialogState(() => errorMsg = l10n.securityCurrentPasswordWrong);
                    return;
                  }
                }
                if (newCtrl.text.length < 4) {
                  setDialogState(() => errorMsg = l10n.securityPasswordTooShort);
                  return;
                }
                if (newCtrl.text != confirmCtrl.text) {
                  setDialogState(() => errorMsg = l10n.securityPasswordMismatch);
                  return;
                }
                await AuthService.instance.setPassword(newCtrl.text);
                if (ctx.mounted) Navigator.of(ctx).pop();
              },
              child: Text(l10n.save),
            ),
          ],
        ),
      ),
    );

    currentCtrl.dispose();
    newCtrl.dispose();
    confirmCtrl.dispose();
    await _loadSecurityState();
  }

  Future<void> _removePassword(BuildContext context, AppLocalizations l10n) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.securityRemovePassword),
        content: Text(l10n.securityRemovePasswordConfirm),
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
    if (confirmed == true) {
      await AuthService.instance.removePassword();
      await _loadSecurityState();
    }
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

  /// String key used by the theme dropdown. We can't extend [ThemeMode] so we
  /// use a string union: system | light | dark | darkAurora.
  static String _themeKey(ThemeProvider tp) {
    if (tp.isAurora) return 'darkAurora';
    return tp.themeMode.name; // 'system' | 'light' | 'dark'
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);
    final l10n = AppLocalizations.of(context)!;
    final showAurora = themeProvider.isAurora;

    return Scaffold(
      backgroundColor: showAurora ? Colors.transparent : null,
      body: Stack(
        children: [
          // ── Aurora background (only for Dark Aurora) ───────────
          buildAuroraLayer(context),

          // ── Scrollable content ────────────────────────────────
          ListView(
            physics: const ClampingScrollPhysics(),
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + kToolbarHeight + 12,
              left: showAurora ? 16 : 0,
              right: showAurora ? 16 : 0,
              bottom: 24,
            ),
            children: [
              // ── Appearance ──
              _wrapCard(
                showAurora: showAurora,
                children: [
                  ListTile(
                    title: Text(l10n.theme),
                    trailing: DropdownButton<String>(
                      value: _themeKey(themeProvider),
                      onChanged: (String? key) {
                        if (key == null) return;
                        switch (key) {
                          case 'system':
                            themeProvider.setThemeMode(ThemeMode.system);
                          case 'light':
                            themeProvider.setThemeMode(ThemeMode.light);
                          case 'dark':
                            themeProvider.setThemeMode(ThemeMode.dark);
                          case 'darkAurora':
                            themeProvider.setThemeMode(ThemeMode.dark, aurora: true);
                        }
                      },
                      items: [
                        DropdownMenuItem(value: 'system', child: Text(l10n.system)),
                        DropdownMenuItem(value: 'light', child: Text(l10n.light)),
                        DropdownMenuItem(value: 'dark', child: Text(l10n.dark)),
                        DropdownMenuItem(value: 'darkAurora', child: Text(l10n.darkAurora)),
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

              SizedBox(height: showAurora ? 14 : 0),
              if (!showAurora) const Divider(),

              // ── Date Range ──
              _wrapCard(
                showAurora: showAurora,
                children: [
                  ListTile(
                    title: Text(l10n.startDate),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        OutlinedButton(
                          style:
                              _outlinedStyle(context, _isSinceStartSelected),
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
                          style:
                              _outlinedStyle(context, !_isSinceStartSelected),
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
                ],
              ),

              SizedBox(height: showAurora ? 14 : 0),
              if (!showAurora) const Divider(),

              // ── Database ──
              _wrapCard(
                showAurora: showAurora,
                children: [
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

              SizedBox(height: showAurora ? 14 : 0),
              if (!showAurora) const Divider(),

              // ── Live Prices ──
              _wrapCard(
                showAurora: showAurora,
                children: [
                  ListTile(
                    leading: const Icon(Icons.cell_tower),
                    title: const Text('Live-Preise'),
                    subtitle: Consumer<LivePriceProvider>(
                      builder: (context, lp, _) => Text(
                        lp.isSyncing
                            ? 'Synchronisiere...'
                            : 'Yahoo Finance · CoinGecko',
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: showAurora ? 14 : 0),
              if (!showAurora) const Divider(),

              // ── Security ──
              _wrapCard(
                showAurora: showAurora,
                children: [
                  ListTile(
                    leading: const Icon(Icons.visibility_off_outlined),
                    title: Text(l10n.privacyMode),
                    subtitle: Text(l10n.privacyModeDescription),
                    trailing: Consumer<PrivacyProvider>(
                      builder: (context, privacy, _) => Switch(
                        value: privacy.enabled,
                        onChanged: (val) => privacy.setEnabled(val),
                      ),
                    ),
                  ),
                  if (!_passwordSet)
                    ListTile(
                      leading: const Icon(Icons.lock_outline),
                      title: Text(l10n.securitySetPassword),
                      onTap: () => _showSetPasswordDialog(context, l10n),
                    )
                  else ...[
                    ListTile(
                      leading: const Icon(Icons.lock),
                      title: Text(l10n.securityChangePassword),
                      onTap: () => _showSetPasswordDialog(context, l10n, isChange: true),
                    ),
                    ListTile(
                      leading: const Icon(Icons.lock_open),
                      title: Text(l10n.securityRemovePassword),
                      onTap: () => _removePassword(context, l10n),
                    ),
                    ListTile(
                      leading: const Icon(Icons.fingerprint),
                      title: Text(l10n.securityBiometrics),
                      subtitle: _biometricsAvailable
                          ? null
                          : Text(l10n.securityBiometricsNotAvailable),
                      trailing: Switch(
                        value: _biometricsEnabled,
                        onChanged: _biometricsAvailable
                            ? (val) async {
                                await AuthService.instance.setBiometricsEnabled(val);
                                await _loadSecurityState();
                              }
                            : null,
                      ),
                    ),
                  ],
                ],
              ),

              SizedBox(height: showAurora ? 14 : 0),
              if (!showAurora) const Divider(),

              // ── Info ──
              _wrapCard(
                showAurora: showAurora,
                children: [
                  ListTile(
                    title: Text(l10n.baseCurrency),
                    trailing: Text(
                      _baseCurrencyAsset != null
                          ? '${_baseCurrencyAsset!.name} (${_baseCurrencyAsset!.currencySymbol ?? _baseCurrencyAsset!.tickerSymbol})'
                          : '${BaseCurrencyProvider.symbol} (${context.read<BaseCurrencyProvider>().tickerSymbol})',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // ── Glass app bar ─────────────────────────────────────
          buildLiquidGlassAppBar(context, title: Text(l10n.settings)),
        ],
      ),
    );
  }

  /// Wraps [children] in a glass card when aurora is active,
  /// otherwise returns a plain [Column].
  Widget _wrapCard({required bool showAurora, required List<Widget> children}) {
    if (showAurora) {
      return buildLiquidGlassCard(children: children);
    }
    return Column(mainAxisSize: MainAxisSize.min, children: children);
  }
}
