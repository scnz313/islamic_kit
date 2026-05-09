import 'dart:async';

import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';

import 'package:islamic_kit/src/prayer_time/prayer_calc.dart';

/// Displays daily prayer times based on the user's location.
///
/// Fetches the current location, calculates prayer times with a selectable
/// [CalculationMethod], and shows a live countdown to the next prayer.
class PrayerTimeWidget extends StatefulWidget {
  /// Creates a [PrayerTimeWidget].
  const PrayerTimeWidget({
    super.key,
    this.initialCalculationMethod = CalculationMethod.muslim_world_league,
    this.madhab = Madhab.shafi,
    this.showSunnahTimes = true,
  });

  /// The calculation method to use when the widget first loads.
  final CalculationMethod initialCalculationMethod;

  /// The [Madhab] used for Asr calculation.
  final Madhab madhab;

  /// Whether to append Sunnah times (last third of the night) to the list.
  final bool showSunnahTimes;

  @override
  State<PrayerTimeWidget> createState() => _PrayerTimeWidgetState();
}

class _PrayerTimeWidgetState extends State<PrayerTimeWidget> {
  PrayerTimes? _prayerTimes;
  SunnahTimes? _sunnahTimes;
  String? _location;
  Timer? _timer;
  Duration? _timeUntilNextPrayer;
  Prayer? _nextPrayer;
  DateTime? _nextPrayerTime;
  String? _error;
  late CalculationMethod _selectedMethod;

  @override
  void initState() {
    super.initState();
    _selectedMethod = widget.initialCalculationMethod;
    _fetchPrayerData();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchPrayerData() async {
    setState(() {
      _error = null;
      _prayerTimes = null;
      _sunnahTimes = null;
    });
    try {
      final position = await PrayerCalc.getCurrentLocation();
      final prayerTimes = PrayerCalc.getPrayerTimes(
        latitude: position.latitude,
        longitude: position.longitude,
        date: DateTime.now(),
        calculationMethod: _selectedMethod,
        madhab: widget.madhab,
      );
      String location = 'Unknown Location';
      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          location = [p.locality, p.country]
              .whereType<String>()
              .where((s) => s.isNotEmpty)
              .join(', ');
          if (location.isEmpty) location = 'Unknown Location';
        }
      } catch (_) {
        // Best effort only.
      }

      if (!mounted) return;
      setState(() {
        _prayerTimes = prayerTimes;
        _sunnahTimes = SunnahTimes(prayerTimes);
        _location = location;
        _updateNextPrayerInfo();
      });
      _startTimer();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _updateNextPrayerInfo() {
    final prayerTimes = _prayerTimes;
    if (prayerTimes == null) return;
    final now = DateTime.now();
    final next = PrayerCalc.nextPrayerFrom(prayerTimes, now);
    _nextPrayer = next.prayer;
    _nextPrayerTime = next.time;
    final diff = next.time.difference(now);
    _timeUntilNextPrayer = diff.isNegative ? Duration.zero : diff;
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final previousSeconds = _timeUntilNextPrayer?.inSeconds;
      setState(() {
        _updateNextPrayerInfo();
      });
      // If the countdown just hit zero, refresh the prayer times so the
      // "next prayer" highlight moves forward.
      if (previousSeconds != null &&
          previousSeconds > 0 &&
          (_timeUntilNextPrayer?.inSeconds ?? 0) == 0) {
        _fetchPrayerData();
      }
    });
  }

  void _onMethodChanged(CalculationMethod? method) {
    if (method != null && method != _selectedMethod) {
      setState(() {
        _selectedMethod = method;
      });
      _fetchPrayerData();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 40,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 8),
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
    if (_prayerTimes == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PrayerHeader(
            location: _location ?? 'Loading...',
            selectedMethod: _selectedMethod,
            onMethodChanged: _onMethodChanged,
          ),
          const SizedBox(height: 24),
          if (_nextPrayer != null && _nextPrayerTime != null)
            _NextPrayerCountdown(
              nextPrayer: _nextPrayer!,
              nextPrayerTime: _nextPrayerTime!,
              timeUntilNextPrayer: _timeUntilNextPrayer,
            ),
          const SizedBox(height: 24),
          _PrayerTimesList(
            prayerTimes: _prayerTimes!,
            sunnahTimes: _sunnahTimes!,
            nextPrayer: _nextPrayer,
            showSunnahTimes: widget.showSunnahTimes,
          ),
        ],
      ),
    );
  }
}

