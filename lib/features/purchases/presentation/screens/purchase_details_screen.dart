import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../database/app_database.dart';
import '../../../products/presentation/widgets/page_header.dart';
import '../../../products/presentation/providers/products_providers.dart';
import '../providers/purchases_providers.dart';
import '../widgets/payment_status_badge.dart';

class PurchaseDetailsScreen extends ConsumerWidget {
  const PurchaseDetailsScreen({super.key, required this.purchaseId});

  final int purchaseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final purchaseAsync = ref.watch(purchaseDetailProvider(purchaseId));
    final itemsAsync = ref.watch(purchaseItemsProvider(purchaseId));
    final suppliersAsync = ref.watch(activeSuppliersProvider);
    final productsAsync = ref.watch(productsRepositoryProvider);

    return purchaseAsync.when(
      data: (purchase) {
        if (purchase == null) {
          return const Center(child: Text('Purchase not found'));
        }
        return _PurchaseDetailsContent(
          purchase: purchase,
          itemsAsync: itemsAsync,
          supplierName: suppliersAsync.valueOrNull
                  ?.where((s) => s.id == purchase.supplierId)
                  .map((s) => s.name)
                  .firstOrNull ??
              '—',
          getProductName: (id) async {
            final p = await productsAsync.getById(id);
            return p?.name ?? '—';
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

class _PurchaseDetailsContent extends StatelessWidget {
  const _PurchaseDetailsContent({
    required this.purchase,
    required this.itemsAsync,
    required this.supplierName,
    required this.getProductName,
  });

  final Purchase purchase;
  final AsyncValue<List<PurchaseItem>> itemsAsync;
  final String supplierName;
  final Future<String> Function(int) getProductName;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          title: 'Purchase Details',
          actions: [
            TextButton.icon(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back, size: 20),
              label: const Text('Back'),
            ),
          ],
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _InfoCard(
                  purchase: purchase,
                  supplierName: supplierName,
                ),
                const SizedBox(height: 24),
                _ItemsCard(itemsAsync: itemsAsync, getProductName: getProductName),
                const SizedBox(height: 24),
                _TotalsCard(purchase: purchase),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.purchase,
    required this.supplierName,
  });

  final Purchase purchase;
  final String supplierName;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Purchase Info', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            _InfoRow('Supplier', supplierName),
            _InfoRow('Invoice', purchase.invoiceNumber ?? '—'),
            _InfoRow('Date', _formatDate(purchase.purchaseDate)),
            if (purchase.notes != null && purchase.notes!.isNotEmpty)
              _InfoRow('Notes', purchase.notes!),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _ItemsCard extends StatelessWidget {
  const _ItemsCard({
    required this.itemsAsync,
    required this.getProductName,
  });

  final AsyncValue<List<PurchaseItem>> itemsAsync;
  final Future<String> Function(int) getProductName;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Items', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            itemsAsync.when(
              data: (items) => _ItemsTable(items: items, getProductName: getProductName),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemsTable extends StatelessWidget {
  const _ItemsTable({
    required this.items,
    required this.getProductName,
  });

  final List<PurchaseItem> items;
  final Future<String> Function(int) getProductName;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Product')),
          DataColumn(label: Text('Qty')),
          DataColumn(label: Text('Unit Cost')),
          DataColumn(label: Text('Discount')),
          DataColumn(label: Text('Tax')),
          DataColumn(label: Text('Total')),
        ],
        rows: items.map((i) => _buildRow(context, i)).toList(),
      ),
    );
  }

  DataRow _buildRow(BuildContext context, PurchaseItem item) {
    return DataRow(
      cells: [
        DataCell(FutureBuilder<String>(
          future: getProductName(item.productId),
          builder: (_, snap) => Text(snap.data ?? '...'))),
        DataCell(Text(item.quantity.toStringAsFixed(0))),
        DataCell(Text('\$${item.unitCost.toStringAsFixed(2)}')),
        DataCell(Text('\$${item.itemDiscount.toStringAsFixed(2)}')),
        DataCell(Text('\$${item.itemTax.toStringAsFixed(2)}')),
        DataCell(Text('\$${item.totalCost.toStringAsFixed(2)}')),
      ],
    );
  }
}

class _TotalsCard extends StatelessWidget {
  const _TotalsCard({required this.purchase});

  final Purchase purchase;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Summary', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            _TotalRow('Subtotal', purchase.subtotal),
            _TotalRow('Discount', -purchase.discountAmount),
            _TotalRow('Tax', purchase.taxAmount),
            _TotalRow('Other Charges', purchase.otherCharges),
            const Divider(),
            _TotalRow('Total', purchase.totalAmount, bold: true),
            _TotalRow('Paid', purchase.paidAmount),
            _TotalRow('Due', purchase.dueAmount),
            const SizedBox(height: 12),
            PaymentStatusBadge(status: purchase.paymentStatus),
          ],
        ),
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow(this.label, this.amount, {this.bold = false});

  final String label;
  final double amount;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: bold ? FontWeight.bold : null)),
          Text(
            '\$${amount.toStringAsFixed(2)}',
            style: TextStyle(fontWeight: bold ? FontWeight.bold : null),
          ),
        ],
      ),
    );
  }
}
