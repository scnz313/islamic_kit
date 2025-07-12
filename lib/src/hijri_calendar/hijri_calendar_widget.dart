import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';
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

  @override
  void initState() {
    super.initState();
    _hijriDate = HijriCalendar.now();
    _fetchEventsForYear(_hijriDate.hYear);
  }

  Future<void> _fetchEventsForYear(int year) async {
    final events = IslamicEventService.getEventsForYear(year);
    if (mounted) {
      setState(() {
        _events = events;
      });
    }
  }

  void _goToPreviousMonth() {
    setState(() {
      final currentYear = _hijriDate.hYear;
      var newMonth = _hijriDate.hMonth - 1;
      var newYear = _hijriDate.hYear;
      if (newMonth < 1) {
        newMonth = 12;
        newYear--;
      }
      _hijriDate = HijriCalendar()..hYear = newYear..hMonth = newMonth..hDay = 1;

      if (newYear != currentYear) {
        _fetchEventsForYear(newYear);
      }
    });
  }

  void _goToNextMonth() {
    setState(() {
      final currentYear = _hijriDate.hYear;
      var newMonth = _hijriDate.hMonth + 1;
      var newYear = _hijriDate.hYear;
      if (newMonth > 12) {
        newMonth = 1;
        newYear++;
      }
      _hijriDate = HijriCalendar()..hYear = newYear..hMonth = newMonth..hDay = 1;

      if (newYear != currentYear) {
        _fetchEventsForYear(newYear);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _CalendarHeader(
            hijriDate: _hijriDate,
            onPreviousMonth: _goToPreviousMonth,
            onNextMonth: _goToNextMonth,
          ),
          const SizedBox(height: 16),
          const _WeekdaysHeader(),
          const SizedBox(height: 8),
          Expanded(
            child: _CalendarGrid(
              hijriDate: _hijriDate,
              events: _events,
            ),
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
  });

  final HijriCalendar hijriDate;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;

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
        IconButton(
          icon: const Icon(Icons.arrow_forward_ios),
          onPressed: onNextMonth,
        ),
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
  });

  final HijriCalendar hijriDate;
  final List<IslamicEvent> events;

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
    final firstDayOfMonth =
        HijriCalendar()..hYear = hijriDate.hYear..hMonth = hijriDate.hMonth..hDay = 1;
    final int weekDay = firstDayOfMonth.weekDay();
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
        );
      },
    );
  }
}

class _CalendarDay extends StatelessWidget {
  const _CalendarDay({
    required this.day,
    required this.isToday,
    this.event,
  });

  final int day;
  final bool isToday;
  final IslamicEvent? event;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (event != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('${event!.name} on ${event!.date.toFormat("dd MMMM")}')),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isToday
              ? Theme.of(context).colorScheme.primaryContainer
              : Colors.transparent,
          shape: BoxShape.circle,
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
                    color: Theme.of(context).colorScheme.primary,
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
