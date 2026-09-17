import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/glass.dart';

/// The visual baseline is intentionally fixed to white for maximum readability.
class ThemeChooserCards extends StatelessWidget {
  const ThemeChooserCards({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final AppTokens t = context.tokens;
    return GlassCard(
      radius: 18,
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: compact ? 10 : 12),
      glowColor: t.accentGrey,
      glowStrength: 0.04,
      child: Row(
        children: <Widget>[
          Icon(Icons.light_mode_rounded, size: 18, color: t.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Clean White',
                    style: TextStyle(color: t.textPrimary, fontWeight: FontWeight.w700, fontSize: 13.5)),
                const SizedBox(height: 2),
                Text('High-contrast, distraction-free canvas',
                    style: TextStyle(color: t.textMuted, fontSize: 10.5)),
              ],
            ),
          ),
          Icon(Icons.check_circle_rounded, size: 18, color: t.primary),
        ],
      ),
    );
  }
}
