import 'package:intl/intl.dart';

/// Date helpers shared by streaks, analytics, the timeline and the scheduler.
///
/// TauntBuddy never sends date/time maths through `DateTime` string parsing
/// twice: everything funnels through [DayKey] so a "day" means the same thing
/// in the dashboard, the analytics charts and the notification engine.
class DayKey {
  const DayKey(this.year, this.month, this.day);

  final int year;
  final int month;
  final int day;

  factory DayKey.from(DateTime date) =>
      DayKey(date.year, date.month, date.day);

  /// Today in the device's local timezone.
  factory DayKey.today() => DayKey.from(DateTime.now());

  /// Parses the compact `yyyy-MM-dd` representation used in storage.
  factory DayKey.parse(String value) {
    final List<int> parts = value
        .split('-')
        .map((String p) => int.tryParse(p) ?? 0)
        .toList(growable: false);
    if (parts.length != 3) return DayKey.today();
    return DayKey(parts[0], parts[1], parts[2]);
  }

  /// Compact storage key.
  String get id =>
      '${year.toString().padLeft(4, '0')}-'
      '${month.toString().padLeft(2, '0')}-'
      '${day.toString().padLeft(2, '0')}';

  DateTime get dateTime => DateTime(year, month, day);

  String get short => DateFormat('d MMM').format(dateTime);
  String get weekdayShort => DateFormat('EEE').format(dateTime);
  String get long => DateFormat('EEEE, d MMMM y').format(dateTime);

  /// Whole-day difference: `other - this`.
  int daysUntil(DayKey other) =>
      DayKey.from(other.dateTime).dateTime.difference(dateTime).inDays;

  DayKey add(int days) => DayKey.from(dateTime.add(Duration(days: days)));

  @override
  bool operator ==(Object other) => other is DayKey && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => id;
}

/// Utility collection for the productivity maths used across the app.
class AppDateUtils {
  const AppDateUtils._();

  /// `2030-01-05` → `5 Jan 2030`, safe against null/invalid input.
  static String prettyDate(DateTime? value, {String fallback = '—'}) {
    if (value == null) return fallback;
    return DateFormat('d MMM yyyy').format(value);
  }

  /// `09:41` clock label.
  static String clock(DateTime value) => DateFormat('HH:mm').format(value);

  /// `09:41:07` — used by the Timeline & Clock screen.
  static String clockWithSeconds(DateTime value) =>
      DateFormat('HH:mm:ss').format(value);

  /// `1h 25m` / `48m` focus duration label.
  static String durationLabel(int minutes) {
    if (minutes <= 0) return '0m';
    final int hours = minutes ~/ 60;
    final int rest = minutes % 60;
    if (hours == 0) return '${rest}m';
    if (rest == 0) return '${hours}h';
    return '${hours}h ${rest}m';
  }

  /// `02:15` countdown label for timers.
  static String countdown(Duration duration) {
    final int total = duration.inSeconds < 0 ? 0 : duration.inSeconds;
    final int minutes = total ~/ 60;
    final int seconds = total % 60;
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  /// Greeting line used on the Home screen.
  static String greeting(DateTime now) {
    final int hour = now.hour;
    if (hour < 5) return 'Still up';
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    if (hour < 21) return 'Good evening';
    return 'Good night';
  }

  /// The exact Home headline, e.g.
  /// `Good evening, Dastan. Your universe of focus awaits.`
  ///
  /// Lives here rather than in the widget so the copyed copy is unit-tested.
  static const String homeTagline = 'Your universe of focus awaits.';

  static String homeHeadline({required DateTime now, required String name}) {
    final String who = name.trim().isEmpty ? 'friend' : name.trim();
    return '${greeting(now)}, $who. $homeTagline';
  }

  /// Taunt engine time bucket — drives which taunt pack is picked.
  static String timeBucket(DateTime now) {
    final int hour = now.hour;
    if (hour < 5) return 'night';
    if (hour < 12) return 'morning';
    if (hour < 17) return 'afternoon';
    if (hour < 21) return 'evening';
    return 'night';
  }

  /// Percentage helper that never divides by zero.
  static double ratio(int part, int total) {
    if (total <= 0) return 0;
    final double value = part / total;
    return value.clamp(0, 1).toDouble();
  }

  /// Rounds to one decimal for the analytics summary cards.
  static double oneDecimal(double value) =>
      (value * 10).roundToDouble() / 10;

  /// Calendar days (inclusive) between two [DayKey]s.
  static List<DayKey> rangeInclusive(DayKey start, DayKey end) {
    final int span = start.daysUntil(end);
    if (span < 0) return const <DayKey>[];
    return List<DayKey>.generate(span + 1, (int i) => start.add(i));
  }

  /// Last [days] days ending today, oldest first. Used by the analytics charts.
  static List<DayKey> lastDays(int days, {DayKey? end}) {
    final DayKey last = end ?? DayKey.today();
    return List<DayKey>.generate(
      days,
      (int i) => last.add(-(days - 1 - i)),
    );
  }
}

/// Streak maths extracted as a pure function so it can be unit tested without
/// touching `SharedPreferences` or the clock.
class StreakCalculator {
  const StreakCalculator._();

  /// Longest run of consecutive days present in [days].
  static int currentStreak(Set<DayKey> days, {DayKey? today}) {
    if (days.isEmpty) return 0;
    final DayKey anchor = today ?? DayKey.today();
    DayKey cursor = days.contains(anchor) ? anchor : anchor.add(-1);
    if (!days.contains(cursor)) return 0;
    int streak = 0;
    while (days.contains(cursor)) {
      streak += 1;
      cursor = cursor.add(-1);
    }
    return streak;
  }

  static int longestStreak(Set<DayKey> days) {
    if (days.isEmpty) return 0;
    final List<DayKey> sorted = days.toList()..sort((DayKey a, DayKey b) => a.id.compareTo(b.id));
    int best = 1;
    int run = 1;
    for (int i = 1; i < sorted.length; i++) {
      if (sorted[i - 1].daysUntil(sorted[i]) == 1) {
        run += 1;
      } else {
        run = 1;
      }
      if (run > best) best = run;
    }
    return best;
  }
}
