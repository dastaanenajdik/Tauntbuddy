import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_settings.dart';
import '../models/focus_session.dart';
import '../models/tracking.dart';
import '../models/study_task.dart';
import '../models/user_profile.dart';

/// Thin, typed wrapper around [SharedPreferences].
///
/// All persistence goes through this one class so that:
/// * every read is defensive (a corrupt value never crashes a screen),
/// * the "reset app" action is a single call,
/// * and the data shape can be unit tested without a widget tree.
class StorageService {
  StorageService._(this._prefs);

  final SharedPreferences _prefs;

  static const String _kThemeMode = 'tb.themeMode';
  static const String _kProfile = 'tb.profile';
  static const String _kSettings = 'tb.settings';
  static const String _kSessions = 'tb.sessions';
  static const String _kGoals = 'tb.goals';
  static const String _kMoods = 'tb.moods';
  static const String _kTasks = 'tb.tasks';
  static const String _kSubjects = 'tb.subjects';
  static const String _kFavourites = 'tb.favouriteTaunts';
  static const String _kSeenTaunts = 'tb.seenTaunts';
  static const String _kTauntCache = 'tb.tauntCache';
  static const String _kQuoteCache = 'tb.quoteCache';
  static const String _kBadges = 'tb.unlockedBadges';

  static Future<StorageService> open() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return StorageService._(prefs);
  }

  SharedPreferences get raw => _prefs;

  // ---------------------------------------------------------------- theme ---

  ThemeMode readThemeMode() {
    switch (_prefs.getString(_kThemeMode)) {
      case 'dark':
        return ThemeMode.dark;
      case 'light':
        return ThemeMode.light;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> writeThemeMode(ThemeMode mode) =>
      _prefs.setString(_kThemeMode, mode.name);

  // -------------------------------------------------------------- profile ---

  UserProfile readProfile() {
    final Map<String, dynamic>? json = _readMap(_kProfile);
    if (json == null) return UserProfile.guest;
    return UserProfile.fromJson(json);
  }

  Future<void> writeProfile(UserProfile profile) =>
      _writeMap(_kProfile, profile.toJson());

  // ------------------------------------------------------------- settings ---

  AppSettings readSettings() {
    final Map<String, dynamic>? json = _readMap(_kSettings);
    if (json == null) return const AppSettings();
    return AppSettings.fromJson(json);
  }

  Future<void> writeSettings(AppSettings settings) =>
      _writeMap(_kSettings, settings.toJson());

  // ------------------------------------------------------------- sessions ---

  List<FocusSession> readSessions() =>
      _readList(_kSessions, FocusSession.fromJson);

  Future<void> writeSessions(List<FocusSession> sessions) =>
      _writeList(_kSessions, sessions.map((FocusSession s) => s.toJson()).toList());

  // ---------------------------------------------------------------- goals ---

  List<DailyGoal> readGoals() => _readList(_kGoals, DailyGoal.fromJson);

  Future<void> writeGoals(List<DailyGoal> goals) =>
      _writeList(_kGoals, goals.map((DailyGoal g) => g.toJson()).toList());

  // ---------------------------------------------------------------- moods ---

  List<MoodEntry> readMoods() => _readList(_kMoods, MoodEntry.fromJson);

  Future<void> writeMoods(List<MoodEntry> moods) =>
      _writeList(_kMoods, moods.map((MoodEntry m) => m.toJson()).toList());

  // ---------------------------------------------------------------- tasks ---

  List<StudyTask> readTasks() => _readList(_kTasks, StudyTask.fromJson);

  Future<void> writeTasks(List<StudyTask> tasks) =>
      _writeList(_kTasks, tasks.map((StudyTask t) => t.toJson()).toList());

  // ------------------------------------------------------------- subjects ---

  List<SyllabusSubject> readSubjects() =>
      _readList(_kSubjects, SyllabusSubject.fromJson);

  Future<void> writeSubjects(List<SyllabusSubject> subjects) =>
      _writeList(_kSubjects, subjects.map((SyllabusSubject s) => s.toJson()).toList());

  // ----------------------------------------------------- taunt favourites ---

  Set<String> readFavouriteTaunts() =>
      _prefs.getStringList(_kFavourites)?.toSet() ?? <String>{};

  Future<void> writeFavouriteTaunts(Set<String> ids) =>
      _prefs.setStringList(_kFavourites, ids.toList(growable: false));

  /// Taunt ids already shown, so the engine rotates instead of repeating.
  Set<String> readSeenTaunts() =>
      _prefs.getStringList(_kSeenTaunts)?.toSet() ?? <String>{};

  Future<void> writeSeenTaunts(Set<String> ids) {
    // Keep the memory bounded; older ids simply become eligible again.
    final List<String> bounded = ids.length <= 60 ? ids.toList() : ids.toList().sublist(ids.length - 60);
    return _prefs.setStringList(_kSeenTaunts, bounded);
  }

  // ------------------------------------------------------------ datasets ---

  Map<String, dynamic>? readTauntCache() => _readMap(_kTauntCache);
  Future<void> writeTauntCache(Map<String, dynamic> json) => _writeMap(_kTauntCache, json);

  Map<String, dynamic>? readQuoteCache() => _readMap(_kQuoteCache);
  Future<void> writeQuoteCache(Map<String, dynamic> json) => _writeMap(_kQuoteCache, json);

  // --------------------------------------------------------------- badges ---

  Set<String> readUnlockedBadges() =>
      _prefs.getStringList(_kBadges)?.toSet() ?? <String>{};

  Future<void> writeUnlockedBadges(Set<String> ids) =>
      _prefs.setStringList(_kBadges, ids.toList(growable: false));

  // ---------------------------------------------------------------- utils ---

  Future<void> resetAll() async {
    for (final String key in <String>[
      _kProfile,
      _kSettings,
      _kSessions,
      _kGoals,
      _kMoods,
      _kTasks,
      _kSubjects,
      _kFavourites,
      _kSeenTaunts,
      _kTauntCache,
      _kQuoteCache,
      _kBadges,
    ]) {
      await _prefs.remove(key);
    }
  }

  Map<String, dynamic>? _readMap(String key) {
    final String? value = _prefs.getString(key);
    if (value == null || value.isEmpty) return null;
    try {
      final Object? decoded = jsonDecode(value);
      if (decoded is Map<String, dynamic>) return decoded;
      return null;
    } on FormatException {
      return null;
    }
  }

  List<T> _readList<T>(String key, T Function(Map<String, dynamic>) build) {
    final String? value = _prefs.getString(key);
    if (value == null || value.isEmpty) return <T>[];
    try {
      final Object? decoded = jsonDecode(value);
      if (decoded is! List) return <T>[];
      return decoded.whereType<Map<String, dynamic>>().map(build).toList();
    } on FormatException {
      return <T>[];
    }
  }

  Future<void> _writeMap(String key, Map<String, dynamic> value) =>
      _prefs.setString(key, jsonEncode(value));

  Future<void> _writeList(String key, List<Map<String, dynamic>> value) =>
      _prefs.setString(key, jsonEncode(value));
}
