import 'purchase_report_row.dart';

/// Purchase report with rows and summary.
class PurchaseReportResult {
  const PurchaseReportResult({
    required this.rows,
    required this.totalCount,
    required this.totalValue,
    required this.totalPaid,
    required this.totalDue,
  });

  final List<PurchaseReportRow> rows;
  final int totalCount;
  final double totalValue;
  final double totalPaid;
  final double totalDue;
}
