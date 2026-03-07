import 'package:islamic_kit/islamic_kit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Gregorian and Hijri conversion remain consistent', () {
    final gregorianDate = DateTime(2026, 3, 7);
    final hijriDate = IslamicDateConverter.gregorianToHijri(gregorianDate);
    final convertedBack = IslamicDateConverter.hijriToGregorian(
      hijriDate.hYear,
      hijriDate.hMonth,
      hijriDate.hDay,
    );

    expect(convertedBack.year, gregorianDate.year);
    expect(convertedBack.month, gregorianDate.month);
    expect(convertedBack.day, gregorianDate.day);
  });
}
