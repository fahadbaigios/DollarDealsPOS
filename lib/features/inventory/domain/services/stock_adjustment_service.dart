import 'package:drift/drift.dart';

import '../../../../database/app_database.dart';
import '../../../../database/database_constants.dart';

class StockAdjustmentService {
  StockAdjustmentService(this._db);

  final AppDatabase _db;

  /// Perform stock adjustment. Runs in a single transaction.
  /// [adjustmentType] must be adjustment_in or adjustment_out.
  /// [allowNegativeStock] if false, adjustment_out will fail when resulting stock < 0.
  Future<void> adjustStock({
    required int productId,
    required String adjustmentType,
    required double quantity,
    double? unitCost,
    String? notes,
    bool allowNegativeStock = false,
  }) async {
    if (quantity <= 0) {
      throw ArgumentError('Quantity must be greater than zero');
    }
    if (adjustmentType != DatabaseConstants.transactionTypeAdjustmentIn &&
        adjustmentType != DatabaseConstants.transactionTypeAdjustmentOut) {
      throw ArgumentError(
        'adjustmentType must be adjustment_in or adjustment_out',
      );
    }

    await _db.transaction(() async {
      final product = await (_db.select(_db.products)
            ..where((t) => t.id.equals(productId)))
          .getSingleOrNull();
      if (product == null) {
        throw StateError('Product not found');
      }

      final currentStock = product.stockQuantity;
      final cost = unitCost ?? product.costPrice;

      double newStock;
      if (adjustmentType == DatabaseConstants.transactionTypeAdjustmentIn) {
        newStock = currentStock + quantity;
      } else {
        newStock = currentStock - quantity;
        if (!allowNegativeStock && newStock < 0) {
          throw StateError(
            'Insufficient stock. Current: $currentStock, requested: $quantity',
          );
        }
      }

      await (_db.update(_db.products)
            ..where((t) => t.id.equals(productId)))
          .write(
        ProductsCompanion(
          stockQuantity: Value(newStock),
          updatedAt: Value(DateTime.now()),
        ),
      );

      await _db.into(_db.inventoryTransactions).insert(
            InventoryTransactionsCompanion.insert(
              productId: productId,
              transactionType: adjustmentType,
              quantity: quantity,
              unitCost: Value(cost),
              referenceType: const Value(DatabaseConstants.referenceTypeAdjustment),
              notes: notes == null || notes.trim().isEmpty
                  ? const Value.absent()
                  : Value(notes.trim()),
            ),
          );
    });
  }
}
