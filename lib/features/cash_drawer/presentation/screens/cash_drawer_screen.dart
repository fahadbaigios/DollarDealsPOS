import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../database/app_database.dart';
import '../../data/repositories/cash_drawer_repository.dart';
import '../../domain/models/cash_drawer_summary.dart';
import '../providers/cash_drawer_providers.dart';

class CashDrawerScreen extends ConsumerWidget {
  const CashDrawerScreen({super.key});

  static final _currency = NumberFormat.currency(symbol: 'PKR ');
  static final _dateTime = DateFormat('MMM d, yyyy • h:mm a');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(cashDrawerSummaryProvider);
    final activityAsync = ref.watch(cashDrawerActivityProvider);
    final summary = summaryAsync.valueOrNull;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Cash Drawer',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Refresh',
                onPressed: () => refreshCashDrawer(ref),
                icon: const Icon(Icons.refresh),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => _showCashInDialog(context, ref),
                icon: const Icon(Icons.add),
                label: const Text('Cash In'),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: summary == null || summary.balanceMinor <= 0
                    ? null
                    : () {
                        _showCashOutDialog(context, ref, summary);
                      },
                icon: const Icon(Icons.remove),
                label: const Text('Cash Out'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Cash sales are added automatically. Card, bank, and wallet sales do not affect this drawer.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          summaryAsync.when(
            data: (summary) => _SummaryCards(summary: summary),
            loading: () => const SizedBox(
              height: 120,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => Text('Unable to load drawer: $error'),
          ),
          const SizedBox(height: 24),
          Text(
            'Recent Activity',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: activityAsync.when(
              data: (movements) => _ActivityList(movements: movements),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) =>
                  Center(child: Text('Unable to load activity: $error')),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showCashInDialog(BuildContext context, WidgetRef ref) async {
    final result = await _showAmountDialog(
      context,
      title: 'Cash In',
      message: 'Enter the change money you are putting into the drawer.',
      confirmLabel: 'Add Cash',
    );
    if (result == null) return;

    try {
      await ref
          .read(cashDrawerRepositoryProvider)
          .addCashIn(amount: result.amount, note: result.note);
      refreshCashDrawer(ref);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Cash added to drawer')));
      }
    } catch (error) {
      if (context.mounted) _showError(context, error);
    }
  }

  Future<void> _showCashOutDialog(
    BuildContext context,
    WidgetRef ref,
    CashDrawerSummary summary,
  ) async {
    final suggestion = summary.suggestedCashOutMinor / 100;
    final result = await _showAmountDialog(
      context,
      title: 'Cash Out',
      message:
          'Today\'s remaining cash sales: ${_formatMinor(summary.suggestedCashOutMinor)}\n'
          'Current drawer balance: ${_formatMinor(summary.balanceMinor)}',
      confirmLabel: 'Remove Cash',
      initialAmount: suggestion > 0 ? suggestion : null,
      maximumAmount: summary.balanceMinor / 100,
      defaultNote: suggestion > 0 ? 'Daily cash out' : null,
    );
    if (result == null) return;

    try {
      await ref
          .read(cashDrawerRepositoryProvider)
          .addCashOut(amount: result.amount, note: result.note);
      refreshCashDrawer(ref);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${_currency.format(result.amount)} removed from drawer',
            ),
          ),
        );
      }
    } catch (error) {
      if (context.mounted) _showError(context, error);
    }
  }

  Future<({double amount, String note})?> _showAmountDialog(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    double? initialAmount,
    double? maximumAmount,
    String? defaultNote,
  }) {
    return showDialog<({double amount, String note})>(
      context: context,
      builder: (_) => _CashMovementDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        initialAmount: initialAmount,
        maximumAmount: maximumAmount,
        defaultNote: defaultNote,
      ),
    );
  }

  void _showError(BuildContext context, Object error) {
    final message = error is StateError
        ? error.message
        : error is ArgumentError
        ? error.message?.toString() ?? 'Invalid amount'
        : error.toString();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  static String _formatMinor(int amountMinor) {
    return _currency.format(amountMinor / 100);
  }

  static String _movementTitle(String type) {
    switch (type) {
      case CashDrawerRepository.cashInType:
        return 'Cash In';
      case CashDrawerRepository.cashSaleType:
        return 'Cash Sale';
      case CashDrawerRepository.cashOutType:
        return 'Cash Out';
      default:
        return type;
    }
  }
}

