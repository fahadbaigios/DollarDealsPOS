import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../database/app_database.dart';
import '../../../products/presentation/providers/products_providers.dart';
import '../../domain/models/product_inventory_view.dart';
import '../providers/inventory_providers.dart';
import '../widgets/stock_status_badge.dart';
import '../widgets/stock_summary_card.dart';
import '../dialogs/stock_adjustment_dialog.dart';

class InventoryOverviewScreen extends ConsumerWidget {
  const InventoryOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overviewAsync = ref.watch(inventoryOverviewStreamProvider);
    final summaryAsync = ref.watch(inventorySummaryProvider);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Inventory Overview',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              FilledButton.icon(
                onPressed: () => _showAdjustmentDialog(context, ref),
                icon: const Icon(Icons.add),
                label: const Text('Adjust Stock'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          summaryAsync.when(
            data: (s) => Row(
              children: [
                Expanded(
                  child: StockSummaryCard(
                    title: 'Total Products',
                    count: s.totalProducts,
                    icon: Icons.inventory_2_outlined,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: StockSummaryCard(
                    title: 'Low Stock',
                    count: s.lowStockCount,
                    icon: Icons.warning_amber_outlined,
                    color: Colors.orange,
                    onTap: () => ref
                        .read(inventoryStockStatusFilterProvider.notifier)
                        .state = 'low_stock',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: StockSummaryCard(
                    title: 'Out of Stock',
                    count: s.outOfStockCount,
                    icon: Icons.remove_shopping_cart_outlined,
                    color: Colors.red,
                    onTap: () => ref
                        .read(inventoryStockStatusFilterProvider.notifier)
                        .state = 'out_of_stock',
                  ),
                ),
              ],
            ),
            loading: () => const SizedBox(height: 80),
            error: (e, _) => Text('Error: $e'),
          ),
          const SizedBox(height: 24),
          const _FilterBar(),
          const SizedBox(height: 16),
          Expanded(
            child: overviewAsync.when(
              data: (items) => _InventoryTable(
                items: items,
                onViewDetail: (v) => _openProductDetail(context, ref, v),
                onAdjust: (v) => _showAdjustmentDialog(context, ref, product: v.product),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }

  void _showAdjustmentDialog(BuildContext context, WidgetRef ref,
      {Product? product}) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => StockAdjustmentDialog(product: product),
    ).then((_) {
      ref.invalidate(inventoryOverviewStreamProvider);
      ref.invalidate(inventorySummaryProvider);
    });
  }

  void _openProductDetail(
      BuildContext context, WidgetRef ref, ProductInventoryView view) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (ctx) => _ProductDetailPage(view: view),
      ),
    );
  }
}

class _FilterBar extends ConsumerWidget {
  const _FilterBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesListProvider);
    final search = ref.watch(inventorySearchQueryProvider);
    final categoryId = ref.watch(inventoryCategoryFilterProvider);
    final isActive = ref.watch(inventoryActiveFilterProvider);
    final stockStatus = ref.watch(inventoryStockStatusFilterProvider);

    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        SizedBox(
          width: 240,
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search by name, SKU, barcode',
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (v) =>
                ref.read(inventorySearchQueryProvider.notifier).state = v,
          ),
        ),
        categoriesAsync.when(
          data: (cats) => DropdownButtonFormField<int?>(
            value: categoryId,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: [
              const DropdownMenuItem(value: null, child: Text('All Categories')),
              ...cats.map((c) => DropdownMenuItem(
                    value: c.id,
                    child: Text(c.name),
                  )),
            ],
            onChanged: (v) =>
                ref.read(inventoryCategoryFilterProvider.notifier).state = v,
          ),
          loading: () => const SizedBox(),
          error: (_, __) => const SizedBox(),
        ),
        DropdownButtonFormField<bool?>(
          value: isActive,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: const [
            DropdownMenuItem(value: null, child: Text('All')),
            DropdownMenuItem(value: true, child: Text('Active')),
            DropdownMenuItem(value: false, child: Text('Inactive')),
          ],
          onChanged: (v) =>
              ref.read(inventoryActiveFilterProvider.notifier).state = v,
        ),
        DropdownButtonFormField<String?>(
          value: stockStatus,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: const [
            DropdownMenuItem(value: null, child: Text('All Status')),
            DropdownMenuItem(value: 'normal', child: Text('Normal')),
            DropdownMenuItem(value: 'low_stock', child: Text('Low Stock')),
            DropdownMenuItem(value: 'out_of_stock', child: Text('Out of Stock')),
          ],
          onChanged: (v) =>
              ref.read(inventoryStockStatusFilterProvider.notifier).state = v,
        ),
        if (search.isNotEmpty ||
            categoryId != null ||
            isActive != null ||
            stockStatus != null)
          TextButton.icon(
            onPressed: () {
              ref.read(inventorySearchQueryProvider.notifier).state = '';
              ref.read(inventoryCategoryFilterProvider.notifier).state = null;
              ref.read(inventoryActiveFilterProvider.notifier).state = null;
              ref.read(inventoryStockStatusFilterProvider.notifier).state = null;
            },
            icon: const Icon(Icons.clear),
            label: const Text('Clear'),
          ),
      ],
    );
  }
}

