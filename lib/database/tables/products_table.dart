import 'package:drift/drift.dart';

import 'categories_table.dart';
import 'suppliers_table.dart';
import 'units_table.dart';

@TableIndex(name: 'idx_products_name', columns: {#name})
@TableIndex(name: 'idx_products_sku', columns: {#sku}, unique: true)
@TableIndex(name: 'idx_products_barcode', columns: {#barcode})
class Products extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get categoryId => integer().references(Categories, #id)();
  IntColumn get unitId => integer().references(Units, #id)();
  IntColumn get supplierId => integer().nullable().references(Suppliers, #id)();
  TextColumn get name => text()();
  TextColumn get sku => text()();
  TextColumn get barcode => text().nullable()();
  TextColumn get description => text().nullable()();
  RealColumn get costPrice => real().withDefault(const Constant(0))();
  RealColumn get salePrice => real().withDefault(const Constant(0))();
  RealColumn get taxRate => real().withDefault(const Constant(0))();
  RealColumn get stockQuantity => real().withDefault(const Constant(0))();
  RealColumn get reorderLevel => real().withDefault(const Constant(0))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
