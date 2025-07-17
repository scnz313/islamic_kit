import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'package:islamic_kit/src/date_converter/converter.dart';
import 'package:islamic_kit/src/events/islamic_event_service.dart';

/// A service to schedule local notifications for Islamic events.
class ReminderScheduler {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// Initializes the notification service.
  /// Returns true if initialization was successful, false otherwise.
  static Future<bool> initialize() async {
    try {
      tz.initializeTimeZones();
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true,
          );

      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      final bool? initialized = await _notificationsPlugin.initialize(initializationSettings);
      return initialized ?? false;
    } catch (e) {
      // Log error in production apps
      return false;
    }
  }

  /// Requests notification permissions (mainly for iOS).
  static Future<bool> requestPermissions() async {
    try {
      final bool? result = await _notificationsPlugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Schedules a notification for a given [IslamicEvent].
  /// Returns true if the notification was scheduled successfully.
  static Future<bool> scheduleNotification(IslamicEvent event) async {
    try {
      final gregorianDate = IslamicDateConverter.hijriToGregorian(
          event.date.hYear, event.date.hMonth, event.date.hDay);

      // Schedule the notification for 9 AM on the day of the event.
      final scheduledDate = tz.TZDateTime.from(gregorianDate, tz.local)
          .add(const Duration(hours: 9));

      // Don't schedule notifications for past dates
      if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) {
        return false;
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
        event.hashCode, // Use a unique ID for the notification
        'Upcoming Islamic Event',
        'Today is ${event.name}',
        scheduledDate,
        platformChannelSpecifics,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dateAndTime,
      );
      return true;
    } catch (e) {
      // Log error in production apps
      return false;
    }
  }
}
