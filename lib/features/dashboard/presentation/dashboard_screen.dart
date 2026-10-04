import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/route_names.dart';
import '../../products/presentation/widgets/data_table_card.dart';
import '../../products/presentation/widgets/empty_state.dart';
import '../../expenses/presentation/providers/expenses_providers.dart';
import '../../sales/presentation/screens/sale_details_screen.dart';
import '../../settings/presentation/providers/settings_providers.dart';
import '../../expenses/presentation/dialogs/expense_form_dialog.dart';
import 'providers/dashboard_providers.dart';
import 'widgets/summary_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Dashboard',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              FilledButton.icon(
                onPressed: () => showExpenseFormDialog(context),
                icon: const Icon(Icons.add, size: 20),
                label: const Text('Add Expense'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SummaryCardsGrid(),
          const SizedBox(height: 24),
          const _TodaySalesByPaymentMethodSection(),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: _RecentSalesSection()),
              const SizedBox(width: 24),
              Expanded(flex: 2, child: _LowStockSection()),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: _RecentExpensesSection()),
              const SizedBox(width: 24),
              Expanded(flex: 2, child: _TopSellingSection()),
            ],
          ),
        ],
      ),
    );
  }
}

class _TodaySalesByPaymentMethodSection extends ConsumerWidget {
  const _TodaySalesByPaymentMethodSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salesAsync = ref.watch(todaySalesByPaymentMethodProvider);
    final currencySymbol =
        ref
            .watch(businessProfileSettingsProvider)
            .valueOrNull
            ?.currencySymbol ??
        'PKR ';
    final currencyFormat = NumberFormat.currency(symbol: currencySymbol);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          "Today's Sales by Payment Method",
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        salesAsync.when(
          data: (summaries) {
            if (summaries.isEmpty) {
              return const Text('No payment methods configured.');
            }
            return LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth >= 1100
                    ? (constraints.maxWidth - 48) / 4
                    : constraints.maxWidth >= 700
                    ? (constraints.maxWidth - 16) / 2
                    : constraints.maxWidth;
                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: summaries
                      .map(
                        (summary) => SizedBox(
                          width: width,
                          height: 118,
                          child: SummaryCard(
                            title: '${summary.paymentMethodName} Sales',
                            value: currencyFormat.format(summary.total),
                            subtitle:
                                '${summary.saleCount} ${summary.saleCount == 1 ? 'order' : 'orders'} today',
                            icon: _paymentMethodIcon(summary.paymentMethodName),
                            iconColor: _paymentMethodColor(
                              context,
                              summary.paymentMethodName,
                            ),
                            routePath: RouteNames.salesHistoryPath,
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            );
          },
          loading: () => const SizedBox(
            height: 118,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => Text('Unable to load payment totals: $error'),
        ),
      ],
    );
  }

  IconData _paymentMethodIcon(String name) {
    final normalized = name.toLowerCase();
    if (normalized.contains('cash') && !normalized.contains('jazz')) {
      return Icons.payments_outlined;
    }
    if (normalized.contains('card')) return Icons.credit_card;
    if (normalized.contains('bank')) return Icons.account_balance_outlined;
    if (normalized.contains('jazz') ||
        normalized.contains('easypaisa') ||
        normalized.contains('wallet')) {
      return Icons.phone_android;
    }
    return Icons.payment;
  }

  Color _paymentMethodColor(BuildContext context, String name) {
    final normalized = name.toLowerCase();
    if (normalized.contains('cash') && !normalized.contains('jazz')) {
      return Colors.green;
    }
    if (normalized.contains('card')) return Colors.blue;
    if (normalized.contains('bank')) return Colors.indigo;
    if (normalized.contains('jazz')) return Colors.red;
    return Theme.of(context).colorScheme.primary;
  }
}

