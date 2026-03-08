import '../../../../database/app_database.dart';

/// Export-ready purchase report row.
class PurchaseReportRow {
  const PurchaseReportRow({
    required this.purchase,
    this.supplierName,
    this.createdByName,
  });

  final Purchase purchase;
  final String? supplierName;
  final String? createdByName;

  String? get invoiceNumber => purchase.invoiceNumber;
  DateTime get date => purchase.purchaseDate;
  double get subtotal => purchase.subtotal;
  double get discount => purchase.discountAmount;
  double get tax => purchase.taxAmount;
  double get total => purchase.totalAmount;
  double get paid => purchase.paidAmount;
  double get due => purchase.dueAmount;
  String get paymentStatus => purchase.paymentStatus;
}
