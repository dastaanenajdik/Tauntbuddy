import 'package:flutter/material.dart';

/// Accent keys used across TauntBuddy.
///
/// Accents are stored as short string keys inside asset JSON
/// (`assets/data/seed_catalog.json`) so that content stays data, not code.
/// Widgets resolve a key through [AppTokens.accent].
enum AppAccent { violet, cyan, magenta, mint, amber, grey }

/// Resolves an [AppAccent] from its JSON key. Unknown keys fall back to violet
/// so a typo in a remote dataset can never crash a screen.
AppAccent accentFromKey(String? key) {
  switch ((key ?? '').toLowerCase()) {
    case 'cyan':
      return AppAccent.cyan;
    case 'magenta':
      return AppAccent.magenta;
    case 'mint':
      return AppAccent.mint;
    case 'amber':
      return AppAccent.amber;
    case 'grey':
    case 'gray':
      return AppAccent.grey;
    case 'violet':
    default:
      return AppAccent.violet;
  }
}

/// The design tokens that give TauntBuddy its signature look: a deep, almost
/// black canvas, frosted glass panels and electric violet highlights.
///
/// Exposed as a [ThemeExtension] so the light/dark/system switch is a single
/// `MaterialApp.themeMode` change and every widget reacts instantly.
@immutable
class AppTokens extends ThemeExtension<AppTokens> {
  const AppTokens({
    required this.isDark,
    required this.background,
    required this.backgroundAlt,
    required this.surface,
    required this.surfaceHigh,
    required this.glassFill,
    required this.glassBorder,
    required this.glassHighlight,
    required this.textPrimary,
    required this.textMuted,
    required this.primary,
    required this.primaryDeep,
    required this.glow,
    required this.accentViolet,
    required this.accentCyan,
    required this.accentMagenta,
    required this.accentMint,
    required this.accentAmber,
    required this.accentGrey,
    required this.success,
    required this.warning,
    required this.danger,
    required this.shadow,
    required this.gridLine,
  });

  final bool isDark;
  final Color background;
  final Color backgroundAlt;
  final Color surface;
  final Color surfaceHigh;
  final Color glassFill;
  final Color glassBorder;
  final Color glassHighlight;
  final Color textPrimary;
  final Color textMuted;
  final Color primary;
  final Color primaryDeep;
  final Color glow;
  final Color accentViolet;
  final Color accentCyan;
  final Color accentMagenta;
  final Color accentMint;
  final Color accentAmber;
  final Color accentGrey;
  final Color success;
  final Color warning;
  final Color danger;
  final Color shadow;
  final Color gridLine;

  /// Modern dark neon palette — the default TauntBuddy mood.
  static const AppTokens dark = AppTokens(
    isDark: true,
    background: Color(0xFF0C0B10),
    backgroundAlt: Color(0xFF141021),
    surface: Color(0xFF14121B),
    surfaceHigh: Color(0xFF1C1A27),
    glassFill: Color(0x14FFFFFF),
    glassBorder: Color(0x1FFFFFFF),
    glassHighlight: Color(0x0AFFFFFF),
    textPrimary: Color(0xFFF6F4FF),
    textMuted: Color(0xFF9A95AD),
    primary: Color(0xFF9D4EDD),
    primaryDeep: Color(0xFF8A2BE2),
    glow: Color(0xFFB388FF),
    accentViolet: Color(0xFF9D4EDD),
    accentCyan: Color(0xFF4CC9F0),
    accentMagenta: Color(0xFFF72585),
    accentMint: Color(0xFF43E5B8),
    accentAmber: Color(0xFFFFC857),
    accentGrey: Color(0xFF7C7893),
    success: Color(0xFF38D39F),
    warning: Color(0xFFFFB020),
    danger: Color(0xFFFF4D6D),
    shadow: Color(0x99000000),
    gridLine: Color(0x14FFFFFF),
  );

  /// Light mode keeps the same neon accents on a soft porcelain canvas.
  static const AppTokens light = AppTokens(
    isDark: false,
    background: Color(0xFFF7F5FC),
    backgroundAlt: Color(0xFFEDE8FA),
    surface: Color(0xFFFFFFFF),
    surfaceHigh: Color(0xFFF2EEFB),
    glassFill: Color(0xB3FFFFFF),
    glassBorder: Color(0x1A5B2C8F),
    glassHighlight: Color(0x66FFFFFF),
    textPrimary: Color(0xFF17131F),
    textMuted: Color(0xFF6D6880),
    primary: Color(0xFF7B2FF7),
    primaryDeep: Color(0xFF5B18CC),
    glow: Color(0xFFB98BFF),
    accentViolet: Color(0xFF7B2FF7),
    accentCyan: Color(0xFF0E9BD8),
    accentMagenta: Color(0xFFD81B60),
    accentMint: Color(0xFF0F9E7A),
    accentAmber: Color(0xFFB7791F),
    accentGrey: Color(0xFF8B86A0),
    success: Color(0xFF0F9E7A),
    warning: Color(0xFFC77700),
    danger: Color(0xFFD32F4B),
    shadow: Color(0x1F2A1B4D),
    gridLine: Color(0x14000000),
  );

