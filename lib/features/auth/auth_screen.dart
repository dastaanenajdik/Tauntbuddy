import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/ambient_background.dart';
import '../../core/widgets/emoji_burst.dart';
import '../../core/widgets/glass.dart';
import '../../core/widgets/hamster_mascot.dart';
import '../../core/widgets/ui_kit.dart';
import '../../state/app_state.dart';
import '../settings/widgets/theme_chooser.dart' show ThemeChooserCards;
import '../../core/widgets/form_fields.dart';

/// Local-first authentication.
///
/// TauntBuddy has no backend: an "account" is a profile stored on the device,
/// and the optional ifallertzia server sync only ever moves the *taunt dataset*. This screen
/// therefore validates properly but never sends credentials anywhere.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _name = TextEditingController();

  bool _signUp = false;
  bool _busy = false;
  bool _hidePassword = true;
  String? _emailError;
  String? _passwordError;
  String? _nameError;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final String? emailError = Validators.email(_email.text);
    final String? passwordError = Validators.password(_password.text);
    final String? nameError = _signUp ? Validators.displayName(_name.text) : null;
    setState(() {
      _emailError = emailError;
      _passwordError = passwordError;
      _nameError = nameError;
    });
    if (emailError != null || passwordError != null || nameError != null) return;

    setState(() => _busy = true);
    final AppState app = context.read<AppState>();
    final String derivedName = _signUp
        ? _name.text.trim()
        : _email.text.split('@').first.replaceAll('.', ' ');

    await app.updateProfile(
      app.profile.copyWith(
        name: derivedName.isEmpty ? 'Friend' : derivedName,
        email: _email.text.trim(),
        isGuest: false,
        lastLoginAt: DateTime.now(),
        createdAt: app.profile.createdAt ?? DateTime.now(),
      ),
    );
    await app.updateSettings(app.settings.copyWith(onboardingDone: true));
    if (!mounted) return;
    EmojiBurst.fireFrom(context, emojis: EmojiBurst.rewardEmojis, count: 14);
    Navigator.of(context).pushNamedAndRemoveUntil(AppRouter.shell, (Route<dynamic> r) => false);
  }

  Future<void> _continueAsGuest() async {
    final AppState app = context.read<AppState>();
    await app.updateProfile(
      app.profile.copyWith(isGuest: true, lastLoginAt: DateTime.now()),
    );
    await app.updateSettings(app.settings.copyWith(onboardingDone: true));
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(AppRouter.shell, (Route<dynamic> r) => false);
  }

  @override
  Widget build(BuildContext context) {
    final AppTokens t = context.tokens;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AmbientBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 40),
            children: <Widget>[
              Row(
                children: <Widget>[
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: Icon(Icons.arrow_back_rounded, color: t.textPrimary),
                  ),
                  const Spacer(),
                  const HamsterMascot(size: 54, showShell: false, showGlow: false),
                ],
              ),
              const SizedBox(height: 10),
              GradientText(
                _signUp ? 'Create your account' : 'Welcome back',
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const SizedBox(height: 10),
              Text(
                _signUp
                    ? 'Your profile lives on this device. No passwords leave your phone.'
                    : 'Sign in to pick up your streak exactly where you left it.',
                style: TextStyle(color: t.textMuted, fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 24),
              if (_signUp) ...<Widget>[
                GlassField(
                  controller: _name,
                  label: 'Name',
                  hint: 'Aarav Sharma',
                  error: _nameError,
                  prefixIcon: Icons.person_rounded,
                ),
                const SizedBox(height: 16),
              ],
              GlassField(
                controller: _email,
                label: 'Email',
                hint: 'you@college.edu',
                error: _emailError,
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.alternate_email_rounded,
              ),
              const SizedBox(height: 16),
              GlassField(
                controller: _password,
                label: 'Password',
                hint: '••••••••',
                error: _passwordError,
                obscure: _hidePassword,
                prefixIcon: Icons.lock_rounded,
                suffix: IconButton(
                  icon: Icon(
                    _hidePassword ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                    size: 18,
                    color: t.textMuted,
                  ),
                  onPressed: () => setState(() => _hidePassword = !_hidePassword),
                ),
              ),
              const SizedBox(height: 22),
              GlowButton(
                label: _signUp ? 'Create account' : 'Sign in',
                icon: Icons.login_rounded,
                busy: _busy,
                onPressed: _busy ? null : _submit,
              ),
              const SizedBox(height: 12),
              GhostButton(
                label: 'Continue as guest',
                icon: Icons.person_outline_rounded,
                expand: true,
                compact: false,
                onPressed: _busy ? null : _continueAsGuest,
              ),
              const SizedBox(height: 18),
              Center(
                child: TextButton(
                  onPressed: () => setState(() {
                    _signUp = !_signUp;
                    _emailError = null;
                    _passwordError = null;
                    _nameError = null;
                  }),
                  child: Text(
                    _signUp
                        ? 'Already have an account? Sign in'
                        : "New here? Create an account",
                    style: TextStyle(color: t.accentCyan, fontSize: 12.5, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              GlassCard(
                radius: 20,
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: <Widget>[
                    Icon(Icons.privacy_tip_rounded, size: 17, color: t.accentMint),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'TauntBuddy stores everything locally. The only network call is '
                        'fetching the taunt dataset JSON from the ifallertzia server.',
                        style: TextStyle(color: t.textMuted, fontSize: 11, height: 1.45),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Text(
                'Theme',
                style: TextStyle(color: t.textMuted, fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 1),
              ),
              const SizedBox(height: 10),
              const ThemeChooserCards(compact: true),
            ],
          ),
        ),
      ),
    );
  }
}
