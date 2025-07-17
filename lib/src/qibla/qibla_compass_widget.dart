import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_svg/svg.dart';
import 'package:geocoding/geocoding.dart';
import 'package:islamic_kit/islamic_kit.dart';

/// A widget that displays a compass pointing to the Qibla direction.
///
/// It uses the device's location and compass sensors to provide an accurate
/// bearing. A fallback UI is shown on the web.
class QiblaCompassWidget extends StatefulWidget {
  /// Creates a [QiblaCompassWidget].
  const QiblaCompassWidget({super.key});

  @override
  State<QiblaCompassWidget> createState() => _QiblaCompassWidgetState();
}

class _QiblaCompassWidgetState extends State<QiblaCompassWidget> {
  QiblaDetails? _qiblaDetails;
  Placemark? _placemark;
  String? _error;
  Stream<CompassEvent>? _compassStream;
  StreamSubscription<CompassEvent>? _compassSubscription;

  @override
  void initState() {
    super.initState();
    _initQibla();
  }

  @override
  void dispose() {
    _compassSubscription?.cancel();
    super.dispose();
  }

  void _initQibla() async {
    // Clear previous errors
    setState(() => _error = null);
    try {
      debugPrint('[QiblaCompass] Initializing...');
      final position = await PrayerCalc.getCurrentLocation();
      debugPrint('[QiblaCompass] Got position: $position');

      final qiblaDetails = QiblaService.getQiblaDetails(position.latitude, position.longitude);
      debugPrint('[QiblaCompass] Got Qibla details: Bearing=${qiblaDetails.bearing}');

      // Handle placemark lookup failure gracefully as it's non-critical.
      List<Placemark> placemarks = [];
      try {
        placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
        if (placemarks.isNotEmpty) {
          debugPrint('[QiblaCompass] Got placemark: ${placemarks.first.locality}');
        } else {
          debugPrint('[QiblaCompass] placemarkFromCoordinates returned empty list.');
        }
      } catch (e) {
        debugPrint('[QiblaCompass] Could not get placemark: $e. This is non-critical, continuing.');
      }

      if (mounted) {
        setState(() {
          _qiblaDetails = qiblaDetails;
          _placemark = placemarks.isNotEmpty ? placemarks.first : null;
          if (!kIsWeb) {
            _compassStream = FlutterCompass.events;
          }
        });
      }
    } catch (e, stacktrace) {
      debugPrint('[QiblaCompass] Error initializing Qibla: $e');
      debugPrint('[QiblaCompass] Stacktrace: $stacktrace');
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: _buildCompass(),
    );
  }

  Widget _buildCompass() {
    if (_error != null) {
      return _ErrorDisplay(error: _error!, onRetry: _initQibla);
    }

    if (_qiblaDetails == null) {
      return const CircularProgressIndicator();
    }

    if (kIsWeb) {
      return _WebFallback(qiblaDetails: _qiblaDetails!, placemark: _placemark);
    }

    return StreamBuilder<CompassEvent>(
      stream: _compassStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _ErrorDisplay(error: 'Error reading heading: ${snapshot.error}', onRetry: _initQibla);
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }

        final double? direction = snapshot.data?.heading;

        if (direction == null) {
          return _ErrorDisplay(
            error: 'Could not get compass heading. Please ensure your device has compass sensors and they are calibrated.',
            onRetry: _initQibla,
          );
        }

        return _CompassView(
          direction: direction,
          qiblaDetails: _qiblaDetails!,
          placemark: _placemark,
        );
      },
    );
  }
}

class _ErrorDisplay extends StatelessWidget {
  const _ErrorDisplay({required this.error, required this.onRetry});

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(error, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _CompassView extends StatelessWidget {
  const _CompassView({
    required this.direction,
    required this.qiblaDetails,
    this.placemark,
  });

  final double direction;
  final QiblaDetails qiblaDetails;
  final Placemark? placemark;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _CompassImage(direction: direction, qiblaBearing: qiblaDetails.bearing),
        const SizedBox(height: 24),
        _InfoPanel(qiblaDetails: qiblaDetails, placemark: placemark),
      ],
    );
  }
}

class _CompassImage extends StatelessWidget {
  const _CompassImage({
    required this.direction,
    required this.qiblaBearing,
  });

  final double direction;
  final double qiblaBearing;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Transform.rotate(
          angle: (direction * (math.pi / 180) * -1),
          child: SvgPicture.asset(
            'assets/images/compass.svg',
            width: 300,
            package: 'islamic_kit',
          ),
        ),
        Transform.rotate(
          angle: ((qiblaBearing) * (math.pi / 180) * -1) + (direction * (math.pi / 180) * -1),
          child: SvgPicture.asset(
            'assets/images/needle.svg',
            width: 280,
            package: 'islamic_kit',
          ),
        ),
        Positioned(
          top: 10,
          child: Text(
            'N',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 24,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({
    required this.qiblaDetails,
    this.placemark,
  });

  final QiblaDetails qiblaDetails;
  final Placemark? placemark;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Qibla Direction',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _InfoItem('Bearing', '${qiblaDetails.bearing.toStringAsFixed(2)}°'),
                _InfoItem('Distance', '${qiblaDetails.distance.toStringAsFixed(2)} km'),
              ],
            ),
            const SizedBox(height: 16),
            if (placemark != null)
              Text(
                '${placemark!.locality}, ${placemark!.country}',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  const _InfoItem(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 4),
        Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _WebFallback extends StatelessWidget {
  const _WebFallback({
    required this.qiblaDetails,
    this.placemark,
  });

  final QiblaDetails qiblaDetails;
  final Placemark? placemark;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'The live compass is not available on the web. Please use a mobile device for the full experience.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        const SizedBox(height: 24),
        _InfoPanel(qiblaDetails: qiblaDetails, placemark: placemark),
      ],
    );
  }
}



