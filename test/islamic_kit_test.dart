import 'package:flutter_test/flutter_test.dart';
import 'package:islamic_kit/islamic_kit.dart';

void main() {
  group('islamic_kit barrel file', () {
    test('exports all public API surfaces', () {
      // Compile-time assertions: referencing each type confirms it is
      // exported correctly from the barrel file.
      expect(PrayerCalc, isNotNull);
      expect(QiblaService, isNotNull);
      expect(HijriService, isNotNull);
      expect(IslamicEventService, isNotNull);
      expect(IslamicDateConverter, isNotNull);
      expect(HijriRange.minYear, 1356);
      expect(HijriRange.maxYear, 1500);
      expect(KaabaLocation.latitude, closeTo(21.42, 0.01));
      expect(KaabaLocation.longitude, closeTo(39.83, 0.01));
    });
  });
}
