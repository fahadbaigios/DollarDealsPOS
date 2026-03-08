import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../database/app_database.dart';
import '../providers/settings_providers.dart';

/// Dialog to add or edit a printer.
Future<bool?> showPrinterFormDialog(
  BuildContext context,
  WidgetRef ref, {
  PrinterSetting? existing,
}) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => _PrinterFormDialog(existing: existing, ref: ref),
  );
}

class _PrinterFormDialog extends ConsumerStatefulWidget {
  const _PrinterFormDialog({this.existing, required this.ref});

  final PrinterSetting? existing;
  final WidgetRef ref;

  @override
  ConsumerState<_PrinterFormDialog> createState() => _PrinterFormDialogState();
}

class _PrinterFormDialogState extends ConsumerState<_PrinterFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _paperWidthController;
  late TextEditingController _copiesController;
  String _printerType = 'thermal';
  bool _isDefault = true;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameController = TextEditingController(text: e?.printerName ?? '');
    _paperWidthController = TextEditingController(
      text: e?.paperWidth.toString() ?? '80',
    );
    _copiesController = TextEditingController(
      text: e?.copies.toString() ?? '1',
    );
    _printerType = e?.printerType ?? 'thermal';
    _isDefault = e?.isDefault ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _paperWidthController.dispose();
    _copiesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing != null ? 'Edit Printer' : 'Add Printer'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Printer Name *',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _printerType,
                decoration: const InputDecoration(
                  labelText: 'Printer Type *',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'thermal', child: Text('Thermal')),
                  DropdownMenuItem(value: 'a4', child: Text('A4')),
                ],
                onChanged: (v) => setState(() => _printerType = v ?? 'thermal'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _paperWidthController,
                decoration: const InputDecoration(
                  labelText: 'Paper Width (mm) *',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  final w = double.tryParse(v ?? '');
                  return w == null || w <= 0 ? 'Required, > 0' : null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _copiesController,
                decoration: const InputDecoration(
                  labelText: 'Copies *',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  final c = int.tryParse(v ?? '');
                  return c == null || c < 1 ? 'Must be >= 1' : null;
                },
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Default printer'),
                value: _isDefault,
                onChanged: (v) => setState(() => _isDefault = v),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => _save(),
          child: const Text('Save'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final paperWidth = double.tryParse(_paperWidthController.text) ?? 80.0;
    final copies = int.tryParse(_copiesController.text) ?? 1;

    await ref.read(settingsRepositoryProvider).savePrinter(
          printerName: _nameController.text.trim(),
          printerType: _printerType,
          paperWidth: paperWidth,
          isDefault: _isDefault,
          copies: copies,
          id: widget.existing?.id,
        );

    if (!context.mounted) return;
    Navigator.pop(context, true);
  }
}
