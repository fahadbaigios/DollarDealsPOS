import 'package:drift/drift.dart';

import 'customers_table.dart';
import 'payment_methods_table.dart';
import 'users_table.dart';

@TableIndex(name: 'idx_sales_sale_date', columns: {#saleDate})
@TableIndex(name: 'idx_sales_invoice_number', columns: {#invoiceNumber}, unique: true)
class Sales extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get cashierId => integer().references(Users, #id)();
  IntColumn get paymentMethodId => integer().nullable().references(PaymentMethods, #id)();
  IntColumn get customerId => integer().nullable().references(Customers, #id)();
  TextColumn get invoiceNumber => text()();
  DateTimeColumn get saleDate => dateTime()();
  RealColumn get subtotal => real().withDefault(const Constant(0))();
  RealColumn get taxAmount => real().withDefault(const Constant(0))();
  RealColumn get discountAmount => real().withDefault(const Constant(0))();
  RealColumn get totalAmount => real().withDefault(const Constant(0))();
  RealColumn get paidAmount => real().withDefault(const Constant(0))();
  RealColumn get dueAmount => real().withDefault(const Constant(0))();
  TextColumn get paymentStatus => text().withDefault(const Constant('unpaid'))();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
