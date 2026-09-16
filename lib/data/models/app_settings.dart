/// Everything the user can configure, persisted as a single JSON blob.
///
/// Kept as one immutable object so "reset app data" and export/import are
/// trivial, and so the settings screen can diff old vs new in one place.
class AppSettings {
  const AppSettings({
    this.notificationsEnabled = false,
    this.notificationsAsked = false,
    this.tauntIntensity = 2,
    this.dailyReminderHour = 20,
    this.dailyReminderMinute = 30,
    this.remindersPerDay = 3,
    this.morningReminder = true,
    this.eveningReminder = true,
    this.streakAlerts = true,
    this.examAlerts = true,
    this.moodReminder = true,
    this.dhyanReminder = false,
    this.weeklyDigest = true,
    this.soundEnabled = true,
    this.hapticsEnabled = true,
    this.kavachAutoStart = true,
    this.kavachStrict = false,
    this.leaderboardOptIn = false,
    this.analyticsOptIn = true,
    this.keepScreenOn = true,
    this.tauntRepoUrl =
        'https://raw.githubusercontent.com/dastaanenajdik/Tauntbuddy/main/assets/data/taunts.json',
    this.lastSyncAt,
    this.lastSyncCount = 0,
    this.onboardingDone = false,
    this.pomodoroFocusMinutes = 25,
    this.pomodoroShortBreakMinutes = 5,
    this.pomodoroLongBreakMinutes = 15,
    this.pomodoroRounds = 4,
    this.dailyFocusGoalMinutes = 120,
    this.proUnlocked = false,
  });

  /// Master switch for the smart taunt notifications.
  final bool notificationsEnabled;

  /// True once the app has asked the OS for permission (so we ask only once
  /// and fall back to a settings CTA afterwards).
  final bool notificationsAsked;

  /// 1 = polite, 2 = judgemental, 3 = ruthless. Caps taunt severity.
  final int tauntIntensity;
  final int dailyReminderHour;
  final int dailyReminderMinute;
  final int remindersPerDay;
  final bool morningReminder;
  final bool eveningReminder;
  final bool streakAlerts;
  final bool examAlerts;
  final bool moodReminder;
  final bool dhyanReminder;
  final bool weeklyDigest;
  final bool soundEnabled;
  final bool hapticsEnabled;
  final bool kavachAutoStart;
  final bool kavachStrict;
  final bool leaderboardOptIn;
  final bool analyticsOptIn;
  final bool keepScreenOn;

  /// GitHub raw URL used to refresh the taunt dataset.
  final String tauntRepoUrl;
  final DateTime? lastSyncAt;
  final int lastSyncCount;
  final bool onboardingDone;

  final int pomodoroFocusMinutes;
  final int pomodoroShortBreakMinutes;
  final int pomodoroLongBreakMinutes;
  final int pomodoroRounds;

  final int dailyFocusGoalMinutes;
  final bool proUnlocked;

  /// How many taunts a day the scheduler is allowed to fire.
  int get effectiveReminders {
    if (!notificationsEnabled) return 0;
    return remindersPerDay.clamp(0, 6);
  }

  /// The hours at which the daily taunt slots fire.
  List<int> get reminderHours {
    final int count = effectiveReminders;
    if (count <= 0) return const <int>[];
    if (count == 1) return <int>[dailyReminderHour];
    if (count == 2) return <int>[8, dailyReminderHour];
    if (count == 3) return <int>[8, 15, dailyReminderHour];
    return <int>[7, 11, 15, 19, dailyReminderHour, 22].take(count).toList(growable: false);
  }

  int get severityCap {
    switch (tauntIntensity.clamp(1, 3)) {
      case 1:
        return 1;
      case 2:
        return 2;
      default:
        return 3;
    }
  }

  String get intensityLabel {
    switch (tauntIntensity.clamp(1, 3)) {
      case 1:
        return 'Polite';
      case 2:
        return 'Judgemental';
      default:
        return 'Ruthless';
    }
  }

