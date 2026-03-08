import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../database/app_database.dart';
import '../dialogs/category_form_dialog.dart';
import '../providers/products_providers.dart';
import '../widgets/data_table_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/page_header.dart';
import '../widgets/search_field.dart';
import '../widgets/status_badge.dart';

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesStreamProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          title: 'Categories',
          actions: [
            SearchField(
              controller: _searchController,
              hintText: 'Search categories...',
              onChanged: (v) => ref.read(categoriesSearchQueryProvider.notifier).state = v,
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed: () async {
                await showCategoryFormDialog(context);
              },
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Add Category'),
            ),
          ],
        ),
        Expanded(
          child: categoriesAsync.when(
            data: (categories) => _buildTable(context, categories),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
        ),
      ],
    );
  }

  Widget _buildTable(BuildContext context, List<Category> categories) {
    if (categories.isEmpty) {
      return const EmptyState(
        message: 'No categories yet. Add one to get started.',
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

  DataRow _buildRow(BuildContext context, Category category) {
    return DataRow(
      cells: [
        DataCell(Text(category.name)),
        DataCell(Text(category.description ?? '—')),
        DataCell(
          GestureDetector(
            onTap: () async {
              final repo = ref.read(categoriesRepositoryProvider);
              await repo.setActiveStatus(category.id, !category.isActive);
            },
            child: StatusBadge(active: category.isActive),
          ),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20),
                onPressed: () async {
                  await showCategoryFormDialog(context, existing: category);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
