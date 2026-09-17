import 'package:flutter/foundation.dart';

import '../../core/utils/app_date_utils.dart';
import '../models/catalog.dart';
import '../models/focus_session.dart';
import '../models/study_task.dart';
import '../models/tracking.dart';
import '../services/storage_service.dart';

/// The numbers shown in the Monthly Snapshot card and the Analytics screen.
@immutable
class AnalyticsSnapshot {
  const AnalyticsSnapshot({
    required this.windowDays,
    required this.focusMinutes,
    required this.dhyanMinutes,
    required this.sessions,
    required this.completedSessions,
    required this.activeDays,
    required this.currentStreak,
    required this.longestStreak,
    required this.goalsDone,
    required this.goalsTotal,
    required this.kavachSessions,
    required this.depthScore,
    required this.moodAverage,
    required this.bestDayMinutes,
  });

  final int windowDays;
  final int focusMinutes;
  final int dhyanMinutes;
  final int sessions;
  final int completedSessions;
  final int activeDays;
  final int currentStreak;
  final int longestStreak;
  final int goalsDone;
  final int goalsTotal;
  final int kavachSessions;
  final int depthScore;
  final double moodAverage;
  final int bestDayMinutes;

  /// Share of days in the window with at least one focused session.
  double get consistency => AppDateUtils.ratio(activeDays, windowDays);

  /// Share of sessions that ran to completion.
  double get completionRate => AppDateUtils.ratio(completedSessions, sessions);

  /// Average Focus Score (quality-weighted minutes) per day.
  double get avgDepthPerDay =>
      windowDays == 0 ? 0 : AppDateUtils.oneDecimal(depthScore / windowDays);

  double get avgFocusPerActiveDay =>
      activeDays == 0 ? 0 : AppDateUtils.oneDecimal(focusMinutes / activeDays);

  static const AnalyticsSnapshot empty = AnalyticsSnapshot(
    windowDays: 30,
    focusMinutes: 0,
    dhyanMinutes: 0,
    sessions: 0,
    completedSessions: 0,
    activeDays: 0,
    currentStreak: 0,
    longestStreak: 0,
    goalsDone: 0,
    goalsTotal: 0,
    kavachSessions: 0,
    depthScore: 0,
    moodAverage: 0,
    bestDayMinutes: 0,
  );
}

/// Single source of truth for everything the user *does* in TauntBuddy:
/// focus sessions, mindful sessions, goals, moods, planner tasks and syllabus.
///
/// Pure data + maths — no `notifyListeners()` here. The state layer wraps this
/// so that analytics can also be unit tested against a fake storage.
class ActivityRepository {
  ActivityRepository({required StorageService storage}) : _storage = storage;

  final StorageService _storage;

  List<FocusSession> _sessions = <FocusSession>[];
  List<DailyGoal> _goals = <DailyGoal>[];
  List<MoodEntry> _moods = <MoodEntry>[];
  List<StudyTask> _tasks = <StudyTask>[];
  List<SyllabusSubject> _subjects = <SyllabusSubject>[];

  List<FocusSession> get sessions => List<FocusSession>.unmodifiable(_sessions);
  List<DailyGoal> get goals => List<DailyGoal>.unmodifiable(_goals);
  List<MoodEntry> get moods => List<MoodEntry>.unmodifiable(_moods);
  List<StudyTask> get tasks => List<StudyTask>.unmodifiable(_tasks);
  List<SyllabusSubject> get subjects => List<SyllabusSubject>.unmodifiable(_subjects);

  void load() {
    _sessions = _storage.readSessions();
    _goals = _storage.readGoals();
    _moods = _storage.readMoods();
    _tasks = _storage.readTasks();
    _subjects = _storage.readSubjects();
  }

  // ------------------------------------------------------------- sessions ---

  Future<void> addSession(FocusSession session) async {
    _sessions = <FocusSession>[..._sessions, session];
    await _storage.writeSessions(_sessions);
  }

  Future<void> deleteSession(String id) async {
    _sessions = _sessions.where((FocusSession s) => s.id != id).toList(growable: false);
    await _storage.writeSessions(_sessions);
  }

