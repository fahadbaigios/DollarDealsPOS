import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../database/app_database.dart';
import '../providers/products_providers.dart';
import '../widgets/form_dialog.dart';

Future<Unit?> showUnitFormDialog(
  BuildContext context, {
  Unit? existing,
}) {
  return showDialog<Unit>(
    context: context,
    builder: (context) => UnitFormDialog(existing: existing),
  );
}

class UnitFormDialog extends ConsumerStatefulWidget {
  const UnitFormDialog({super.key, this.existing});

  final Unit? existing;

  @override
  ConsumerState<UnitFormDialog> createState() => _UnitFormDialogState();
}

class _UnitFormDialogState extends ConsumerState<UnitFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _symbolController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existing?.name ?? '');
    _symbolController = TextEditingController(text: widget.existing?.symbol ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _symbolController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final name = _nameController.text.trim();
    final symbol = _symbolController.text.trim();
    final repo = ref.read(unitsRepositoryProvider);

    if (widget.existing != null) {
      final existing = widget.existing!;
      final dupName = await repo.getByName(name, excludeId: existing.id);
      final dupSymbol = await repo.getBySymbol(symbol, excludeId: existing.id);
      if (dupName != null || dupSymbol != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Name or symbol already exists')),
          );
        }
        return;
      }
      await repo.update(existing.id, name, symbol);
    } else {
      final dupName = await repo.getByName(name);
      final dupSymbol = await repo.getBySymbol(symbol);
      if (dupName != null || dupSymbol != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Name or symbol already exists')),
          );
        }
        return;
      }
      await repo.create(name, symbol);
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return FormDialog(
      title: widget.existing != null ? 'Edit Unit' : 'Add Unit',
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
                hintText: 'e.g. Kilogram',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v?.trim().isEmpty ?? true ? 'Name is required' : null,
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _symbolController,
              decoration: const InputDecoration(
                labelText: 'Symbol (short name)',
                hintText: 'e.g. kg',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v?.trim().isEmpty ?? true ? 'Symbol is required' : null,
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
