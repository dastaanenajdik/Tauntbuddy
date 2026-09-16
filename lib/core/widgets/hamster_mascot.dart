import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// Every mood the brand mascot can express. The pose changes eyes, ears, mouth
/// and the accessory the hamster is holding — this is the app's living logo.
enum MascotPose {
  idle,
  judging,
  focus,
  celebrate,
  sleepy,
  shield,
  thinking,
}

/// The animated TauntBuddy hamster: the app's dynamic brand identity.
///
/// Rendered fully in code (no image assets, so it stays razor sharp from a
/// 24px launcher icon to a 320px onboarding hero) with three layered
/// animations:
///
/// 1. idle float + breathe (slow sine)
/// 2. eye blink on a randomised timer
/// 3. pose transitions (interpolated, so switches never "pop")
///
/// [HamsterMascot] also drives the launcher/app icon artwork through
/// `tools/generate_branding_assets.dart`, keeping icon and in-app mascot
/// pixel-identical.
class HamsterMascot extends StatefulWidget {
  const HamsterMascot({
    super.key,
    this.size = 180,
    this.pose = MascotPose.idle,
    this.animate = true,
    this.showGlow = true,
    this.showShell = true,
    this.onTap,
    this.glowColor,
    this.semanticLabel = 'TauntBuddy hamster mascot',
  });

  final double size;
  final MascotPose pose;
  final bool animate;
  final bool showGlow;

  /// The cracked eggshell the hamster sits in. Disabled for the compact
  /// avatar/icon rendering.
  final bool showShell;
  final VoidCallback? onTap;
  final Color? glowColor;
  final String semanticLabel;

  @override
  State<HamsterMascot> createState() => _HamsterMascotState();
}

