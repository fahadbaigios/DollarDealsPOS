import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../database/app_database.dart';
import '../dialogs/supplier_form_dialog.dart';
import '../providers/products_providers.dart';
import '../widgets/data_table_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/page_header.dart';
import '../widgets/search_field.dart';
import '../widgets/status_badge.dart';

class SuppliersScreen extends ConsumerStatefulWidget {
  const SuppliersScreen({super.key});

  @override
  ConsumerState<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends ConsumerState<SuppliersScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final suppliersAsync = ref.watch(suppliersStreamProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          title: 'Suppliers',
          actions: [
            SearchField(
              controller: _searchController,
              hintText: 'Search by name or phone...',
              onChanged: (v) => ref.read(suppliersSearchQueryProvider.notifier).state = v,
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed: () async {
                await showSupplierFormDialog(context);
              },
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Add Supplier'),
            ),
          ],
        ),
        Expanded(
          child: suppliersAsync.when(
            data: (suppliers) => _buildTable(context, suppliers),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
        ),
      ],
    );
  }

  Widget _buildTable(BuildContext context, List<Supplier> suppliers) {
    if (suppliers.isEmpty) {
      return const EmptyState(
        message: 'No suppliers yet. Add one to get started.',
        icon: Icons.local_shipping_outlined,
      );
    }

    return DataTableCard(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Name')),
            DataColumn(label: Text('Contact')),
            DataColumn(label: Text('Phone')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Actions')),
          ],
          rows: suppliers.map((s) => _buildRow(context, s)).toList(),
        ),
      ),
    );
  }

  DataRow _buildRow(BuildContext context, Supplier supplier) {
    return DataRow(
      cells: [
        DataCell(Text(supplier.name)),
        DataCell(Text(supplier.contactPerson ?? '—')),
        DataCell(Text(supplier.phone ?? '—')),
        DataCell(
          GestureDetector(
            onTap: () async {
              final repo = ref.read(suppliersRepositoryProvider);
              await repo.setActiveStatus(supplier.id, !supplier.isActive);
            },
            child: StatusBadge(active: supplier.isActive),
          ),
        ),
        DataCell(
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            onPressed: () async {
              await showSupplierFormDialog(context, existing: supplier);
            },
          ),
        ),
      ],
    );
  }
}
