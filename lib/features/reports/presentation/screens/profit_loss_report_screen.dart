import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../products/presentation/widgets/data_table_card.dart';
import '../../../products/presentation/widgets/empty_state.dart';
import '../providers/reports_providers.dart';
import '../widgets/report_filter_bar.dart';
import '../widgets/report_page_scaffold.dart';
import '../widgets/report_summary_card.dart';

class ProfitLossReportScreen extends ConsumerWidget {
  const ProfitLossReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(reportFilterStateProvider);
    final reportAsync = ref.watch(profitLossReportProvider);
    final currencyFormat = NumberFormat.currency(symbol: '\$');

    return ReportPageScaffold(
      title: 'Profit/Loss Report',
      filterBar: ReportFilterBar(
        filter: filter,
        onFilterChanged: (f) =>
            ref.read(reportFilterStateProvider.notifier).state = f,
        showSearch: false,
      ),
      summaryCards: reportAsync.when(
        data: (r) {
          final s = r.summary;
          return Wrap(
            spacing: 16,
            runSpacing: 12,
            children: [
              ReportSummaryCard(
                title: 'Revenue',
                value: currencyFormat.format(s.revenue),
                icon: Icons.trending_up,
                iconColor: Colors.green,
              ),
              ReportSummaryCard(
                title: 'COGS',
                value: currencyFormat.format(s.cogs),
                icon: Icons.inventory,
              ),
              ReportSummaryCard(
                title: 'Gross Profit',
                value: currencyFormat.format(s.grossProfit),
                icon: Icons.account_balance,
                iconColor: s.grossProfit >= 0 ? Colors.green : Colors.red,
              ),
              ReportSummaryCard(
                title: 'Expenses',
                value: currencyFormat.format(s.expenses),
                icon: Icons.receipt_long,
                iconColor: Colors.orange,
              ),
              ReportSummaryCard(
                title: 'Net Profit',
                value: currencyFormat.format(s.netProfit),
                icon: Icons.account_balance_wallet,
                iconColor: s.netProfit >= 0 ? Colors.green : Colors.red,
              ),
            ],
          );
        },
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
          final hasDetails = result.topSellingProducts.isNotEmpty ||
              result.expenseByCategory.isNotEmpty;
          if (!hasDetails) {
            return const EmptyState(
              message: 'No detailed data in the selected date range',
              icon: Icons.account_balance_wallet,
            );
          }
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (result.topSellingProducts.isNotEmpty) ...[
                  Text(
                    'Top Selling Products',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 12),
                  DataTableCard(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Product')),
                          DataColumn(label: Text('Quantity')),
                          DataColumn(label: Text('Revenue')),
                        ],
                        rows: result.topSellingProducts.map((p) => DataRow(
                              cells: [
                                DataCell(Text(p.name)),
                                DataCell(Text(p.quantity.toStringAsFixed(1))),
                                DataCell(Text(currencyFormat.format(p.revenue))),
                              ],
                            )).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                if (result.expenseByCategory.isNotEmpty) ...[
                  Text(
                    'Expenses by Category',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 12),
                  DataTableCard(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Category')),
                          DataColumn(label: Text('Amount')),
                        ],
                        rows: result.expenseByCategory.entries.map((e) => DataRow(
                              cells: [
                                DataCell(Text(e.key)),
                                DataCell(Text(currencyFormat.format(e.value))),
                              ],
                            )).toList(),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
