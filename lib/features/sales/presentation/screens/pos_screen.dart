import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../database/app_database.dart';
import '../../../printing/presentation/providers/printing_providers.dart';
import '../../../products/presentation/providers/products_providers.dart';
import '../../../settings/presentation/providers/settings_providers.dart';
import '../../domain/models/cart_item.dart';
import '../providers/sales_providers.dart';
import 'sale_details_screen.dart';

class PosScreen extends ConsumerStatefulWidget {
  const PosScreen({super.key});

  @override
  ConsumerState<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends ConsumerState<PosScreen> {
  final _searchFocusNode = FocusNode();
  final _searchController = TextEditingController();
  final _barcodeFocusNode = FocusNode();
  final _barcodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _barcodeFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    _searchController.dispose();
    _barcodeFocusNode.dispose();
    _barcodeController.dispose();
    super.dispose();
  }

  void _focusBarcodeField() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _barcodeFocusNode.requestFocus();
    });
  }

  Future<void> _handleBarcodeSubmit() async {
    final barcode = _barcodeController.text.trim();
    if (barcode.isEmpty) return;

    final prefs = await ref.read(systemPreferencesProvider.future);
    final scanner = ref.read(posScannerServiceProvider);
    final cart = ref.read(cartProvider);
    final result = await scanner.handleBarcodeScan(
      barcode,
      currentCart: cart,
      allowNegativeStock: prefs.allowNegativeStock,
    );

    if (!mounted) return;
    if (result.success && result.product != null) {
      final units = await ref.read(unitsListProvider.future);
      final unitMap = {for (final u in units) u.id: u.name};
      final unitName = unitMap[result.product!.unitId] ?? 'pc';
      final item = CartItem(
        product: result.product!,
        unitName: unitName,
        quantity: 1,
        unitCost: result.product!.costPrice,
        unitPrice: result.product!.salePrice,
      );
      ref.read(cartProvider.notifier).addItem(item);
      _barcodeController.clear();
      _focusBarcodeField();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Added: ${result.product!.name}')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error ?? 'Product not found'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      _focusBarcodeField();
    }
  }

  void _addToCart(Product product, String unitName) {
    final item = CartItem(
      product: product,
      unitName: unitName,
      quantity: 1,
      unitCost: product.costPrice,
      unitPrice: product.salePrice,
    );
    ref.read(cartProvider.notifier).addItem(item);
    _searchController.clear();
    ref.read(posProductSearchQueryProvider.notifier).state = '';
    _searchFocusNode.requestFocus();
  }

  Future<void> _completeSale() async {
    final cart = ref.read(cartProvider);
    if (cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cart is empty')),
      );
      return;
    }

    final cashier = await ref.read(currentCashierProvider.future);
    if (cashier == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No cashier configured. Add a user first.')),
      );
      return;
    }

    final total = ref.read(cartTotalProvider);
    final paid = ref.read(posPaidAmountProvider);
    if (paid < total) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Paid amount (\$${paid.toStringAsFixed(2)}) must be >= total (\$${total.toStringAsFixed(2)})'),
        ),
      );
      return;
    }

    final prefs = await ref.read(systemPreferencesProvider.future);

    try {
      final saleId = await ref.read(salesCheckoutServiceProvider).completeSale(
            items: cart,
            cashierId: cashier.id,
            customerId: ref.read(posCustomerIdProvider),
            paymentMethodId: ref.read(posPaymentMethodIdProvider),
            orderDiscount: ref.read(posOrderDiscountProvider),
            paidAmount: paid,
            allowNegativeStock: prefs.allowNegativeStock,
          );

      ref.read(cartProvider.notifier).clear();
      ref.read(posOrderDiscountProvider.notifier).state = 0;
      ref.read(posPaidAmountProvider.notifier).state = 0;
      ref.read(posCustomerIdProvider.notifier).state = null;
      ref.read(posPaymentMethodIdProvider.notifier).state = null;
      _barcodeController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sale completed successfully')),
        );
        if (prefs.autoPrintAfterSale) {
          try {
            await ref.read(printServiceProvider).printThermalReceipt(context, saleId);
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Print failed: $e. You can reprint from sale details.'),
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
              );
            }
          }
        }
        _focusBarcodeField();
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (ctx) => SaleDetailsScreen(saleId: saleId),
          ),
        );
      }
    } on StateError catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } on ArgumentError catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Invalid input')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _clearCart() {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Cart'),
        content: const Text('Remove all items from cart?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Clear'),
          ),
        ],
      ),
    ).then((ok) {
      if (ok == true) {
        ref.read(cartProvider.notifier).clear();
        _focusBarcodeField();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(posProductSearchResultsProvider);
    final unitsAsync = ref.watch(unitsListProvider);
    final cart = ref.watch(cartProvider);
    final customersAsync = ref.watch(activeCustomersProvider);
    final paymentMethodsAsync = ref.watch(activePaymentMethodsProvider);
    final subtotal = ref.watch(cartSubtotalProvider);
    final total = ref.watch(cartTotalProvider);
    final paid = ref.watch(posPaidAmountProvider);
    final change = ref.watch(changeAmountProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _barcodeController,
            focusNode: _barcodeFocusNode,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Scan barcode or enter code',
              prefixIcon: const Icon(Icons.qr_code_scanner),
              border: const OutlineInputBorder(),
              filled: true,
              isDense: true,
            ),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _handleBarcodeSubmit(),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 1,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Products',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _searchController,
                            focusNode: _searchFocusNode,
                            decoration: const InputDecoration(
                              hintText: 'Search by name, SKU, barcode',
                              prefixIcon: Icon(Icons.search),
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            onChanged: (v) =>
                                ref.read(posProductSearchQueryProvider.notifier).state = v,
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: unitsAsync.when(
                              data: (units) {
                                final unitMap = {for (final u in units) u.id: u.name};
                                return productsAsync.when(
                                  data: (products) {
                                    if (products.isEmpty) {
                                      return Center(
                                        child: Text(
                                          productsAsync.hasValue && ref.read(posProductSearchQueryProvider).isEmpty
                                              ? 'No active products'
                                              : 'No matching products',
                                        ),
                                      );
                                    }
                                    return ListView.builder(
                                      itemCount: products.length,
                                      itemBuilder: (_, i) {
                                        final p = products[i];
                                        final unitName = unitMap[p.unitId] ?? 'pc';
                                        return ListTile(
                                          title: Text(p.name),
                                          subtitle: Text('${p.sku} • \$${p.salePrice.toStringAsFixed(2)} • Stock: ${p.stockQuantity.toStringAsFixed(0)}'),
                                          trailing: p.stockQuantity <= 0
                                              ? const Text('Out of stock', style: TextStyle(color: Colors.red))
                                              : FilledButton(
                                                  onPressed: () => _addToCart(p, unitName),
                                                  child: const Text('Add'),
                                                ),
                                        );
                                      },
                                    );
                                  },
                                  loading: () => const Center(child: CircularProgressIndicator()),
                                  error: (e, st) => Center(child: Text('Error: $e')),
                                );
                              },
                              loading: () => const Center(child: CircularProgressIndicator()),
                              error: (e, st) => Center(child: Text('Error: $e')),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 1,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Cart',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ),
                              if (cart.isNotEmpty)
                                TextButton.icon(
                                  onPressed: _clearCart,
                                  icon: const Icon(Icons.clear_all, size: 18),
                                  label: const Text('Clear'),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            flex: 2,
                            child: cart.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey.shade400),
                                  const SizedBox(height: 16),
                                  Text('Cart is empty', style: TextStyle(color: Colors.grey.shade600)),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: cart.length,
                              itemBuilder: (_, i) {
                                final item = cart[i];
                                return _CartItemRow(
                                  item: item,
                                  onQuantityChanged: (q) => ref
                                      .read(cartProvider.notifier)
                                      .updateQuantity(item.product.id, q),
                                  onRemove: () => ref
                                      .read(cartProvider.notifier)
                                      .removeItem(item.product.id),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                      key: ValueKey('discount_${ref.watch(posOrderDiscountProvider)}'),
                      initialValue: ref.watch(posOrderDiscountProvider) == 0
                          ? ''
                          : ref.watch(posOrderDiscountProvider).toStringAsFixed(2),
                      decoration: const InputDecoration(
                        labelText: 'Order Discount',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            onChanged: (v) {
                              final n = double.tryParse(v) ?? 0;
                              ref.read(posOrderDiscountProvider.notifier).state = n < 0 ? 0 : n;
                            },
                          ),
                          const SizedBox(height: 12),
                          customersAsync.when(
                            data: (customers) => _CustomerSelector(customers: customers),
                            loading: () => const SizedBox(),
                            error: (_, __) => const SizedBox(),
                          ),
                          const SizedBox(height: 12),
                          _TotalsSection(
                      subtotal: subtotal,
                      orderDiscount: ref.watch(posOrderDiscountProvider),
                      total: total,
                      paid: paid,
                      change: change,
                      onDiscountChanged: (v) =>
                          ref.read(posOrderDiscountProvider.notifier).state = v,
                      onPaidChanged: (v) =>
                          ref.read(posPaidAmountProvider.notifier).state = v,
                    ),
                          const SizedBox(height: 12),
                          paymentMethodsAsync.when(
                            data: (methods) => _PaymentMethodSelector(methods: methods),
                            loading: () => const SizedBox(),
                            error: (_, __) => const SizedBox(),
                          ),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: cart.isEmpty ? null : _completeSale,
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text('Complete Sale'),
                          ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
    );
  }
}

class _CartItemRow extends StatelessWidget {
  const _CartItemRow({
    required this.item,
    required this.onQuantityChanged,
    required this.onRemove,
  });

  final CartItem item;
  final void Function(double) onQuantityChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                  Text('${item.product.sku} • \$${item.unitPrice.toStringAsFixed(2)} x ${item.quantity.toStringAsFixed(0)}'),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: () => onQuantityChanged(item.quantity - 1),
                ),
                SizedBox(
                  width: 48,
                  child: Text(
                    item.quantity.toStringAsFixed(0),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => onQuantityChanged(item.quantity + 1),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: onRemove,
                ),
              ],
            ),
            SizedBox(
              width: 70,
              child: Text(
                '\$${item.lineTotal.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.w600),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomerSelector extends ConsumerWidget {
  const _CustomerSelector({required this.customers});

  final List<Customer> customers;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedId = ref.watch(posCustomerIdProvider);
    return DropdownButtonFormField<int?>(
      value: selectedId,
      decoration: const InputDecoration(
        labelText: 'Customer',
        border: OutlineInputBorder(),
        isDense: true,
      ),
      items: [
        const DropdownMenuItem(value: null, child: Text('Walk-in')),
        ...customers.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
      ],
      onChanged: (v) => ref.read(posCustomerIdProvider.notifier).state = v,
    );
  }
}

class _PaymentMethodSelector extends ConsumerWidget {
  const _PaymentMethodSelector({required this.methods});

  final List<PaymentMethod> methods;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedId = ref.watch(posPaymentMethodIdProvider);
    return DropdownButtonFormField<int?>(
      value: selectedId,
      decoration: const InputDecoration(
        labelText: 'Payment Method',
        border: OutlineInputBorder(),
        isDense: true,
      ),
      items: [
        const DropdownMenuItem(value: null, child: Text('Select')),
        ...methods.map((m) => DropdownMenuItem(value: m.id, child: Text(m.name))),
      ],
      onChanged: (v) => ref.read(posPaymentMethodIdProvider.notifier).state = v,
    );
  }
}

class _TotalsSection extends ConsumerWidget {
  const _TotalsSection({
    required this.subtotal,
    required this.orderDiscount,
    required this.total,
    required this.paid,
    required this.change,
    required this.onDiscountChanged,
    required this.onPaidChanged,
  });

  final double subtotal;
  final double orderDiscount;
  final double total;
  final double paid;
  final double change;
  final void Function(double) onDiscountChanged;
  final void Function(double) onPaidChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Row('Subtotal', subtotal),
            _Row('Discount', -orderDiscount),
            const Divider(),
            _Row('Total', total, bold: true),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: paid == 0 ? '' : paid.toStringAsFixed(2),
              decoration: const InputDecoration(
                labelText: 'Paid Amount',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (v) {
                final n = double.tryParse(v) ?? 0;
                onPaidChanged(n < 0 ? 0 : n);
              },
            ),
            if (change > 0) ...[
              const SizedBox(height: 8),
              _Row('Change', change, color: Colors.green),
            ],
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value, {this.bold = false, this.color});

  final String label;
  final double value;
  final bool bold;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
          Text(
            '\$${value.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
