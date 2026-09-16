import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';

/// TauntBuddy entry point.
///
/// Everything heavy (preferences, datasets, notifications, theme) is prepared
/// by [TauntBuddyBoot.create] *before* the first frame, so the UI never shows a
/// half-initialised state.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Neon UI looks best edge-to-edge; keep the status bar readable in both themes.
  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Color(0xFF0C0B10),
      statusBarIconBrightness: Brightness.light,
    ),
  );

  final Widget app = await TauntBuddyBoot.create();
  runApp(app);
}
