import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_svg/svg.dart';
import 'package:geocoding/geocoding.dart';
import 'package:islamic_kit/src/prayer_time/prayer_calc.dart';
import 'package:islamic_kit/src/qibla/qibla_service.dart';

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
  Object? _error;
  Stream<CompassEvent>? _compassStream;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    unawaited(_initQibla());
  }

  Future<void> _initQibla() async {
    setState(() {
      _error = null;
      _isLoading = true;
    });
    try {
      final position = await PrayerCalc.getCurrentLocation();
      final qiblaDetails = QiblaService.getQiblaDetails(position.latitude, position.longitude);

      List<Placemark> placemarks = [];
      try {
        placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      } catch (_) {
        placemarks = const [];
      }

      if (mounted) {
        setState(() {
          _qiblaDetails = qiblaDetails;
          _placemark = placemarks.isNotEmpty ? placemarks.first : null;
          _compassStream = kIsWeb ? null : FlutterCompass.events;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e;
          _isLoading = false;
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
    if (_error != null && _qiblaDetails == null) {
      return _QiblaErrorView(
        error: _error!,
        onRetry: _initQibla,
      );
    }

    if (_isLoading && _qiblaDetails == null) {
      return const CircularProgressIndicator();
    }

    if (kIsWeb) {
      return _StaticQiblaView(
        qiblaDetails: _qiblaDetails!,
        placemark: _placemark,
        message:
            'The live compass is not available on the web, but the Qibla bearing below still helps you orient yourself.',
      );
    }

    if (_compassStream == null) {
      return _StaticQiblaView(
        qiblaDetails: _qiblaDetails!,
        placemark: _placemark,
        message:
            'This device does not expose compass sensor data. You can still use the bearing and distance details below.',
      );
    }

    return StreamBuilder<CompassEvent>(
      stream: _compassStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _StaticQiblaView(
            qiblaDetails: _qiblaDetails!,
            placemark: _placemark,
            message:
                'Live heading updates are unavailable right now. Use the Qibla bearing details below instead.',
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }

        final double? direction = snapshot.data?.heading;

        if (direction == null) {
          return _StaticQiblaView(
            qiblaDetails: _qiblaDetails!,
            placemark: _placemark,
            message:
                'Compass heading is unavailable. Calibrate your device or use the bearing details below.',
          );
        }

        return _LiveQiblaView(
          direction: direction,
          qiblaDetails: _qiblaDetails!,
          placemark: _placemark,
        );
      },
    );
  }
}

class _QiblaErrorView extends StatelessWidget {
  const _QiblaErrorView({
    required this.error,
    required this.onRetry,
  });

  final Object error;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final locationError = error is LocationException ? error as LocationException : null;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.explore_off_outlined,
                  size: 42,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 12),
                Text(
                  'Qibla direction needs your location',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString().replaceFirst('Exception: ', ''),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        unawaited(onRetry());
                      },
                      child: const Text('Retry'),
                    ),
                    if (locationError?.type ==
                        LocationIssueType.permissionDeniedForever)
                      OutlinedButton(
                        onPressed: () {
                          unawaited(PrayerCalc.openAppSettings());
                        },
                        child: const Text('Open app settings'),
                      ),
                    if (locationError?.type ==
                            LocationIssueType.servicesDisabled ||
                        locationError?.type == LocationIssueType.unavailable)
                      OutlinedButton(
                        onPressed: () {
                          unawaited(PrayerCalc.openLocationSettings());
                        },
                        child: const Text('Open location settings'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LiveQiblaView extends StatelessWidget {
  const _LiveQiblaView({
    required this.direction,
    required this.qiblaDetails,
    this.placemark,
  });

  final double direction;
  final QiblaDetails qiblaDetails;
  final Placemark? placemark;

  @override
  Widget build(BuildContext context) {
    final alignmentMessage = _alignmentMessage(
      heading: direction,
      qiblaBearing: qiblaDetails.bearing,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _CompassImage(direction: direction, qiblaBearing: qiblaDetails.bearing),
          const SizedBox(height: 20),
          _StatusBanner(message: alignmentMessage),
          const SizedBox(height: 16),
          _InfoPanel(
            qiblaDetails: qiblaDetails,
            placemark: placemark,
            heading: direction,
            statusMessage: alignmentMessage,
          ),
        ],
      ),
    );
  }
}

class _StaticQiblaView extends StatelessWidget {
  const _StaticQiblaView({
    required this.qiblaDetails,
    required this.message,
    this.placemark,
  });

  final QiblaDetails qiblaDetails;
  final String message;
  final Placemark? placemark;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: _StatusBanner(message: message),
          ),
          const SizedBox(height: 20),
          Icon(
            Icons.navigation,
            size: 72,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 8),
          Text(
            'Face ${QiblaService.getCardinalDirection(qiblaDetails.bearing)}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          _InfoPanel(
            qiblaDetails: qiblaDetails,
            placemark: placemark,
            statusMessage: message,
          ),
        ],
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
      ),
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
    final dialRotation = direction * (math.pi / 180) * -1;
    final qiblaRotation = QiblaService.relativeTurnAngle(
          heading: direction,
          qiblaBearing: qiblaBearing,
        ) *
        (math.pi / 180);

    return Stack(
      alignment: Alignment.center,
      children: [
        Transform.rotate(
          angle: dialRotation,
          child: SvgPicture.asset(
            'assets/compass.svg',
            width: 300,
            package: 'islamic_kit',
          ),
        ),
        Transform.rotate(
          angle: qiblaRotation,
          child: Icon(
            Icons.navigation,
            size: 108,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({
    required this.qiblaDetails,
    required this.statusMessage,
    this.placemark,
    this.heading,
  });

  final QiblaDetails qiblaDetails;
  final Placemark? placemark;
  final double? heading;
  final String statusMessage;

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
            const SizedBox(height: 8),
            Text(
              'Face ${QiblaService.getCardinalDirection(qiblaDetails.bearing)}'
              ' (${qiblaDetails.bearing.toStringAsFixed(1)}° from North)',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _InfoItem('Bearing', '${qiblaDetails.bearing.toStringAsFixed(1)}°'),
                _InfoItem('Distance', '${qiblaDetails.distance.toStringAsFixed(0)} km'),
              ],
            ),
            const SizedBox(height: 16),
            if (heading != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: _InfoItem('Current heading', '${heading!.toStringAsFixed(1)}°'),
              ),
            Text(
              statusMessage,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            if (placemark != null)
              Text(
                _formatPlacemark(placemark!),
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

String _alignmentMessage({
  required double heading,
  required double qiblaBearing,
}) {
  final turnAngle = QiblaService.relativeTurnAngle(
    heading: heading,
    qiblaBearing: qiblaBearing,
  );
  if (turnAngle.abs() <= 5) {
    return 'You are aligned with the Qibla.';
  }
  final direction = turnAngle.isNegative ? 'left' : 'right';
  return 'Turn ${turnAngle.abs().toStringAsFixed(0)}° $direction to face the Qibla.';
}

String _formatPlacemark(Placemark placemark) {
  final parts = <String>[
    if (placemark.locality != null && placemark.locality!.isNotEmpty)
      placemark.locality!,
    if (placemark.country != null && placemark.country!.isNotEmpty)
      placemark.country!,
  ];
  return parts.join(', ');
}



