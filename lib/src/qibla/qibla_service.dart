import 'dart:math';

/// The geographic coordinates of the Kaaba in Makkah.
///
/// These coordinates are used as the target when computing Qibla bearings.
class KaabaLocation {
  /// Latitude of the Kaaba in decimal degrees.
  static const double latitude = 21.4225;

  /// Longitude of the Kaaba in decimal degrees.
  static const double longitude = 39.8262;
}

/// The bearing and distance from an origin to the Kaaba.
class QiblaDetails {
  /// Creates a [QiblaDetails] object.
  ///
  /// [bearing] is expressed in degrees clockwise from North in `[0, 360)`.
  /// [distance] is the great-circle distance to the Kaaba in kilometers.
  const QiblaDetails({required this.bearing, required this.distance})
      : assert(bearing >= 0 && bearing < 360,
            'bearing must be within [0, 360)'),
        assert(distance >= 0, 'distance must be non-negative');

  /// The bearing to the Kaaba in degrees from North, in `[0, 360)`.
  final double bearing;

  /// The great-circle distance to the Kaaba in kilometers.
  final double distance;

  @override
  String toString() =>
      'QiblaDetails(bearing: ${bearing.toStringAsFixed(2)}°, '
      'distance: ${distance.toStringAsFixed(2)} km)';

  @override
  bool operator ==(Object other) =>
      other is QiblaDetails &&
      other.bearing == bearing &&
      other.distance == distance;

  @override
  int get hashCode => Object.hash(bearing, distance);
}

/// Calculates the Qibla direction from any point on Earth.
class QiblaService {
  static const double _earthRadiusKm = 6371.0088;

  static void _validateCoordinates(double latitude, double longitude) {
    if (latitude.isNaN || longitude.isNaN) {
      throw ArgumentError('Latitude and longitude must be finite numbers.');
    }
    if (latitude < -90 || latitude > 90) {
      throw ArgumentError(
          'Latitude must be between -90 and 90 degrees (got $latitude).');
    }
    if (longitude < -180 || longitude > 180) {
      throw ArgumentError(
          'Longitude must be between -180 and 180 degrees (got $longitude).');
    }
  }

  /// Calculates the initial great-circle bearing from ([latitude], [longitude])
  /// to the Kaaba.
  ///
  /// Returns the bearing in degrees clockwise from North in the range
  /// `[0, 360)`. Throws [ArgumentError] if the coordinates are out of range.
  static double getBearing(double latitude, double longitude) {
    _validateCoordinates(latitude, longitude);

    final lat1 = latitude * pi / 180;
    final lon1 = longitude * pi / 180;
    const lat2 = KaabaLocation.latitude * pi / 180;
    const lon2 = KaabaLocation.longitude * pi / 180;
    final dLon = lon2 - lon1;

    final y = sin(dLon) * cos(lat2);
    final x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);

    final bearing = atan2(y, x) * 180 / pi;
    final mod = bearing % 360;
    return mod < 0 ? mod + 360 : mod;
  }

  /// Calculates both the bearing and distance to the Kaaba from
  /// ([latitude], [longitude]).
  static QiblaDetails getQiblaDetails(double latitude, double longitude) {
    _validateCoordinates(latitude, longitude);
    final bearing = getBearing(latitude, longitude);
    final distance = _calculateDistance(latitude, longitude);
    return QiblaDetails(bearing: bearing, distance: distance);
  }

  /// Great-circle distance (Haversine) to the Kaaba in kilometers.
  static double _calculateDistance(double latitude, double longitude) {
    final lat1 = latitude * pi / 180;
    final lon1 = longitude * pi / 180;
    const lat2 = KaabaLocation.latitude * pi / 180;
    const lon2 = KaabaLocation.longitude * pi / 180;

    final dLat = lat2 - lat1;
    final dLon = lon2 - lon1;

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return _earthRadiusKm * c;
  }
}
