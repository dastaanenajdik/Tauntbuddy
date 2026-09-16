import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Bridge to the small native KAVACH helper that ships with the Android app.
///
/// The Dart side of KAVACH (screen awareness + breach counting) works on every
/// platform; the native part adds a persistent shield notification and,
/// optionally, a draw-over-other-apps chip. Everything here degrades silently
/// when the platform has no implementation, which keeps web/desktop builds
/// free of platform channels.
class KavachService {
  const KavachService();

  static const MethodChannel channel = MethodChannel('com.tauntbuddy.app/tauntbuddy_native');

  /// Whether the current platform has a native shield implementation.
  Future<bool> isSupported() async {
    if (kIsWeb) return false;
    try {
      final bool? result = await channel.invokeMethod<bool>('isSupported');
      return result ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException catch (e) {
      debugPrint('KAVACH: isSupported failed (${e.code})');
      return false;
    }
  }

  /// Android "Display over other apps" permission state.
  Future<bool> hasOverlayPermission() async {
    if (kIsWeb) return false;
    try {
      final bool? result = await channel.invokeMethod<bool>('hasOverlayPermission');
      return result ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  /// Opens the Android overlay-permission settings page.
  Future<void> requestOverlayPermission() async {
    if (kIsWeb) return;
    try {
      await channel.invokeMethod<void>('requestOverlayPermission');
    } on MissingPluginException {
      // Desktop/web: nothing to do.
    } on PlatformException catch (e) {
      debugPrint('KAVACH: requestOverlayPermission failed (${e.code})');
    }
  }

  /// Starts the native shield (persistent notification + optional chip).
  Future<bool> startShield({
    required String label,
    required int minutes,
    required bool strict,
  }) async {
    if (kIsWeb) return false;
    try {
      final bool? result = await channel.invokeMethod<bool>('startShield', <String, dynamic>{
        'label': label,
        'minutes': minutes,
        'strict': strict,
      });
      return result ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException catch (e) {
      debugPrint('KAVACH: startShield failed (${e.code})');
      return false;
    }
  }

  /// Stops the native shield.
  Future<void> stopShield() async {
    if (kIsWeb) return;
    try {
      await channel.invokeMethod<void>('stopShield');
    } on MissingPluginException {
      // Nothing running natively.
    } on PlatformException catch (e) {
      debugPrint('KAVACH: stopShield failed (${e.code})');
    }
  }

  /// Number of shield breaches recorded natively while the app was backgrounded.
  Future<int> consumeNativeBreaches() async {
    if (kIsWeb) return 0;
    try {
      final int? result = await channel.invokeMethod<int>('consumeBreaches');
      return result ?? 0;
    } on MissingPluginException {
      return 0;
    } on PlatformException {
      return 0;
    }
  }
}
