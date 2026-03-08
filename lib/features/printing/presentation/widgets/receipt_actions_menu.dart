import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/printing_providers.dart';

/// Menu with receipt/invoice print and export actions.
class ReceiptActionsMenu extends ConsumerWidget {
  const ReceiptActionsMenu({
    super.key,
    required this.saleId,
    required this.invoiceNumber,
    required this.onReprintComplete,
  });

  final int saleId;
  final String invoiceNumber;
  final VoidCallback? onReprintComplete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final printService = ref.watch(printServiceProvider);
    final receiptsRepo = ref.watch(receiptsRepositoryProvider);

    return PopupMenuButton<String>(
      icon: const Icon(Icons.print),
      tooltip: 'Print / Export',
      onSelected: (value) async {
        switch (value) {
          case 'preview_thermal':
            await printService.previewThermalReceipt(context, saleId);
            await receiptsRepo.incrementPrintedCount(saleId);
            onReprintComplete?.call();
            break;
          case 'preview_a4':
            await printService.previewA4Invoice(context, saleId);
            await receiptsRepo.incrementPrintedCount(saleId);
            onReprintComplete?.call();
            break;
          case 'print_thermal':
            await printService.printThermalReceipt(context, saleId);
            await receiptsRepo.incrementPrintedCount(saleId);
            onReprintComplete?.call();
            break;
          case 'print_a4':
            await printService.printA4Invoice(context, saleId);
            await receiptsRepo.incrementPrintedCount(saleId);
            onReprintComplete?.call();
            break;
          case 'export_thermal':
            final path = await printService.savePdfToFile(
              saleId: saleId,
              invoiceNumber: invoiceNumber,
              isThermal: true,
            );
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(path != null
                      ? 'Saved to $path'
                      : 'Export failed'),
                ),
              );
            }
            break;
          case 'export_a4':
            final path = await printService.savePdfToFile(
              saleId: saleId,
              invoiceNumber: invoiceNumber,
              isThermal: false,
            );
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(path != null
                      ? 'Saved to $path'
                      : 'Export failed'),
                ),
              );
            }
            break;
        }
      },
      itemBuilder: (ctx) => [
        const PopupMenuItem(
          value: 'preview_thermal',
          child: ListTile(
            leading: Icon(Icons.receipt_long),
            title: Text('Preview Thermal Receipt'),
          ),
        ),
        const PopupMenuItem(
          value: 'preview_a4',
          child: ListTile(
            leading: Icon(Icons.description),
            title: Text('Preview A4 Invoice'),
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'print_thermal',
          child: ListTile(
            leading: Icon(Icons.print),
            title: Text('Print Thermal Receipt'),
          ),
        ),
        const PopupMenuItem(
          value: 'print_a4',
          child: ListTile(
            leading: Icon(Icons.print),
            title: Text('Print A4 Invoice'),
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'export_thermal',
          child: ListTile(
            leading: Icon(Icons.save_alt),
            title: Text('Export Receipt PDF'),
          ),
        ),
        const PopupMenuItem(
          value: 'export_a4',
          child: ListTile(
            leading: Icon(Icons.save_alt),
            title: Text('Export Invoice PDF'),
          ),
        ),
      ],
    );
  }
}
