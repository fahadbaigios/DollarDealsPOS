import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../database/app_database.dart';
import '../providers/products_providers.dart';
import '../widgets/form_dialog.dart';

Future<Product?> showProductFormDialog(
  BuildContext context, {
  Product? existing,
}) {
  return showDialog<Product>(
    context: context,
    builder: (context) => ProductFormDialog(existing: existing),
  );
}

class ProductFormDialog extends ConsumerStatefulWidget {
  const ProductFormDialog({super.key, this.existing});

  final Product? existing;

  @override
  ConsumerState<ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends ConsumerState<ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _skuController;
  late final TextEditingController _barcodeController;
  late final TextEditingController _descController;
  late final TextEditingController _costController;
  late final TextEditingController _priceController;
  late final TextEditingController _taxController;
  late final TextEditingController _reorderController;

  int? _categoryId;
  int? _supplierId;
  int? _unitId;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameController = TextEditingController(text: e?.name ?? '');
    _skuController = TextEditingController(text: e?.sku ?? '');
    _barcodeController = TextEditingController(text: e?.barcode ?? '');
    _descController = TextEditingController(text: e?.description ?? '');
    _costController = TextEditingController(text: e?.costPrice.toString() ?? '0');
    _priceController = TextEditingController(text: e?.salePrice.toString() ?? '0');
    _taxController = TextEditingController(text: (e?.taxRate ?? 0).toString());
    _reorderController = TextEditingController(text: (e?.reorderLevel ?? 0).toString());
    _categoryId = e?.categoryId;
    _supplierId = e?.supplierId;
    _unitId = e?.unitId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _barcodeController.dispose();
    _descController.dispose();
    _costController.dispose();
    _priceController.dispose();
    _taxController.dispose();
    _reorderController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categoryId == null || _unitId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select category and unit')),
      );
      return;
    }

    final cost = double.tryParse(_costController.text) ?? 0;
    final price = double.tryParse(_priceController.text) ?? 0;
    final tax = double.tryParse(_taxController.text) ?? 0;
    final reorder = double.tryParse(_reorderController.text) ?? 0;

    final repo = ref.read(productsRepositoryProvider);

    if (widget.existing != null) {
      final existing = widget.existing!;
      final dupSku = await repo.getBySku(_skuController.text.trim(), excludeId: existing.id);
      if (dupSku != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('A product with this SKU already exists')),
          );
        }
        return;
      }
      await repo.update(
        id: existing.id,
        name: _nameController.text.trim(),
        sku: _skuController.text.trim(),
        barcode: _barcodeController.text.trim().isEmpty ? null : _barcodeController.text.trim(),
        categoryId: _categoryId!,
        supplierId: _supplierId,
        unitId: _unitId!,
        description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
        costPrice: cost,
        salePrice: price,
        taxRate: tax,
        reorderLevel: reorder,
        isActive: existing.isActive,
      );
    } else {
      final dupSku = await repo.getBySku(_skuController.text.trim());
      if (dupSku != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('A product with this SKU already exists')),
          );
        }
        return;
      }
      await repo.create(
        name: _nameController.text.trim(),
        sku: _skuController.text.trim(),
        barcode: _barcodeController.text.trim().isEmpty ? null : _barcodeController.text.trim(),
        categoryId: _categoryId!,
        supplierId: _supplierId,
        unitId: _unitId!,
        description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
        costPrice: cost,
        salePrice: price,
        taxRate: tax,
        stockQuantity: widget.existing?.stockQuantity ?? 0,
        reorderLevel: reorder,
      );
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesListProvider);
    final unitsAsync = ref.watch(unitsListProvider);
    final suppliersAsync = ref.watch(suppliersListProvider);

    return FormDialog(
      title: widget.existing != null ? 'Edit Product' : 'Add Product',
      width: 560,
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
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
              const SizedBox(height: 12),
              TextFormField(
                controller: _skuController,
                decoration: const InputDecoration(
                  labelText: 'SKU',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v?.trim().isEmpty ?? true ? 'SKU is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _barcodeController,
                decoration: const InputDecoration(
                  labelText: 'Barcode (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              categoriesAsync.when(
                data: (categories) => DropdownButtonFormField<int>(
                  value: _categoryId,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: categories
                      .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                      .toList(),
                  onChanged: (v) => setState(() => _categoryId = v),
                  validator: (v) => v == null ? 'Category is required' : null,
                ),
                loading: () => const LinearProgressIndicator(),
                error: (e, st) => Text('Failed to load categories: $e'),
              ),
              const SizedBox(height: 12),
              unitsAsync.when(
                data: (units) => DropdownButtonFormField<int>(
                  value: _unitId,
                  decoration: const InputDecoration(
                    labelText: 'Unit',
                    border: OutlineInputBorder(),
                  ),
                  items: units.map((u) => DropdownMenuItem(value: u.id, child: Text('${u.name} (${u.symbol})'))).toList(),
                  onChanged: (v) => setState(() => _unitId = v),
                  validator: (v) => v == null ? 'Unit is required' : null,
                ),
                loading: () => const LinearProgressIndicator(),
                error: (e, st) => Text('Failed to load units: $e'),
              ),
              const SizedBox(height: 12),
              suppliersAsync.when(
                data: (suppliers) => DropdownButtonFormField<int?>(
                  value: _supplierId,
                  decoration: const InputDecoration(
                    labelText: 'Supplier (optional)',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<int?>(value: null, child: Text('— None —')),
                    ...suppliers.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))),
                  ],
                  onChanged: (v) => setState(() => _supplierId = v),
                ),
                loading: () => const LinearProgressIndicator(),
                error: (e, st) => Text('Failed to load suppliers: $e'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _costController,
                      decoration: const InputDecoration(
                        labelText: 'Cost Price',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) {
                        final n = double.tryParse(v ?? '');
                        if (n == null || n < 0) return 'Must be >= 0';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(
                        labelText: 'Selling Price',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) {
                        final n = double.tryParse(v ?? '');
                        if (n == null || n <= 0) return 'Must be > 0';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _taxController,
                      decoration: const InputDecoration(
                        labelText: 'Tax Rate %',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _reorderController,
                      decoration: const InputDecoration(
                        labelText: 'Reorder Level',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) {
                        final n = double.tryParse(v ?? '');
                        if (n == null || n < 0) return 'Must be >= 0';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              if (widget.existing != null) ...[
                const SizedBox(height: 12),
                Text(
                  'Stock: ${widget.existing!.stockQuantity} (read-only)',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
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
