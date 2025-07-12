import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:islamic_kit/islamic_kit.dart';

/// A widget that displays a list of important Islamic events for the current Hijri year.
///
/// Each event shows its name, Hijri date, corresponding Gregorian date, and an
/// icon. Users can set a notification reminder for each event.
class IslamicEventsWidget extends StatefulWidget {
    /// Creates an [IslamicEventsWidget].
  const IslamicEventsWidget({super.key});

  @override
  State<IslamicEventsWidget> createState() => _IslamicEventsWidgetState();
}

class _IslamicEventsWidgetState extends State<IslamicEventsWidget> {
  late final List<IslamicEvent> _events;

  @override
  void initState() {
    super.initState();
    // Initialize the scheduler statically
    ReminderScheduler.initialize();
    _events = IslamicEventService.getEventsForYear(HijriCalendar.now().hYear);
  }

  IconData _getIconForEvent(String eventName) {
    if (eventName.contains('New Year')) return Icons.celebration;
    if (eventName.contains('Ashura')) return Icons.water_drop_outlined;
    if (eventName.contains('Mawlid')) return Icons.cake;
    if (eventName.contains('Isra and Mi\'raj')) return Icons.nightlight_round;
    if (eventName.contains('Ramadan')) return Icons.no_food; // Corrected icon
    if (eventName.contains('Laylat al-Qadr')) return Icons.star;
    if (eventName.contains('Eid al-Fitr')) return Icons.card_giftcard;
    if (eventName.contains('Arafah')) return Icons.landscape;
    if (eventName.contains('Eid al-Adha')) return Icons.pets;
    return Icons.event;
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: _events.length,
      itemBuilder: (context, index) {
        final event = _events[index];
        final gregorianDate = IslamicDateConverter.hijriToGregorian(
          event.date.hYear,
          event.date.hMonth,
          event.date.hDay,
        );
        final formattedHijriDate = event.date.toFormat('d MMMM, yyyy');
        final formattedGregorianDate =
            DateFormat('EEEE, d MMMM yyyy').format(gregorianDate);

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          elevation: 2.0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16.0),
            leading: Icon(_getIconForEvent(event.name),
                size: 40, color: Theme.of(context).colorScheme.primary),
            title: Text(
              event.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    formattedHijriDate,
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.color
                          ?.withAlpha(178),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Corresponds to: $formattedGregorianDate',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.color
                          ?.withAlpha(178),
                    ),
                  ),
                ],
              ),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.notifications_active),
              onPressed: () {
                // Call the static method with the correct parameter
                ReminderScheduler.scheduleNotification(event);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Reminder set for ${event.name}'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
