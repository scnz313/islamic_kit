import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'package:islamic_kit/src/events/islamic_event_service.dart';

/// The outcome of a reminder scheduling action.
class ReminderScheduleResult {
  /// Creates a [ReminderScheduleResult].
  const ReminderScheduleResult({
    required this.isSuccess,
    required this.message,
  });

  /// Whether the action succeeded.
  final bool isSuccess;

  /// A user-friendly status message.
  final String message;
}

/// A service to schedule local notifications for Islamic events.
class ReminderScheduler {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static bool _isInitialized = false;
  static Future<bool>? _initializationFuture;

  /// Initializes the notification service.
  /// Returns true if initialization was successful, false otherwise.
  static Future<bool> initialize() async {
    if (_isInitialized) {
      return true;
    }
    if (_initializationFuture != null) {
      return _initializationFuture!;
    }

    _initializationFuture = _initializeInternal();
    final initialized = await _initializationFuture!;
    _initializationFuture = null;
    return initialized;
  }

  static Future<bool> _initializeInternal() async {
    try {
      tz.initializeTimeZones();
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          );

      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      final bool? initialized = await _notificationsPlugin.initialize(initializationSettings);
      _isInitialized = initialized ?? false;
      return _isInitialized;
    } catch (e) {
      _isInitialized = false;
      return false;
    }
  }

  /// Requests notification permissions on supported platforms.
  static Future<bool> requestPermissions() async {
    try {
      final initialized = await initialize();
      if (!initialized) {
        return false;
      }

      final androidImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        final alreadyGranted =
            (await androidImplementation.areNotificationsEnabled()) ?? false;
        if (alreadyGranted) {
          return true;
        }
        return (await androidImplementation.requestNotificationsPermission()) ??
            false;
      }

      final iosImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      if (iosImplementation != null) {
        return (await iosImplementation.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            )) ??
            false;
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Schedules a notification for a given [IslamicEvent] and returns details
  /// about the outcome.
  static Future<ReminderScheduleResult> scheduleEventReminder(
    IslamicEvent event,
  ) async {
    try {
      final initialized = await initialize();
      if (!initialized) {
        return const ReminderScheduleResult(
          isSuccess: false,
          message:
              'Reminders are unavailable because notifications could not be initialized.',
        );
      }

      final permissionsGranted = await requestPermissions();
      if (!permissionsGranted) {
        return const ReminderScheduleResult(
          isSuccess: false,
          message:
              'Notification permission is required before a reminder can be scheduled.',
        );
      }

      if (!event.canScheduleReminder()) {
        return ReminderScheduleResult(
          isSuccess: false,
          message: 'The reminder time for ${event.name} has already passed.',
        );
      }

      // Convert the local 9:00 AM reminder time into an absolute UTC instant so
      // a one-off reminder stays stable without relying on the device timezone
      // being configured in the timezone package.
      final scheduledLocalDate = event.reminderTime();
      final scheduledDate =
          tz.TZDateTime.from(scheduledLocalDate.toUtc(), tz.UTC);
      final now = tz.TZDateTime.from(DateTime.now().toUtc(), tz.UTC);

      if (!scheduledDate.isAfter(now)) {
        return ReminderScheduleResult(
          isSuccess: false,
          message: 'The date for ${event.name} has already passed this year.',
        );
      }

      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'islamic_events_channel',
        'Islamic Events',
        channelDescription: 'Channel for Islamic event reminders',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: false,
      );

      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails platformChannelSpecifics =
          NotificationDetails(
            android: androidPlatformChannelSpecifics,
            iOS: iOSPlatformChannelSpecifics,
          );

      await _notificationsPlugin.zonedSchedule(
        notificationIdForEvent(event),
        event.name,
        event.isEstimated
            ? '${event.name} is approaching. Local moon sighting may affect the observed date.'
            : 'Today is ${event.name}.',
        scheduledDate,
        platformChannelSpecifics,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      return ReminderScheduleResult(
        isSuccess: true,
        message: 'Reminder scheduled for ${event.name} at 9:00 AM.',
      );
    } catch (e) {
      return const ReminderScheduleResult(
        isSuccess: false,
        message:
            'The reminder could not be scheduled right now. Please try again.',
      );
    }
  }

  /// Schedules a notification for a given [IslamicEvent].
  /// Returns true if the notification was scheduled successfully.
  static Future<bool> scheduleNotification(IslamicEvent event) async {
    final result = await scheduleEventReminder(event);
    return result.isSuccess;
  }

  /// Returns a deterministic notification ID for the provided [event].
  static int notificationIdForEvent(IslamicEvent event) {
    final source = event.id;
    var hash = 5381;
    for (final codeUnit in source.codeUnits) {
      hash = ((hash << 5) + hash) ^ codeUnit;
    }
    return hash & 0x7fffffff;
  }
}
