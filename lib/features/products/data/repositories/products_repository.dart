import 'package:drift/drift.dart';

import '../../../../database/app_database.dart';

class ProductsRepository {
  ProductsRepository(this._db);

  final AppDatabase _db;

  Stream<List<Product>> watchAll() {
    return (_db.select(_db.products)..orderBy([(t) => OrderingTerm.asc(t.name)])).watch();
  }

  Stream<List<Product>> watchFiltered({
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

  Future<List<Product>> getAll() async {
    return (_db.select(_db.products)..orderBy([(t) => OrderingTerm.asc(t.name)])).get();
  }

  Future<Product?> getById(int id) async {
    return (_db.select(_db.products)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<Product?> getBySku(String sku, {int? excludeId}) async {
    final s = sku.trim().toLowerCase();
    return (_db.select(_db.products)
          ..where((t) => t.sku.lower().equals(s) & (excludeId == null ? const Constant(true) : t.id.isNotValue(excludeId))))
        .getSingleOrNull();
  }

  /// Exact barcode match. Returns active product only, or null if not found/inactive.
  Future<Product?> getProductByBarcode(String barcode) async {
    final b = barcode.trim();
    if (b.isEmpty) return null;
    final product = await (_db.select(_db.products)
          ..where((t) => t.barcode.equals(b)))
        .getSingleOrNull();
    if (product == null || !product.isActive) return null;
    return product;
  }

  Future<int> create({
    required String name,
    required String sku,
    String? barcode,
    required int categoryId,
    int? supplierId,
    required int unitId,
    String? description,
    required double costPrice,
    required double salePrice,
    double taxRate = 0,
    double stockQuantity = 0,
    double reorderLevel = 0,
  }) async {
    return _db.into(_db.products).insert(
          ProductsCompanion.insert(
            name: name,
            sku: sku,
            barcode: Value(barcode),
            categoryId: categoryId,
            supplierId: Value(supplierId),
            unitId: unitId,
            description: Value(description),
            costPrice: Value(costPrice),
            salePrice: Value(salePrice),
            taxRate: Value(taxRate),
            stockQuantity: Value(stockQuantity),
            reorderLevel: Value(reorderLevel),
          ),
        );
  }

  Future<bool> update({
    required int id,
    required String name,
    required String sku,
    String? barcode,
    required int categoryId,
    int? supplierId,
    required int unitId,
    String? description,
    required double costPrice,
    required double salePrice,
    double taxRate = 0,
    double reorderLevel = 0,
    bool? isActive,
  }) async {
    final existing = await getById(id);
    if (existing == null) return false;

    return _db.update(_db.products).replace(
          ProductsCompanion(
            id: Value(id),
            name: Value(name),
            sku: Value(sku),
            barcode: Value(barcode),
            categoryId: Value(categoryId),
            supplierId: Value(supplierId),
            unitId: Value(unitId),
            description: Value(description),
            costPrice: Value(costPrice),
            salePrice: Value(salePrice),
            taxRate: Value(taxRate),
            stockQuantity: Value(existing.stockQuantity),
            reorderLevel: Value(reorderLevel),
            isActive: Value(isActive ?? existing.isActive),
            updatedAt: Value(DateTime.now()),
          ),
        );
  }

  Future<bool> setActiveStatus(int id, bool isActive) async {
    final existing = await getById(id);
    if (existing == null) return false;
    return _db.update(_db.products).replace(existing.copyWith(isActive: isActive).toCompanion(true));
  }
}
