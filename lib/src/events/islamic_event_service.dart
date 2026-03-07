import 'package:hijri/hijri_calendar.dart';
import 'package:islamic_kit/src/date_converter/converter.dart';

/// Represents a significant Islamic event.
class IslamicEvent {
  /// Creates an [IslamicEvent] with its metadata.
  const IslamicEvent({
    required this.name,
    required this.date,
    required this.description,
    this.isEstimated = false,
  });

  /// The name of the event (e.g., 'Eid al-Fitr').
  final String name;

  /// The date of the event in the Hijri calendar.
  final HijriCalendar date;

  /// A short description that explains the significance of the event.
  final String description;

  /// Whether the date may vary by local moon sighting or regional practice.
  final bool isEstimated;

  /// A deterministic identifier that stays stable across launches.
  String get id {
    final normalizedName =
        name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    return '${date.hYear}-${date.hMonth}-${date.hDay}-$normalizedName';
  }

  /// Converts the Hijri event date to the Gregorian calendar.
  DateTime get gregorianDate => IslamicDateConverter.hijriToGregorian(
        date.hYear,
        date.hMonth,
        date.hDay,
      );

  /// Returns `true` when the event date is before the provided day.
  bool isPast({DateTime? referenceDate}) {
    final reference = _startOfDay(referenceDate ?? DateTime.now());
    return gregorianDate.isBefore(reference);
  }

  /// Returns the number of whole days until the event.
  int daysUntil({DateTime? referenceDate}) {
    final reference = _startOfDay(referenceDate ?? DateTime.now());
    return _startOfDay(gregorianDate).difference(reference).inDays;
  }

  /// Returns the default reminder time for the event.
  DateTime reminderTime({int reminderHour = 9}) {
    final eventDate = gregorianDate;
    return DateTime(
      eventDate.year,
      eventDate.month,
      eventDate.day,
      reminderHour,
    );
  }

  /// Returns `true` when a reminder can still be scheduled for this event.
  bool canScheduleReminder({
    DateTime? referenceDate,
    int reminderHour = 9,
  }) {
    final reference = referenceDate ?? DateTime.now();
    return reminderTime(reminderHour: reminderHour).isAfter(reference);
  }

  static DateTime _startOfDay(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}

/// A service to find Islamic events within a given year.
class IslamicEventService {
  /// Returns a list of major Islamic events for a given Hijri year.
  static List<IslamicEvent> getEventsForYear(int year) {
    final events = [
      IslamicEvent(
        name: 'Islamic New Year',
        date: _createHijriDate(year, 1, 1),
        description:
            'Marks the beginning of a new Hijri year and a moment for reflection and renewal.',
      ),
      IslamicEvent(
        name: 'Day of Ashura',
        date: _createHijriDate(year, 1, 10),
        description:
            'Observed on the tenth of Muharram and widely associated with fasting and remembrance.',
      ),
      IslamicEvent(
        name: 'Mawlid al-Nabi',
        date: _createHijriDate(year, 3, 12),
        description:
            'A commemoration of the birth of the Prophet Muhammad (peace be upon him).',
        isEstimated: true,
      ),
      IslamicEvent(
        name: 'Isra and Mi\'raj',
        date: _createHijriDate(year, 7, 27),
        description:
            'Commemorates the Night Journey and Ascension.',
        isEstimated: true,
      ),
      IslamicEvent(
        name: 'Start of Ramadan',
        date: _createHijriDate(year, 9, 1),
        description:
            'The beginning of Ramadan, the month of fasting, prayer, and Quran recitation.',
        isEstimated: true,
      ),
      IslamicEvent(
        name: 'Laylat al-Qadr',
        date: _createHijriDate(year, 9, 27),
        description:
            'A highly blessed night in Ramadan that is often observed in the last ten nights.',
        isEstimated: true,
      ),
      IslamicEvent(
        name: 'Eid al-Fitr',
        date: _createHijriDate(year, 10, 1),
        description:
            'Celebrates the completion of Ramadan with prayer, charity, and gathering.',
        isEstimated: true,
      ),
      IslamicEvent(
        name: 'Day of Arafah',
        date: _createHijriDate(year, 12, 9),
        description:
            'Observed on the ninth of Dhul Hijjah and especially significant during Hajj.',
        isEstimated: true,
      ),
      IslamicEvent(
        name: 'Eid al-Adha',
        date: _createHijriDate(year, 12, 10),
        description:
            'Celebrates devotion and sacrifice during the days of Hajj.',
        isEstimated: true,
      ),
    ];
    events.sort(
      (first, second) => first.gregorianDate.compareTo(second.gregorianDate),
    );
    return events;
  }

  /// Returns the next upcoming Islamic event across the current and next Hijri year.
  static IslamicEvent? getUpcomingEvent({DateTime? referenceDate}) {
    final reference = referenceDate ?? DateTime.now();
    return _firstMatchingEvent(
      reference: reference,
      matcher: (event) => !event.isPast(referenceDate: reference),
    );
  }

  /// Returns the next event whose default reminder time has not yet passed.
  static IslamicEvent? getUpcomingReminderEvent({DateTime? referenceDate}) {
    final reference = referenceDate ?? DateTime.now();
    return _firstMatchingEvent(
      reference: reference,
      matcher: (event) => event.canScheduleReminder(referenceDate: reference),
    );
  }

  static IslamicEvent? _firstMatchingEvent({
    required DateTime reference,
    required bool Function(IslamicEvent event) matcher,
  }) {
    final hijriYear = HijriCalendar.fromDate(reference).hYear;
    final events = <IslamicEvent>[
      ...getEventsForYear(hijriYear),
      ...getEventsForYear(hijriYear + 1),
    ]..sort(
        (first, second) =>
            first.gregorianDate.compareTo(second.gregorianDate),
      );

    for (final event in events) {
      if (matcher(event)) {
        return event;
      }
    }

    return events.isEmpty ? null : events.first;
  }

  /// Helper method to create a HijriCalendar with specific date values.
  /// Validates input parameters to ensure valid Hijri dates.
  static HijriCalendar _createHijriDate(int year, int month, int day) {
    // Validate year (reasonable range)
    if (year < 1 || year > 2000) {
      throw ArgumentError('Invalid Hijri year: $year. Must be between 1 and 2000.');
    }
    
    // Validate month (1-12)
    if (month < 1 || month > 12) {
      throw ArgumentError('Invalid Hijri month: $month. Must be between 1 and 12.');
    }
    
    // Validate day (1-30, as Hijri months can have 29 or 30 days)
    if (day < 1 || day > 30) {
      throw ArgumentError('Invalid Hijri day: $day. Must be between 1 and 30.');
    }
    
    final hijriDate = HijriCalendar();
    hijriDate.hYear = year;
    hijriDate.hMonth = month;
    hijriDate.hDay = day;
    return hijriDate;
  }
}
