import 'package:flutter_test/flutter_test.dart';
import 'package:islamic_kit/islamic_kit.dart';

void main() {
  group('ZakatCalculatorWidget.calculate', () {
    test('empty inputs produce ZakatStatus.empty', () {
      final r = ZakatCalculatorWidget.calculate();
      expect(r.status, ZakatStatus.empty);
      expect(r.zakatDue, 0);
    });

    test('assets below Nisab produce ZakatStatus.belowNisab', () {
      final r = ZakatCalculatorWidget.calculate(cash: 2000);
      expect(r.status, ZakatStatus.belowNisab);
      expect(r.zakatDue, 0);
    });

    test('assets above Nisab produce ZakatStatus.due at 2.5%', () {
      final r = ZakatCalculatorWidget.calculate(
        cash: 10_000,
        gold: 20_000,
        silver: 5_000,
        investments: 15_000,
        debts: 5_000,
      );
      expect(r.status, ZakatStatus.due);
      expect(r.zakatableAmount, 45_000);
      expect(r.zakatDue, closeTo(1125, 0.0001));
    });

    test('debts greater than assets produce ZakatStatus.empty (zakatable<=0)',
        () {
      final r = ZakatCalculatorWidget.calculate(cash: 1000, debts: 2000);
      expect(r.status, ZakatStatus.empty);
      expect(r.zakatableAmount, lessThanOrEqualTo(0));
      expect(r.zakatDue, 0);
    });

    test('negative inputs are coerced to zero', () {
      final r = ZakatCalculatorWidget.calculate(
        cash: -500,
        gold: 10_000,
      );
      // -500 should have been treated as 0, so total = 10000 which is above
      // the default Nisab threshold.
      expect(r.status, ZakatStatus.due);
      expect(r.zakatableAmount, 10_000);
    });

    test('respects custom Nisab threshold', () {
      final r = ZakatCalculatorWidget.calculate(
        cash: 8000,
        nisabThreshold: 10_000,
      );
      expect(r.status, ZakatStatus.belowNisab);
    });

    test('Zakat rate constant is exactly 2.5%', () {
      expect(ZakatCalculatorWidget.zakatRate, 0.025);
    });
  });
}
