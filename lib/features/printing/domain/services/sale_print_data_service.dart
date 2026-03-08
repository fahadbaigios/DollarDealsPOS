import '../../../../database/app_database.dart';
import '../../data/repositories/business_settings_repository.dart';
import '../../data/repositories/receipts_repository.dart';
import '../models/sale_print_data.dart';

class SalePrintDataService {
  SalePrintDataService(
    this._db,
    this._businessSettingsRepo,
    this._receiptsRepo,
  );

  final AppDatabase _db;
  final BusinessSettingsRepository _businessSettingsRepo;
  final ReceiptsRepository _receiptsRepo;

  Future<SalePrintData> getSalePrintData(int saleId) async {
    final sale = await (_db.select(_db.sales)
          ..where((t) => t.id.equals(saleId)))
        .getSingleOrNull();
    if (sale == null) {
      throw StateError('Sale not found');
    }

    final items = await (_db.select(_db.saleItems)
          ..where((t) => t.saleId.equals(saleId)))
        .get();

    final productIds = items.map((i) => i.productId).toSet().toList();
    final products = await (_db.select(_db.products)
          ..where((t) => t.id.isIn(productIds)))
        .get();
    final productNames = {for (final p in products) p.id: p.name};

    Customer? customer;
    if (sale.customerId != null) {
      customer = await (_db.select(_db.customers)
            ..where((t) => t.id.equals(sale.customerId!)))
          .getSingleOrNull();
    }

    User? cashier;
    cashier = await (_db.select(_db.users)
          ..where((t) => t.id.equals(sale.cashierId)))
        .getSingleOrNull();

    PaymentMethod? paymentMethod;
    if (sale.paymentMethodId != null) {
      paymentMethod = await (_db.select(_db.paymentMethods)
            ..where((t) => t.id.equals(sale.paymentMethodId!)))
          .getSingleOrNull();
    }

    final settingsMap = await _businessSettingsRepo.getAllAsMap();
    final businessSettings = BusinessSettingsMap.fromDbMap(settingsMap);

    final receipt = await _receiptsRepo.getBySaleId(saleId);

    return SalePrintData(
      sale: sale,
      items: items,
      itemProductNames: productNames,
      customer: customer,
      cashier: cashier,
      paymentMethod: paymentMethod,
      businessSettings: businessSettings,
      receipt: receipt,
    );
  }
}
