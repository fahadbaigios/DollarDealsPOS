class CashDrawerSummary {
  const CashDrawerSummary({
    required this.balanceMinor,
    required this.todayCashSalesMinor,
    required this.todayCashInMinor,
    required this.todayCashOutMinor,
  });

  final int balanceMinor;
  final int todayCashSalesMinor;
  final int todayCashInMinor;
  final int todayCashOutMinor;

  int get suggestedCashOutMinor {
    final remainingSales = todayCashSalesMinor - todayCashOutMinor;
    if (remainingSales <= 0 || balanceMinor <= 0) return 0;
    return remainingSales > balanceMinor ? balanceMinor : remainingSales;
  }
}
