import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:islamic_kit/islamic_kit.dart';

void main() {
  group('IslamicEventsWidget', () {
    testWidgets('renders a card for every known event', (tester) async {
      // Make the viewport tall enough that ListView.builder materializes
      // every child card.
      tester.view.physicalSize = const Size(800, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox.expand(
              child: IslamicEventsWidget(year: 1446),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (final name in IslamicEventService.knownEventNames) {
        expect(find.text(name), findsOneWidget, reason: name);
      }
      expect(find.byIcon(Icons.notifications_active),
          findsNWidgets(IslamicEventService.knownEventNames.length));
    });

    testWidgets('invokes onReminderTap and shows a snackbar', (tester) async {
      IslamicEvent? captured;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IslamicEventsWidget(
              year: 1446,
              onReminderTap: (event) async {
                captured = event;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.notifications_active).first);
      await tester.pumpAndSettle();

      expect(captured, isNotNull);
      expect(captured!.name, IslamicEventService.knownEventNames.first);
      expect(
        find.textContaining(
            'Reminder set for ${IslamicEventService.knownEventNames.first}'),
        findsOneWidget,
      );
    });

    testWidgets('displays both Hijri and Gregorian dates for each event',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox.expand(
              child: IslamicEventsWidget(year: 1446),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Corresponds to:'), findsWidgets);
    });
  });
}
