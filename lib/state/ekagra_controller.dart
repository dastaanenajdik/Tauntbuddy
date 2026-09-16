import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/utils/app_date_utils.dart';
import '../data/models/app_settings.dart';
import '../data/models/focus_session.dart';
import '../data/repositories/activity_repository.dart';
import '../data/services/notification_service.dart';
import 'kavach_controller.dart';

/// What the Ekagra timer is doing right now.
enum EkagraPhase { idle, running, paused, breakTime, finished }

/// The deep-focus engine behind **Ekagra**: Pomodoro rounds, break handling,
/// KAVACH integration and Ekagra Depth accounting.
///
/// A single [Timer.periodic] drives everything; the controller is deliberately
/// independent of the widget tree so the countdown keeps running while the user
/// browses other screens (and is persisted as a finished session on stop).
class EkagraController extends ChangeNotifier {
  EkagraController({
    required ActivityRepository activity,
    required KavachController kavach,
    required NotificationService notifications,
    AppSettings settings = const AppSettings(),
  })  : _activity = activity,
        _kavach = kavach,
        _notifications = notifications,
        _settings = settings;

  final ActivityRepository _activity;
  final KavachController _kavach;
  final NotificationService _notifications;
  AppSettings _settings;

  Timer? _ticker;
  EkagraPhase _phase = EkagraPhase.idle;
  SessionKind _kind = SessionKind.ekagra;
  int _focusMinutes = 25;
  int _shortBreakMinutes = 5;
  int _longBreakMinutes = 15;
  int _rounds = 4;
  int _currentRound = 1;
  int _remainingSeconds = 25 * 60;
  DateTime? _startedAt;
  String _subject = 'General';
  bool _shieldArmed = false;
  int _breaches = 0;
  bool _manualDurations = false;
  bool _disposed = false;

  // ------------------------------------------------------------- getters ---

  EkagraPhase get phase => _phase;
  bool get isRunning => _phase == EkagraPhase.running;
  bool get isPaused => _phase == EkagraPhase.paused;
  bool get isIdle => _phase == EkagraPhase.idle;
  bool get onBreak => _phase == EkagraPhase.breakTime;
  SessionKind get kind => _kind;
  int get focusMinutes => _focusMinutes;
  int get shortBreakMinutes => _shortBreakMinutes;
  int get longBreakMinutes => _longBreakMinutes;
  int get rounds => _rounds;
  int get currentRound => _currentRound;
  int get remainingSeconds => _remainingSeconds;
  int get elapsedSeconds => (totalSeconds - _remainingSeconds).clamp(0, 1 << 30);
  int get totalSeconds => (onBreak ? _shortBreakMinutes : _focusMinutes) * 60;
  String get subject => _subject;
  bool get shieldArmed => _shieldArmed;
  int get breaches => _breaches;
  DateTime? get startedAt => _startedAt;

  double get progress => totalSeconds == 0
      ? 0
      : ((totalSeconds - _remainingSeconds) / totalSeconds).clamp(0, 1).toDouble();

