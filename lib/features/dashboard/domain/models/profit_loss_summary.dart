/// Profit/Loss summary for a date range.
class ProfitLossSummary {
  const ProfitLossSummary({
    required this.revenue,
    required this.cogs,
    required this.grossProfit,
    required this.expenses,
    required this.netProfit,
    required this.from,
    required this.to,
  });

  final double revenue;
  final double cogs;
  final double grossProfit;
  final double expenses;
  final double netProfit;
  final DateTime from;
  final DateTime to;
}
