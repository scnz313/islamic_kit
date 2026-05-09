import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geocoding/geocoding.dart';
import 'package:islamic_kit/src/prayer_time/prayer_calc.dart';
import 'package:islamic_kit/src/qibla/qibla_service.dart';

/// A widget that displays a compass pointing to the Qibla direction.
///
/// It uses the device's location and compass sensors to provide an accurate
/// bearing. A fallback UI is shown on the web and on devices without a
/// compass sensor.
///
/// The compass is rendered with [CustomPaint] so it has no asset dependencies
/// and renders reliably in tests and on all platforms.
class QiblaCompassWidget extends StatefulWidget {
  /// Creates a [QiblaCompassWidget].
  ///
  /// [size] controls the diameter of the compass. Defaults to 280 logical
  /// pixels. [showInfoPanel] toggles the Bearing/Distance/City info card.
  const QiblaCompassWidget({
    super.key,
    this.size = 280,
    this.showInfoPanel = true,
  });

  /// Diameter of the compass widget in logical pixels.
  final double size;

  /// Whether the info panel (bearing / distance / city) is shown below the
  /// compass. Defaults to `true`.
  final bool showInfoPanel;

  @override
  State<QiblaCompassWidget> createState() => _QiblaCompassWidgetState();
}

class _QiblaCompassWidgetState extends State<QiblaCompassWidget> {
  QiblaDetails? _qiblaDetails;
  Placemark? _placemark;
  String? _error;
  final bool _compassAvailable = !kIsWeb;

  @override
  void initState() {
    super.initState();
    _initQibla();
  }

  Future<void> _initQibla() async {
    setState(() {
      _error = null;
      _qiblaDetails = null;
      _placemark = null;
    });
    try {
      final position = await PrayerCalc.getCurrentLocation();
      final qiblaDetails =
          QiblaService.getQiblaDetails(position.latitude, position.longitude);

      // Placemark lookup is best-effort; a failure here must not break the
      // compass UI.
      Placemark? placemark;
      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          placemark = placemarks.first;
        }
      } catch (_) {
        placemark = null;
      }

      if (!mounted) return;
      setState(() {
        _qiblaDetails = qiblaDetails;
        _placemark = placemark;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return _ErrorDisplay(error: _error!, onRetry: _initQibla);
    }
    if (_qiblaDetails == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (kIsWeb || !_compassAvailable) {
      return _buildStatic(_qiblaDetails!, bearingOverride: null);
    }

    return StreamBuilder<CompassEvent>(
      stream: FlutterCompass.events,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _ErrorDisplay(
            error: 'Error reading compass: ${snapshot.error}',
            onRetry: _initQibla,
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final heading = snapshot.data?.heading;
        if (heading == null) {
          // Sensor not available on this device, fall back to static view.
          return _buildStatic(_qiblaDetails!, bearingOverride: null);
        }
        return _buildStatic(_qiblaDetails!, bearingOverride: heading);
      },
    );
  }

  Widget _buildStatic(QiblaDetails details, {double? bearingOverride}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _CompassView(
            size: widget.size,
            qiblaBearing: details.bearing,
            deviceHeading: bearingOverride,
          ),
          if (widget.showInfoPanel) ...[
            const SizedBox(height: 16),
            _InfoPanel(
              qiblaDetails: details,
              placemark: _placemark,
              liveCompass: bearingOverride != null,
            ),
          ],
        ],
      ),
    );
  }
}

/// Normalizes any degree value into the [0, 360) range.
///
/// Some devices / platforms (notably older Android devices) return heading
/// values in `(-180, 180]` which must be normalized before rendering.
@visibleForTesting
double normalizeDegrees(double value) {
  final mod = value % 360;
  return mod < 0 ? mod + 360 : mod;
}

/// Renders the compass face and a needle that points to the Qibla.
///
/// If [deviceHeading] is non-null, the needle rotates relative to the device
/// heading so that it physically points towards the Qibla. Otherwise the
/// needle points to the Qibla bearing from North (useful as a static view
/// on the web / on devices without a compass sensor).
class _CompassView extends StatelessWidget {
  const _CompassView({
    required this.size,
    required this.qiblaBearing,
    required this.deviceHeading,
  });

  final double size;
  final double qiblaBearing;
  final double? deviceHeading;

  @override
  Widget build(BuildContext context) {
    final heading =
        deviceHeading == null ? 0.0 : normalizeDegrees(deviceHeading!);
    // When the device heading matches the Qibla bearing, the needle should
    // point "up" (0 radians). Otherwise the needle should point at
    // (qiblaBearing - heading) degrees clockwise from up.
    final needleAngleDeg = normalizeDegrees(qiblaBearing - heading);
    final needleAngleRad = needleAngleDeg * (math.pi / 180);

    // Indicate to the user when they are aligned with the Qibla.
    final aligned = _isAligned(needleAngleDeg);

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CompassPainter(
          needleAngle: needleAngleRad,
          aligned: aligned,
          primary: Theme.of(context).colorScheme.primary,
          onSurface: Theme.of(context).colorScheme.onSurface,
          surface: Theme.of(context).colorScheme.surface,
        ),
      ),
    );
  }

  bool _isAligned(double angleDeg) {
    // Within 5 degrees of Qibla direction.
    final delta = math.min(angleDeg, 360 - angleDeg);
    return delta <= 5;
  }
}

