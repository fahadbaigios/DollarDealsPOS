import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../database/app_database.dart';
import '../providers/products_providers.dart';
import '../widgets/form_dialog.dart';

Future<Category?> showCategoryFormDialog(
  BuildContext context, {
  Category? existing,
}) {
  return showDialog<Category>(
    context: context,
    builder: (context) => CategoryFormDialog(existing: existing),
  );
}

class CategoryFormDialog extends ConsumerStatefulWidget {
  const CategoryFormDialog({super.key, this.existing});

  final Category? existing;

  @override
  ConsumerState<CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends ConsumerState<CategoryFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existing?.name ?? '');
    _descController = TextEditingController(text: widget.existing?.description ?? '');
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
    final description = _descController.text.trim().isEmpty ? null : _descController.text.trim();
    final repo = ref.read(categoriesRepositoryProvider);

    if (widget.existing != null) {
      final existing = widget.existing!;
      final duplicate = await repo.getByName(name, excludeId: existing.id);
      if (duplicate != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('A category with this name already exists')),
          );
        }
        return;
      }
      await repo.update(existing.id, name, description: description, isActive: existing.isActive);
    } else {
      final duplicate = await repo.getByName(name);
      if (duplicate != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('A category with this name already exists')),
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
      title: widget.existing != null ? 'Edit Category' : 'Add Category',
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
              validator: (v) => v?.trim().isEmpty ?? true ? 'Name is required' : null,
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
