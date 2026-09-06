import 'package:drift/drift.dart';

import 'expense_categories_table.dart';
import 'payment_methods_table.dart';
import 'users_table.dart';

@TableIndex(name: 'idx_expenses_expense_date', columns: {#expenseDate})
class Expenses extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withDefault(const Constant('Expense'))();
  IntColumn get expenseCategoryId => integer().references(ExpenseCategories, #id)();
  RealColumn get amount => real()();
  DateTimeColumn get expenseDate => dateTime()();
  IntColumn get paymentMethodId => integer().nullable().references(PaymentMethods, #id)();
  TextColumn get referenceNumber => text().nullable()();
  TextColumn get description => text().nullable()();
  TextColumn get notes => text().nullable()();
  IntColumn get createdBy => integer().nullable().references(Users, #id)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
