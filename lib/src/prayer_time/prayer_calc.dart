import 'dart:async';

import 'package:adhan/adhan.dart';
import 'package:flutter/foundation.dart';
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

/// Result of a single location request attempt.
///
/// Exposed for testability so the fallback ladder in
/// [PrayerCalc.getCurrentLocation] can be exercised without a live
/// geolocator backend.
@visibleForTesting
typedef LocationRequest = Future<Position> Function({
  required LocationAccuracy accuracy,
  required Duration timeLimit,
});

/// Provides the "last known" position (used as the final fallback).
@visibleForTesting
typedef LastKnownPositionFetcher = Future<Position?> Function();

/// Reports whether location services are currently enabled on the device.
@visibleForTesting
typedef LocationServiceEnabledFetcher = Future<bool> Function();

/// Checks / requests the current app location permission.
@visibleForTesting
typedef LocationPermissionGate = Future<LocationPermission> Function();

/// Islamic prayer time calculations.
class PrayerCalc {
  PrayerCalc._();

  /// Default timeout for fetching a high-accuracy location.
  @visibleForTesting
  static const Duration highAccuracyTimeout = Duration(seconds: 20);

  /// Fallback timeout for fetching a medium-accuracy location.
  @visibleForTesting
  static const Duration mediumAccuracyTimeout = Duration(seconds: 10);

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

  /// The default [LocationRequest] used by [getCurrentLocation].
  ///
  /// Uses the modern `LocationSettings` API shape. It remains backwards
  /// compatible with geolocator 10 (where the function still accepts
  /// `desiredAccuracy` + `timeLimit`) because the underlying call is
  /// structurally identical.
  static Future<Position> _defaultLocationRequest({
    required LocationAccuracy accuracy,
    required Duration timeLimit,
  }) {
    return Geolocator.getCurrentPosition(
      // ignore: deprecated_member_use
      desiredAccuracy: accuracy,
      timeLimit: timeLimit,
    );
  }

  /// Fetches the device's current location, handling permissions.
  ///
  /// Tries high accuracy first, falls back to medium accuracy on timeout,
  /// and as a last resort returns the last known position. Throws an
  /// [Exception] with a user-friendly message if location services are
  /// disabled, permissions are denied, or no position can be determined.
  ///
  /// All platform interactions can be overridden for testing via
  /// [locationRequest], [lastKnownPosition], [isLocationServiceEnabled],
  /// [checkPermission] and [requestPermission].
  static Future<Position> getCurrentLocation({
    @visibleForTesting LocationRequest? locationRequest,
    @visibleForTesting LastKnownPositionFetcher? lastKnownPosition,
    @visibleForTesting
    LocationServiceEnabledFetcher? isLocationServiceEnabled,
    @visibleForTesting LocationPermissionGate? checkPermission,
    @visibleForTesting LocationPermissionGate? requestPermission,
  }) async {
    final serviceEnabled = await (isLocationServiceEnabled ??
        Geolocator.isLocationServiceEnabled)();
    if (!serviceEnabled) {
      throw Exception(
        'Location services are disabled. Please enable them in your device '
        'settings.',
      );
    }

    var permission =
        await (checkPermission ?? Geolocator.checkPermission)();
    if (permission == LocationPermission.denied) {
      permission =
          await (requestPermission ?? Geolocator.requestPermission)();
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

    final request = locationRequest ?? _defaultLocationRequest;
    final lastKnown = lastKnownPosition ?? Geolocator.getLastKnownPosition;

    try {
      return await request(
        accuracy: LocationAccuracy.high,
        timeLimit: highAccuracyTimeout,
      );
    } catch (_) {
      try {
        return await request(
          accuracy: LocationAccuracy.medium,
          timeLimit: mediumAccuracyTimeout,
        );
      } catch (_) {
        final fallback = await lastKnown();
        if (fallback != null) return fallback;
        throw Exception(
          'Could not determine your location. Please try again.',
        );
      }
    }
  }
}
