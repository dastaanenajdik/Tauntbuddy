import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// The TauntBuddy canvas: a deep gradient with two slowly drifting neon blooms
/// and a faint technical grid.
///
/// It is deliberately GPU-cheap (two gradient circles + one painted grid) so it
/// can sit behind every screen — including the web build — without dropping
/// frames on mid-range phones.
class AmbientBackground extends StatefulWidget {
  const AmbientBackground({
    super.key,
    required this.child,
    this.showGrid = true,
    this.intensity = 1,
    this.animate = true,
  });

  final Widget child;
  final bool showGrid;
  final double intensity;
  final bool animate;

  @override
  State<AmbientBackground> createState() => _AmbientBackgroundState();
}

class _AmbientBackgroundState extends State<AmbientBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _drift = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 18),
  );

  @override
  void initState() {
    super.initState();
    if (widget.animate) _drift.repeat(reverse: true);
  }

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppTokens t = context.tokens;
    final List<Color> gradient = t.backgroundGradient;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          if (widget.showGrid)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(painter: _GridPainter(color: t.gridLine)),
              ),
            ),
          AnimatedBuilder(
            animation: _drift,
            builder: (BuildContext context, Widget? child) {
              final double v = widget.animate ? _drift.value : 0.35;
              return Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  Align(
                    alignment: Alignment(
                      -0.85 + v * 0.35,
                      -0.9 + math.sin(v * math.pi) * 0.25,
                    ),
                    child: _Bloom(
                      color: t.accentViolet,
                      size: 340,
                      opacity: (t.isDark ? 0.34 : 0.22) * widget.intensity,
                    ),
                  ),
                  Align(
                    alignment: Alignment(
                      0.9 - v * 0.3,
                      0.85 - math.cos(v * math.pi) * 0.2,
                    ),
                    child: _Bloom(
                      color: t.accentCyan,
                      size: 300,
                      opacity: (t.isDark ? 0.22 : 0.16) * widget.intensity,
                    ),
                  ),
                  Align(
                    alignment: Alignment(
                      math.sin(v * math.pi) * 0.4,
                      0.35,
                    ),
                    child: _Bloom(
                      color: t.accentMagenta,
                      size: 220,
                      opacity: (t.isDark ? 0.14 : 0.1) * widget.intensity,
                    ),
                  ),
                ],
              );
            },
          ),
          widget.child,
        ],
      ),
    );
  }
}

class _Bloom extends StatelessWidget {
  const _Bloom({required this.color, required this.size, required this.opacity});

  final Color color;
  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: <Color>[
              color.withValues(alpha: opacity),
              color.withValues(alpha: opacity * 0.35),
              Colors.transparent,
            ],
            stops: const <double>[0, 0.5, 1],
          ),
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  _GridPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const double step = 44;
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = 0.6;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter old) => old.color != color;
}
