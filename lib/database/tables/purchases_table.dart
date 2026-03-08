import 'package:drift/drift.dart';

import 'suppliers_table.dart';
import 'users_table.dart';

@TableIndex(name: 'idx_purchases_purchase_date', columns: {#purchaseDate})
@TableIndex(name: 'idx_purchases_invoice_number', columns: {#invoiceNumber})
class Purchases extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get supplierId => integer().references(Suppliers, #id)();
  IntColumn get createdBy => integer().nullable().references(Users, #id)();
  TextColumn get invoiceNumber => text().nullable()();
  DateTimeColumn get purchaseDate => dateTime()();
  RealColumn get subtotal => real().withDefault(const Constant(0))();
  RealColumn get discountAmount => real().withDefault(const Constant(0))();
  RealColumn get taxAmount => real().withDefault(const Constant(0))();
  RealColumn get otherCharges => real().withDefault(const Constant(0))();
  RealColumn get totalAmount => real().withDefault(const Constant(0))();
  RealColumn get paidAmount => real().withDefault(const Constant(0))();
  RealColumn get dueAmount => real().withDefault(const Constant(0))();
  TextColumn get paymentStatus => text().withDefault(const Constant('unpaid'))();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
