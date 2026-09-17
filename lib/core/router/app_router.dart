import 'package:flutter/material.dart';

import '../../features/analytics/analytics_screen.dart';
import '../../features/auth/auth_screen.dart';
import '../../features/circles/circles_screen.dart';
import '../../features/courses/courses_screen.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/dhyan/dhyan_screen.dart';
import '../../features/ekagra/ekagra_screen.dart';
import '../../features/exams/exams_screen.dart';
import '../../features/goals/goals_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/kavach/kavach_screen.dart';
import '../../features/leaderboard/leaderboard_screen.dart';
import '../../features/library/library_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/planner/planner_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/search/search_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/shell/app_shell.dart';
import '../../features/taunts/taunts_screen.dart';
import '../../features/timeline/timeline_screen.dart';

/// Central route table.
///
/// Feature cards in `seed_catalog.json` carry a route string; [routes] maps
/// those strings onto screens, and [pushNamed] falls back to the shell for
/// unknown routes so a dataset update can never strand the user on a blank
/// screen.
class AppRouter {
  const AppRouter._();

  static const String root = '/';
  static const String onboarding = '/onboarding';
  static const String auth = '/auth';
  static const String shell = '/shell';
  static const String home = '/home';
  static const String dashboard = '/dashboard';
  static const String ekagra = '/ekagra';
  static const String planner = '/planner';
  static const String exams = '/exams';
  static const String kavach = '/kavach';
  static const String leaderboard = '/leaderboard';
  static const String courses = '/courses';
  static const String circles = '/circles';
  static const String dhyan = '/dhyan';
  static const String timeline = '/timeline';
  static const String goals = '/goals';
  static const String taunts = '/taunts';
  static const String library = '/library';
  static const String analytics = '/analytics';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String search = '/search';

  static final Map<String, WidgetBuilder> routes = <String, WidgetBuilder>{
    shell: (BuildContext context) => const AppShell(),
    onboarding: (BuildContext context) => const OnboardingScreen(),
    auth: (BuildContext context) => const AuthScreen(),
    home: (BuildContext context) => const HomeScreen(),
    dashboard: (BuildContext context) => const DashboardScreen(),
    ekagra: (BuildContext context) => const EkagraScreen(),
    planner: (BuildContext context) => const PlannerScreen(),
    exams: (BuildContext context) => const ExamsScreen(),
    kavach: (BuildContext context) => const KavachScreen(),
    leaderboard: (BuildContext context) => const LeaderboardScreen(),
    courses: (BuildContext context) => const CoursesScreen(),
    circles: (BuildContext context) => const CirclesScreen(),
    dhyan: (BuildContext context) => const DhyanScreen(),
    timeline: (BuildContext context) => const TimelineScreen(),
    goals: (BuildContext context) => const GoalsScreen(),
    taunts: (BuildContext context) => const TauntsScreen(),
    library: (BuildContext context) => const LibraryScreen(),
    analytics: (BuildContext context) => const AnalyticsScreen(),
    profile: (BuildContext context) => const ProfileScreen(),
    settings: (BuildContext context) => const SettingsScreen(),
    search: (BuildContext context) => const SearchScreen(),
  };

  /// Navigates to [route], ignoring repeated taps of the same route.
  static Future<void> go(BuildContext context, String route) async {
    if (!routes.containsKey(route)) return;
    final ModalRoute<dynamic>? current = ModalRoute.of(context);
    if (current?.settings.name == route) return;
    await Navigator.of(context).pushNamed(route);
  }

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final WidgetBuilder? builder = routes[settings.name];
    if (builder == null) return null;
    return MaterialPageRoute<void>(builder: builder, settings: settings);
  }
}
