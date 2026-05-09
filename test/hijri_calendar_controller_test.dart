import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:islamic_kit/islamic_kit.dart';

void main() {
  group('HijriCalendarController', () {
    test('defaults to today\'s Hijri month when no initialDate is given', () {
      final controller = HijriCalendarController();
      final today = HijriCalendar.now();
      expect(controller.value.hYear, today.hYear);
      expect(controller.value.hMonth, today.hMonth);
      expect(controller.value.hDay, 1,
          reason: 'value should be normalized to the 1st of the month');
      addTearDown(controller.dispose);
    });

    test('respects initialDate', () {
      final initial = HijriCalendar()
        ..hYear = 1446
        ..hMonth = 6
        ..hDay = 15;
      final controller =
          HijriCalendarController(initialDate: initial);
      expect(controller.value.hYear, 1446);
      expect(controller.value.hMonth, 6);
      expect(controller.value.hDay, 1);
      addTearDown(controller.dispose);
    });

    test('goToMonth notifies listeners on change and no-ops on identity', () {
      final initial = HijriCalendar()
        ..hYear = 1446
        ..hMonth = 6
        ..hDay = 1;
      final controller = HijriCalendarController(initialDate: initial);
      addTearDown(controller.dispose);

      var notifications = 0;
      controller.addListener(() => notifications++);

      controller.goToMonth(1446, 7);
      expect(controller.value.hMonth, 7);
      expect(notifications, 1);

      // Navigating to the same month should not notify again.
      controller.goToMonth(1446, 7);
      expect(notifications, 1);
    });

    test('goToPreviousMonth / goToNextMonth roll over year boundaries', () {
      final initial = HijriCalendar()
        ..hYear = 1446
        ..hMonth = 12
        ..hDay = 1;
      final controller = HijriCalendarController(initialDate: initial);
      addTearDown(controller.dispose);

      controller.goToNextMonth();
      expect(controller.value.hYear, 1447);
      expect(controller.value.hMonth, 1);

      controller.goToPreviousMonth();
      expect(controller.value.hYear, 1446);
      expect(controller.value.hMonth, 12);
    });

    test('goToToday jumps to today\'s Hijri month', () {
      final initial = HijriCalendar()
        ..hYear = 1356
        ..hMonth = 1
        ..hDay = 1;
      final controller = HijriCalendarController(initialDate: initial);
      addTearDown(controller.dispose);

      controller.goToToday();

      final today = HijriCalendar.now();
      expect(controller.value.hYear, today.hYear);
      expect(controller.value.hMonth, today.hMonth);
    });

    test('goToMonth rejects out-of-range dates', () {
      final controller = HijriCalendarController();
      addTearDown(controller.dispose);

      expect(() => controller.goToMonth(1000, 1), throwsArgumentError);
      expect(() => controller.goToMonth(1446, 0), throwsArgumentError);
      expect(() => controller.goToMonth(1446, 13), throwsArgumentError);
    });
  });

  group('HijriCalendarWidget with external controller', () {
    testWidgets('external controller drives the visible month',
        (tester) async {
      final controller = HijriCalendarController(
        initialDate: HijriCalendar()
          ..hYear = 1446
          ..hMonth = 6
          ..hDay = 1,
      );
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox.expand(
              child: HijriCalendarWidget(controller: controller),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(HijriService.firstDayOfMonth(1446, 6).toFormat('MMMM yyyy')),
        findsOneWidget,
      );

      controller.goToNextMonth();
      await tester.pumpAndSettle();
      expect(
        find.text(HijriService.firstDayOfMonth(1446, 7).toFormat('MMMM yyyy')),
        findsOneWidget,
      );

      controller.goToMonth(1500, 12);
      await tester.pumpAndSettle();
      expect(
        find.text(
            HijriService.firstDayOfMonth(1500, 12).toFormat('MMMM yyyy')),
        findsOneWidget,
      );
    });

    testWidgets('tapping widget nav buttons mutates the external controller',
        (tester) async {
      final controller = HijriCalendarController(
        initialDate: HijriCalendar()
          ..hYear = 1446
          ..hMonth = 6
          ..hDay = 1,
      );
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox.expand(
              child: HijriCalendarWidget(controller: controller),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Next month'));
      await tester.pumpAndSettle();
      expect(controller.value.hMonth, 7);

      await tester.tap(find.byTooltip('Previous month'));
      await tester.pumpAndSettle();
      expect(controller.value.hMonth, 6);
    });
  });
}
