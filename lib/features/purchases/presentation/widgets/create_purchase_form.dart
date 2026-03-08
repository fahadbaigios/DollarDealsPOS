import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../database/app_database.dart';
import '../providers/purchases_providers.dart';
import '../../domain/models/purchase_item_input.dart';
import 'payment_status_badge.dart';
import 'purchase_item_row.dart';

class CreatePurchaseForm extends ConsumerWidget {
  const CreatePurchaseForm({
    super.key,
    required this.supplier,
    required this.onSupplierChanged,
    required this.purchaseDate,
    required this.onPurchaseDateChanged,
    required this.notes,
    required this.onNotesChanged,
    this.invoiceNumber,
    required this.onInvoiceNumberChanged,
    required this.discountAmount,
    required this.onDiscountAmountChanged,
    required this.otherCharges,
    required this.onOtherChargesChanged,
    required this.paidAmount,
    required this.onPaidAmountChanged,
    required this.subtotal,
    required this.totalTax,
    required this.totalAmount,
    required this.dueAmount,
    required this.paymentStatus,
  });

  final Supplier? supplier;
  final ValueChanged<Supplier?> onSupplierChanged;
  final DateTime purchaseDate;
  final ValueChanged<DateTime> onPurchaseDateChanged;
  final String notes;
  final ValueChanged<String> onNotesChanged;
  final String? invoiceNumber;
  final ValueChanged<String?> onInvoiceNumberChanged;
  final double discountAmount;
  final ValueChanged<double> onDiscountAmountChanged;
  final double otherCharges;
  final ValueChanged<double> onOtherChargesChanged;
  final double paidAmount;
  final ValueChanged<double> onPaidAmountChanged;
  final double subtotal;
  final double totalTax;
  final double totalAmount;
  final double dueAmount;
  final String paymentStatus;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(createPurchaseItemsProvider);
    final suppliersAsync = ref.watch(activeSuppliersProvider);
    final productsAsync = ref.watch(activeProductsProvider);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _MetadataSection(
                supplier: supplier,
                onSupplierChanged: onSupplierChanged,
                purchaseDate: purchaseDate,
                onPurchaseDateChanged: onPurchaseDateChanged,
                notes: notes,
                onNotesChanged: onNotesChanged,
                invoiceNumber: invoiceNumber,
                onInvoiceNumberChanged: onInvoiceNumberChanged,
                suppliersAsync: suppliersAsync,
              ),
              const SizedBox(height: 24),
              _ItemsSection(
                items: items,
                productsAsync: productsAsync,
                onAddItem: () {
                  final products = productsAsync.valueOrNull;
                  if (products == null || products.isEmpty) return;
                  ref.read(createPurchaseItemsProvider.notifier).state = [
                    ...items,
                    PurchaseItemInput(
                      product: products.first,
                      quantity: 1,
                      unitCost: 0,
                    ),
                  ];
                },
                onRemoveItem: (index) {
                  final updated = [...items];
                  updated.removeAt(index);
                  ref.read(createPurchaseItemsProvider.notifier).state = updated;
                },
                onItemChanged: (index, item) {
                  final updated = [...items];
                  updated[index] = item;
                  ref.read(createPurchaseItemsProvider.notifier).state = updated;
                },
              ),
            ],
          ),
        ),
        const SizedBox(width: 24),
        SizedBox(
          width: 320,
          child: _TotalsSection(
            discountAmount: discountAmount,
            onDiscountAmountChanged: onDiscountAmountChanged,
            otherCharges: otherCharges,
            onOtherChargesChanged: onOtherChargesChanged,
            paidAmount: paidAmount,
            onPaidAmountChanged: onPaidAmountChanged,
            subtotal: subtotal,
            totalTax: totalTax,
            totalAmount: totalAmount,
            dueAmount: dueAmount,
            paymentStatus: paymentStatus,
          ),
        ),
      ],
    );
  }
}

class _MetadataSection extends StatelessWidget {
  const _MetadataSection({
    required this.supplier,
    required this.onSupplierChanged,
    required this.purchaseDate,
    required this.onPurchaseDateChanged,
    required this.notes,
    required this.onNotesChanged,
    this.invoiceNumber,
    required this.onInvoiceNumberChanged,
    required this.suppliersAsync,
  });