class _InventoryTable extends StatelessWidget {
  const _InventoryTable({
    required this.items,
    required this.onViewDetail,
    required this.onAdjust,
  });

  final List<ProductInventoryView> items;
  final void Function(ProductInventoryView) onViewDetail;
  final void Function(ProductInventoryView) onAdjust;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No products match your filters',
              style: TextStyle(color: Colors.grey.shade600),
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
              DataColumn(label: Text('Barcode')),
              DataColumn(label: Text('Category')),
              DataColumn(label: Text('Supplier')),
              DataColumn(label: Text('Unit')),
              DataColumn(label: Text('Stock'), numeric: true),
              DataColumn(label: Text('Reorder'), numeric: true),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Active')),
              DataColumn(label: Text('Actions')),
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
        DataCell(Text(p.barcode ?? '-')),
        DataCell(Text(v.categoryName)),
        DataCell(Text(v.supplierName ?? '-')),
        DataCell(Text(v.unitName)),
        DataCell(Text(p.stockQuantity.toStringAsFixed(0))),
        DataCell(Text(p.reorderLevel.toStringAsFixed(0))),
        DataCell(StockStatusBadge(
          status: p.isActive ? v.stockStatus : 'inactive',
          compact: true,
        )),
        DataCell(Text(p.isActive ? 'Yes' : 'No')),
        DataCell(
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => onAdjust(v),
            tooltip: 'Adjust stock',
          ),
        ),
      ],
    );
  }
}

class _ProductDetailPage extends ConsumerWidget {
  const _ProductDetailPage({required this.view});

  final ProductInventoryView view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync =
        ref.watch(productRecentTransactionsProvider(view.product.id));

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
                ref.invalidate(productInventoryDetailProvider(view.product.id));
                ref.invalidate(productRecentTransactionsProvider(view.product.id));
              });
            },
            tooltip: 'Adjust stock',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 1,
              child: Card(
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
                      _DetailRow('Unit', view.unitName),
                      _DetailRow('Current Stock',
                          view.product.stockQuantity.toStringAsFixed(0)),
                      _DetailRow('Reorder Level',
                          view.product.reorderLevel.toStringAsFixed(0)),
                      _DetailRow('Cost Price',
                          '\$${view.product.costPrice.toStringAsFixed(2)}'),
                      _DetailRow('Selling Price',
                          '\$${view.product.salePrice.toStringAsFixed(2)}'),
                      _DetailRow('Status',
                          StockStatusBadge(
                            status: view.product.isActive
                                ? view.stockStatus
                                : 'inactive',
                          )),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              flex: 2,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Recent Transactions',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 16),
                      Expanded(
                        child: transactionsAsync.when(
                          data: (txs) => txs.isEmpty
                              ? const Center(
                                  child: Text('No transactions yet'),
                                )
                              : ListView.builder(
                                  itemCount: txs.length,
                                  itemBuilder: (_, i) {
                                    final t = txs[i];
                                    return ListTile(
                                      dense: true,
                                      title: Text(t.transactionType),
                                      subtitle: Text(
                                        '${t.quantity} @ ${t.createdAt}',
                                      ),
                                      trailing: Text(
                                        t.unitCost != null
                                            ? '\$${t.unitCost!.toStringAsFixed(2)}'
                                            : '-',
                                      ),
                                    );
                                  },
                                ),
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                          error: (e, _) => Text('Error: $e'),
                        ),
                      ),
                    ],
                  ),
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
