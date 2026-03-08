import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../database/app_database.dart';
import '../../../../database/database_constants.dart';
import '../../../purchases/presentation/providers/purchases_providers.dart';
import '../providers/inventory_providers.dart';

/// Dialog for stock adjustment (adjustment_in / adjustment_out).
class StockAdjustmentDialog extends ConsumerStatefulWidget {
  const StockAdjustmentDialog({
    super.key,
    this.product,
    this.productId,
  });

  /// Pre-selected product when opened from product detail.
  final Product? product;
  final int? productId;

  @override
  ConsumerState<StockAdjustmentDialog> createState() =>
      _StockAdjustmentDialogState();
}

class _StockAdjustmentDialogState extends ConsumerState<StockAdjustmentDialog> {
  final _formKey = GlobalKey<FormState>();
  Product? _selectedProduct;
  String _adjustmentType = DatabaseConstants.transactionTypeAdjustmentIn;
  final _quantityController = TextEditingController();
  final _unitCostController = TextEditingController();
  final _notesController = TextEditingController();
  bool _allowNegativeStock = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _selectedProduct = widget.product;
      _unitCostController.text = widget.product!.costPrice.toStringAsFixed(2);
    } else if (widget.productId != null) {
      _loadProduct(widget.productId!);
    }
  }

  Future<void> _loadProduct(int id) async {
    final product = await ref.read(inventoryRepositoryProvider).getProductById(id);
    if (product != null && mounted) {
      setState(() {
        _selectedProduct = product;
        _unitCostController.text = product.costPrice.toStringAsFixed(2);
      });
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _unitCostController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a product')),
      );
      return;
    }

    final qty = double.tryParse(_quantityController.text.trim());
    if (qty == null || qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quantity must be greater than zero')),
      );
      return;
    }

    final notes = _notesController.text.trim();
    if (notes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notes are required for audit trail'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref.read(stockAdjustmentServiceProvider).adjustStock(
            productId: _selectedProduct!.id,
            adjustmentType: _adjustmentType,
            quantity: qty,
            unitCost: double.tryParse(_unitCostController.text.trim()),
            notes: notes,
            allowNegativeStock: _allowNegativeStock,
          );
      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Stock adjusted successfully')),
        );
      }
    } on StateError catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(activeProductsProvider);

    return AlertDialog(
      title: const Text('Stock Adjustment'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.product == null && widget.productId == null) ...[
                  const Text('Product', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  productsAsync.when(
                    data: (products) => DropdownButtonFormField<Product>(
                      value: _selectedProduct,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: products
                          .map((p) => DropdownMenuItem(
                                value: p,
                                child: Text('${p.name} (${p.sku})'),
                              ))
                          .toList(),
                      onChanged: (p) {
                        setState(() {
                          _selectedProduct = p;
                          if (p != null) {
                            _unitCostController.text =
                                p.costPrice.toStringAsFixed(2);
                          }
                        });
                      },
                      validator: (v) =>
                          v == null ? 'Select a product' : null,
                    ),
                    loading: () => const CircularProgressIndicator(),
                    error: (e, _) => Text('Error: $e'),
                  ),
                  const SizedBox(height: 16),
                ] else if (_selectedProduct != null)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      '${_selectedProduct!.name} (${_selectedProduct!.sku})',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(
                      'Current stock: ${_selectedProduct!.stockQuantity.toStringAsFixed(0)}',
                    ),
                  ),
                const SizedBox(height: 16),
                const Text('Adjustment Type', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: DatabaseConstants.transactionTypeAdjustmentIn,
                      label: Text('Add Stock'),
                      icon: Icon(Icons.add),
                    ),
                    ButtonSegment(
                      value: DatabaseConstants.transactionTypeAdjustmentOut,
                      label: Text('Remove Stock'),
                      icon: Icon(Icons.remove),
                    ),
                  ],
                  selected: {_adjustmentType},
                  onSelectionChanged: (s) =>
                      setState(() => _adjustmentType = s.first),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _quantityController,
                  decoration: const InputDecoration(
                    labelText: 'Quantity *',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) {
                    final n = double.tryParse(v ?? '');
                    if (n == null || n <= 0) return 'Quantity must be > 0';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _unitCostController,
                  decoration: const InputDecoration(
                    labelText: 'Unit Cost (optional)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes *',
                    hintText: 'Reason for adjustment',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                  validator: (v) =>
                      (v ?? '').trim().isEmpty ? 'Notes are required' : null,
                ),
                if (_adjustmentType ==
                    DatabaseConstants.transactionTypeAdjustmentOut) ...[
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    value: _allowNegativeStock,
                    onChanged: (v) =>
                        setState(() => _allowNegativeStock = v ?? false),
                    title: const Text(
                      'Allow negative stock',
                      style: TextStyle(fontSize: 13),
                    ),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Apply'),
        ),
      ],
    );
  }
}
