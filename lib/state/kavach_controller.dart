import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../data/services/kavach_service.dart';

/// KAVACH — the focus shield.
///
/// While a shield session is active the controller watches the app lifecycle:
/// leaving TauntBuddy counts as a breach (that is the distraction we are
/// guarding against), and on Android the native helper raises a persistent
/// shield notification so leaving the app is visible even in the task switcher.
class KavachController extends ChangeNotifier with WidgetsBindingObserver {
  KavachController({KavachService service = const KavachService()}) : _service = service;

  final KavachService _service;

  bool _active = false;
  int _breaches = 0;
  bool _nativeSupported = false;
  bool _overlayGranted = false;
  String _profileId = 'kavach-strict';
  String _label = 'Ekagra block';
  int _targetMinutes = 25;
  DateTime? _startedAt;
  bool _strict = true;

  /// Called whenever a breach is registered so the timer can react (for
  /// example: pause the session and let the hamster comment).
  VoidCallback? onBreach;

  bool get isActive => _active;
  int get breaches => _breaches;
  bool get nativeSupported => _nativeSupported;
  bool get overlayGranted => _overlayGranted;
  String get profileId => _profileId;
  String get label => _label;
  int get targetMinutes => _targetMinutes;
  bool get strict => _strict;
  DateTime? get startedAt => _startedAt;

  Duration get elapsed => _startedAt == null
      ? Duration.zero
      : DateTime.now().difference(_startedAt!);

  /// 0 = perfectly shielded, 1 = the hamster is disappointed.
  double get integrity {
    if (!_active) return 1;
    return (1 - (_breaches * 0.12)).clamp(0, 1).toDouble();
  }

  String get statusLabel {
    if (!_active) return 'Shield offline';
    if (_breaches == 0) return 'Shield holding';
    if (_breaches == 1) return '1 breach logged';
    return '$_breaches breaches logged';
  }

  /// Registers the lifecycle observer and probes native support.
  Future<void> init() async {
    WidgetsBinding.instance.addObserver(this);
    _nativeSupported = await _service.isSupported();
    _overlayGranted = await _service.hasOverlayPermission();
    notifyListeners();
  }

  Future<void> refreshPermissions() async {
    _overlayGranted = await _service.hasOverlayPermission();
    notifyListeners();
  }

  Future<void> requestOverlayPermission() async {
    await _service.requestOverlayPermission();
    await Future<void>.delayed(const Duration(milliseconds: 400));
    await refreshPermissions();
  }

  /// Arms the shield for a session.
  Future<void> activate({
    required String profileId,
    required String label,
    required int minutes,
    required bool strict,
  }) async {
    _active = true;
    _breaches = 0;
    _profileId = profileId;
    _label = label;
    _targetMinutes = minutes;
    _strict = strict;
    _startedAt = DateTime.now();
    notifyListeners();

    if (_nativeSupported) {
      await _service.startShield(label: label, minutes: minutes, strict: strict);
    }
  }

  /// Disarms the shield and reports how many breaches were recorded.
  Future<int> deactivate() async {
    final int breaches = _breaches;
    _active = false;
    _startedAt = null;
    notifyListeners();
    if (_nativeSupported) {
      await _service.stopShield();
    }
    return breaches;
  }

  /// Manual breach (used by the in-app "I escaped" detection and tests).
  void registerBreach({String reason = 'app backgrounded'}) {
    if (!_active) return;
    _breaches += 1;
    debugPrint('KAVACH breach: $reason (total $_breaches)');
    onBreach?.call();
    notifyListeners();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_active) return;
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      registerBreach();
    }
    if (state == AppLifecycleState.resumed) {
      // Pull any breaches the native shield recorded while we were away.
      _service.consumeNativeBreaches().then((int native) {
        if (native > _breaches) {
          _breaches = native;
          notifyListeners();
        }
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
