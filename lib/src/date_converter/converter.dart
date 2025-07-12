import 'package:hijri/hijri_calendar.dart';
import 'package:islamic_kit/src/hijri_calendar/hijri_service.dart';

/// A utility class for converting between Islamic and Gregorian dates.
class IslamicDateConverter {
  /// Converts a Gregorian [DateTime] to a [HijriCalendar] date.
  static HijriCalendar gregorianToHijri(DateTime date) {
    return HijriService.toHijri(date);
  }

  /// Converts a Hijri date to a Gregorian [DateTime].
  static DateTime hijriToGregorian(int year, int month, int day) {
    return HijriService.toGregorian(year, month, day);
  }
}

