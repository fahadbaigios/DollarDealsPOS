import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../database/app_database.dart';
import '../providers/sales_providers.dart';
import '../widgets/payment_status_badge.dart';
import 'sale_details_screen.dart';

class SalesHistoryScreen extends ConsumerWidget {
  const SalesHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salesAsync = ref.watch(salesStreamProvider);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Sales History',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              SizedBox(
                width: 240,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search by invoice',
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (v) =>
                      ref.read(salesHistorySearchQueryProvider.notifier).state = v,
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  final from = await showDatePicker(
                    context: context,
                    initialDate: ref.read(salesHistoryDateFromProvider) ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (from != null) {
                    ref.read(salesHistoryDateFromProvider.notifier).state = from;
                  }
                },
                icon: const Icon(Icons.calendar_today, size: 18),
                label: Text(
                  ref.watch(salesHistoryDateFromProvider) != null
                      ? '${ref.watch(salesHistoryDateFromProvider)!.year}-${ref.watch(salesHistoryDateFromProvider)!.month.toString().padLeft(2, '0')}-${ref.watch(salesHistoryDateFromProvider)!.day.toString().padLeft(2, '0')}'
                      : 'From',
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () async {
                  final to = await showDatePicker(
                    context: context,
                    initialDate: ref.watch(salesHistoryDateToProvider) ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (to != null) {
                    ref.read(salesHistoryDateToProvider.notifier).state = to;
                  }
                },
                icon: const Icon(Icons.calendar_today, size: 18),
                label: Text(
                  ref.watch(salesHistoryDateToProvider) != null
                      ? '${ref.watch(salesHistoryDateToProvider)!.year}-${ref.watch(salesHistoryDateToProvider)!.month.toString().padLeft(2, '0')}-${ref.watch(salesHistoryDateToProvider)!.day.toString().padLeft(2, '0')}'
                      : 'To',
                ),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () {
                  ref.read(salesHistorySearchQueryProvider.notifier).state = '';
                  ref.read(salesHistoryDateFromProvider.notifier).state = null;
                  ref.read(salesHistoryDateToProvider.notifier).state = null;
                },
                icon: const Icon(Icons.clear),
                label: const Text('Clear'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: salesAsync.when(
              data: (sales) => _SalesTable(sales: sales),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }
}

class _SalesTable extends ConsumerWidget {
  const _SalesTable({required this.sales});

  final List<Sale> sales;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (sales.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text('No sales found', style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      );
    }

    return FutureBuilder<({Map<int, String> customerNames, Map<int, String> cashierNames})>(
      future: () async {
        final customersRepo = ref.read(customersRepositoryProvider);
        final usersRepo = ref.read(usersRepositoryProvider);
        final customerNames = <int, String>{};
        final cashierNames = <int, String>{};
        for (final s in sales) {
          if (s.customerId != null) {
            final c = await customersRepo.getById(s.customerId!);
            customerNames[s.id] = c?.name ?? '-';
          } else {
            customerNames[s.id] = 'Walk-in';
          }
          final u = await usersRepo.getById(s.cashierId);
          cashierNames[s.id] = u?.fullName ?? '-';
        }
        return (customerNames: customerNames, cashierNames: cashierNames);
      }(),
      builder: (context, snap) {
        final customerNames = snap.data?.customerNames ?? {};
        final cashierNames = snap.data?.cashierNames ?? {};

        return Card(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Invoice')),
                  DataColumn(label: Text('Date')),
                  DataColumn(label: Text('Customer')),
                  DataColumn(label: Text('Cashier')),
                  DataColumn(label: Text('Total'), numeric: true),
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('Action')),
                ],
                rows: sales.map((s) => DataRow(
                  cells: [
                    DataCell(Text(s.invoiceNumber)),
                    DataCell(Text(_formatDate(s.saleDate))),
                    DataCell(Text(customerNames[s.id] ?? '...')),
                    DataCell(Text(cashierNames[s.id] ?? '...')),
                    DataCell(Text('\$${s.totalAmount.toStringAsFixed(2)}')),
                    DataCell(PaymentStatusBadge(status: s.paymentStatus, compact: true)),
                    DataCell(
                      TextButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (ctx) => SaleDetailsScreen(saleId: s.id),
                          ),
                        ),
                        child: const Text('View'),
                      ),
                    ),
                  ],
                )).toList(),
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }
}
