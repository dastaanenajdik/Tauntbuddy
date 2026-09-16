import 'package:flutter/material.dart';

import '../../data/services/storage_service.dart';

/// Owns the Dark / Light / System theme selection.
///
/// The value is persisted so the very first frame of the next launch already
/// uses the right palette (no white flash on a dark-neon phone).
class ThemeController extends ChangeNotifier {
  ThemeController(this._storage);

  final StorageService _storage;

  ThemeMode _mode = ThemeMode.system;
  ThemeMode get mode => _mode;

  bool get isSystem => _mode == ThemeMode.system;

  /// Loads the persisted preference. Safe to call more than once.
  void hydrate() {
    _mode = _storage.readThemeMode();
    notifyListeners();
  }

  Future<void> setMode(ThemeMode next) async {
    if (next == _mode) return;
    _mode = next;
    notifyListeners();
    await _storage.writeThemeMode(next);
  }

  /// Cycles Dark → Light → System, used by the drawer's quick toggle.
  Future<void> cycle() async {
    switch (_mode) {
      case ThemeMode.dark:
        await setMode(ThemeMode.light);
      case ThemeMode.light:
        await setMode(ThemeMode.system);
      case ThemeMode.system:
        await setMode(ThemeMode.dark);
    }
  }

  String label(BuildContext context) {
    switch (_mode) {
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.system:
        return 'System';
    }
  }

  IconData get icon {
    switch (_mode) {
      case ThemeMode.dark:
        return Icons.dark_mode_rounded;
      case ThemeMode.light:
        return Icons.light_mode_rounded;
      case ThemeMode.system:
        return Icons.brightness_auto_rounded;
    }
  }
}
