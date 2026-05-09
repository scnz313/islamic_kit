import 'dart:async';

import 'package:adhan/adhan.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:islamic_kit/islamic_kit.dart';

Position _fakePosition({double latitude = 40.7128, double longitude = -74.0060}) {
  return Position(
    latitude: latitude,
    longitude: longitude,
    timestamp: DateTime.utc(2024, 1, 1),
    accuracy: 5,
    altitude: 0,
    altitudeAccuracy: 0,
    heading: 0,
    headingAccuracy: 0,
    speed: 0,
    speedAccuracy: 0,
  );
}

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

  group('PrayerCalc.getCurrentLocation (injected fakes)', () {
    test('throws when location services are disabled', () async {
      expect(
        () => PrayerCalc.getCurrentLocation(
          isLocationServiceEnabled: () async => false,
          checkPermission: () async => LocationPermission.always,
          requestPermission: () async => LocationPermission.always,
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Location services are disabled'),
        )),
      );
    });

    test('throws when permission is denied after requesting', () async {
      expect(
        () => PrayerCalc.getCurrentLocation(
          isLocationServiceEnabled: () async => true,
          checkPermission: () async => LocationPermission.denied,
          requestPermission: () async => LocationPermission.denied,
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Location permissions are denied'),
        )),
      );
    });

    test('throws when permission is deniedForever', () async {
      expect(
        () => PrayerCalc.getCurrentLocation(
          isLocationServiceEnabled: () async => true,
          checkPermission: () async => LocationPermission.deniedForever,
          requestPermission: () async => LocationPermission.deniedForever,
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('permanently denied'),
        )),
      );
    });

    test('returns the high-accuracy position when available', () async {
      final highAccuracyPosition = _fakePosition(latitude: 1, longitude: 2);
      final mediumAccuracyCalls = <LocationAccuracy>[];
      final result = await PrayerCalc.getCurrentLocation(
        isLocationServiceEnabled: () async => true,
        checkPermission: () async => LocationPermission.always,
        requestPermission: () async => LocationPermission.always,
        locationRequest: ({required accuracy, required timeLimit}) async {
          mediumAccuracyCalls.add(accuracy);
          return highAccuracyPosition;
        },
        lastKnownPosition: () async => null,
      );
      expect(result, same(highAccuracyPosition));
      expect(mediumAccuracyCalls, [LocationAccuracy.high]);
    });

    test('falls back to medium accuracy when high-accuracy times out',
        () async {
      final fallback = _fakePosition(latitude: 10, longitude: 20);
      final callsSeen = <LocationAccuracy>[];
      final result = await PrayerCalc.getCurrentLocation(
        isLocationServiceEnabled: () async => true,
        checkPermission: () async => LocationPermission.always,
        requestPermission: () async => LocationPermission.always,
        locationRequest: ({required accuracy, required timeLimit}) async {
          callsSeen.add(accuracy);
          if (accuracy == LocationAccuracy.high) {
            throw TimeoutException('timed out');
          }
          return fallback;
        },
        lastKnownPosition: () async => null,
      );
      expect(result, same(fallback));
      expect(
        callsSeen,
        [LocationAccuracy.high, LocationAccuracy.medium],
        reason: 'should have attempted high then fallen back to medium',
      );
    });

    test(
        'falls back to last-known position when both high and medium accuracy '
        'fail', () async {
      final lastKnown = _fakePosition(latitude: 30, longitude: 40);
      final result = await PrayerCalc.getCurrentLocation(
        isLocationServiceEnabled: () async => true,
        checkPermission: () async => LocationPermission.always,
        requestPermission: () async => LocationPermission.always,
        locationRequest: ({required accuracy, required timeLimit}) async {
          throw TimeoutException('nope');
        },
        lastKnownPosition: () async => lastKnown,
      );
      expect(result, same(lastKnown));
    });

    test('throws a user-friendly error when every source fails', () async {
      expect(
        () => PrayerCalc.getCurrentLocation(
          isLocationServiceEnabled: () async => true,
          checkPermission: () async => LocationPermission.always,
          requestPermission: () async => LocationPermission.always,
          locationRequest: ({required accuracy, required timeLimit}) async {
            throw TimeoutException('nope');
          },
          lastKnownPosition: () async => null,
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Could not determine your location'),
        )),
      );
    });

    test('requests permission only when initial checkPermission is denied',
        () async {
      var requestPermissionCalled = 0;
      await PrayerCalc.getCurrentLocation(
        isLocationServiceEnabled: () async => true,
        checkPermission: () async => LocationPermission.always,
        requestPermission: () async {
          requestPermissionCalled++;
          return LocationPermission.always;
        },
        locationRequest: ({required accuracy, required timeLimit}) async =>
            _fakePosition(),
        lastKnownPosition: () async => null,
      );
      expect(requestPermissionCalled, 0);
    });
  });
}
