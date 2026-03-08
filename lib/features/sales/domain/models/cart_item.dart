import '../../../../database/app_database.dart';

/// Cart item for POS checkout.
class CartItem {
  const CartItem({
    required this.product,
    required this.unitName,
    required this.quantity,
    required this.unitCost,
    required this.unitPrice,
    this.itemDiscount = 0,
    this.itemTax = 0,
  });

  final Product product;
  final String unitName;
  final double quantity;
  final double unitCost;
  final double unitPrice;
  final double itemDiscount;
  final double itemTax;

  double get lineTotal =>
      (quantity * unitPrice) - itemDiscount + itemTax;

  CartItem copyWith({
    Product? product,
    String? unitName,
    double? quantity,
    double? unitCost,
    double? unitPrice,
    double? itemDiscount,
    double? itemTax,
  }) {
    return CartItem(
      product: product ?? this.product,
      unitName: unitName ?? this.unitName,
      quantity: quantity ?? this.quantity,
      unitCost: unitCost ?? this.unitCost,
      unitPrice: unitPrice ?? this.unitPrice,
      itemDiscount: itemDiscount ?? this.itemDiscount,
      itemTax: itemTax ?? this.itemTax,
    );
  }
}
