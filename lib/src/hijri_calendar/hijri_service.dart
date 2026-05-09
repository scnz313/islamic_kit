import 'package:hijri/hijri_calendar.dart';

/// Supported Hijri year range.
///
/// The underlying `hijri` package uses the Umm Al-Qura tables which are only
/// valid for Hijri years 1356–1500 AH (roughly 1937–2077 CE).
class HijriRange {
  /// Minimum supported Hijri year (inclusive).
  static const int minYear = 1356;

  /// Maximum supported Hijri year (inclusive).
  static const int maxYear = 1500;
}

/// Conversion and construction helpers for [HijriCalendar] dates.
class HijriService {
  /// Converts a Gregorian [DateTime] to a [HijriCalendar].
  static HijriCalendar toHijri(DateTime gregorianDate) {
    return HijriCalendar.fromDate(gregorianDate);
  }

  /// Converts a Hijri date (year, month, day) to a Gregorian [DateTime].
  ///
  /// Throws [ArgumentError] if the provided date is not a valid Hijri date
  /// (year out of range, month not 1–12, day not 1–30).
  static DateTime toGregorian(int year, int month, int day) {
    validateDate(year, month, day);
    return HijriCalendar().hijriToGregorian(year, month, day);
  }

  /// Returns today's Hijri date.
  static HijriCalendar get currentHijriDate => HijriCalendar.now();

  /// Returns a fully-initialized [HijriCalendar] for the 1st day of
  /// ([year], [month]).
  ///
  /// This is the safe way to construct a [HijriCalendar] because it ensures
  /// all `late` fields (e.g. `lengthOfMonth`, `longMonthName`) are populated
  /// — something that doesn't happen when the instance is built purely via
  /// setters (`HijriCalendar()..hYear = y..hMonth = m..hDay = d`).
  static HijriCalendar firstDayOfMonth(int year, int month) {
    return fromDate(year, month, 1);
  }

  /// Returns a fully-initialized [HijriCalendar] for ([year], [month], [day]).
  ///
  /// Throws [ArgumentError] if the provided date is not a valid Hijri date.
  static HijriCalendar fromDate(int year, int month, int day) {
    validateDate(year, month, day);
    final gregorian = HijriCalendar().hijriToGregorian(year, month, day);
    return HijriCalendar.fromDate(gregorian);
  }

  /// Validates a Hijri date. Throws [ArgumentError] on bad input.
  static void validateDate(int year, int month, int day) {
    if (year < HijriRange.minYear || year > HijriRange.maxYear) {
      throw ArgumentError(
          'Hijri year $year is out of supported range '
          '(${HijriRange.minYear}–${HijriRange.maxYear}).');
    }
    if (month < 1 || month > 12) {
      throw ArgumentError('Invalid Hijri month: $month. Must be 1–12.');
    }
    if (day < 1 || day > 30) {
      throw ArgumentError('Invalid Hijri day: $day. Must be 1–30.');
    }
  }
}