class _HamsterMascotState extends State<HamsterMascot> with TickerProviderStateMixin {
  late final AnimationController _breathe = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );
  late final AnimationController _blink = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 180),
  );
  late final AnimationController _poseMix = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
    value: 1,
  );

  MascotPose _from = MascotPose.idle;
  MascotPose _current = MascotPose.idle;
  bool _squash = false;

  @override
  void initState() {
    super.initState();
    _current = widget.pose;
    _from = widget.pose;
    if (widget.animate) {
      _breathe.repeat(reverse: true);
      _scheduleBlink();
    }
  }

  @override
  void didUpdateWidget(covariant HamsterMascot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pose != widget.pose) {
      _from = _current;
      _current = widget.pose;
      _poseMix.forward(from: 0);
    }
    if (oldWidget.animate != widget.animate) {
      if (widget.animate) {
        _breathe.repeat(reverse: true);
        _scheduleBlink();
      } else {
        _breathe.stop();
      }
    }
  }

  void _scheduleBlink() {
    Future<void>.delayed(Duration(milliseconds: 1800 + math.Random().nextInt(2600)), () {
      if (!mounted || !widget.animate) return;
      _blink.forward(from: 0).then((_) {
        if (!mounted) return;
        _blink.reverse();
        _scheduleBlink();
      });
    });
  }

  void _handleTap() {
    widget.onTap?.call();
    setState(() => _squash = true);
    Future<void>.delayed(const Duration(milliseconds: 140), () {
      if (mounted) setState(() => _squash = false);
    });
  }

  @override
  void dispose() {
    _breathe.dispose();
    _blink.dispose();
    _poseMix.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppTokens t = context.tokens;
    final Color glow = widget.glowColor ?? t.glow;

    return Semantics(
      label: widget.semanticLabel,
      button: widget.onTap != null,
      child: GestureDetector(
        onTap: widget.onTap == null ? null : _handleTap,
        child: AnimatedBuilder(
          animation: Listenable.merge(<Listenable>[_breathe, _blink, _poseMix]),
          builder: (BuildContext context, _) {
            final double breathe = _breathe.value;
            final double scale = _squash ? 0.94 : 1 + (breathe * 0.014);
            return Transform.scale(
              scale: scale,
              child: CustomPaint(
                size: Size.square(widget.size),
                painter: _HamsterPainter(
                  tokens: t,
                  breathe: breathe,
                  blink: _blink.value,
                  pose: _current,
                  previous: _from,
                  mix: Curves.easeOutCubic.transform(_poseMix.value),
                  showShell: widget.showShell,
                  showGlow: widget.showGlow,
                  glow: glow,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _HamsterPainter extends CustomPainter {
  _HamsterPainter({
    required this.tokens,
    required this.breathe,
    required this.blink,
    required this.pose,
    required this.previous,
    required this.mix,
    required this.showShell,
    required this.showGlow,
    required this.glow,
  });

  final AppTokens tokens;
  final double breathe;
  final double blink;
  final MascotPose pose;
  final MascotPose previous;
  final double mix;
  final bool showShell;
  final bool showGlow;
  final Color glow;

  /// Linearly mixes 0→1 pose flags so the mascot morphs instead of cutting.
  double _flag(
    bool Function(MascotPose) predicate, {
    double from = 0,
    double to = 1,
  }) {
    final double a = predicate(previous) ? to : from;
    final double b = predicate(pose) ? to : from;
    return a + (b - a) * mix;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final double s = size.width;
    final double u = s / 100; // layout unit
    final Offset center = Offset(s / 2, s / 2);

    final double float = showShell ? math.sin(breathe * math.pi) * 1.6 * u : 0;
    canvas.save();
    canvas.translate(0, float);

    if (showGlow) _paintGlow(canvas, center, u);

    final double headWidth = 62 * u;
    final double headHeight = 56 * u;
    final double headCenterY = (showShell ? 40 : 52) * u;
    final Offset headCenter = Offset(center.dx, headCenterY);

    final double judging = _flag((MascotPose p) => p == MascotPose.judging);
    final double focus = _flag((MascotPose p) => p == MascotPose.focus);
    final double sleepy = _flag((MascotPose p) => p == MascotPose.sleepy);
    final double cheer = _flag((MascotPose p) => p == MascotPose.celebrate);
    final double shield = _flag((MascotPose p) => p == MascotPose.shield);
    final double thinking = _flag((MascotPose p) => p == MascotPose.thinking);

    _paintEars(canvas, headCenter, headWidth, headHeight, u, judging, sleepy);
    _paintHead(canvas, headCenter, headWidth, headHeight, u, judging, focus);
    _paintCheeks(canvas, headCenter, headWidth, headHeight, u, cheer, shield);
    _paintEyes(canvas, headCenter, headWidth, headHeight, u, judging, sleepy, focus, cheer);
    _paintNoseAndMouth(canvas, headCenter, headHeight, u, judging, sleepy, cheer, focus);
    if (showShell) {
      _paintPaws(canvas, headCenter, u, cheer, thinking);
      _paintShell(canvas, center, s, u);
    }
    _paintCap(canvas, headCenter, headWidth, u, judging, cheer);
    _paintAccessory(canvas, headCenter, u, shield, focus, cheer, thinking, sleepy);

    canvas.restore();
  }

  void _paintGlow(Canvas canvas, Offset center, double u) {
    final double radius = 46 * u;
    final Paint glowPaint = Paint()
      ..shader = RadialGradient(
        colors: <Color>[
          glow.withValues(alpha: tokens.isDark ? 0.45 : 0.28),
          glow.withValues(alpha: 0.12),
          Colors.transparent,
        ],
        stops: const <double>[0, 0.55, 1],
      ).createShader(Rect.fromCircle(center: center, radius: radius + 12 * u));
    canvas.drawCircle(center, radius + 12 * u, glowPaint);

    final Paint ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1 * u
      ..color = glow.withValues(alpha: 0.35);
    canvas.drawCircle(center, radius + (breathe * 3 * u), ring);
  }

  void _paintEars(
    Canvas canvas,
    Offset head,
    double w,
    double h,
    double u,
    double judging,
    double sleepy,
  ) {
    final Color fur = tokens.isDark ? const Color(0xFFE8B07A) : const Color(0xFFE8A96B);
    final Color inner = const Color(0xFFF87C9A);
    final Paint stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4 * u
      ..color = const Color(0xFF2A1A2E);
    final double size = 15 * u;
    final double droop = sleepy * 4 * u;
    final double lift = judging * 2.2 * u;

    for (final int side in <int>[-1, 1]) {
      final Offset c = Offset(
        head.dx + side * (w / 2 - 3 * u),
        head.dy - h / 2 + size * 0.55 + droop - lift * (side == 1 ? 1 : 0),
      );
      canvas.drawCircle(c, size, Paint()..color = fur);
      canvas.drawCircle(c, size, stroke);
      canvas.drawCircle(
        c.translate(side * 0.5 * u, 0.5 * u),
        size * 0.5,
        Paint()..color = inner.withValues(alpha: 0.9),
      );
    }
  }

  void _paintHead(
    Canvas canvas,
    Offset head,
    double w,
    double h,
    double u,
    double judging,
    double focus,
  ) {
    final Color furTop = tokens.isDark ? const Color(0xFFF3C08A) : const Color(0xFFF6C795);
    final Color furBottom = tokens.isDark ? const Color(0xFFD08B45) : const Color(0xFFD98E48);
    final Rect rect = Rect.fromCenter(
      center: head.translate((judging * 1.5 - focus * 0.5) * u, 0),
      width: w,
      height: h,
    );
    final RRect body = RRect.fromRectAndCorners(
      rect,
      topLeft: Radius.circular(30 * u),
      topRight: Radius.circular(30 * u),
      bottomLeft: Radius.circular(26 * u),
      bottomRight: Radius.circular(26 * u),
    );

    canvas.drawRRect(
      body,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[furTop, furBottom],
        ).createShader(rect),
    );

    // Muzzle / cheek patch keeps the face readable at small sizes.
    final Path muzzle = Path()
      ..addOval(
        Rect.fromCenter(
          center: head.translate(0, h * 0.16),
          width: w * 0.78,
          height: h * 0.52,
        ),
      );
    canvas.drawPath(muzzle, Paint()..color = const Color(0xFFFFF6EA));

    canvas.drawRRect(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6 * u
        ..color = const Color(0xFF2A1A2E),
    );
  }

  void _paintCheeks(
    Canvas canvas,
    Offset head,
    double w,
    double h,
    double u,
    double cheer,
    double shield,
  ) {
    final double alpha = 0.42 + cheer * 0.3 + shield * 0.1;
    final Paint blush = Paint()..color = const Color(0xFFF7757F).withValues(alpha: alpha);
    for (final int side in <int>[-1, 1]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: head.translate(side * w * 0.3, h * 0.2),
          width: 13 * u,
          height: 7.5 * u,
        ),
        blush,
      );
    }
  }

  void _paintEyes(
    Canvas canvas,
    Offset head,
    double w,
    double h,
    double u,
    double judging,
    double sleepy,
    double focus,
    double cheer,
  ) {
    final double openness = (1 - blink).clamp(0, 1) * (1 - sleepy * 0.85);
    final Paint dark = Paint()..color = const Color(0xFF241329);
    final Paint white = Paint()..color = Colors.white.withValues(alpha: 0.95);
    final double eyeY = head.dy - h * 0.04;
    final double eyeX = w * 0.21;

    for (final int side in <int>[-1, 1]) {
      final Offset c = Offset(head.dx + side * eyeX, eyeY);
      final double ew = (7.4 - focus * 0.6) * u;
      final double eh = (8.6 * openness + 1.1) * u;

      if (cheer > 0.5) {
        // Happy closed-arc eyes (^^) while celebrating.
        final Path arc = Path()
          ..moveTo(c.dx - ew, c.dy + 1.5 * u)
          ..quadraticBezierTo(c.dx, c.dy - 5 * u, c.dx + ew, c.dy + 1.5 * u);
        canvas.drawPath(
          arc,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeWidth = 2.4 * u
            ..color = const Color(0xFF241329),
        );
      } else {
        canvas.drawOval(
          Rect.fromCenter(center: c, width: ew * 2, height: eh * 2),
          dark,
        );
        // Catch-light: top-right sparkle keeps the mascot friendly.
        canvas.drawCircle(
          c.translate(1.6 * u, -2.2 * u * openness),
          1.5 * u,
          white,
        );
      }

      if (judging > 0.25) {
        // Slanted judge-brow, the app's "I saw that" face.
        final Path brow = Path()
          ..moveTo(c.dx - 6 * u, c.dy - (9 + side * 1.4) * u)
          ..lineTo(c.dx + 6 * u, c.dy - (7 - side * 1.4) * u);
        canvas.drawPath(
          brow,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeWidth = 2.1 * u
            ..color = const Color(0xFF2A1A2E),
        );
      }

      // Whiskers.
      for (int i = 0; i < 2; i++) {
        final double dy = (2 + i * 4) * u;
        canvas.drawLine(
          Offset(c.dx + side * 12 * u, c.dy + dy),
          Offset(c.dx + side * 22 * u, c.dy + dy - 2 * u),
          Paint()
            ..strokeWidth = 1.1 * u
            ..strokeCap = StrokeCap.round
            ..color = const Color(0xFF2A1A2E).withValues(alpha: 0.55),
        );
      }
    }
  }

  void _paintNoseAndMouth(
    Canvas canvas,
    Offset head,
    double h,
    double u,
    double judging,
    double sleepy,
    double cheer,
    double focus,
  ) {
    final Offset nose = head.translate(0, h * 0.13);
    final Path nosePath = Path()
      ..moveTo(nose.dx - 4 * u, nose.dy - 2.4 * u)
      ..lineTo(nose.dx + 4 * u, nose.dy - 2.4 * u)
      ..quadraticBezierTo(nose.dx + 2 * u, nose.dy + 3 * u, nose.dx, nose.dy + 3.4 * u)
      ..quadraticBezierTo(nose.dx - 2 * u, nose.dy + 3 * u, nose.dx - 4 * u, nose.dy - 2.4 * u)
      ..close();
    canvas.drawPath(nosePath, Paint()..color = const Color(0xFFE85C7A));

    final Paint mouthPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.8 * u
      ..color = const Color(0xFF2A1A2E);

    final double openMouth = cheer;
    if (openMouth > 0.15) {
      canvas.drawOval(
        Rect.fromCenter(
          center: nose.translate(0, 6.5 * u),
          width: (9 + openMouth * 3) * u,
          height: (7 + openMouth * 4) * u,
        ),
        Paint()..color = const Color(0xFF5C2233),
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: nose.translate(0, 9 * u),
          width: 5 * u,
          height: 3 * u,
        ),
        Paint()..color = const Color(0xFFF7757F),
      );
      return;
    }

    final double droop = 1 - sleepy;
    final double smirk = judging;
    final Path mouth = Path()
      ..moveTo(nose.dx - 1, nose.dy + 4 * u)
      ..quadraticBezierTo(
        nose.dx - 5 * u,
        nose.dy + (9 * droop) * u + smirk * 1.2 * u,
        nose.dx - 9 * u,
        nose.dy + (5 * droop) * u - smirk * 2.4 * u + focus * 1.2 * u,
      )
      ..moveTo(nose.dx + 1, nose.dy + 4 * u)
      ..quadraticBezierTo(
        nose.dx + 5 * u,
        nose.dy + (9 * droop) * u + smirk * 1.2 * u,
        nose.dx + 9 * u,
        nose.dy + (5 * droop) * u - smirk * 2.4 * u + focus * 1.2 * u,
      );
    canvas.drawPath(mouth, mouthPaint);
  }

  void _paintPaws(
    Canvas canvas,
    Offset head,
    double u,
    double cheer,
    double thinking,
  ) {
    final Paint fur = Paint()..color = const Color(0xFFF0BB86);
    final Paint stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2 * u
      ..color = const Color(0xFF2A1A2E);

    final double lift = cheer * 8 * u;
    final Rect left = Rect.fromCenter(
      center: Offset(head.dx - 20 * u, head.dy + 34 * u - lift),
      width: 15 * u,
      height: 10 * u,
    );
    final Rect right = Rect.fromCenter(
      center: Offset(head.dx + 20 * u, head.dy + 34 * u - lift * 1.6 - thinking * 6 * u),
      width: 15 * u,
      height: 10 * u,
    );
    canvas.drawRRect(RRect.fromRectAndRadius(left, Radius.circular(6 * u)), fur);
    canvas.drawRRect(RRect.fromRectAndRadius(left, Radius.circular(6 * u)), stroke);
    canvas.drawRRect(RRect.fromRectAndRadius(right, Radius.circular(6 * u)), fur);
    canvas.drawRRect(RRect.fromRectAndRadius(right, Radius.circular(6 * u)), stroke);
  }

  void _paintShell(Canvas canvas, Offset center, double s, double u) {
    final double w = 78 * u;
    final double h = 42 * u;
    final Rect rect = Rect.fromCenter(
      center: Offset(center.dx, center.dy + 24 * u),
      width: w,
      height: h,
    );
    final Path shell = Path()
      ..moveTo(rect.left, rect.top + 6 * u)
      ..lineTo(rect.left + 9 * u, rect.top)
      ..lineTo(rect.left + 19 * u, rect.top + 7 * u)
      ..lineTo(rect.left + 29 * u, rect.top)
      ..lineTo(rect.left + 39 * u, rect.top + 7 * u)
      ..lineTo(rect.left + 49 * u, rect.top)
      ..lineTo(rect.left + 59 * u, rect.top + 7 * u)
      ..lineTo(rect.left + 69 * u, rect.top)
      ..lineTo(rect.right, rect.top + 6 * u)
      ..cubicTo(rect.right, rect.bottom - 6 * u, rect.center.dx + w * 0.28, rect.bottom, rect.center.dx, rect.bottom)
      ..cubicTo(rect.center.dx - w * 0.28, rect.bottom, rect.left, rect.bottom - 6 * u, rect.left, rect.top + 6 * u)
      ..close();

    canvas.drawPath(
      shell,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: tokens.isDark
              ? const <Color>[Color(0xFF3A3350), Color(0xFF241E36)]
              : const <Color>[Color(0xFFFFFFFF), Color(0xFFEDE6FB)],
        ).createShader(rect),
    );
    canvas.drawPath(
      shell,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = 2.4 * u
        ..color = const Color(0xFF2A1A2E),
    );
  }

  void _paintCap(
    Canvas canvas,
    Offset head,
    double w,
    double u,
    double judging,
    double cheer,
  ) {
    final double tilt = -0.12 + judging * 0.06 + cheer * -0.1;
    final double boardW = 34 * u;
    final Offset boardCenter = Offset(head.dx, head.dy - 27 * u);

    canvas.save();
    canvas.translate(boardCenter.dx, boardCenter.dy);
    canvas.rotate(tilt);
    canvas.translate(-boardCenter.dx, -boardCenter.dy);

    final Paint ink = Paint()..color = const Color(0xFF161221);
    final Rect board = Rect.fromCenter(
      center: boardCenter,
      width: boardW * 2,
      height: boardW * 0.62,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(board, Radius.circular(3.4 * u)),
      ink,
    );
    // Band + button in the brand violet.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: boardCenter.translate(0, 5 * u),
          width: boardW * 0.62,
          height: 7.5 * u,
        ),
        Radius.circular(2.4 * u),
      ),
      Paint()..color = const Color(0xFF1E1830),
    );
    canvas.drawCircle(boardCenter, 2.1 * u, Paint()..color = tokens.accentAmber);

    // Tassel swings independently so the cap always feels alive.
    final double swing = math.sin(breathe * math.pi * 2) * 0.22;
    canvas.save();
    canvas.translate(boardCenter.dx + boardW, boardCenter.dy);
    canvas.rotate(swing);
    canvas.drawLine(
      Offset.zero,
      Offset(0, 10 * u),
      Paint()
        ..strokeWidth = 1.4 * u
        ..color = tokens.accentAmber,
    );
    canvas.drawCircle(
      Offset(0, 11.6 * u),
      2.4 * u,
      Paint()..color = tokens.accentAmber,
    );
    canvas.restore();
    canvas.restore();
  }

  void _paintAccessory(
    Canvas canvas,
    Offset head,
    double u,
    double shield,
    double focus,
    double cheer,
    double thinking,
    double sleepy,
  ) {
    final double alpha = math.max(
      math.max(shield, focus),
      math.max(cheer * 0.9, math.max(thinking * 0.8, sleepy * 0.7)),
    );
    if (alpha < 0.06) return;

    final Offset anchor = Offset(head.dx + 30 * u, head.dy + 26 * u);
    canvas.save();
    canvas.translate(anchor.dx, anchor.dy);
    canvas.scale(alpha);
    canvas.rotate(math.sin(breathe * math.pi) * 0.08);

    if (shield > 0.05) {
      final Path shieldPath = Path()
        ..moveTo(0, -9 * u)
        ..lineTo(8 * u, -5 * u)
        ..lineTo(8 * u, 3 * u)
        ..quadraticBezierTo(8 * u, 9 * u, 0, 12 * u)
        ..quadraticBezierTo(-8 * u, 9 * u, -8 * u, 3 * u)
        ..lineTo(-8 * u, -5 * u)
        ..close();
      canvas.drawPath(
        shieldPath,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[tokens.accentCyan, tokens.accentViolet],
          ).createShader(Rect.fromCircle(center: Offset.zero, radius: 12 * u)),
      );
      canvas.drawCircle(Offset.zero, 2.6 * u, Paint()..color = Colors.white.withValues(alpha: 0.92));
    } else if (focus > 0.05) {
      canvas.drawCircle(Offset.zero, 9 * u, Paint()..color = tokens.accentViolet.withValues(alpha: 0.22));
      canvas.drawCircle(
        Offset.zero,
        9 * u,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8 * u
          ..color = tokens.accentViolet,
      );
      canvas.drawLine(
        Offset.zero,
        Offset(0, -5 * u),
        Paint()
          ..strokeWidth = 1.6 * u
          ..strokeCap = StrokeCap.round
          ..color = Colors.white,
      );
      canvas.drawLine(
        Offset.zero,
        Offset(4 * u, 2 * u),
        Paint()
          ..strokeWidth = 1.6 * u
          ..strokeCap = StrokeCap.round
          ..color = Colors.white,
      );
    } else if (cheer > 0.05) {
      _paintStar(canvas, Offset.zero, 9 * u, tokens.accentAmber);
    } else if (thinking > 0.05) {
      canvas.drawCircle(Offset.zero, 8 * u, Paint()..color = tokens.accentCyan.withValues(alpha: 0.2));
      canvas.drawCircle(
        Offset.zero,
        8 * u,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6 * u
          ..color = tokens.accentCyan,
      );
    } else {
      // Sleepy: a tiny floating "z".
      canvas.drawCircle(Offset(-2 * u, 0), 7 * u, Paint()..color = tokens.accentAmber.withValues(alpha: 0.22));
      canvas.drawCircle(
        Offset(-2 * u, 0),
        7 * u,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5 * u
          ..color = tokens.accentAmber,
      );
    }
    canvas.restore();
  }

  void _paintStar(Canvas canvas, Offset c, double r, Color color) {
    final Path star = Path();
    for (int i = 0; i < 10; i++) {
      final double radius = i.isEven ? r : r * 0.45;
      final double angle = -math.pi / 2 + i * math.pi / 5;
      final Offset p = Offset(c.dx + radius * math.cos(angle), c.dy + radius * math.sin(angle));
      if (i == 0) {
        star.moveTo(p.dx, p.dy);
      } else {
        star.lineTo(p.dx, p.dy);
      }
    }
    star.close();
    canvas.drawPath(star, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _HamsterPainter old) =>
      old.breathe != breathe ||
      old.blink != blink ||
      old.pose != pose ||
      old.mix != mix ||
      old.tokens != tokens ||
      old.showShell != showShell ||
      old.showGlow != showGlow;
}
