import 'dart:async';

import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:islamic_kit/src/date_converter/converter.dart';
import 'package:islamic_kit/src/prayer_time/prayer_calc.dart';

/// A widget that displays daily prayer times based on the user's location.
///
/// It automatically fetches the current location, calculates prayer times using
/// the specified `CalculationMethod`, and shows a countdown to the next prayer.
class PrayerTimeWidget extends StatefulWidget {
  /// Creates a [PrayerTimeWidget].
  const PrayerTimeWidget({super.key});

  @override
  State<PrayerTimeWidget> createState() => _PrayerTimeWidgetState();
}

class _PrayerTimeWidgetState extends State<PrayerTimeWidget> {
  PrayerTimes? _prayerTimes;
  SunnahTimes? _sunnahTimes;
  Position? _cachedPosition;
  String? _locationLabel;
  Timer? _timer;
  final ValueNotifier<Duration?> _countdownNotifier =
      ValueNotifier<Duration?>(null);
  Object? _error;
  bool _isLoading = true;
  bool _isRefreshInFlight = false;
  CalculationMethod _selectedCalcMethod = CalculationMethod.muslim_world_league;
  Prayer? _definitiveNextPrayer;
  DateTime? _definitiveNextPrayerTime;
  DateTime? _prayerTimesDate;
  DateTime? _lastAutoRefreshAttemptAt;

  @override
  void initState() {
    super.initState();
    unawaited(_fetchPrayerData(refreshLocation: true));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _countdownNotifier.dispose();
    super.dispose();
  }

