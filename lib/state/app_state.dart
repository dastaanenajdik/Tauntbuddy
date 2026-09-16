import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show ThemeMode;

import '../core/theme/theme_controller.dart';
import '../core/utils/app_date_utils.dart';
import '../data/models/app_settings.dart';
import '../data/models/study_task.dart';
import '../data/models/taunt.dart';
import '../data/models/tracking.dart';
import '../data/models/user_profile.dart';
import '../data/repositories/activity_repository.dart';
import '../data/repositories/catalog_repository.dart';
import '../data/repositories/taunt_repository.dart';
import '../data/services/github_source.dart';
import '../data/services/kavach_service.dart';
import '../data/services/notification_service.dart';
import '../data/services/reminder_scheduler.dart';
import '../data/services/storage_service.dart';

/// Root application state: bootstrap, profile, settings, datasets, the smart
/// taunt engine and notification scheduling.
///
/// Everything the UI needs is exposed as a synchronous getter; all mutations go
/// through async methods that persist before notifying, so the app can be
/// killed at any moment without losing data.
class AppState extends ChangeNotifier {
  AppState({
    required StorageService storage,
    StorageService? storageOverride,
    GithubDatasetSource? source,
    NotificationService? notifications,
    KavachService kavachService = const KavachService(),
    ThemeController? themeController,
  })  : _storage = storageOverride ?? storage,
        _source = source ?? GithubDatasetSource(),
        _notifications = notifications ?? NotificationService(),
        _kavachService = kavachService,
        _themeController = themeController;

  final StorageService _storage;
  final GithubDatasetSource _source;
  final NotificationService _notifications;
  final KavachService _kavachService;
  ThemeController? _themeController;

  late final TauntRepository taunts = TauntRepository(source: _source, storage: _storage);
  late final CatalogRepository catalog = CatalogRepository(source: _source, storage: _storage);
  late final ActivityRepository activity = ActivityRepository(storage: _storage);
  late final ReminderScheduler scheduler = ReminderScheduler(notifications: _notifications);

  AppSettings _settings = const AppSettings();
  UserProfile _profile = UserProfile.guest;
  bool _ready = false;
  bool _notificationsGranted = false;
  String _bootstrapMessage = 'Waking the hamster...';
  SyncResult _lastQuoteSync = SyncResult.skipped('Not synced yet.');
  List<ScheduledTaunt> _plan = const <ScheduledTaunt>[];
  Taunt? _activeTaunt;
  int _tauntTick = 0;

  // ------------------------------------------------------------- getters ---

  AppSettings get settings => _settings;
  UserProfile get profile => _profile;
  bool get ready => _ready;
  bool get notificationsGranted => _notificationsGranted;
  String get bootstrapMessage => _bootstrapMessage;
  SyncResult get lastQuoteSync => _lastQuoteSync;
  List<ScheduledTaunt> get plan => List<ScheduledTaunt>.unmodifiable(_plan);
  Taunt? get activeTaunt => _activeTaunt;
  ThemeController? get themeController => _themeController;
  KavachService get kavachService => _kavachService;
  NotificationService get notifications => _notifications;

  bool get isPro => _settings.proUnlocked || _profile.isPro;

  /// Today's "Ekagra Depth" in minutes.
  int get todayDepth => activity.depthOn(DayKey.today());

  int get todayFocusMinutes => activity.minutesOn(DayKey.today());
  int get todayDhyanMinutes => activity.minutesOn(DayKey.today(), kind: SessionKind.dhyan);

  AnalyticsSnapshot get snapshot30 => activity.snapshot(windowDays: 30);

  int get streak {
    final Set<DayKey> active = activity.activeDays();
    return StreakCalculator.currentStreak(active);
  }

  /// Level + progress for the home header.
  double get levelProgress {
    final int total = activity.totalFocusMinutes;
    final next = catalog.nextLevelFor(total);
    if (next == null) return 1;
    final int floor = catalog.levelFor(total).minFocusMinutes;
    final int span = (next.minFocusMinutes - floor).clamp(1, 1 << 30);
    return ((total - floor) / span).clamp(0, 1).toDouble();
  }

  // ------------------------------------------------------------ bootstrap ---

  Future<void> bootstrap() async {
    _bootstrapMessage = 'Loading your focus universe...';
    notifyListeners();

    _settings = _storage.readSettings();
    _profile = _storage.readProfile();
    activity.load();

    _bootstrapMessage = 'Loading taunt packs...';
    notifyListeners();
    await taunts.load();
    await catalog.load();
    await activity.ensureGoalsForToday();

    _bootstrapMessage = 'Waking the hamster...';
    notifyListeners();
    await _notifications.init();
    _notifications.onTauntTapped = _handleNotificationTap;
    _notificationsGranted = await _notifications.areEnabled();

    if (_settings.notificationsEnabled) {
      await refreshReminders();
    }

    _ready = true;
    notifyListeners();

    // Non-blocking refresh so a slow or blocked network never delays first paint.
    unawaited(syncQuietly());
  }

  void attachThemeController(ThemeController controller) {
    _themeController = controller;
  }

  // -------------------------------------------------------------- profile ---

  Future<void> completeOnboarding({
    required String name,
    required String email,
    required bool isGuest,
    required bool wantsNotifications,
    required bool acceptedKavach,
  }) async {
    _profile = _profile.copyWith(
      name: name.trim().isEmpty ? 'Friend' : name.trim(),
      email: email.trim().isEmpty ? 'guest@tauntbuddy.app' : email.trim(),
      isGuest: isGuest,
      createdAt: _profile.createdAt ?? DateTime.now(),
      lastLoginAt: DateTime.now(),
    );
    await _storage.writeProfile(_profile);

    final AppSettings next = _settings.copyWith(
      onboardingDone: true,
      notificationsAsked: true,
      notificationsEnabled: wantsNotifications,
      kavachAutoStart: acceptedKavach,
    );
    await _persistSettings(next);

    if (wantsNotifications) {
      await requestNotificationPermission();
    }
    notifyListeners();
  }

