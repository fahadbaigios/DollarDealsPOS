import 'package:drift/drift.dart';

import '../../../../database/app_database.dart';
import '../../domain/models/product_inventory_view.dart';
import '../../domain/models/transaction_with_product.dart';

class InventoryRepository {
  InventoryRepository(this._db);

  final AppDatabase _db;

  /// Watch all products with category, supplier, unit names for inventory overview.
  Stream<List<ProductInventoryView>> watchInventoryOverview({
    String? searchQuery,
    int? categoryId,
    bool? isActive,
    String? stockStatusFilter,
  }) async* {
    await for (final products in _watchProductsFiltered(
      searchQuery: searchQuery,
      categoryId: categoryId,
      isActive: isActive,
    )) {
      if (products.isEmpty) {
        yield [];
        continue;
      }
      final categories = await _db.select(_db.categories).get();
      final suppliers = await _db.select(_db.suppliers).get();
      final units = await _db.select(_db.units).get();
      final catMap = {for (final c in categories) c.id: c.name};
      final supMap = {for (final s in suppliers) s.id: s.name};
      final unitMap = {for (final u in units) u.id: u.name};

      var views = products.map((p) {
        final view = ProductInventoryView(
          product: p,
          categoryName: catMap[p.categoryId] ?? 'Unknown',
          supplierName: p.supplierId != null ? supMap[p.supplierId!] : null,
          unitName: unitMap[p.unitId] ?? 'Unknown',
        );
        return view;
      }).toList();

      if (stockStatusFilter != null && stockStatusFilter.isNotEmpty) {
        views = views.where((v) => v.stockStatus == stockStatusFilter).toList();
      }

      yield views;
    }
  }

  Stream<List<Product>> _watchProductsFiltered({
    String? searchQuery,
    int? categoryId,
    bool? isActive,
  }) {
    return (_db.select(_db.products)
          ..where((t) {
            Expression<bool> cond = const Constant(true);
            if (searchQuery != null && searchQuery.trim().isNotEmpty) {
              final q = searchQuery.trim().toLowerCase();
              cond = cond &
                  (t.name.lower().like('%$q%') |
                      t.sku.lower().like('%$q%') |
                      (t.barcode.isNotNull() & t.barcode.like('%$q%')));
            }
            if (categoryId != null) {
              cond = cond & t.categoryId.equals(categoryId);
            }
            if (isActive != null) {
              cond = cond & t.isActive.equals(isActive);
            }
            return cond;
          })
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .watch();
  }

  /// Watch products where stock_quantity <= reorder_level.
  Stream<List<ProductInventoryView>> watchLowStockProducts({
    String? searchQuery,
  }) async* {
    await for (final views in watchInventoryOverview(
      searchQuery: searchQuery,
      isActive: true,
      stockStatusFilter: 'low_stock',
    )) {
      yield views;
    }
  }

  /// Also include out-of-stock in low stock screen for daily review.
  Stream<List<ProductInventoryView>> watchLowStockAndOutOfStock({
    String? searchQuery,
  }) async* {
    await for (final products in _watchProductsFiltered(
      searchQuery: searchQuery,
      isActive: true,
    )) {
      if (products.isEmpty) {
        yield [];
        continue;
      }
      final categories = await _db.select(_db.categories).get();
      final suppliers = await _db.select(_db.suppliers).get();
      final units = await _db.select(_db.units).get();
      final catMap = {for (final c in categories) c.id: c.name};
      final supMap = {for (final s in suppliers) s.id: s.name};
      final unitMap = {for (final u in units) u.id: u.name};

      final views = products
          .where((p) =>
              p.stockQuantity <= 0 ||
              (p.reorderLevel > 0 && p.stockQuantity <= p.reorderLevel))
          .map((p) => ProductInventoryView(
                product: p,
                categoryName: catMap[p.categoryId] ?? 'Unknown',
                supplierName: p.supplierId != null ? supMap[p.supplierId!] : null,
                unitName: unitMap[p.unitId] ?? 'Unknown',
              ))
          .toList();

      yield views;
    }
  }

  /// Watch inventory transactions with product info.
  Stream<List<TransactionWithProduct>> watchInventoryTransactions({
    int? productId,
    String? transactionType,
    DateTime? from,
    DateTime? to,
  }) async* {
    await for (final rows in (_db.select(_db.inventoryTransactions)
          ..where((t) {
            Expression<bool> cond = const Constant(true);
            if (productId != null) {
              cond = cond & t.productId.equals(productId);
            }
            if (transactionType != null && transactionType.isNotEmpty) {
              cond = cond & t.transactionType.equals(transactionType);
            }
            if (from != null) {
              cond = cond & t.createdAt.isBiggerOrEqualValue(from);
            }
            if (to != null) {
              final end = DateTime(to.year, to.month, to.day, 23, 59, 59);
              cond = cond & t.createdAt.isSmallerOrEqualValue(end);
            }
            return cond;
          })
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch()) {
      if (rows.isEmpty) {
        yield [];
        continue;
      }
      final productIds = rows.map((r) => r.productId).toSet().toList();
      final products = await (_db.select(_db.products)
            ..where((t) => t.id.isIn(productIds)))
          .get();
      final productMap = {for (final p in products) p.id: p};

      yield rows.map((r) {
        final p = productMap[r.productId];
        return TransactionWithProduct(
          transaction: r,
          productName: p?.name ?? 'Unknown',
          productSku: p?.sku ?? '-',
        );
      }).toList();
    }
  }

  Future<Product?> getProductById(int id) async {
    return (_db.select(_db.products)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<ProductInventoryView?> getProductInventoryDetail(int productId) async {
    final product = await getProductById(productId);
    if (product == null) return null;

    final category = await (_db.select(_db.categories)
          ..where((t) => t.id.equals(product.categoryId)))
        .getSingleOrNull();
    final supplier = product.supplierId != null
        ? await (_db.select(_db.suppliers)
              ..where((t) => t.id.equals(product.supplierId!)))
            .getSingleOrNull()
        : null;
    final unit = await (_db.select(_db.units)
          ..where((t) => t.id.equals(product.unitId)))
        .getSingleOrNull();

    return ProductInventoryView(
      product: product,
      categoryName: category?.name ?? 'Unknown',
      supplierName: supplier?.name,
      unitName: unit?.name ?? 'Unknown',
    );
  }

  Future<List<InventoryTransaction>> getRecentTransactionsForProduct(
    int productId, {
    int limit = 20,
  }) async {
    return (_db.select(_db.inventoryTransactions)
          ..where((t) => t.productId.equals(productId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(limit))
        .get();
  }

  /// Count active products where stock <= reorder_level and stock > 0.
  Future<int> getLowStockCount() async {
    final products = await (_db.select(_db.products)
          ..where((t) => t.isActive.equals(true)))
        .get();
    return products
        .where((p) =>
            p.reorderLevel > 0 &&
            p.stockQuantity > 0 &&
            p.stockQuantity <= p.reorderLevel)
        .length;
  }

  Future<int> getOutOfStockCount() async {
    final list = await (_db.select(_db.products)
          ..where((t) =>
              t.isActive.equals(true) &
              t.stockQuantity.isSmallerOrEqualValue(0)))
        .get();
    return list.length;
  }

  Future<int> getTotalProductsCount() async {
    final list = await _db.select(_db.products).get();
    return list.length;
  }
}