  List<FocusSession> sessionsOn(DayKey day) =>
      _sessions.where((FocusSession s) => s.day == day).toList(growable: false)
        ..sort((FocusSession a, FocusSession b) => b.startedAt.compareTo(a.startedAt));

  List<FocusSession> get recentSessions {
    final List<FocusSession> sorted = <FocusSession>[..._sessions]
      ..sort((FocusSession a, FocusSession b) => b.startedAt.compareTo(a.startedAt));
    return sorted.take(30).toList(growable: false);
  }

  /// Minutes focused per day for the analytics bar chart.
  Map<DayKey, int> focusMinutesByDay({int windowDays = 30}) {
    final List<DayKey> window = AppDateUtils.lastDays(windowDays);
    final Map<DayKey, int> result = <DayKey, int>{
      for (final DayKey day in window) day: 0,
    };
    for (final FocusSession session in _sessions) {
      if (!result.containsKey(session.day)) continue;
      result[session.day] = (result[session.day] ?? 0) + session.actualMinutes;
    }
    return result;
  }

  // ---------------------------------------------------------------- goals ---

  List<DailyGoal> goalsOn(DayKey day) =>
      _goals.where((DailyGoal g) => g.day == day).toList(growable: false);

  /// Goals for today, seeding a starter set the first time a day is opened.
  Future<List<DailyGoal>> ensureGoalsForToday() async {
    final DayKey today = DayKey.today();
    final List<DailyGoal> existing = goalsOn(today);
    if (existing.isNotEmpty) return existing;
    final List<DailyGoal> seeded = DailyGoal.starter(day: today);
    _goals = <DailyGoal>[..._goals, ...seeded];
    await _storage.writeGoals(_goals);
    return seeded;
  }

  Future<void> addGoal(DailyGoal goal) async {
    _goals = <DailyGoal>[..._goals, goal];
    await _storage.writeGoals(_goals);
  }

  Future<void> toggleGoal(String id) async {
    _goals = _goals
        .map((DailyGoal g) => g.id == id ? g.copyWith(done: !g.done) : g)
        .toList(growable: false);
    await _storage.writeGoals(_goals);
  }

  Future<void> deleteGoal(String id) async {
    _goals = _goals.where((DailyGoal g) => g.id != id).toList(growable: false);
    await _storage.writeGoals(_goals);
  }

  // ---------------------------------------------------------------- moods ---

  MoodEntry? moodOn(DayKey day) {
    for (final MoodEntry entry in _moods) {
      if (entry.day == day) return entry;
    }
    return null;
  }

  Future<void> setMood(MoodEntry entry) async {
    _moods = <MoodEntry>[
      ..._moods.where((MoodEntry m) => m.day != entry.day),
      entry,
    ];
    await _storage.writeMoods(_moods);
  }

  /// Mood score per day (oldest first) for the wellbeing sparkline.
  List<double> moodTrend({int windowDays = 14}) {
    final List<DayKey> window = AppDateUtils.lastDays(windowDays);
    return window.map((DayKey day) => (moodOn(day)?.score ?? 0).toDouble()).toList(growable: false);
  }

  // ---------------------------------------------------------------- tasks ---

  List<StudyTask> tasksOn(DayKey day) =>
      _tasks.where((StudyTask t) => t.day == day).toList(growable: false)
        ..sort((StudyTask a, StudyTask b) => b.priority.compareTo(a.priority));

  List<StudyTask> get upcomingTasks {
    final DayKey today = DayKey.today();
    final List<StudyTask> upcoming = _tasks
        .where((StudyTask t) => !t.done && t.day.daysUntil(today) <= 0)
        .toList(growable: true)
      ..sort((StudyTask a, StudyTask b) => a.day.id.compareTo(b.day.id));
    return upcoming.take(12).toList(growable: false);
  }

  Future<void> addTask(StudyTask task) async {
    _tasks = <StudyTask>[..._tasks, task];
    await _storage.writeTasks(_tasks);
  }

  Future<void> toggleTask(String id) async {
    _tasks = _tasks
        .map((StudyTask t) => t.id == id ? t.copyWith(done: !t.done) : t)
        .toList(growable: false);
    await _storage.writeTasks(_tasks);
  }