class _PrayerHeader extends StatelessWidget {
  const _PrayerHeader({
    required this.location,
    required this.selectedMethod,
    required this.onMethodChanged,
  });

  final String location;
  final CalculationMethod selectedMethod;
  final ValueChanged<CalculationMethod?> onMethodChanged;

  String _prettyMethodName(CalculationMethod method) {
    return method.name.split('_').map((w) {
      if (w.isEmpty) return w;
      return '${w[0].toUpperCase()}${w.substring(1)}';
    }).join(' ');
  }

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
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<CalculationMethod>(
          value: selectedMethod,
          decoration: InputDecoration(
            labelText: 'Calculation Method',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
          ),
          items: CalculationMethod.values
              .map(
                (method) => DropdownMenuItem<CalculationMethod>(
                  value: method,
                  child: Text(_prettyMethodName(method)),
                ),
              )
              .toList(),
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
    final countdown = timeUntil == null
        ? null
        : '${timeUntil.inHours.toString().padLeft(2, '0')}:'
            '${(timeUntil.inMinutes % 60).toString().padLeft(2, '0')}:'
            '${(timeUntil.inSeconds % 60).toString().padLeft(2, '0')}';

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.primaryContainer,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Text(
              'Next Prayer: ${_capitalise(nextPrayer.name)}',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              formattedTime,
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w200,
                  ),
            ),
            const SizedBox(height: 16),
            if (countdown != null && !(timeUntil?.isNegative ?? true))
              Text(
                countdown,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(color: Colors.white70),
              ),
          ],
        ),
      ),
    );
  }

  String _capitalise(String s) {
    if (s.isEmpty) return s;
    return '${s[0].toUpperCase()}${s.substring(1)}';
  }
}

class _PrayerTimesList extends StatelessWidget {
  const _PrayerTimesList({
    required this.prayerTimes,
    required this.sunnahTimes,
    required this.nextPrayer,
    required this.showSunnahTimes,
  });

  final PrayerTimes prayerTimes;
  final SunnahTimes sunnahTimes;
  final Prayer? nextPrayer;
  final bool showSunnahTimes;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            _buildRow(context, Prayer.fajr, prayerTimes.fajr),
            _buildRow(context, Prayer.sunrise, prayerTimes.sunrise),
            _buildRow(context, Prayer.dhuhr, prayerTimes.dhuhr),
            _buildRow(context, Prayer.asr, prayerTimes.asr),
            _buildRow(context, Prayer.maghrib, prayerTimes.maghrib),
            _buildRow(context, Prayer.isha, prayerTimes.isha),
            if (showSunnahTimes) ...[
              const Divider(height: 24, indent: 16, endIndent: 16),
              _buildSunnahRow(context, 'Qiyam', sunnahTimes.lastThirdOfTheNight),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRow(BuildContext context, Prayer prayer, DateTime time) {
    final isNext = prayer == nextPrayer;
    final name = prayer.name;
    final label = '${name[0].toUpperCase()}${name.substring(1)}';
    return _PrayerRow(
      label: label,
      time: time,
      isHighlighted: isNext,
    );
  }

  Widget _buildSunnahRow(BuildContext context, String label, DateTime time) {
    return _PrayerRow(label: label, time: time, isHighlighted: false);
  }
}

class _PrayerRow extends StatelessWidget {
  const _PrayerRow({
    required this.label,
    required this.time,
    required this.isHighlighted,
  });

  final String label;
  final DateTime time;
  final bool isHighlighted;

  @override
  Widget build(BuildContext context) {
    final baseStyle = Theme.of(context).textTheme.titleMedium;
    final style = baseStyle?.copyWith(
      fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
      color: isHighlighted ? Theme.of(context).colorScheme.primary : null,
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: isHighlighted
            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(DateFormat.jm().format(time), style: style),
        ],
      ),
    );
  }
}
