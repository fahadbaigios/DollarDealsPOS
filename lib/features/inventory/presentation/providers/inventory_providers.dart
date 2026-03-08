import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/database_provider.dart';
import '../../../../database/app_database.dart';
import '../../data/repositories/inventory_repository.dart';
import '../../domain/models/product_inventory_view.dart';
import '../../domain/models/transaction_with_product.dart';
import '../../domain/services/stock_adjustment_service.dart';

final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  return InventoryRepository(ref.watch(databaseProvider));
});

final stockAdjustmentServiceProvider = Provider<StockAdjustmentService>((ref) {
  return StockAdjustmentService(ref.watch(databaseProvider));
});

// Overview filters
final inventorySearchQueryProvider = StateProvider<String>((ref) => '');
final inventoryCategoryFilterProvider = StateProvider<int?>((ref) => null);
final inventoryActiveFilterProvider = StateProvider<bool?>((ref) => null);
final inventoryStockStatusFilterProvider = StateProvider<String?>((ref) => null);

final inventoryOverviewStreamProvider =
    StreamProvider.autoDispose<List<ProductInventoryView>>((ref) {
  final repo = ref.watch(inventoryRepositoryProvider);
  final search = ref.watch(inventorySearchQueryProvider);
  final categoryId = ref.watch(inventoryCategoryFilterProvider);
  final isActive = ref.watch(inventoryActiveFilterProvider);
  final stockStatus = ref.watch(inventoryStockStatusFilterProvider);
  return repo.watchInventoryOverview(
    searchQuery: search.isEmpty ? null : search,
    categoryId: categoryId,
    isActive: isActive,
    stockStatusFilter: stockStatus,
  );
});

final lowStockSearchQueryProvider = StateProvider<String>((ref) => '');

final lowStockStreamProvider =
    StreamProvider.autoDispose<List<ProductInventoryView>>((ref) {
  final repo = ref.watch(inventoryRepositoryProvider);
  final search = ref.watch(lowStockSearchQueryProvider);
  return repo.watchLowStockAndOutOfStock(
    searchQuery: search.isEmpty ? null : search,
  );
});

// Transaction history filters
final transactionsProductFilterProvider = StateProvider<int?>((ref) => null);
final transactionsTypeFilterProvider = StateProvider<String?>((ref) => null);
final transactionsDateFromProvider = StateProvider<DateTime?>((ref) => null);
final transactionsDateToProvider = StateProvider<DateTime?>((ref) => null);

final inventoryTransactionsStreamProvider =
    StreamProvider.autoDispose<List<TransactionWithProduct>>((ref) {
  final repo = ref.watch(inventoryRepositoryProvider);
  final productId = ref.watch(transactionsProductFilterProvider);
  final type = ref.watch(transactionsTypeFilterProvider);
  final from = ref.watch(transactionsDateFromProvider);
  final to = ref.watch(transactionsDateToProvider);
  return repo.watchInventoryTransactions(
    productId: productId,
    transactionType: type,
    from: from,
    to: to,
  );
});

final productInventoryDetailProvider =
    FutureProvider.autoDispose.family<ProductInventoryView?, int>((ref, id) {
  return ref.watch(inventoryRepositoryProvider).getProductInventoryDetail(id);
});

final productRecentTransactionsProvider =
    FutureProvider.autoDispose.family<List<InventoryTransaction>, int>(
        (ref, productId) {
  return ref
      .watch(inventoryRepositoryProvider)
      .getRecentTransactionsForProduct(productId);
});

// Summary counts
final inventorySummaryProvider = FutureProvider.autoDispose<InventorySummary>(
    (ref) async {
  final repo = ref.watch(inventoryRepositoryProvider);
  final total = await repo.getTotalProductsCount();
  final lowStock = await repo.getLowStockCount();
  final outOfStock = await repo.getOutOfStockCount();
  return InventorySummary(
    totalProducts: total,
    lowStockCount: lowStock,
    outOfStockCount: outOfStock,
  );
});

class InventorySummary {
  const InventorySummary({
    required this.totalProducts,
    required this.lowStockCount,
    required this.outOfStockCount,
  });

  final int totalProducts;
  final int lowStockCount;
  final int outOfStockCount;
}

// For stock adjustment dialog - product selection
final stockAdjustmentProductIdProvider = StateProvider<int?>((ref) => null);
