import 'package:adhan/adhan.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:islamic_kit/islamic_kit.dart';

void main() {
  group('PrayerCalc.getPrayerTimes', () {
    test('returns prayer times in strictly increasing order for a known '
        'location', () {
      final date = DateTime(2024, 6, 21); // Summer solstice.
      final times = PrayerCalc.getPrayerTimes(
        latitude: 40.7128,
        longitude: -74.0060,
        date: date,
        calculationMethod: CalculationMethod.muslim_world_league,
      );
      expect(times.fajr.isBefore(times.sunrise), isTrue);
      expect(times.sunrise.isBefore(times.dhuhr), isTrue);
      expect(times.dhuhr.isBefore(times.asr), isTrue);
      expect(times.asr.isBefore(times.maghrib), isTrue);
      expect(times.maghrib.isBefore(times.isha), isTrue);
    });

    test('rejects invalid coordinates', () {
      expect(
        () => PrayerCalc.getPrayerTimes(
          latitude: 91,
          longitude: 0,
          date: DateTime.now(),
          calculationMethod: CalculationMethod.muslim_world_league,
        ),
        throwsArgumentError,
      );
      expect(
        () => PrayerCalc.getPrayerTimes(
          latitude: 0,
          longitude: -181,
          date: DateTime.now(),
          calculationMethod: CalculationMethod.muslim_world_league,
        ),
        throwsArgumentError,
      );
    });

    test('respects the [madhab] for Asr calculation', () {
      final date = DateTime(2024, 6, 21);
      final shafi = PrayerCalc.getPrayerTimes(
        latitude: 40.7128,
        longitude: -74.0060,
        date: date,
        calculationMethod: CalculationMethod.muslim_world_league,
      );
      final hanafi = PrayerCalc.getPrayerTimes(
        latitude: 40.7128,
        longitude: -74.0060,
        date: date,
        calculationMethod: CalculationMethod.muslim_world_league,
        madhab: Madhab.hanafi,
      );
      // Hanafi Asr is always later than Shafi Asr.
      expect(hanafi.asr.isAfter(shafi.asr), isTrue);
    });
  });

  group('PrayerCalc.nextPrayerFrom', () {
    late PrayerTimes times;
    setUp(() {
      times = PrayerCalc.getPrayerTimes(
        latitude: 40.7128,
        longitude: -74.0060,
        date: DateTime(2024, 6, 21),
        calculationMethod: CalculationMethod.muslim_world_league,
      );
    });

    test('picks Fajr when now is before Fajr', () {
      final now = times.fajr.subtract(const Duration(hours: 1));
      final next = PrayerCalc.nextPrayerFrom(times, now);
      expect(next.prayer, Prayer.fajr);
      expect(next.time, times.fajr);
    });

    test('picks the correct prayer in the middle of the day', () {
      final now = times.dhuhr.subtract(const Duration(minutes: 1));
      final next = PrayerCalc.nextPrayerFrom(times, now);
      expect(next.prayer, Prayer.dhuhr);
      expect(next.time, times.dhuhr);
    });

    test('falls back to tomorrow Fajr after Isha', () {
      final now = times.isha.add(const Duration(hours: 1));
      final next = PrayerCalc.nextPrayerFrom(times, now);
      expect(next.prayer, Prayer.fajr);
      expect(next.time.isAfter(times.isha), isTrue);
      // Tomorrow's Fajr should be on a later date.
      expect(next.time.day, isNot(equals(now.day)));
    });
  });
}
