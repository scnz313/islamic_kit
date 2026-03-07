import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart';
import 'package:islamic_kit/src/date_converter/converter.dart';
import 'package:islamic_kit/src/events/islamic_event_service.dart';

/// A widget that displays a scrollable Hijri calendar.
class HijriCalendarWidget extends StatefulWidget {
  /// Creates a [HijriCalendarWidget].
  const HijriCalendarWidget({super.key});

  @override
  State<HijriCalendarWidget> createState() => _HijriCalendarWidgetState();
}

class _HijriCalendarWidgetState extends State<HijriCalendarWidget> {
  late HijriCalendar _hijriDate;
  List<IslamicEvent> _events = [];
  IslamicEvent? _selectedEvent;

  @override
  void initState() {
    super.initState();
    _hijriDate = HijriCalendar.now();
    _fetchEventsForYear(_hijriDate.hYear);
  }

  void _fetchEventsForYear(int year) {
    final events = IslamicEventService.getEventsForYear(year);
    setState(() {
      _events = events;
      if (_selectedEvent != null && _selectedEvent!.date.hYear != year) {
        _selectedEvent = null;
      }
    });
  }

  void _goToPreviousMonth() {
    final currentYear = _hijriDate.hYear;
    var newMonth = _hijriDate.hMonth - 1;
    var newYear = _hijriDate.hYear;
    if (newMonth < 1) {
      newMonth = 12;
      newYear--;
    }

    setState(() {
      _hijriDate = HijriCalendar()..hYear = newYear..hMonth = newMonth..hDay = 1;
    });
    if (newYear != currentYear) {
      _fetchEventsForYear(newYear);
    }
  }

  void _goToNextMonth() {
    final currentYear = _hijriDate.hYear;
    var newMonth = _hijriDate.hMonth + 1;
    var newYear = _hijriDate.hYear;
    if (newMonth > 12) {
      newMonth = 1;
      newYear++;
    }

    setState(() {
      _hijriDate = HijriCalendar()..hYear = newYear..hMonth = newMonth..hDay = 1;
    });
    if (newYear != currentYear) {
      _fetchEventsForYear(newYear);
    }
  }

  void _goToToday() {
    setState(() {
      _hijriDate = HijriCalendar.now();
      _selectedEvent = null;
    });
    _fetchEventsForYear(_hijriDate.hYear);
  }

  void _showEventDetails(IslamicEvent event) {
    setState(() {
      _selectedEvent = event;
    });

    final gregorianDate = event.gregorianDate;
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
                Text('Hijri: ${event.date.toFormat('d MMMM yyyy')}'),
                const SizedBox(height: 8),
                Text(
                  'Gregorian: ${DateFormat('EEEE, d MMMM yyyy').format(gregorianDate)}',
                ),
                if (event.isEstimated)
                  const Padding(
                    padding: EdgeInsets.only(top: 12.0),
                    child: _CalendarInfoCard(
                      message:
                          'This observance may shift based on local moon sighting or regional practice.',
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final monthEvents = _events
        .where((event) =>
            event.date.hYear == _hijriDate.hYear &&
            event.date.hMonth == _hijriDate.hMonth)
        .toList();
    final currentGregorianDate = IslamicDateConverter.hijriToGregorian(
      _hijriDate.hYear,
      _hijriDate.hMonth,
      1,
    );

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CalendarHeader(
            hijriDate: _hijriDate,
            onPreviousMonth: _goToPreviousMonth,
            onNextMonth: _goToNextMonth,
            onToday: _goToToday,
          ),
          const SizedBox(height: 8),
          Text(
            DateFormat('MMMM yyyy').format(currentGregorianDate),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          const _CalendarLegend(),
          const SizedBox(height: 12),
          const _WeekdaysHeader(),
          const SizedBox(height: 8),
          Expanded(
            child: _CalendarGrid(
              hijriDate: _hijriDate,
              events: _events,
              selectedEvent: _selectedEvent,
              onEventTap: _showEventDetails,
            ),
          ),
          const SizedBox(height: 16),
          if (monthEvents.isNotEmpty)
            _MonthEventsCard(
              events: monthEvents,
              onEventTap: _showEventDetails,
            ),
        ],
      ),
    );
  }
}

class _CalendarHeader extends StatelessWidget {
  const _CalendarHeader({
    required this.hijriDate,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onToday,
  });

  final HijriCalendar hijriDate;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final VoidCallback onToday;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: onPreviousMonth,
        ),
        Text(
          hijriDate.toFormat("MMMM yyyy"),
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              onPressed: onToday,
              child: const Text('Today'),
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios),
              onPressed: onNextMonth,
            ),
          ],
        ),
      ],
    );
  }
}

