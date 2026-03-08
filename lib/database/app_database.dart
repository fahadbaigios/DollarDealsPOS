import 'package:drift/drift.dart';

import 'database_connection.dart';
import 'tables/business_settings_table.dart';
import 'tables/printer_settings_table.dart';
import 'tables/categories_table.dart';
import 'tables/customers_table.dart';
import 'tables/expense_categories_table.dart';
import 'tables/expenses_table.dart';
import 'tables/inventory_transactions_table.dart';
import 'tables/payment_methods_table.dart';
import 'tables/products_table.dart';
import 'tables/purchase_items_table.dart';
import 'tables/purchases_table.dart';
import 'tables/receipts_table.dart';
import 'tables/roles_table.dart';
import 'tables/sale_items_table.dart';
import 'tables/sales_table.dart';
import 'tables/suppliers_table.dart';
import 'tables/units_table.dart';
import 'tables/users_table.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Roles,
    Users,
    Categories,
    Units,
    Suppliers,
    Customers,
    Products,
    PaymentMethods,
    ExpenseCategories,
    Purchases,
    PurchaseItems,
    Sales,
    SaleItems,
    InventoryTransactions,
    Expenses,
    Receipts,
    BusinessSettings,
    PrinterSettings,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(createDatabaseConnection());

  @override
  int get schemaVersion => 7;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
          await _seedInitialData();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          if (from < 2) {
            await m.addColumn(categories, categories.isActive);
            await m.addColumn(products, products.taxRate);
          }
          if (from < 3) {
            await m.addColumn(purchases, purchases.createdBy);
            await m.addColumn(purchases, purchases.subtotal);
            await m.addColumn(purchases, purchases.discountAmount);
            await m.addColumn(purchases, purchases.otherCharges);
            await m.addColumn(purchases, purchases.paidAmount);
            await m.addColumn(purchases, purchases.dueAmount);
            await m.addColumn(purchases, purchases.paymentStatus);
            await m.addColumn(purchaseItems, purchaseItems.itemDiscount);
            await m.addColumn(purchaseItems, purchaseItems.itemTax);
          }
          if (from < 4) {
            await m.addColumn(sales, sales.paidAmount);
            await m.addColumn(sales, sales.dueAmount);
            await m.addColumn(sales, sales.paymentStatus);
            await m.addColumn(saleItems, saleItems.itemDiscount);
            await m.addColumn(saleItems, saleItems.itemTax);
          }
          if (from < 5) {
            await m.addColumn(receipts, receipts.printedCount);
            await m.addColumn(receipts, receipts.lastPrintedAt);
          }
          if (from < 6) {
            await m.addColumn(expenses, expenses.title);
            await m.addColumn(expenses, expenses.paymentMethodId);
            await m.addColumn(expenses, expenses.notes);
            await m.addColumn(expenses, expenses.createdBy);
            // description already exists in v1-v5
          }
          if (from < 7) {
            await m.createTable(printerSettings);
          }
        },
      );

  /// Seeds default roles, payment methods, and expense categories.
  Future<void> _seedInitialData() async {
    await batch((batch) {
      batch.insertAll(roles, [
        RolesCompanion.insert(name: 'Admin', description: const Value('Full system access')),
        RolesCompanion.insert(name: 'Manager', description: const Value('Manage operations')),
        RolesCompanion.insert(name: 'Cashier', description: const Value('POS and sales')),
      ]);

      batch.insertAll(paymentMethods, [
        PaymentMethodsCompanion.insert(name: 'Cash'),
        PaymentMethodsCompanion.insert(name: 'Card'),
        PaymentMethodsCompanion.insert(name: 'Bank Transfer'),
      ]);

      batch.insertAll(expenseCategories, [
        ExpenseCategoriesCompanion.insert(name: 'Rent'),
        ExpenseCategoriesCompanion.insert(name: 'Utilities'),
        ExpenseCategoriesCompanion.insert(name: 'Salaries'),
        ExpenseCategoriesCompanion.insert(name: 'Miscellaneous'),
      ]);

      batch.insertAll(units, [
        UnitsCompanion.insert(name: 'Piece', symbol: 'pc'),
        UnitsCompanion.insert(name: 'Kilogram', symbol: 'kg'),
        UnitsCompanion.insert(name: 'Liter', symbol: 'ltr'),
        UnitsCompanion.insert(name: 'Box', symbol: 'box'),
      ]);

      batch.insertAll(categories, [
        CategoriesCompanion.insert(name: 'General', description: const Value('Default category')),
      ]);

      batch.insert(users, UsersCompanion.insert(
        roleId: 1,
        username: 'admin',
        passwordHash: 'default',
        fullName: 'Admin',
      ));
    });
  }

  /// Call to seed initial data on existing database (e.g. after manual migration).
  Future<void> seedInitialDataIfEmpty() async {
    final roleCount = await select(roles).get();
    if (roleCount.isEmpty) {
      await _seedInitialData();
    }
  }
}
