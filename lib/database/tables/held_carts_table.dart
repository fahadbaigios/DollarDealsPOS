import 'package:drift/drift.dart';

import 'customers_table.dart';
import 'payment_methods_table.dart';

/// A cart "put on hold" mid-sale (e.g. customer steps away to grab more
/// items) so the cashier can serve other customers in the meantime and
/// resume this cart later exactly where it left off.
class HeldCarts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get label => text().nullable()();
  IntColumn get customerId => integer().nullable().references(Customers, #id)();
  IntColumn get paymentMethodId => integer().nullable().references(PaymentMethods, #id)();
  RealColumn get orderDiscount => real().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
