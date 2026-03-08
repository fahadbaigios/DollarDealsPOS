import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/database_provider.dart';
import '../../../../database/app_database.dart';
import '../../../products/presentation/providers/products_providers.dart';
import '../../data/repositories/purchases_repository.dart';
import '../../domain/models/purchase_item_input.dart';
import '../../domain/services/purchase_service.dart';

final purchasesRepositoryProvider = Provider<PurchasesRepository>((ref) {
  return PurchasesRepository(ref.watch(databaseProvider));
});

final purchaseServiceProvider = Provider<PurchaseService>((ref) {
  return PurchaseService(
    ref.watch(databaseProvider),
    ref.watch(purchasesRepositoryProvider),
  );
});

final purchasesSearchQueryProvider = StateProvider<String>((ref) => '');
final purchasesDateFromProvider = StateProvider<DateTime?>((ref) => null);
final purchasesDateToProvider = StateProvider<DateTime?>((ref) => null);

final purchasesStreamProvider = StreamProvider.autoDispose<List<Purchase>>((ref) {
  final repo = ref.watch(purchasesRepositoryProvider);
  final query = ref.watch(purchasesSearchQueryProvider);
  final from = ref.watch(purchasesDateFromProvider);
  final to = ref.watch(purchasesDateToProvider);
  return repo.search(query, from: from, to: to);
});

final purchaseDetailProvider =
    FutureProvider.autoDispose.family<Purchase?, int>((ref, id) async {
  return ref.watch(purchasesRepositoryProvider).getById(id);
});

final purchaseItemsProvider =
    FutureProvider.autoDispose.family<List<PurchaseItem>, int>((ref, purchaseId) async {
  return ref.watch(purchasesRepositoryProvider).getPurchaseItems(purchaseId);
});

final activeSuppliersProvider = FutureProvider.autoDispose<List<Supplier>>((ref) async {
  final suppliers = await ref.watch(suppliersRepositoryProvider).getAll();
  return suppliers.where((s) => s.isActive).toList();
});

final activeProductsProvider = FutureProvider.autoDispose<List<Product>>((ref) async {
  final products = await ref.watch(productsRepositoryProvider).getAll();
  return products.where((p) => p.isActive).toList();
});

final createPurchaseItemsProvider =
    StateProvider<List<PurchaseItemInput>>((ref) => []);
