import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tauntbuddy/core/theme/app_theme.dart';
import 'package:tauntbuddy/core/theme/app_tokens.dart';
import 'package:tauntbuddy/core/utils/app_date_utils.dart';
import 'package:tauntbuddy/core/widgets/glass.dart';
import 'package:tauntbuddy/core/widgets/hamster_mascot.dart';
import 'package:tauntbuddy/core/widgets/ui_kit.dart';

void main() {
  group('Home greeting (acceptance copy)', () {
    test('evening greeting matches the required sentence exactly', () {
      expect(
        AppDateUtils.homeHeadline(
          now: DateTime(2026, 9, 16, 19, 30),
          name: 'Dastan',
        ),
        'Good evening, Dastan. Your universe of focus awaits.',
      );
    });

    test('the same sentence shape is used at every hour', () {
      for (final int hour in <int>[6, 9, 14, 16, 19, 22]) {
        final String headline = AppDateUtils.homeHeadline(
          now: DateTime(2026, 9, 16, hour),
          name: 'Dastan',
        );
        expect(headline, endsWith('Dastan. Your universe of focus awaits.'));
        expect(headline, startsWith(AppDateUtils.greeting(DateTime(2026, 9, 16, hour))));
      }
    });

    test('a blank name never leaks an empty greeting', () {
      expect(
        AppDateUtils.homeHeadline(now: DateTime(2026, 9, 16, 20), name: '  '),
        'Good evening, friend. Your universe of focus awaits.',
      );
    });
  });

  group('Solid Neon tokens', () {
    test('brand colours match the design spec', () {
      const AppTokens dark = AppTokens.dark;
      expect(dark.background, const Color(0xFF131120));
      expect(dark.primary, const Color(0xFFA855F7));
      expect(dark.primaryDeep, const Color(0xFF7C3AED));
      expect(dark.textPrimary, const Color(0xFFFFFFFF));
      expect(dark.textMuted, const Color(0xFFBDB8D4));
    });

    test('cards, borders and type are solid — nothing is washed out', () {
      for (final AppTokens tokens in <AppTokens>[AppTokens.dark, AppTokens.light]) {
        expect(tokens.glassFill.a, closeTo(1, 0.001), reason: 'card fills must be opaque');
        expect(tokens.surface.a, closeTo(1, 0.001));
        expect(tokens.glassBorder.a, closeTo(1, 0.001),
            reason: 'hairlines are solid colours, not translucent white');
        expect(tokens.textPrimary.a, closeTo(1, 0.001));
        expect(tokens.textMuted.a, closeTo(1, 0.001),
            reason: 'secondary text is never faded');
      }
    });

    test('text keeps a professional contrast ratio', () {
      expect(contrastRatio(AppTokens.dark.textPrimary, AppTokens.dark.background),
          greaterThanOrEqualTo(12));
      expect(contrastRatio(AppTokens.dark.textMuted, AppTokens.dark.glassFill),
          greaterThanOrEqualTo(7));
      expect(contrastRatio(AppTokens.light.textPrimary, AppTokens.light.glassFill),
          greaterThanOrEqualTo(12));
      expect(contrastRatio(AppTokens.light.textMuted, AppTokens.light.glassFill),
          greaterThanOrEqualTo(7));
    });

    test('accent keys resolve for every catalog accent', () {
      expect(accentFromKey('violet'), AppAccent.violet);
      expect(accentFromKey('cyan'), AppAccent.cyan);
      expect(accentFromKey('magenta'), AppAccent.magenta);
      expect(accentFromKey('mint'), AppAccent.mint);
      expect(accentFromKey('amber'), AppAccent.amber);
      expect(accentFromKey('grey'), AppAccent.grey);
      expect(accentFromKey(null), AppAccent.violet);
      expect(accentFromKey('nonsense'), AppAccent.violet);

      const AppTokens dark = AppTokens.dark;
      for (final AppAccent accent in AppAccent.values) {
        expect(dark.accent(accent), isA<Color>());
      }
    });

    test('both themes register the token extension', () {
      expect(AppTheme.dark().extension<AppTokens>(), isNotNull);
      expect(AppTheme.light().extension<AppTokens>(), isNotNull);
      expect(AppTheme.light().extension<AppTokens>()!.background,
          isNot(AppTheme.dark().extension<AppTokens>()!.background));
      expect(AppTheme.paletteName, isNotEmpty);
    });
  });

  group('Brand widgets', () {
    testWidgets('mascot renders in every pose without throwing', (WidgetTester tester) async {
      for (final MascotPose pose in MascotPose.values) {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.dark(),
            home: Scaffold(
              body: Center(
                child: HamsterMascot(size: 140, pose: pose, animate: false),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 40));
        expect(tester.takeException(), isNull, reason: 'pose $pose failed');
        expect(find.byType(CustomPaint), findsWidgets);
      }
    });

    testWidgets('glass kit renders on a tall page', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  GlassCard(
                    child: Column(
                      children: <Widget>[
                        const Text('glass card body'),
                        const NeonChip(label: 'FOCUS MODE', dense: true),
                        const GradientText('TauntBuddy'),
                      ],
                    ),
                  ),
                  const StatTile(label: 'Streak', value: '12d'),
                  const MetricRing(progress: 0.5, value: '50%', label: 'EKAGRA'),
                  const NeonProgressBar(progress: 0.4),
                  const SectionHeader(title: 'Today', subtitle: 'Nothing yet'),
                  const EmptyState(title: 'Empty', message: 'Nothing here yet'),
                  const ProBadge(),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 60));

      expect(find.text('glass card body'), findsOneWidget);
      expect(find.text('FOCUS MODE'), findsOneWidget);
      expect(find.text('TauntBuddy'), findsOneWidget);
      expect(find.text('50%'), findsOneWidget);
      expect(find.text('Nothing here yet'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('action buttons fire their callbacks', (WidgetTester tester) async {
      int taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  GlowButton(label: 'Start focus', onPressed: () => taps += 1),
                  const SizedBox(height: 12),
                  GhostButton(label: 'Later', onPressed: () => taps += 1),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 60));

      await tester.tap(find.text('Start focus'));
      await tester.pump();
      await tester.tap(find.text('Later'));
      await tester.pump();
      expect(taps, 2);
      expect(tester.takeException(), isNull);
    });
  });
}

/// WCAG 2.1 relative contrast — the number behind "not dim".
double relativeLuminance(Color color) {
  double channel(double value) =>
      value <= 0.03928 ? value / 12.92 : math.pow((value + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * channel(color.r) +
      0.7152 * channel(color.g) +
      0.0722 * channel(color.b);
}

double contrastRatio(Color foreground, Color background) {
  final double a = relativeLuminance(foreground);
  final double b = relativeLuminance(background);
  final double lighter = a > b ? a : b;
  final double darker = a > b ? b : a;
  return (lighter + 0.05) / (darker + 0.05);
}
