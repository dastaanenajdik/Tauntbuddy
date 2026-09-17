import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/app_date_utils.dart';
import '../../core/widgets/emoji_burst.dart';
import '../../core/widgets/glass.dart';
import '../../core/widgets/hamster_mascot.dart';
import '../../core/widgets/ui_kit.dart';
import '../../data/models/catalog.dart';
import '../../state/app_state.dart';
import '../../state/ekagra_controller.dart';
import '../../state/kavach_controller.dart';

/// KAVACH — the focus shield.
///
/// In-app the shield watches the app lifecycle: leaving TauntBuddy during a
/// focus block is a breach. On Android the native helper adds a persistent
/// shield notification (and an optional draw-over chip) so the commitment is
/// visible even outside the app.
class KavachScreen extends StatelessWidget {
  const KavachScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final KavachController kavach = context.watch<KavachController>();
    final EkagraController ekagra = context.watch<EkagraController>();
    final AppState app = context.watch<AppState>();
    final AppTokens t = context.tokens;

    final List<KavachProfile> profiles = app.catalog.kavachProfiles;
    final KavachProfile selected = profiles.firstWhere(
      (KavachProfile p) => p.id == kavach.profileId,
      orElse: () => profiles.isEmpty
          ? const KavachProfile(
              id: 'kavach-strict',
              title: 'Strict Shield',
              strictness: 'no grace',
              accent: 'magenta',
              description: '',
              blockedApps: <String>[],
            )
          : profiles.first,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 120),
      children: <Widget>[
        SectionHeader(
          title: 'Distraction Shield',
          subtitle: 'Your distraction shield',
          icon: Icons.shield_rounded,
          accent: t.accentMagenta,
          trailing: NeonChip(
            label: kavach.isActive ? 'ACTIVE' : 'OFFLINE',
            dense: true,
            color: kavach.isActive ? t.accentMint : t.accentGrey,
          ),
        ),
        GlassCard(
          radius: 28,
          glowColor: kavach.isActive ? t.accentMint : t.accentMagenta,
          glowStrength: kavach.isActive ? 0.35 : 0.18,
          padding: const EdgeInsets.all(20),
          child: Column(
            children: <Widget>[
              MetricRing(
                progress: kavach.integrity,
                value: '${(kavach.integrity * 100).round()}%',
                label: 'INTEGRITY',
                size: 150,
                stroke: 11,
                colors: kavach.breaches == 0
                    ? <Color>[t.accentMint, t.accentCyan]
                    : <Color>[t.accentAmber, t.danger],
              ),
              const SizedBox(height: 12),
              HamsterMascot(
                size: 92,
                pose: kavach.isActive ? MascotPose.shield : MascotPose.judging,
                showShell: false,
              ),
              const SizedBox(height: 10),
              Text(
                kavach.isActive
                    ? '${kavach.label} · ${AppDateUtils.durationLabel(kavach.targetMinutes)}'
                    : 'Shield is offline',
                textAlign: TextAlign.center,
                style: TextStyle(color: t.textPrimary, fontSize: 15, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                kavach.isActive
                    ? '${kavach.statusLabel}. Stay here and it stays clean.'
                    : 'Arm it before you start a block — the hamster logs every escape.',
                textAlign: TextAlign.center,
                style: TextStyle(color: t.textMuted, fontSize: 12, height: 1.45),
              ),
              const SizedBox(height: 18),
              Row(
                children: <Widget>[
                  Expanded(
                    child: GlowButton(
                      label: kavach.isActive ? 'Disarm shield' : 'Arm shield now',
                      icon: kavach.isActive ? Icons.gpp_bad_rounded : Icons.gpp_good_rounded,
                      gradient: kavach.isActive
                          ? <Color>[t.danger, t.accentMagenta]
                          : <Color>[t.accentMint, t.accentCyan],
                      onPressed: () async {
                        if (kavach.isActive) {
                          await kavach.deactivate();
                          return;
                        }
                        await kavach.activate(
                          profileId: selected.id,
                          label: selected.title,
                          minutes: ekagra.focusMinutes,
                          strict: app.settings.kavachStrict,
                        );
                        if (context.mounted) {
                          EmojiBurst.fireFrom(context, emojis: EmojiBurst.rewardEmojis, count: 10);
                        }
                      },
                    ),
                  ),
                ],
              ),
              if (!ekagra.isRunning && !kavach.isActive) ...<Widget>[
                const SizedBox(height: 10),
                GhostButton(
                  label: 'Start Focus Flow with shield armed',
                  icon: Icons.bolt_rounded,
                  expand: true,
                  compact: false,
                  onPressed: () async {
                    await ekagra.start(armShield: true);
                    if (!context.mounted) return;
                    AppRouter.go(context, AppRouter.ekagra);
                  },
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 18),
        SectionHeader(
          title: 'Shield profile',
          subtitle: 'How aggressive should it be?',
          icon: Icons.tune_rounded,
        ),
        Column(
          children: <Widget>[
            for (final KavachProfile profile in profiles)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GlassCard(
                  radius: 20,
                  padding: const EdgeInsets.all(14),
                  glowColor: t.accent(accentFromKey(profile.accent)),
                  glowStrength: selected.id == profile.id ? 0.3 : 0.06,
                  onTap: () => app.updateSettings(
                    app.settings.copyWith(kavachStrict: profile.id != 'kavach-soft'),
                  ),
                  child: Row(
                    children: <Widget>[
                      Icon(
                        profile.id == 'kavach-exam'
                            ? Icons.lock_clock_rounded
                            : profile.id == 'kavach-strict'
                                ? Icons.shield_rounded
                                : Icons.shield_outlined,
                        color: t.accent(accentFromKey(profile.accent)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              profile.title,
                              style: TextStyle(
                                color: t.textPrimary,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${profile.strictness} · blocks ${profile.blockedApps.length} apps',
                              style: TextStyle(color: t.textMuted, fontSize: 11),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              profile.description,
                              style: TextStyle(color: t.textMuted, fontSize: 10.5, height: 1.35),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        if (!kIsWeb) _NativeShieldCard(kavach: kavach),
        const SizedBox(height: 16),
        SectionHeader(
          title: 'Breach log',
          subtitle: 'Times you left the arena',
          icon: Icons.warning_amber_rounded,
          accent: t.danger,
        ),
        GlassCard(
          radius: 22,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: <Widget>[
              Icon(Icons.visibility_off_rounded, size: 18, color: t.danger),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '${kavach.breaches} breach${kavach.breaches == 1 ? '' : 'es'} this session',
                      style: TextStyle(color: t.textPrimary, fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      kavach.breaches == 0
                          ? 'Clean run so far. The hamster is almost proud.'
                          : 'Each breach costs you 12% of the session quality score.',
                      style: TextStyle(color: t.textMuted, fontSize: 11, height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NativeShieldCard extends StatelessWidget {
  const _NativeShieldCard({required this.kavach});

  final KavachController kavach;

  @override
  Widget build(BuildContext context) {
    final AppTokens t = context.tokens;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: GlassCard(
        radius: 22,
        padding: const EdgeInsets.all(16),
        glowColor: t.accentCyan,
        glowStrength: 0.18,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(Icons.phone_android_rounded, size: 18, color: t.accentCyan),
                const SizedBox(width: 10),
                Text(
                  'Native shield (Android)',
                  style: TextStyle(color: t.textPrimary, fontSize: 13.5, fontWeight: FontWeight.w800),
                ),
                const Spacer(),
                NeonChip(
                  label: kavach.nativeSupported ? 'supported' : 'not available',
                  dense: true,
                  color: kavach.nativeSupported ? t.accentMint : t.accentGrey,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              kavach.nativeSupported
                  ? 'A persistent shield notification keeps your session visible. Grant the '
                      'optional "display over other apps" permission for the on-screen chip.'
                  : 'This build runs the shield entirely in-app. Install the Android build for the '
                      'persistent notification guard.',
              style: TextStyle(color: t.textMuted, fontSize: 11.5, height: 1.45),
            ),
            if (kavach.nativeSupported) ...<Widget>[
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  GhostButton(
                    label: kavach.overlayGranted ? 'Permission granted' : 'Grant overlay permission',
                    icon: Icons.layers_rounded,
                    color: kavach.overlayGranted ? t.accentMint : t.accentCyan,
                    onPressed: kavach.overlayGranted ? null : kavach.requestOverlayPermission,
                  ),
                  const SizedBox(width: 8),
                  GhostButton(
                    label: 'Refresh',
                    icon: Icons.refresh_rounded,
                    onPressed: kavach.refreshPermissions,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
