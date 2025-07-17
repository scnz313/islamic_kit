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
      IslamicEvent('Islamic New Year', _createHijriDate(year, 1, 1)),
      IslamicEvent('Day of Ashura', _createHijriDate(year, 1, 10)),
      IslamicEvent('Mawlid al-Nabi', _createHijriDate(year, 3, 12)),
      IslamicEvent('Isra and Mi\'raj', _createHijriDate(year, 7, 27)),
      IslamicEvent('Start of Ramadan', _createHijriDate(year, 9, 1)),
      IslamicEvent('Laylat al-Qadr', _createHijriDate(year, 9, 27)),
      IslamicEvent('Eid al-Fitr', _createHijriDate(year, 10, 1)),
      IslamicEvent('Day of Arafah', _createHijriDate(year, 12, 9)),
      IslamicEvent('Eid al-Adha', _createHijriDate(year, 12, 10)),
    ];
    return events;
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