  AppSettings copyWith({
    bool? notificationsEnabled,
    bool? notificationsAsked,
    int? tauntIntensity,
    int? dailyReminderHour,
    int? dailyReminderMinute,
    int? remindersPerDay,
    bool? morningReminder,
    bool? eveningReminder,
    bool? streakAlerts,
    bool? examAlerts,
    bool? moodReminder,
    bool? dhyanReminder,
    bool? weeklyDigest,
    bool? soundEnabled,
    bool? hapticsEnabled,
    bool? kavachAutoStart,
    bool? kavachStrict,
    bool? leaderboardOptIn,
    bool? analyticsOptIn,
    bool? keepScreenOn,
    String? tauntRepoUrl,
    DateTime? lastSyncAt,
    int? lastSyncCount,
    bool? onboardingDone,
    int? pomodoroFocusMinutes,
    int? pomodoroShortBreakMinutes,
    int? pomodoroLongBreakMinutes,
    int? pomodoroRounds,
    int? dailyFocusGoalMinutes,
    bool? proUnlocked,
  }) {
    return AppSettings(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      notificationsAsked: notificationsAsked ?? this.notificationsAsked,
      tauntIntensity: tauntIntensity ?? this.tauntIntensity,
      dailyReminderHour: dailyReminderHour ?? this.dailyReminderHour,
      dailyReminderMinute: dailyReminderMinute ?? this.dailyReminderMinute,
      remindersPerDay: remindersPerDay ?? this.remindersPerDay,
      morningReminder: morningReminder ?? this.morningReminder,
      eveningReminder: eveningReminder ?? this.eveningReminder,
      streakAlerts: streakAlerts ?? this.streakAlerts,
      examAlerts: examAlerts ?? this.examAlerts,
      moodReminder: moodReminder ?? this.moodReminder,
      dhyanReminder: dhyanReminder ?? this.dhyanReminder,
      weeklyDigest: weeklyDigest ?? this.weeklyDigest,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      kavachAutoStart: kavachAutoStart ?? this.kavachAutoStart,
      kavachStrict: kavachStrict ?? this.kavachStrict,
      leaderboardOptIn: leaderboardOptIn ?? this.leaderboardOptIn,
      analyticsOptIn: analyticsOptIn ?? this.analyticsOptIn,
      keepScreenOn: keepScreenOn ?? this.keepScreenOn,
      tauntRepoUrl: tauntRepoUrl ?? this.tauntRepoUrl,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      lastSyncCount: lastSyncCount ?? this.lastSyncCount,
      onboardingDone: onboardingDone ?? this.onboardingDone,
      pomodoroFocusMinutes: pomodoroFocusMinutes ?? this.pomodoroFocusMinutes,
      pomodoroShortBreakMinutes: pomodoroShortBreakMinutes ?? this.pomodoroShortBreakMinutes,
      pomodoroLongBreakMinutes: pomodoroLongBreakMinutes ?? this.pomodoroLongBreakMinutes,
      pomodoroRounds: pomodoroRounds ?? this.pomodoroRounds,
      dailyFocusGoalMinutes: dailyFocusGoalMinutes ?? this.dailyFocusGoalMinutes,
      proUnlocked: proUnlocked ?? this.proUnlocked,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'notificationsEnabled': notificationsEnabled,
        'notificationsAsked': notificationsAsked,
        'tauntIntensity': tauntIntensity,
        'dailyReminderHour': dailyReminderHour,
        'dailyReminderMinute': dailyReminderMinute,
        'remindersPerDay': remindersPerDay,
        'morningReminder': morningReminder,
        'eveningReminder': eveningReminder,
        'streakAlerts': streakAlerts,
        'examAlerts': examAlerts,
        'moodReminder': moodReminder,
        'dhyanReminder': dhyanReminder,
        'weeklyDigest': weeklyDigest,
        'soundEnabled': soundEnabled,
        'hapticsEnabled': hapticsEnabled,
        'kavachAutoStart': kavachAutoStart,
        'kavachStrict': kavachStrict,
        'leaderboardOptIn': leaderboardOptIn,
        'analyticsOptIn': analyticsOptIn,
        'keepScreenOn': keepScreenOn,
        'tauntRepoUrl': tauntRepoUrl,
        'lastSyncAt': lastSyncAt?.toIso8601String(),
        'lastSyncCount': lastSyncCount,
        'onboardingDone': onboardingDone,
        'pomodoroFocusMinutes': pomodoroFocusMinutes,
        'pomodoroShortBreakMinutes': pomodoroShortBreakMinutes,
        'pomodoroLongBreakMinutes': pomodoroLongBreakMinutes,
        'pomodoroRounds': pomodoroRounds,
        'dailyFocusGoalMinutes': dailyFocusGoalMinutes,
        'proUnlocked': proUnlocked,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    bool b(String key, bool fallback) => (json[key] as bool?) ?? fallback;
    int i(String key, int fallback) => (json[key] as num?)?.toInt() ?? fallback;
    return AppSettings(
      notificationsEnabled: b('notificationsEnabled', false),
      notificationsAsked: b('notificationsAsked', false),
      tauntIntensity: i('tauntIntensity', 2),
      dailyReminderHour: i('dailyReminderHour', 20),
      dailyReminderMinute: i('dailyReminderMinute', 30),
      remindersPerDay: i('remindersPerDay', 3),
      morningReminder: b('morningReminder', true),
      eveningReminder: b('eveningReminder', true),
      streakAlerts: b('streakAlerts', true),
      examAlerts: b('examAlerts', true),
      moodReminder: b('moodReminder', true),
      dhyanReminder: b('dhyanReminder', false),
      weeklyDigest: b('weeklyDigest', true),
      soundEnabled: b('soundEnabled', true),
      hapticsEnabled: b('hapticsEnabled', true),
      kavachAutoStart: b('kavachAutoStart', true),
      kavachStrict: b('kavachStrict', false),
      leaderboardOptIn: b('leaderboardOptIn', false),
      analyticsOptIn: b('analyticsOptIn', true),
      keepScreenOn: b('keepScreenOn', true),
      tauntRepoUrl: (json['tauntRepoUrl'] as String?) ??
          'https://raw.githubusercontent.com/dastaanenajdik/Tauntbuddy/main/assets/data/taunts.json',
      lastSyncAt: json['lastSyncAt'] is String
          ? DateTime.tryParse(json['lastSyncAt'] as String)
          : null,
      lastSyncCount: i('lastSyncCount', 0),
      onboardingDone: b('onboardingDone', false),
      pomodoroFocusMinutes: i('pomodoroFocusMinutes', 25),
      pomodoroShortBreakMinutes: i('pomodoroShortBreakMinutes', 5),
      pomodoroLongBreakMinutes: i('pomodoroLongBreakMinutes', 15),
      pomodoroRounds: i('pomodoroRounds', 4),
      dailyFocusGoalMinutes: i('dailyFocusGoalMinutes', 120),
      proUnlocked: b('proUnlocked', false),
    );
  }
}
