import '../../../../database/app_database.dart';

/// Input model for a purchase item before it's saved (no purchaseId yet).
class PurchaseItemInput {
  const PurchaseItemInput({
    required this.product,
    required this.quantity,
    required this.unitCost,
    this.itemDiscount = 0,
    this.itemTax = 0,
  });

  final Product product;
  final double quantity;
  final double unitCost;
  final double itemDiscount;
  final double itemTax;

  double get lineTotal => (quantity * unitCost) - itemDiscount + itemTax;

  PurchaseItemInput copyWith({
    Product? product,
    double? quantity,
    double? unitCost,
    double? itemDiscount,
    double? itemTax,
  }) {
    return PurchaseItemInput(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      unitCost: unitCost ?? this.unitCost,
      itemDiscount: itemDiscount ?? this.itemDiscount,
      itemTax: itemTax ?? this.itemTax,
    );
  }
}
