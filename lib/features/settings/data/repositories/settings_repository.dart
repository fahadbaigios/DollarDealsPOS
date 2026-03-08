import 'package:drift/drift.dart';

import '../../../../database/app_database.dart';
import '../../../printing/data/repositories/business_settings_repository.dart';
import '../../domain/models/business_profile_settings.dart';
import '../../domain/models/system_preferences.dart';

/// Central repository for settings.
class SettingsRepository {
  SettingsRepository(this._db, this._businessSettingsRepo);

  final AppDatabase _db;
  final BusinessSettingsRepository _businessSettingsRepo;

  Future<BusinessProfileSettings> getBusinessProfile() async {
    final map = await _businessSettingsRepo.getAllAsMap();
    return BusinessProfileSettings(
      businessName: map['business_name'] ?? 'My Store',
      address: map['address'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
      ntmOrTaxNumber: map['ntm_or_tax_number'] ?? '',
      currencyCode: map['currency_code'] ?? 'USD',
      currencySymbol: map['currency_symbol'] ?? '\$',
      receiptFooter: map['receipt_footer'] ?? 'Thank you for your business!',
      logoPath: map['logo_path'],
      taxEnabled: (map['tax_enabled'] ?? 'false') == 'true',
      defaultTaxRate: double.tryParse(map['default_tax_rate'] ?? '0') ?? 0,
    );
  }

  Future<void> saveBusinessProfile(BusinessProfileSettings s) async {
    await _businessSettingsRepo.setAll({
      'business_name': s.businessName,
      'address': s.address,
      'phone': s.phone,
      'email': s.email,
      'ntm_or_tax_number': s.ntmOrTaxNumber,
      'currency_code': s.currencyCode,
      'currency_symbol': s.currencySymbol,
      'receipt_footer': s.receiptFooter,
      if (s.logoPath != null) 'logo_path': s.logoPath!,
      'tax_enabled': s.taxEnabled.toString(),
      'default_tax_rate': s.defaultTaxRate.toString(),
    });
  }

  Future<SystemPreferences> getSystemPreferences() async {
    final map = await _businessSettingsRepo.getAllAsMap();
    return SystemPreferences(
      allowNegativeStock: (map['app_allow_negative_stock'] ?? 'false') == 'true',
      autoPrintAfterSale: (map['app_auto_print_after_sale'] ?? 'false') == 'true',
      confirmBeforeCompletingSale:
          (map['app_confirm_before_sale'] ?? 'false') == 'true',
      showPhoneOnReceipt: (map['receipt_show_phone'] ?? 'true') == 'true',
      showTaxNumberOnReceipt: (map['receipt_show_tax_number'] ?? 'true') == 'true',
    );
  }

  Future<void> saveSystemPreferences(SystemPreferences p) async {
    await _businessSettingsRepo.setAll({
      'app_allow_negative_stock': p.allowNegativeStock.toString(),
      'app_auto_print_after_sale': p.autoPrintAfterSale.toString(),
      'app_confirm_before_sale': p.confirmBeforeCompletingSale.toString(),
      'receipt_show_phone': p.showPhoneOnReceipt.toString(),
      'receipt_show_tax_number': p.showTaxNumberOnReceipt.toString(),
    });
  }

  Future<PrinterSetting?> getDefaultPrinter() async {
    return (_db.select(_db.printerSettings)
          ..where((t) => t.isDefault.equals(true))
          ..limit(1))
        .getSingleOrNull();
  }

  Future<List<PrinterSetting>> getAllPrinters() async {
    return (_db.select(_db.printerSettings)
          ..orderBy([(t) => OrderingTerm.desc(t.isDefault), (t) => OrderingTerm.asc(t.id)]))
        .get();
  }

  Future<PrinterSetting?> getPrinterById(int id) async {
    return (_db.select(_db.printerSettings)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<int> savePrinter({
    required String printerName,
    required String printerType,
    required double paperWidth,
    required bool isDefault,
    required int copies,
    int? id,
  }) async {
    if (isDefault) {
      await (_db.update(_db.printerSettings)
            ..where((t) => t.isDefault.equals(true)))
          .write(const PrinterSettingsCompanion(isDefault: Value(false)));
    }
    if (id != null) {
      final existing = await getPrinterById(id);
      if (existing != null) {
        await _db.update(_db.printerSettings).replace(
              existing.copyWith(
                printerName: printerName,
                printerType: printerType,
                paperWidth: paperWidth,
                isDefault: isDefault,
                copies: copies,
                updatedAt: DateTime.now(),
              ).toCompanion(true),
            );
        return id;
      }
    }
    return _db.into(_db.printerSettings).insert(
          PrinterSettingsCompanion.insert(
            printerName: printerName,
            printerType: printerType,
            paperWidth: paperWidth,
            isDefault: Value(isDefault),
            copies: Value(copies),
          ),
        );
  }

  Future<void> deletePrinter(int id) async {
    await (_db.delete(_db.printerSettings)..where((t) => t.id.equals(id))).go();
  }
}
