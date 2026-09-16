import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'core/widgets/ambient_background.dart';
import 'core/widgets/hamster_mascot.dart';
import 'core/widgets/glass.dart';
import 'core/theme/app_tokens.dart';
import 'data/services/storage_service.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'state/activity_controller.dart';
import 'state/app_state.dart';
import 'state/ekagra_controller.dart';
import 'state/kavach_controller.dart';
import 'state/shell_controller.dart';

/// Boots the object graph once and hands it to the widget tree.
class TauntBuddyBoot {
  const TauntBuddyBoot._();

  static Future<Widget> create() async {
    final StorageService storage = await StorageService.open();
    final ThemeController theme = ThemeController(storage)..hydrate();
    final AppState app = AppState(storage: storage, themeController: theme);
    final KavachController kavach = KavachController(service: app.kavachService);
    final ActivityController activity = ActivityController(app.activity);
    final EkagraController ekagra = EkagraController(
      activity: app.activity,
      kavach: kavach,
      notifications: app.notifications,
      settings: app.settings,
    );
    kavach.onBreach = ekagra.handleBreach;

    await app.bootstrap();
    await kavach.init();
    ekagra.applySettings(app.settings);

    return TauntBuddyApp(
      appState: app,
      themeController: theme,
      kavachController: kavach,
      activityController: activity,
      ekagraController: ekagra,
    );
  }
}

class TauntBuddyApp extends StatelessWidget {
  const TauntBuddyApp({
    super.key,
    required this.appState,
    required this.themeController,
    required this.kavachController,
    required this.activityController,
    required this.ekagraController,
  });

  final AppState appState;
  final ThemeController themeController;
  final KavachController kavachController;
  final ActivityController activityController;
  final EkagraController ekagraController;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AppState>.value(value: appState),
        ChangeNotifierProvider<ThemeController>.value(value: themeController),
        ChangeNotifierProvider<KavachController>.value(value: kavachController),
        ChangeNotifierProvider<ActivityController>.value(value: activityController),
        ChangeNotifierProvider<EkagraController>.value(value: ekagraController),
        ChangeNotifierProvider<ShellController>(create: (_) => ShellController()),
      ],
      child: Consumer<ThemeController>(
        builder: (BuildContext context, ThemeController theme, _) {
          return MaterialApp(
            title: 'TauntBuddy',
            debugShowCheckedModeBanner: false,
            themeMode: theme.mode,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            onGenerateRoute: AppRouter.onGenerateRoute,
            home: const _AppEntry(),
            builder: (BuildContext context, Widget? child) {
              // Lock text scaling to a sane range so the neon layout survives
              // aggressive accessibility settings.
              final MediaQueryData media = MediaQuery.of(context);
              return MediaQuery(
                data: media.copyWith(
                  textScaler: media.textScaler.clamp(
                    minScaleFactor: 0.9,
                    maxScaleFactor: 1.25,
                  ),
                ),
                child: child ?? const SizedBox.shrink(),
              );
            },
          );
        },
      ),
    );
  }
}

/// Decides between the boot splash, onboarding and the main shell.
class _AppEntry extends StatelessWidget {
  const _AppEntry();

  @override
  Widget build(BuildContext context) {
    final AppState app = context.watch<AppState>();
    if (!app.ready) return const BootSplash();
    if (!app.settings.onboardingDone) return const OnboardingScreen();
    return const AppShellHost();
  }
}

/// Placeholder replaced by the router — kept so `_AppEntry` stays readable.
class AppShellHost extends StatelessWidget {
  const AppShellHost({super.key});

  @override
  Widget build(BuildContext context) => AppRouter.routes[AppRouter.shell]!(context);
}

/// Animated first-paint screen while preferences and datasets load.
class BootSplash extends StatefulWidget {
  const BootSplash({super.key});

  @override
  State<BootSplash> createState() => _BootSplashState();
}

class _BootSplashState extends State<BootSplash> {
  @override
  Widget build(BuildContext context) {
    final AppState app = context.watch<AppState>();
    final AppTokens t = context.tokens;

    return Scaffold(
      body: AmbientBackground(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const HamsterMascot(size: 190, animate: true),
              const SizedBox(height: 26),
              GradientText(
                'TauntBuddy',
                style: Theme.of(context).textTheme.displayMedium,
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  '"Kyuki kal karunga se degree nahi milti"',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: t.textMuted, fontSize: 13, fontStyle: FontStyle.italic),
                ),
              ),
              const SizedBox(height: 34),
              GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                radius: 20,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: t.glow),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      app.bootstrapMessage,
                      style: TextStyle(color: t.textPrimary, fontSize: 12.5, fontWeight: FontWeight.w600),
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
