import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:islamic_kit/islamic_kit.dart';

void main() {
  group('HijriCalendarWidget', () {
    testWidgets('renders the current Hijri month header and weekday row',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: SizedBox.expand(child: HijriCalendarWidget())),
        ),
      );
      // Weekday labels.
      for (final d in ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']) {
        expect(find.text(d), findsOneWidget);
      }
      // Navigation buttons.
      expect(find.byTooltip('Previous month'), findsOneWidget);
      expect(find.byTooltip('Next month'), findsOneWidget);
    });

    testWidgets('navigating forwards/backwards does not crash and updates '
        'the header', (tester) async {
      final initial = HijriCalendar()
        ..hYear = 1446
        ..hMonth = 6
        ..hDay = 1;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox.expand(
              child: HijriCalendarWidget(initialDate: initial),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final initialHeader = HijriService.firstDayOfMonth(1446, 6)
          .toFormat('MMMM yyyy');
      expect(find.text(initialHeader), findsOneWidget);

      await tester.tap(find.byTooltip('Next month'));
      await tester.pumpAndSettle();
      final nextHeader = HijriService.firstDayOfMonth(1446, 7)
          .toFormat('MMMM yyyy');
      expect(find.text(nextHeader), findsOneWidget);

      // Tapping back 2x rolls over to the previous month twice.
      await tester.tap(find.byTooltip('Previous month'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Previous month'));
      await tester.pumpAndSettle();
      final prevHeader = HijriService.firstDayOfMonth(1446, 5)
          .toFormat('MMMM yyyy');
      expect(find.text(prevHeader), findsOneWidget);
    });

    testWidgets('rolls over year boundaries correctly', (tester) async {
      final initial = HijriCalendar()
        ..hYear = 1446
        ..hMonth = 12
        ..hDay = 1;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox.expand(
              child: HijriCalendarWidget(initialDate: initial),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Next month'));
      await tester.pumpAndSettle();
      final header = HijriService.firstDayOfMonth(1447, 1)
          .toFormat('MMMM yyyy');
      expect(find.text(header), findsOneWidget);
    });

    testWidgets('renders days 1..lengthOfMonth', (tester) async {
      final initial = HijriCalendar()
        ..hYear = 1446
        ..hMonth = 6
        ..hDay = 1;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox.expand(
              child: HijriCalendarWidget(initialDate: initial),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final month = HijriService.firstDayOfMonth(1446, 6);
      for (final day in [1, 10, month.lengthOfMonth]) {
        expect(find.text('$day'), findsWidgets,
            reason: 'day $day should be rendered');
      }
    });
  });
}
