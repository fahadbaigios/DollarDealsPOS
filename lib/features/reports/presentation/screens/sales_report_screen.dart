import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../database/app_database.dart';
import '../../../products/presentation/widgets/data_table_card.dart';
import '../../../products/presentation/widgets/empty_state.dart';
import '../../../sales/presentation/screens/sale_details_screen.dart';
import '../../../sales/presentation/widgets/payment_status_badge.dart';
import '../providers/reports_providers.dart';
import '../widgets/report_filter_bar.dart';
import '../widgets/report_page_scaffold.dart';
import '../widgets/report_summary_card.dart';

class SalesReportScreen extends ConsumerWidget {
  const SalesReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(reportFilterStateProvider);
    final reportAsync = ref.watch(salesReportProvider);
    final usersAsync = ref.watch(reportUsersProvider);
    final customersAsync = ref.watch(reportCustomersProvider);

    final cashierOptions = usersAsync.valueOrNull
            ?.map((u) => (id: (u as User).id, name: u.fullName))
            .toList() ??
        [];
    final customerOptions = customersAsync.valueOrNull
            ?.map((c) => (id: (c as Customer).id, name: c.name))
            .toList() ??
        [];

    return ReportPageScaffold(
      title: 'Sales Report',
      filterBar: ReportFilterBar(
        filter: filter,
        onFilterChanged: (f) =>
            ref.read(reportFilterStateProvider.notifier).state = f,
        showSearch: true,
        searchHint: 'Search by invoice',
        showCashierFilter: true,
        cashierOptions: cashierOptions,
        showCustomerFilter: true,
        customerOptions: customerOptions,
      ),
      summaryCards: reportAsync.when(
        data: (r) => Wrap(
          spacing: 16,
          runSpacing: 12,
          children: [
            ReportSummaryCard(
              title: 'Total Sales',
              value: '${r.totalCount}',
              icon: Icons.receipt,
              iconColor: Colors.green,
            ),
            ReportSummaryCard(
              title: 'Total Revenue',
              value: NumberFormat.currency(symbol: '\$').format(r.totalRevenue),
              icon: Icons.attach_money,
              iconColor: Colors.green,
            ),
            ReportSummaryCard(
              title: 'Total Discount',
              value: NumberFormat.currency(symbol: '\$').format(r.totalDiscount),
              icon: Icons.discount,
            ),
            ReportSummaryCard(
              title: 'Total Tax',
              value: NumberFormat.currency(symbol: '\$').format(r.totalTax),
              icon: Icons.percent,
            ),
            ReportSummaryCard(
              title: 'Total Due',
              value: NumberFormat.currency(symbol: '\$').format(r.totalDue),
              icon: Icons.pending,
              iconColor: Colors.orange,
            ),
          ],
        ),
        loading: () => const SizedBox(height: 80),
        error: (_, __) => const SizedBox.shrink(),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/reports'),
        ),
      ],
      child: reportAsync.when(
        data: (result) {
          if (result.rows.isEmpty) {
            return const EmptyState(
              message: 'No sales in the selected date range',
              icon: Icons.point_of_sale,
            );
          }
          final currencyFormat = NumberFormat.currency(symbol: '\$');
          final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
          return DataTableCard(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Invoice')),
                    DataColumn(label: Text('Date')),
                    DataColumn(label: Text('Customer')),
                    DataColumn(label: Text('Cashier')),
                    DataColumn(label: Text('Subtotal')),
                    DataColumn(label: Text('Discount')),
                    DataColumn(label: Text('Tax')),
                    DataColumn(label: Text('Total')),
                    DataColumn(label: Text('Paid')),
                    DataColumn(label: Text('Due')),
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('')),
                  ],
                  rows: result.rows.map((r) => DataRow(
                        cells: [
                          DataCell(Text(r.invoiceNumber)),
                          DataCell(Text(dateFormat.format(r.date))),
                          DataCell(Text(r.customerName ?? '—')),
                          DataCell(Text(r.cashierName ?? '—')),
                          DataCell(Text(currencyFormat.format(r.subtotal))),
                          DataCell(Text(currencyFormat.format(r.discount))),
                          DataCell(Text(currencyFormat.format(r.tax))),
                          DataCell(Text(currencyFormat.format(r.total))),
                          DataCell(Text(currencyFormat.format(r.paid))),
                          DataCell(Text(currencyFormat.format(r.due))),
                          DataCell(PaymentStatusBadge(status: r.paymentStatus, compact: true)),
                          DataCell(IconButton(
                            icon: const Icon(Icons.open_in_new, size: 18),
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => SaleDetailsScreen(saleId: r.sale.id),
                              ),
                            ),
                          )),
                        ],
                      )).toList(),
                ),
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
