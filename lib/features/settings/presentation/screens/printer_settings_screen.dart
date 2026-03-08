import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../database/app_database.dart';
import '../../../../core/constants/route_names.dart';
import '../../../products/presentation/widgets/page_header.dart';
import '../providers/settings_providers.dart';
import '../dialogs/printer_form_dialog.dart';

/// Printer settings screen.
class PrinterSettingsScreen extends ConsumerWidget {
  const PrinterSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final printersAsync = ref.watch(printerSettingsListProvider);
    final defaultAsync = ref.watch(defaultPrinterProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          title: 'Printer Settings',
          actions: [
            TextButton.icon(
              onPressed: () => context.goNamed(RouteNames.settings),
              icon: const Icon(Icons.arrow_back, size: 18),
              label: const Text('Back'),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: () async {
                final result = await showPrinterFormDialog(context, ref);
                if (result == true) {
                  ref.invalidate(printerSettingsListProvider);
                  ref.invalidate(defaultPrinterProvider);
                }
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Printer'),
            ),
          ],
        ),
        Expanded(
          child: printersAsync.when(
            data: (printers) {
              if (printers.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.print_outlined, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No printer configured',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add a printer to enable receipt printing',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: () async {
                          final result = await showPrinterFormDialog(context, ref);
                          if (result == true) {
                            ref.invalidate(printerSettingsListProvider);
                            ref.invalidate(defaultPrinterProvider);
                          }
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Add Printer'),
                      ),
                    ],
                  ),
                );
              }
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Name')),
                    DataColumn(label: Text('Type')),
                    DataColumn(label: Text('Paper Width')),
                    DataColumn(label: Text('Copies')),
                    DataColumn(label: Text('Default')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: printers.map<DataRow>((p) {
                    final printer = p as PrinterSetting;
                    final isDefault = defaultAsync.valueOrNull?.id == printer.id;
                    return DataRow(
                      cells: [
                        DataCell(Text(printer.printerName)),
                        DataCell(Text(printer.printerType)),
                        DataCell(Text('${printer.paperWidth} mm')),
                        DataCell(Text('${printer.copies}')),
                        DataCell(isDefault
                            ? const Icon(Icons.star, color: Colors.amber, size: 20)
                            : const SizedBox.shrink()),
                        DataCell(Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, size: 20),
                              onPressed: () async {
                                final result = await showPrinterFormDialog(
                                  context,
                                  ref,
                                  existing: printer,
                                );
                                if (result == true) {
                                  ref.invalidate(printerSettingsListProvider);
                                  ref.invalidate(defaultPrinterProvider);
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 20),
                              onPressed: () async {
                                final ok = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Delete Printer'),
                                    content: Text(
                                      'Delete "${printer.printerName}"?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx, false),
                                        child: const Text('Cancel'),
                                      ),
                                      FilledButton(
                                        onPressed: () => Navigator.pop(ctx, true),
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  ),
                                );
                                if (ok == true && context.mounted) {
                                  await ref
                                      .read(settingsRepositoryProvider)
                                      .deletePrinter(printer.id);
                                  ref.invalidate(printerSettingsListProvider);
                                  ref.invalidate(defaultPrinterProvider);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Printer deleted')),
                                    );
                                  }
                                }
                              },
                            ),
                          ],
                        )),
                      ],
                    );
                  }).toList(),
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Center(child: Text('Error: $e')),
          ),
        ),
      ],
    );
  }
}
