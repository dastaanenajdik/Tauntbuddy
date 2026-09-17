import 'dart:math' as math;

/// Why a taunt fired. The reminder engine and the in-app "next taunt" picker
/// both select by trigger, which is how the same dataset serves notifications,
/// mascot bubbles and the Taunt Vault.
enum TauntTrigger {
  onboarding,
  morning,
  afternoon,
  evening,
  night,
  idle,
  streakLost,
  goalMissed,
  sessionEnd,
  breakOver,
  examSoon,
  kavachBreak,
  comeback,
  milestone,
  manual;

  /// JSON key used inside `assets/data/taunts.json`.
  String get key {
    switch (this) {
      case TauntTrigger.onboarding:
        return 'onboarding';
      case TauntTrigger.morning:
        return 'morning';
      case TauntTrigger.afternoon:
        return 'afternoon';
      case TauntTrigger.evening:
        return 'evening';
      case TauntTrigger.night:
        return 'night';
      case TauntTrigger.idle:
        return 'idle';
      case TauntTrigger.streakLost:
        return 'streak_lost';
      case TauntTrigger.goalMissed:
        return 'goal_missed';
      case TauntTrigger.sessionEnd:
        return 'session_end';
      case TauntTrigger.breakOver:
        return 'break_over';
      case TauntTrigger.examSoon:
        return 'exam_soon';
      case TauntTrigger.kavachBreak:
        return 'kavach_break';
      case TauntTrigger.comeback:
        return 'comeback';
      case TauntTrigger.milestone:
        return 'milestone';
      case TauntTrigger.manual:
        return 'manual';
    }
  }

  /// Human label used in the Taunt Vault filters.
  String get label {
    switch (this) {
      case TauntTrigger.onboarding:
        return 'Onboarding';
      case TauntTrigger.morning:
        return 'Morning';
      case TauntTrigger.afternoon:
        return 'Afternoon';
      case TauntTrigger.evening:
        return 'Evening';
      case TauntTrigger.night:
        return 'Night';
      case TauntTrigger.idle:
        return 'Idle';
      case TauntTrigger.streakLost:
        return 'Streak risk';
      case TauntTrigger.goalMissed:
        return 'Goal missed';
      case TauntTrigger.sessionEnd:
        return 'Session end';
      case TauntTrigger.breakOver:
        return 'Break over';
      case TauntTrigger.examSoon:
        return 'Exam soon';
      case TauntTrigger.kavachBreak:
        return 'Kavach break';
      case TauntTrigger.comeback:
        return 'Comeback';
      case TauntTrigger.milestone:
        return 'Milestone';
      case TauntTrigger.manual:
        return 'Manual';
    }
  }

  static TauntTrigger fromKey(String? key) {
    final String value = (key ?? '').trim().toLowerCase();
    for (final TauntTrigger trigger in TauntTrigger.values) {
      if (trigger.key == value) return trigger;
    }
    return TauntTrigger.manual;
  }
}

/// Where a taunt came from — surfaced in the Taunt Vault so the user can see
/// the ifallertzia server sync actually doing something.
enum TauntSource { bundled, remote }

/// One taunt line, optionally with a device-local favourite flag.
class Taunt {
  const Taunt({
    required this.id,
    required this.text,
    required this.category,
    required this.trigger,
    required this.severity,
    this.tags = const <String>[],
    this.packId = 'core-roasts',
    this.packTitle = 'Core Roasts',
    this.source = TauntSource.bundled,
  });

  final String id;
  final String text;
  final String category;
  final TauntTrigger trigger;

  /// 1 = gentle nudge, 2 = judgemental, 3 = full hamster rage.
  final int severity;
  final List<String> tags;
  final String packId;
  final String packTitle;
  final TauntSource source;

  bool get isRoast => severity >= 3;

  /// Emoji prefix chosen from the category so notifications look playful
  /// without the dataset having to carry one per row.
  String get emoji {
    switch (category) {
      case 'procrastination':
        return '😭';
      case 'focus':
        return '🎯';
      case 'exam':
        return '📚';
      case 'streak':
        return '🔥';
      case 'kavach':
        return '🛡️';
      case 'wellbeing':
        return '🧘';
      case 'routine':
        return '⏰';
      case 'screen':
        return '📱';
      case 'social':
        return '👥';
      case 'comeback':
        return '🚀';
      case 'gamification':
        return '🏅';
      case 'attendance':
        return '🎓';
      default:
        return '🐹';
    }
  }

