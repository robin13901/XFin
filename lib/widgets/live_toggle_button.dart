import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_theme.dart';
import '../l10n/app_localizations.dart';
import '../providers/live_price_provider.dart';

class LiveToggleButton extends StatefulWidget {
  const LiveToggleButton({super.key});

  @override
  State<LiveToggleButton> createState() => _LiveToggleButtonState();
}

class _LiveToggleButtonState extends State<LiveToggleButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _pulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Consumer<LivePriceProvider>(
      builder: (context, provider, _) {
        final isSyncing = provider.isSyncing;
        final syncFailed = provider.syncFailed;
        final isLive = provider.isLive;
        final isConnected = provider.isConnected;
        final isConnecting = isLive && !isConnected;

        if ((isConnecting || isSyncing) && !_pulseController.isAnimating) {
          _pulseController.repeat(reverse: true);
        } else if (!isConnecting && !isSyncing && _pulseController.isAnimating) {
          _pulseController.stop();
          _pulseController.value = 1.0;
        }

        if (isSyncing) {
          return IconButton(
            key: const Key('live_toggle'),
            icon: FadeTransition(
              opacity: _pulseAnimation,
              child: const Icon(Icons.sync),
            ),
            onPressed: null,
            tooltip: l10n.syncInProgress,
          );
        }

        if (syncFailed && !isLive) {
          return IconButton(
            key: const Key('live_toggle'),
            icon: const Icon(
              Icons.wifi_off,
              color: Colors.orange,
            ),
            onPressed: null,
            tooltip: l10n.noInternetConnection,
          );
        }

        Widget icon = Icon(
          Icons.cell_tower,
          color: isLive
              ? (isConnected ? AppColors.green : Colors.orange)
              : null,
        );

        if (isConnecting) {
          icon = FadeTransition(
            opacity: _pulseAnimation,
            child: icon,
          );
        }

        return IconButton(
          key: const Key('live_toggle'),
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              icon,
              if (isLive && isConnected)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          onPressed: () async {
            await provider.toggle();
            if (context.mounted && provider.lastError != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(provider.lastError!),
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          },
          tooltip: isLive ? l10n.liveOn : l10n.liveOff,
        );
      },
    );
  }
}