  Future<void> _fetchPrayerData({required bool refreshLocation}) async {
    if (_isRefreshInFlight) {
      return;
    }

    _isRefreshInFlight = true;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final position = refreshLocation || _cachedPosition == null
          ? await PrayerCalc.getCurrentLocation()
          : _cachedPosition!;
      final calculationDate = DateTime.now();
      final prayerTimes = PrayerCalc.getPrayerTimes(
        latitude: position.latitude,
        longitude: position.longitude,
        date: calculationDate,
        calculationMethod: _selectedCalcMethod,
      );
      final sunnahTimes = SunnahTimes(prayerTimes);
      final locationLabel = refreshLocation || _locationLabel == null
          ? await _resolveLocationLabel(position)
          : _locationLabel!;

      if (mounted) {
        setState(() {
          _cachedPosition = position;
          _prayerTimes = prayerTimes;
          _sunnahTimes = sunnahTimes;
          _locationLabel = locationLabel;
          _prayerTimesDate = DateTime(
            calculationDate.year,
            calculationDate.month,
            calculationDate.day,
          );
          _lastAutoRefreshAttemptAt = null;
          _isLoading = false;
        });
        _updateNextPrayerInfo();
        _startTimer();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e;
          _isLoading = false;
        });
      }
    } finally {
      _isRefreshInFlight = false;
    }
  }

  Future<String> _resolveLocationLabel(Position position) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isEmpty) {
        return _formatCoordinates(position);
      }

      final placemark = placemarks.first;
      final segments = <String>[
        if (placemark.locality != null && placemark.locality!.isNotEmpty)
          placemark.locality!,
        if (placemark.country != null && placemark.country!.isNotEmpty)
          placemark.country!,
      ];
      return segments.isEmpty ? _formatCoordinates(position) : segments.join(', ');
    } catch (_) {
      return _formatCoordinates(position);
    }
  }

  String _formatCoordinates(Position position) =>
      '${position.latitude.toStringAsFixed(3)}, ${position.longitude.toStringAsFixed(3)}';

  void _updateNextPrayerInfo() {
    if (_prayerTimes == null) {
      return;
    }

    Prayer nextPrayer;
    DateTime nextPrayerTime;
    final now = DateTime.now();

    final rawNextPrayer = _prayerTimes!.nextPrayer();

    if (rawNextPrayer == Prayer.none) {
      // After Isha, so next prayer is Fajr tomorrow
      nextPrayer = Prayer.fajr;
      final tomorrow = DateComponents.from(now.add(const Duration(days: 1)));
      final tomorrowPrayerTimes = PrayerTimes(
        _prayerTimes!.coordinates,
        tomorrow,
        _prayerTimes!.calculationParameters,
      );
      nextPrayerTime = tomorrowPrayerTimes.fajr;
    } else if (rawNextPrayer.name == 'fajrafter') {
      nextPrayer = Prayer.fajr;
      nextPrayerTime = _prayerTimes!.fajr;
    } else {
      nextPrayer = rawNextPrayer;
      final prayerTime = _prayerTimes!.timeForPrayer(rawNextPrayer);
      if (prayerTime == null) {
        nextPrayerTime = now;
      } else {
        nextPrayerTime = prayerTime;
      }
    }

    final duration = nextPrayerTime.difference(now);
    final countdown = duration.isNegative ? Duration.zero : duration;
    _countdownNotifier.value = countdown;

    final nextPrayerChanged = nextPrayer != _definitiveNextPrayer ||
        nextPrayerTime != _definitiveNextPrayerTime;
    _definitiveNextPrayer = nextPrayer;
    _definitiveNextPrayerTime = nextPrayerTime;
    if (nextPrayerChanged && mounted) {
      setState(() {});
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _prayerTimes == null) {
        return;
      }

      final now = DateTime.now();
      if (_prayerTimesDate != null && !_isSameDay(_prayerTimesDate!, now)) {
        final canAttemptRefresh = _lastAutoRefreshAttemptAt == null ||
            now.difference(_lastAutoRefreshAttemptAt!) >=
                const Duration(minutes: 1);
        if (canAttemptRefresh) {
          _lastAutoRefreshAttemptAt = now;
          unawaited(_fetchPrayerData(refreshLocation: false));
        }
        return;
      }

      _updateNextPrayerInfo();
    });
  }

  bool _isSameDay(DateTime first, DateTime second) =>
      first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;

  void _onCalculationMethodChanged(CalculationMethod? method) {
    if (method != null && method != _selectedCalcMethod) {
      setState(() {
        _selectedCalcMethod = method;
      });
      unawaited(_fetchPrayerData(refreshLocation: false));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null && _prayerTimes == null) {
      return _PrayerErrorView(
        error: _error!,
        onRetry: () {
          unawaited(_fetchPrayerData(refreshLocation: true));
        },
      );
    }

    return _isLoading && _prayerTimes == null
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _PrayerHeader(
                  location: _locationLabel ?? 'Current location',
                  selectedCalcMethod: _selectedCalcMethod,
                  onMethodChanged: _onCalculationMethodChanged,
                  onRefreshLocation: () {
                    unawaited(_fetchPrayerData(refreshLocation: true));
                  },
                  isRefreshing: _isLoading,
                ),
                const SizedBox(height: 24),
                if (_definitiveNextPrayer != null &&
                    _definitiveNextPrayerTime != null)
                  _NextPrayerCountdown(
                    nextPrayer: _definitiveNextPrayer!,
                    nextPrayerTime: _definitiveNextPrayerTime!,
                    countdownListenable: _countdownNotifier,
                  ),
                const SizedBox(height: 24),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: _InlineStatusCard(
                      message: _error.toString().replaceFirst('Exception: ', ''),
                      icon: Icons.info_outline,
                    ),
                  ),
                _PrayerTimesList(
                  prayerTimes: _prayerTimes!,
                  sunnahTimes: _sunnahTimes!,
                  nextPrayer: _definitiveNextPrayer!,
                ),
              ],
            ),
          );
  }
}

class _PrayerHeader extends StatelessWidget {
  const _PrayerHeader({
    required this.location,
    required this.selectedCalcMethod,
    required this.onMethodChanged,
    required this.onRefreshLocation,
    required this.isRefreshing,
  });

  final String location;
  final CalculationMethod selectedCalcMethod;
  final ValueChanged<CalculationMethod?> onMethodChanged;
  final VoidCallback onRefreshLocation;
  final bool isRefreshing;

  @override
  Widget build(BuildContext context) {
    final hijriDate = IslamicDateConverter.gregorianToHijri(DateTime.now());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('EEEE, d MMMM yyyy').format(DateTime.now()),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hijriDate.toFormat('d MMMM yyyy'),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.color
                              ?.withAlpha(180),
                        ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Refresh location and times',
              onPressed: isRefreshing ? null : onRefreshLocation,
              icon: isRefreshing
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          location,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<CalculationMethod>(
          value: selectedCalcMethod,
          decoration: InputDecoration(
            labelText: 'Calculation Method',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
          ),
          items: CalculationMethod.values.map((method) {
            return DropdownMenuItem<CalculationMethod>(
              value: method,
              child: Text(method.name.replaceAll('_', ' ').split(' ').map((l) => l[0].toUpperCase() + l.substring(1)).join(' ')),
            );
          }).toList(),
          onChanged: onMethodChanged,
        ),
      ],
    );
  }
}

