import '../../../../database/app_database.dart';

/// Export-ready sales report row.
class SalesReportRow {
  const SalesReportRow({
    required this.sale,
    this.customerName,
    this.cashierName,
  });

  final Sale sale;
  final String? customerName;
  final String? cashierName;

  String get invoiceNumber => sale.invoiceNumber;
  DateTime get date => sale.saleDate;
  double get subtotal => sale.subtotal;
  double get discount => sale.discountAmount;
  double get tax => sale.taxAmount;
  double get total => sale.totalAmount;
  double get paid => sale.paidAmount;
  double get due => sale.dueAmount;
  String get paymentStatus => sale.paymentStatus;
}