  String get clock {
    final int minutes = _remainingSeconds ~/ 60;
    final int seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  int get todayFocusMinutes =>
      _activity.minutesOn(DayKey.today(), kind: SessionKind.ekagra);

  // ------------------------------------------------------------ settings ---

  void applySettings(AppSettings settings) {
    _settings = settings;
    // The user may have tweaked the dial straight on the timer screen; those
    // values win until they start a fresh session.
    if (_manualDurations) return;
    _focusMinutes = settings.pomodoroFocusMinutes;
    _shortBreakMinutes = settings.pomodoroShortBreakMinutes;
    _longBreakMinutes = settings.pomodoroLongBreakMinutes;
    _rounds = settings.pomodoroRounds;
    if (_phase == EkagraPhase.idle) {
      _remainingSeconds = _focusMinutes * 60;
    }
    notifyListeners();
  }

  void setDurations({int? focus, int? shortBreak, int? longBreak, int? rounds}) {
    if (focus != null) _focusMinutes = focus.clamp(5, 180);
    if (shortBreak != null) _shortBreakMinutes = shortBreak.clamp(1, 60);
    if (longBreak != null) _longBreakMinutes = longBreak.clamp(5, 90);
    if (rounds != null) _rounds = rounds.clamp(1, 12);
    _manualDurations = true;
    if (_phase == EkagraPhase.idle) {
      _remainingSeconds = _focusMinutes * 60;
    }
    notifyListeners();
  }

  /// Re-reads the configured Pomodoro values (used after a settings reset).
  void resetDurationsToSettings() {
    _manualDurations = false;
    applySettings(_settings);
  }

  void setKind(SessionKind kind) {
    _kind = kind;
    _focusMinutes = kind == SessionKind.dhyan ? 10 : _settings.pomodoroFocusMinutes;
    if (_phase == EkagraPhase.idle) {
      _remainingSeconds = _focusMinutes * 60;
    }
    notifyListeners();
  }

  void setSubject(String subject) {
    _subject = subject;
    notifyListeners();
  }

  // --------------------------------------------------------------- engine ---

  /// Starts (or resumes) a session.
  Future<void> start({bool armShield = false}) async {
    if (_phase == EkagraPhase.running) return;

    if (_phase == EkagraPhase.idle || _phase == EkagraPhase.finished) {
      _startedAt = DateTime.now();
      _remainingSeconds = _focusMinutes * 60;
      _currentRound = 1;
      _breaches = 0;
    }

    _phase = EkagraPhase.running;
    _startTicker();
    notifyListeners();

    if (armShield && _settings.kavachAutoStart) {
      await _kavach.activate(
        profileId: _settings.kavachStrict ? 'kavach-strict' : 'kavach-soft',
        label: _subject.isEmpty ? 'Ekagra block' : '$_subject · Ekagra',
        minutes: _focusMinutes,
        strict: _settings.kavachStrict,
      );
      _shieldArmed = _kavach.isActive;
      notifyListeners();
    }
  }

  void pause() {
    if (_phase != EkagraPhase.running) return;
    _phase = EkagraPhase.paused;
    _ticker?.cancel();
    notifyListeners();
  }

  Future<void> resume() async {
    if (_phase != EkagraPhase.paused) return;
    _phase = EkagraPhase.running;
    _startTicker();
    notifyListeners();
  }

  /// Ends the current session, optionally saving it.
  Future<FocusSession?> stop({bool save = true, bool completed = false}) async {
    _ticker?.cancel();
    final FocusSession? session = save ? await _persist(completed: completed) : null;
    _phase = EkagraPhase.idle;
    _remainingSeconds = _focusMinutes * 60;
    _startedAt = null;
    _currentRound = 1;

    if (_shieldArmed) {
      _breaches = await _kavach.deactivate();
      _shieldArmed = false;
    }
    notifyListeners();
    return session;
  }

  /// Skips the break and jumps straight into the next focus round.
  Future<void> skipBreak() async {
    _ticker?.cancel();
    _phase = EkagraPhase.idle;
    _remainingSeconds = _focusMinutes * 60;
    notifyListeners();
  }

  /// Called by the KAVACH controller when the user leaves the app.
  void handleBreach() {
    if (_phase == EkagraPhase.idle) return;
    _breaches += 1;
    if (_settings.kavachStrict && _phase == EkagraPhase.running) {
      pause();
    }
    notifyListeners();
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (Timer timer) async {
      if (_disposed) {
        timer.cancel();
        return;
      }
      if (_remainingSeconds > 0) {
        _remainingSeconds -= 1;
        notifyListeners();
        return;
      }
      timer.cancel();
      await _handleRoundComplete();
    });
  }

  Future<void> _handleRoundComplete() async {
    if (onBreak) {
      _phase = EkagraPhase.idle;
      _remainingSeconds = _focusMinutes * 60;
      notifyListeners();
      return;
    }

    final FocusSession? session = await _persist(completed: true);
    final bool hasNextRound = _currentRound < _rounds;

    // Notify the user that a round wrapped up (the hamster is proud).
    await _notifications.showTaunt(
      id: 7000 + _currentRound,
      title: 'Ekagra round $_currentRound complete 🎯',
      body: session == null
          ? 'Break time. Stretch, hydrate, come back sharper.'
          : '${session.actualMinutes} minutes banked · depth ${session.depthScore}. '
              'Break time!',
      severity: 1,
      sound: _settings.soundEnabled,
    );

    if (!hasNextRound) {
      _phase = EkagraPhase.finished;
      notifyListeners();
      return;
    }

    _currentRound += 1;
    _phase = EkagraPhase.breakTime;
    _remainingSeconds = (_currentRound % _rounds == 0 ? _longBreakMinutes : _shortBreakMinutes) * 60;
    notifyListeners();
    _startTicker();
  }

  Future<FocusSession?> _persist({required bool completed}) async {
    final DateTime? started = _startedAt;
    if (started == null) return null;
    final int planned = (_kind == SessionKind.dhyan ? _focusMinutes : _focusMinutes);
    final int actual = ((DateTime.now().difference(started).inSeconds) / 60).floor();
    if (actual <= 0) return null;

    final FocusSession session = FocusSession(
      id: 's-${DateTime.now().microsecondsSinceEpoch}',
      startedAt: started,
      plannedMinutes: planned,
      actualMinutes: actual,
      kind: _kind,
      subject: _subject,
      kavachBreaches: _breaches,
      completed: completed,
      label: _shieldArmed ? 'kavach · $_subject' : _subject,
    );
    await _activity.addSession(session);
    return session;
  }

  @override
  void dispose() {
    _disposed = true;
    _ticker?.cancel();
    super.dispose();
  }
}
