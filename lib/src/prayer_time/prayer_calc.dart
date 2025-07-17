import 'package:adhan/adhan.dart';
import 'package:geolocator/geolocator.dart';

/// A service class to calculate Islamic prayer times.
class PrayerCalc {
  /// Calculates prayer times for a given date and location.
  ///
  /// Returns a [PrayerTimes] object from the `adhan_dart` package.
  static PrayerTimes getPrayerTimes({
    required double latitude,
    required double longitude,
    required DateTime date,
    required CalculationMethod calculationMethod,
  }) {
    // Get calculation parameters for the chosen method
    final params = calculationMethod.getParameters();

    // Create coordinates wrapper required by adhan_dart
    final coordinates = Coordinates(latitude, longitude);

    // Convert DateTime to DateComponents
    final dateComponents = DateComponents.from(date);

    // adhan_dart >=1.1.0 expects **named** parameters
    return PrayerTimes(coordinates, dateComponents, params);
  }

  /// A helper to get the device's current location.
  /// Handles permissions and returns a [Position] object.
  static Future<Position> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled. Please enable them in your device settings.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied. Please enable them in your app settings.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied. Please enable them in your app settings.');
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 30),
      );
    } catch (e) {
      // Fallback to lower accuracy if high accuracy times out
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 15),
      );
    }
  }
}
