import 'package:hijri/hijri_calendar.dart';
import 'package:islamic_kit/src/hijri_calendar/hijri_service.dart';

/// Utilities for converting between Gregorian and Hijri dates.
class IslamicDateConverter {
  IslamicDateConverter._();

  /// Converts a Gregorian [DateTime] to a [HijriCalendar].
  static HijriCalendar gregorianToHijri(DateTime date) {
    return HijriService.toHijri(date);
  }

  /// Converts a Hijri date to a Gregorian [DateTime].
  ///
  /// Throws [ArgumentError] if [year], [month] or [day] are out of range.
  static DateTime hijriToGregorian(int year, int month, int day) {
    return HijriService.toGregorian(year, month, day);
  }
}
