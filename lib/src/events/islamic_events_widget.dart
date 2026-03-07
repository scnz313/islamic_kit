import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart';
import 'package:islamic_kit/src/events/islamic_event_service.dart';
import 'package:islamic_kit/src/events/reminder_scheduler.dart';

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
  final Set<String> _busyEventIds = <String>{};
  bool _isInitializingReminders = true;
  bool _remindersAvailable = false;

  @override
  void initState() {
    super.initState();
    _events = IslamicEventService.getEventsForYear(HijriCalendar.now().hYear);
    unawaited(_initializeReminders());
  }

  Future<void> _initializeReminders() async {
    final remindersAvailable = await ReminderScheduler.initialize();
    if (!mounted) {
      return;
    }
    setState(() {
      _remindersAvailable = remindersAvailable;
      _isInitializingReminders = false;
    });
  }

  Future<void> _scheduleReminder(IslamicEvent event) async {
    setState(() {
      _busyEventIds.add(event.id);
    });

    final result = await ReminderScheduler.scheduleEventReminder(event);
    if (!mounted) {
      return;
    }

    setState(() {
      _busyEventIds.remove(event.id);
      if (result.isSuccess) {
        _remindersAvailable = true;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.message)),
    );
  }

  void _showEventDetails(IslamicEvent event) {
    final gregorianDate = event.gregorianDate;
    final formattedGregorianDate =
        DateFormat('EEEE, d MMMM yyyy').format(gregorianDate);

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.name,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                Text(event.description),
                const SizedBox(height: 16),
                _EventMetaRow(
                  icon: Icons.calendar_month,
                  label: 'Hijri date',
                  value: event.date.toFormat('d MMMM yyyy'),
                ),
                _EventMetaRow(
                  icon: Icons.event_available,
                  label: 'Gregorian date',
                  value: formattedGregorianDate,
                ),
                if (event.isEstimated)
                  const Padding(
                    padding: EdgeInsets.only(top: 12.0),
                    child: _InfoMessageCard(
                      icon: Icons.info_outline,
                      message:
                          'This date may vary by local moon sighting or regional practice.',
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
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
    final upcomingEvent = IslamicEventService.getUpcomingEvent();

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        if (upcomingEvent != null)
          _UpcomingEventCard(
            event: upcomingEvent,
            onSchedule: upcomingEvent.canScheduleReminder()
                ? () {
                    unawaited(_scheduleReminder(upcomingEvent));
                  }
                : null,
            isBusy: _busyEventIds.contains(upcomingEvent.id),
          ),
        const SizedBox(height: 16),
        const _InfoMessageCard(
          icon: Icons.brightness_2_outlined,
          message:
              'Moon-sighting-dependent observances are marked as estimated and can vary by region.',
        ),
        const SizedBox(height: 12),
        _InfoMessageCard(
          icon: Icons.notifications_active_outlined,
          message: _isInitializingReminders
              ? 'Preparing reminders...'
              : _remindersAvailable
                  ? 'Reminders are ready. You may be asked for permission before scheduling.'
                  : 'Reminders will request notification permission when you schedule one.',
        ),
        const SizedBox(height: 12),
        for (final event in _events)
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: _EventCard(
              event: event,
              icon: _getIconForEvent(event.name),
              isBusy: _busyEventIds.contains(event.id),
              onDetails: () => _showEventDetails(event),
              onSchedule: event.canScheduleReminder()
                  ? () {
                      unawaited(_scheduleReminder(event));
                    },
                  : null,
            ),
          ),
      ],
    );
  }
}

class _UpcomingEventCard extends StatelessWidget {
  const _UpcomingEventCard({
    required this.event,
    required this.isBusy,
    this.onSchedule,
  });

  final IslamicEvent event;
  final bool isBusy;
  final VoidCallback? onSchedule;

  @override
  Widget build(BuildContext context) {
    final daysUntil = event.daysUntil();
    final formattedDate =
        DateFormat('EEE, d MMM yyyy').format(event.gregorianDate);

    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Upcoming event',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              event.name,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(event.description),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  avatar: const Icon(Icons.event, size: 18),
                  label: Text(formattedDate),
                ),
                Chip(
                  avatar: const Icon(Icons.schedule, size: 18),
                  label: Text(
                    daysUntil == 0
                        ? 'Today'
                        : daysUntil == 1
                            ? 'In 1 day'
                            : 'In $daysUntil days',
                  ),
                ),
                if (event.isEstimated)
                  const Chip(
                    avatar: Icon(Icons.info_outline, size: 18),
                    label: Text('Estimated date'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.icon(
                onPressed: isBusy ? null : onSchedule,
                icon: isBusy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.notifications_active),
                label: const Text('Set reminder'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({
    required this.event,
    required this.icon,
    required this.isBusy,
    required this.onDetails,
    this.onSchedule,
  });

  final IslamicEvent event;
  final IconData icon;
  final bool isBusy;
  final VoidCallback onDetails;
  final VoidCallback? onSchedule;

  @override
  Widget build(BuildContext context) {
    final formattedGregorianDate =
        DateFormat('EEEE, d MMMM yyyy').format(event.gregorianDate);
    final daysUntil = event.daysUntil();
    final statusLabel = daysUntil < 0
        ? 'Passed'
        : daysUntil == 0
            ? 'Today'
            : daysUntil == 1
                ? 'Tomorrow'
                : 'In $daysUntil days';

    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12.0),
        onTap: onDetails,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primaryContainer
                          .withAlpha(180),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      size: 28,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.name,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(event.description),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Event details',
                    onPressed: onDetails,
                    icon: const Icon(Icons.info_outline),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(label: Text(event.date.toFormat('d MMMM yyyy'))),
                  Chip(label: Text(formattedGregorianDate)),
                  Chip(label: Text(statusLabel)),
                  if (event.isEstimated) const Chip(label: Text('Estimated')),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      onSchedule == null
                          ? 'Reminder unavailable because the scheduled reminder time has passed'
                          : 'Schedule a 9:00 AM reminder on the event date',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.tonalIcon(
                    onPressed: isBusy ? null : onSchedule,
                    icon: isBusy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.notifications_active_outlined),
                    label: Text(onSchedule == null ? 'Unavailable' : 'Remind me'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EventMetaRow extends StatelessWidget {
  const _EventMetaRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: DefaultTextStyle.of(context).style,
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoMessageCard extends StatelessWidget {
  const _InfoMessageCard({
    required this.icon,
    required this.message,
  });

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}
