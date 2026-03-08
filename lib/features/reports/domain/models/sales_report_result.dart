import 'sales_report_row.dart';

/// Sales report with rows and summary.
class SalesReportResult {
  const SalesReportResult({
    required this.rows,
    required this.totalCount,
    required this.totalRevenue,
    required this.totalDiscount,
    required this.totalTax,
    required this.totalDue,
  });

  final List<SalesReportRow> rows;
  final int totalCount;
  final double totalRevenue;
  final double totalDiscount;
  final double totalTax;
  final double totalDue;
}
