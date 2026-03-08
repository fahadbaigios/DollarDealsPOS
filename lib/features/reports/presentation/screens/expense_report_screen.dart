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

class ExpenseReportScreen extends ConsumerWidget {
  const ExpenseReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(reportFilterStateProvider);
    final reportAsync = ref.watch(expenseReportProvider);
    final expenseCategoriesAsync = ref.watch(reportExpenseCategoriesProvider);

    final expenseCategoryOptions = expenseCategoriesAsync.valueOrNull
            ?.map((e) => (id: (e as ExpenseCategory).id, name: e.name))
            .toList() ??
        [];

    return ReportPageScaffold(
      title: 'Expense Report',
      filterBar: ReportFilterBar(
        filter: filter,
        onFilterChanged: (f) =>
            ref.read(reportFilterStateProvider.notifier).state = f,
        showSearch: true,
        searchHint: 'Search by title',
        showExpenseCategoryFilter: true,
        expenseCategoryOptions: expenseCategoryOptions,
      ),
      summaryCards: reportAsync.when(
        data: (r) => Wrap(
          spacing: 16,
          runSpacing: 12,
          children: [
            ReportSummaryCard(
              title: 'Total Expenses',
              value: '${r.totalCount}',
              icon: Icons.receipt_long,
              iconColor: Colors.orange,
            ),
            ReportSummaryCard(
              title: 'Total Amount',
              value: NumberFormat.currency(symbol: '\$').format(r.totalAmount),
              icon: Icons.attach_money,
              iconColor: Colors.orange,
            ),
            if (r.largestExpense != null)
              ReportSummaryCard(
                title: 'Largest Expense',
                value: NumberFormat.currency(symbol: '\$').format(r.largestExpense!),
                icon: Icons.trending_up,
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
              message: 'No expenses in the selected date range',
              icon: Icons.receipt_long,
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
                    DataColumn(label: Text('Date')),
                    DataColumn(label: Text('Title')),
                    DataColumn(label: Text('Category')),
                    DataColumn(label: Text('Amount')),
                    DataColumn(label: Text('Payment Method')),
                    DataColumn(label: Text('Reference')),
                  ],
                  rows: result.rows.map((r) => DataRow(
                        cells: [
                          DataCell(Text(dateFormat.format(r.date))),
                          DataCell(Text(r.title)),
                          DataCell(Text(r.categoryName)),
                          DataCell(Text(currencyFormat.format(r.amount))),
                          DataCell(Text(r.paymentMethodName ?? '—')),
                          DataCell(Text(r.referenceNumber ?? '—')),
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
