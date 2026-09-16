import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// Primary neon CTA. Gradient fill, violet bloom and a subtle press animation.
class GlowButton extends StatefulWidget {
  const GlowButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.expand = true,
    this.height = 52,
    this.gradient,
    this.busy = false,
    this.compact = false,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool expand;
  final double height;
  final List<Color>? gradient;
  final bool busy;
  final bool compact;

  @override
  State<GlowButton> createState() => _GlowButtonState();
}

class _GlowButtonState extends State<GlowButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final AppTokens t = context.tokens;
    final bool enabled = widget.onPressed != null && !widget.busy;
    final List<Color> colors = widget.gradient ?? t.brandGradient;

    final Widget core = AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      height: widget.compact ? 42 : widget.height,
      padding: EdgeInsets.symmetric(horizontal: widget.compact ? 16 : 22),
      transform: Matrix4.identity()..scale(_pressed ? 0.975 : 1.0),
      transformAlignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: enabled
              ? colors
              : <Color>[
                  t.accentGrey.withValues(alpha: 0.5),
                  t.accentGrey.withValues(alpha: 0.35),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(widget.compact ? 14 : 18),
        boxShadow: enabled
            ? <BoxShadow>[
                BoxShadow(
                  color: colors.first.withValues(alpha: 0.45),
                  blurRadius: 22,
                  spreadRadius: -4,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          if (widget.busy)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          else if (widget.icon != null)
            Icon(widget.icon, color: Colors.white, size: widget.compact ? 16 : 19),
          if (widget.busy || widget.icon != null) const SizedBox(width: 9),
          Text(
            widget.label,
            style: TextStyle(
              color: Colors.white,
              fontSize: widget.compact ? 12.5 : 14.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );

    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
      onTapUp: enabled
          ? (_) {
              setState(() => _pressed = false);
              widget.onPressed?.call();
            }
          : null,
      child: widget.expand ? SizedBox(width: double.infinity, child: core) : core,
    );
  }
}

/// Secondary action: transparent with a hairline neon border.
class GhostButton extends StatelessWidget {
  const GhostButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.color,
    this.expand = false,
    this.compact = true,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final Color? color;
  final bool expand;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final AppTokens t = context.tokens;
    final Color c = color ?? t.textPrimary;
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: compact ? 40 : 50,
        padding: EdgeInsets.symmetric(horizontal: compact ? 14 : 20),
        width: expand ? double.infinity : null,
        decoration: BoxDecoration(
          color: c.withValues(alpha: t.isDark ? 0.06 : 0.04),
          borderRadius: BorderRadius.circular(compact ? 13 : 16),
          border: Border.all(color: c.withValues(alpha: 0.28)),
        ),
        child: Row(
          mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (icon != null) ...<Widget>[
              Icon(icon, size: compact ? 15 : 18, color: c),
              const SizedBox(width: 7),
            ],
            Text(
              label,
              style: TextStyle(
                color: c,
                fontWeight: FontWeight.w700,
                fontSize: compact ? 12.5 : 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Rounded section title with an optional trailing action.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.icon,
    this.accent,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final IconData? icon;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final AppTokens t = context.tokens;
    final Color c = accent ?? t.primary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          if (icon != null)
            Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: c.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: c.withValues(alpha: 0.3)),
              ),
              child: Icon(icon, size: 15, color: c),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: t.textPrimary == null
                      ? null
                      : Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: t.textPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                ),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      subtitle!,
                      style: TextStyle(color: t.textMuted, fontSize: 12, height: 1.35),
                    ),
                  ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Compact metric tile used in dashboards and analytics summaries.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.accent,
    this.caption,
    this.onTap,
  });

  final String label;
  final String value;
  final IconData? icon;
  final Color? accent;
  final String? caption;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final AppTokens t = context.tokens;
    final Color c = accent ?? t.primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: c.withValues(alpha: t.isDark ? 0.09 : 0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: c.withValues(alpha: 0.24)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              children: <Widget>[
                if (icon != null) ...<Widget>[
                  Icon(icon, size: 14, color: c),
                  const SizedBox(width: 6),
                ],
                Expanded(
                  child: Text(
                    label.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: t.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            Text(
              value,
              style: TextStyle(
                color: t.textPrimary,
                fontSize: 21,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),
            if (caption != null)
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Text(
                  caption!,
                  style: TextStyle(color: t.textMuted, fontSize: 11),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Circular progress ring with a gradient sweep — used for streaks,
/// completion rates and the focus depth score.
class MetricRing extends StatelessWidget {
  const MetricRing({
    super.key,
    required this.progress,
    required this.value,
    this.label,
    this.size = 96,
    this.stroke = 9,
    this.colors,
  });

  final double progress;
  final String value;
  final String? label;
  final double size;
  final double stroke;
  final List<Color>? colors;

  @override
  Widget build(BuildContext context) {
    final AppTokens t = context.tokens;
    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: progress.clamp(0, 1)),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic,
        builder: (BuildContext context, double value, _) {
          return CustomPaint(
            painter: _RingPainter(
              progress: value,
              colors: colors ?? <Color>[t.accentViolet, t.accentMagenta],
              track: t.glassBorder,
              stroke: stroke,
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    value == 0 ? '0' : this.value,
                    style: TextStyle(
                      color: t.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: size * 0.24,
                    ),
                  ),
                  if (label != null)
                    Text(
                      label!,
                      style: TextStyle(
                        color: t.textMuted,
                        fontSize: size * 0.11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.colors,
    required this.track,
    required this.stroke,
  });

  final double progress;
  final List<Color> colors;
  final Color track;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    final Offset center = rect.center;
    final double radius = (size.shortestSide - stroke) / 2;
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = track,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = stroke
        ..shader = SweepGradient(colors: colors, startAngle: 0, endAngle: math.pi * 2)
            .createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress || old.colors != colors || old.stroke != stroke;
}

/// Slim animated progress bar.
class NeonProgressBar extends StatelessWidget {
  const NeonProgressBar({
    super.key,
    required this.progress,
    this.height = 7,
    this.colors,
    this.track,
  });

  final double progress;
  final double height;
  final List<Color>? colors;
  final Color? track;

  @override
  Widget build(BuildContext context) {
    final AppTokens t = context.tokens;
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: progress.clamp(0, 1)),
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeOutCubic,
        builder: (BuildContext context, double value, _) {
          return Container(
            height: height,
            color: track ?? t.glassBorder,
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: value == 0 ? 0.001 : value,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: colors ?? t.brandGradient),
                  borderRadius: BorderRadius.circular(height),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: (colors ?? t.brandGradient).first.withValues(alpha: 0.5),
                      blurRadius: 10,
                      spreadRadius: -2,
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

/// Vertical bar chart for focus minutes / completion trends.
class MiniBarChart extends StatelessWidget {
  const MiniBarChart({
    super.key,
    required this.values,
    required this.labels,
    this.height = 130,
    this.colors,
    this.valueFormatter,
  });

  final List<double> values;
  final List<String> labels;
  final double height;
  final List<Color>? colors;
  final String Function(double)? valueFormatter;

  @override
  Widget build(BuildContext context) {
    final AppTokens t = context.tokens;
    final double maxValue = values.isEmpty
        ? 1
        : values.reduce((double a, double b) => a > b ? a : b).clamp(1, double.infinity);

    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          for (int i = 0; i < values.length; i++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2.5),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: values[i] / maxValue),
                      duration: Duration(milliseconds: 500 + i * 60),
                      curve: Curves.easeOutCubic,
                      builder: (BuildContext context, double factor, _) {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            if (factor > 0.35 && valueFormatter != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text(
                                  valueFormatter!(values[i]),
                                  style: TextStyle(color: t.textMuted, fontSize: 9),
                                ),
                              ),
                            Container(
                              height: (height - 34) * factor,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: colors ?? <Color>[t.accentViolet, t.accentMagenta],
                                ),
                                borderRadius: BorderRadius.circular(7),
                                boxShadow: factor > 0.05
                                    ? <BoxShadow>[
                                        BoxShadow(
                                          color: (colors ?? <Color>[t.accentViolet]).first
                                              .withValues(alpha: 0.35),
                                          blurRadius: 10,
                                          spreadRadius: -3,
                                        ),
                                      ]
                                    : null,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 6),
                    Text(
                      i < labels.length ? labels[i] : '',
                      style: TextStyle(color: t.textMuted, fontSize: 9.5, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Friendly illustrated empty state with the mascot's judgemental face.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.auto_awesome_rounded,
    this.accent,
    this.action,
  });

  final String title;
  final String message;
  final IconData icon;
  final Color? accent;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final AppTokens t = context.tokens;
    final Color c = accent ?? t.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: c.withValues(alpha: 0.12),
              border: Border.all(color: c.withValues(alpha: 0.3)),
            ),
            child: Icon(icon, size: 30, color: c),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(color: t.textPrimary, fontSize: 16.5, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: t.textMuted, fontSize: 13, height: 1.5),
          ),
          if (action != null) ...<Widget>[const SizedBox(height: 20), action!],
        ],
      ),
    );
  }
}

/// Hairline gradient divider used between dashboard modules.
class NeonDivider extends StatelessWidget {
  const NeonDivider({super.key, this.height = 1, this.opacity = 0.18});

  final double height;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final AppTokens t = context.tokens;
    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[
            Colors.transparent,
            t.primary.withValues(alpha: opacity),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}

/// Three-dot "the hamster is typing a taunt" loader.
class TauntLoader extends StatefulWidget {
  const TauntLoader({super.key, this.color, this.size = 7});

  final Color? color;
  final double size;

  @override
  State<TauntLoader> createState() => _TauntLoaderState();
}

class _TauntLoaderState extends State<TauntLoader> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color c = widget.color ?? context.tokens.primary;
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            for (int i = 0; i < 3; i++)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: widget.size * 0.22),
                child: Transform.translate(
                  offset: Offset(
                    0,
                    -math.sin((_controller.value * math.pi * 2) + i * 0.7) * widget.size * 0.55,
                  ),
                  child: Container(
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(color: c, shape: BoxShape.circle),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
