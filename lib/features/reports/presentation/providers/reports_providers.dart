import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/database_provider.dart';
import '../../data/repositories/reports_repository.dart';
import '../../domain/models/expense_report_result.dart';
import '../../domain/models/inventory_report_result.dart';
import '../../domain/models/inventory_report_row.dart';
import '../../domain/models/profit_loss_report_result.dart';
import '../../domain/models/purchase_report_result.dart';
import '../../domain/models/report_date_range.dart';
import '../../domain/models/report_filter_state.dart';
import '../../domain/models/sales_report_result.dart';

final reportsRepositoryProvider = Provider<ReportsRepository>((ref) {
  return ReportsRepository(ref.watch(databaseProvider));
});

/// Shared report filter state - can be overridden per report type.
final reportFilterStateProvider =
    StateProvider.autoDispose<ReportFilterState>((ref) {
  return ReportFilterState(dateRange: ReportDateRange.thisMonth());
});

final reportFilterStateFamily =
    StateProvider.autoDispose.family<ReportFilterState, String>((ref, reportType) {
  return ReportFilterState(dateRange: ReportDateRange.thisMonth());
});

final salesReportProvider = FutureProvider.autoDispose<SalesReportResult>((ref) async {
  final repo = ref.watch(reportsRepositoryProvider);
  final filter = ref.watch(reportFilterStateProvider);
  return repo.getSalesReport(filter);
});

final purchaseReportProvider =
    FutureProvider.autoDispose<PurchaseReportResult>((ref) async {
  final repo = ref.watch(reportsRepositoryProvider);
  final filter = ref.watch(reportFilterStateProvider);
  return repo.getPurchaseReport(filter);
});

final inventoryReportProvider =
    FutureProvider.autoDispose<InventoryReportResult>((ref) async {
  final repo = ref.watch(reportsRepositoryProvider);
  final filter = ref.watch(reportFilterStateProvider);
  return repo.getInventoryReport(filter);
});

final lowStockReportProvider =
    FutureProvider.autoDispose<List<InventoryReportRow>>((ref) async {
  final repo = ref.watch(reportsRepositoryProvider);
  final filter = ref.watch(reportFilterStateProvider);
  return repo.getLowStockReport(filter);
});

final expenseReportProvider =
    FutureProvider.autoDispose<ExpenseReportResult>((ref) async {
  final repo = ref.watch(reportsRepositoryProvider);
  final filter = ref.watch(reportFilterStateProvider);
  return repo.getExpenseReport(filter);
});

final profitLossReportProvider =
    FutureProvider.autoDispose<ProfitLossReportResult>((ref) async {
  final repo = ref.watch(reportsRepositoryProvider);
  final filter = ref.watch(reportFilterStateProvider);
  return repo.getProfitLossReport(filter);
});

final reportUsersProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final repo = ref.watch(reportsRepositoryProvider);
  return repo.getUsersForFilter();
});

final reportCustomersProvider =
    FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final repo = ref.watch(reportsRepositoryProvider);
  return repo.getCustomersForFilter();
});

final reportSuppliersProvider =
    FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final repo = ref.watch(reportsRepositoryProvider);
  return repo.getSuppliersForFilter();
});

final reportCategoriesProvider =
    FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final repo = ref.watch(reportsRepositoryProvider);
  return repo.getCategoriesForFilter();
});

final reportExpenseCategoriesProvider =
    FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final repo = ref.watch(reportsRepositoryProvider);
  return repo.getExpenseCategoriesForFilter();
});