  Future<void> updateProfile(UserProfile profile) async {
    _profile = profile;
    await _storage.writeProfile(profile);
    notifyListeners();
  }

  Future<void> signOut() async {
    _profile = UserProfile.guest;
    await _storage.writeProfile(_profile);
    final AppSettings next = _settings.copyWith(onboardingDone: false);
    await _persistSettings(next);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await _themeController?.setMode(mode);
    notifyListeners();
  }

  // ------------------------------------------------------------- settings ---

  Future<void> updateSettings(AppSettings next) async {
    await _persistSettings(next);
    if (next.notificationsEnabled != _settings.notificationsEnabled ||
        next.remindersPerDay != _settings.remindersPerDay) {
      await refreshReminders();
    }
    notifyListeners();
  }

  Future<void> _persistSettings(AppSettings next) async {
    _settings = next;
    await _storage.writeSettings(next);
  }

  Future<void> requestNotificationPermission() async {
    final bool granted = await _notifications.requestPermission();
    _notificationsGranted = granted;
    final AppSettings next = _settings.copyWith(
      notificationsEnabled: granted,
      notificationsAsked: true,
    );
    await _persistSettings(next);
    await refreshReminders();
    notifyListeners();
  }

  // -------------------------------------------------------------- taunts ----

  /// Rebuilds the daily taunt schedule from the current dataset + settings.
  Future<void> refreshReminders() async {
    _plan = scheduler.buildPlan(
      settings: _settings,
      dataset: taunts.dataset,
      excludeIds: taunts.seenIds,
    );
    await scheduler.apply(
      _plan,
      soundEnabled: _settings.soundEnabled,
      enabled: _settings.notificationsEnabled,
    );
    notifyListeners();
  }

  Future<SyncResult> syncTaunts({bool refreshSchedule = true}) async {
    final SyncResult result = await taunts.syncFromGithub(_settings.tauntRepoUrl);
    final AppSettings next = _settings.copyWith(
      lastSyncAt: result.at ?? DateTime.now(),
      lastSyncCount: taunts.count,
    );
    await _persistSettings(next);
    if (refreshSchedule) await refreshReminders();
    notifyListeners();
    return result;
  }

  Future<void> syncQuietly() async {
    try {
      await taunts.syncFromGithub(_settings.tauntRepoUrl);
      _lastQuoteSync = await catalog.syncQuotes(GithubDatasetSource.defaultQuotesUrl);
      if (_settings.notificationsEnabled) await refreshReminders();
    } catch (e) {
      debugPrint('TauntBuddy: background sync failed ($e)');
    }
    notifyListeners();
  }

  /// Fires an immediate taunt notification — the "send test ping" button.
  Future<bool> sendTestTaunt({TauntTrigger trigger = TauntTrigger.manual}) async {
    final Taunt? taunt = taunts.next(
      triggers: <TauntTrigger>[trigger, TauntTrigger.idle, TauntTrigger.goalMissed],
      maxSeverity: 3,
    );
    if (taunt == null) return false;

    _activeTaunt = taunt;
    _tauntTick += 1;

    if (_settings.notificationsEnabled) {
      await _notifications.showTaunt(
        id: 4242,
        title: 'TauntBuddy 🐹',
        body: taunt.text,
        severity: taunt.severity,
        payload: taunt.id,
        sound: _settings.soundEnabled,
      );
    }
    notifyListeners();
    return true;
  }

  /// Picks the taunt the mascot should speak right now, based on how the day
  /// is actually going.
  Taunt? pickSituationalTaunt() {
    final List<TauntTrigger> triggers = <TauntTrigger>[];
    final String bucket = AppDateUtils.timeBucket(DateTime.now());
    switch (bucket) {
      case 'morning':
        triggers.add(TauntTrigger.morning);
      case 'afternoon':
        triggers.add(TauntTrigger.afternoon);
      case 'evening':
        triggers.add(TauntTrigger.evening);
      default:
        triggers.add(TauntTrigger.night);
    }

    final int streak = this.streak;
    final DaySummary today = activity.summarize(DayKey.today());
    if (today.goalsTotal > 0 && today.goalsDone < today.goalsTotal) {
      triggers.add(TauntTrigger.goalMissed);
    }
    if (streak > 0 && activity.isSlackingToday) {
      triggers.add(TauntTrigger.streakLost);
    }
    final SyllabusSubject? exam = activity.nextExam;
    if (exam != null && exam.daysToExam <= 7) {
      triggers.add(TauntTrigger.examSoon);
    }
    triggers.add(TauntTrigger.idle);

    return taunts.next(triggers: triggers, maxSeverity: _settings.severityCap);
  }

  void setActiveTaunt(Taunt taunt) {
    _activeTaunt = taunt;
    _tauntTick += 1;
    notifyListeners();
  }

  int get tauntTick => _tauntTick;

  void _handleNotificationTap(String? payload) {
    if (payload == null) return;
    for (final Taunt taunt in taunts.all) {
      if (taunt.id == payload) {
        _activeTaunt = taunt;
        _tauntTick += 1;
        notifyListeners();
        return;
      }
    }
  }

  // -------------------------------------------------------------- teardown ---

  Future<void> resetEverything() async {
    await _storage.resetAll();
    await _notifications.cancelAllPending();
    _settings = const AppSettings();
    _profile = UserProfile.guest;
    activity.load();
    notifyListeners();
  }

  @override
  void dispose() {
    _source.dispose();
    super.dispose();
  }
}
