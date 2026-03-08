/// System behavior preferences.
class SystemPreferences {
  const SystemPreferences({
    this.allowNegativeStock = false,
    this.autoPrintAfterSale = false,
    this.confirmBeforeCompletingSale = false,
    this.showPhoneOnReceipt = true,
    this.showTaxNumberOnReceipt = true,
  });

  final bool allowNegativeStock;
  final bool autoPrintAfterSale;
  final bool confirmBeforeCompletingSale;
  final bool showPhoneOnReceipt;
  final bool showTaxNumberOnReceipt;

  SystemPreferences copyWith({
    bool? allowNegativeStock,
    bool? autoPrintAfterSale,
    bool? confirmBeforeCompletingSale,
    bool? showPhoneOnReceipt,
    bool? showTaxNumberOnReceipt,
  }) {
    return SystemPreferences(
      allowNegativeStock: allowNegativeStock ?? this.allowNegativeStock,
      autoPrintAfterSale: autoPrintAfterSale ?? this.autoPrintAfterSale,
      confirmBeforeCompletingSale:
          confirmBeforeCompletingSale ?? this.confirmBeforeCompletingSale,
      showPhoneOnReceipt: showPhoneOnReceipt ?? this.showPhoneOnReceipt,
      showTaxNumberOnReceipt:
          showTaxNumberOnReceipt ?? this.showTaxNumberOnReceipt,
    );
  }
}
