import '../../../../database/app_database.dart';

/// Aggregated data for receipt/invoice PDF generation.
class SalePrintData {
  const SalePrintData({
    required this.sale,
    required this.items,
    required this.itemProductNames,
    this.customer,
    this.cashier,
    this.paymentMethod,
    required this.businessSettings,
    this.receipt,
  });

  final Sale sale;
  final List<SaleItem> items;
  final Map<int, String> itemProductNames;
  final Customer? customer;
  final User? cashier;
  final PaymentMethod? paymentMethod;
  final BusinessSettingsMap businessSettings;
  final Receipt? receipt;
}

/// Business settings as a typed map for PDF templates.
class BusinessSettingsMap {
  const BusinessSettingsMap({
    this.businessName = 'My Store',
    this.address = '',
    this.phone = '',
    this.email = '',
    this.ntmOrTaxNumber = '',
    this.currencyCode = 'USD',
    this.currencySymbol = '\$',
    this.receiptFooter = 'Thank you for your business!',
    this.logoPath,
  });

  final String businessName;
  final String address;
  final String phone;
  final String email;
  final String ntmOrTaxNumber;
  final String currencyCode;
  final String currencySymbol;
  final String receiptFooter;
  final String? logoPath;

  factory BusinessSettingsMap.fromDbMap(Map<String, String> map) {
    return BusinessSettingsMap(
      businessName: map['business_name'] ?? 'My Store',
      address: map['address'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
      ntmOrTaxNumber: map['ntm_or_tax_number'] ?? '',
      currencyCode: map['currency_code'] ?? 'USD',
      currencySymbol: map['currency_symbol'] ?? '\$',
      receiptFooter: map['receipt_footer'] ?? 'Thank you for your business!',
      logoPath: map['logo_path'],
    );
  }
}
