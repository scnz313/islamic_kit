import 'package:flutter_test/flutter_test.dart';
import 'package:islamic_kit/src/events/islamic_event_service.dart';
import 'package:islamic_kit/src/events/reminder_scheduler.dart';

void main() {
  group('IslamicEventService', () {
    test('returns enriched event metadata for a Hijri year', () {
      final events = IslamicEventService.getEventsForYear(1447);
      final ramadan = events.firstWhere((event) => event.name == 'Start of Ramadan');

      expect(events, isNotEmpty);
      expect(ramadan.description, isNotEmpty);
      expect(ramadan.isEstimated, isTrue);
      expect(ramadan.id, contains('start_of_ramadan'));
    });

    test('finds the next year event after the current year has ended', () {
      final events = IslamicEventService.getEventsForYear(1447);
      final referenceDate = events.last.gregorianDate.add(const Duration(days: 1));

      final upcomingEvent =
          IslamicEventService.getUpcomingEvent(referenceDate: referenceDate);

      expect(upcomingEvent, isNotNull);
      expect(upcomingEvent!.date.hYear, 1448);
    });

    test('finds the next remindable event after reminder time has passed', () {
      final events = IslamicEventService.getEventsForYear(1447);
      final firstEvent = events.first;
      final referenceDate =
          firstEvent.reminderTime().add(const Duration(hours: 1));

      final upcomingEvent = IslamicEventService.getUpcomingReminderEvent(
        referenceDate: referenceDate,
      );

      expect(upcomingEvent, isNotNull);
      expect(upcomingEvent!.id, isNot(firstEvent.id));
    });

    test('generates stable reminder notification IDs', () {
      final event = IslamicEventService.getEventsForYear(1447).first;

      final firstId = ReminderScheduler.notificationIdForEvent(event);
      final secondId = ReminderScheduler.notificationIdForEvent(event);

      expect(firstId, equals(secondId));
      expect(firstId, greaterThanOrEqualTo(0));
    });
  });
}
