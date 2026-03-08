import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/database_provider.dart';
import '../../../../database/app_database.dart';
import '../../data/repositories/categories_repository.dart';
import '../../data/repositories/products_repository.dart';
import '../../data/repositories/suppliers_repository.dart';
import '../../data/repositories/units_repository.dart';

final categoriesRepositoryProvider = Provider<CategoriesRepository>((ref) {
  return CategoriesRepository(ref.watch(databaseProvider));
});

final unitsRepositoryProvider = Provider<UnitsRepository>((ref) {
  return UnitsRepository(ref.watch(databaseProvider));
});

final suppliersRepositoryProvider = Provider<SuppliersRepository>((ref) {
  return SuppliersRepository(ref.watch(databaseProvider));
});

final productsRepositoryProvider = Provider<ProductsRepository>((ref) {
  return ProductsRepository(ref.watch(databaseProvider));
});

final categoriesSearchQueryProvider = StateProvider<String>((ref) => '');

final categoriesStreamProvider = StreamProvider.autoDispose<List<Category>>((ref) {
  final repo = ref.watch(categoriesRepositoryProvider);
  final query = ref.watch(categoriesSearchQueryProvider);
  return repo.search(query);
});

final unitsStreamProvider = StreamProvider.autoDispose<List<Unit>>((ref) {
  return ref.watch(unitsRepositoryProvider).watchAll();
});

final suppliersSearchQueryProvider = StateProvider<String>((ref) => '');

final suppliersStreamProvider = StreamProvider.autoDispose<List<Supplier>>((ref) {
  final repo = ref.watch(suppliersRepositoryProvider);
  final query = ref.watch(suppliersSearchQueryProvider);
  return repo.search(query);
});

final productsSearchQueryProvider = StateProvider<String>((ref) => '');
final productsCategoryFilterProvider = StateProvider<int?>((ref) => null);
final productsActiveFilterProvider = StateProvider<bool?>((ref) => null);

final productsStreamProvider = StreamProvider.autoDispose<List<Product>>((ref) {
  final repo = ref.watch(productsRepositoryProvider);
  final search = ref.watch(productsSearchQueryProvider);
  final categoryId = ref.watch(productsCategoryFilterProvider);
  final isActive = ref.watch(productsActiveFilterProvider);
  return repo.watchFiltered(
    searchQuery: search.isEmpty ? null : search,
    categoryId: categoryId,
    isActive: isActive,
  );
});

final categoriesListProvider = FutureProvider.autoDispose<List<Category>>((ref) {
  return ref.watch(categoriesRepositoryProvider).getAll();
});

final unitsListProvider = FutureProvider.autoDispose<List<Unit>>((ref) {
  return ref.watch(unitsRepositoryProvider).getAll();
});

final suppliersListProvider = FutureProvider.autoDispose<List<Supplier>>((ref) {
  return ref.watch(suppliersRepositoryProvider).getAll();
});