  Future<void> deleteTask(String id) async {
    _tasks = _tasks.where((StudyTask t) => t.id != id).toList(growable: false);
    await _storage.writeTasks(_tasks);
  }

  // ------------------------------------------------------------- subjects ---

  Future<void> upsertSubject(SyllabusSubject subject) async {
    final List<SyllabusSubject> next = <SyllabusSubject>[..._subjects];
    final int index = next.indexWhere((SyllabusSubject s) => s.id == subject.id);
    if (index >= 0) {
      next[index] = subject;
    } else {
      next.add(subject);
    }
    _subjects = next;
    await _storage.writeSubjects(_subjects);
  }

  Future<void> deleteSubject(String id) async {
    _subjects = _subjects.where((SyllabusSubject s) => s.id != id).toList(growable: false);
    await _storage.writeSubjects(_subjects);
  }

  Future<void> bumpUnit(String id, int delta) async {
    for (final SyllabusSubject subject in _subjects) {
      if (subject.id != id) continue;
      final int next = (subject.completedUnits + delta).clamp(0, subject.totalUnits);
      await upsertSubject(subject.copyWith(completedUnits: next));
      return;
    }
  }

  /// Nearest exam across the syllabus (drives the dashboard countdown and the
  /// "exam soon" taunt trigger).
  SyllabusSubject? get nextExam {
    SyllabusSubject? best;
    for (final SyllabusSubject subject in _subjects) {
      if (subject.examDate == null) continue;
      if (best == null || subject.daysToExam < best.daysToExam) {
        if (subject.daysToExam >= 0) best = subject;
      }
    }
    return best;
  }

  double get syllabusProgress {
    if (_subjects.isEmpty) return 0;
    final int total = _subjects.fold(0, (int sum, SyllabusSubject s) => sum + s.totalUnits);
    final int done = _subjects.fold(0, (int sum, SyllabusSubject s) => sum + s.completedUnits);
    return AppDateUtils.ratio(done, total);
  }

  // ------------------------------------------------------- analytics core ---

  Set<DayKey> activeDays() => _sessions
      .where((FocusSession s) => s.actualMinutes > 0)
      .map((FocusSession s) => s.day)
      .toSet();

  int minutesOn(DayKey day, {SessionKind? kind}) => _sessions
      .where((FocusSession s) => s.day == day && (kind == null || s.kind == kind))
      .fold(0, (int sum, FocusSession s) => sum + s.actualMinutes);

  int depthOn(DayKey day) => _sessions
      .where((FocusSession s) => s.day == day)
      .fold(0, (int sum, FocusSession s) => sum + s.depthScore);

  DaySummary summarize(DayKey day) {
    final List<FocusSession> todays =
        _sessions.where((FocusSession s) => s.day == day).toList(growable: false);
    final List<DailyGoal> goals = goalsOn(day);
    return DaySummary(
      day: day,
      focusMinutes: todays
          .where((FocusSession s) => s.kind == SessionKind.ekagra)
          .fold(0, (int sum, FocusSession s) => sum + s.actualMinutes),
      dhyanMinutes: todays
          .where((FocusSession s) => s.kind == SessionKind.dhyan)
          .fold(0, (int sum, FocusSession s) => sum + s.actualMinutes),
      depthScore: todays.fold(0, (int sum, FocusSession s) => sum + s.depthScore),
      sessions: todays.length,
      completedSessions: todays.where((FocusSession s) => s.completed).length,
      goalsDone: goals.where((DailyGoal g) => g.done).length,
      goalsTotal: goals.length,
      kavachBreaches: todays.fold(0, (int sum, FocusSession s) => sum + s.kavachBreaches),
    );
  }

