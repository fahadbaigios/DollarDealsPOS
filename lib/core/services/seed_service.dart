import 'package:drift/drift.dart';

import '../../database/app_database.dart';

/// Result of a seed operation.
class SeedResult {
  const SeedResult({
    required this.success,
    this.message,
    this.error,
  });

  final bool success;
  final String? message;
  final String? error;
}

/// Service for seeding initial and demo data.
/// Safe: only seeds when DB is empty or explicitly requested.
class SeedService {
  SeedService(this._db);

  final AppDatabase _db;

  /// Returns true if the database has no seed data (roles empty).
  Future<bool> isEmpty() async {
    final count = await _db.select(_db.roles).get();
    return count.isEmpty;
  }

  /// Seeds minimal initial data (roles, payment methods, expense categories,
  /// units, categories, default admin). Safe to call on empty DB.
  Future<SeedResult> seedInitialData() async {
    try {
      final empty = await isEmpty();
      if (!empty) {
        return const SeedResult(
          success: false,
          message: 'Database already has data. Use seedDemoData to add demo content.',
        );
      }
      await _db.batch((batch) {
        batch.insertAll(_db.roles, [
          RolesCompanion.insert(name: 'Admin', description: const Value('Full system access')),
          RolesCompanion.insert(name: 'Manager', description: const Value('Manage operations')),
          RolesCompanion.insert(name: 'Cashier', description: const Value('POS and sales')),
        ]);
        batch.insertAll(_db.paymentMethods, [
          PaymentMethodsCompanion.insert(name: 'Cash'),
          PaymentMethodsCompanion.insert(name: 'Card'),
          PaymentMethodsCompanion.insert(name: 'Bank Transfer'),
        ]);
        batch.insertAll(_db.expenseCategories, [
          ExpenseCategoriesCompanion.insert(name: 'Rent'),
          ExpenseCategoriesCompanion.insert(name: 'Utilities'),
          ExpenseCategoriesCompanion.insert(name: 'Salaries'),
          ExpenseCategoriesCompanion.insert(name: 'Miscellaneous'),
        ]);
        batch.insertAll(_db.units, [
          UnitsCompanion.insert(name: 'Piece', symbol: 'pc'),
          UnitsCompanion.insert(name: 'Kilogram', symbol: 'kg'),
          UnitsCompanion.insert(name: 'Liter', symbol: 'ltr'),
          UnitsCompanion.insert(name: 'Box', symbol: 'box'),
        ]);
        batch.insertAll(_db.categories, [
          CategoriesCompanion.insert(name: 'General', description: const Value('Default category')),
        ]);
        batch.insert(_db.users, UsersCompanion.insert(
          roleId: 1,
          username: 'admin',
          passwordHash: 'default',
          fullName: 'Admin',
        ));
      });
      return const SeedResult(success: true, message: 'Initial data seeded.');
    } catch (e) {
      return SeedResult(success: false, error: e.toString());
    }
  }

  /// Seeds demo data: sample categories, units, suppliers, customers, products.
  /// Only runs when DB already has initial data. Idempotent for demo entities.
  Future<SeedResult> seedDemoData() async {
    try {
      final empty = await isEmpty();
      if (empty) {
        return const SeedResult(
          success: false,
          message: 'Run seedInitialData first.',
        );
      }
      final existingProducts = await _db.select(_db.products).get();
      if (existingProducts.isNotEmpty) {
        return const SeedResult(
          success: false,
          message: 'Demo data already exists. Clear products first if you want to re-seed.',
        );
      }

      final categories = await _db.select(_db.categories).get();
      final units = await _db.select(_db.units).get();
      final catId = categories.isNotEmpty ? categories.first.id : 1;
      final unitId = units.isNotEmpty ? units.first.id : 1;

      await _db.transaction(() async {
        final supplierIds = <int>[];
        for (final s in _demoSuppliers) {
          final id = await _db.into(_db.suppliers).insert(
            SuppliersCompanion.insert(name: s),
          );
          supplierIds.add(id);
        }
        final customerIds = <int>[];
        for (final c in _demoCustomers) {
          final id = await _db.into(_db.customers).insert(
            CustomersCompanion.insert(name: c),
          );
          customerIds.add(id);
        }
        for (var i = 0; i < _demoProducts.length; i++) {
          final p = _demoProducts[i];
          await _db.into(_db.products).insert(
            ProductsCompanion.insert(
              name: p.name,
              sku: 'DEMO-${(i + 1).toString().padLeft(3, '0')}',
              categoryId: catId,
              unitId: unitId,
              costPrice: Value(p.cost),
              salePrice: Value(p.price),
              stockQuantity: Value(p.stock),
              reorderLevel: const Value(5),
              supplierId: Value(supplierIds[i % supplierIds.length]),
            ),
          );
        }
      });

      return const SeedResult(success: true, message: 'Demo data seeded.');
    } catch (e) {
      return SeedResult(success: false, error: e.toString());
    }
  }

  static const _demoSuppliers = [
    'ABC Wholesale',
    'Global Supplies Co',
    'Local Distributor',
  ];

  static const _demoCustomers = [
    'Walk-in Customer',
    'John Doe',
    'Jane Smith',
  ];

  static final _demoProducts = [
    _DemoProduct('Sample Product A', 0.50, 1.00, 100),
    _DemoProduct('Sample Product B', 0.75, 1.50, 50),
    _DemoProduct('Sample Product C', 1.00, 2.00, 25),
  ];
}

class _DemoProduct {
  _DemoProduct(this.name, this.cost, this.price, this.stock);
  final String name;
  final double cost;
  final double price;
  final double stock;
}
