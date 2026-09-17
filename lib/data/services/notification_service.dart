import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Android notification channels created once at startup.
class NotificationChannels {
  const NotificationChannels._();

  /// Taunts fired by the reminder engine.
  static const String taunts = 'tauntbuddy_taunts';

  /// Streak / goal / exam nudges.
  static const String reminders = 'tauntbuddy_reminders';

  /// KAVACH shield status (persistent while a session is running).
  static const String kavach = 'tauntbuddy_kavach';
}

/// Cross-platform smart-taunt notifications.
///
/// Supports Android, iOS, macOS, Linux, Windows and Web through
/// `flutter_local_notifications` 22.x. Every platform-specific call is guarded,
/// so an unsupported platform degrades to an in-app taunt banner instead of
/// crashing the app.
class NotificationService {
  NotificationService({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;
  bool _timezonesReady = false;

  /// Called when the user taps a taunt notification.
  void Function(String? payload)? onTauntTapped;

  bool get isInitialized => _initialized;

  /// Prepares the plugin. Safe to call repeatedly.
  Future<void> init() async {
    if (_initialized) return;
    _initTimezones();

    const InitializationSettings settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestSoundPermission: false,
        requestBadgePermission: false,
      ),
      macOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestSoundPermission: false,
        requestBadgePermission: false,
      ),
      linux: LinuxInitializationSettings(defaultActionName: 'Open TauntBuddy'),
      web: WebInitializationSettings(),
    );

    try {
      await _plugin.initialize(
        settings: settings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          onTauntTapped?.call(response.payload);
        },
      );
      _initialized = true;
      await _createChannels();
    } catch (e) {
      debugPrint('TauntBuddy notifications: init failed ($e)');
      _initialized = false;
    }
  }

  void _initTimezones() {
    if (_timezonesReady) return;
    tzdata.initializeTimeZones();
    // TauntBuddy schedules in wall-clock terms. We pin the tz database to UTC
    // and convert the device-local target time into UTC ourselves (see
    // ReminderScheduler.nextInstance) which keeps the maths dependency-free and
    // exact for fixed-offset zones (IST included).
    tz.setLocalLocation(tz.getLocation('UTC'));
    _timezonesReady = true;
  }

  Future<void> _createChannels() async {
    final AndroidFlutterLocalNotificationsPlugin? android =
        _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return;
    try {
      await android.createNotificationChannel(
        const AndroidNotificationChannel(
          NotificationChannels.taunts,
          'Hamster taunts',
          description: 'Witty taunts that pull you back to your books.',
          importance: Importance.high,
        ),
      );
      await android.createNotificationChannel(
        const AndroidNotificationChannel(
          NotificationChannels.reminders,
          'Study reminders',
          description: 'Streak, goal and exam reminders.',
          importance: Importance.defaultImportance,
        ),
      );
      await android.createNotificationChannel(
        const AndroidNotificationChannel(
          NotificationChannels.kavach,
          'KAVACH shield',
          description: 'Shows while a focus shield session is running.',
          importance: Importance.low,
        ),
      );
    } catch (e) {
      debugPrint('TauntBuddy notifications: channel setup failed ($e)');
    }
  }

  /// Asks the OS for permission. Returns `true` when notifications may be shown.
  ///
  /// On Android < 13 and on desktop the request is a no-op and the current
  /// state is reported instead.
  Future<bool> requestPermission() async {
    await init();
    try {
      final AndroidFlutterLocalNotificationsPlugin? android =
          _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        final bool? granted = await android.requestNotificationsPermission();
        return granted ?? await areEnabled();
      }

      final IOSFlutterLocalNotificationsPlugin? ios =
          _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      if (ios != null) {
        final bool? granted = await ios.requestPermissions(alert: true, badge: true, sound: true);
        return granted ?? true;
      }
    } catch (e) {
      debugPrint('TauntBuddy notifications: permission request failed ($e)');
    }
    return areEnabled();
  }

  /// Current permission state without prompting.
  Future<bool> areEnabled() async {
    await init();
    try {
      final AndroidFlutterLocalNotificationsPlugin? android =
          _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        return await android.areNotificationsEnabled() ?? true;
      }
      final IOSFlutterLocalNotificationsPlugin? ios =
          _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      if (ios != null) {
        final NotificationsEnabledOptions? options = await ios.checkPermissions();
        return options?.isEnabled ?? true;
      }
    } catch (e) {
      debugPrint('TauntBuddy notifications: permission check failed ($e)');
    }
    // Web, Linux and Windows report as enabled; the platform itself decides.
    return true;
  }

  /// Opens the OS notification settings for TauntBuddy.
  Future<void> openSystemSettings() async {
    await init();
    try {
      await _plugin.openAppNotificationSettings();
    } catch (e) {
      debugPrint('TauntBuddy notifications: open settings failed ($e)');
    }
  }

  NotificationDetails _details({required int severity, bool sound = true}) {
    final Importance importance = severity >= 3
        ? Importance.max
        : severity == 2
            ? Importance.high
            : Importance.defaultImportance;
    final Priority priority = severity >= 3
        ? Priority.max
        : severity == 2
            ? Priority.high
            : Priority.defaultPriority;

    return NotificationDetails(
      android: AndroidNotificationDetails(
        NotificationChannels.taunts,
        'Hamster taunts',
        channelDescription: 'Witty taunts that pull you back to your books.',
        importance: importance,
        priority: priority,
        playSound: sound,
        color: const Color(0xFFA855F7),
        category: AndroidNotificationCategory.reminder,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.timeSensitive,
      ),
      macOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  /// Immediate taunt notification ("test ping" from the Taunt Vault).
  Future<void> showTaunt({
    required int id,
    required String title,
    required String body,
    int severity = 2,
    String? payload,
    bool sound = true,
  }) async {
    await init();
    try {
      await _plugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: _details(severity: severity, sound: sound),
        payload: payload,
      );
    } catch (e) {
      debugPrint('TauntBuddy notifications: show failed ($e)');
    }
  }

  /// Daily repeating taunt at [scheduledDate].
  Future<void> scheduleDailyTaunt({
    required int id,
    required tz.TZDateTime scheduledDate,
    required String title,
    required String body,
    int severity = 2,
    String? payload,
    bool repeatDaily = true,
    bool sound = true,
  }) async {
    await init();
    try {
      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        notificationDetails: _details(severity: severity, sound: sound),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: repeatDaily ? DateTimeComponents.time : null,
        payload: payload,
      );
    } catch (e) {
      debugPrint('TauntBuddy notifications: schedule failed ($e)');
    }
  }

  Future<void> cancel(int id) async {
    try {
      await _plugin.cancel(id: id);
    } catch (e) {
      debugPrint('TauntBuddy notifications: cancel failed ($e)');
    }
  }

  /// Removes every pending taunt (used when notifications are switched off).
  Future<void> cancelAllPending() async {
    try {
      await _plugin.cancelAllPendingNotifications();
    } catch (e) {
      debugPrint('TauntBuddy notifications: cancelAll failed ($e)');
    }
  }

  Future<int> pendingCount() async {
    try {
      final List<PendingNotificationRequest> pending =
          await _plugin.pendingNotificationRequests();
      return pending.length;
    } catch (e) {
      return 0;
    }
  }
}
