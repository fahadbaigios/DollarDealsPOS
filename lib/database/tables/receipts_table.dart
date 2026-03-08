import 'package:drift/drift.dart';

import 'sales_table.dart';

class Receipts extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get saleId => integer().references(Sales, #id)();
  TextColumn get receiptContent => text()();
  IntColumn get printedCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get printedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get lastPrintedAt => dateTime().nullable()();
}
