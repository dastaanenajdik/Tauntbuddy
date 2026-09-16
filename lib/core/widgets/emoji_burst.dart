import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Emoji confetti burst — the little dopamine hit every time the mascot is
/// tapped, a session finishes or a badge unlocks.
///
/// Implemented as a self-removing [OverlayEntry] so it can be fired from any
/// callback without adding a Stack to every screen.
class EmojiBurst {
  const EmojiBurst._();

  static const List<String> tauntEmojis = <String>['🦋', '🌸', '✨', '🌺', '🌷', '🦋', '🌼'];
  static const List<String> rewardEmojis = <String>['🎉', '🏅', '✨', '💜', '🔥', '⭐'];
  static const List<String> focusEmojis = <String>['⏳', '🎯', '⚡', '💜', '✨'];

  /// Fires [count] emojis outward from [globalPosition].
  ///
  /// [globalPosition] is normally obtained from
  /// `context.findRenderObject()` on a tap, or from the render box of a button.
  static void fire(
    BuildContext context,
    Offset globalPosition, {
    List<String> emojis = tauntEmojis,
    int count = 10,
    double spread = 190,
  }) {
    final OverlayState? overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (BuildContext context) => _BurstLayer(
        origin: globalPosition,
        emojis: emojis,
        count: count,
        spread: spread,
        onFinished: () {
          if (entry.mounted) entry.remove();
        },
      ),
    );
    overlay.insert(entry);
  }

  /// Convenience helper that centres the burst on a widget's own box.
  static void fireFrom(
    BuildContext context, {
    List<String> emojis = tauntEmojis,
    int count = 10,
  }) {
    final RenderObject? box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return;
    final Offset center = box.localToGlobal(box.size.center(Offset.zero));
    fire(context, center, emojis: emojis, count: count);
  }
}

class _BurstLayer extends StatefulWidget {
  const _BurstLayer({
    required this.origin,
    required this.emojis,
    required this.count,
    required this.spread,
    required this.onFinished,
  });

  final Offset origin;
  final List<String> emojis;
  final int count;
  final double spread;
  final VoidCallback onFinished;

  @override
  State<_BurstLayer> createState() => _BurstLayerState();
}

class _BurstLayerState extends State<_BurstLayer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1150),
  );
  late final List<_Particle> _particles = _buildParticles();

  List<_Particle> _buildParticles() {
    final math.Random random = math.Random();
    return List<_Particle>.generate(widget.count, (int i) {
      final double angle = (i / widget.count) * math.pi * 2 + random.nextDouble() * 0.6;
      final double distance = widget.spread * (0.45 + random.nextDouble() * 0.75);
      return _Particle(
        emoji: widget.emojis[random.nextInt(widget.emojis.length)],
        dx: math.cos(angle) * distance,
        dy: math.sin(angle) * distance - random.nextDouble() * 60,
        rotation: (random.nextDouble() - 0.5) * 3.4,
        scale: 0.7 + random.nextDouble() * 0.8,
        delay: random.nextDouble() * 0.18,
        size: 16 + random.nextDouble() * 14,
      );
    });
  }

  @override
  void initState() {
    super.initState();
    _controller.forward().whenComplete(widget.onFinished);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (BuildContext context, _) {
          return Stack(
            children: <Widget>[
              for (final _Particle p in _particles)
                Positioned(
                  left: widget.origin.dx - p.size / 2,
                  top: widget.origin.dy - p.size / 2,
                  child: Transform.translate(
                    offset: Offset(
                      p.dx * Curves.easeOutCubic.transform(_progressFor(p)),
                      p.dy * Curves.easeOutCubic.transform(_progressFor(p)),
                    ),
                    child: Transform.rotate(
                      angle: p.rotation * _progressFor(p),
                      child: Opacity(
                        opacity: (1 - _progressFor(p)).clamp(0, 1),
                        child: Transform.scale(
                          scale: p.scale * (0.4 + _progressFor(p) * 0.8),
                          child: Text(p.emoji, style: TextStyle(fontSize: p.size)),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  double _progressFor(_Particle p) {
    final double raw = (_controller.value - p.delay) / (1 - p.delay);
    return raw.clamp(0, 1);
  }
}

class _Particle {
  const _Particle({
    required this.emoji,
    required this.dx,
    required this.dy,
    required this.rotation,
    required this.scale,
    required this.delay,
    required this.size,
  });

  final String emoji;
  final double dx;
  final double dy;
  final double rotation;
  final double scale;
  final double delay;
  final double size;
}
