import 'package:hijri/hijri_calendar.dart';

/// A service class for Hijri calendar conversions and calculations.
class HijriService {
  /// Converts a Gregorian [DateTime] to a Hijri date.
  static HijriCalendar toHijri(DateTime gregorianDate) {
    return HijriCalendar.fromDate(gregorianDate);
  }

  /// Converts a Hijri date (year, month, day) to a Gregorian [DateTime].
  static DateTime toGregorian(int year, int month, int day) {
    return HijriCalendar().hijriToGregorian(year, month, day);
  }

  /// Gets the current Hijri date.
  static HijriCalendar get currentHijriDate {
    return HijriCalendar.now();
  }
}
