import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart';

import 'package:islamic_kit/src/events/islamic_event_service.dart';
import 'package:islamic_kit/src/events/reminder_scheduler.dart';

/// Callback used by [IslamicEventsWidget] to respond to reminder taps.
typedef IslamicEventCallback = Future<void> Function(IslamicEvent event);

/// Displays a list of major Islamic events for the current Hijri year.
///
/// Each row shows the event name, Hijri date and corresponding Gregorian
/// date, plus a button to schedule a local notification reminder.
class IslamicEventsWidget extends StatefulWidget {
  /// Creates an [IslamicEventsWidget].
  ///
  /// Pass [year] to display events for a specific Hijri year. Defaults to
  /// the current Hijri year.
  ///
  /// Pass [onReminderTap] to override the default behaviour (scheduling a
  /// local notification via [ReminderScheduler]). Useful for tests.
  const IslamicEventsWidget({
    super.key,
    this.year,
    this.onReminderTap,
  });

  /// Hijri year to display. Defaults to the current year.
  final int? year;

  /// Optional override for the reminder tap handler. Defaults to scheduling
  /// a local notification via [ReminderScheduler].
  final IslamicEventCallback? onReminderTap;

  @override
  State<IslamicEventsWidget> createState() => _IslamicEventsWidgetState();
}

class _IslamicEventsWidgetState extends State<IslamicEventsWidget> {
  late final List<IslamicEvent> _events;

  @override
  void initState() {
    super.initState();
    final year = widget.year ?? HijriCalendar.now().hYear;
    _events = IslamicEventService.getEventsForYear(year);
  }

  static IconData _iconFor(String name) {
    if (name.contains('New Year')) return Icons.celebration;
    if (name.contains('Ashura')) return Icons.water_drop_outlined;
    if (name.contains('Mawlid')) return Icons.cake;
    if (name.contains("Isra")) return Icons.nightlight_round;
    if (name.contains('Ramadan')) return Icons.no_food;
    if (name.contains('Laylat')) return Icons.star;
    if (name.contains('Fitr')) return Icons.card_giftcard;
    if (name.contains('Arafah')) return Icons.landscape;
    if (name.contains('Adha')) return Icons.pets;
    return Icons.event;
  }

  Future<void> _handleReminderTap(IslamicEvent event) async {
    final handler = widget.onReminderTap ??
        (IslamicEvent e) async {
          await ReminderScheduler.initialize();
          await ReminderScheduler.scheduleNotification(e);
        };
    await handler(event);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Reminder set for ${event.name}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: _events.length,
      itemBuilder: (context, index) {
        final event = _events[index];
        final gregorian = event.gregorianDate;
        final formattedHijri = event.date.toFormat('d MMMM, yyyy');
        final formattedGregorian =
            DateFormat('EEEE, d MMMM yyyy').format(gregorian);
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Icon(
              _iconFor(event.name),
              size: 40,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text(
              event.name,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    formattedHijri,
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.color
                          ?.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Corresponds to: $formattedGregorian',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.color
                          ?.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.notifications_active),
              tooltip: 'Set reminder',
              onPressed: () => _handleReminderTap(event),
            ),
          ),
        );
      },
    );
  }
}
