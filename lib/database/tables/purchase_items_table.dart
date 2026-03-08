import 'package:drift/drift.dart';

import 'products_table.dart';
import 'purchases_table.dart';

class PurchaseItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get purchaseId => integer().references(Purchases, #id)();
  IntColumn get productId => integer().references(Products, #id)();
  RealColumn get quantity => real()();
  RealColumn get unitCost => real()();
  RealColumn get itemDiscount => real().withDefault(const Constant(0))();
  RealColumn get itemTax => real().withDefault(const Constant(0))();
  RealColumn get totalCost => real()();
}
