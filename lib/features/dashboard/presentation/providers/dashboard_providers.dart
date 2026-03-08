import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/database_provider.dart';
import '../../../../database/app_database.dart';
import '../../data/repositories/dashboard_repository.dart';
import '../../domain/models/profit_loss_summary.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(ref.watch(databaseProvider));
});

final todayProfitLossProvider = FutureProvider.autoDispose<ProfitLossSummary>((ref) {
  return ref.watch(dashboardRepositoryProvider).getTodayProfitLoss();
});

final monthlyProfitLossProvider = FutureProvider.autoDispose<ProfitLossSummary>((ref) {
  return ref.watch(dashboardRepositoryProvider).getMonthlyProfitLoss();
});

final todaySalesTotalProvider = FutureProvider.autoDispose<double>((ref) {
  return ref.watch(dashboardRepositoryProvider).getTodaySalesTotal();
});

final todayExpensesTotalProvider = FutureProvider.autoDispose<double>((ref) {
  return ref.watch(dashboardRepositoryProvider).getTodayExpensesTotal();
});

final monthlySalesTotalProvider = FutureProvider.autoDispose<double>((ref) {
  return ref.watch(dashboardRepositoryProvider).getMonthlySalesTotal();
});

final monthlyExpensesTotalProvider = FutureProvider.autoDispose<double>((ref) {
  return ref.watch(dashboardRepositoryProvider).getMonthlyExpensesTotal();
});

final lowStockCountProvider = FutureProvider.autoDispose<int>((ref) {
  return ref.watch(dashboardRepositoryProvider).getLowStockCount();
});

final outOfStockCountProvider = FutureProvider.autoDispose<int>((ref) {
  return ref.watch(dashboardRepositoryProvider).getOutOfStockCount();
});

final totalProductsCountProvider = FutureProvider.autoDispose<int>((ref) {
  return ref.watch(dashboardRepositoryProvider).getTotalProductsCount();
});

final recentSalesProvider = FutureProvider.autoDispose<List<Sale>>((ref) {
  return ref.watch(dashboardRepositoryProvider).getRecentSales(limit: 10);
});

final recentExpensesProvider = FutureProvider.autoDispose<List<Expense>>((ref) {
  return ref.watch(dashboardRepositoryProvider).getRecentExpenses(limit: 10);
});

final topSellingProductsProvider =
    FutureProvider.autoDispose<List<({int productId, String name, double quantity, double revenue})>>((ref) {
  return ref.watch(dashboardRepositoryProvider).getTopSellingProducts(limit: 10);
});

final lowStockProductsProvider = FutureProvider.autoDispose<List<Product>>((ref) {
  return ref.watch(dashboardRepositoryProvider).getLowStockProducts(limit: 10);
});