  factory Taunt.fromJson(
    Map<String, dynamic> json, {
    String packId = 'core-roasts',
    String packTitle = 'Core Roasts',
    TauntSource source = TauntSource.bundled,
  }) {
    return Taunt(
      id: (json['id'] as String?) ?? 'taunt-${json.hashCode}',
      text: (json['text'] as String?) ?? '',
      category: (json['category'] as String?) ?? 'focus',
      trigger: TauntTrigger.fromKey(json['trigger'] as String?),
      severity: ((json['severity'] as num?)?.toInt() ?? 1).clamp(1, 3),
      tags: (json['tags'] as List<dynamic>?)
              ?.map((dynamic e) => e.toString())
              .toList(growable: false) ??
          const <String>[],
      packId: packId,
      packTitle: packTitle,
      source: source,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'text': text,
        'category': category,
        'trigger': trigger.key,
        'severity': severity,
        'tags': tags,
      };

  /// Preview text for the compact in-app taunt banner.
  String get shortText => text.length <= 96 ? text : '${text.substring(0, 93)}...';

  Taunt copyWith({
    String? packId,
    String? packTitle,
    TauntSource? source,
    int? severity,
  }) {
    return Taunt(
      id: id,
      text: text,
      category: category,
      trigger: trigger,
      severity: severity ?? this.severity,
      tags: tags,
      packId: packId ?? this.packId,
      packTitle: packTitle ?? this.packTitle,
      source: source ?? this.source,
    );
  }

  @override
  bool operator ==(Object other) => other is Taunt && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// A themed group of taunts inside the JSON dataset.
class TauntPack {
  const TauntPack({
    required this.id,
    required this.title,
    required this.description,
    required this.taunts,
  });

  final String id;
  final String title;
  final String description;
  final List<Taunt> taunts;

  factory TauntPack.fromJson(Map<String, dynamic> json) {
    final String id = (json['id'] as String?) ?? 'pack';
    final String title = (json['title'] as String?) ?? 'Pack';
    final List<dynamic> raw = (json['taunts'] as List<dynamic>?) ?? const <dynamic>[];
    return TauntPack(
      id: id,
      title: title,
      description: (json['description'] as String?) ?? '',
      taunts: raw
          .whereType<Map<String, dynamic>>()
          .map((Map<String, dynamic> t) => Taunt.fromJson(
                t,
                packId: id,
                packTitle: title,
              ))
          .toList(growable: false),
    );
  }
}

/// The complete taunt dataset. Parsed from a bundled asset **or** fetched from
/// ifallertzia server raw — the shape is identical so the repository can swap sources
/// without touching UI code.
class TauntDataset {
  const TauntDataset({
    required this.schemaVersion,
    required this.packs,
    this.updatedAt,
    this.source = TauntSource.bundled,
  });

  final int schemaVersion;
  final List<TauntPack> packs;
  final String? updatedAt;
  final TauntSource source;

  static const TauntDataset empty = TauntDataset(schemaVersion: 1, packs: <TauntPack>[]);

  List<Taunt> get all => packs
      .expand((TauntPack pack) => pack.taunts.map((Taunt t) => t.copyWith(source: source)))
      .toList(growable: false);

  int get length => packs.fold(0, (int sum, TauntPack p) => sum + p.taunts.length);

  bool get isEmpty => length == 0;

  List<String> get categories => all
      .map((Taunt t) => t.category)
      .toSet()
      .toList(growable: false)
    ..sort();

  /// All taunts matching any of [triggers], ordered by severity (soft first when
  /// [gentle] is true) so the engine can escalate through the day.
  List<Taunt> byTriggers(List<TauntTrigger> triggers, {bool gentle = true}) {
    final List<Taunt> matches = all
        .where((Taunt t) => triggers.contains(t.trigger))
        .toList(growable: true);
    matches.sort((Taunt a, Taunt b) =>
        gentle ? a.severity.compareTo(b.severity) : b.severity.compareTo(a.severity));
    return matches;
  }

  /// Deterministic pick so the same day/time slot always yields the same line
  /// (no "same taunt twice in a row" bug after a rebuild).
  Taunt? pick({
    required List<TauntTrigger> triggers,
    int? seed,
    int maxSeverity = 3,
    Set<String> excludeIds = const <String>{},
  }) {
    List<Taunt> pool = byTriggers(triggers)
        .where((Taunt t) => t.severity <= maxSeverity && !excludeIds.contains(t.id))
        .toList(growable: true);
    if (pool.isEmpty) {
      pool = byTriggers(triggers).where((Taunt t) => !excludeIds.contains(t.id)).toList();
    }
    if (pool.isEmpty) pool = all.toList();
    if (pool.isEmpty) return null;
    final int index = seed == null ? math.Random().nextInt(pool.length) : seed.abs() % pool.length;
    return pool[index];
  }

  factory TauntDataset.fromJson(
    Map<String, dynamic> json, {
    TauntSource source = TauntSource.bundled,
  }) {
    final List<dynamic> packs = (json['packs'] as List<dynamic>?) ?? const <dynamic>[];
    return TauntDataset(
      schemaVersion: (json['schemaVersion'] as num?)?.toInt() ?? 1,
      updatedAt: json['updatedAt'] as String?,
      source: source,
      packs: packs
          .whereType<Map<String, dynamic>>()
          .map(TauntPack.fromJson)
          .toList(growable: false),
    );
  }
}
