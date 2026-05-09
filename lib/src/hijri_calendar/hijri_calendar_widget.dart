import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:islamic_kit/src/date_converter/converter.dart';
import 'package:islamic_kit/src/events/islamic_event_service.dart';
import 'package:islamic_kit/src/hijri_calendar/hijri_service.dart';

/// A scrollable Hijri calendar widget with month navigation.
///
/// The widget highlights today's date and displays a dot marker on days where
/// an [IslamicEvent] falls. Tapping a day with an event shows a short
/// notification with the event name.
class HijriCalendarWidget extends StatefulWidget {
  /// Creates a [HijriCalendarWidget].
  ///
  /// If [initialDate] is provided it controls the month initially displayed.
  /// Otherwise the widget starts on today's Hijri date.
  const HijriCalendarWidget({super.key, HijriCalendar? initialDate})
      : _initialDate = initialDate;

  final HijriCalendar? _initialDate;

  @override
  State<HijriCalendarWidget> createState() => _HijriCalendarWidgetState();
}

class _HijriCalendarWidgetState extends State<HijriCalendarWidget> {
  late HijriCalendar _hijriDate;
  List<IslamicEvent> _events = const [];

  @override
  void initState() {
    super.initState();
    final initial = widget._initialDate ?? HijriCalendar.now();
    _hijriDate = HijriService.firstDayOfMonth(initial.hYear, initial.hMonth);
    _loadEventsForYear(_hijriDate.hYear);
  }

  void _loadEventsForYear(int year) {
    _events = IslamicEventService.getEventsForYear(year);
  }

  void _goToPreviousMonth() {
    var newMonth = _hijriDate.hMonth - 1;
    var newYear = _hijriDate.hYear;
    if (newMonth < 1) {
      newMonth = 12;
      newYear--;
    }
    _changeMonth(newYear, newMonth);
  }

  void _goToNextMonth() {
    var newMonth = _hijriDate.hMonth + 1;
    var newYear = _hijriDate.hYear;
    if (newMonth > 12) {
      newMonth = 1;
      newYear++;
    }
    _changeMonth(newYear, newMonth);
  }

  void _changeMonth(int year, int month) {
    setState(() {
      final previousYear = _hijriDate.hYear;
      _hijriDate = HijriService.firstDayOfMonth(year, month);
      if (year != previousYear) {
        _loadEventsForYear(year);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
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
          tooltip: 'Previous month',
          onPressed: onPreviousMonth,
        ),
        Text(
          hijriDate.toFormat('MMMM yyyy'),
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        IconButton(
          icon: const Icon(Icons.arrow_forward_ios),
          tooltip: 'Next month',
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
    const weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: weekdays
          .map(
            (day) => Expanded(
              child: Center(
                child: Text(
                  day,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _CalendarGrid extends StatelessWidget {
  const _CalendarGrid({required this.hijriDate, required this.events});

  final HijriCalendar hijriDate;
  final List<IslamicEvent> events;

  @override
  Widget build(BuildContext context) {
    final daysInMonth = hijriDate.lengthOfMonth;
    // [HijriCalendar.weekDay()] returns 1..7 with Monday == 1. We lay the
    // grid out Sun..Sat so convert to 0..6 with Sunday == 0.
    final int mondayIndex = hijriDate.weekDay();
    final int emptyCells = mondayIndex % 7;

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
        return _CalendarDay(day: day, isToday: isToday, event: event);
      },
    );
  }

  bool _isToday(int day) {
    final now = HijriCalendar.now();
    return hijriDate.hYear == now.hYear &&
        hijriDate.hMonth == now.hMonth &&
        day == now.hDay;
  }

  IslamicEvent? _getEventForDay(int day) {
    for (final event in events) {
      if (event.date.hYear == hijriDate.hYear &&
          event.date.hMonth == hijriDate.hMonth &&
          event.date.hDay == day) {
        return event;
      }
    }
    return null;
  }
}

class _CalendarDay extends StatelessWidget {
  const _CalendarDay({required this.day, required this.isToday, this.event});

  final int day;
  final bool isToday;
  final IslamicEvent? event;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (event != null) {
          final gregorian = IslamicDateConverter.hijriToGregorian(
            event!.date.hYear,
            event!.date.hMonth,
            event!.date.hDay,
          );
          final formattedGregorian =
              '${gregorian.day}/${gregorian.month}/${gregorian.year}';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${event!.name} ($formattedGregorian)'),
              duration: const Duration(seconds: 2),
            ),
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
