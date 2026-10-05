import 'package:drift/drift.dart';

import 'sales_table.dart';

@TableIndex(name: 'idx_cash_drawer_movements_created_at', columns: {#createdAt})
@TableIndex(
  name: 'idx_cash_drawer_movements_sale_id',
  columns: {#saleId},
  unique: true,
)
class CashDrawerMovements extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get movementType => text()();
  IntColumn get amountMinor =>
      integer().customConstraint('NOT NULL CHECK (amount_minor > 0)')();
  IntColumn get saleId => integer().nullable().references(Sales, #id)();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
