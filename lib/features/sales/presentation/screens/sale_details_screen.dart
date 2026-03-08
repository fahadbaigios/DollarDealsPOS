import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../database/app_database.dart';
import '../../../printing/presentation/providers/printing_providers.dart';
import '../../../printing/presentation/widgets/receipt_actions_menu.dart';
import '../../../products/presentation/providers/products_providers.dart';
import '../providers/sales_providers.dart';
import '../widgets/payment_status_badge.dart';

String _formatDate(DateTime d) {
  return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} '
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}

class SaleDetailsScreen extends ConsumerWidget {
  const SaleDetailsScreen({super.key, required this.saleId});

  final int saleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saleAsync = ref.watch(saleDetailProvider(saleId));
    final itemsAsync = ref.watch(saleItemsProvider(saleId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sale Details'),
        actions: [
          saleAsync.when(
            data: (sale) => sale != null
                ? ReceiptActionsMenu(
                    saleId: saleId,
                    invoiceNumber: sale.invoiceNumber,
                    onReprintComplete: () => ref.invalidate(receiptForSaleProvider(saleId)),
                  )
                : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: saleAsync.when(
        data: (sale) {
          if (sale == null) {
            return const Center(child: Text('Sale not found'));
          }
          return _SaleContent(sale: sale, itemsAsync: itemsAsync);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _SaleContent extends ConsumerWidget {
  const _SaleContent({
    required this.sale,
    required this.itemsAsync,
  });

  final Sale sale;
  final AsyncValue<List<SaleItem>> itemsAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receiptAsync = ref.watch(receiptForSaleProvider(sale.id));
    return FutureBuilder<({Customer? customer, PaymentMethod? paymentMethod, User? cashier})>(
      future: () async {
        final customersRepo = ref.read(customersRepositoryProvider);
        final paymentRepo = ref.read(paymentMethodsRepositoryProvider);
        final usersRepo = ref.read(usersRepositoryProvider);
        final customer = sale.customerId != null
            ? await customersRepo.getById(sale.customerId!)
            : null;
        final paymentMethod = sale.paymentMethodId != null
            ? await paymentRepo.getById(sale.paymentMethodId!)
            : null;
        final cashier = await usersRepo.getById(sale.cashierId);
        return (customer: customer, paymentMethod: paymentMethod, cashier: cashier);
      }(),
      builder: (context, snap) {
        final customer = snap.data?.customer;
        final paymentMethod = snap.data?.paymentMethod;
        final cashier = snap.data?.cashier;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Sale Info', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 16),
                      _DetailRow('Invoice', sale.invoiceNumber),
                      _DetailRow('Date', sale.saleDate.toIso8601String()),
                      _DetailRow('Customer', customer?.name ?? 'Walk-in'),
                      _DetailRow('Cashier', cashier?.fullName ?? '-'),
                      _DetailRow('Payment Method', paymentMethod?.name ?? '-'),
                      _DetailRow('Status', PaymentStatusBadge(status: sale.paymentStatus)),
                      receiptAsync.when(
                        data: (r) => r != null
                            ? _DetailRow(
                                'Receipt',
                                'Printed ${r.printedCount}x${r.lastPrintedAt != null ? ' • Last: ${_formatDate(r.lastPrintedAt!)}' : ''}',
                              )
                            : const SizedBox.shrink(),
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Totals', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 16),
                      _DetailRow('Subtotal', '\$${sale.subtotal.toStringAsFixed(2)}'),
                      _DetailRow('Discount', '\$${(-sale.discountAmount).toStringAsFixed(2)}'),
                      _DetailRow('Tax', '\$${sale.taxAmount.toStringAsFixed(2)}'),
                      _DetailRow('Total', '\$${sale.totalAmount.toStringAsFixed(2)}'),
                      _DetailRow('Paid', '\$${sale.paidAmount.toStringAsFixed(2)}'),
                      _DetailRow('Due', '\$${sale.dueAmount.toStringAsFixed(2)}'),
                      if (sale.notes != null && sale.notes!.isNotEmpty)
                        _DetailRow('Notes', sale.notes!),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Items', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 16),
                      itemsAsync.when(
                        data: (items) => _ItemsTable(items: items),
                        loading: () => const CircularProgressIndicator(),
                        error: (e, _) => Text('Error: $e'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ItemsTable extends ConsumerWidget {
  const _ItemsTable({required this.items});

  final List<SaleItem> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<Map<int, String>>(
      future: () async {
        final productsRepo = ref.read(productsRepositoryProvider);
        final map = <int, String>{};
        for (final item in items) {
          final p = await productsRepo.getById(item.productId);
          map[item.productId] = p?.name ?? 'Unknown';
        }
        return map;
      }(),
      builder: (context, snap) {
        final names = snap.data ?? {};
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Product')),
              DataColumn(label: Text('Qty'), numeric: true),
              DataColumn(label: Text('Unit Price'), numeric: true),
              DataColumn(label: Text('Discount'), numeric: true),
              DataColumn(label: Text('Tax'), numeric: true),
              DataColumn(label: Text('Total'), numeric: true),
            ],
            rows: items.map((i) => DataRow(
              cells: [
                DataCell(Text(names[i.productId] ?? '...')),
                DataCell(Text(i.quantity.toStringAsFixed(0))),
                DataCell(Text('\$${i.unitPrice.toStringAsFixed(2)}')),
                DataCell(Text('\$${i.itemDiscount.toStringAsFixed(2)}')),
                DataCell(Text('\$${i.itemTax.toStringAsFixed(2)}')),
                DataCell(Text('\$${i.totalAmount.toStringAsFixed(2)}')),
              ],
            )).toList(),
          ),
        );
      },
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
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: value is Widget ? value : Text(value?.toString() ?? '-'),
          ),
        ],
      ),
    );
  }
}
