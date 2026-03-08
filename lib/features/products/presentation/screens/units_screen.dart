import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../database/app_database.dart';
import '../dialogs/unit_form_dialog.dart';
import '../providers/products_providers.dart';
import '../widgets/data_table_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/page_header.dart';

class UnitsScreen extends ConsumerWidget {
  const UnitsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unitsAsync = ref.watch(unitsStreamProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          title: 'Units',
          actions: [
            FilledButton.icon(
              onPressed: () async {
                await showUnitFormDialog(context);
              },
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Add Unit'),
            ),
          ],
        ),
        Expanded(
          child: unitsAsync.when(
            data: (units) => _buildTable(context, units),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
        ),
      ],
    );
  }

  Widget _buildTable(BuildContext context, List<Unit> units) {
    if (units.isEmpty) {
      return const EmptyState(
        message: 'No units yet. Add one to get started (e.g. Piece/pc, Kilogram/kg).',
        icon: Icons.straighten_outlined,
      );
    }

    return DataTableCard(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Name')),
            DataColumn(label: Text('Symbol')),
            DataColumn(label: Text('Actions')),
          ],
          rows: units.map((u) => _buildRow(context, u)).toList(),
        ),
      ),
    );
  }

  DataRow _buildRow(BuildContext context, Unit unit) {
    return DataRow(
      cells: [
        DataCell(Text(unit.name)),
        DataCell(Text(unit.symbol)),
        DataCell(
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            onPressed: () async {
              await showUnitFormDialog(context, existing: unit);
            },
          ),
        ),
      ],
    );
  }
}
