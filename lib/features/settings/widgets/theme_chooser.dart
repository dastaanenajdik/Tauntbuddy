import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/glass.dart';
import '../../../state/app_state.dart';

/// Dark / Light / System selector. Used by onboarding and Settings so the
/// control is literally identical in both places.
class ThemeChooserCards extends StatelessWidget {
  const ThemeChooserCards({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final AppState app = context.watch<AppState>();
    final AppTokens t = context.tokens;

    const List<(ThemeMode, String, IconData, String)> options =
        <(ThemeMode, String, IconData, String)>[
      (ThemeMode.dark, 'Dark Neon', Icons.dark_mode_rounded, 'Default'),
      (ThemeMode.light, 'Light', Icons.light_mode_rounded, 'Porcelain'),
      (ThemeMode.system, 'System', Icons.brightness_auto_rounded, 'Follows OS'),
    ];

    return Column(
      children: <Widget>[
        for (final (ThemeMode mode, String label, IconData icon, String hint) in options)
          Padding(
            padding: EdgeInsets.only(bottom: compact ? 8 : 10),
            child: GlassCard(
              radius: 18,
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: compact ? 10 : 12),
              glowColor: app.themeController?.mode == mode ? t.primary : t.accentGrey,
              glowStrength: app.themeController?.mode == mode ? 0.35 : 0.08,
              onTap: () => app.setThemeMode(mode),
              child: Row(
                children: <Widget>[
                  Icon(
                    icon,
                    size: 18,
                    color: app.themeController?.mode == mode ? t.primary : t.textMuted,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: t.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                  Text(hint, style: TextStyle(color: t.textMuted, fontSize: 11)),
                  const SizedBox(width: 10),
                  Icon(
                    app.themeController?.mode == mode
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_off_rounded,
                    size: 18,
                    color: app.themeController?.mode == mode ? t.primary : t.textMuted,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