  /// Page background gradient used behind every screen.
  List<Color> get backgroundGradient => isDark
      ? const <Color>[Color(0xFF0C0B10), Color(0xFF120E1C), Color(0xFF0C0B10)]
      : const <Color>[Color(0xFFF9F8FE), Color(0xFFEFE9FC), Color(0xFFF9F8FE)];

  /// Violet → magenta gradient used for hero text and primary buttons.
  List<Color> get brandGradient => isDark
      ? const <Color>[Color(0xFFB388FF), Color(0xFFF72585)]
      : const <Color>[Color(0xFF7B2FF7), Color(0xFFD81B60)];

  /// Soft glow used for the mascot halo and neon borders.
  Color glowWith(double opacity) => glow.withValues(alpha: opacity);

  /// Resolves one of the named accents.
  Color accent(AppAccent value) {
    switch (value) {
      case AppAccent.violet:
        return accentViolet;
      case AppAccent.cyan:
        return accentCyan;
      case AppAccent.magenta:
        return accentMagenta;
      case AppAccent.mint:
        return accentMint;
      case AppAccent.amber:
        return accentAmber;
      case AppAccent.grey:
        return accentGrey;
    }
  }

  @override
  AppTokens copyWith({
    bool? isDark,
    Color? background,
    Color? backgroundAlt,
    Color? surface,
    Color? surfaceHigh,
    Color? glassFill,
    Color? glassBorder,
    Color? glassHighlight,
    Color? textPrimary,
    Color? textMuted,
    Color? primary,
    Color? primaryDeep,
    Color? glow,
    Color? accentViolet,
    Color? accentCyan,
    Color? accentMagenta,
    Color? accentMint,
    Color? accentAmber,
    Color? accentGrey,
    Color? success,
    Color? warning,
    Color? danger,
    Color? shadow,
    Color? gridLine,
  }) {
    return AppTokens(
      isDark: isDark ?? this.isDark,
      background: background ?? this.background,
      backgroundAlt: backgroundAlt ?? this.backgroundAlt,
      surface: surface ?? this.surface,
      surfaceHigh: surfaceHigh ?? this.surfaceHigh,
      glassFill: glassFill ?? this.glassFill,
      glassBorder: glassBorder ?? this.glassBorder,
      glassHighlight: glassHighlight ?? this.glassHighlight,
      textPrimary: textPrimary ?? this.textPrimary,
      textMuted: textMuted ?? this.textMuted,
      primary: primary ?? this.primary,
      primaryDeep: primaryDeep ?? this.primaryDeep,
      glow: glow ?? this.glow,
      accentViolet: accentViolet ?? this.accentViolet,
      accentCyan: accentCyan ?? this.accentCyan,
      accentMagenta: accentMagenta ?? this.accentMagenta,
      accentMint: accentMint ?? this.accentMint,
      accentAmber: accentAmber ?? this.accentAmber,
      accentGrey: accentGrey ?? this.accentGrey,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      shadow: shadow ?? this.shadow,
      gridLine: gridLine ?? this.gridLine,
    );
  }

  @override
  AppTokens lerp(covariant ThemeExtension<AppTokens>? other, double t) {
    if (other is! AppTokens) return this;
    return AppTokens(
      isDark: t < 0.5 ? isDark : other.isDark,
      background: Color.lerp(background, other.background, t)!,
      backgroundAlt: Color.lerp(backgroundAlt, other.backgroundAlt, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceHigh: Color.lerp(surfaceHigh, other.surfaceHigh, t)!,
      glassFill: Color.lerp(glassFill, other.glassFill, t)!,
      glassBorder: Color.lerp(glassBorder, other.glassBorder, t)!,
      glassHighlight: Color.lerp(glassHighlight, other.glassHighlight, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      primaryDeep: Color.lerp(primaryDeep, other.primaryDeep, t)!,
      glow: Color.lerp(glow, other.glow, t)!,
      accentViolet: Color.lerp(accentViolet, other.accentViolet, t)!,
      accentCyan: Color.lerp(accentCyan, other.accentCyan, t)!,
      accentMagenta: Color.lerp(accentMagenta, other.accentMagenta, t)!,
      accentMint: Color.lerp(accentMint, other.accentMint, t)!,
      accentAmber: Color.lerp(accentAmber, other.accentAmber, t)!,
      accentGrey: Color.lerp(accentGrey, other.accentGrey, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
      gridLine: Color.lerp(gridLine, other.gridLine, t)!,
    );
  }
}

/// Tiny ergonomic accessor: `context.tokens.accentViolet`.
extension AppTokensX on BuildContext {
  AppTokens get tokens => Theme.of(this).extension<AppTokens>() ?? AppTokens.dark;
}