class _CalendarLegend extends StatelessWidget {
  const _CalendarLegend();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 8,
      children: const [
        _LegendItem(
          color: Colors.transparent,
          border: true,
          label: 'Selected event',
        ),
        _LegendItem(
          color: null,
          label: 'Today',
        ),
        _LegendItem(
          color: Colors.blue,
          label: 'Event day',
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.label,
    this.color,
    this.border = false,
  });

  final String label;
  final Color? color;
  final bool border;

  @override
  Widget build(BuildContext context) {
    final displayColor = color ?? Theme.of(context).colorScheme.primaryContainer;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: displayColor,
            borderRadius: BorderRadius.circular(6),
            border: border
                ? Border.all(color: Theme.of(context).colorScheme.primary)
                : null,
          ),
        ),
        const SizedBox(width: 6),
        Text(label),
      ],
    );
  }
}

class _WeekdaysHeader extends StatelessWidget {
  const _WeekdaysHeader();

  @override
  Widget build(BuildContext context) {
    final weekdays = ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: weekdays
          .map((day) => Text(day, style: const TextStyle(fontWeight: FontWeight.bold)))
          .toList(),
    );
  }
}

class _CalendarGrid extends StatelessWidget {
  const _CalendarGrid({
    required this.hijriDate,
    required this.events,
    required this.onEventTap,
    required this.selectedEvent,
  });

  final HijriCalendar hijriDate;
  final List<IslamicEvent> events;
  final ValueChanged<IslamicEvent> onEventTap;
  final IslamicEvent? selectedEvent;

  bool _isToday(int day) {
    final now = HijriCalendar.now();
    return hijriDate.hYear == now.hYear &&
        hijriDate.hMonth == now.hMonth &&
        day == now.hDay;
  }

  IslamicEvent? _getEventForDay(int day) {
    try {
      return events.firstWhere((event) =>
          event.date.hYear == hijriDate.hYear &&
          event.date.hMonth == hijriDate.hMonth &&
          event.date.hDay == day);
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final daysInMonth = hijriDate.lengthOfMonth;
    final firstDayOfMonthGregorian = IslamicDateConverter.hijriToGregorian(
      hijriDate.hYear,
      hijriDate.hMonth,
      1,
    );
    final int weekDay = firstDayOfMonthGregorian.weekday;
    final int emptyCells = weekDay % 7;

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
      ),
      itemCount: daysInMonth + emptyCells,
      itemBuilder: (context, index) {
        if (index < emptyCells) {
          return const SizedBox.shrink();
        }

        final day = index - emptyCells + 1;
        final isToday = _isToday(day);
        final event = _getEventForDay(day);

        return _CalendarDay(
          day: day,
          isToday: isToday,
          event: event,
          isSelected: selectedEvent?.id == event?.id,
          onEventTap: onEventTap,
        );
      },
    );
  }
}

class _CalendarDay extends StatelessWidget {
  const _CalendarDay({
    required this.day,
    required this.isToday,
    required this.isSelected,
    required this.onEventTap,
    this.event,
  });

  final int day;
  final bool isToday;
  final bool isSelected;
  final ValueChanged<IslamicEvent> onEventTap;
  final IslamicEvent? event;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (event != null) {
          onEventTap(event!);
        }
      },
      child: Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isToday
              ? Theme.of(context).colorScheme.primaryContainer
              : Colors.transparent,
          shape: BoxShape.circle,
          border: isSelected
              ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2)
              : null,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              '$day',
              style: TextStyle(
                color: isToday
                    ? Theme.of(context).colorScheme.onPrimaryContainer
                    : null,
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (event != null)
              Positioned(
                bottom: 4,
                child: Container(
                  height: 5,
                  width: 5,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MonthEventsCard extends StatelessWidget {
  const _MonthEventsCard({
    required this.events,
    required this.onEventTap,
  });

  final List<IslamicEvent> events;
  final ValueChanged<IslamicEvent> onEventTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Events this month',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            for (final event in events)
              ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: const Icon(Icons.event_note),
                title: Text(event.name),
                subtitle: Text(event.date.toFormat('d MMMM yyyy')),
                trailing: event.isEstimated
                    ? const Icon(Icons.info_outline, size: 18)
                    : null,
                onTap: () => onEventTap(event),
              ),
          ],
        ),
      ),
    );
  }
}

class _CalendarInfoCard extends StatelessWidget {
  const _CalendarInfoCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}
