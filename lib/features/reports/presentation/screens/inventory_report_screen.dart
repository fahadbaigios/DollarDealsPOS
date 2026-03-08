import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../database/app_database.dart';
import '../../../products/presentation/widgets/data_table_card.dart';
import '../../../products/presentation/widgets/empty_state.dart';
import '../providers/reports_providers.dart';
import '../widgets/report_filter_bar.dart';
import '../widgets/report_page_scaffold.dart';
import '../widgets/report_summary_card.dart';

class InventoryReportScreen extends ConsumerWidget {
  const InventoryReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(reportFilterStateProvider);
    final reportAsync = ref.watch(inventoryReportProvider);
    final categoriesAsync = ref.watch(reportCategoriesProvider);

    final categoryOptions = categoriesAsync.valueOrNull
            ?.map((c) => (id: (c as Category).id, name: c.name))
            .toList() ??
        [];

    return ReportPageScaffold(
      title: 'Inventory Report',
      filterBar: ReportFilterBar(
        filter: filter,
        onFilterChanged: (f) =>
            ref.read(reportFilterStateProvider.notifier).state = f,
        showSearch: true,
        searchHint: 'Search by name, SKU, barcode',
        showCategoryFilter: true,
        categoryOptions: categoryOptions,
      ),
      summaryCards: reportAsync.when(
        data: (r) => Wrap(
          spacing: 16,
          runSpacing: 12,
          children: [
            ReportSummaryCard(
              title: 'Total Products',
              value: '${r.totalProducts}',
              icon: Icons.inventory_2,
              iconColor: Colors.indigo,
            ),
            ReportSummaryCard(
              title: 'Total Stock Qty',
              value: r.totalStockQuantity.toStringAsFixed(1),
              icon: Icons.numbers,
            ),
            ReportSummaryCard(
              title: 'Stock Value (Cost)',
              value: NumberFormat.currency(symbol: '\$').format(r.totalStockValueAtCost),
              icon: Icons.account_balance_wallet,
            ),
            ReportSummaryCard(
              title: 'Stock Value (Selling)',
              value: NumberFormat.currency(symbol: '\$').format(r.totalStockValueAtSelling),
              icon: Icons.trending_up,
            ),
            ReportSummaryCard(
              title: 'Low Stock',
              value: '${r.lowStockCount}',
              icon: Icons.warning_amber,
              iconColor: Colors.amber,
            ),
            ReportSummaryCard(
              title: 'Out of Stock',
              value: '${r.outOfStockCount}',
              icon: Icons.remove_shopping_cart,
              iconColor: Colors.red,
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
              message: 'No products match the filters',
              icon: Icons.inventory_2,
            );
          }
          final currencyFormat = NumberFormat.currency(symbol: '\$');
          return DataTableCard(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Product')),
                    DataColumn(label: Text('SKU')),
                    DataColumn(label: Text('Barcode')),
                    DataColumn(label: Text('Category')),
                    DataColumn(label: Text('Supplier')),
                    DataColumn(label: Text('Unit')),
                    DataColumn(label: Text('Stock')),
                    DataColumn(label: Text('Reorder')),
                    DataColumn(label: Text('Cost')),
                    DataColumn(label: Text('Price')),
                    DataColumn(label: Text('Value (Cost)')),
                    DataColumn(label: Text('Value (Selling)')),
                    DataColumn(label: Text('Status')),
                  ],
                  rows: result.rows.map((r) => DataRow(
                        cells: [
                          DataCell(Text(r.name)),
                          DataCell(Text(r.sku)),
                          DataCell(Text(r.barcode ?? '—')),
                          DataCell(Text(r.categoryName)),
                          DataCell(Text(r.supplierName ?? '—')),
                          DataCell(Text(r.unitName)),
                          DataCell(Text(r.stockQuantity.toStringAsFixed(1))),
                          DataCell(Text(r.reorderLevel.toStringAsFixed(1))),
                          DataCell(Text(currencyFormat.format(r.costPrice))),
                          DataCell(Text(currencyFormat.format(r.salePrice))),
                          DataCell(Text(currencyFormat.format(r.stockValueAtCost))),
                          DataCell(Text(currencyFormat.format(r.stockValueAtSelling))),
                          DataCell(Text(r.stockStatus)),
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
