import 'package:adhan/adhan.dart';
import 'package:geolocator/geolocator.dart';

/// Pre-computed prayer times for a given day, plus convenience helpers.
class DailyPrayerTimes {
  /// Creates a [DailyPrayerTimes].
  const DailyPrayerTimes(this.prayerTimes);

  /// The underlying [PrayerTimes] from the `adhan` package.
  final PrayerTimes prayerTimes;

  /// Returns the [DateTime] for the given [Prayer], or `null` if not
  /// applicable (e.g. [Prayer.none]).
  DateTime? timeFor(Prayer prayer) => prayerTimes.timeForPrayer(prayer);

  /// Returns `true` if [now] falls before the next prayer of the day.
  bool hasPrayerAfter(DateTime now) =>
      prayerTimes.nextPrayerByDateTime(now) != Prayer.none;
}

/// Islamic prayer time calculations.
class PrayerCalc {
  PrayerCalc._();

  /// Default timeout for fetching a high-accuracy location.
  static const Duration _highAccuracyTimeout = Duration(seconds: 20);

  /// Fallback timeout for fetching a medium-accuracy location.
  static const Duration _mediumAccuracyTimeout = Duration(seconds: 10);

  /// Calculates prayer times for a given [date] and location.
  ///
  /// Throws [ArgumentError] if [latitude] or [longitude] are out of range.
  static PrayerTimes getPrayerTimes({
    required double latitude,
    required double longitude,
    required DateTime date,
    required CalculationMethod calculationMethod,
    Madhab madhab = Madhab.shafi,
  }) {
    if (latitude < -90 || latitude > 90 || latitude.isNaN) {
      throw ArgumentError(
          'Latitude must be between -90 and 90 (got $latitude).');
    }
    if (longitude < -180 || longitude > 180 || longitude.isNaN) {
      throw ArgumentError(
          'Longitude must be between -180 and 180 (got $longitude).');
    }

    final params = calculationMethod.getParameters()..madhab = madhab;
    final coordinates = Coordinates(latitude, longitude);
    final components = DateComponents.from(date);
    return PrayerTimes(coordinates, components, params);
  }

  /// Returns the next [Prayer] and its scheduled [DateTime] relative to
  /// [now] for the location embedded in [prayerTimes]. If [now] is past the
  /// last prayer of the day, this returns tomorrow's Fajr.
  static ({Prayer prayer, DateTime time}) nextPrayerFrom(
      PrayerTimes prayerTimes, DateTime now) {
    final next = prayerTimes.nextPrayerByDateTime(now);
    if (next != Prayer.none) {
      final time = prayerTimes.timeForPrayer(next);
      if (time != null) {
        return (prayer: next, time: time);
      }
    }
    // Past Isha — next prayer is tomorrow's Fajr.
    final tomorrow = DateComponents.from(now.add(const Duration(days: 1)));
    final tomorrowTimes = PrayerTimes(
      prayerTimes.coordinates,
      tomorrow,
      prayerTimes.calculationParameters,
    );
    return (prayer: Prayer.fajr, time: tomorrowTimes.fajr);
  }

  /// Fetches the device's current location, handling permissions.
  ///
  /// Throws an [Exception] with a user-friendly message if location services
  /// are disabled or permissions are denied.
  static Future<Position> getCurrentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception(
        'Location services are disabled. Please enable them in your device '
        'settings.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception(
          'Location permissions are denied. Please enable them in your app '
          'settings.',
        );
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Location permissions are permanently denied. Please enable them in '
        'your app settings.',
      );
    }

    // Try high accuracy first, fall back to medium accuracy on timeout.
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: _highAccuracyTimeout,
      );
    } catch (_) {
      try {
        return await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: _mediumAccuracyTimeout,
        );
      } catch (_) {
        // Last-chance: use the last known position if available.
        final lastKnown = await Geolocator.getLastKnownPosition();
        if (lastKnown != null) return lastKnown;
        throw Exception(
          'Could not determine your location. Please try again.',
        );
      }
    }
  }
}
