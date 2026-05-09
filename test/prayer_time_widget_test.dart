import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:islamic_kit/islamic_kit.dart';

void main() {
  group('PrayerTimeWidget', () {
    testWidgets('renders without crashing and shows a loader or error',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: PrayerTimeWidget())),
      );
      // Either a loading indicator or a retry button should be visible;
      // without geolocation plugin the fetch will fail quickly.
      final loading = find.byType(CircularProgressIndicator);
      final retry = find.text('Retry');
      expect(
        loading.evaluate().isNotEmpty || retry.evaluate().isNotEmpty,
        isTrue,
      );
    });
  });
}
