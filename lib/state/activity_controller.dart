import 'package:flutter/foundation.dart';

import '../core/utils/app_date_utils.dart';
import '../data/models/catalog.dart';
import '../data/models/focus_session.dart';
import '../data/models/study_task.dart';
import '../data/models/tracking.dart';
import '../data/repositories/activity_repository.dart';

/// Reactive wrapper around [ActivityRepository].
///
/// Repositories stay pure (easy to unit test); controllers are the things the
/// widget tree listens to.
class ActivityController extends ChangeNotifier {
  ActivityController(this._repository);

  final ActivityRepository _repository;

  ActivityRepository get repository => _repository;

  List<FocusSession> get sessions => _repository.sessions;
  List<DailyGoal> get goals => _repository.goals;
  List<StudyTask> get tasks => _repository.tasks;
  List<SyllabusSubject> get subjects => _repository.subjects;
  List<FocusSession> get recentSessions => _repository.recentSessions;
  List<StudyTask> get upcomingTasks => _repository.upcomingTasks;

  DayKey get today => DayKey.today();

  DaySummary todaySummary() => _repository.summarize(today);

  List<DailyGoal> goalsOn(DayKey day) => _repository.goalsOn(day);
  List<StudyTask> tasksOn(DayKey day) => _repository.tasksOn(day);
  List<FocusSession> sessionsOn(DayKey day) => _repository.sessionsOn(day);
  MoodEntry? moodOn(DayKey day) => _repository.moodOn(day);

  AnalyticsSnapshot snapshot({int windowDays = 30}) =>
      _repository.snapshot(windowDays: windowDays);

  Map<DayKey, int> focusByDay({int windowDays = 14}) =>
      _repository.focusMinutesByDay(windowDays: windowDays);

  List<double> moodTrend({int windowDays = 14}) => _repository.moodTrend(windowDays: windowDays);

  int get streak => StreakCalculator.currentStreak(_repository.activeDays());
  int get longestStreak => StreakCalculator.longestStreak(_repository.activeDays());
  int get totalFocusMinutes => _repository.totalFocusMinutes;
  int get totalSessions => _repository.totalSessions;
  double get syllabusProgress => _repository.syllabusProgress;
  SyllabusSubject? get nextExam => _repository.nextExam;

  Map<String, int> badgeMetricValues(Iterable<BadgeDefinition> badges) =>
      _repository.metricValuesFor(badges);

  Set<String> satisfiedBadges(Iterable<BadgeDefinition> badges) =>
      _repository.satisfiedBadges(badges);

  bool get isSlackingToday => _repository.isSlackingToday;

  // ----------------------------------------------------------- mutations ---

  Future<void> addSession(FocusSession session) async {
    await _repository.addSession(session);
    notifyListeners();
  }

  Future<void> deleteSession(String id) async {
    await _repository.deleteSession(id);
    notifyListeners();
  }

  Future<void> ensureTodayGoals() async {
    await _repository.ensureGoalsForToday();
    notifyListeners();
  }

  Future<void> addGoal(String title, {String accent = 'violet', String category = 'study'}) async {
    await _repository.addGoal(
      DailyGoal(
        id: 'goal-${DateTime.now().microsecondsSinceEpoch}',
        title: title.trim(),
        day: today,
        accent: accent,
        category: category,
      ),
    );
    notifyListeners();
  }

  Future<void> toggleGoal(String id) async {
    await _repository.toggleGoal(id);
    notifyListeners();
  }

  Future<void> deleteGoal(String id) async {
    await _repository.deleteGoal(id);
    notifyListeners();
  }

  Future<void> setMood(MoodOption mood, {String note = ''}) async {
    await _repository.setMood(
      MoodEntry(day: today, moodId: mood.id, score: mood.score, note: note),
    );
    notifyListeners();
  }

  Future<void> addTask({
    required String title,
    required StudyTaskKind kind,
    required DayKey day,
    String subject = 'General',
    int estimatedMinutes = 45,
    int priority = 2,
    String notes = '',
  }) async {
    await _repository.addTask(
      StudyTask(
        id: 'task-${DateTime.now().microsecondsSinceEpoch}',
        title: title.trim(),
        kind: kind,
        day: day,
        subject: subject,
        estimatedMinutes: estimatedMinutes,
        priority: priority,
        notes: notes,
      ),
    );
    notifyListeners();
  }

  Future<void> toggleTask(String id) async {
    await _repository.toggleTask(id);
    notifyListeners();
  }

  Future<void> deleteTask(String id) async {
    await _repository.deleteTask(id);
    notifyListeners();
  }

  Future<void> upsertSubject(SyllabusSubject subject) async {
    await _repository.upsertSubject(subject);
    notifyListeners();
  }

  Future<void> addSubject({
    required String name,
    required int totalUnits,
    DateTime? examDate,
    String accent = 'violet',
  }) async {
    await _repository.upsertSubject(
      SyllabusSubject(
        id: 'sub-${DateTime.now().microsecondsSinceEpoch}',
        name: name.trim(),
        totalUnits: totalUnits,
        examDate: examDate,
        accent: accent,
      ),
    );
    notifyListeners();
  }

  Future<void> bumpUnit(String id, int delta) async {
    await _repository.bumpUnit(id, delta);
    notifyListeners();
  }

  Future<void> deleteSubject(String id) async {
    await _repository.deleteSubject(id);
    notifyListeners();
  }
}
