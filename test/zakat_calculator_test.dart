import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:islamic_kit/islamic_kit.dart';

void main() {
  group('ZakatCalculatorWidget', () {

    testWidgets('renders correctly and has an initial state', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: ZakatCalculatorWidget())));

      // Verify that all input fields are present using their keys
      expect(find.byKey(const Key('cash_input')), findsOneWidget);
      expect(find.byKey(const Key('gold_input')), findsOneWidget);
      expect(find.byKey(const Key('silver_input')), findsOneWidget);
      expect(find.byKey(const Key('investments_input')), findsOneWidget);
      expect(find.byKey(const Key('debts_input')), findsOneWidget);

      // Verify that the buttons are present
      expect(find.text('Calculate'), findsOneWidget);
      expect(find.text('Reset'), findsOneWidget);

      // Verify that the result card is not initially visible
      expect(find.text('Zakat Due:'), findsNothing);
    });

    testWidgets('shows validation error for non-numeric input', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: ZakatCalculatorWidget())));

      // Provide valid input for all fields except the one being tested
      await tester.enterText(find.byKey(const Key('cash_input')), 'abc'); // Invalid
      await tester.enterText(find.byKey(const Key('gold_input')), '100');
      await tester.enterText(find.byKey(const Key('silver_input')), '100');
      await tester.enterText(find.byKey(const Key('investments_input')), '100');
      await tester.enterText(find.byKey(const Key('debts_input')), '50');

      await tester.tap(find.text('Calculate'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a valid number'), findsOneWidget);

      // Ensure the result card is not shown
      expect(find.byType(ZakatResultCard), findsNothing);
    });

    testWidgets('calculates zakat correctly with valid inputs', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: ZakatCalculatorWidget())));

      // Enter values into the fields using their keys (total: 50000 - 5000 = 45000, above Nisab)
      await tester.enterText(find.byKey(const Key('cash_input')), '10000');
      await tester.enterText(find.byKey(const Key('gold_input')), '20000');
      await tester.enterText(find.byKey(const Key('silver_input')), '5000');
      await tester.enterText(find.byKey(const Key('investments_input')), '15000');
      await tester.enterText(find.byKey(const Key('debts_input')), '5000');

      // Tap the calculate button
      await tester.tap(find.text('Calculate'));
      await tester.pumpAndSettle();

      // Verify that the result card is now visible
      expect(find.text('Zakat Due:'), findsOneWidget);

      // Verify the calculated amount (45000 * 0.025 = 1125)
      expect(find.text('\$ 1,125.00'), findsOneWidget);
    });

    testWidgets('calculates zakat as 0 if zakatable amount is negative', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: ZakatCalculatorWidget())));

      await tester.enterText(find.byKey(const Key('cash_input')), '1000');
      await tester.enterText(find.byKey(const Key('debts_input')), '2000');

      await tester.tap(find.text('Calculate'));
      await tester.pumpAndSettle();

      // With negative zakatable amount, no result card should be shown
      final resultCardFinder = find.byType(ZakatResultCard);
      expect(resultCardFinder, findsNothing);

      // Also no Nisab message should be shown for negative amounts
      expect(find.text('Below Nisab Threshold'), findsNothing);
    });

    testWidgets('resets all fields and calculation', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: ZakatCalculatorWidget())));

      // Enter a value above Nisab threshold and calculate
      await tester.enterText(find.byKey(const Key('cash_input')), '10000');
      await tester.tap(find.text('Calculate'));
      await tester.pumpAndSettle();

      // Verify calculation is shown (10000 * 0.025 = 250)
      expect(find.text('Zakat Due:'), findsOneWidget);
      expect(find.text('\$ 250.00'), findsOneWidget);

      // Tap the reset button
      await tester.tap(find.text('Reset'));
      await tester.pumpAndSettle();

      // Verify that the result card is hidden
      expect(find.text('Zakat Due:'), findsNothing);

      // Verify that the text field is cleared
      final cashField = tester.widget<TextFormField>(find.byKey(const Key('cash_input')));
      expect(cashField.controller?.text, isEmpty);
    });

    testWidgets('handles empty fields as zero without validation errors', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: ZakatCalculatorWidget())));

      await tester.tap(find.text('Calculate'));
      await tester.pumpAndSettle();

      // No validation errors should appear for empty fields.
      expect(find.text('Please enter a valid number'), findsNothing);

      // With empty fields (0 total), no result card should be shown since it's below Nisab
      final resultCardFinder = find.byType(ZakatResultCard);
      expect(resultCardFinder, findsNothing);
      
      // Also no Nisab message should be shown for zero amounts
      expect(find.text('Below Nisab Threshold'), findsNothing);
    });

    testWidgets('shows below Nisab message for amounts below threshold', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: ZakatCalculatorWidget())));

      // Enter amount below Nisab threshold (default is 4000)
      await tester.enterText(find.byKey(const Key('cash_input')), '2000');
      await tester.tap(find.text('Calculate'));
      await tester.pumpAndSettle();

      // Should show Nisab message, not result card
      expect(find.text('Below Nisab Threshold'), findsOneWidget);
      expect(find.byType(ZakatResultCard), findsNothing);
      expect(find.textContaining('Your total assets are below the Nisab threshold'), findsOneWidget);
    });

    testWidgets('shows validation error for negative numbers', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: ZakatCalculatorWidget())));

      // Enter negative value
      await tester.enterText(find.byKey(const Key('cash_input')), '-1000');
      await tester.tap(find.text('Calculate'));
      await tester.pumpAndSettle();

      // Should show validation error
      expect(find.text('Please enter a positive number'), findsOneWidget);
      expect(find.byType(ZakatResultCard), findsNothing);
    });
  });
}
