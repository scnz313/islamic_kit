import 'package:hijri/hijri_calendar.dart';

/// Represents a significant Islamic event.
class IslamicEvent {
  /// The name of the event (e.g., 'Eid al-Fitr').
  final String name;

  /// The date of the event in the Hijri calendar.
  final HijriCalendar date;

  /// Creates an [IslamicEvent] with a given [name] and [date].
  IslamicEvent(this.name, this.date);
}

/// A service to find Islamic events within a given year.
class IslamicEventService {
  /// Returns a list of major Islamic events for a given Hijri year.
  static List<IslamicEvent> getEventsForYear(int year) {
    final events = [
      IslamicEvent('Islamic New Year', HijriCalendar()..hYear = year..hMonth = 1..hDay = 1),
      IslamicEvent('Day of Ashura', HijriCalendar()..hYear = year..hMonth = 1..hDay = 10),
      IslamicEvent('Mawlid al-Nabi', HijriCalendar()..hYear = year..hMonth = 3..hDay = 12),
      IslamicEvent('Isra and Mi\'raj', HijriCalendar()..hYear = year..hMonth = 7..hDay = 27),
      IslamicEvent('Start of Ramadan', HijriCalendar()..hYear = year..hMonth = 9..hDay = 1),
      IslamicEvent('Laylat al-Qadr', HijriCalendar()..hYear = year..hMonth = 9..hDay = 27),
      IslamicEvent('Eid al-Fitr', HijriCalendar()..hYear = year..hMonth = 10..hDay = 1),
      IslamicEvent('Day of Arafah', HijriCalendar()..hYear = year..hMonth = 12..hDay = 9),
      IslamicEvent('Eid al-Adha', HijriCalendar()..hYear = year..hMonth = 12..hDay = 10),
    ];
    return events;
  }
}
