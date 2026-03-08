import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../database/app_database.dart';
import '../../products/presentation/widgets/confirm_dialog.dart';
import '../../products/presentation/widgets/data_table_card.dart';
import '../../products/presentation/widgets/empty_state.dart';
import '../../products/presentation/widgets/page_header.dart';
import '../../products/presentation/widgets/search_field.dart';
import 'dialogs/expense_category_form_dialog.dart';
import 'dialogs/expense_form_dialog.dart';
import 'providers/expenses_providers.dart';

class ExpensesScreen extends ConsumerStatefulWidget {
  const ExpensesScreen({super.key});

  @override
  ConsumerState<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends ConsumerState<ExpensesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          title: 'Expenses',
          actions: [
            if (_tabController.index == 0) ...[
              SearchField(
                controller: _searchController,
                hintText: 'Search by title...',
                onChanged: (v) =>
                    ref.read(expensesSearchQueryProvider.notifier).state = v,
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: () async {
                  await showExpenseFormDialog(context);
                },
                icon: const Icon(Icons.add, size: 20),
                label: const Text('Add Expense'),
              ),
            ] else
              FilledButton.icon(
                onPressed: () async {
                  await showExpenseCategoryFormDialog(context);
                },
                icon: const Icon(Icons.add, size: 20),
                label: const Text('Add Category'),
              ),
          ],
        ),
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Expenses'),
            Tab(text: 'Categories'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _ExpensesTab(
                onAddExpense: () => showExpenseFormDialog(context),
              ),
              const _ExpenseCategoriesTab(),
            ],
          ),
        ),
      ],
    );
  }
}

class _ExpensesTab extends ConsumerWidget {
  const _ExpensesTab({required this.onAddExpense});

  final VoidCallback onAddExpense;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expensesStreamProvider);
    final categoriesAsync = ref.watch(expenseCategoriesStreamProvider);
    final paymentMethodsAsync = ref.watch(expensePaymentMethodsProvider);

    return expensesAsync.when(
      data: (expenses) => _ExpensesList(
        expenses: expenses,
        categories: categoriesAsync.valueOrNull ?? [],
        paymentMethods: paymentMethodsAsync.valueOrNull ?? [],
        onAddExpense: onAddExpense,
        onEdit: (e) => showExpenseFormDialog(context, existing: e),
        onDelete: (e) => _confirmDelete(context, ref, e),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, Expense expense) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Delete Expense',
      message:
          'Delete "${expense.title}" (${NumberFormat.currency(symbol: '\$').format(expense.amount)})?',
      confirmText: 'Delete',
      isDanger: true,
    );
    if (!ok || !context.mounted) return;
    final repo = ref.read(expensesRepositoryProvider);
    await repo.delete(expense.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Expense deleted')),
      );
    }
  }
}

class _ExpensesList extends StatelessWidget {
  const _ExpensesList({
    required this.expenses,
    required this.categories,
    required this.paymentMethods,
    required this.onAddExpense,
    required this.onEdit,
    required this.onDelete,
  });

  final List<Expense> expenses;
  final List<ExpenseCategory> categories;
  final List<PaymentMethod> paymentMethods;
  final VoidCallback onAddExpense;
  final void Function(Expense) onEdit;
  final void Function(Expense) onDelete;

