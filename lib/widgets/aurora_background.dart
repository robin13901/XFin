import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';

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
  if (!context.watch<ThemeProvider>().isAurora) return const SizedBox.shrink();
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

/// Singleton animator that drives all [AuroraBackground] widgets.
///
/// Uses a single persistent frame callback instead of per-widget
/// AnimationControllers.  Throttles updates to [targetFps] (default 20)
/// so the slow ambient animation doesn't repaint on every vsync frame.
class AuroraAnimator {
  AuroraAnimator._();
  static final AuroraAnimator instance = AuroraAnimator._();

  /// The current animation progress in [0, 1) range, cycling every
  /// [cycleDuration].
  final ValueNotifier<double> progress = ValueNotifier<double>(0.0);

  static const Duration cycleDuration = Duration(seconds: 60);
  static const int targetFps = 20;
  static const double _minDelta = 1.0 / (targetFps * 60); // progress delta

  int _listeners = 0;
  int? _callbackId;
  Duration _lastFrameTime = Duration.zero;
  double _lastEmitted = 0.0;

  /// Call when an AuroraBackground mounts.
  void addListener() {
    _listeners++;
    if (_listeners == 1) _start();
  }

  /// Call when an AuroraBackground unmounts.
  void removeListener() {
    _listeners--;
    if (_listeners <= 0) {
      _listeners = 0;
      _stop();
    }
  }

  void _start() {
    if (_callbackId != null) return;
    _lastFrameTime = Duration.zero;
    _callbackId =
        SchedulerBinding.instance.scheduleFrameCallback(_onFrame);
  }

  void _stop() {
    // No explicit cancel needed — _onFrame will not reschedule
    // when _listeners <= 0
    _callbackId = null;
  }

  void _onFrame(Duration timestamp) {
    _callbackId = null;
    if (_listeners <= 0) return;

    if (_lastFrameTime == Duration.zero) {
      _lastFrameTime = timestamp;
    }

    final elapsed = timestamp - _lastFrameTime;
    _lastFrameTime = timestamp;

    // Advance progress
    final delta =
        elapsed.inMicroseconds / cycleDuration.inMicroseconds;
    var p = progress.value + delta;
    if (p >= 1.0) p -= 1.0;

    // Only notify listeners when change exceeds threshold (~20fps)
    if ((p - _lastEmitted).abs() >= _minDelta || p < _lastEmitted) {
      _lastEmitted = p;
      progress.value = p;
    }

    // Schedule next frame
    _callbackId =
        SchedulerBinding.instance.scheduleFrameCallback(_onFrame);
  }
}

/// Animated aurora background.
///
/// Renders several large, inherently soft radial-gradient "blobs" that drift
/// in slow organic paths.  The gradients use many stops with a very gradual
/// alpha falloff so no runtime blur pass is needed.
///
/// Uses [AuroraAnimator] singleton so all instances share one frame callback.
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

class _AuroraBackgroundState extends State<AuroraBackground> {
  @override
  void initState() {
    super.initState();
    AuroraAnimator.instance.addListener();
  }

  @override
  void dispose() {
    AuroraAnimator.instance.removeListener();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: ValueListenableBuilder<double>(
        valueListenable: AuroraAnimator.instance.progress,
        builder: (context, progress, _) {
          return CustomPaint(
            painter: _AuroraPainter(
              progress: progress,
              colors: widget.colors,
              speed: widget.speed,
              opacity: widget.opacity,
              blendMode: widget.blendMode,
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

/// Pre-computed blob color stops to avoid allocating Colors every frame.
class _BlobColors {
  final List<Color> stops; // 6 gradient stops

  _BlobColors(Color base, double opacity)
      : stops = [
          base.withValues(alpha: 0.35 * opacity),
          base.withValues(alpha: 0.25 * opacity),
          base.withValues(alpha: 0.15 * opacity),
          base.withValues(alpha: 0.08 * opacity),
          base.withValues(alpha: 0.02 * opacity),
          base.withValues(alpha: 0.0),
        ];
}

class _AuroraPainter extends CustomPainter {
  final double progress;
  final List<Color> colors;
  final double speed;
  final double opacity;
  final BlendMode blendMode;

  late final List<_BlobColors> _blobColors;

  _AuroraPainter({
    required this.progress,
    required this.colors,
    required this.speed,
    required this.opacity,
    required this.blendMode,
  }) {
    // Pre-compute gradient colors (bake opacity in)
    _blobColors = [
      _BlobColors(_colorAt(0), opacity),
      _BlobColors(_colorAt(1), opacity),
      _BlobColors(_colorAt(2), opacity),
    ];
  }

  static const _gradientStops = [0.0, 0.15, 0.30, 0.50, 0.75, 1.0];

  @override
  void paint(Canvas canvas, Size size) {
    final double t = progress * 2 * math.pi * speed;

    // Blob 0
    _drawBlob(
      canvas,
      size,
      cx: size.width * (0.25 + 0.20 * math.sin(t * 0.7)),
      cy: size.height * (0.18 + 0.15 * math.cos(t * 0.5)),
      radius: size.width * 0.85,
      colors: _blobColors[0],
    );

    // Blob 1
    _drawBlob(
      canvas,
      size,
      cx: size.width * (0.72 + 0.15 * math.cos(t * 0.6)),
      cy: size.height * (0.38 + 0.12 * math.sin(t * 0.8)),
      radius: size.width * 0.75,
      colors: _blobColors[1],
    );

    // Blob 2
    _drawBlob(
      canvas,
      size,
      cx: size.width * (0.50 + 0.22 * math.sin(t * 0.9 + 1.5)),
      cy: size.height * (0.65 + 0.14 * math.cos(t * 0.4)),
      radius: size.width * 0.80,
      colors: _blobColors[2],
    );
  }

  void _drawBlob(
    Canvas canvas,
    Size size, {
    required double cx,
    required double cy,
    required double radius,
    required _BlobColors colors,
  }) {
    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: radius);
    final paint = Paint()
      ..shader = RadialGradient(
        colors: colors.stops,
        stops: _gradientStops,
      ).createShader(rect)
      ..blendMode = blendMode;
    canvas.drawOval(rect, paint);
  }

  Color _colorAt(int index) =>
      index < colors.length ? colors[index] : colors[index % colors.length];

  @override
  bool shouldRepaint(covariant _AuroraPainter old) =>
      old.progress != progress;
}
