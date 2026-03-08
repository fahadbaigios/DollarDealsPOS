import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../database/app_database.dart';
import '../../../products/presentation/widgets/page_header.dart';
import '../../domain/models/purchase_item_input.dart';
import '../providers/purchases_providers.dart';
import '../widgets/create_purchase_form.dart';

class CreatePurchaseScreen extends ConsumerStatefulWidget {
  const CreatePurchaseScreen({super.key});

  @override
  ConsumerState<CreatePurchaseScreen> createState() => _CreatePurchaseScreenState();
}

class _CreatePurchaseScreenState extends ConsumerState<CreatePurchaseScreen> {
  Supplier? _supplier;
  DateTime _purchaseDate = DateTime.now();
  String _notes = '';
  String? _invoiceNumber;
  double _discountAmount = 0;
  double _otherCharges = 0;
  double _paidAmount = 0;
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(createPurchaseItemsProvider);
    final service = ref.read(purchaseServiceProvider);

    final subtotal = items.fold<double>(0, (s, i) => s + i.lineTotal);
    final totalTax = items.fold<double>(0, (s, i) => s + i.itemTax);
    final totalAmount =
        subtotal - _discountAmount + totalTax + _otherCharges;
    final dueAmount = (totalAmount - _paidAmount).clamp(0.0, double.infinity);
    final paymentStatus =
        service.computePaymentStatus(totalAmount, _paidAmount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          title: 'New Purchase',
          actions: [
            TextButton(
              onPressed: _isSaving ? null : () => context.pop(),
              child: const Text('Cancel'),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed: _isSaving
                  ? null
                  : () => _save(context, ref, items, totalAmount),
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save, size: 20),
              label: Text(_isSaving ? 'Saving...' : 'Save Purchase'),
            ),
          ],
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: CreatePurchaseForm(
              supplier: _supplier,
              onSupplierChanged: (s) => setState(() => _supplier = s),
              purchaseDate: _purchaseDate,
              onPurchaseDateChanged: (d) => setState(() => _purchaseDate = d),
              notes: _notes,
              onNotesChanged: (v) => setState(() => _notes = v),
              invoiceNumber: _invoiceNumber,
              onInvoiceNumberChanged: (v) => setState(() => _invoiceNumber = v),
              discountAmount: _discountAmount,
              onDiscountAmountChanged: (v) => setState(() => _discountAmount = v),
              otherCharges: _otherCharges,
              onOtherChargesChanged: (v) => setState(() => _otherCharges = v),
              paidAmount: _paidAmount,
              onPaidAmountChanged: (v) => setState(() => _paidAmount = v),
              subtotal: subtotal,
              totalTax: totalTax,
              totalAmount: totalAmount,
              dueAmount: dueAmount,
              paymentStatus: paymentStatus,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _save(
    BuildContext context,
    WidgetRef ref,
    List<PurchaseItemInput> items,
    double totalAmount,
  ) async {
    if (_supplier == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a supplier')),
      );
      return;
    }
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one item')),
      );
      return;
    }
    if (_paidAmount < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Paid amount cannot be negative')),
      );
      return;
    }
    if (_discountAmount < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Discount cannot be negative')),
      );
      return;
    }
    if (_otherCharges < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Other charges cannot be negative')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Purchase'),
        content: Text(
          'Save this purchase for \$${totalAmount.toStringAsFixed(2)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    ref.read(createPurchaseItemsProvider.notifier).state = [];
    setState(() => _isSaving = true);

    try {
      final service = ref.read(purchaseServiceProvider);
      final id = await service.createPurchaseWithItems(
        supplierId: _supplier!.id,
        purchaseDate: _purchaseDate,
        invoiceNumber: _invoiceNumber?.trim().isEmpty ?? true
            ? null
            : _invoiceNumber?.trim(),
        notes: _notes.trim().isEmpty ? null : _notes.trim(),
        items: items,
        discountAmount: _discountAmount,
        otherCharges: _otherCharges,
        paidAmount: _paidAmount,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Purchase saved successfully')),
        );
        context.go('/purchases/$id');
      }
    } on ArgumentError catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (context.mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}
