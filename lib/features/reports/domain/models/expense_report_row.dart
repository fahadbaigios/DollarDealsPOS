import '../../../../database/app_database.dart';

/// Export-ready expense report row.
class ExpenseReportRow {
  const ExpenseReportRow({
    required this.expense,
    this.categoryName = '—',
    this.paymentMethodName,
  });

  final Expense expense;
  final String categoryName;
  final String? paymentMethodName;

  DateTime get date => expense.expenseDate;
  String get title => expense.title;
  double get amount => expense.amount;
  String? get referenceNumber => expense.referenceNumber;
}
