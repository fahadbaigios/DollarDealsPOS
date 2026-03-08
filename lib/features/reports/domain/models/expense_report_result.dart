import 'expense_report_row.dart';

/// Expense report with rows and summary.
class ExpenseReportResult {
  const ExpenseReportResult({
    required this.rows,
    required this.totalCount,
    required this.totalAmount,
    this.largestExpense,
    this.categoryTotals = const {},
  });

  final List<ExpenseReportRow> rows;
  final int totalCount;
  final double totalAmount;
  final double? largestExpense;
  final Map<String, double> categoryTotals;
}
