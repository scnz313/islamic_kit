import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// A widget for calculating Zakat based on user input for different asset types.
class ZakatCalculatorWidget extends StatefulWidget {
  /// Creates a [ZakatCalculatorWidget].
  const ZakatCalculatorWidget({
    super.key,
    this.currencySymbol = '\$',
    this.nisabThreshold = 4000.0, // Approximate USD value
  });

  /// The currency symbol to display (default: USD)
  final String currencySymbol;

  /// The Nisab threshold in the selected currency
  final double nisabThreshold;

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

  double _totalZakat = 0.0;
  bool _isCalculated = false;
  bool _belowNisab = false;

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

  String? _validateNumber(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Handled as 0, not an error
    }
    final parsedValue = double.tryParse(value);
    if (parsedValue == null) {
      return 'Please enter a valid number';
    }
    if (parsedValue < 0) {
      return 'Please enter a positive number';
    }
    return null;
  }

  void _calculateZakat() {
    setState(() {
      _cashErrorText = _validateNumber(_cashController.text);
      _goldErrorText = _validateNumber(_goldController.text);
      _silverErrorText = _validateNumber(_silverController.text);
      _investmentsErrorText = _validateNumber(_investmentsController.text);
      _debtsErrorText = _validateNumber(_debtsController.text);

      final bool hasError = _cashErrorText != null ||
          _goldErrorText != null ||
          _silverErrorText != null ||
          _investmentsErrorText != null ||
          _debtsErrorText != null;

      if (hasError) {
        _isCalculated = false;
        _totalZakat = 0.0;
        _belowNisab = false;
      } else {
        final cash = double.tryParse(_cashController.text) ?? 0.0;
        final gold = double.tryParse(_goldController.text) ?? 0.0;
        final silver = double.tryParse(_silverController.text) ?? 0.0;
        final investments = double.tryParse(_investmentsController.text) ?? 0.0;
        final debts = double.tryParse(_debtsController.text) ?? 0.0;

        final totalAssets = cash + gold + silver + investments;
        final zakatableAmount = totalAssets - debts;

        if (zakatableAmount >= widget.nisabThreshold) {
          _totalZakat = zakatableAmount * 0.025; // 2.5% Zakat rate
          _belowNisab = false;
        } else {
          _totalZakat = 0.0;
          _belowNisab = zakatableAmount > 0; // Show Nisab message if assets exist but below threshold
        }
        _isCalculated = true;
      }
    });
  }

  void _resetCalculator() {
    setState(() {
      _cashController.clear();
      _goldController.clear();
      _silverController.clear();
      _investmentsController.clear();
      _debtsController.clear();

      _cashErrorText = null;
      _goldErrorText = null;
      _silverErrorText = null;
      _investmentsErrorText = null;
      _debtsErrorText = null;

      _totalZakat = 0.0;
      _isCalculated = false;
      _belowNisab = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildAssetInput(
            key: const Key('cash_input'),
            controller: _cashController,
            label: 'Cash & Bank Balance',
            icon: Icons.account_balance_wallet_outlined,
            info: 'Includes all cash on hand and balances in your bank accounts.',
            errorText: _cashErrorText,
          ),
          const SizedBox(height: 8),
          _buildAssetInput(
            key: const Key('gold_input'),
            controller: _goldController,
            label: 'Value of Gold',
            icon: Icons.paid_outlined,
            info: 'The market value of all gold you own above the Nisab threshold.',
            errorText: _goldErrorText,
          ),
          const SizedBox(height: 8),
          _buildAssetInput(
            key: const Key('silver_input'),
            controller: _silverController,
            label: 'Value of Silver',
            icon: Icons.toll_outlined,
            info: 'The market value of all silver you own above the Nisab threshold.',
            errorText: _silverErrorText,
          ),
          const SizedBox(height: 8),
          _buildAssetInput(
            key: const Key('investments_input'),
            controller: _investmentsController,
            label: 'Investments',
            icon: Icons.trending_up,
            info: 'Value of stocks, mutual funds, and other investments intended for growth.',
            errorText: _investmentsErrorText,
          ),
          const SizedBox(height: 8),
          _buildAssetInput(
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
                onPressed: _calculateZakat,
                child: const Text('Calculate'),
              ),
              TextButton(
                onPressed: _resetCalculator,
                child: const Text('Reset'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_isCalculated && _belowNisab)
            Card(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
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
                      'Your total assets are below the Nisab threshold of ${_currencyFormat.format(widget.nisabThreshold)}. Zakat is not required.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (_isCalculated && !_belowNisab && _totalZakat > 0)
            ZakatResultCard(totalZakat: _totalZakat, currencyFormat: _currencyFormat),
        ],
      ),
    );
  }

  Widget _buildAssetInput({
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
        contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
        suffixIcon: IconButton(
          icon: const Icon(Icons.info_outline),
          onPressed: () => _showInfoDialog(context, label, info),
        ),
        errorText: errorText,
      ),
    );
  }

  void _showInfoDialog(BuildContext context, String title, String content) {
    showDialog(
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
        padding: const EdgeInsets.all(16.0),
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
