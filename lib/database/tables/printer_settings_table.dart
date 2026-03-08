import 'package:drift/drift.dart';

class PrinterSettings extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get printerName => text()();
  TextColumn get printerType => text()(); // 'thermal' | 'a4'
  RealColumn get paperWidth => real()(); // mm
  BoolColumn get isDefault => boolean().withDefault(const Constant(true))();
  IntColumn get copies => integer().withDefault(const Constant(1))();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
