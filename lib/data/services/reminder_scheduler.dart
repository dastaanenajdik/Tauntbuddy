import 'package:flutter/foundation.dart';
import 'package:timezone/timezone.dart' as tz;

import '../models/app_settings.dart';
import '../models/taunt.dart';
import 'notification_service.dart';

/// One taunt slot the app wants the OS to fire.
class ScheduledTaunt {
  const ScheduledTaunt({
    required this.id,
    required this.hour,
    required this.minute,
    required this.taunt,
  });

  /// Stable notification id per slot so rescheduling replaces instead of piling up.
  final int id;
  final int hour;
  final int minute;
  final Taunt taunt;
}

/// Result of a reschedule pass, shown in Settings → Notifications.
class ScheduleReport {
  const ScheduleReport({
    required this.scheduled,
    required this.message,
    this.cleared = 0,
  });

  final int scheduled;
  final int cleared;
  final String message;
}

/// Turns the current taunt plan into real OS notifications.
///
/// Scheduling strategy:
/// * every slot is an `inexactAllowWhileIdle` daily repeat — no exact-alarm
///   permission prompts on Android 13+, and battery friendly,
/// * all slots share the `tauntbuddy_taunts` channel so the user can silence
///   the hamster without losing their other reminders,
/// * the plan itself (which taunt for which hour) is built by [AppState], which
///   is the only place that knows the streak, goals and severity cap.
class ReminderScheduler {
  ReminderScheduler({required NotificationService notifications})
      : _notifications = notifications;

  final NotificationService _notifications;

  /// Notification ids reserved for the daily taunt slots.
  static const List<int> slotIds = <int>[9001, 9002, 9003, 9004, 9005, 9006];

  /// Converts a device-local wall clock time into the UTC instant the plugin
  /// should target, rolling over to tomorrow when the time has already passed.
  ///
  /// The tz database is pinned to UTC (see [NotificationService._initTimezones]),
  /// so converting here — instead of trusting `tz.local` — keeps reminders
  /// firing at the intended local clock time with no extra plugin dependency.
  static tz.TZDateTime nextInstance(int hour, int minute, {DateTime? now}) {
    final DateTime localNow = now ?? DateTime.now();
    final DateTime targetLocal = DateTime(
      localNow.year,
      localNow.month,
      localNow.day,
      hour,
      minute,
    );
    final DateTime targetUtcWallClock = targetLocal.subtract(localNow.timeZoneOffset);
    tz.TZDateTime scheduled = tz.TZDateTime.utc(
      targetUtcWallClock.year,
      targetUtcWallClock.month,
      targetUtcWallClock.day,
      targetUtcWallClock.hour,
      targetUtcWallClock.minute,
    );
    if (!scheduled.isAfter(tz.TZDateTime.now(tz.UTC))) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  /// Applies [plan] and clears any leftover slots.
  Future<ScheduleReport> apply(
    List<ScheduledTaunt> plan, {
    required bool soundEnabled,
    bool enabled = true,
  }) async {
    await _notifications.cancelAllPending();
    if (!enabled || plan.isEmpty) {
      return ScheduleReport(
        scheduled: 0,
        cleared: plan.length,
        message: enabled
            ? 'No taunt slots configured.'
            : 'Taunt notifications are switched off.',
      );
    }

    int scheduled = 0;
    for (final ScheduledTaunt slot in plan) {
      try {
        await _notifications.scheduleDailyTaunt(
          id: slot.id,
          scheduledDate: nextInstance(slot.hour, slot.minute),
          title: 'TauntBuddy 🐹',
          body: slot.taunt.text,
          severity: slot.taunt.severity,
          payload: slot.taunt.id,
          sound: soundEnabled,
        );
        scheduled += 1;
      } catch (e) {
        debugPrint('TauntBuddy scheduler: slot ${slot.id} failed ($e)');
      }
    }

    return ScheduleReport(
      scheduled: scheduled,
      message: scheduled == 0
          ? 'Could not schedule taunts on this platform.'
          : '$scheduled taunt${scheduled == 1 ? '' : 's'} scheduled. Fear the hamster.',
    );
  }

  /// Builds the daily plan: one taunt per configured hour, escalating in
  /// severity through the day so mornings stay polite and nights get spicy.
  List<ScheduledTaunt> buildPlan({
    required AppSettings settings,
    required TauntDataset dataset,
    Set<String> excludeIds = const <String>{},
    DateTime? now,
  }) {
    final List<int> hours = settings.reminderHours;
    if (hours.isEmpty || dataset.isEmpty) return const <ScheduledTaunt>[];

    final List<ScheduledTaunt> plan = <ScheduledTaunt>[];
    final Set<String> used = <String>{...excludeIds};
    final DateTime reference = now ?? DateTime.now();

    for (int i = 0; i < hours.length && i < slotIds.length; i++) {
      final int hour = hours[i];
      final bool isLate = hour >= 20 || hour < 6;
      final List<TauntTrigger> triggers = <TauntTrigger>[
        if (hour < 12) TauntTrigger.morning,
        if (hour >= 12 && hour < 17) TauntTrigger.afternoon,
        if (hour >= 17 && hour < 21) TauntTrigger.evening,
        if (isLate) TauntTrigger.night,
        TauntTrigger.idle,
        TauntTrigger.goalMissed,
        TauntTrigger.streakLost,
      ];

      // Escalate severity: first slot of the day stays gentle.
      final int severityCap = i == 0
          ? settings.severityCap.clamp(1, 2).toInt()
          : settings.severityCap;

      final Taunt? taunt = dataset.pick(
        triggers: triggers,
        seed: reference.day * 100 + i,
        maxSeverity: severityCap,
        excludeIds: used,
      );
      if (taunt == null) continue;
      used.add(taunt.id);
      plan.add(
        ScheduledTaunt(
          id: slotIds[i],
          hour: hour,
          minute: settings.dailyReminderMinute,
          taunt: taunt,
        ),
      );
    }
    return plan;
  }
}
