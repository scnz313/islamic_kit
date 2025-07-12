import 'package:flutter/material.dart';
import 'package:islamic_kit/islamic_kit.dart';

// Before running, ensure you have configured platform-specific settings
// for geolocator and flutter_local_notifications (AndroidManifest.xml and Info.plist).

void main() async {
  // Required for plugins
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the notification scheduler
  await ReminderScheduler.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Islamic Kit Example',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const ExampleHomePage(),
    );
  }
}

class ExampleHomePage extends StatelessWidget {
  const ExampleHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Islamic Kit Example'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(icon: Icon(Icons.access_time), text: 'Prayer Times'),
              Tab(icon: Icon(Icons.calendar_month), text: 'Hijri Calendar'),
              Tab(icon: Icon(Icons.explore), text: 'Qibla Compass'),
              Tab(icon: Icon(Icons.event), text: 'Islamic Events'),
              Tab(icon: Icon(Icons.calculate), text: 'Zakat Calculator'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            // Prayer Times Widget
            PrayerTimeWidget(),

            // Hijri Calendar Widget
            HijriCalendarWidget(),

            // Qibla Compass Widget
            QiblaCompassWidget(),

            // Islamic Events Widget
            IslamicEventsWidget(),

            // Zakat Calculator Widget
            ZakatCalculatorWidget(),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showEventNotificationDialog(context),
          label: const Text('Test Notifications'),
          icon: const Icon(Icons.notifications_active),
        ),
      ),
    );
  }

  void _showEventNotificationDialog(BuildContext context) {
    final nextEvent = IslamicEventService.getEventsForYear(HijriCalendar.now().hYear).firstWhere(
      (event) => IslamicDateConverter.hijriToGregorian(event.date.hYear, event.date.hMonth, event.date.hDay).isAfter(DateTime.now()),
      orElse: () => IslamicEvent('Next Year Event', HijriCalendar()..hYear = HijriCalendar.now().hYear + 1..hMonth = 1..hDay = 1),
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Schedule a Reminder'),
        content: Text('Do you want to schedule a reminder for the next upcoming event: ${nextEvent.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ReminderScheduler.scheduleNotification(nextEvent);
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notification scheduled!')),
              );
            },
            child: const Text('Schedule'),
          ),
        ],
      ),
    );
  }
}
