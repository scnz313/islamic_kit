import 'package:flutter_test/flutter_test.dart';
import 'package:islamic_kit/islamic_kit.dart';

void main() {
  group('IslamicEventService.getEventsForYear', () {
    test('returns the 9 canonical events', () {
      final events = IslamicEventService.getEventsForYear(1446);
      expect(events.length, 9);
      final names = events.map((e) => e.name).toSet();
      expect(names, containsAll(IslamicEventService.knownEventNames));
    });

    test('events are sorted by (month, day)', () {
      final events = IslamicEventService.getEventsForYear(1446);
      for (var i = 1; i < events.length; i++) {
        final a = events[i - 1].date;
        final b = events[i].date;
        expect(
          a.hMonth * 100 + a.hDay <= b.hMonth * 100 + b.hDay,
          isTrue,
          reason:
              '${events[i - 1].name} (${a.hMonth}/${a.hDay}) should come '
              'before or on ${events[i].name} (${b.hMonth}/${b.hDay})',
        );
      }
    });

    test('all events have initialized Hijri fields (lengthOfMonth set)', () {
      // This test catches the regression where HijriCalendar was built
      // via setters only, leaving `lengthOfMonth` uninitialized.
      final events = IslamicEventService.getEventsForYear(1446);
      for (final event in events) {
        expect(() => event.date.lengthOfMonth, returnsNormally,
            reason: 'lengthOfMonth should be initialized for ${event.name}');
        expect(event.date.lengthOfMonth, inInclusiveRange(29, 30));
        expect(() => event.date.weekDay(), returnsNormally,
            reason: 'weekDay() should not throw for ${event.name}');
      }
    });

    test('every event round-trips to a valid Gregorian date', () {
      final events = IslamicEventService.getEventsForYear(1446);
      for (final event in events) {
        final g = event.gregorianDate;
        expect(g.year, greaterThan(1900));
        expect(g.year, lessThan(2100));
      }
    });

    test('rejects years outside the supported range', () {
      expect(
          () => IslamicEventService.getEventsForYear(1000), throwsArgumentError);
      expect(
          () => IslamicEventService.getEventsForYear(2500), throwsArgumentError);
    });
  });

  group('IslamicEventService.nextEvent', () {
    test('returns an event whose date is on or after the reference date', () {
      final from = DateTime(2024, 6, 1);
      final next = IslamicEventService.nextEvent(from: from);
      expect(next, isNotNull);
      expect(next!.gregorianDate.isBefore(from), isFalse);
    });

    test('rolls over to the next Hijri year when appropriate', () {
      // Pick a date after all events for the current Hijri year to force
      // the search to roll to the next year.
      final thisYear = IslamicEventService.getEventsForYear(
        IslamicDateConverter.gregorianToHijri(DateTime.now()).hYear,
      );
      final afterLast =
          thisYear.last.gregorianDate.add(const Duration(days: 1));
      final next = IslamicEventService.nextEvent(from: afterLast);
      expect(next, isNotNull);
      expect(next!.gregorianDate.isAfter(thisYear.last.gregorianDate), isTrue);
    });
  });
}
