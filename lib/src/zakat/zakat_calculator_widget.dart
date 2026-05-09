import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// The outcome of a Zakat calculation.
enum ZakatStatus {
  /// No assets have been entered yet.
  empty,

  /// Total zakatable assets are below the Nisab threshold; Zakat is not due.
  belowNisab,

  /// Zakat is due on the provided assets.
  due,
}

/// The result of a Zakat calculation.
class ZakatResult {
  /// Creates a [ZakatResult].
  const ZakatResult({
    required this.status,
    required this.zakatableAmount,
    required this.zakatDue,
  });

  /// The status of the calculation.
  final ZakatStatus status;

  /// Total assets minus debts. May be zero or negative.
  final double zakatableAmount;

  /// Amount of Zakat due (2.5% of [zakatableAmount] when [status] is
  /// [ZakatStatus.due], otherwise `0`).
  final double zakatDue;
}

/// A widget for calculating Zakat on common asset classes.
///
/// The widget accepts numeric input for cash, gold, silver, investments and
/// debts. It validates non-negative numeric input and applies the standard
/// 2.5% rate above the configured [nisabThreshold].
class ZakatCalculatorWidget extends StatefulWidget {
  /// Creates a [ZakatCalculatorWidget].
  const ZakatCalculatorWidget({
    super.key,
    this.currencySymbol = '\$',
    this.nisabThreshold = 4000.0,
  }) : assert(nisabThreshold >= 0,
            'nisabThreshold must be non-negative (got $nisabThreshold)');

  /// The currency symbol displayed in the result card.
  final String currencySymbol;

  /// Nisab threshold above which Zakat is due, in the same currency unit
  /// as the input.
  final double nisabThreshold;

  /// The Zakat rate (2.5%).
  static const double zakatRate = 0.025;

  /// Computes the Zakat result from raw asset values.
  ///
  /// Negative inputs are treated as `0` because the widget validates them
  /// separately and this helper is also intended for direct programmatic
  /// use.
  static ZakatResult calculate({
    double cash = 0,
    double gold = 0,
    double silver = 0,
    double investments = 0,
    double debts = 0,
    double nisabThreshold = 4000,
  }) {
    double nonNegative(double v) => v < 0 ? 0 : v;
    final totalAssets = nonNegative(cash) +
        nonNegative(gold) +
        nonNegative(silver) +
        nonNegative(investments);
    final zakatable = totalAssets - nonNegative(debts);

    if (totalAssets == 0 || zakatable <= 0) {
      return ZakatResult(
        status: ZakatStatus.empty,
        zakatableAmount: zakatable,
        zakatDue: 0,
      );
    }
    if (zakatable < nisabThreshold) {
      return ZakatResult(
        status: ZakatStatus.belowNisab,
        zakatableAmount: zakatable,
        zakatDue: 0,
      );
    }
    return ZakatResult(
      status: ZakatStatus.due,
      zakatableAmount: zakatable,
      zakatDue: zakatable * zakatRate,
    );
  }

  @override
  State<ZakatCalculatorWidget> createState() => _ZakatCalculatorWidgetState();
}

class _ZakatCalculatorWidgetState extends State<ZakatCalculatorWidget> {
  final _cashController = TextEditingController();
  final _goldController = TextEditingController();
  final _silverController = TextEditingController();
  final _investmentsController = TextEditingController();
  final _debtsController = TextEditingController();

  String? _cashErrorText;
  String? _goldErrorText;
  String? _silverErrorText;
  String? _investmentsErrorText;
  String? _debtsErrorText;

  ZakatResult? _result;
  late final NumberFormat _currencyFormat;

  @override
  void initState() {
    super.initState();
    _currencyFormat = NumberFormat.currency(
      symbol: '${widget.currencySymbol} ',
      decimalDigits: 2,
    );
  }

  @override
  void dispose() {
    _cashController.dispose();
    _goldController.dispose();
    _silverController.dispose();
    _investmentsController.dispose();
    _debtsController.dispose();
    super.dispose();
  }

  /// Parses a string, allowing optional thousands-separators (',' or ' ').
  /// Returns `null` if parsing fails.
  static double? _parse(String raw) {
    if (raw.isEmpty) return 0;
    final cleaned = raw.replaceAll(RegExp(r'[\s,]'), '');
    return double.tryParse(cleaned);
  }

  String? _validate(String? value) {
    if (value == null || value.isEmpty) return null;
    final parsed = _parse(value);
    if (parsed == null) return 'Please enter a valid number';
    if (parsed < 0) return 'Please enter a positive number';
    return null;
  }

