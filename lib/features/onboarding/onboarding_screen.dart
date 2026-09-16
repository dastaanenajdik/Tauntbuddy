import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/ambient_background.dart';
import '../../core/widgets/emoji_burst.dart';
import '../../core/widgets/form_fields.dart';
import '../../core/widgets/glass.dart';
import '../../core/widgets/hamster_mascot.dart';
import '../../core/widgets/ui_kit.dart';
import '../../state/app_state.dart';
import '../settings/widgets/theme_chooser.dart';

/// First-run flow: brand → identity → notification permission → theme & KAVACH.
///
/// Notification permission is requested *here, on purpose*: the smart taunts
/// are the product's core USP, so the ask is explained before the OS dialog
/// appears instead of interrupting the user later.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _college = TextEditingController();
  final TextEditingController _exam = TextEditingController();

  int _page = 0;
  bool _wantsNotifications = true;
  bool _armKavach = true;
  String? _nameError;
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    _name.dispose();
    _college.dispose();
    _exam.dispose();
    super.dispose();
  }

  void _next() {
    if (_page == 1 && Validators.displayName(_name.text) != null) {
      setState(() => _nameError = Validators.displayName(_name.text));
      return;
    }
    if (_page < 3) {
      setState(() => _nameError = null);
      _controller.nextPage(duration: const Duration(milliseconds: 380), curve: Curves.easeOutCubic);
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    setState(() => _busy = true);
    final AppState app = context.read<AppState>();
    await app.completeOnboarding(
      name: _name.text,
      email: '${_name.text.trim().toLowerCase().replaceAll(' ', '.')}@tauntbuddy.local',
      isGuest: true,
      wantsNotifications: _wantsNotifications,
      acceptedKavach: _armKavach,
    );
    await app.updateProfile(
      app.profile.copyWith(college: _college.text.trim(), examTarget: _exam.text.trim()),
    );
    if (!mounted) return;
    EmojiBurst.fireFrom(context, emojis: EmojiBurst.rewardEmojis, count: 16);
    Navigator.of(context).pushReplacementNamed(AppRouter.shell);
  }

  @override
  Widget build(BuildContext context) {
    final AppTokens t = context.tokens;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AmbientBackground(
        child: SafeArea(
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: Row(
                  children: <Widget>[
                    GradientText('TauntBuddy', style: Theme.of(context).textTheme.headlineSmall),
                    const Spacer(),
                    Text(
                      '${_page + 1}/4',
                      style: TextStyle(color: t.textMuted, fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _controller,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (int index) => setState(() => _page = index),
                  children: <Widget>[
                    _WelcomePage(onStart: _next),
                    _IdentityPage(
                      name: _name,
                      college: _college,
                      exam: _exam,
                      error: _nameError,
                    ),
                    _PermissionPage(
                      enabled: _wantsNotifications,
                      onChanged: (bool value) => setState(() => _wantsNotifications = value),
                    ),
                    _FinishPage(
                      armKavach: _armKavach,
                      onArmKavach: (bool value) => setState(() => _armKavach = value),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
                child: Column(
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        for (int i = 0; i < 4; i++)
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: i == _page ? 22 : 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: i == _page ? t.primary : t.glassBorder,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    GlowButton(
                      label: _page == 3 ? 'Enter the arena' : 'Continue',
                      icon: _page == 3 ? Icons.rocket_launch_rounded : Icons.arrow_forward_rounded,
                      busy: _busy,
                      onPressed: _busy ? null : _next,
                    ),
                    if (_page == 1)
                      TextButton(
                        onPressed: () => AppRouter.go(context, AppRouter.auth),
                        child: Text(
                          'Already have an account? Sign in',
                          style: TextStyle(color: t.textMuted, fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WelcomePage extends StatelessWidget {
  const _WelcomePage({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final AppTokens t = context.tokens;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const HamsterMascot(size: 190, pose: MascotPose.celebrate, onTap: null),
          const SizedBox(height: 22),
          GradientText(
            'Meet your judgemental study buddy',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: 14),
          Text(
            'Ekagra focus timers, a KAVACH distraction shield, exam planning, Dhyan '
            'resets — and a hamster who will absolutely roast you if you slack off.',
            textAlign: TextAlign.center,
            style: TextStyle(color: t.textMuted, fontSize: 13, height: 1.6),
          ),
          const SizedBox(height: 22),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: <Widget>[
              NeonChip(label: 'Web + Mobile', icon: Icons.devices_rounded, color: t.accentCyan),
              NeonChip(label: 'GitHub synced taunts', icon: Icons.cloud_sync_rounded, color: t.accentViolet),
              NeonChip(label: 'Offline first', icon: Icons.wifi_off_rounded, color: t.accentMint),
            ],
          ),
        ],
      ),
    );
  }
}

class _IdentityPage extends StatelessWidget {
  const _IdentityPage({
    required this.name,
    required this.college,
    required this.exam,
    this.error,
  });

  final TextEditingController name;
  final TextEditingController college;
  final TextEditingController exam;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final AppTokens t = context.tokens;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const SizedBox(height: 10),
          const Center(child: HamsterMascot(size: 130, pose: MascotPose.thinking, showShell: false)),
          const SizedBox(height: 18),
          Text('What should the hamster call you?', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 6),
          Text(
            'This stays on your device. No servers, no sign-up wall.',
            style: TextStyle(color: t.textMuted, fontSize: 12.5),
          ),
          const SizedBox(height: 20),
          GlassField(controller: name, label: 'Your name', hint: 'Aarav', error: error),
          const SizedBox(height: 14),
          GlassField(controller: college, label: 'College / School (optional)', hint: 'IIT Dhanbad'),
          const SizedBox(height: 14),
          GlassField(controller: exam, label: 'Target exam (optional)', hint: 'End Semester'),
        ],
      ),
    );
  }
}

class _PermissionPage extends StatelessWidget {
  const _PermissionPage({required this.enabled, required this.onChanged});

  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final AppTokens t = context.tokens;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Center(
            child: HamsterMascot(
              size: 140,
              pose: enabled ? MascotPose.shield : MascotPose.sleepy,
              showShell: false,
            ),
          ),
          const SizedBox(height: 24),
          Text('Let the taunts find you', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 10),
          Text(
            'TauntBuddy sends smart reminders when you go quiet: a nudge in the morning, '
            'a roast when your streak is dying, and a final call before midnight.',
            style: TextStyle(color: t.textMuted, fontSize: 13, height: 1.55),
          ),
          const SizedBox(height: 18),
          GlassCard(
            radius: 22,
            glowColor: enabled ? t.accentMint : t.accentGrey,
            child: Row(
              children: <Widget>[
                Icon(
                  enabled ? Icons.notifications_active_rounded : Icons.notifications_off_rounded,
                  color: enabled ? t.accentMint : t.accentGrey,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Smart taunt notifications',
                        style: TextStyle(color: t.textPrimary, fontWeight: FontWeight.w700, fontSize: 13.5),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        enabled ? 'On · 3 taunts a day by default' : 'Off · you can enable this later',
                        style: TextStyle(color: t.textMuted, fontSize: 11.5),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: enabled,
                  onChanged: onChanged,
                  activeTrackColor: t.accentMint.withValues(alpha: 0.45),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'You can change the intensity, timing and count any time in Settings.',
            style: TextStyle(color: t.textMuted, fontSize: 11.5),
          ),
        ],
      ),
    );
  }
}

class _FinishPage extends StatelessWidget {
  const _FinishPage({required this.armKavach, required this.onArmKavach});

  final bool armKavach;
  final ValueChanged<bool> onArmKavach;

  @override
  Widget build(BuildContext context) {
    final AppTokens t = context.tokens;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Choose your look', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          const ThemeChooserCards(),
          const SizedBox(height: 22),
          GlassCard(
            radius: 22,
            glowColor: t.accentMagenta,
            child: Row(
              children: <Widget>[
                Icon(Icons.shield_rounded, color: t.accentMagenta),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Arm KAVACH with every session',
                        style: TextStyle(color: t.textPrimary, fontWeight: FontWeight.w700, fontSize: 13.5),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Leaving the app during a focus block is logged as a breach.',
                        style: TextStyle(color: t.textMuted, fontSize: 11.5),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: armKavach,
                  onChanged: onArmKavach,
                  activeTrackColor: t.accentMagenta.withValues(alpha: 0.45),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
