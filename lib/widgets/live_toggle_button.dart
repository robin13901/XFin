import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/live_price_provider.dart';

class LiveToggleButton extends StatelessWidget {
  const LiveToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LivePriceProvider>(
      builder: (context, provider, _) {
        final isLive = provider.isLive;
        final isConnected = provider.isConnected;

        return IconButton(
          key: const Key('live_toggle'),
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                Icons.cell_tower,
                color: isLive
                    ? (isConnected ? Colors.green : Colors.orange)
                    : null,
              ),
              if (isLive && isConnected)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          onPressed: () => provider.toggle(),
          tooltip: isLive ? 'Live off' : 'Live on',
        );
      },
    );
  }
}
