import '../../../../database/app_database.dart';
import '../../../products/data/repositories/products_repository.dart';
import '../models/cart_item.dart';

/// Result of a barcode scan attempt. Caller adds to cart on success.
class BarcodeScanResult {
  const BarcodeScanResult({
    required this.success,
    this.product,
    this.error,
  });

  final bool success;
  final Product? product;
  final String? error;

  factory BarcodeScanResult.success(Product product) =>
      BarcodeScanResult(success: true, product: product);

  factory BarcodeScanResult.failure(String error) =>
      BarcodeScanResult(success: false, error: error);
}

/// Service for barcode-based POS scanning.
/// Handles product lookup, validation, and cart add logic.
class PosScannerService {
  PosScannerService(this._productsRepo);

  final ProductsRepository _productsRepo;

  /// Lookup sellable product by exact barcode.
  /// Returns null if not found or inactive.
  Future<Product?> getSellableProductByBarcode(String barcode) async {
    return _productsRepo.getProductByBarcode(barcode);
  }

  /// Handle barcode scan: lookup product, validate, return result for cart add.
  /// Does not modify cart; caller adds/increments based on result.
  Future<BarcodeScanResult> handleBarcodeScan(
    String barcode, {
    required List<CartItem> currentCart,
    required bool allowNegativeStock,
  }) async {
    final b = barcode.trim();
    if (b.isEmpty) {
      return BarcodeScanResult.failure('Enter or scan a barcode');
    }

    final product = await getSellableProductByBarcode(b);
    if (product == null) {
      final bySku = await _productsRepo.getBySku(b);
      if (bySku != null && bySku.isActive) {
        return BarcodeScanResult.success(bySku);
      }
      return BarcodeScanResult.failure('Product not found');
    }

    final existingQty = currentCart
        .where((i) => i.product.id == product.id)
        .fold<double>(0, (s, i) => s + i.quantity);
    final newQty = existingQty + 1;

    if (!allowNegativeStock && newQty > product.stockQuantity) {
      return BarcodeScanResult.failure(
        'Insufficient stock for ${product.name}. Available: ${product.stockQuantity.toStringAsFixed(0)}',
      );
    }

    return BarcodeScanResult.success(product);
  }
}