class _CashMovementDialog extends StatefulWidget {
  const _CashMovementDialog({
    required this.title,
    required this.message,
    required this.confirmLabel,
    this.initialAmount,
    this.maximumAmount,
    this.defaultNote,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final double? initialAmount;
  final double? maximumAmount;
  final String? defaultNote;

  @override
  State<_CashMovementDialog> createState() => _CashMovementDialogState();
}

class _CashMovementDialogState extends State<_CashMovementDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.initialAmount?.toStringAsFixed(2) ?? '',
    );
    _noteController = TextEditingController(text: widget.defaultNote ?? '');
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(widget.message),
              const SizedBox(height: 20),
              TextFormField(
                key: const ValueKey('cash-drawer-amount-field'),
                controller: _amountController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  prefixText: 'PKR ',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) {
                  final amount = double.tryParse(value?.trim() ?? '');
                  if (amount == null || amount <= 0) {
                    return 'Enter an amount greater than zero';
                  }
                  final maximum = widget.maximumAmount;
                  if (maximum != null && amount > maximum) {
                    return 'Amount cannot exceed ${CashDrawerScreen._currency.format(maximum)}';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: 'Note (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.of(context).pop((
              amount: double.parse(_amountController.text.trim()),
              note: _noteController.text.trim(),
            ));
          },
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}

class _SummaryCards extends StatelessWidget {
  const _SummaryCards({required this.summary});

  final CashDrawerSummary summary;

  @override
  Widget build(BuildContext context) {
    final cards = [
      (
        label: 'Expected Cash',
        amount: summary.balanceMinor,
        icon: Icons.account_balance_wallet_outlined,
        color: Theme.of(context).colorScheme.primary,
      ),
      (
        label: "Today's Cash Sales",
        amount: summary.todayCashSalesMinor,
        icon: Icons.point_of_sale,
        color: Colors.green,
      ),
      (
        label: "Today's Cash In",
        amount: summary.todayCashInMinor,
        icon: Icons.add_circle_outline,
        color: Colors.blue,
      ),
      (
        label: "Today's Cash Out",
        amount: summary.todayCashOutMinor,
        icon: Icons.remove_circle_outline,
        color: Colors.orange,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900 ? 4 : 2;
        final width = (constraints.maxWidth - ((columns - 1) * 16)) / columns;
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: cards
              .map(
                (card) => SizedBox(
                  width: width,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(card.icon, color: card.color),
                          const SizedBox(height: 12),
                          Text(
                            card.label,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            CashDrawerScreen._formatMinor(card.amount),
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _ActivityList extends StatelessWidget {
  const _ActivityList({required this.movements});

  final List<CashDrawerMovement> movements;

  @override
  Widget build(BuildContext context) {
    if (movements.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              'No drawer activity yet',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 4),
            const Text('Use Cash In to add your starting change money.'),
          ],
        ),
      );
    }

    return Card(
      child: ListView.separated(
        itemCount: movements.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final movement = movements[index];
          final isOut =
              movement.movementType == CashDrawerRepository.cashOutType;
          final detail = movement.note?.trim().isNotEmpty == true
              ? movement.note!
              : movement.saleId != null
              ? 'Sale #${movement.saleId}'
              : 'Manual entry';
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: (isOut ? Colors.orange : Colors.green)
                  .withValues(alpha: 0.12),
              child: Icon(
                isOut ? Icons.arrow_upward : Icons.arrow_downward,
                color: isOut ? Colors.orange : Colors.green,
              ),
            ),
            title: Text(CashDrawerScreen._movementTitle(movement.movementType)),
            subtitle: Text(
              '$detail • ${CashDrawerScreen._dateTime.format(movement.createdAt)}',
            ),
            trailing: Text(
              '${isOut ? '-' : '+'}${CashDrawerScreen._formatMinor(movement.amountMinor)}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: isOut ? Colors.orange : Colors.green,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        },
      ),
    );
  }
}
