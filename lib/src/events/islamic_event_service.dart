import 'package:hijri/hijri_calendar.dart';
import 'package:islamic_kit/src/hijri_calendar/hijri_service.dart';

/// A significant Islamic event.
class IslamicEvent {
  /// Creates an [IslamicEvent] with a given [name] and Hijri [date].
  const IslamicEvent(this.name, this.date);

  /// The name of the event (e.g. "Eid al-Fitr").
  final String name;

  /// The Hijri date of the event.
  final HijriCalendar date;

  /// Returns the Gregorian [DateTime] that corresponds to [date].
  DateTime get gregorianDate => HijriService.toGregorian(
        date.hYear,
        date.hMonth,
        date.hDay,
      );

  @override
  String toString() =>
      'IslamicEvent($name, ${date.hDay}/${date.hMonth}/${date.hYear} AH)';
}

/// Lookups for major Islamic events.
class IslamicEventService {
  IslamicEventService._();

  /// Definitions of major annual Islamic events, as `(name, month, day)` in
  /// the Hijri calendar. The list is ordered by (month, day).
  static const List<(String, int, int)> _eventDefinitions = [
    ('Islamic New Year', 1, 1),
    ('Day of Ashura', 1, 10),
    ("Mawlid al-Nabi", 3, 12),
    ("Isra and Mi'raj", 7, 27),
    ('Start of Ramadan', 9, 1),
    ('Laylat al-Qadr', 9, 27),
    ('Eid al-Fitr', 10, 1),
    ('Day of Arafah', 12, 9),
    ('Eid al-Adha', 12, 10),
  ];

  /// Returns the list of supported major Islamic event names.
  static List<String> get knownEventNames =>
      _eventDefinitions.map((e) => e.$1).toList(growable: false);

  /// Returns a list of major Islamic events for the given Hijri [year].
  ///
  /// Throws [ArgumentError] if [year] is outside the supported Hijri range
  /// (see [HijriRange]).
  static List<IslamicEvent> getEventsForYear(int year) {
    if (year < HijriRange.minYear || year > HijriRange.maxYear) {
      throw ArgumentError(
          'Hijri year $year is out of supported range '
          '(${HijriRange.minYear}–${HijriRange.maxYear}).');
    }
    return _eventDefinitions
        .map((def) => IslamicEvent(
              def.$1,
              HijriService.fromDate(year, def.$2, def.$3),
            ))
        .toList(growable: false);
  }

  /// Returns the next upcoming [IslamicEvent] on or after [from], looking
  /// up to [yearsAhead] Hijri years ahead. Returns `null` if no event is
  /// found within the supported range.
  static IslamicEvent? nextEvent({DateTime? from, int yearsAhead = 2}) {
    final reference = from ?? DateTime.now();
    final startHijri = HijriService.toHijri(reference);
    for (var y = startHijri.hYear;
        y <= startHijri.hYear + yearsAhead && y <= HijriRange.maxYear;
        y++) {
      for (final event in getEventsForYear(y)) {
        if (!event.gregorianDate.isBefore(
            DateTime(reference.year, reference.month, reference.day))) {
          return event;
        }
      }
    }
    return null;
  }
}
