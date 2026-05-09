import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:islamic_kit/src/qibla/qibla_compass_widget.dart';

void main() {
  group('normalizeDegrees', () {
    test('returns values in [0, 360)', () {
      expect(normalizeDegrees(0), 0);
      expect(normalizeDegrees(359.9), closeTo(359.9, 1e-9));
      expect(normalizeDegrees(360), 0);
      expect(normalizeDegrees(540), 180);
      expect(normalizeDegrees(-90), 270);
      expect(normalizeDegrees(-450), 270);
    });
  });

  group('QiblaCompassWidget', () {
    testWidgets('shows a CircularProgressIndicator while loading',
        (tester) async {
      // Without a plugin backend the widget will be stuck loading, which
      // is fine — we just want to verify the initial paint renders.
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: QiblaCompassWidget()),
        ),
      );
      // A single frame has been pumped; we expect the loading indicator
      // (or an error retry button if permission checks short-circuit).
      final loader = find.byType(CircularProgressIndicator);
      final retry = find.text('Retry');
      expect(
        loader.evaluate().isNotEmpty || retry.evaluate().isNotEmpty,
        isTrue,
        reason: 'Expected a progress indicator or error retry UI.',
      );
    });
  });
}