  AnalyticsSnapshot snapshot({int windowDays = 30}) {
    final List<DayKey> window = AppDateUtils.lastDays(windowDays);
    final Set<DayKey> windowSet = window.toSet();

    final List<FocusSession> scoped = _sessions
        .where((FocusSession s) => windowSet.contains(s.day))
        .toList(growable: false);

    int focusMinutes = 0;
    int dhyanMinutes = 0;
    int depth = 0;
    int kavachSessions = 0;
    final Map<DayKey, int> perDay = <DayKey, int>{};

    for (final FocusSession session in scoped) {
      if (session.kind == SessionKind.dhyan) {
        dhyanMinutes += session.actualMinutes;
      } else {
        focusMinutes += session.actualMinutes;
      }
      depth += session.depthScore;
      if (session.label.toLowerCase().contains('kavach')) kavachSessions += 1;
      perDay[session.day] = (perDay[session.day] ?? 0) + session.actualMinutes;
    }

    final List<DailyGoal> goalWindow =
        _goals.where((DailyGoal g) => windowSet.contains(g.day)).toList(growable: false);

    final List<MoodEntry> moodWindow =
        _moods.where((MoodEntry m) => windowSet.contains(m.day)).toList(growable: false);

    final double moodAverage = moodWindow.isEmpty
        ? 0
        : AppDateUtils.oneDecimal(
            moodWindow.fold(0, (int sum, MoodEntry m) => sum + m.score) / moodWindow.length,
          );

    final Set<DayKey> active = activeDays();

    return AnalyticsSnapshot(
      windowDays: windowDays,
      focusMinutes: focusMinutes,
      dhyanMinutes: dhyanMinutes,
      sessions: scoped.length,
      completedSessions: scoped.where((FocusSession s) => s.completed).length,
      activeDays: active.where(windowSet.contains).length,
      currentStreak: StreakCalculator.currentStreak(active),
      longestStreak: StreakCalculator.longestStreak(active),
      goalsDone: goalWindow.where((DailyGoal g) => g.done).length,
      goalsTotal: goalWindow.length,
      kavachSessions: kavachSessions,
      depthScore: depth,
      moodAverage: moodAverage,
      bestDayMinutes: perDay.isEmpty
          ? 0
          : perDay.values.reduce((int a, int b) => a > b ? a : b),
    );
  }

  /// Lifetime focus minutes, used for levels and the leaderboard estimate.
  int get totalFocusMinutes => _sessions
      .where((FocusSession s) => s.kind == SessionKind.ekagra)
      .fold(0, (int sum, FocusSession s) => sum + s.actualMinutes);

  int get totalSessions => _sessions.length;

  // ------------------------------------------------------------- badges -----

  /// Current value for a badge metric key.
  int metricValue(String metric) {
    final Set<DayKey> active = activeDays();
    switch (metric) {
      case 'sessions':
        return _sessions.where((FocusSession s) => s.kind == SessionKind.ekagra).length;
      case 'focus_minutes':
        return totalFocusMinutes;
      case 'streak':
        return StreakCalculator.currentStreak(active);
      case 'dhyan_sessions':
        return _sessions.where((FocusSession s) => s.kind == SessionKind.dhyan).length;
      case 'early_sessions':
        return _sessions.where((FocusSession s) => s.startedAt.hour < 7).length;
      case 'late_sessions':
        return _sessions.where((FocusSession s) => s.startedAt.hour >= 22).length;
      case 'goals_done':
        return _goals.where((DailyGoal g) => g.done).length;
      case 'mood_checkins':
        return _moods.length;
      case 'kavach_sessions':
        return _sessions
            .where((FocusSession s) => s.label.toLowerCase().contains('kavach'))
            .length;
      default:
        return 0;
    }
  }

  Map<String, int> metricValuesFor(Iterable<BadgeDefinition> badges) {
    final Map<String, int> values = <String, int>{};
    for (final BadgeDefinition badge in badges) {
      values.putIfAbsent(badge.metric, () => metricValue(badge.metric));
    }
    return values;
  }

  /// Badges that are currently satisfied (used for the unlock celebration).
  Set<String> satisfiedBadges(Iterable<BadgeDefinition> badges) {
    final Set<String> result = <String>{};
    for (final BadgeDefinition badge in badges) {
      if (metricValue(badge.metric) >= badge.threshold) result.add(badge.id);
    }
    return result;
  }

  // -------------------------------------------------------------- helpers ---

  bool get isEmpty => _sessions.isEmpty && _goals.isEmpty && _tasks.isEmpty;

  /// True when today has no focused minutes yet — the taunt engine reads this
  /// to decide between a friendly nudge and a full roast.
  bool get isSlackingToday => minutesOn(DayKey.today(), kind: SessionKind.ekagra) == 0;
}
