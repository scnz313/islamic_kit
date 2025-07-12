import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:adhan/adhan.dart';
import 'package:geocoding/geocoding.dart';
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
  String? _location;
  Timer? _timer;
  Duration? _timeUntilNextPrayer;
  String? _error;
  CalculationMethod _selectedCalcMethod = CalculationMethod.muslim_world_league;

  // Add state for the definitive next prayer
  Prayer? _definitiveNextPrayer;
  DateTime? _definitiveNextPrayerTime;

  @override
  void initState() {
    super.initState();
    _fetchPrayerData();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchPrayerData() async {
    // Clear previous errors and set loading state
    setState(() {
      _error = null;
    });

    try {
      debugPrint('[PrayerTime] Fetching prayer data...');
      final position = await PrayerCalc.getCurrentLocation();
      debugPrint('[PrayerTime] Got position: $position');

      final prayerTimes = PrayerCalc.getPrayerTimes(
        latitude: position.latitude,
        longitude: position.longitude,
        date: DateTime.now(),
        calculationMethod: _selectedCalcMethod,
      );

      // Handle placemark lookup failure gracefully as it's non-critical.
      List<Placemark> placemarks = [];
      try {
        placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
        if (placemarks.isNotEmpty) {
          debugPrint('[PrayerTime] Got placemark: ${placemarks.first.locality}');
        } else {
          debugPrint('[PrayerTime] placemarkFromCoordinates returned empty list.');
        }
      } catch (e) {
        debugPrint('[PrayerTime] Could not get placemark: $e. This is non-critical, continuing.');
      }

      final sunnahTimes = SunnahTimes(prayerTimes);

      if (mounted) {
        setState(() {
          _prayerTimes = prayerTimes;
          _sunnahTimes = sunnahTimes;
          _location = placemarks.isNotEmpty ? '${placemarks.first.locality}, ${placemarks.first.country}' : 'Unknown Location';
          _updateNextPrayerInfo(); // Initial update
        });
        _startTimer();
      }
      debugPrint('[PrayerTime] Calculated prayer times successfully.');
    } catch (e, stacktrace) {
      debugPrint('[PrayerTime] Error fetching prayer data: $e');
      debugPrint('[PrayerTime] Stacktrace: $stacktrace');
      if (mounted) {
        setState(() {
          // Strip the 'Exception: ' prefix for a cleaner message.
          _error = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  void _updateNextPrayerInfo() {
    if (_prayerTimes == null) return;

    Prayer nextPrayer;
    DateTime nextPrayerTime;
    final now = DateTime.now();

    if (_prayerTimes!.nextPrayer() == Prayer.none) {
      // After Isha, so next prayer is Fajr tomorrow
      nextPrayer = Prayer.fajr;
      final tomorrow = DateComponents.from(now.add(const Duration(days: 1)));
      final tomorrowPrayerTimes = PrayerTimes(_prayerTimes!.coordinates,
          tomorrow, _prayerTimes!.calculationParameters);
      nextPrayerTime = tomorrowPrayerTimes.fajr;
    } else {
      nextPrayer = _prayerTimes!.nextPrayer();
      nextPrayerTime = _prayerTimes!.timeForPrayer(nextPrayer)!;
    }

    _definitiveNextPrayer = nextPrayer;
    _definitiveNextPrayerTime = nextPrayerTime;
    _timeUntilNextPrayer = nextPrayerTime.difference(now);
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _updateNextPrayerInfo();
        });
      }
    });
  }

  void _onCalculationMethodChanged(CalculationMethod? method) {
    if (method != null && method != _selectedCalcMethod) {
      setState(() {
        _selectedCalcMethod = method;
        _prayerTimes = null; // Show loading indicator
      });
      _fetchPrayerData();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchPrayerData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return _prayerTimes == null
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _PrayerHeader(
                  location: _location ?? 'Loading...',
                  selectedCalcMethod: _selectedCalcMethod,
                  onMethodChanged: _onCalculationMethodChanged,
                ),
                const SizedBox(height: 24),
                if (_definitiveNextPrayer != null && _definitiveNextPrayerTime != null)
                  _NextPrayerCountdown(
                    nextPrayer: _definitiveNextPrayer!,
                    nextPrayerTime: _definitiveNextPrayerTime!,
                    timeUntilNextPrayer: _timeUntilNextPrayer,
                  ),
                const SizedBox(height: 24),
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
  });

  final String location;
  final CalculationMethod selectedCalcMethod;
  final ValueChanged<CalculationMethod?> onMethodChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          DateFormat('EEEE, d MMMM yyyy').format(DateTime.now()),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
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
    this.timeUntilNextPrayer,
  });

  final Prayer nextPrayer;
  final DateTime nextPrayerTime;
  final Duration? timeUntilNextPrayer;

  @override
  Widget build(BuildContext context) {
    final formattedTime = DateFormat.jm().format(nextPrayerTime);
    final timeUntil = timeUntilNextPrayer;

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
              'Next Prayer: ${nextPrayer.name.substring(0, 1).toUpperCase()}${nextPrayer.name.substring(1)}',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              formattedTime,
              style: Theme.of(context).textTheme.displaySmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w200),
            ),
            const SizedBox(height: 16),
            if (timeUntil != null && !timeUntil.isNegative)
              Text(
                '-${(timeUntil.inHours).toString().padLeft(2, '0')}:${(timeUntil.inMinutes % 60).toString().padLeft(2, '0')}:${(timeUntil.inSeconds % 60).toString().padLeft(2, '0')}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white70),
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
            '${prayerName[0].toUpperCase()}${prayerName.substring(1)}',
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

