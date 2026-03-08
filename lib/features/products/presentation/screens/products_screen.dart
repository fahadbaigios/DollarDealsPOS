import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../database/app_database.dart';
import '../dialogs/product_form_dialog.dart';
import '../providers/products_providers.dart';
import '../screens/categories_screen.dart';
import '../screens/suppliers_screen.dart';
import '../screens/units_screen.dart';
import '../widgets/data_table_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/page_header.dart';
import '../widgets/search_field.dart';
import '../widgets/status_badge.dart';

class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({super.key});

  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabs: const [
              Tab(text: 'Products'),
              Tab(text: 'Categories'),
              Tab(text: 'Units'),
              Tab(text: 'Suppliers'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _ProductsTab(searchController: _searchController),
              const CategoriesScreen(),
              const UnitsScreen(),
              const SuppliersScreen(),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProductsTab extends ConsumerWidget {
  const _ProductsTab({required this.searchController});

  final TextEditingController searchController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsStreamProvider);
    final categoriesAsync = ref.watch(categoriesListProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          title: 'Products',
          actions: [
            SearchField(
              controller: searchController,
              hintText: 'Search by name, SKU, barcode...',
              onChanged: (v) => ref.read(productsSearchQueryProvider.notifier).state = v,
            ),
            const SizedBox(width: 12),
            categoriesAsync.when(
              data: (categories) => DropdownButton<int?>(
                value: ref.watch(productsCategoryFilterProvider),
                hint: const Text('All categories'),
                items: [
                  const DropdownMenuItem<int?>(value: null, child: Text('All categories')),
                  ...categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
                ],
                onChanged: (v) => ref.read(productsCategoryFilterProvider.notifier).state = v,
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(width: 12),
              SegmentedButton<bool?>(
                segments: const [
                  ButtonSegment(value: null, label: Text('All')),
                  ButtonSegment(value: true, label: Text('Active')),
                  ButtonSegment(value: false, label: Text('Inactive')),
                ],
                selected: {ref.watch(productsActiveFilterProvider)},
                onSelectionChanged: (s) => ref.read(productsActiveFilterProvider.notifier).state = s.first,
              ),
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed: () async {
                await showProductFormDialog(context);
              },
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Add Product'),
            ),
          ],
        ),
        Expanded(
          child: productsAsync.when(
            data: (products) => _buildTable(context, ref, products),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
        ),
      ],
    );
  }

  Widget _buildTable(BuildContext context, WidgetRef ref, List<Product> products) {
    if (products.isEmpty) {
      return const EmptyState(
        message: 'No products yet. Add categories and units first, then add products.',
        icon: Icons.inventory_2_outlined,
      );
    }

    return DataTableCard(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Name')),
            DataColumn(label: Text('SKU')),
            DataColumn(label: Text('Category')),
            DataColumn(label: Text('Stock')),
            DataColumn(label: Text('Cost')),
            DataColumn(label: Text('Price')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Actions')),
          ],
          rows: products.map((p) => _buildRow(context, ref, p)).toList(),
        ),
      ),
    );
  }

  DataRow _buildRow(BuildContext context, WidgetRef ref, Product product) {
    final isLowStock = product.stockQuantity <= product.reorderLevel;
    return DataRow(
      cells: [
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(product.name),
              if (isLowStock) ...[
                const SizedBox(width: 6),
                Icon(Icons.warning_amber_rounded, size: 18, color: Theme.of(context).colorScheme.error),
              ],
            ],
          ),
        ),
        DataCell(Text(product.sku)),
        DataCell(
          FutureBuilder(
            future: ref.read(categoriesRepositoryProvider).getById(product.categoryId),
            builder: (context, snap) => Text(snap.data?.name ?? '—'),
          ),
        ),
        DataCell(Text(product.stockQuantity.toStringAsFixed(0))),
        DataCell(Text('\$${product.costPrice.toStringAsFixed(2)}')),
        DataCell(Text('\$${product.salePrice.toStringAsFixed(2)}')),
        DataCell(
          GestureDetector(
            onTap: () async {
              final repo = ref.read(productsRepositoryProvider);
              await repo.setActiveStatus(product.id, !product.isActive);
            },
            child: StatusBadge(active: product.isActive),
          ),
        ),
        DataCell(
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            onPressed: () async {
              await showProductFormDialog(context, existing: product);
            },
          ),
        ),
      ],
    );
  }
}
