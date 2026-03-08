import '../../../../database/app_database.dart';

/// Inventory transaction with resolved product name and SKU.
class TransactionWithProduct {
  const TransactionWithProduct({
    required this.transaction,
    required this.productName,
    required this.productSku,
  });

  final InventoryTransaction transaction;
  final String productName;
  final String productSku;
}
