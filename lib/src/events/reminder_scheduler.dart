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
  static Future<void> initialize() async {
    tz.initializeTimeZones();
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _notificationsPlugin.initialize(initializationSettings);
  }

  /// Schedules a notification for a given [IslamicEvent].
  static Future<void> scheduleNotification(IslamicEvent event) async {
    final gregorianDate = IslamicDateConverter.hijriToGregorian(
        event.date.hYear, event.date.hMonth, event.date.hDay);

    // Schedule the notification for 9 AM on the day of the event.
    final scheduledDate = tz.TZDateTime.from(gregorianDate, tz.local)
        .add(const Duration(hours: 9));

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'islamic_events_channel',
      'Islamic Events',
      channelDescription: 'Channel for Islamic event reminders',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

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
  }
}