  final Supplier? supplier;
  final ValueChanged<Supplier?> onSupplierChanged;
  final DateTime purchaseDate;
  final ValueChanged<DateTime> onPurchaseDateChanged;
  final String notes;
  final ValueChanged<String> onNotesChanged;
  final String? invoiceNumber;
  final ValueChanged<String?> onInvoiceNumberChanged;
  final AsyncValue<List<Supplier>> suppliersAsync;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Purchase Info', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            suppliersAsync.when(
              data: (suppliers) => DropdownButtonFormField<Supplier>(
                value: supplier,
                decoration: const InputDecoration(
                  labelText: 'Supplier *',
                  border: OutlineInputBorder(),
                ),
                items: suppliers
                    .map((s) => DropdownMenuItem(value: s, child: Text(s.name)))
                    .toList(),
                onChanged: onSupplierChanged,
              ),
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Error: $e'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: invoiceNumber,
                    decoration: const InputDecoration(
                      labelText: 'Invoice (auto if empty)',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) => onInvoiceNumberChanged(v.isEmpty ? null : v),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DatePickerField(
                    date: purchaseDate,
                    onDateChanged: onPurchaseDateChanged,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: notes,
              decoration: const InputDecoration(
                labelText: 'Notes',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              onChanged: onNotesChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemsSection extends StatelessWidget {
  const _ItemsSection({
    required this.items,
    required this.productsAsync,
    required this.onAddItem,
    required this.onRemoveItem,
    required this.onItemChanged,
  });

  final List<PurchaseItemInput> items;
  final AsyncValue<List<Product>> productsAsync;
  final VoidCallback onAddItem;
  final ValueChanged<int> onRemoveItem;
  final ValueChanged2<int, PurchaseItemInput> onItemChanged;

  TableRow _buildItemRow({
    required PurchaseItemInput item,
    required List<Product> products,
    required ValueChanged<PurchaseItemInput> onChanged,
    required VoidCallback onRemove,
  }) {
    return TableRow(
      children: [
        PurchaseItemRow.buildProductCell(
          product: item.product,
          products: products,
          onProductChanged: (p) => onChanged(item.copyWith(product: p)),
        ),
        PurchaseItemRow.buildNumberCell(
          value: item.quantity,
          onChanged: (v) => onChanged(item.copyWith(quantity: v)),
          min: 0.001,
        ),
        PurchaseItemRow.buildNumberCell(
          value: item.unitCost,
          onChanged: (v) => onChanged(item.copyWith(unitCost: v)),
          min: 0,
        ),
        PurchaseItemRow.buildNumberCell(
          value: item.itemDiscount,
          onChanged: (v) => onChanged(item.copyWith(itemDiscount: v)),
          min: 0,
        ),
        PurchaseItemRow.buildNumberCell(
          value: item.itemTax,
          onChanged: (v) => onChanged(item.copyWith(itemTax: v)),
          min: 0,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text('\$${item.lineTotal.toStringAsFixed(2)}'),
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline, size: 20),
          onPressed: onRemove,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Items', style: Theme.of(context).textTheme.titleMedium),
                FilledButton.icon(
                  onPressed: productsAsync.hasValue ? onAddItem : null,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Item'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (items.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: Text('Add items to this purchase'),
                ),
              )
            else
              Table(
                columnWidths: const {
                  0: FlexColumnWidth(3),
                  1: FlexColumnWidth(1),
                  2: FlexColumnWidth(1),
                  3: FlexColumnWidth(1),
                  4: FlexColumnWidth(1),
                  5: FlexColumnWidth(1),
                  6: FlexColumnWidth(0.5),
                },
                children: [
                  TableRow(
                    children: [
                      _TableHeader('Product'),
                      _TableHeader('Qty'),
                      _TableHeader('Unit Cost'),
                      _TableHeader('Discount'),
                      _TableHeader('Tax'),
                      _TableHeader('Total'),
                      _TableHeader(''),
                    ],
                  ),
                  ...items.asMap().entries.map((e) => _buildItemRow(
                        item: e.value,
                        products: productsAsync.valueOrNull ?? [],
                        onChanged: (item) => onItemChanged(e.key, item),
                        onRemove: () => onRemoveItem(e.key),
                      )),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}

class _TotalsSection extends StatelessWidget {
  const _TotalsSection({
    required this.discountAmount,
    required this.onDiscountAmountChanged,
    required this.otherCharges,
    required this.onOtherChargesChanged,
    required this.paidAmount,
    required this.onPaidAmountChanged,
    required this.subtotal,
    required this.totalTax,
    required this.totalAmount,
    required this.dueAmount,
    required this.paymentStatus,
  });

  final double discountAmount;
  final ValueChanged<double> onDiscountAmountChanged;
  final double otherCharges;
  final ValueChanged<double> onOtherChargesChanged;
  final double paidAmount;
  final ValueChanged<double> onPaidAmountChanged;
  final double subtotal;
  final double totalTax;
  final double totalAmount;
  final double dueAmount;
  final String paymentStatus;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Summary', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            _SummaryRow('Subtotal', subtotal),
            _MoneyField(
              label: 'Order Discount',
              value: discountAmount,
              onChanged: onDiscountAmountChanged,
            ),
            _SummaryRow('Tax', totalTax),
            _MoneyField(
              label: 'Other Charges',
              value: otherCharges,
              onChanged: onOtherChargesChanged,
            ),
            const Divider(),
            _SummaryRow('Total', totalAmount, bold: true),
            _MoneyField(
              label: 'Paid Amount',
              value: paidAmount,
              onChanged: onPaidAmountChanged,
            ),
            _SummaryRow('Due', dueAmount),
            const SizedBox(height: 12),
            PaymentStatusBadge(status: paymentStatus),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow(this.label, this.amount, {this.bold = false});

  final String label;
  final double amount;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: bold ? FontWeight.bold : null)),
          Text(
            '\$${amount.toStringAsFixed(2)}',
            style: TextStyle(fontWeight: bold ? FontWeight.bold : null),
          ),
        ],
      ),
    );
  }
}

class _MoneyField extends StatelessWidget {
  const _MoneyField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        initialValue: value == 0 ? '' : value.toStringAsFixed(2),
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          prefixText: '\$ ',
        ),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        onChanged: (v) {
          final n = double.tryParse(v) ?? 0;
          onChanged(n);
        },
      ),
    );
  }
}

typedef ValueChanged2<A, B> = void Function(A a, B b);

class _DatePickerField extends StatelessWidget {
  const _DatePickerField({
    required this.date,
    required this.onDateChanged,
  });

  final DateTime date;
  final ValueChanged<DateTime> onDateChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (picked != null) onDateChanged(picked);
      },
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Date',
          border: OutlineInputBorder(),
        ),
        child: Text(
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
        ),
      ),
    );
  }
}