class _SummaryCardsGrid extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayPlAsync = ref.watch(todayProfitLossProvider);
    final monthlyPlAsync = ref.watch(monthlyProfitLossProvider);
    final lowStockAsync = ref.watch(lowStockCountProvider);
    final outOfStockAsync = ref.watch(outOfStockCountProvider);
    final totalProductsAsync = ref.watch(totalProductsCountProvider);
    final todayExpensesAsync = ref.watch(todayExpensesTotalProvider);

    final currencyFormat = NumberFormat.currency(symbol: 'PKR ');

    return todayPlAsync.when(
      data: (todayPl) {
        return monthlyPlAsync.when(
          data: (monthlyPl) {
            return lowStockAsync.when(
              data: (lowStock) {
                return outOfStockAsync.when(
                  data: (outOfStock) {
                    return totalProductsAsync.when(
                      data: (totalProducts) {
                        return todayExpensesAsync.when(
                          data: (todayExpenses) {
                            return LayoutBuilder(
                              builder: (context, constraints) {
                                final crossAxisCount =
                                    constraints.maxWidth > 1200 ? 4 : 2;
                                return GridView.count(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  crossAxisCount: crossAxisCount,
                                  mainAxisSpacing: 16,
                                  crossAxisSpacing: 16,
                                  childAspectRatio: 1.8,
                                  children: [
                                    SummaryCard(
                                      title: 'Today Sales',
                                      value: currencyFormat.format(
                                        todayPl.revenue,
                                      ),
                                      icon: Icons.point_of_sale,
                                      iconColor: Colors.green,
                                      routePath: RouteNames.salesHistoryPath,
                                    ),
                                    SummaryCard(
                                      title: 'Today Profit',
                                      value: currencyFormat.format(
                                        todayPl.netProfit,
                                      ),
                                      subtitle:
                                          'Gross: ${currencyFormat.format(todayPl.grossProfit)}',
                                      icon: Icons.trending_up,
                                      iconColor: todayPl.netProfit >= 0
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                    SummaryCard(
                                      title: 'Monthly Sales',
                                      value: currencyFormat.format(
                                        monthlyPl.revenue,
                                      ),
                                      icon: Icons.calendar_month,
                                      iconColor: Colors.blue,
                                      routePath: RouteNames.salesHistoryPath,
                                    ),
                                    SummaryCard(
                                      title: 'Monthly Profit',
                                      value: currencyFormat.format(
                                        monthlyPl.netProfit,
                                      ),
                                      subtitle:
                                          'Gross: ${currencyFormat.format(monthlyPl.grossProfit)}',
                                      icon: Icons.account_balance_wallet,
                                      iconColor: monthlyPl.netProfit >= 0
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                    SummaryCard(
                                      title: 'Today Expenses',
                                      value: currencyFormat.format(
                                        todayExpenses,
                                      ),
                                      icon: Icons.receipt_long,
                                      iconColor: Colors.orange,
                                      routePath: RouteNames.expensesPath,
                                    ),
                                    SummaryCard(
                                      title: 'Low Stock',
                                      value: '$lowStock',
                                      icon: Icons.warning_amber,
                                      iconColor: Colors.amber,
                                      routePath: RouteNames.inventoryPath,
                                    ),
                                    SummaryCard(
                                      title: 'Total Products',
                                      value: '$totalProducts',
                                      icon: Icons.inventory_2,
                                      iconColor: Colors.indigo,
                                      routePath: RouteNames.productsPath,
                                    ),
                                    SummaryCard(
                                      title: 'Out of Stock',
                                      value: '$outOfStock',
                                      icon: Icons.remove_shopping_cart,
                                      iconColor: Colors.red,
                                      routePath: RouteNames.inventoryPath,
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                          loading: () => _gridPlaceholder(context),
                          error: (_, __) => _gridPlaceholder(context),
                        );
                      },
                      loading: () => _gridPlaceholder(context),
                      error: (_, __) => _gridPlaceholder(context),
                    );
                  },
                  loading: () => _gridPlaceholder(context),
                  error: (_, __) => _gridPlaceholder(context),
                );
              },
              loading: () => _gridPlaceholder(context),
              error: (_, __) => _gridPlaceholder(context),
            );
          },
          loading: () => _gridPlaceholder(context),
          error: (_, __) => _gridPlaceholder(context),
        );
      },
      loading: () => _gridPlaceholder(context),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Widget _gridPlaceholder(BuildContext context) {
    return SizedBox(
      height: 120,
      child: Center(
        child: CircularProgressIndicator(
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

class _RecentSalesSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(recentSalesProvider);
    final currencyFormat = NumberFormat.currency(symbol: 'PKR ');
    final dateFormat = DateFormat('MMM d, HH:mm');

    return DataTableCard(
      child: async.when(
        data: (sales) {
          if (sales.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(24),
              child: EmptyState(
                message: 'No recent sales',
                icon: Icons.shopping_cart_outlined,
              ),
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text(
                      'Recent Sales',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => context.go(RouteNames.salesHistoryPath),
                      child: const Text('View all'),
                    ),
                  ],
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Invoice')),
                    DataColumn(label: Text('Date')),
                    DataColumn(label: Text('Amount')),
                    DataColumn(label: Text('')),
                  ],
                  rows: sales.take(5).map((s) {
                    return DataRow(
                      cells: [
                        DataCell(Text(s.invoiceNumber)),
                        DataCell(Text(dateFormat.format(s.saleDate))),
                        DataCell(Text(currencyFormat.format(s.totalAmount))),
                        DataCell(
                          IconButton(
                            icon: const Icon(Icons.arrow_forward, size: 18),
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => SaleDetailsScreen(saleId: s.id),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: CircularProgressIndicator(),
          ),
        ),
        error: (e, _) => Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Error: $e'),
        ),
      ),
    );
  }
}

class _LowStockSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(lowStockProductsProvider);

    return DataTableCard(
      child: async.when(
        data: (products) {
          if (products.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(24),
              child: EmptyState(
                message: 'All products are well stocked',
                icon: Icons.check_circle_outline,
              ),
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text(
                      'Low Stock Products',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => context.go(RouteNames.inventoryPath),
                      child: const Text('View all'),
                    ),
                  ],
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Product')),
                    DataColumn(label: Text('SKU')),
                    DataColumn(label: Text('Stock')),
                    DataColumn(label: Text('Reorder')),
                  ],
                  rows: products.take(5).map((p) {
                    return DataRow(
                      cells: [
                        DataCell(Text(p.name)),
                        DataCell(Text(p.sku)),
                        DataCell(Text(p.stockQuantity.toStringAsFixed(1))),
                        DataCell(Text(p.reorderLevel.toStringAsFixed(1))),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: CircularProgressIndicator(),
          ),
        ),
        error: (e, _) => Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Error: $e'),
        ),
      ),
    );
  }
}

class _RecentExpensesSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(recentExpensesProvider);
    final categoriesAsync = ref.watch(expenseCategoriesStreamProvider);
    final currencyFormat = NumberFormat.currency(symbol: 'PKR ');
    final dateFormat = DateFormat('MMM d');

    return DataTableCard(
      child: async.when(
        data: (expenses) {
          final categories = categoriesAsync.valueOrNull ?? [];
          final catMap = {for (final c in categories) c.id: c.name};
          if (expenses.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(24),
              child: EmptyState(
                message: 'No recent expenses',
                icon: Icons.receipt_long_outlined,
              ),
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text(
                      'Recent Expenses',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => context.go(RouteNames.expensesPath),
                      child: const Text('View all'),
                    ),
                  ],
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Title')),
                    DataColumn(label: Text('Category')),
                    DataColumn(label: Text('Date')),
                    DataColumn(label: Text('Amount')),
                  ],
                  rows: expenses.take(5).map((e) {
                    return DataRow(
                      cells: [
                        DataCell(Text(e.title)),
                        DataCell(Text(catMap[e.expenseCategoryId] ?? '—')),
                        DataCell(Text(dateFormat.format(e.expenseDate))),
                        DataCell(Text(currencyFormat.format(e.amount))),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: CircularProgressIndicator(),
          ),
        ),
        error: (e, _) => Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Error: $e'),
        ),
      ),
    );
  }
}

class _TopSellingSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(topSellingProductsProvider);
    final currencyFormat = NumberFormat.currency(symbol: 'PKR ');

    return DataTableCard(
      child: async.when(
        data: (products) {
          if (products.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(24),
              child: EmptyState(
                message: 'No sales this month',
                icon: Icons.bar_chart_outlined,
              ),
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Top Selling (This Month)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Product')),
                    DataColumn(label: Text('Qty')),
                    DataColumn(label: Text('Revenue')),
                  ],
                  rows: products.take(5).map((p) {
                    return DataRow(
                      cells: [
                        DataCell(Text(p.name)),
                        DataCell(Text(p.quantity.toStringAsFixed(1))),
                        DataCell(Text(currencyFormat.format(p.revenue))),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: CircularProgressIndicator(),
          ),
        ),
        error: (e, _) => Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Error: $e'),
        ),
      ),
    );
  }
}
