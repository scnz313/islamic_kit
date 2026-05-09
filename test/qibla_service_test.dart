import 'package:flutter_test/flutter_test.dart';
import 'package:islamic_kit/islamic_kit.dart';

void main() {
  group('QiblaService.getBearing', () {
    test('returns 0..360 range for a wide sample of coordinates', () {
      final samples = <(double, double)>[
        (0, 0),
        (-89.9, 179.9),
        (89.9, -179.9),
        (21.4225, 39.8262), // on the Kaaba itself
        (40.7128, -74.0060), // New York
        (51.5074, -0.1278), // London
        (35.6762, 139.6503), // Tokyo
        (-33.8688, 151.2093), // Sydney
      ];
      for (final (lat, lon) in samples) {
        final bearing = QiblaService.getBearing(lat, lon);
        expect(bearing, greaterThanOrEqualTo(0),
            reason: 'bearing from ($lat,$lon)');
        expect(bearing, lessThan(360),
            reason: 'bearing from ($lat,$lon)');
      }
    });

    test('known landmark bearings are within 1 degree of published values',
        () {
      // Published Qibla bearings (approximate) for reference cities.
      final expectations = <String, (double, double, double)>{
        // city: (lat, lon, expectedBearingDeg)
        'New York': (40.7128, -74.0060, 58.5),
        'London': (51.5074, -0.1278, 118.9),
        'Tokyo': (35.6762, 139.6503, 293.0),
        'Sydney': (-33.8688, 151.2093, 277.5),
        'Istanbul': (41.0082, 28.9784, 151.8),
      };
      expectations.forEach((city, data) {
        final (lat, lon, expected) = data;
        final actual = QiblaService.getBearing(lat, lon);
        expect(
          (actual - expected).abs(),
          lessThan(1.0),
          reason: '$city bearing expected ≈$expected, got $actual',
        );
      });
    });

    test('throws ArgumentError on invalid coordinates', () {
      expect(() => QiblaService.getBearing(91, 0), throwsArgumentError);
      expect(() => QiblaService.getBearing(-91, 0), throwsArgumentError);
      expect(() => QiblaService.getBearing(0, 181), throwsArgumentError);
      expect(() => QiblaService.getBearing(0, -181), throwsArgumentError);
      expect(() => QiblaService.getBearing(double.nan, 0), throwsArgumentError);
    });
  });

  group('QiblaService.getQiblaDetails', () {
    test('returns 0 km distance at the Kaaba location', () {
      final details = QiblaService.getQiblaDetails(
        KaabaLocation.latitude,
        KaabaLocation.longitude,
      );
      expect(details.distance, lessThan(0.1));
    });

    test('returns sensible distance for known cities', () {
      final ny = QiblaService.getQiblaDetails(40.7128, -74.0060);
      expect(ny.distance, inInclusiveRange(10_000, 12_000));

      final london = QiblaService.getQiblaDetails(51.5074, -0.1278);
      expect(london.distance, inInclusiveRange(4_500, 5_500));

      final tokyo = QiblaService.getQiblaDetails(35.6762, 139.6503);
      expect(tokyo.distance, inInclusiveRange(9_000, 10_000));
    });

    test('QiblaDetails equality and hashCode', () {
      const a = QiblaDetails(bearing: 10, distance: 100);
      const b = QiblaDetails(bearing: 10, distance: 100);
      const c = QiblaDetails(bearing: 11, distance: 100);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });
  });
}
