import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_names.dart';
import '../../../../database/app_database.dart';
import '../../../products/presentation/widgets/data_table_card.dart';
import '../../../products/presentation/widgets/empty_state.dart';
import '../../../products/presentation/widgets/page_header.dart';
import '../../../products/presentation/widgets/search_field.dart';
import '../providers/purchases_providers.dart';
import '../widgets/payment_status_badge.dart';

class PurchasesListScreen extends ConsumerStatefulWidget {
  const PurchasesListScreen({super.key});

  @override
  ConsumerState<PurchasesListScreen> createState() => _PurchasesListScreenState();
}

class _PurchasesListScreenState extends ConsumerState<PurchasesListScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final purchasesAsync = ref.watch(purchasesStreamProvider);
    final suppliersAsync = ref.watch(activeSuppliersProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          title: 'Purchases',
          actions: [
            SearchField(
              controller: _searchController,
              hintText: 'Search by invoice or notes...',
              onChanged: (v) =>
                  ref.read(purchasesSearchQueryProvider.notifier).state = v,
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed: () => context.push(RouteNames.createPurchasePath),
              icon: const Icon(Icons.add, size: 20),
              label: const Text('New Purchase'),
            ),
          ],
        ),
        Expanded(
          child: purchasesAsync.when(
            data: (purchases) => _buildTable(context, ref, purchases, suppliersAsync),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
        ),
      ],
    );
  }

  Widget _buildTable(
    BuildContext context,
    WidgetRef ref,
    List<Purchase> purchases,
    AsyncValue<List<Supplier>> suppliersAsync,
  ) {
    if (purchases.isEmpty) {
      return const EmptyState(
        message: 'No purchases yet. Create one to get started.',
        icon: Icons.shopping_cart_outlined,
      );
    }

    return DataTableCard(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Invoice')),
            DataColumn(label: Text('Supplier')),
            DataColumn(label: Text('Date')),
            DataColumn(label: Text('Total')),
            DataColumn(label: Text('Paid')),
            DataColumn(label: Text('Due')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Actions')),
          ],
          rows: purchases
              .map((p) => _buildRow(context, ref, p, suppliersAsync))
              .toList(),
        ),
      ),
    );
  }

  DataRow _buildRow(
    BuildContext context,
    WidgetRef ref,
    Purchase purchase,
    AsyncValue<List<Supplier>> suppliersAsync,
  ) {
    final supplierName = suppliersAsync.valueOrNull
            ?.where((s) => s.id == purchase.supplierId)
            .map((s) => s.name)
            .firstOrNull ??
        '—';

    return DataRow(
      cells: [
        DataCell(Text(purchase.invoiceNumber ?? '—')),
        DataCell(Text(supplierName)),
        DataCell(Text(_formatDate(purchase.purchaseDate))),
        DataCell(Text('\$${purchase.totalAmount.toStringAsFixed(2)}')),
        DataCell(Text('\$${purchase.paidAmount.toStringAsFixed(2)}')),
        DataCell(Text('\$${purchase.dueAmount.toStringAsFixed(2)}')),
        DataCell(PaymentStatusBadge(status: purchase.paymentStatus)),
        DataCell(
          IconButton(
            icon: const Icon(Icons.visibility_outlined, size: 20),
            onPressed: () => context.push('/purchases/${purchase.id}'),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }
}
