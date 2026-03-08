import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../database/app_database.dart';
import '../../../products/presentation/widgets/data_table_card.dart';
import '../../../products/presentation/widgets/empty_state.dart';
import '../../../purchases/presentation/screens/purchase_details_screen.dart';
import '../../../sales/presentation/widgets/payment_status_badge.dart';
import '../providers/reports_providers.dart';
import '../widgets/report_filter_bar.dart';
import '../widgets/report_page_scaffold.dart';
import '../widgets/report_summary_card.dart';

class PurchaseReportScreen extends ConsumerWidget {
  const PurchaseReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(reportFilterStateProvider);
    final reportAsync = ref.watch(purchaseReportProvider);
    final suppliersAsync = ref.watch(reportSuppliersProvider);

    final supplierOptions = suppliersAsync.valueOrNull
            ?.map((s) => (id: (s as Supplier).id, name: s.name))
            .toList() ??
        [];

    return ReportPageScaffold(
      title: 'Purchase Report',
      filterBar: ReportFilterBar(
        filter: filter,
        onFilterChanged: (f) =>
            ref.read(reportFilterStateProvider.notifier).state = f,
        showSearch: true,
        searchHint: 'Search by invoice or notes',
        showSupplierFilter: true,
        supplierOptions: supplierOptions,
      ),
      summaryCards: reportAsync.when(
        data: (r) => Wrap(
          spacing: 16,
          runSpacing: 12,
          children: [
            ReportSummaryCard(
              title: 'Total Purchases',
              value: '${r.totalCount}',
              icon: Icons.shopping_cart,
              iconColor: Colors.blue,
            ),
            ReportSummaryCard(
              title: 'Total Value',
              value: NumberFormat.currency(symbol: '\$').format(r.totalValue),
              icon: Icons.attach_money,
              iconColor: Colors.blue,
            ),
            ReportSummaryCard(
              title: 'Total Paid',
              value: NumberFormat.currency(symbol: '\$').format(r.totalPaid),
              icon: Icons.check_circle,
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
              message: 'No purchases in the selected date range',
              icon: Icons.shopping_cart,
            );
          }
          final currencyFormat = NumberFormat.currency(symbol: '\$');
          final dateFormat = DateFormat('yyyy-MM-dd');
          return DataTableCard(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Invoice')),
                    DataColumn(label: Text('Date')),
                    DataColumn(label: Text('Supplier')),
                    DataColumn(label: Text('Subtotal')),
                    DataColumn(label: Text('Discount')),
                    DataColumn(label: Text('Tax')),
                    DataColumn(label: Text('Total')),
                    DataColumn(label: Text('Paid')),
                    DataColumn(label: Text('Due')),
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('Created By')),
                    DataColumn(label: Text('')),
                  ],
                  rows: result.rows.map((r) => DataRow(
                        cells: [
                          DataCell(Text(r.invoiceNumber ?? '—')),
                          DataCell(Text(dateFormat.format(r.date))),
                          DataCell(Text(r.supplierName ?? '—')),
                          DataCell(Text(currencyFormat.format(r.subtotal))),
                          DataCell(Text(currencyFormat.format(r.discount))),
                          DataCell(Text(currencyFormat.format(r.tax))),
                          DataCell(Text(currencyFormat.format(r.total))),
                          DataCell(Text(currencyFormat.format(r.paid))),
                          DataCell(Text(currencyFormat.format(r.due))),
                          DataCell(PaymentStatusBadge(status: r.paymentStatus, compact: true)),
                          DataCell(Text(r.createdByName ?? '—')),
                          DataCell(IconButton(
                            icon: const Icon(Icons.open_in_new, size: 18),
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    PurchaseDetailsScreen(purchaseId: r.purchase.id),
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
