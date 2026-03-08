import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../database/app_database.dart';
import '../../../products/presentation/widgets/data_table_card.dart';
import '../../../products/presentation/widgets/empty_state.dart';
import '../providers/reports_providers.dart';
import '../widgets/report_filter_bar.dart';
import '../widgets/report_page_scaffold.dart';
import '../widgets/report_summary_card.dart';

class LowStockReportScreen extends ConsumerWidget {
  const LowStockReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(reportFilterStateProvider);
    final reportAsync = ref.watch(lowStockReportProvider);
    final categoriesAsync = ref.watch(reportCategoriesProvider);

    final categoryOptions = categoriesAsync.valueOrNull
            ?.map((c) => (id: (c as Category).id, name: c.name))
            .toList() ??
        [];

    final lowStockCount = reportAsync.valueOrNull
        ?.where((r) =>
            r.product.stockQuantity > 0 &&
            r.product.reorderLevel > 0 &&
            r.product.stockQuantity <= r.product.reorderLevel)
        .length ??
        0;
    final outOfStockCount =
        reportAsync.valueOrNull?.where((r) => r.product.stockQuantity <= 0).length ?? 0;

    return ReportPageScaffold(
      title: 'Low Stock Report',
      filterBar: ReportFilterBar(
        filter: filter,
        onFilterChanged: (f) =>
            ref.read(reportFilterStateProvider.notifier).state = f,
        showSearch: true,
        searchHint: 'Search by name, SKU',
        showCategoryFilter: true,
        categoryOptions: categoryOptions,
      ),
      summaryCards: reportAsync.when(
        data: (_) => Wrap(
          spacing: 16,
          runSpacing: 12,
          children: [
            ReportSummaryCard(
              title: 'Low Stock Count',
              value: '$lowStockCount',
              icon: Icons.warning_amber,
              iconColor: Colors.amber,
            ),
            ReportSummaryCard(
              title: 'Out of Stock Count',
              value: '$outOfStockCount',
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
        data: (rows) {
          if (rows.isEmpty) {
            return const EmptyState(
              message: 'All products are well stocked',
              icon: Icons.check_circle_outline,
            );
          }
          return DataTableCard(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Product')),
                    DataColumn(label: Text('SKU')),
                    DataColumn(label: Text('Category')),
                    DataColumn(label: Text('Supplier')),
                    DataColumn(label: Text('Current Stock')),
                    DataColumn(label: Text('Reorder Level')),
                    DataColumn(label: Text('Status')),
                  ],
                  rows: rows.map((r) => DataRow(
                        cells: [
                          DataCell(Text(r.name)),
                          DataCell(Text(r.sku)),
                          DataCell(Text(r.categoryName)),
                          DataCell(Text(r.supplierName ?? '—')),
                          DataCell(Text(r.stockQuantity.toStringAsFixed(1))),
                          DataCell(Text(r.reorderLevel.toStringAsFixed(1))),
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
