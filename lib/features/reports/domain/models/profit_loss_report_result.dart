import '../../../dashboard/domain/models/profit_loss_summary.dart';

/// Profit/Loss report with summary and optional details.
class ProfitLossReportResult {
  const ProfitLossReportResult({
    required this.summary,
    this.topSellingProducts = const [],
    this.expenseByCategory = const {},
  });

  final ProfitLossSummary summary;
  final List<({int productId, String name, double quantity, double revenue})>
      topSellingProducts;
  final Map<String, double> expenseByCategory;
}
