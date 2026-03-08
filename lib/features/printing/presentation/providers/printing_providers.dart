import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../database/app_database.dart';
import '../../../../core/services/database_provider.dart';
import '../../data/repositories/business_settings_repository.dart';
import '../../data/repositories/receipts_repository.dart';
import '../../domain/services/print_service.dart';
import '../../domain/services/receipt_pdf_service.dart';
import '../../domain/services/sale_print_data_service.dart';

final businessSettingsRepositoryProvider = Provider<BusinessSettingsRepository>((ref) {
  return BusinessSettingsRepository(ref.watch(databaseProvider));
});

final receiptsRepositoryProvider = Provider<ReceiptsRepository>((ref) {
  return ReceiptsRepository(ref.watch(databaseProvider));
});

final salePrintDataServiceProvider = Provider<SalePrintDataService>((ref) {
  return SalePrintDataService(
    ref.watch(databaseProvider),
    ref.watch(businessSettingsRepositoryProvider),
    ref.watch(receiptsRepositoryProvider),
  );
});

final receiptPdfServiceProvider = Provider<ReceiptPdfService>((ref) {
  final printDataService = ref.watch(salePrintDataServiceProvider);
  return ReceiptPdfService((saleId) => printDataService.getSalePrintData(saleId));
});

final printServiceProvider = Provider<PrintService>((ref) {
  final pdfService = ref.watch(receiptPdfServiceProvider);
  return PrintService(
    pdfService.generateThermalReceiptPdf,
    pdfService.generateA4InvoicePdf,
  );
});

final receiptForSaleProvider =
    FutureProvider.autoDispose.family<Receipt?, int>((ref, saleId) async {
  return ref.watch(receiptsRepositoryProvider).getBySaleId(saleId);
});
