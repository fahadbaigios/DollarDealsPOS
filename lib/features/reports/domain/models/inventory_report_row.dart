import '../../../../database/app_database.dart';

/// Export-ready inventory report row.
class InventoryReportRow {
  const InventoryReportRow({
    required this.product,
    this.categoryName = '—',
    this.supplierName,
    this.unitName = '—',
  });

  final Product product;
  final String categoryName;
  final String? supplierName;
  final String unitName;

  String get name => product.name;
  String get sku => product.sku;
  String? get barcode => product.barcode;
  double get stockQuantity => product.stockQuantity;
  double get reorderLevel => product.reorderLevel;
  double get costPrice => product.costPrice;
  double get salePrice => product.salePrice;
  bool get isActive => product.isActive;

  double get stockValueAtCost => product.stockQuantity * product.costPrice;
  double get stockValueAtSelling => product.stockQuantity * product.salePrice;

  String get stockStatus {
    if (product.stockQuantity <= 0) return 'Out of Stock';
    if (product.reorderLevel > 0 &&
        product.stockQuantity <= product.reorderLevel) {
      return 'Low Stock';
    }
    return 'Normal';
  }
}
