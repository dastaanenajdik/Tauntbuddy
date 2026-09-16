import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import 'glass.dart';

/// Glassy text field used across onboarding, auth, planner, taunts and settings.
///
/// Keeps the neon language consistent: frosted panel, hairline border, and a
/// glow that turns red when validation fails.
class GlassField extends StatelessWidget {
  const GlassField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.error,
    this.obscure = false,
    this.keyboardType,
    this.maxLines = 1,
    this.onSubmitted,
    this.onChanged,
    this.suffix,
    this.prefixIcon,
    this.enabled = true,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final String? error;
  final bool obscure;
  final TextInputType? keyboardType;
  final int maxLines;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final Widget? suffix;
  final IconData? prefixIcon;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final AppTokens t = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: t.textMuted,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 6),
        GlassCard(
          radius: 16,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          glowColor: error == null ? t.primary : t.danger,
          glowStrength: error == null ? 0.1 : 0.35,
          child: Row(
            children: <Widget>[
              if (prefixIcon != null) ...<Widget>[
                Icon(prefixIcon, size: 16, color: t.textMuted),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: TextField(
                  controller: controller,
                  enabled: enabled,
                  obscureText: obscure,
                  keyboardType: keyboardType,
                  maxLines: obscure ? 1 : maxLines,
                  onSubmitted: onSubmitted,
                  onChanged: onChanged,
                  style: TextStyle(color: t.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    hintText: hint,
                    hintStyle: TextStyle(color: t.textMuted.withValues(alpha: 0.7), fontSize: 13),
                  ),
                ),
              ),
              if (suffix != null) suffix!,
            ],
          ),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(error!, style: TextStyle(color: t.danger, fontSize: 11.5)),
          ),
      ],
    );
  }
}

/// Small stat switcher row (used for Pomodoro presets and intensity pickers).
class SegmentedNeonPicker extends StatelessWidget {
  const SegmentedNeonPicker({
    super.key,
    required this.options,
    required this.selectedIndex,
    required this.onSelected,
    this.accent,
  });

  final List<String> options;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final AppTokens t = context.tokens;
    final Color color = accent ?? t.primary;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: t.glassFill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.glassBorder),
      ),
      child: Row(
        children: <Widget>[
          for (int i = 0; i < options.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => onSelected(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    color: i == selectedIndex ? color.withValues(alpha: 0.22) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: i == selectedIndex ? color.withValues(alpha: 0.5) : Colors.transparent,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      options[i],
                      style: TextStyle(
                        color: i == selectedIndex ? t.textPrimary : t.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
