import 'package:drift/drift.dart';

import 'products_table.dart';
import 'sales_table.dart';

class SaleItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get saleId => integer().references(Sales, #id)();
  IntColumn get productId => integer().references(Products, #id)();
  RealColumn get quantity => real()();
  RealColumn get unitCost => real()();
  RealColumn get unitPrice => real()();
  RealColumn get itemDiscount => real().withDefault(const Constant(0))();
  RealColumn get itemTax => real().withDefault(const Constant(0))();
  RealColumn get totalAmount => real()();
}
