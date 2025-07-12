import 'dart:math';

/// A data class to hold the Qibla bearing and distance.
class QiblaDetails {
  /// Creates a [QiblaDetails] object.
  QiblaDetails({required this.bearing, required this.distance});

  /// The bearing to the Kaaba in degrees from North.
  final double bearing;

  /// The distance to the Kaaba in kilometers.
  final double distance;
}

/// A service class to calculate the Qibla direction.
class QiblaService {
  static const double _kaabaLatitude = 21.422487;
  static const double _kaabaLongitude = 39.826206;

  /// Calculates the Qibla bearing in degrees from North.
  ///
  /// Takes the device's current [latitude] and [longitude] as input.
  static double getBearing(double latitude, double longitude) {
    final double latRad = latitude * (pi / 180);
    final double lonRad = longitude * (pi / 180);
    const double kaabaLatRad = _kaabaLatitude * (pi / 180);
    const double kaabaLonRad = _kaabaLongitude * (pi / 180);

    final double lonDiff = kaabaLonRad - lonRad;

    final double y = sin(lonDiff) * cos(kaabaLatRad);
    final double x =
        cos(latRad) * sin(kaabaLatRad) - sin(latRad) * cos(kaabaLatRad) * cos(lonDiff);

    final double bearing = atan2(y, x);
    return (bearing * (180 / pi) + 360) % 360;
  }

  /// Calculates both the bearing and distance to the Kaaba.
  static QiblaDetails getQiblaDetails(double latitude, double longitude) {
    final bearing = getBearing(latitude, longitude);
    final distance = _calculateDistance(latitude, longitude);
    return QiblaDetails(bearing: bearing, distance: distance);
  }

  /// Calculates the distance to the Kaaba in kilometers.
  static double _calculateDistance(double latitude, double longitude) {
    const double earthRadius = 6371; // in kilometers

    final double latRad1 = latitude * (pi / 180);
    final double lonRad1 = longitude * (pi / 180);
    const double latRad2 = _kaabaLatitude * (pi / 180);
    const double lonRad2 = _kaabaLongitude * (pi / 180);

    final double dLat = latRad2 - latRad1;
    final double dLon = lonRad2 - lonRad1;

    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(latRad1) * cos(latRad2) * sin(dLon / 2) * sin(dLon / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }
}

