import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../providers/theme_provider.dart';

/// Aurora colours shared across all screens.
const auroraColors = [
  Color(0xFF1A5CFF), // vivid blue
  Color(0xFF6B3FA0), // deep purple
  Color(0xFF3D5AFE), // indigo
];

/// Builds the aurora background layer for use as the first child
/// inside a [Stack].  Returns [SizedBox.shrink] when aurora is off.
Widget buildAuroraLayer(BuildContext context) {
  if (!ThemeProvider.instance.isAurora) return const SizedBox.shrink();
  return Positioned.fill(
    child: ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: const AuroraBackground(
        colors: auroraColors,
        speed: 2.0,
        opacity: 0.6,
      ),
    ),
  );
}

/// Animated aurora background.
///
/// Renders several large, inherently soft radial-gradient "blobs" that drift
/// in slow organic paths.  The gradients use many stops with a very gradual
/// alpha falloff so no runtime blur pass is needed.
///
/// Wrapped in a [RepaintBoundary] so only the background layer repaints.
class AuroraBackground extends StatefulWidget {
  final List<Color> colors;
  final double speed;
  final double opacity;

  /// Blend mode for the gradient blobs.
  ///
  /// Use [BlendMode.screen] on dark backgrounds (lightens) and
  /// [BlendMode.multiply] on light backgrounds (tints).
  final BlendMode blendMode;

  const AuroraBackground({
    super.key,
    this.colors = const [
      Color(0xFF1A5CFF), // vivid blue
      Color(0xFF6B3FA0), // deep purple
      Color(0xFF3D5AFE), // indigo
    ],
    this.speed = 1.0,
    this.opacity = 1.0,
    this.blendMode = BlendMode.screen,
  });

  @override
  State<AuroraBackground> createState() => _AuroraBackgroundState();
}

class _AuroraBackgroundState extends State<AuroraBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Opacity(
        opacity: widget.opacity,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return CustomPaint(
              painter: _AuroraPainter(
                progress: _controller.value,
                colors: widget.colors,
                speed: widget.speed,
                blendMode: widget.blendMode,
              ),
              size: Size.infinite,
            );
          },
        ),
      ),
    );
  }
}

class _AuroraPainter extends CustomPainter {
  final double progress;
  final List<Color> colors;
  final double speed;
  final BlendMode blendMode;

  _AuroraPainter({
    required this.progress,
    required this.colors,
    required this.speed,
    required this.blendMode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double t = progress * 2 * math.pi * speed;

    final blobs = <_Blob>[
      _Blob(
        cx: size.width * (0.25 + 0.20 * math.sin(t * 0.7)),
        cy: size.height * (0.18 + 0.15 * math.cos(t * 0.5)),
        radius: size.width * 0.85,
        color: _colorAt(0),
      ),
      _Blob(
        cx: size.width * (0.72 + 0.15 * math.cos(t * 0.6)),
        cy: size.height * (0.38 + 0.12 * math.sin(t * 0.8)),
        radius: size.width * 0.75,
        color: _colorAt(1),
      ),
      _Blob(
        cx: size.width * (0.50 + 0.22 * math.sin(t * 0.9 + 1.5)),
        cy: size.height * (0.65 + 0.14 * math.cos(t * 0.4)),
        radius: size.width * 0.80,
        color: _colorAt(2),
      ),
      _Blob(
        cx: size.width * (0.40 + 0.18 * math.cos(t * 0.35 + 2.0)),
        cy: size.height * (0.45 + 0.10 * math.sin(t * 0.55)),
        radius: size.width * 0.70,
        color: _colorAt(0).withValues(alpha: 0.20),
      ),
    ];

    for (final blob in blobs) {
      final rect = Rect.fromCircle(
        center: Offset(blob.cx, blob.cy),
        radius: blob.radius,
      );

      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            blob.color.withValues(alpha: 0.35),
            blob.color.withValues(alpha: 0.25),
            blob.color.withValues(alpha: 0.15),
            blob.color.withValues(alpha: 0.08),
            blob.color.withValues(alpha: 0.02),
            blob.color.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.15, 0.30, 0.50, 0.75, 1.0],
        ).createShader(rect)
        ..blendMode = blendMode;

      canvas.drawOval(rect, paint);
    }
  }

  Color _colorAt(int index) =>
      index < colors.length ? colors[index] : colors[index % colors.length];

  @override
  bool shouldRepaint(covariant _AuroraPainter old) =>
      old.progress != progress;
}

class _Blob {
  final double cx;
  final double cy;
  final double radius;
  final Color color;

  const _Blob({
    required this.cx,
    required this.cy,
    required this.radius,
    required this.color,
  });
}
