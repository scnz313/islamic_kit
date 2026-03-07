import 'package:adhan/adhan.dart';
import 'package:geolocator/geolocator.dart';

/// Describes the type of failure encountered while retrieving location data.
enum LocationIssueType {
  /// The device location services are switched off.
  servicesDisabled,

  /// The user denied location access for the app.
  permissionDenied,

  /// The user permanently denied location access for the app.
  permissionDeniedForever,

  /// Location retrieval timed out or no fresh fix could be produced.
  unavailable,
}

/// An exception that provides structured details for location-related failures.
class LocationException implements Exception {
  /// Creates a [LocationException].
  const LocationException(this.type, this.message);

  /// The classified failure type.
  final LocationIssueType type;

  /// A user-friendly error message.
  final String message;

  @override
  String toString() => message;
}

/// A service class to calculate Islamic prayer times.
class PrayerCalc {
  /// Calculates prayer times for a given date and location.
  ///
  /// Returns a [PrayerTimes] object from the `adhan` package.
  static PrayerTimes getPrayerTimes({
    required double latitude,
    required double longitude,
    required DateTime date,
    required CalculationMethod calculationMethod,
  }) {
    // Get calculation parameters for the chosen method
    final params = calculationMethod.getParameters();

    // Create the coordinate wrapper required by the adhan package.
    final coordinates = Coordinates(latitude, longitude);

    // Convert DateTime to DateComponents
    final dateComponents = DateComponents.from(date);

    return PrayerTimes(coordinates, dateComponents, params);
  }

  /// A helper to get the device's current location.
  /// Handles permissions and returns a [Position] object.
  static Future<Position> getCurrentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationException(
        LocationIssueType.servicesDisabled,
        'Location services are disabled. Please enable them in your device settings.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw const LocationException(
          LocationIssueType.permissionDenied,
          'Location permission was denied. Please allow access to continue.',
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw const LocationException(
        LocationIssueType.permissionDeniedForever,
        'Location permission is permanently denied. Please enable it from your app settings.',
      );
    }

    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 30),
      );
    } catch (e) {
      try {
        return await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 15),
        );
      } catch (_) {
        final lastKnownPosition = await Geolocator.getLastKnownPosition();
        if (lastKnownPosition != null) {
          return lastKnownPosition;
        }
        throw const LocationException(
          LocationIssueType.unavailable,
          'Unable to determine your location right now. Please move to an open area and try again.',
        );
      }
    }
  }

  /// Opens the app settings screen when the platform supports it.
  static Future<bool> openAppSettings() => Geolocator.openAppSettings();

  /// Opens the device location settings screen when the platform supports it.
  static Future<bool> openLocationSettings() =>
      Geolocator.openLocationSettings();
}
