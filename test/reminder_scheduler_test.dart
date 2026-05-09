import 'package:flutter_test/flutter_test.dart';
import 'package:islamic_kit/islamic_kit.dart';

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
      final ids =
          events.map(ReminderScheduler.notificationIdFor).toSet();
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
      final a = ReminderScheduler.notificationIdFor(event);
      final b = ReminderScheduler.notificationIdFor(event);
      expect(a, b);
    });
  });
}
