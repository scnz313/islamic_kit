import 'package:flutter_test/flutter_test.dart';
import 'package:islamic_kit/islamic_kit.dart';

void main() {
  group('HijriService conversions', () {
    test('toHijri(2024-01-01) returns a valid Hijri date', () {
      final h = HijriService.toHijri(DateTime(2024, 1, 1));
      expect(h.hYear, greaterThan(1440));
      expect(h.hYear, lessThan(1460));
      expect(h.hMonth, inInclusiveRange(1, 12));
      expect(h.hDay, inInclusiveRange(1, 30));
    });

    test('toGregorian/toHijri round-trip returns the same Hijri date', () {
      // Use a date we know is valid in the Umm al-Qura table.
      final hijri = HijriService.toHijri(DateTime(2025, 6, 15));
      final gregorian = HijriService.toGregorian(
        hijri.hYear,
        hijri.hMonth,
        hijri.hDay,
      );
      final roundTrip = HijriService.toHijri(gregorian);
      expect(roundTrip.hYear, hijri.hYear);
      expect(roundTrip.hMonth, hijri.hMonth);
      expect(roundTrip.hDay, hijri.hDay);
    });

    test('currentHijriDate is a valid HijriCalendar', () {
      final now = HijriService.currentHijriDate;
      expect(now.hYear, inInclusiveRange(HijriRange.minYear, HijriRange.maxYear));
    });
  });

  group('HijriService.firstDayOfMonth / fromDate', () {
    test('firstDayOfMonth exposes a non-null lengthOfMonth', () {
      final h = HijriService.firstDayOfMonth(1446, 6);
      expect(h.hYear, 1446);
      expect(h.hMonth, 6);
      expect(h.hDay, 1);
      expect(h.lengthOfMonth, inInclusiveRange(29, 30));
      expect(h.weekDay(), inInclusiveRange(1, 7));
    });

    test('fromDate supports any day in the month', () {
      final h = HijriService.fromDate(1446, 9, 15);
      expect(h.hYear, 1446);
      expect(h.hMonth, 9);
      expect(h.hDay, 15);
    });
  });

  group('HijriService.validateDate', () {
    test('accepts valid dates', () {
      expect(() => HijriService.validateDate(1446, 1, 1), returnsNormally);
      expect(() => HijriService.validateDate(1500, 12, 30), returnsNormally);
    });

    test('rejects years outside the supported range', () {
      expect(
          () => HijriService.validateDate(1000, 1, 1), throwsArgumentError);
      expect(
          () => HijriService.validateDate(2500, 1, 1), throwsArgumentError);
    });

    test('rejects months outside [1,12]', () {
      expect(() => HijriService.validateDate(1446, 0, 1), throwsArgumentError);
      expect(
          () => HijriService.validateDate(1446, 13, 1), throwsArgumentError);
    });

    test('rejects days outside [1,30]', () {
      expect(() => HijriService.validateDate(1446, 1, 0), throwsArgumentError);
      expect(
          () => HijriService.validateDate(1446, 1, 31), throwsArgumentError);
    });
  });

  group('IslamicDateConverter', () {
    test('gregorianToHijri is consistent with HijriCalendar.fromDate', () {
      final date = DateTime(2024, 4, 10);
      final a = IslamicDateConverter.gregorianToHijri(date);
      final b = HijriCalendar.fromDate(date);
      expect(a.hYear, b.hYear);
      expect(a.hMonth, b.hMonth);
      expect(a.hDay, b.hDay);
    });

    test('hijriToGregorian throws on invalid input', () {
      expect(
        () => IslamicDateConverter.hijriToGregorian(999, 1, 1),
        throwsArgumentError,
      );
    });
  });
}
