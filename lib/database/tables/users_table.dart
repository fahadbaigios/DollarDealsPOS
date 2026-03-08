import 'package:drift/drift.dart';

import 'roles_table.dart';

class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get roleId => integer().references(Roles, #id)();
  TextColumn get username => text()();
  TextColumn get passwordHash => text()();
  TextColumn get fullName => text()();
  TextColumn get email => text().nullable()();
  TextColumn get phone => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
