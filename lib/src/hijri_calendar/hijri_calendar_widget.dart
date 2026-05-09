import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:islamic_kit/src/date_converter/converter.dart';
import 'package:islamic_kit/src/events/islamic_event_service.dart';
import 'package:islamic_kit/src/hijri_calendar/hijri_service.dart';

/// Controls a [HijriCalendarWidget] programmatically.
///
/// Attach an instance to a [HijriCalendarWidget] via the
/// [HijriCalendarWidget.controller] parameter, and then call
/// [goToPreviousMonth], [goToNextMonth], [goToMonth] or [goToToday] from
/// anywhere (e.g. an `AppBar` action) to drive the visible month.
///
/// The controller also exposes the currently visible month as a
/// [ValueListenable], which is useful for building synchronised headers or
/// breadcrumb UIs.
///
/// Example:
/// ```dart
/// final controller = HijriCalendarController();
/// // ...
/// AppBar(actions: [
///   IconButton(
///     icon: const Icon(Icons.today),
///     onPressed: controller.goToToday,
///   ),
/// ]),
/// body: HijriCalendarWidget(controller: controller),
/// ```
///
/// Dispose the controller in your `State.dispose` when you're done with it.
class HijriCalendarController extends ChangeNotifier
    implements ValueListenable<HijriCalendar> {
  /// Creates a [HijriCalendarController].
  ///
  /// If [initialDate] is provided it controls which month the calendar
  /// initially displays. Otherwise today's Hijri month is used.
  HijriCalendarController({HijriCalendar? initialDate})
      : _value = HijriService.firstDayOfMonth(
          (initialDate ?? HijriCalendar.now()).hYear,
          (initialDate ?? HijriCalendar.now()).hMonth,
        );

  HijriCalendar _value;

  /// The first day of the month currently displayed.
  @override
  HijriCalendar get value => _value;

  /// Jumps to the month ([year], [month]).
  ///
  /// Throws [ArgumentError] if the date is outside the supported Hijri
  /// range — see [HijriRange].
  void goToMonth(int year, int month) {
    HijriService.validateDate(year, month, 1);
    final next = HijriService.firstDayOfMonth(year, month);
    if (next.hYear == _value.hYear && next.hMonth == _value.hMonth) return;
    _value = next;
    notifyListeners();
  }

  /// Navigates to the previous Hijri month, rolling over across years.
  void goToPreviousMonth() {
    var newMonth = _value.hMonth - 1;
    var newYear = _value.hYear;
    if (newMonth < 1) {
      newMonth = 12;
      newYear--;
    }
    goToMonth(newYear, newMonth);
  }

  /// Navigates to the next Hijri month, rolling over across years.
  void goToNextMonth() {
    var newMonth = _value.hMonth + 1;
    var newYear = _value.hYear;
    if (newMonth > 12) {
      newMonth = 1;
      newYear++;
    }
    goToMonth(newYear, newMonth);
  }

  /// Jumps to today's Hijri month.
  void goToToday() {
    final today = HijriCalendar.now();
    goToMonth(today.hYear, today.hMonth);
  }
}

/// A scrollable Hijri calendar widget with month navigation.
///
/// The widget highlights today's date and displays a dot marker on days
/// where an [IslamicEvent] falls. Tapping a day with an event shows a brief
/// snackbar with the event name and Gregorian date.
class HijriCalendarWidget extends StatefulWidget {
  /// Creates a [HijriCalendarWidget].
  ///
  /// Pass a [controller] to drive the calendar programmatically. If no
  /// controller is provided, one is created internally using [initialDate]
  /// (falling back to today's Hijri month).
  const HijriCalendarWidget({
    super.key,
    this.controller,
    HijriCalendar? initialDate,
  }) : _initialDate = initialDate;

  /// An optional external controller. The widget will use its value as the
  /// source of truth and listen to its notifications.
  final HijriCalendarController? controller;

  final HijriCalendar? _initialDate;

  @override
  State<HijriCalendarWidget> createState() => _HijriCalendarWidgetState();
}

class _HijriCalendarWidgetState extends State<HijriCalendarWidget> {
  late HijriCalendarController _controller;
  bool _ownsController = false;
  List<IslamicEvent> _events = const [];
  int _lastLoadedYear = -1;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ??
        HijriCalendarController(initialDate: widget._initialDate);
    _ownsController = widget.controller == null;
    _controller.addListener(_onControllerChanged);
    _loadEventsForYear(_controller.value.hYear);
  }

  @override
  void didUpdateWidget(covariant HijriCalendarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      _controller.removeListener(_onControllerChanged);
      if (_ownsController) _controller.dispose();
      _controller = widget.controller ??
          HijriCalendarController(initialDate: widget._initialDate);
      _ownsController = widget.controller == null;
      _controller.addListener(_onControllerChanged);
      _loadEventsForYear(_controller.value.hYear);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (!mounted) return;
    setState(() {
      _loadEventsForYear(_controller.value.hYear);
    });
  }

  void _loadEventsForYear(int year) {
    if (year == _lastLoadedYear) return;
    _events = IslamicEventService.getEventsForYear(year);
    _lastLoadedYear = year;
  }

  @override
  Widget build(BuildContext context) {
    final hijriDate = _controller.value;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _CalendarHeader(
            hijriDate: hijriDate,
            onPreviousMonth: _controller.goToPreviousMonth,
            onNextMonth: _controller.goToNextMonth,
          ),
          const SizedBox(height: 16),
          const _WeekdaysHeader(),
          const SizedBox(height: 8),
          Expanded(
            child: _CalendarGrid(
              hijriDate: hijriDate,
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
