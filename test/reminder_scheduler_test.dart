import 'package:flutter_test/flutter_test.dart';
import 'package:islamic_kit/islamic_kit.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

void main() {
  group('ReminderScheduler.notificationIdFor', () {
    setUp(ReminderScheduler.debugReset);

    test('is always non-negative and fits a 31-bit int', () {
      for (var y = HijriRange.minYear; y <= HijriRange.maxYear; y += 10) {
        final events = IslamicEventService.getEventsForYear(y);
        for (final event in events) {
          final id = ReminderScheduler.notificationIdFor(event);
          expect(id, greaterThanOrEqualTo(0),
              reason: 'id for ${event.name} $y');
          expect(id, lessThanOrEqualTo(0x7fffffff),
              reason: 'id for ${event.name} $y');
        }
      }
    });

    test('returns distinct ids across different events in the same year', () {
      final events = IslamicEventService.getEventsForYear(1446);
      final ids = events.map(ReminderScheduler.notificationIdFor).toSet();
      expect(ids.length, events.length,
          reason: 'ids should be unique across events');
    });

    test('returns distinct ids for the same event name across different years',
        () {
      final a = IslamicEvent(
        'Eid al-Fitr',
        HijriService.fromDate(1446, 10, 1),
      );
      final b = IslamicEvent(
        'Eid al-Fitr',
        HijriService.fromDate(1447, 10, 1),
      );
      expect(
        ReminderScheduler.notificationIdFor(a),
        isNot(equals(ReminderScheduler.notificationIdFor(b))),
      );
    });

    test('is stable for a given (year, month, day, name)', () {
      final event = IslamicEvent(
        'Eid al-Fitr',
        HijriService.fromDate(1446, 10, 1),
      );
      expect(
        ReminderScheduler.notificationIdFor(event),
        ReminderScheduler.notificationIdFor(event),
      );
    });
  });

  group('ReminderScheduler.setDefaultLocation / resolveScheduledDate', () {
    setUpAll(tz.initializeTimeZones);
    setUp(ReminderScheduler.debugReset);

    test('defaultLocation falls back to tz.local when unset', () {
      expect(ReminderScheduler.defaultLocation, tz.local);
    });

    test('setDefaultLocation overrides the effective location', () {
      final tokyo = tz.getLocation('Asia/Tokyo');
      ReminderScheduler.setDefaultLocation(tokyo);
      expect(ReminderScheduler.defaultLocation, tokyo);
      ReminderScheduler.setDefaultLocation(null);
      expect(ReminderScheduler.defaultLocation, tz.local);
    });

    test('resolveScheduledDate uses the provided location', () {
      final tokyo = tz.getLocation('Asia/Tokyo');
      final newYork = tz.getLocation('America/New_York');

      final event = IslamicEvent(
        'Eid al-Fitr',
        HijriService.fromDate(1446, 10, 1),
      );

      final tokyoTime = ReminderScheduler.resolveScheduledDate(
        event,
        reminderTimeOfDay: const Duration(hours: 9),
        location: tokyo,
      );
      final newYorkTime = ReminderScheduler.resolveScheduledDate(
        event,
        reminderTimeOfDay: const Duration(hours: 9),
        location: newYork,
      );

      expect(tokyoTime.location, tokyo);
      expect(newYorkTime.location, newYork);
      // Wall-clock components should match reminderTimeOfDay regardless of
      // timezone.
      expect(tokyoTime.hour, 9);
      expect(newYorkTime.hour, 9);
      // Same wall-clock time in two different timezones → different UTC
      // instants.
      expect(
        tokyoTime.millisecondsSinceEpoch,
        isNot(equals(newYorkTime.millisecondsSinceEpoch)),
      );
    });

    test('resolveScheduledDate honors setDefaultLocation', () {
      final tokyo = tz.getLocation('Asia/Tokyo');
      ReminderScheduler.setDefaultLocation(tokyo);
      final event = IslamicEvent(
        'Eid al-Fitr',
        HijriService.fromDate(1446, 10, 1),
      );
      final result = ReminderScheduler.resolveScheduledDate(event);
      expect(result.location, tokyo);
    });

    test('resolveScheduledDate picks up minutes from reminderTimeOfDay', () {
      final event = IslamicEvent(
        'Eid al-Fitr',
        HijriService.fromDate(1446, 10, 1),
      );
      final result = ReminderScheduler.resolveScheduledDate(
        event,
        reminderTimeOfDay: const Duration(hours: 5, minutes: 30),
        location: tz.getLocation('UTC'),
      );
      expect(result.hour, 5);
      expect(result.minute, 30);
    });
  });
}
