import 'package:flutter_test/flutter_test.dart';
import 'package:islamic_kit/src/qibla/qibla_service.dart';

void main() {
  group('QiblaService', () {
    test('calculates a plausible bearing for London', () {
      final bearing = QiblaService.getBearing(51.5074, -0.1278);

      expect(bearing, inInclusiveRange(118, 120));
    });

    test('calculates distance details to the Kaaba', () {
      final details = QiblaService.getQiblaDetails(51.5074, -0.1278);

      expect(details.distance, closeTo(4789, 25));
      expect(details.bearing, inInclusiveRange(118, 120));
    });

    test('computes the shortest relative turn angle', () {
      expect(
        QiblaService.relativeTurnAngle(
          heading: 350,
          qiblaBearing: 10,
        ),
        closeTo(20, 0.001),
      );
      expect(
        QiblaService.relativeTurnAngle(
          heading: 10,
          qiblaBearing: 350,
        ),
        closeTo(-20, 0.001),
      );
    });

    test('returns readable cardinal directions', () {
      expect(QiblaService.getCardinalDirection(0), 'N');
      expect(QiblaService.getCardinalDirection(90), 'E');
      expect(QiblaService.getCardinalDirection(225), 'SW');
    });
  });
}
