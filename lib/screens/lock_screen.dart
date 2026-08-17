import 'package:flutter/material.dart';
import 'package:xfin/l10n/app_localizations.dart';
import 'package:xfin/services/auth_service.dart';
import 'package:xfin/widgets/aurora_background.dart';
import 'package:xfin/widgets/liquid_glass_widgets.dart';
import 'package:provider/provider.dart';
import 'package:xfin/providers/theme_provider.dart';

class LockScreen extends StatefulWidget {
  final AuthService? authService;

  const LockScreen({super.key, this.authService});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _obscure = true;
  String? _errorText;
  bool _loading = false;
  bool _biometricsAvailable = false;
  bool _biometricsChecked = false;

  AuthService get _auth => widget.authService ?? AuthService.instance;

  @override
  void initState() {
    super.initState();
    _initBiometrics();
  }

  Future<void> _initBiometrics() async {
    final enabled = await _auth.isBiometricsEnabled;
    if (!enabled || !mounted) {
      setState(() => _biometricsChecked = true);
      _focusNode.requestFocus();
      return;
    }
    final available = await _auth.canCheckBiometrics;
    if (!mounted) return;
    setState(() {
      _biometricsAvailable = available;
      _biometricsChecked = true;
    });
    if (available) {
      final ok = await _tryBiometrics();
      if (!ok && mounted) _focusNode.requestFocus();
    } else {
      _focusNode.requestFocus();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<bool> _tryBiometrics() async {
    if (!mounted) return false;
    final l10n = AppLocalizations.of(context)!;
    final ok = await _auth.authenticateWithBiometrics(l10n.lockBiometricReason);
    if (ok && mounted) _unlock();
    return ok;
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    final password = _controller.text;
    if (password.isEmpty) return;

    setState(() {
      _loading = true;
      _errorText = null;
    });

    final ok = await _auth.verifyPassword(password);

    if (!mounted) return;
    if (ok) {
      _unlock();
    } else {
      setState(() {
        _loading = false;
        _errorText = l10n.lockWrongPassword;
        _controller.clear();
      });
      _focusNode.requestFocus();
    }
  }

  void _unlock() {
    Navigator.of(context).pushReplacementNamed('/main');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isAurora = context.watch<ThemeProvider>().isAurora;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: isAurora ? Colors.transparent : null,
      body: Stack(
        children: [
          buildAuroraLayer(context),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: 64,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    l10n.lockTitle,
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 32),
                  if (_biometricsChecked)
                    if (isAurora)
                      _buildGlassField(l10n, theme)
                    else
                      _buildPlainField(l10n, theme),
                  const SizedBox(height: 16),
                  if (_errorText != null)
                    Text(
                      _errorText!,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _loading || !_biometricsChecked ? null : _submit,
                      child: _loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(l10n.lockUnlock),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_biometricsAvailable)
                    TextButton.icon(
                      icon: const Icon(Icons.fingerprint),
                      label: Text(l10n.lockUseBiometrics),
                      onPressed: _tryBiometrics,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlainField(AppLocalizations l10n, ThemeData theme) {
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      obscureText: _obscure,
      autofocus: false,
      textInputAction: TextInputAction.done,
      onSubmitted: (_) => _submit(),
      decoration: InputDecoration(
        labelText: l10n.lockPasswordLabel,
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
      ),
    );
  }

  Widget _buildGlassField(AppLocalizations l10n, ThemeData theme) {
    return buildLiquidGlassCard(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            obscureText: _obscure,
            autofocus: false,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              labelText: l10n.lockPasswordLabel,
              border: InputBorder.none,
              suffixIcon: IconButton(
                icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
