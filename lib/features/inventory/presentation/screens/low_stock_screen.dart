import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/product_inventory_view.dart';
import '../providers/inventory_providers.dart';
import '../widgets/stock_status_badge.dart';
import '../dialogs/stock_adjustment_dialog.dart';

class LowStockScreen extends ConsumerWidget {
  const LowStockScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lowStockAsync = ref.watch(lowStockStreamProvider);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Low Stock & Out of Stock',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              SizedBox(
                width: 240,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search products',
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (v) =>
                      ref.read(lowStockSearchQueryProvider.notifier).state = v,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: lowStockAsync.when(
              data: (items) => _LowStockTable(
                items: items,
                onAdjust: (v) => _showAdjustmentDialog(context, ref, v),
                onViewDetail: (v) => _openProductDetail(context, ref, v),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }

  void _showAdjustmentDialog(
      BuildContext context, WidgetRef ref, ProductInventoryView view) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => StockAdjustmentDialog(product: view.product),
    ).then((_) {
      ref.invalidate(lowStockStreamProvider);
    });
  }

  void _openProductDetail(
      BuildContext context, WidgetRef ref, ProductInventoryView view) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (ctx) => _ProductDetailSheet(view: view),
      ),
    );
  }
}

class _LowStockTable extends StatelessWidget {
  const _LowStockTable({
    required this.items,
    required this.onAdjust,
    required this.onViewDetail,
  });

  final List<ProductInventoryView> items;
  final void Function(ProductInventoryView) onAdjust;
  final void Function(ProductInventoryView) onViewDetail;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline,
                size: 64, color: Colors.green.shade400),
            const SizedBox(height: 16),
            Text(
              'All products are well stocked',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No low stock or out of stock items',
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Product')),
              DataColumn(label: Text('SKU')),
              DataColumn(label: Text('Category')),
              DataColumn(label: Text('Current Stock'), numeric: true),
              DataColumn(label: Text('Reorder Level'), numeric: true),
              DataColumn(label: Text('Supplier')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Action')),
            ],
            rows: items.map((v) => _buildRow(context, v)).toList(),
          ),
        ),
      ),
    );
  }

  DataRow _buildRow(BuildContext context, ProductInventoryView v) {
    final p = v.product;
    return DataRow(
      cells: [
        DataCell(
          TextButton(
            onPressed: () => onViewDetail(v),
            child: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
        ),
        DataCell(Text(p.sku)),
        DataCell(Text(v.categoryName)),
        DataCell(Text(p.stockQuantity.toStringAsFixed(0))),
        DataCell(Text(p.reorderLevel.toStringAsFixed(0))),
        DataCell(Text(v.supplierName ?? '-')),
        DataCell(StockStatusBadge(
          status: v.stockStatus,
          compact: true,
        )),
        DataCell(
          FilledButton.tonal(
            onPressed: () => onAdjust(v),
            child: const Text('Adjust'),
          ),
        ),
      ],
    );
  }
}

class _ProductDetailSheet extends ConsumerWidget {
  const _ProductDetailSheet({required this.view});

  final ProductInventoryView view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(view.product.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              showDialog<bool>(
                context: context,
                builder: (ctx) => StockAdjustmentDialog(product: view.product),
              ).then((_) {
                ref.invalidate(lowStockStreamProvider);
                if (context.mounted) Navigator.of(context).pop();
              });
            },
            tooltip: 'Adjust stock',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Product Details',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 16),
                    _DetailRow('SKU', view.product.sku),
                    _DetailRow('Category', view.categoryName),
                    _DetailRow('Supplier', view.supplierName ?? '-'),
                    _DetailRow('Current Stock',
                        view.product.stockQuantity.toStringAsFixed(0)),
                    _DetailRow('Reorder Level',
                        view.product.reorderLevel.toStringAsFixed(0)),
                    _DetailRow('Status',
                        StockStatusBadge(
                          status: view.stockStatus,
                        )),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value);

  final String label;
  final dynamic value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: value is Widget
                ? value
                : Text(value?.toString() ?? '-'),
          ),
        ],
      ),
    );
  }
}
