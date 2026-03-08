import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../database/app_database.dart';
import '../../../../database/database_constants.dart';
import '../../../purchases/presentation/providers/purchases_providers.dart';
import '../../domain/models/transaction_with_product.dart';
import '../providers/inventory_providers.dart';
import '../widgets/transaction_type_badge.dart';

class InventoryTransactionsScreen extends ConsumerWidget {
  const InventoryTransactionsScreen({super.key});

  static const List<String> _transactionTypes = [
    DatabaseConstants.transactionTypePurchase,
    DatabaseConstants.transactionTypeSale,
    DatabaseConstants.transactionTypeReturnIn,
    DatabaseConstants.transactionTypeReturnOut,
    DatabaseConstants.transactionTypeAdjustmentIn,
    DatabaseConstants.transactionTypeAdjustmentOut,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(inventoryTransactionsStreamProvider);
    final productsAsync = ref.watch(activeProductsProvider);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Inventory Transaction History',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 20),
          _FilterBar(
            productsAsync: productsAsync,
            transactionTypes: _transactionTypes,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: transactionsAsync.when(
              data: (items) => _TransactionsTable(
                items: items,
                onProductTap: (twp) {
                  // Could open product detail
                },
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterBar extends ConsumerWidget {
  const _FilterBar({
    required this.productsAsync,
    required this.transactionTypes,
  });

  final AsyncValue<List<Product>> productsAsync;
  final List<String> transactionTypes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productId = ref.watch(transactionsProductFilterProvider);
    final type = ref.watch(transactionsTypeFilterProvider);
    final from = ref.watch(transactionsDateFromProvider);
    final to = ref.watch(transactionsDateToProvider);

    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        productsAsync.when(
          data: (products) => SizedBox(
            width: 260,
            child: DropdownButtonFormField<int?>(
              value: productId,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('All Products')),
                ...products.map((p) => DropdownMenuItem(
                      value: p.id,
                      child: Text('${p.name} (${p.sku})',
                          overflow: TextOverflow.ellipsis),
                    )),
              ],
              onChanged: (v) =>
                  ref.read(transactionsProductFilterProvider.notifier).state = v,
            ),
          ),
          loading: () => const SizedBox(width: 260),
          error: (_, __) => const SizedBox(),
        ),
        SizedBox(
          width: 160,
          child: DropdownButtonFormField<String?>(
            value: type,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: [
              const DropdownMenuItem(value: null, child: Text('All Types')),
              ...transactionTypes.map((t) => DropdownMenuItem(
                    value: t,
                    child: Text(_typeLabel(t)),
                  )),
            ],
            onChanged: (v) =>
                ref.read(transactionsTypeFilterProvider.notifier).state = v,
          ),
        ),
        OutlinedButton.icon(
          onPressed: () async {
            final d = await showDatePicker(
              context: context,
              initialDate: from ?? DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
            );
            if (d != null) {
              ref.read(transactionsDateFromProvider.notifier).state = d;
            }
          },
          icon: const Icon(Icons.calendar_today, size: 18),
          label: Text(from != null
              ? '${from.year}-${from.month.toString().padLeft(2, '0')}-${from.day.toString().padLeft(2, '0')}'
              : 'From'),
        ),
        OutlinedButton.icon(
          onPressed: () async {
            final d = await showDatePicker(
              context: context,
              initialDate: to ?? DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
            );
            if (d != null) {
              ref.read(transactionsDateToProvider.notifier).state = d;
            }
          },
          icon: const Icon(Icons.calendar_today, size: 18),
          label: Text(to != null
              ? '${to.year}-${to.month.toString().padLeft(2, '0')}-${to.day.toString().padLeft(2, '0')}'
              : 'To'),
        ),
        if (productId != null || type != null || from != null || to != null)
          TextButton.icon(
            onPressed: () {
              ref.read(transactionsProductFilterProvider.notifier).state = null;
              ref.read(transactionsTypeFilterProvider.notifier).state = null;
              ref.read(transactionsDateFromProvider.notifier).state = null;
              ref.read(transactionsDateToProvider.notifier).state = null;
            },
            icon: const Icon(Icons.clear),
            label: const Text('Clear'),
          ),
      ],
    );
  }

  static String _typeLabel(String t) {
    switch (t) {
      case 'purchase':
        return 'Purchase';
      case 'sale':
        return 'Sale';
      case 'return_in':
        return 'Return In';
      case 'return_out':
        return 'Return Out';
      case 'adjustment_in':
        return 'Adjust In';
      case 'adjustment_out':
        return 'Adjust Out';
      default:
        return t;
    }
  }
}

class _TransactionsTable extends StatelessWidget {
  const _TransactionsTable({
    required this.items,
    required this.onProductTap,
  });

  final List<TransactionWithProduct> items;
  final void Function(TransactionWithProduct) onProductTap;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No transactions found',
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
              DataColumn(label: Text('Date/Time')),
              DataColumn(label: Text('Product')),
              DataColumn(label: Text('SKU')),
              DataColumn(label: Text('Type')),
              DataColumn(label: Text('Reference'), numeric: true),
              DataColumn(label: Text('Quantity'), numeric: true),
              DataColumn(label: Text('Unit Cost'), numeric: true),
              DataColumn(label: Text('Notes')),
            ],
            rows: items.map((twp) => _buildRow(context, twp)).toList(),
          ),
        ),
      ),
    );
  }

  DataRow _buildRow(BuildContext context, TransactionWithProduct twp) {
    final t = twp.transaction;
    return DataRow(
      cells: [
        DataCell(Text(_formatDate(t.createdAt))),
        DataCell(Text(twp.productName)),
        DataCell(Text(twp.productSku)),
        DataCell(TransactionTypeBadge(
          transactionType: t.transactionType,
          compact: true,
        )),
        DataCell(Text(t.referenceId?.toString() ?? '-')),
        DataCell(Text(t.quantity.toStringAsFixed(0))),
        DataCell(Text(
          t.unitCost != null ? '\$${t.unitCost!.toStringAsFixed(2)}' : '-',
        )),
        DataCell(Text(t.notes ?? '-', maxLines: 2, overflow: TextOverflow.ellipsis)),
      ],
    );
  }

  String _formatDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }
}
