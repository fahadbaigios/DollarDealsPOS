import 'inventory_report_row.dart';

/// Inventory report with rows and summary.
class InventoryReportResult {
  const InventoryReportResult({
    required this.rows,
    required this.totalProducts,
    required this.totalStockQuantity,
    required this.totalStockValueAtCost,
    required this.totalStockValueAtSelling,
    required this.lowStockCount,
    required this.outOfStockCount,
  });

  final List<InventoryReportRow> rows;
  final int totalProducts;
  final double totalStockQuantity;
  final double totalStockValueAtCost;
  final double totalStockValueAtSelling;
  final int lowStockCount;
  final int outOfStockCount;
}
