import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../database/app_database.dart';
import '../../../products/presentation/widgets/form_dialog.dart';
import '../../../sales/presentation/providers/sales_providers.dart';
import '../providers/expenses_providers.dart';

Future<void> showExpenseFormDialog(
  BuildContext context, {
  Expense? existing,
}) {
  return showDialog(
    context: context,
    builder: (context) => ExpenseFormDialog(existing: existing),
  );
}

class ExpenseFormDialog extends ConsumerStatefulWidget {
  const ExpenseFormDialog({super.key, this.existing});

  final Expense? existing;

  @override
  ConsumerState<ExpenseFormDialog> createState() => _ExpenseFormDialogState();
}

class _ExpenseFormDialogState extends ConsumerState<ExpenseFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  late final TextEditingController _referenceController;
  late final TextEditingController _notesController;
  DateTime _expenseDate = DateTime.now();
  int? _categoryId;
  int? _paymentMethodId;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.existing?.title ?? '');
    _amountController = TextEditingController(
        text: widget.existing != null ? widget.existing!.amount.toString() : '');
    _referenceController =
        TextEditingController(text: widget.existing?.referenceNumber ?? '');
    _notesController = TextEditingController(text: widget.existing?.notes ?? '');
    _expenseDate = widget.existing?.expenseDate ?? DateTime.now();
    _categoryId = widget.existing?.expenseCategoryId;
    _paymentMethodId = widget.existing?.paymentMethodId;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _referenceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final title = _titleController.text.trim();
    final amount = double.tryParse(_amountController.text.trim());
    final categoryId = _categoryId;
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Amount must be greater than 0')),
      );
      return;
    }
    if (categoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }
    final repo = ref.read(expensesRepositoryProvider);
    final reference =
        _referenceController.text.trim().isEmpty ? null : _referenceController.text.trim();
    final notes = _notesController.text.trim().isEmpty ? null : _notesController.text.trim();

    try {
      if (widget.existing != null) {
        await repo.update(
          id: widget.existing!.id,
          title: title,
          expenseCategoryId: categoryId,
          amount: amount,
          expenseDate: _expenseDate,
          paymentMethodId: _paymentMethodId,
          referenceNumber: reference,
          notes: notes,
        );
      } else {
        await repo.create(
          title: title,
          expenseCategoryId: categoryId,
          amount: amount,
          expenseDate: _expenseDate,
          paymentMethodId: _paymentMethodId,
          referenceNumber: reference,
          notes: notes,
        );
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(expenseCategoriesActiveListProvider);
    final paymentMethodsAsync = ref.watch(activePaymentMethodsProvider);

    return FormDialog(
      title: widget.existing != null ? 'Edit Expense' : 'Add Expense',
      width: 520,
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v?.trim().isEmpty ?? true ? 'Title is required' : null,
                autofocus: true,
              ),
              const SizedBox(height: 16),
              categoriesAsync.when(
                data: (categories) {
                  if (categories.isEmpty) {
                    return const Text(
                      'No expense categories. Add one first.',
                      style: TextStyle(color: Colors.orange),
                    );
                  }
                  if (_categoryId == null && categories.isNotEmpty) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted && _categoryId == null) {
                        setState(() => _categoryId = categories.first.id);
                      }
                    });
                  }
                  return DropdownButtonFormField<int>(
                    value: _categoryId,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                    ),
                    items: categories
                        .map((c) =>
                            DropdownMenuItem(value: c.id, child: Text(c.name)))
                        .toList(),
                    onChanged: (v) => setState(() => _categoryId = v),
                    validator: (v) =>
                        v == null ? 'Category is required' : null,
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const Text('Failed to load categories'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  border: OutlineInputBorder(),
                  prefixText: '\$ ',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  final n = double.tryParse(v?.trim() ?? '');
                  if (n == null || n <= 0) return 'Amount must be greater than 0';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Expense Date'),
                subtitle: Text(
                  '${_expenseDate.year}-${_expenseDate.month.toString().padLeft(2, '0')}-${_expenseDate.day.toString().padLeft(2, '0')}',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _expenseDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null && mounted) {
                      setState(() => _expenseDate = picked);
                    }
                  },
                ),
              ),
              const SizedBox(height: 16),
              paymentMethodsAsync.when(
                data: (methods) {
                  return DropdownButtonFormField<int?>(
                    value: _paymentMethodId,
                    decoration: const InputDecoration(
                      labelText: 'Payment Method (optional)',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('— None —'),
                      ),
                      ...methods.map((m) => DropdownMenuItem<int?>(
                            value: m.id,
                            child: Text(m.name),
                          )),
                    ],
                    onChanged: (v) => setState(() => _paymentMethodId = v),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _referenceController,
                decoration: const InputDecoration(
                  labelText: 'Reference Number (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
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
          onPressed: _submit,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
