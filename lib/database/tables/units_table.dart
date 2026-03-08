import 'package:drift/drift.dart';

@TableIndex(name: 'idx_units_name', columns: {#name}, unique: true)
@TableIndex(name: 'idx_units_symbol', columns: {#symbol}, unique: true)
class Units extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get symbol => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