  @override
  Widget build(BuildContext context) {
    if (expenses.isEmpty) {
      return EmptyState(
        message: 'No expenses yet. Add one to get started.',
        icon: Icons.receipt_long_outlined,
      );
    }

    final catMap = {for (final c in categories) c.id: c.name};
    final pmMap = {for (final p in paymentMethods) p.id: p.name};
    final dateFormat = DateFormat('yyyy-MM-dd');
    final currencyFormat = NumberFormat.currency(symbol: '\$');

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ExpensesFilters(),
          const SizedBox(height: 16),
          Expanded(
            child: DataTableCard(
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
                      DataColumn(label: Text('Payment')),
                      DataColumn(label: Text('Reference')),
                      DataColumn(label: Text('Actions')),
                    ],
                    rows: expenses.map((e) {
                      return DataRow(
                        cells: [
                          DataCell(Text(dateFormat.format(e.expenseDate))),
                          DataCell(Text(e.title)),
                          DataCell(Text(catMap[e.expenseCategoryId] ?? '—')),
                          DataCell(Text(currencyFormat.format(e.amount))),
                          DataCell(Text(
                              e.paymentMethodId != null
                                  ? (pmMap[e.paymentMethodId] ?? '—')
                                  : '—')),
                          DataCell(Text(e.referenceNumber ?? '—')),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, size: 20),
                                  onPressed: () => onEdit(e),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 20),
                                  onPressed: () => onDelete(e),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpensesFilters extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(expenseCategoriesStreamProvider);
    final categoryFilter = ref.watch(expensesCategoryFilterProvider);
    final dateFrom = ref.watch(expensesDateFromProvider);
    final dateTo = ref.watch(expensesDateToProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        children: [
          categoriesAsync.when(
            data: (categories) {
              return DropdownButton<int?>(
                value: categoryFilter,
                hint: const Text('All Categories'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('All Categories')),
                  ...categories.map((c) => DropdownMenuItem(
                        value: c.id,
                        child: Text(c.name),
                      )),
                ],
                onChanged: (v) =>
                    ref.read(expensesCategoryFilterProvider.notifier).state = v,
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          TextButton.icon(
            onPressed: () async {
              final range = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
                initialDateRange: dateFrom != null && dateTo != null
                    ? DateTimeRange(start: dateFrom, end: dateTo)
                    : null,
              );
              if (range != null) {
                ref.read(expensesDateFromProvider.notifier).state = range.start;
                ref.read(expensesDateToProvider.notifier).state = range.end;
              }
            },
            icon: const Icon(Icons.date_range, size: 18),
            label: Text(
              dateFrom != null && dateTo != null
                  ? '${DateFormat('MMM d').format(dateFrom)} - ${DateFormat('MMM d').format(dateTo)}'
                  : 'Date Range',
            ),
          ),
          if (dateFrom != null || dateTo != null)
            TextButton(
              onPressed: () {
                ref.read(expensesDateFromProvider.notifier).state = null;
                ref.read(expensesDateToProvider.notifier).state = null;
              },
              child: const Text('Clear dates'),
            ),
        ],
      ),
    );
  }
}

class _ExpenseCategoriesTab extends ConsumerWidget {
  const _ExpenseCategoriesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(expenseCategoriesStreamProvider);

    return categoriesAsync.when(
      data: (categories) => _CategoriesList(categories: categories),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

class _CategoriesList extends StatelessWidget {
  const _CategoriesList({required this.categories});

  final List<ExpenseCategory> categories;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return const EmptyState(
        message: 'No expense categories yet. Add one to get started.',
        icon: Icons.category_outlined,
      );
    }

    return DataTableCard(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Name')),
            DataColumn(label: Text('Description')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Actions')),
          ],
          rows: categories.map((c) => _buildRow(context, c)).toList(),
        ),
      ),
    );
  }

  DataRow _buildRow(BuildContext context, ExpenseCategory category) {
    return DataRow(
      cells: [
        DataCell(Text(category.name)),
        DataCell(Text(category.description ?? '—')),
        DataCell(
          Consumer(
            builder: (context, ref, _) {
              return GestureDetector(
                onTap: () async {
                  final repo = ref.read(expenseCategoriesRepositoryProvider);
                  await repo.setActiveStatus(category.id, !category.isActive);
                },
                child: Chip(
                  label: Text(category.isActive ? 'Active' : 'Inactive'),
                  backgroundColor: category.isActive
                      ? Colors.green.withValues(alpha: 0.2)
                      : Colors.grey.withValues(alpha: 0.2),
                ),
              );
            },
          ),
        ),
        DataCell(
          Consumer(
            builder: (context, ref, _) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    onPressed: () async {
                      await showExpenseCategoryFormDialog(context,
                          existing: category);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    onPressed: () async {
                      final repo = ref.read(expenseCategoriesRepositoryProvider);
                      final deleted = await repo.delete(category.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(deleted
                                ? 'Category deleted'
                                : 'Cannot delete: category has expenses'),
                          ),
                        );
                      }
                    },
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
