import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/sales_history_page_result.dart';
import '../providers/sales_providers.dart';
import '../widgets/payment_status_badge.dart';
import 'sale_details_screen.dart';

class SalesHistoryScreen extends ConsumerWidget {
  const SalesHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageAsync = ref.watch(salesHistoryPaginatedProvider);

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
                  decoration: const InputDecoration(
                    hintText: 'Search by invoice',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (v) {
                    ref.read(salesHistorySearchQueryProvider.notifier).state = v;
                    resetSalesHistoryPage(ref);
                  },
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  final from = await showDatePicker(
                    context: context,
                    initialDate:
                        ref.read(salesHistoryDateFromProvider) ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (from != null) {
                    ref.read(salesHistoryDateFromProvider.notifier).state = from;
                    resetSalesHistoryPage(ref);
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
                    initialDate:
                        ref.watch(salesHistoryDateToProvider) ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (to != null) {
                    ref.read(salesHistoryDateToProvider.notifier).state = to;
                    resetSalesHistoryPage(ref);
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
                onPressed: () => resetSalesHistoryToToday(ref),
                icon: const Icon(Icons.clear),
                label: const Text('Today'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: pageAsync.when(
              data: (page) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _SalesTable(page: page),
                  ),
                  if (page.totalCount > 0) _PaginationBar(page: page),
                ],
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

class _PaginationBar extends ConsumerWidget {
  const _PaginationBar({required this.page});

  final SalesHistoryPageResult page;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          Text(
            'Showing ${page.rangeStart}-${page.rangeEnd} of ${page.totalCount}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          Text(
            'Page ${page.page + 1} of ${page.totalPages}',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: page.hasPreviousPage
                ? () => ref.read(salesHistoryPageProvider.notifier).state =
                    page.page - 1
                : null,
            icon: const Icon(Icons.chevron_left),
            label: const Text('Previous'),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: page.hasNextPage
                ? () => ref.read(salesHistoryPageProvider.notifier).state =
                    page.page + 1
                : null,
            icon: const Icon(Icons.chevron_right),
            label: const Text('Next'),
          ),
        ],
      ),
    );
  }
}

class _SalesTable extends StatelessWidget {
  const _SalesTable({required this.page});

  final SalesHistoryPageResult page;

  @override
  Widget build(BuildContext context) {
    final sales = page.sales;
    if (sales.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text('No sales found', style: TextStyle(color: Colors.grey.shade600)),
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
              DataColumn(label: Text('Invoice')),
              DataColumn(label: Text('Date')),
              DataColumn(label: Text('Customer')),
              DataColumn(label: Text('Cashier')),
              DataColumn(label: Text('Total'), numeric: true),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Action')),
            ],
            rows: sales.map((s) {
              return DataRow(
                cells: [
                  DataCell(Text(s.invoiceNumber)),
                  DataCell(Text(_formatDate(s.saleDate))),
                  DataCell(Text(page.customerNamesBySaleId[s.id] ?? '-')),
                  DataCell(Text(page.cashierNamesBySaleId[s.id] ?? '-')),
                  DataCell(Text('\$${s.totalAmount.toStringAsFixed(2)}')),
                  DataCell(
                      PaymentStatusBadge(status: s.paymentStatus, compact: true)),
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
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }
}
