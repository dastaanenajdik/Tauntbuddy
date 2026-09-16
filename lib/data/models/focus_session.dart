import '../../core/utils/app_date_utils.dart';

/// Ekagra focus vs Dhyan mindfulness — both are timed sessions but they feed
/// different analytics lanes.
enum SessionKind { ekagra, dhyan }

SessionKind sessionKindFromKey(String? key) =>
    (key ?? '').toLowerCase() == 'dhyan' ? SessionKind.dhyan : SessionKind.ekagra;

extension SessionKindX on SessionKind {
  String get key => this == SessionKind.dhyan ? 'dhyan' : 'ekagra';

  String get label => this == SessionKind.dhyan ? 'Dhyan' : 'Ekagra';

  String get emoji => this == SessionKind.dhyan ? '🧘' : '🎯';
}

/// A finished (or abandoned) timer run.
///
/// `depthScore` is TauntBuddy's own metric: minutes actually spent focused,
/// weighted by how few times the KAVACH shield was broken. It powers
/// "Ekagra Depth" on the dashboard and the analytics drill-down.
class FocusSession {
  const FocusSession({
    required this.id,
    required this.startedAt,
    required this.plannedMinutes,
    required this.actualMinutes,
    this.kind = SessionKind.ekagra,
    this.subject = '',
    this.kavachBreaches = 0,
    this.completed = true,
    this.label = '',
  });

  final String id;
  final DateTime startedAt;
  final int plannedMinutes;
  final int actualMinutes;
  final SessionKind kind;
  final String subject;
  final int kavachBreaches;
  final bool completed;
  final String label;

  DayKey get day => DayKey.from(startedAt);

  /// 0–1 quality coefficient derived from focus time vs breaches.
  double get quality {
    if (actualMinutes <= 0) return 0;
    final double base = AppDateUtils.ratio(actualMinutes, plannedMinutes <= 0 ? actualMinutes : plannedMinutes);
    final double penalty = (kavachBreaches * 0.12).clamp(0, 0.6);
    return ((base - penalty).clamp(0, 1)).toDouble();
  }

  /// Ekagra Depth for this session = minutes x quality, rounded.
  int get depthScore => (actualMinutes * quality).round();

  FocusSession copyWith({
    int? plannedMinutes,
    int? actualMinutes,
    int? kavachBreaches,
    bool? completed,
    String? subject,
    String? label,
  }) {
    return FocusSession(
      id: id,
      startedAt: startedAt,
      plannedMinutes: plannedMinutes ?? this.plannedMinutes,
      actualMinutes: actualMinutes ?? this.actualMinutes,
      kind: kind,
      subject: subject ?? this.subject,
      kavachBreaches: kavachBreaches ?? this.kavachBreaches,
      completed: completed ?? this.completed,
      label: label ?? this.label,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'startedAt': startedAt.toIso8601String(),
        'plannedMinutes': plannedMinutes,
        'actualMinutes': actualMinutes,
        'kind': kind.key,
        'subject': subject,
        'kavachBreaches': kavachBreaches,
        'completed': completed,
        'label': label,
      };

  factory FocusSession.fromJson(Map<String, dynamic> json) {
    return FocusSession(
      id: (json['id'] as String?) ?? 'session',
      startedAt: DateTime.tryParse((json['startedAt'] as String?) ?? '') ?? DateTime.now(),
      plannedMinutes: (json['plannedMinutes'] as num?)?.toInt() ?? 25,
      actualMinutes: (json['actualMinutes'] as num?)?.toInt() ?? 0,
      kind: sessionKindFromKey(json['kind'] as String?),
      subject: (json['subject'] as String?) ?? '',
      kavachBreaches: (json['kavachBreaches'] as num?)?.toInt() ?? 0,
      completed: (json['completed'] as bool?) ?? true,
      label: (json['label'] as String?) ?? '',
    );
  }
}