class _CompassPainter extends CustomPainter {
  _CompassPainter({
    required this.needleAngle,
    required this.aligned,
    required this.primary,
    required this.onSurface,
    required this.surface,
  });

  final double needleAngle;
  final bool aligned;
  final Color primary;
  final Color onSurface;
  final Color surface;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;

    // Compass face.
    final facePaint = Paint()..color = surface;
    canvas.drawCircle(center, radius, facePaint);
    final borderPaint = Paint()
      ..color = onSurface.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius - 1, borderPaint);

    // Cardinal tick marks.
    final tickPaint = Paint()
      ..color = onSurface.withValues(alpha: 0.6)
      ..strokeWidth = 2;
    for (var i = 0; i < 360; i += 30) {
      final angle = i * math.pi / 180;
      final isCardinal = i % 90 == 0;
      final innerR = radius - (isCardinal ? 16 : 8);
      final p1 = Offset(
        center.dx + innerR * math.sin(angle),
        center.dy - innerR * math.cos(angle),
      );
      final p2 = Offset(
        center.dx + (radius - 2) * math.sin(angle),
        center.dy - (radius - 2) * math.cos(angle),
      );
      canvas.drawLine(
        p1,
        p2,
        tickPaint..strokeWidth = isCardinal ? 3 : 1.5,
      );
    }

    // Cardinal labels.
    const labels = {0: 'N', 90: 'E', 180: 'S', 270: 'W'};
    labels.forEach((deg, label) {
      final angle = deg * math.pi / 180;
      final labelR = radius - 30;
      final pos = Offset(
        center.dx + labelR * math.sin(angle),
        center.dy - labelR * math.cos(angle),
      );
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            color: deg == 0 ? primary : onSurface,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
    });

    // Needle.
    final needleColor = aligned ? Colors.green : primary;
    final needleLength = radius - 30;
    final needleWidth = 16.0;
    final needlePath = Path()
      ..moveTo(center.dx, center.dy - needleLength)
      ..lineTo(center.dx - needleWidth / 2, center.dy)
      ..lineTo(center.dx + needleWidth / 2, center.dy)
      ..close();

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(needleAngle);
    canvas.translate(-center.dx, -center.dy);
    canvas.drawPath(
      needlePath,
      Paint()..color = needleColor,
    );
    // Tail of needle (opposite direction, lighter color).
    final tailPath = Path()
      ..moveTo(center.dx, center.dy + needleLength)
      ..lineTo(center.dx - needleWidth / 2, center.dy)
      ..lineTo(center.dx + needleWidth / 2, center.dy)
      ..close();
    canvas.drawPath(
      tailPath,
      Paint()..color = onSurface.withValues(alpha: 0.3),
    );
    canvas.restore();

    // Center hub.
    canvas.drawCircle(
      center,
      8,
      Paint()..color = needleColor,
    );
    canvas.drawCircle(
      center,
      8,
      Paint()
        ..color = surface
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _CompassPainter oldDelegate) =>
      oldDelegate.needleAngle != needleAngle ||
      oldDelegate.aligned != aligned ||
      oldDelegate.primary != primary ||
      oldDelegate.onSurface != onSurface ||
      oldDelegate.surface != surface;
}

class _ErrorDisplay extends StatelessWidget {
  const _ErrorDisplay({required this.error, required this.onRetry});

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 40,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 8),
            Text(error, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({
    required this.qiblaDetails,
    required this.placemark,
    required this.liveCompass,
  });

  final QiblaDetails qiblaDetails;
  final Placemark? placemark;
  final bool liveCompass;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('Qibla Direction',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _InfoItem(
                  label: 'Bearing',
                  value: '${qiblaDetails.bearing.toStringAsFixed(1)}°',
                ),
                _InfoItem(
                  label: 'Distance',
                  value: _formatDistance(qiblaDetails.distance),
                ),
              ],
            ),
            if (placemark != null) ...[
              const SizedBox(height: 12),
              Text(
                [placemark!.locality, placemark!.country]
                    .whereType<String>()
                    .where((s) => s.isNotEmpty)
                    .join(', '),
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ],
            if (!liveCompass) ...[
              const SizedBox(height: 12),
              Text(
                'Live compass is not available. The needle shows the bearing '
                'to the Qibla from North.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDistance(double km) {
    if (km < 1) {
      return '${(km * 1000).toStringAsFixed(0)} m';
    }
    if (km < 10) {
      return '${km.toStringAsFixed(2)} km';
    }
    return '${km.toStringAsFixed(0)} km';
  }
}

class _InfoItem extends StatelessWidget {
  const _InfoItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
