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
    final colorScheme = ColorScheme.fromSeed(seedColor: Colors.teal);

    return MaterialApp(
      title: 'Islamic Kit Example',
      theme: ThemeData(
        colorScheme: colorScheme,
        useMaterial3: true,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      debugShowCheckedModeBanner: false,
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
          actions: [
            IconButton(
              tooltip: 'About this app',
              onPressed: () => _showAboutSheet(context),
              icon: const Icon(Icons.info_outline),
            ),
          ],
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

  Future<void> _showEventNotificationDialog(BuildContext context) async {
    final nextEvent = IslamicEventService.getUpcomingReminderEvent();
    if (nextEvent == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No upcoming events are currently available.'),
        ),
      );
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Schedule a Reminder'),
        content: Text(
          'Do you want to schedule a 9:00 AM reminder for the next upcoming event: ${nextEvent.name}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final result =
                  await ReminderScheduler.scheduleEventReminder(nextEvent);
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(result.message)));
            },
            child: const Text('Schedule'),
          ),
        ],
      ),
    );
  }

  void _showAboutSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return const SafeArea(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Islamic Kit Example',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 12),
                Text(
                  'Explore prayer times, Hijri dates, Qibla guidance, Islamic events, and zakat calculations in one sample app.',
                ),
                SizedBox(height: 16),
                Text('Highlights'),
                SizedBox(height: 8),
                Text('- Prayer times with live next-prayer countdown'),
                Text('- Hijri calendar with highlighted event days'),
                Text('- Qibla guidance with compass or bearing fallback'),
                Text('- Event reminders with clearer scheduling feedback'),
                Text('- Zakat calculator with a full summary breakdown'),
              ],
            ),
          ),
        );
      },
    );
  }
}
