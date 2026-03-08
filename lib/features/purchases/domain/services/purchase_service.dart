import 'package:drift/drift.dart';

import '../../../../database/app_database.dart';
import '../../../../database/database_constants.dart';
import '../models/purchase_item_input.dart';
import '../../data/repositories/purchases_repository.dart';

class PurchaseService {
  PurchaseService(this._db, this._purchasesRepo);

  final AppDatabase _db;
  final PurchasesRepository _purchasesRepo;

  String computePaymentStatus(double total, double paid) {
    if (paid <= 0) return DatabaseConstants.paymentStatusUnpaid;
    final due = total - paid;
    if (due <= 0) return DatabaseConstants.paymentStatusPaid;
    return DatabaseConstants.paymentStatusPartial;
  }

  Future<String> generateInvoiceNumber() async {
    final seq = await _purchasesRepo.getNextInvoiceSequence();
    final date = DateTime.now();
    final dateStr =
        '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
    return 'PUR-$dateStr-${seq.toString().padLeft(4, '0')}';
  }

  Future<int> createPurchaseWithItems({
    required int supplierId,
    required DateTime purchaseDate,
    String? invoiceNumber,
    String? notes,
    required List<PurchaseItemInput> items,
    double discountAmount = 0,
    double otherCharges = 0,
    double paidAmount = 0,
    int? createdBy,
  }) async {
    if (items.isEmpty) {
      throw ArgumentError('At least one purchase item is required');
    }

    double subtotal = 0;
    double totalTax = 0;
    for (final item in items) {
      if (item.quantity <= 0) {
        throw ArgumentError('Quantity must be greater than zero');
      }
      if (item.unitCost < 0) {
        throw ArgumentError('Unit cost cannot be negative');
      }
      subtotal += item.lineTotal;
      totalTax += item.itemTax;
    }

    final totalAmount = subtotal - discountAmount + totalTax + otherCharges;
    final dueAmount = (totalAmount - paidAmount).clamp(0.0, double.infinity);
    final paymentStatus = computePaymentStatus(totalAmount, paidAmount);

    if (paidAmount < 0) {
      throw ArgumentError('Paid amount cannot be negative');
    }
    if (discountAmount < 0) {
      throw ArgumentError('Discount cannot be negative');
    }
    if (otherCharges < 0) {
      throw ArgumentError('Other charges cannot be negative');
    }

    return _db.transaction(() async {
      final invoice = invoiceNumber ?? await generateInvoiceNumber();

      final purchaseId = await _db.into(_db.purchases).insert(
            PurchasesCompanion.insert(
              supplierId: supplierId,
              createdBy: createdBy == null ? const Value.absent() : Value(createdBy),
              invoiceNumber: Value(invoice),
              purchaseDate: purchaseDate,
              subtotal: Value(subtotal),
              discountAmount: Value(discountAmount),
              taxAmount: Value(totalTax),
              otherCharges: Value(otherCharges),
              totalAmount: Value(totalAmount),
              paidAmount: Value(paidAmount),
              dueAmount: Value(dueAmount),
              paymentStatus: Value(paymentStatus),
              notes: notes == null ? const Value.absent() : Value(notes),
            ),
          );

      for (final item in items) {
        final lineTotal = item.lineTotal;
        await _db.into(_db.purchaseItems).insert(
              PurchaseItemsCompanion.insert(
                purchaseId: purchaseId,
                productId: item.product.id,
                quantity: item.quantity,
                unitCost: item.unitCost,
                itemDiscount: Value(item.itemDiscount),
                itemTax: Value(item.itemTax),
                totalCost: lineTotal,
              ),
            );

        final currentProduct = await (_db.select(_db.products)
              ..where((t) => t.id.equals(item.product.id)))
            .getSingle();
        final newStock = currentProduct.stockQuantity + item.quantity;

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
                transactionType: DatabaseConstants.transactionTypePurchase,
                quantity: item.quantity,
                unitCost: Value(item.unitCost),
                referenceType: Value(DatabaseConstants.referenceTypePurchase),
                referenceId: Value(purchaseId),
              ),
            );
      }

      return purchaseId;
    });
  }
}
