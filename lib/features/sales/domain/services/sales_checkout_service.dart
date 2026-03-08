import 'package:drift/drift.dart';

import '../../../../database/app_database.dart';
import '../../../../database/database_constants.dart';
import '../../data/repositories/sales_repository.dart';
import '../models/cart_item.dart';

class SalesCheckoutService {
  SalesCheckoutService(this._db, this._salesRepo);

  final AppDatabase _db;
  final SalesRepository _salesRepo;

  String computePaymentStatus(double total, double paid) {
    if (paid <= 0) return DatabaseConstants.paymentStatusUnpaid;
    final due = total - paid;
    if (due <= 0) return DatabaseConstants.paymentStatusPaid;
    return DatabaseConstants.paymentStatusPartial;
  }

  Future<String> generateInvoiceNumber() async {
    final seq = await _salesRepo.getNextInvoiceSequence();
    final date = DateTime.now();
    final dateStr =
        '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
    return 'SAL-$dateStr-${seq.toString().padLeft(4, '0')}';
  }

  /// Validate stock for all cart items. Throws if any item exceeds available stock.
  Future<void> validateStock(List<CartItem> items) async {
    for (final item in items) {
      final product = await (_db.select(_db.products)
            ..where((t) => t.id.equals(item.product.id)))
          .getSingleOrNull();
      if (product == null) {
        throw StateError('Product ${item.product.name} not found');
      }
      if (item.quantity > product.stockQuantity) {
        throw StateError(
          'Insufficient stock for ${item.product.name}. '
          'Available: ${product.stockQuantity}, requested: ${item.quantity}',
        );
      }
    }
  }

  /// Complete sale in a single transaction.
  Future<int> completeSale({
    required List<CartItem> items,
    required int cashierId,
    int? customerId,
    int? paymentMethodId,
    double orderDiscount = 0,
    double paidAmount = 0,
    String? notes,
    bool allowNegativeStock = false,
  }) async {
    if (items.isEmpty) {
      throw ArgumentError('Cart cannot be empty');
    }
    if (paidAmount < 0) {
      throw ArgumentError('Paid amount cannot be negative');
    }
    if (orderDiscount < 0) {
      throw ArgumentError('Order discount cannot be negative');
    }

    if (!allowNegativeStock) {
      await validateStock(items);
    }

    double subtotal = 0;
    double totalTax = 0;
    for (final item in items) {
      if (item.quantity <= 0) {
        throw ArgumentError('Quantity must be greater than zero');
      }
      subtotal += item.lineTotal;
      totalTax += item.itemTax;
    }

    final totalAmount = subtotal - orderDiscount + totalTax;
    final dueAmount = (totalAmount - paidAmount).clamp(0.0, double.infinity);
    final paymentStatus = computePaymentStatus(totalAmount, paidAmount);

    return _db.transaction(() async {
      final invoice = await generateInvoiceNumber();
      final saleDate = DateTime.now();

      final saleId = await _db.into(_db.sales).insert(
            SalesCompanion.insert(
              cashierId: cashierId,
              paymentMethodId: paymentMethodId == null
                  ? const Value.absent()
                  : Value(paymentMethodId),
              customerId:
                  customerId == null ? const Value.absent() : Value(customerId),
              invoiceNumber: invoice,
              saleDate: saleDate,
              subtotal: Value(subtotal),
              taxAmount: Value(totalTax),
              discountAmount: Value(orderDiscount),
              totalAmount: Value(totalAmount),
              paidAmount: Value(paidAmount),
              dueAmount: Value(dueAmount),
              paymentStatus: Value(paymentStatus),
              notes: notes == null || notes.trim().isEmpty
                  ? const Value.absent()
                  : Value(notes.trim()),
            ),
          );

      for (final item in items) {
        await _db.into(_db.saleItems).insert(
              SaleItemsCompanion.insert(
                saleId: saleId,
                productId: item.product.id,
                quantity: item.quantity,
                unitCost: item.unitCost,
                unitPrice: item.unitPrice,
                itemDiscount: Value(item.itemDiscount),
                itemTax: Value(item.itemTax),
                totalAmount: item.lineTotal,
              ),
            );

        final currentProduct = await (_db.select(_db.products)
              ..where((t) => t.id.equals(item.product.id)))
            .getSingle();
        final newStock = currentProduct.stockQuantity - item.quantity;

        if (!allowNegativeStock && newStock < 0) {
          throw StateError(
            'Insufficient stock for ${item.product.name} during checkout',
          );
        }

        await (_db.update(_db.products)
              ..where((t) => t.id.equals(item.product.id)))
            .write(
              ProductsCompanion(
                stockQuantity: Value(newStock),
                updatedAt: Value(DateTime.now()),
              ),
            );

        await _db.into(_db.inventoryTransactions).insert(
              InventoryTransactionsCompanion.insert(
                productId: item.product.id,
                transactionType: DatabaseConstants.transactionTypeSale,
                quantity: item.quantity,
                unitCost: Value(item.unitCost),
                referenceType: Value(DatabaseConstants.referenceTypeSale),
                referenceId: Value(saleId),
              ),
            );
      }

      final receiptContent = _buildReceiptContent(
        invoice: invoice,
        saleDate: saleDate,
        items: items,
        subtotal: subtotal,
        orderDiscount: orderDiscount,
        totalTax: totalTax,
        totalAmount: totalAmount,
        paidAmount: paidAmount,
        change: paidAmount > totalAmount ? paidAmount - totalAmount : 0,
      );

      await _db.into(_db.receipts).insert(
            ReceiptsCompanion.insert(
              saleId: saleId,
              receiptContent: receiptContent,
            ),
          );

      return saleId;
    });
  }

  String _buildReceiptContent({
    required String invoice,
    required DateTime saleDate,
    required List<CartItem> items,
    required double subtotal,
    required double orderDiscount,
    required double totalTax,
    required double totalAmount,
    required double paidAmount,
    required double change,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('=== RECEIPT ===');
    buffer.writeln('Invoice: $invoice');
    buffer.writeln('Date: ${saleDate.toIso8601String()}');
    buffer.writeln('---');
    for (final item in items) {
      buffer.writeln(
        '${item.product.name} x${item.quantity} @ \$${item.unitPrice.toStringAsFixed(2)} = \$${item.lineTotal.toStringAsFixed(2)}',
      );
    }
    buffer.writeln('---');
    buffer.writeln('Subtotal: \$${subtotal.toStringAsFixed(2)}');
    if (orderDiscount > 0) {
      buffer.writeln('Discount: -\$${orderDiscount.toStringAsFixed(2)}');
    }
    buffer.writeln('Tax: \$${totalTax.toStringAsFixed(2)}');
    buffer.writeln('Total: \$${totalAmount.toStringAsFixed(2)}');
    buffer.writeln('Paid: \$${paidAmount.toStringAsFixed(2)}');
    if (change > 0) {
      buffer.writeln('Change: \$${change.toStringAsFixed(2)}');
    }
    buffer.writeln('===============');
    return buffer.toString();
  }
}
