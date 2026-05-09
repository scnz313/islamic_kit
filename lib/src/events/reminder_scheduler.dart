import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'package:islamic_kit/src/events/islamic_event_service.dart';
import 'package:islamic_kit/src/hijri_calendar/hijri_service.dart';

/// Schedules local notifications for Islamic events.
///
/// Call [initialize] once at app startup (ideally after
/// `WidgetsFlutterBinding.ensureInitialized()`) before scheduling any
/// reminders. Use [requestPermissions] to prompt the user for permission on
/// iOS and Android 13+.
///
/// Reminders are scheduled in the local timezone by default. Apps that
/// target users across multiple regions (e.g. a travel app that pins
/// reminders to the user's home city) can pass a specific
/// [tz.Location] to [scheduleNotification] via the `location` parameter or
/// set a process-wide default with [setDefaultLocation].
class ReminderScheduler {
  ReminderScheduler._();

  /// The default time of day at which event reminders fire (local time).
  static const Duration defaultReminderTimeOfDay = Duration(hours: 9);

  /// The Android notification channel id.
  static const String channelId = 'islamic_events_channel';

  /// The Android notification channel name.
  static const String channelName = 'Islamic Events';

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static tz.Location? _defaultLocation;

  /// Whether [initialize] has completed successfully at least once.
  @visibleForTesting
  static bool get isInitialized => _initialized;

  /// The [tz.Location] used by default when scheduling reminders.
  ///
  /// Defaults to [tz.local]. Apps can override this via [setDefaultLocation].
  static tz.Location get defaultLocation => _defaultLocation ?? tz.local;

  /// Sets the process-wide default timezone used when scheduling reminders.
  ///
  /// Pass `null` to revert to `tz.local`.
  static void setDefaultLocation(tz.Location? location) {
    _defaultLocation = location;
  }

  /// Test-only: reset the cached initialization state and default location.
  @visibleForTesting
  static void debugReset() {
    _initialized = false;
    _defaultLocation = null;
  }

  /// Initializes the notification plugin and the timezone database.
  ///
  /// Returns `true` on success. Safe to call multiple times — subsequent
  /// calls are no-ops.
  static Future<bool> initialize() async {
    if (_initialized) return true;
    try {
      tz.initializeTimeZones();
      const androidInit =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosInit = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      const settings = InitializationSettings(
        android: androidInit,
        iOS: iosInit,
      );
      final ok = await _plugin.initialize(settings);
      _initialized = ok ?? false;
      return _initialized;
    } catch (_) {
      _initialized = false;
      return false;
    }
  }

  /// Requests notification permissions on iOS and Android 13+.
  ///
  /// Returns `true` if the user granted permission (or the platform does
  /// not require it).
  static Future<bool> requestPermissions() async {
    try {
      final iosGranted = await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      final androidGranted = await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();

      // If neither platform implementation is registered (e.g. tests), treat
      // as granted.
      if (iosGranted == null && androidGranted == null) return true;
      return (iosGranted ?? true) && (androidGranted ?? true);
    } catch (_) {
      return false;
    }
  }

  /// Computes a stable, non-negative notification id for [event].
  @visibleForTesting
  static int notificationIdFor(IslamicEvent event) {
    // Combine year/month/day/name to avoid collisions across years.
    final key = '${event.date.hYear}-${event.date.hMonth}-'
        '${event.date.hDay}-${event.name}';
    // Fold into a non-negative 31-bit int so it fits Android's notification
    // id constraints.
    return key.hashCode & 0x7fffffff;
  }

  /// Computes the [tz.TZDateTime] at which a reminder for [event] should
  /// fire, for the given [reminderTimeOfDay] and [location].
  ///
  /// Exposed for testability — the scheduling call itself requires a live
  /// platform backend that's not available in unit tests, but the time
  /// calculation is pure.
  @visibleForTesting
  static tz.TZDateTime resolveScheduledDate(
    IslamicEvent event, {
    Duration reminderTimeOfDay = defaultReminderTimeOfDay,
    tz.Location? location,
  }) {
    final gregorian = HijriService.toGregorian(
      event.date.hYear,
      event.date.hMonth,
      event.date.hDay,
    );
    return tz.TZDateTime(
      location ?? defaultLocation,
      gregorian.year,
      gregorian.month,
      gregorian.day,
      reminderTimeOfDay.inHours,
      reminderTimeOfDay.inMinutes % 60,
    );
  }

  /// Schedules a notification for [event] at [reminderTimeOfDay] on the
  /// event's Gregorian date, in the given [location] (defaults to
  /// [defaultLocation]).
  ///
  /// Returns `true` if the notification was scheduled. Returns `false` if:
  ///   - the event's date is in the past, or
  ///   - the notification plugin failed to schedule.
  static Future<bool> scheduleNotification(
    IslamicEvent event, {
    Duration reminderTimeOfDay = defaultReminderTimeOfDay,
    tz.Location? location,
  }) async {
    try {
      if (!_initialized) {
        final ok = await initialize();
        if (!ok) return false;
      }

      final effectiveLocation = location ?? defaultLocation;
      final scheduledDate = resolveScheduledDate(
        event,
        reminderTimeOfDay: reminderTimeOfDay,
        location: effectiveLocation,
      );
      if (scheduledDate.isBefore(tz.TZDateTime.now(effectiveLocation))) {
        return false;
      }

      const androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: 'Channel for Islamic event reminders',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: false,
      );
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _plugin.zonedSchedule(
        notificationIdFor(event),
        'Upcoming Islamic Event',
        'Today is ${event.name}',
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Cancels the scheduled reminder for [event], if any.
  static Future<void> cancelNotification(IslamicEvent event) async {
    try {
      await _plugin.cancel(notificationIdFor(event));
    } catch (_) {
      // Swallow errors: cancelling a non-existent notification is a no-op.
    }
  }

  /// Cancels all pending reminders scheduled by this scheduler.
  static Future<void> cancelAll() async {
    try {
      await _plugin.cancelAll();
    } catch (_) {
      // Swallow — cancellation is best-effort.
    }
  }
}