class _NextPrayerCountdown extends StatelessWidget {
  const _NextPrayerCountdown({
    required this.nextPrayer,
    required this.nextPrayerTime,
    required this.countdownListenable,
  });

  final Prayer nextPrayer;
  final DateTime nextPrayerTime;
  final ValueListenable<Duration?> countdownListenable;

  @override
  Widget build(BuildContext context) {
    final formattedTime = DateFormat.jm().format(nextPrayerTime);

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.primaryContainer],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Text(
              'Next Prayer: ${_formatPrayerName(nextPrayer.name)}',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              formattedTime,
              style: Theme.of(context).textTheme.displaySmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w200),
            ),
            const SizedBox(height: 16),
            ValueListenableBuilder<Duration?>(
              valueListenable: countdownListenable,
              builder: (context, countdown, child) {
                if (countdown == null || countdown.isNegative) {
                  return const SizedBox.shrink();
                }

                return Text(
                  '-${(countdown.inHours).toString().padLeft(2, '0')}:${(countdown.inMinutes % 60).toString().padLeft(2, '0')}:${(countdown.inSeconds % 60).toString().padLeft(2, '0')}',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(color: Colors.white70),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PrayerTimesList extends StatelessWidget {
  const _PrayerTimesList({
    required this.prayerTimes,
    required this.sunnahTimes,
    required this.nextPrayer,
  });

  final PrayerTimes prayerTimes;
  final SunnahTimes sunnahTimes;
  final Prayer nextPrayer;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          children: [
            _buildPrayerRow(context, Prayer.fajr, prayerTimes.fajr),
            _buildPrayerRow(context, Prayer.sunrise, prayerTimes.sunrise),
            _buildPrayerRow(context, Prayer.dhuhr, prayerTimes.dhuhr),
            _buildPrayerRow(context, Prayer.asr, prayerTimes.asr),
            _buildPrayerRow(context, Prayer.maghrib, prayerTimes.maghrib),
            _buildPrayerRow(context, Prayer.isha, prayerTimes.isha),
            const Divider(height: 24, indent: 16, endIndent: 16),
            _buildPrayerRow(context, 'Qiyam', sunnahTimes.lastThirdOfTheNight, isSunnah: true),
          ],
        ),
      ),
    );
  }

  Widget _buildPrayerRow(BuildContext context, dynamic prayer, DateTime time, {bool isSunnah = false}) {
    final prayerName = prayer is Prayer ? prayer.name : prayer.toString();
    final isNextPrayer = !isSunnah && prayer == nextPrayer;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: isNextPrayer ? Theme.of(context).colorScheme.primary.withAlpha(26) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _formatPrayerName(prayerName),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: isNextPrayer ? FontWeight.bold : FontWeight.normal,
                  color: isNextPrayer ? Theme.of(context).colorScheme.primary : null,
                ),
          ),
          Text(
            DateFormat.jm().format(time),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: isNextPrayer ? FontWeight.bold : FontWeight.normal,
                  color: isNextPrayer ? Theme.of(context).colorScheme.primary : null,
                ),
          ),
        ],
      ),
    );
  }
}

class _PrayerErrorView extends StatelessWidget {
  const _PrayerErrorView({
    required this.error,
    required this.onRetry,
  });

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final locationError = error is LocationException ? error as LocationException : null;

    return Center(
      child: Padding(
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
                    Icons.location_off_outlined,
                    size: 42,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Prayer times need your location',
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
                        onPressed: onRetry,
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
                          locationError?.type ==
                              LocationIssueType.unavailable)
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
      ),
    );
  }
}

class _InlineStatusCard extends StatelessWidget {
  const _InlineStatusCard({
    required this.message,
    required this.icon,
  });

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}

String _formatPrayerName(String name) =>
    name[0].toUpperCase() + name.substring(1).replaceAll('_', ' ');

