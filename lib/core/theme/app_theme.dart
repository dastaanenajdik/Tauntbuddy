import 'package:flutter/material.dart';

import 'app_tokens.dart';

/// Builds the TauntBuddy [ThemeData] for dark, light and system modes.
///
/// The theme intentionally keeps a very small surface area: colours, typography
/// and page transitions only. All the neon-glass chrome (frosted panels, glow
/// borders, animated mascot) lives in reusable widgets so that the look stays
/// identical on every platform.
class AppTheme {
  const AppTheme._();

  /// Versioned palette name, surfaced in Settings → About.
  static const String paletteName = 'Solid Neon v2';

  static ThemeData dark() => build(AppTokens.dark);
  static ThemeData light() => build(AppTokens.light);

  /// Resolves the platform brightness for [ThemeMode.system].
  static ThemeData system(Brightness platformBrightness) =>
      platformBrightness == Brightness.dark ? dark() : light();

  static ThemeData build(AppTokens tokens) {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: tokens.primaryDeep,
      brightness: tokens.isDark ? Brightness.dark : Brightness.light,
    ).copyWith(
      primary: tokens.primary,
      secondary: tokens.accentCyan,
      tertiary: tokens.accentMagenta,
      surface: tokens.surface,
      onSurface: tokens.textPrimary,
      error: tokens.danger,
    );

    final TextTheme text = _textTheme(tokens);

    return ThemeData(
      useMaterial3: true,
      brightness: tokens.isDark ? Brightness.dark : Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: tokens.background,
      canvasColor: tokens.background,
      splashFactory: InkSparkle.splashFactory,
      textTheme: text,
      primaryTextTheme: text,
      dividerColor: tokens.glassBorder,
      iconTheme: IconThemeData(color: tokens.textPrimary, size: 22),
      // Solid component chrome: no washed-out tints, no hairline "underline"
      // separators, and readable ink on every overlay the framework paints.
      snackBarTheme: SnackBarThemeData(
        backgroundColor: tokens.surfaceHigh,
        contentTextStyle: TextStyle(
          color: tokens.textPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        actionTextColor: tokens.glow,
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      dividerTheme: DividerThemeData(
        color: tokens.glassBorder,
        thickness: 1,
        space: 1,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: tokens.primary,
        linearTrackColor: tokens.surfaceHigh,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: tokens.primary,
        selectionColor: tokens.primary.withValues(alpha: 0.38),
        selectionHandleColor: tokens.primary,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: _FadeThroughTransitionsBuilder(),
          TargetPlatform.iOS: _FadeThroughTransitionsBuilder(),
          TargetPlatform.macOS: _FadeThroughTransitionsBuilder(),
          TargetPlatform.windows: _FadeThroughTransitionsBuilder(),
          TargetPlatform.linux: _FadeThroughTransitionsBuilder(),
          TargetPlatform.fuchsia: _FadeThroughTransitionsBuilder(),
        },
      ),
      extensions: <ThemeExtension<dynamic>>[tokens],
    );
  }

  static TextTheme _textTheme(AppTokens tokens) {
    const List<String> stack = <String>[
      'Inter',
      'SF Pro Display',
      'Segoe UI Variable',
      'Segoe UI',
      'Roboto',
      'Noto Sans',
    ];

    TextStyle base(double size, FontWeight weight, {double? height, double? spacing}) => TextStyle(
          fontSize: size,
          fontWeight: weight,
          height: height,
          letterSpacing: spacing,
          color: tokens.textPrimary,
          decoration: TextDecoration.none,
          decorationColor: Colors.transparent,
          decorationThickness: 0,
          fontFamilyFallback: stack,
        );

    return TextTheme(
      displayLarge: base(40, FontWeight.w800, height: 1.05, spacing: -1.2),
      displayMedium: base(32, FontWeight.w800, height: 1.1, spacing: -1),
      displaySmall: base(26, FontWeight.w700, height: 1.15, spacing: -0.6),
      headlineMedium: base(22, FontWeight.w700, height: 1.2, spacing: -0.4),
      headlineSmall: base(19, FontWeight.w700, height: 1.25, spacing: -0.2),
      titleLarge: base(17, FontWeight.w700, height: 1.3),
      titleMedium: base(15, FontWeight.w600, height: 1.35),
      titleSmall: base(13.5, FontWeight.w600, height: 1.35),
      bodyLarge: base(15, FontWeight.w400, height: 1.5),
      bodyMedium: base(13.5, FontWeight.w400, height: 1.5),
      bodySmall: base(12, FontWeight.w400, height: 1.45),
      labelLarge: base(13, FontWeight.w700, spacing: 0.4),
      labelMedium: base(11.5, FontWeight.w700, spacing: 0.8),
      labelSmall: base(10.5, FontWeight.w700, spacing: 1),
    );
  }
}

/// Smooth fade + minimal lift for every pushed route. Replaces the default
/// platform transitions so navigation feels identical on web and mobile.
class _FadeThroughTransitionsBuilder extends PageTransitionsBuilder {
  const _FadeThroughTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final Animation<double> curve = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    return FadeTransition(
      opacity: curve,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.035),
          end: Offset.zero,
        ).animate(curve),
        child: child,
      ),
    );
  }
}
