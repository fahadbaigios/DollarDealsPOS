import 'package:drift/drift.dart';

import 'products_table.dart';

@TableIndex(name: 'idx_inventory_transactions_product_id', columns: {#productId})
class InventoryTransactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get productId => integer().references(Products, #id)();
  TextColumn get transactionType => text()();
  RealColumn get quantity => real()();
  RealColumn get unitCost => real().nullable()();
  TextColumn get referenceType => text().nullable()();
  IntColumn get referenceId => integer().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
