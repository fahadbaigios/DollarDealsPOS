class PaymentMethodSalesSummary {
  const PaymentMethodSalesSummary({
    required this.paymentMethodId,
    required this.paymentMethodName,
    required this.total,
    required this.saleCount,
  });

  final int? paymentMethodId;
  final String paymentMethodName;
  final double total;
  final int saleCount;
}
