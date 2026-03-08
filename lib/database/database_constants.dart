/// Constants for database values (e.g. inventory transaction types).
class DatabaseConstants {
  DatabaseConstants._();

  static const String transactionTypePurchase = 'purchase';
  static const String transactionTypeSale = 'sale';
  static const String transactionTypeReturnIn = 'return_in';
  static const String transactionTypeReturnOut = 'return_out';
  static const String transactionTypeAdjustmentIn = 'adjustment_in';
  static const String transactionTypeAdjustmentOut = 'adjustment_out';

  static const String referenceTypePurchase = 'purchase';
  static const String referenceTypeSale = 'sale';
  static const String referenceTypeAdjustment = 'adjustment';

  static const String paymentStatusPaid = 'paid';
  static const String paymentStatusPartial = 'partial';
  static const String paymentStatusUnpaid = 'unpaid';
}
