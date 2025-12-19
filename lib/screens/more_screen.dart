import 'package:flutter/material.dart';
import 'package:xfin/l10n/app_localizations.dart';
import 'package:xfin/screens/settings_screen.dart';
import 'package:xfin/screens/assets_screen.dart';
import 'package:xfin/screens/trades_screen.dart';
import 'package:xfin/screens/transfers_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  Widget _buildCard({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.all(12.0),
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 140,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 36),
                const SizedBox(height: 8),
                Text(label),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _pushScreen(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.more),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Make the grid responsive: more columns on wide screens
          final crossAxisCount = constraints.maxWidth >= 800
              ? 4
              : (constraints.maxWidth >= 600 ? 3 : 2);

          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 8.0),
                child: Column(
                  // center the grid vertically when there's extra space
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GridView.count(
                      crossAxisCount: crossAxisCount,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: 1.15,
                      children: <Widget>[
                        _buildCard(
                          context: context,
                          icon: Icons.settings,
                          label: l10n.settings,
                          onTap: () => _pushScreen(context, const SettingsScreen()),
                        ),
                        _buildCard(
                          context: context,
                          icon: Icons.monetization_on,
                          label: l10n.assets,
                          onTap: () => _pushScreen(context, const AssetsScreen()),
                        ),
                        _buildCard(
                          context: context,
                          icon: Icons.swap_horiz,
                          label: l10n.trades,
                          onTap: () => _pushScreen(context, const TradesScreen()),
                        ),
                        // Transactions card (new)
                        _buildCard(
                          context: context,
                          icon: Icons.receipt_long,
                          label: l10n.transfers,
                          onTap: () => _pushScreen(context, const TransfersScreen()),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}