import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import 'ambient_background.dart';

/// Frosted glass panel — the primary building block of the TauntBuddy UI.
///
/// * heavy corner radius (28) matches the "heavily rounded cards" spec
/// * 1px hairline border + inner highlight sells the glass edge
/// * optional [glowColor] adds the electric violet halo on hero cards
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.margin = EdgeInsets.zero,
    this.radius = 28,
    this.glowColor,
    this.glowStrength = 0.16,
    this.borderColor,
    this.onTap,
    this.fillColor,
    this.blur = 18,
    this.width,
    this.height,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double radius;
  final Color? glowColor;
  final double glowStrength;
  final Color? borderColor;
  final VoidCallback? onTap;
  final Color? fillColor;
  final double blur;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final AppTokens t = context.tokens;
    final Color border = borderColor ?? t.glassBorder;
    final Color glow = (glowColor ?? t.primary).withValues(alpha: glowStrength);

    final Widget panel = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: fillColor ?? t.glassFill,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: border, width: 1),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                (fillColor ?? t.glassFill),
                Color.alphaBlend(t.glassHighlight, fillColor ?? t.glassFill),
              ],
            ),
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );

    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: (fillColor == null ? glow : glow.withValues(alpha: glowStrength * 0.5)),
            blurRadius: 26,
            spreadRadius: -6,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: t.shadow.withValues(alpha: t.isDark ? 0.55 : 0.18),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: onTap == null
          ? panel
          : Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(radius),
                splashColor: t.primary.withValues(alpha: 0.12),
                highlightColor: t.primary.withValues(alpha: 0.06),
                child: panel,
              ),
            ),
    );
  }
}

/// Small pill used for tags, streaks, moods and status labels.
class NeonChip extends StatelessWidget {
  const NeonChip({
    super.key,
    required this.label,
    this.icon,
    this.color,
    this.dense = false,
    this.onTap,
    this.emoji,
  });

  final String label;
  final IconData? icon;
  final Color? color;
  final bool dense;
  final VoidCallback? onTap;
  final String? emoji;

  @override
  Widget build(BuildContext context) {
    final AppTokens t = context.tokens;
    final Color c = color ?? t.primary;
    final Widget content = Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 9 : 12,
        vertical: dense ? 4.5 : 7,
      ),
      decoration: BoxDecoration(
        color: c.withValues(alpha: t.isDark ? 0.24 : 0.18),
        borderRadius: BorderRadius.circular(dense ? 10 : 14),
        border: Border.all(color: c.withValues(alpha: 0.78), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (emoji != null) ...<Widget>[
            Text(emoji!, style: TextStyle(fontSize: dense ? 11 : 13)),
            const SizedBox(width: 5),
          ],
          if (icon != null) ...<Widget>[
            Icon(icon, size: dense ? 12 : 14, color: c),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              color: t.isDark ? c : Color.alphaBlend(c.withValues(alpha: 0.88), t.textPrimary),
              fontSize: dense ? 10.5 : 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return content;
    return GestureDetector(onTap: onTap, child: content);
  }
}

/// "PRO" marker used by Exam Planner and other premium surfaces.
class ProBadge extends StatelessWidget {
  const ProBadge({super.key, this.label = 'PRO', this.locked = false});

  final String label;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final AppTokens t = context.tokens;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: t.brandGradient),
        borderRadius: BorderRadius.circular(8),
        boxShadow: <BoxShadow>[
          BoxShadow(color: t.primary.withValues(alpha: 0.5), blurRadius: 12, spreadRadius: -2),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(locked ? Icons.lock_rounded : Icons.workspace_premium_rounded, size: 11, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

/// Gradient headline text used for the brand and hero numbers.
class GradientText extends StatelessWidget {
  const GradientText(this.text, {super.key, this.style, this.gradient, this.textAlign});

  final String text;
  final TextStyle? style;
  final List<Color>? gradient;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final AppTokens t = context.tokens;
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (Rect bounds) => LinearGradient(
        colors: gradient ?? t.brandGradient,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(bounds),
      child: Text(
        text,
        textAlign: textAlign,
        style: (style ?? const TextStyle()).copyWith(color: Colors.white),
      ),
    );
  }
}

/// Ambient wrapper so pushed screens (search, exam details, anything outside
/// the shell chrome) keep the TauntBuddy canvas behind them.
class GlassScaffold extends StatelessWidget {
  const GlassScaffold({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AmbientBackground(child: SafeArea(child: child)),
    );
  }
}
