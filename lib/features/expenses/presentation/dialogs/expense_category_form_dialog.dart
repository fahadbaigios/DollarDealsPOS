import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../database/app_database.dart';
import '../providers/expenses_providers.dart';
import '../../../../features/products/presentation/widgets/form_dialog.dart';

Future<ExpenseCategory?> showExpenseCategoryFormDialog(
  BuildContext context, {
  ExpenseCategory? existing,
}) {
  return showDialog<ExpenseCategory>(
    context: context,
    builder: (context) => ExpenseCategoryFormDialog(existing: existing),
  );
}

class ExpenseCategoryFormDialog extends ConsumerStatefulWidget {
  const ExpenseCategoryFormDialog({super.key, this.existing});

  final ExpenseCategory? existing;

  @override
  ConsumerState<ExpenseCategoryFormDialog> createState() =>
      _ExpenseCategoryFormDialogState();
}

class _ExpenseCategoryFormDialogState extends ConsumerState<ExpenseCategoryFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existing?.name ?? '');
    _descController =
        TextEditingController(text: widget.existing?.description ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final name = _nameController.text.trim();
    final description =
        _descController.text.trim().isEmpty ? null : _descController.text.trim();
    final repo = ref.read(expenseCategoriesRepositoryProvider);

    if (widget.existing != null) {
      final existing = widget.existing!;
      final duplicate = await repo.getByName(name, excludeId: existing.id);
      if (duplicate != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('An expense category with this name already exists')),
          );
        }
        return;
      }
      await repo.update(existing.id, name, description: description);
    } else {
      final duplicate = await repo.getByName(name);
      if (duplicate != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('An expense category with this name already exists')),
          );
        }
        return;
      }
      await repo.create(name, description: description);
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return FormDialog(
      title: widget.existing != null ? 'Edit Expense Category' : 'Add Expense Category',
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  v?.trim().isEmpty ?? true ? 'Name is required' : null,
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
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
