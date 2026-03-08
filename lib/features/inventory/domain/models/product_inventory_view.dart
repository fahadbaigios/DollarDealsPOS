import '../../../../database/app_database.dart';

/// Product with resolved category, supplier, and unit names for inventory display.
class ProductInventoryView {
  const ProductInventoryView({
    required this.product,
    required this.categoryName,
    this.supplierName,
    required this.unitName,
  });

  final Product product;
  final String categoryName;
  final String? supplierName;
  final String unitName;

  String get stockStatus {
    if (product.stockQuantity <= 0) return 'out_of_stock';
    if (product.reorderLevel > 0 && product.stockQuantity <= product.reorderLevel) {
      return 'low_stock';
    }
    return 'normal';
  }
}
