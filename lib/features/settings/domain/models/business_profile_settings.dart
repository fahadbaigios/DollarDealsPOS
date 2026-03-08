/// Business profile settings for forms.
class BusinessProfileSettings {
  const BusinessProfileSettings({
    this.businessName = '',
    this.address = '',
    this.phone = '',
    this.email = '',
    this.ntmOrTaxNumber = '',
    this.currencyCode = 'USD',
    this.currencySymbol = '\$',
    this.receiptFooter = '',
    this.logoPath,
    this.taxEnabled = false,
    this.defaultTaxRate = 0,
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
  final bool taxEnabled;
  final double defaultTaxRate;

  BusinessProfileSettings copyWith({
    String? businessName,
    String? address,
    String? phone,
    String? email,
    String? ntmOrTaxNumber,
    String? currencyCode,
    String? currencySymbol,
    String? receiptFooter,
    String? logoPath,
    bool? taxEnabled,
    double? defaultTaxRate,
  }) {
    return BusinessProfileSettings(
      businessName: businessName ?? this.businessName,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      ntmOrTaxNumber: ntmOrTaxNumber ?? this.ntmOrTaxNumber,
      currencyCode: currencyCode ?? this.currencyCode,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      receiptFooter: receiptFooter ?? this.receiptFooter,
      logoPath: logoPath ?? this.logoPath,
      taxEnabled: taxEnabled ?? this.taxEnabled,
      defaultTaxRate: defaultTaxRate ?? this.defaultTaxRate,
    );
  }
}