  void _calculate() {
    setState(() {
      _cashErrorText = _validate(_cashController.text);
      _goldErrorText = _validate(_goldController.text);
      _silverErrorText = _validate(_silverController.text);
      _investmentsErrorText = _validate(_investmentsController.text);
      _debtsErrorText = _validate(_debtsController.text);

      final hasError = [
        _cashErrorText,
        _goldErrorText,
        _silverErrorText,
        _investmentsErrorText,
        _debtsErrorText,
      ].any((e) => e != null);

      if (hasError) {
        _result = null;
        return;
      }
      _result = ZakatCalculatorWidget.calculate(
        cash: _parse(_cashController.text) ?? 0,
        gold: _parse(_goldController.text) ?? 0,
        silver: _parse(_silverController.text) ?? 0,
        investments: _parse(_investmentsController.text) ?? 0,
        debts: _parse(_debtsController.text) ?? 0,
        nisabThreshold: widget.nisabThreshold,
      );
    });
  }

  void _reset() {
    setState(() {
      for (final c in [
        _cashController,
        _goldController,
        _silverController,
        _investmentsController,
        _debtsController,
      ]) {
        c.clear();
      }
      _cashErrorText = null;
      _goldErrorText = null;
      _silverErrorText = null;
      _investmentsErrorText = null;
      _debtsErrorText = null;
      _result = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _assetInput(
            key: const Key('cash_input'),
            controller: _cashController,
            label: 'Cash & Bank Balance',
            icon: Icons.account_balance_wallet_outlined,
            info:
                'Includes all cash on hand and balances in your bank accounts.',
            errorText: _cashErrorText,
          ),
          const SizedBox(height: 8),
          _assetInput(
            key: const Key('gold_input'),
            controller: _goldController,
            label: 'Value of Gold',
            icon: Icons.paid_outlined,
            info:
                'The market value of all gold you own above the Nisab threshold.',
            errorText: _goldErrorText,
          ),
          const SizedBox(height: 8),
          _assetInput(
            key: const Key('silver_input'),
            controller: _silverController,
            label: 'Value of Silver',
            icon: Icons.toll_outlined,
            info:
                'The market value of all silver you own above the Nisab threshold.',
            errorText: _silverErrorText,
          ),
          const SizedBox(height: 8),
          _assetInput(
            key: const Key('investments_input'),
            controller: _investmentsController,
            label: 'Investments',
            icon: Icons.trending_up,
            info:
                'Value of stocks, mutual funds, and other investments intended for growth.',
            errorText: _investmentsErrorText,
          ),
          const SizedBox(height: 8),
          _assetInput(
            key: const Key('debts_input'),
            controller: _debtsController,
            label: 'Debts & Liabilities',
            icon: Icons.money_off,
            info: 'Subtract any immediate debts you owe from your total assets.',
            errorText: _debtsErrorText,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: _calculate,
                child: const Text('Calculate'),
              ),
              TextButton(
                onPressed: _reset,
                child: const Text('Reset'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (result != null && result.status == ZakatStatus.belowNisab)
            _BelowNisabCard(
              nisabThreshold: widget.nisabThreshold,
              currencyFormat: _currencyFormat,
            ),
          if (result != null && result.status == ZakatStatus.due)
            ZakatResultCard(
              totalZakat: result.zakatDue,
              currencyFormat: _currencyFormat,
            ),
        ],
      ),
    );
  }

  Widget _assetInput({
    required Key key,
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String info,
    required String? errorText,
  }) {
    return TextFormField(
      key: key,
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        suffixIcon: IconButton(
          icon: const Icon(Icons.info_outline),
          tooltip: 'More info',
          onPressed: () => _showInfoDialog(context, label, info),
        ),
        errorText: errorText,
      ),
    );
  }

  void _showInfoDialog(BuildContext context, String title, String content) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class _BelowNisabCard extends StatelessWidget {
  const _BelowNisabCard({
    required this.nisabThreshold,
    required this.currencyFormat,
  });

  final double nisabThreshold;
  final NumberFormat currencyFormat;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              Icons.info_outline,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              'Below Nisab Threshold',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your total assets are below the Nisab threshold of '
              '${currencyFormat.format(nisabThreshold)}. Zakat is not required.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A card that displays the calculated Zakat result.
class ZakatResultCard extends StatelessWidget {
  /// Creates a [ZakatResultCard].
  const ZakatResultCard({
    super.key,
    required this.totalZakat,
    required this.currencyFormat,
  });

  /// The total zakat amount to be displayed.
  final double totalZakat;

  /// The currency formatter.
  final NumberFormat currencyFormat;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Zakat Due:',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              currencyFormat.format(totalZakat),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
